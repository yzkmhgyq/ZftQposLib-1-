//
//  ZftQposLib.m
//  ZftQposLib
//
//  Created by rjb on 13-8-1.
//  Copyright (c) 2013年 rjb. All rights reserved.
//

#import "ZftQposLib.h"
#import "QFDevice.h"
#import "QFSecurity.h"
#import "Utity.h"

static  id<ZftDelegate> g_itsDelegate;

@interface ZftQposLib()
{
    NSString     * cardNum;
    NSString * command;
    NSTimer *timer;
	int timeLeft;
    NSInteger timecount;
    NSInteger times;
    BOOL isFinishCommand;
}
@property (nonatomic ,retain) NSString * cardNum;
@end


@implementation ZftQposLib
@synthesize cardNum;

static ZftQposLib *sharedQFSDK = nil;

+(ZftQposLib *)getInstance
{
    @synchronized(self) {
        if (sharedQFSDK == nil) {
            sharedQFSDK = [[self alloc] init];            
        }
    }
    return sharedQFSDK;
}

/** 刷卡器构造方法*/
- (id)init {
    self = [super init];
    if (self) {
        [QFDevice shared];
    }
    return self;
}

-(void)dealloc{
    [[QFDevice shared]release];
    [super dealloc];
}



-(void) setLister:(id<ZftDelegate>)lister
{
    QFForgetEvent(QFEventDevicePlugin, lister, @selector(onPlugin));
    QFForgetEvent(QFEventLogout, lister, @selector(onPlugOut));
    //QFForgetEvent(@"finish",lister,@selector())
    
    QFListenEvent(QFEventDevicePlugin, lister, @selector(onPlugin));
    QFListenEvent(QFEventLogout, lister, @selector(onPlugOut));
    //[QFDevice shared].delegate=(id<QFDeviceDelegate>)self;
    g_itsDelegate = lister;
    
}

-(void)Initialize{
    QFListenEvent(QFEventDeviceTimeout, self, @selector(onTimeOut));
}


-(void)onTimeOut{
    
}

-(void) doGetTerminalID:(NSInteger) tries
{
    for(int i = 0 ; i<tries; i++)
    {
        [[QFDevice shared] getID];
    }
}

-(NSString*) getTerminalID
{
    return [[QFDevice shared]getTerminalID];
}
-(NSString*)getCardNum
{
    return self.cardNum;
}
- (NSString *) getPsamID
{
    return [[QFDevice shared]getPsamID];
}
+ (NSString *) getVersionID
{
    return [[QFDevice shared]getVersionID];
}

-(NSInteger)setSleepTime:(NSInteger)time
{
    NSString * str = [NSString stringWithFormat:@"%d",time];
    [[QFDevice shared] setSleepTime:[QFSecurity dataFromHexString:str]];
    NSInteger result = 0 ;
    return result;
}


-(NSInteger) doTradeEx:(NSString*) amountString andType:(NSInteger) type andRandom:(NSString*)random
        andextraString:(NSString*)extraString andTimesOut:(NSInteger)timeout
{    
    
	if ([QFDevice isPluggedIn]) {
		char l= [amountString length];
		
		char apl=[extraString length];   //  char ap[apl];
        
		int i=0;
		
		int allLength=apl+1+4+l+1+1;
		
		char all[allLength+1];
        
		all[0]=(char)type;    //模式
		
        //流水号的后3位作为随机数
		all[1]=3;
        char* prandom = (char*) [random UTF8String];
        //NSLog(@"%s",prandom);
        for(i = 2; i<5; i++)
        {
            all[i] = prandom[i-2];
        }
        
		all[5]=l;
		char *ac=(char*)[amountString UTF8String];
		for (i=0; i<l+1; i++) {
			all[i+6]=ac[i];
		}
        
		all[l+6]=apl;
		ac=(char*)[extraString UTF8String];
		for (i=0; i<apl; i++) {
            
			all[l+7+i]=ac[i];
		}
        
		QFDeviceMessage msg;
		msg.command=0x02;
		msg.subCommand=0x88;
		msg.timeOrCode=DeviceTimeOut;
		msg.length=allLength;
		msg.data=all;
        
		NSData *data= PackMessage(&msg);
		
		[QFDevice shared].delegate=(id<QFDeviceDelegate>)self;
        
        
		if (![[QFDevice shared] sendData:data]) {
			QFLog(@"刷卡器正忙!");
            return  -1;
		}
        return  0;
    }
    
    return  1;
}

-(void)onDeviceRespond:(QFDeviceRespondRef)resp{
    
    
    //NSLog(@"\n刷卡器命令响应 %02X-%02X\n 状态码:%X",resp->command,resp->subCommand,resp->respCode);
        
	if (resp->command==0x02 && (unsigned char)resp->subCommand==0x88) {
		if (resp->respCode==0) {
            
			char *data=(char *)[(NSData*)(resp->data) bytes];
            //磁道密文长度
			char c=data[0];
			uint vlength= c;
			data++;
			
            //磁道密文
			char vdata[vlength];
			memcpy(vdata, data, vlength);
			data+=vlength;
			
			NSMutableData *trackdata=[NSMutableData dataWithBytes:&c length:1];
			[trackdata appendBytes:vdata length:vlength];
			NSString *track=[[QFSecurity hexStringFromData:trackdata] retain];
			//NSLog(@"磁道密文:%@",track);
			
            //PIN密文
			vlength=12;
			char pass[vlength];
			memcpy(pass, data, vlength);
			data+=vlength;
			
			NSString *pin=[[QFSecurity hexStringFromData:[NSData dataWithBytes:pass length:vlength]] retain];
			//NSLog(@"PIN密文:%@",pin);
            
            if(g_itsDelegate && [g_itsDelegate respondsToSelector:@selector(onSwiper:andcardTrac:andpin:)])
            {
                [g_itsDelegate onSwiper:nil andcardTrac:track andpin:pin];
            }
            //PSAM卡号
			vlength=8;
			char psam[vlength];
			memcpy(psam, data, vlength);
			data+=vlength;
			
			NSString *pam=[QFSecurity hexStringFromData:[NSData dataWithBytes:psam length:vlength]];
			//NSLog(@"PSAM卡号:%@",pam);
			
            //刷卡器号
			vlength=10;
			char tid[vlength];
			memcpy(tid, data, vlength);
            //data+=vlength;
			
			NSString *tids=[QFSecurity hexStringFromData:[NSData dataWithBytes:tid length:vlength]];
			
			//NSLog(@"刷卡器号:%@",tids);
			
			NSString *mac=[QFSecurity hexStringFromData:[NSData dataWithBytes:resp->dataMAC length:8]];
            
			NSLog(@"MAC:%@",mac);
            if(g_itsDelegate && [g_itsDelegate respondsToSelector:@selector(andpsam:andtids:)])
               [g_itsDelegate onTradeInfo:mac andpsam:pam andtids:tids];
			
           			return;
		}else if (resp->respCode==0x0A){   
            if(g_itsDelegate!= nil && [g_itsDelegate respondsToSelector:@selector(onError:)])
               [g_itsDelegate onError:@"刷卡操作已取消"];
            
		}else if (resp->respCode==0x01){
            if(g_itsDelegate!= nil && [g_itsDelegate respondsToSelector:@selector(onError:)])
                [g_itsDelegate onError:@"操作超时,请重新刷卡"];
		}else{    
            
            if(g_itsDelegate!= nil && [g_itsDelegate respondsToSelector:@selector(onError:)])
                [g_itsDelegate onError:@"刷卡器错误 请重试！"];

		}
	}
    else if(resp->command==0x02 && resp->subCommand==0x00)
    {


        [self waitUser:1 andtimeOut:60];
    }
    
    else if(resp->command == 0x03 && resp->subCommand == 0x00)
    {
        if (resp->respCode == 0) {
            NSLog(@"%zd",resp->length);
            NSString * str =[Utity NSDataToChar:resp->data andStartPos:0 andLen:resp->length];
            
            self.cardNum = str;
            NSLog(@"%@",self.cardNum);
            if(g_itsDelegate && [g_itsDelegate respondsToSelector:@selector(onSwiper:andcardTrac:andpin:)])
                [g_itsDelegate onSwiper:str  andcardTrac:@"" andpin:@""];
        }
        
    }
    else if(resp->command == 0x0d&& resp->subCommand ==0x00 )
    {
        if (resp->respCode == 0) {
            [self doCommand];
        }
    }
    else if(resp->command == 0x0d&& resp->subCommand ==0x01)
    {
        if (resp->respCode == 0) {
            if(g_itsDelegate && [g_itsDelegate respondsToSelector:@selector(doSecurityCommandStatus:)])
                [g_itsDelegate doSecurityCommandStatus:@"数字信封下发完毕"];

        }
        else{
            if(g_itsDelegate && [g_itsDelegate respondsToSelector:@selector(doSecurityCommandStatus:)])
                [g_itsDelegate doSecurityCommandStatus:@"数字信封写入失败"];

            //[[QFDevice shared] TestSecurityCommandStatus];
        }
    }
   else if(resp->command == 0x0d&& resp->subCommand ==0x03)
   {
       
   }
    else{
        if(g_itsDelegate!= nil && [g_itsDelegate respondsToSelector:@selector(onError:)])
            [g_itsDelegate onError:@"刷卡器错误 请重试！"];
	}
}

-(NSInteger)waitUser:(NSInteger)retry andtimeOut:(NSInteger) timeOut
{
    for (int i = 0;i<retry ; i++) {
        
        timeLeft = timeOut;
    
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
        [timer fire];
    
        [[QFDevice shared] prepareRead];
        [[QFDevice shared]readData];
    }
    return 0;
}
-(void)onTimer{
    
    if (timeLeft==1) {
        NSLog(@"还有%02d秒设备超时",timeLeft);
    }
	
    timeLeft--;
	
	if (timeLeft==0) {
		[[QFDevice shared] stopReadData];
		QFEvent(QFEventDeviceTimeout, nil);
	}
}

-(NSInteger) doSecurityCommand:(NSString*) cmd
{
    NSInteger result = 0;
    isFinishCommand = NO;
    timecount = 0;
    times = 0;
    
    if ([cmd length]%256) {
        NSLog(@"cmd length error");
        return result;
    }
    else timecount = [cmd length]/256;
    
    command = [[NSString alloc]initWithString:cmd];
    [QFDevice shared].delegate=(id<QFDeviceDelegate>)self;
    [self doCommand];
    
    
    return  result;
}

- (void)doCommand
{
    if (!isFinishCommand) {
        NSString* offset = [NSString stringWithFormat:@"00%d%d",times*8/16,times*8%16];
        times++;
        NSLog(@"Times = %d TimeCount = %d",times,timecount);
    if (times == timecount) {
        
        isFinishCommand = YES;
        
        NSString * result = [command substringWithRange:NSMakeRange((times-1)*256, 256)];
        
        result = [NSString stringWithFormat:@"%@%@",offset,result];
        NSData * data = [QFSecurity dataFromHexString:result];
        
        [[QFDevice shared] doSecurityCommand:data];
        
    }
    else if (times <timecount) {
        NSString * result = [command substringWithRange:NSMakeRange((times-1)*256, 256)];
        result = [NSString stringWithFormat:@"%@%@",offset,result];
        NSData * data = [QFSecurity dataFromHexString:result];
        [[QFDevice shared] doSecurityCommand:data];
    }
    else
        NSLog(@"length error");
    }
    else
        [[QFDevice shared]doVerifySecurityCommand];
}
-(NSData*)getTCK
{
    return [QFSecurity getTCK];
}

-(NSInteger ) setDesKey:(NSString *) key
{
    return [QFSecurity setDesKey:key];
}
-(void) powerOff
{
    [[QFDevice shared]poweroff];
}
//public int doSecurityCommand(byte[] cmdBytes){
//    int plen = cmdBytes.length;
//    int index = 0;
//    int offset = 0;
//    //288
//    byte[] paras = new byte[130];
//    if(this.protocolVer==0){
//        return 6;
//    } else {
//        //TODO try to run security command.
//        //必须是256的倍数。
//        if(plen%256 !=0){
//            Tip.d("doSecurityCommand cmd len error");
//            return 6;
//        }
//        
//        while (plen>0){
//            /*
//             * 发过去数据的格式是这样的，parse[0] ,parse[1] 存储的是序号，
//             * 序号是以16个字节为单位的序号。
//             * 每次发送都是以128个字节为一个批次发过去
//             * 而前面的序号则是 传送字节的第一个字节的数组索引除以16得出的。
//             */
//            offset = (index / 16);
//            if (util.IntToHex(offset).length > 1) {
//                paras[0] = util.IntToHex(offset)[0];
//                paras[1] = util.IntToHex(offset)[1];
//            } else {
//                paras[0] = 0;
//                paras[1] = util.IntToHex(offset)[0];
//            }
//            
//            for (int i = 0; i < 128; i++) {
//                paras[2 + i] = cmdBytes[index];
//                index++;
//                plen--;
//            }
//            
//            CommandDownlink dc = new CommandDownlink(0x0d, 0, 60, paras);
//            CommandUplink uc = null;
//            sendCommand(dc);
//            if (offset == 0) {
//                uc = receiveCommandwithRetry(1, 16);
//            } else {
//                uc = receiveCommandwithRetry(1, 4);
//            }
//            if (uc == null) {
//                Tip.d("doSecurityCommand 0d00 time out");
//                return 1; // time out
//            }
//            if (!(uc.command() == 0x0d && uc.subCommand() == 0 && uc
//                  .result() == 0)) {
//                Tip.d("doSecurityCommand 0d00 error");
//                return 6;
//            }
//        }
//        CommandDownlink dc=new CommandDownlink(0x0d,1,30,0);
//        sendCommand(dc);
//        CommandUplink uc=receiveCommandwithRetry(1,4);
//        //			Tip.d("doSecurityCommand uc.result()="+uc.result());
//        if (uc == null) {
//            Tip.d("doSecurityCommand 0d01 time out");
//            return 1;                       //time out
//        }
//        if(!(uc.command()==0x0d && uc.subCommand()==1 && uc.result()==0)){
//            Tip.d("doSecurityCommand 0d00 error");
//            return 6;
//        }
//        return 0;
//    }
//}

@end
