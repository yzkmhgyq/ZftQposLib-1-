//
//  QFDevice.m
//  Apps
//
//  Created by Travis on 11-9-14.
//  Copyright (c) 2011年 QFPay. All rights reserved.
//
#import "QFSecurity.h"
#import "QFDevice.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "QFDeviceEncoder.h"
#import "Utity.h"
#import "ZftQposLib.h"

#import "MediaPlayer/MPMusicPlayerController.h"

/** 刷卡器notifcation标志*/
NSString* const QFEventDevicePlugin			=@"QFEventDevicePluginChange";
NSString* const QFEventDeviceWillSendData	=@"QFEventDeviceWillSendData";
NSString* const QFEventDeviceDidGetData		=@"QFEventDeviceDidGetData";
NSString* const QFEventDeviceTimeout		=@"QFEventDeviceTimeout";
NSString* const QFEventDeviceChanged		=@"QFEventDeviceChanged";

/** 全局静态设备插入标记*/
static BOOL IS_PLUGIN=NO;
#define ZFT_SDK_VERSION "2.0.4"

#pragma mark ---iOS Audio 回调例程---
/** iOS Audio 回调例程*/
void audioRouteChangeListenerCallback (void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue){

    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
	
	UInt32 routeSize = sizeof (CFStringRef);
	NSString *route;
	
	AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &routeSize, &route);
	
	NSLog(@"Route: %@",route);
    
	IS_PLUGIN=NO;
	
    if ([route isEqualToString:@"HeadsetInOut"]) {
            //耳机孔插入
        IS_PLUGIN = YES;
        QFEvent(QFEventDevicePlugin, nil);
	}else if([route isEqualToString:@"ReceiverAndMicrophone"]){
            //耳机孔拔出
        IS_PLUGIN = NO;
        QFEvent(QFEventLogout, nil);
    }else if ([route isEqualToString:@"HeadphonesAndMicrophone"]) {
            //HeadphonesAndMicrophone是中间的插拔过程 所以忽略
    }
}
#pragma mark -
#pragma mark 声音中断通知
void interruptionListener(void *  inClientData,UInt32  inInterruptionState){
    if (inInterruptionState == kAudioSessionBeginInterruption){
		
    }else if (inInterruptionState == kAudioSessionEndInterruption){
        OSStatus result = AudioSessionSetActive(true);
        if (result) NSLog(@"Error setting audio session active! %ld\n", result);
    }
}

/** ??*/
//现在刷卡器逻辑在这边有一个问题：刷卡器显示刷卡后，会在7～12秒后再次显示“请刷卡”，
//其实是在执行：audioInputCallback（）这个方法
void audioInputCallback (     void                                *inUserData,
							  AudioQueueRef                       inAQ,
							  AudioQueueBufferRef                 inBuffer,
							  const AudioTimeStamp                *inStartTime,
							  UInt32                              inNumberPacketDescriptions,
							  AudioStreamPacketDescription  *inPacketDescs ){
    //自动释放池    
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
    /*
    AudioQueueStat *mystat = inUserData;
	
	void *bytes = inBuffer->mAudioData;
	
	NSData *adata = [NSData dataWithBytes:bytes length:inBuffer->mAudioDataByteSize];
	[mystat->data appendData:adata];
	[mystat->adapter performSelector:@selector(onReadData:) withObject:adata];
	
	OSStatus result= AudioQueueEnqueueBuffer(inAQ, inBuffer, 0,NULL);
	
    if(result && (result!=kAudioQueueErr_EnqueueDuringReset) && (result!=-50)) {
        NSLog(@"AudioQueueInputCallback Error %ld", result);
    }
    */
    
    @try {
        
        AudioQueueStat *mystat = inUserData;
        void *bytes = inBuffer->mAudioData;
        NSData *adata = [NSData dataWithBytes:bytes length:inBuffer->mAudioDataByteSize];
        [mystat->data appendData:adata];
        [mystat->adapter performSelector:@selector(onReadData:) withObject:adata];
        OSStatus result = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0,NULL);
        if(result && (result!=kAudioQueueErr_EnqueueDuringReset) && (result!=-50)) {
            NSLog(@"AudioQueueInputCallback Error %ld", result);
        }
    } @catch (NSException *e) {
        NSLog(@"audioInputCallback() Excepion!");
    } @finally {
    }
    
	[pool release];
    //[mystat->adapter performSelector:@selector(onReadBytes:) withObject:bytes];
}

void audioOutputCallback (AudioQueueStat		*mystat,
							   AudioQueueRef        inAQ,
							   AudioQueueBufferRef  inBuffer
							   ){
    
	void *bytes = inBuffer->mAudioData;
	
    int bufferSize = inBuffer->mAudioDataBytesCapacity;
	
	if (mystat != nil) {
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		
        NSMutableData *data = mystat->data;
		
		NSInteger restFrame = [data length] - bufferSize*mystat->currentFrame;
		
		//printf("\n填充缓存 剩余[%05iB], 当前帧[%03i]",restFrame,mystat->currentFrame+1);
		
		NSRange r = NSMakeRange(mystat->currentFrame*SIZ_BUFFERS, bufferSize);
		
		BOOL lastFrame = NO;
		
		if(restFrame<bufferSize){
			
			r.length=restFrame;
			if (restFrame<0) {
				lastFrame=YES;
			}
		}
		
		if (!lastFrame) {
			NSData *sd = [data subdataWithRange:r];
			memcpy(bytes, [sd bytes], r.length);
			inBuffer->mAudioDataByteSize = r.length;
			//[data getBytes:&bytes range:r];
			OSStatus result = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0,NULL);
			
            if (result) {
				NSLog(@"填充出错:%ld",result);
			}
			
            mystat->currentFrame++;
		}else{
			NSLog(@"播放完毕!");
            
            //need fix? line 134,137,140,142的次序？
            [mystat->adapter performSelector:@selector(readData)];
			
            for (int i=0; i<1; i++) {
				AudioQueueFreeBuffer(inAQ, mystat->buffers[i]);
			}
			
			AudioQueueStop(inAQ, NO);
			
            [mystat->adapter performSelectorOnMainThread:@selector(onSendDataFinish) withObject:nil waitUntilDone:YES];
		}

		[pool release];
	}
}

void audioVolumeChangeListenerCallback (void *inUserData,AudioSessionPropertyID inPropertyID,UInt32 inPropertyValueSize,const void *inPropertyValue)
{
    
    if (inPropertyID != kAudioSessionProperty_CurrentHardwareOutputVolume) return;
    
    UInt32 routeSize = sizeof (CFStringRef);
	NSString *route;
	
	AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &routeSize, &route);

    if ([route isEqualToString:@"ReceiverAndMicrophone"]) {
    }
    else {
            [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.70f];
    }
}

#pragma mark ---刷卡器全局实用方法---
/** Byte转换函数*/
int BytesToInt(char* b){
    int i = 0;
    i |= b[0] & 0xFF;
    i <<= 8;
    i |= b[1] & 0xFF;
    return i;
}

/** 打包消息*/
NSData* PackMessage(QFDeviceMessage* msg){
    

	//总长度
	//M(1)+总长度(2)+00(1)+命令(1)+子命令(1)+超时(1)+数据长度(2)+数据+MAC(4)
    int l = 1+2+1+1+1+1+2+(msg->length)+4;
    NSLog(@"%d",l);
    
    char ret[l+1];
	
	char tL[2];
	tL[0] = (char)(((l-3) & 0xFF00) >> 8);
	tL[1] = (char)(((l-3) & 0x00FF) >> 0);
	
	char dL[2];
	dL[0] = (char)(((msg->length) & 0xFF00) >> 8);
	dL[1] = (char)(((msg->length) & 0x00FF) >> 0);
		
	ret[0] = 0x4d;			//'M'
	ret[1] = tL[0];			//总长度
	ret[2] = tL[1];
	ret[3] = 0x00;			//00 固定
	ret[4] = msg->command;	//命令
	ret[5] = msg->subCommand;//子命令
	ret[6] = msg->timeOrCode;//超时
	ret[7] = dL[0];//数据长度
	ret[8] = dL[1];
	
	//填充数据
	for (int i=0; i<msg->length; i++) {
		ret[9+i]=msg->data[i];
	}
    
    
	NSData *dataNeedMac = [NSData dataWithBytes:ret+3 length:l-4-3];
	
    /** need move to QFKit*/
    
	NSData *mac = [QFSecurity MACData:dataNeedMac];
	
    if (!mac) {
        return nil;
    }
    
	char * macbytes = (char*)[mac bytes];
    
	ret[l-4]=macbytes[0];
	ret[l-3]=macbytes[1];
	ret[l-2]=macbytes[2];
	ret[l-1]=macbytes[3];

	ret[l] =GetCheckSum(ret, l);//校验和
	
    return [NSData dataWithBytes:ret length:l+1];
}

/** 得到校验和*/
char GetCheckSum(char* inData, uint length){
	unsigned char initData = inData[0];
	for (int i=1; i<length; i++) {
		initData ^= inData[i];
	}
	NSLog(@"计算校验和: %02X",initData);
	return initData;
}

#pragma mark ---刷卡器驱动实现---

@implementation QFDevice

@synthesize delegate;
@synthesize id,psamid;
@synthesize CardNum;

/** 设备单例*/
static QFDevice *sharedDevice=nil;

/** 20-12-2012 为归档和序列化实现的代码*/

/** 序列化，归档：需要实现的两个方法*/
-(void)encodeWithCoder:(NSCoder *)aCoder {

}

-(id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self=[super init]) {
        
    }

    return self;
}

/** 刷卡器单例*/
+ (QFDevice *)shared{
	if (sharedDevice==nil) {
		sharedDevice=[QFDevice new];
        
	}
	return sharedDevice;
}

/** 取得音频设备*/
+ (NSString*)route{

	UInt32 routeSize = sizeof (CFStringRef);
	CFStringRef route=NULL;
	
	AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &routeSize, &route);
    NSLog(@"getRoute: %@",(NSString*)route);
	return (NSString*)route;
}

/** 刷卡器是否已经插入*/
+ (BOOL)isPluggedIn{
#if TARGET_IPHONE_SIMULATOR
	return NO;
#else
	return IS_PLUGIN;
#endif
}

/** 初始化iOS音频设备*/
- (void)initAudio{
           
	NSError *err = nil;
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setActive:YES error:&err];
	[audioSession setCategory: AVAudioSessionCategorySoloAmbient error: &err];
	[audioSession setCategory: AVAudioSessionCategoryPlayAndRecord error: &err];
	[audioSession setPreferredHardwareSampleRate:44100 error:&err];
	[audioSession setPreferredIOBufferDuration:1.0 error:&err];
    
	if (err) QFLog(@"音频初始化出错: %@",[err description]);
    
	[audioSession setDelegate:self];
    
	OSStatus result = 0;
	
	//禁用蓝牙
	UInt32 allowBluetoothInput = 0;
	AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,
							 sizeof(allowBluetoothInput),
							 &allowBluetoothInput);
    
	//监听耳机插入
	result = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, self);
    
	if (result) NSLog(@"不能监听耳机插入: %ld", result);
    
    //监听系统中耳机模式下音量
    result = AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume,
                                             audioVolumeChangeListenerCallback, self);

	if (result) NSLog(@"不能监听系统音量: %ld", result);
    
	//SLog(@"当前音频路由:%@", [QFDevice route]);    

    
    CFStringRef route;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route);
    
    if((route == NULL) || (CFStringGetLength(route) == 0)){
        IS_PLUGIN=NO;	
    } else {
        NSString* routeStr = (NSString*)route;
        NSRange headphoneRange = [routeStr rangeOfString : @"Headphone"];
        NSRange headsetRange = [routeStr rangeOfString : @"Headset"];
        IS_PLUGIN = headsetRange.location != NSNotFound || headphoneRange.location != NSNotFound;
    }   
	
}

/** 刷卡器构造方法*/
- (id)init {
    self = [super init];
    if (self) {
		
		myPCMFormat.mSampleRate = 44100;
		myPCMFormat.mFormatID =kAudioFormatLinearPCM ;
		
		myPCMFormat.mFormatFlags =  12;//kLinearPCMFormatFlagIsPacked;
		myPCMFormat.mChannelsPerFrame = 1; //单声道
		myPCMFormat.mFramesPerPacket = 1;
		myPCMFormat.mBitsPerChannel	= 16;
		myPCMFormat.mBytesPerPacket = myPCMFormat.mBytesPerFrame = (myPCMFormat.mBitsPerChannel / 8) * myPCMFormat.mChannelsPerFrame;

        //初始化音频设备
		[self initAudio];
    }
    return self;
}

/** 刷卡器响应处理方法*/
-(void)onDeviceRespond:(QFDeviceRespondRef)resp{
	
    isBusy = NO;

    if (resp->respCode==0x0a) {
        QFLog(@"刷卡器超时");
		
        return;
	}
    switch (resp->command) {
        case 0x0d:
            //doSecurityCommand            
            switch (resp->subCommand) {
                case 0x00:
                    
                    
                    
                    break;
                case 0x01:
                    
                    break;
            }
            break;
		case 0x02:
			switch (resp->subCommand) {
				case 0x00:
				{
                    //请注意：1代刷卡器PSAM无法加载，0x0200返回respCode=0x03
                    if (resp->respCode != 0x00) {
                        
                        if (resp->respCode == 0x03) {
                            QFEvent(@"qfpos_0x03_error", nil);
                            //QFEvent(QFEventDevicePlugin, nil);
                        } else {
                            QFEvent(QFEventDevicePlugin, nil);
                        }
                        return;
                    }
                    
                    /** 需要移动到QFKit中*/
					NSString * joind = [QFSecurity hexStringFromData:resp->data];
                    
					NSString *pam=[joind substringToIndex:16];
					self.psamid=pam;
					
					//刷卡器号
					NSString *tids=[joind substringFromIndex:16];
					self.id=tids;
                    
                    //[self onDeviceSendDataFinish];

					IS_PLUGIN=YES;
					
					//QFEvent(QFEventDevicePlugin, tids);
				}break;
              
				default:
					//QFEvent(QFEventDevicePlugin, nil);
					break;
			}
			break;
        case 0x03:
            switch (resp->subCommand) {
                case 0x00:
                {
                    NSString * joind = [QFSecurity hexStringFromData:resp->data];
                    CardNum = [joind substringWithRange:NSMakeRange(18, 19)];

                }
                    break;
                    
                default:
                    break;
            }
		default:
			//QFEvent(QFEventDevicePlugin, nil);
			break;
	}
}

-(void)onDeviceSendDataFinish
{
    
    NSLog(@"success");


}



/** 取消iOS操作*/
-(void)cancel{
	[self getID];   //need fix? 为什么还要getID?
	[self stopReadData];
}

/** 得到设备ID*/
-(void)getID{
    
    /** 处理参数*/
    //step0:判断1.0or 2.0刷卡器
    //step1:依据step0的结果给 codec.c中的工作模式全局变量赋值
	
    [self stopReadData];
    QFEvent(@"linking", nil);
    [[QFDevice shared] setDelegate:(id<QFDeviceDelegate>)[QFDevice shared]];
    QFDeviceMessage msg;
	msg.command=0x02;
	msg.subCommand=0x00;
	msg.timeOrCode=0x05;/**v2.0刷卡器一定要等这么久噢。*/
	msg.length=0;
	msg.data=0;
	
	[self sendMessage:&msg];
	
	isGettingID=YES;
}

/** 得到卡号*/
-(void)getCardNumber{
	QFDeviceMessage msg;
	msg.command=0x03;
	msg.subCommand=0x00;
	msg.timeOrCode=DeviceTimeOut;
	msg.length=0;
	msg.data=0;
	
	NSData* data= PackMessage(&msg);
	[self sendData:data];
}

/** 得到磁道号*/
-(void)getTrack{
	QFDeviceMessage msg;
	msg.command=0x03;
	msg.subCommand=0x01;
	msg.timeOrCode=DeviceTimeOut;
	msg.length=0;
	msg.data=0;
	
	NSData* data= PackMessage(&msg);
	[self sendData:data];
}

/** 重试指令*/
-(void)reGet{
	QFDeviceMessage msg;
	msg.command=0x09;
	msg.subCommand=0x09;
	msg.timeOrCode=DeviceTimeOut;
	msg.length=0;
	msg.data=0;
	
	NSData* data= PackMessage(&msg);
	[self sendData:data];
}

/** 更新密钥指令*/
-(void)doSecurityCommand:(NSData*)idata{
    
	QFDeviceMessage msg;
	msg.command = 0x0d;
    msg.subCommand = 0x00;
    msg.timeOrCode = DeviceTimeOut;
    
    msg.length = [idata length];
    msg.data = (char*)[idata bytes];
	
	NSData* data = PackMessage(&msg);
    
	[self sendData:data];
}

/** 验证密钥更新状态*/
-(void)doVerifySecurityCommand {
    
	QFDeviceMessage msg;
	msg.command = 0x0d;
    msg.subCommand = 0x01;
    msg.timeOrCode = DeviceTimeOut;
    msg.length = 0;
    msg.data = 0;
	
	NSData* data = PackMessage(&msg);
	[self sendData:data];
}

/**查询当前数字信封投递状态*/
- (void)TestSecurityCommandStatus
{
    QFDeviceMessage msg;
    msg.command = 0x0d;
    msg.subCommand = 0x03;
    msg.timeOrCode = DeviceTimeOut;
    msg.length = 0;
    msg.data = 0;
    NSData * data = PackMessage(&msg);
    [self sendData:data];
}

-(void)setSleepTime:(NSData *)idata
{
    QFDeviceMessage msg;
    msg.command = 0x09;
    msg.subCommand = 0x11;
    msg.timeOrCode = DeviceTimeOut;
    msg.length = [idata length];
    msg.data =(char*)[idata bytes];
    
    NSData * data = PackMessage(&msg);
    [self sendData:data];
}

/** 系统断电**/
-(void)poweroff
{
    QFDeviceMessage msg;
    msg.command = 0x0a;
    msg.subCommand = 0x03;
    msg.timeOrCode = DeviceTimeOut;
    msg.length = 0;
    msg.data = 0;
    
    NSData * data = PackMessage(&msg);
    [self sendData:data];
}

/** iOS音频设备声道判断*/
- (void)currentHardwareInputNumberOfChannelsChanged:(NSInteger)numberOfChannels{
    
	NSLog(@"输入声道变为:%i声道",numberOfChannels);
}

/** 判断音频设备的可用性*/
- (void)inputIsAvailableChanged:(BOOL)isInputAvailable{
    
	NSLog(@"音频输入可用 [%i]",isInputAvailable);
}

/** 从刷卡器得到的数据进行解析*/
-(void)parserData:(NSData*)idata{

    /** 需要移动到QFKit*/
    NSLog(@"\n得到数据: %s",[[QFSecurity hexStringFromData:idata] UTF8String]);
//    
//	if ([delegate respondsToSelector:@selector(onDeviceRespond:)]){

		char *msg=(char*)[idata bytes];
		
		if (msg[0]==0x4d) {
            
            if([idata length]<10){
                /*如果数据太短则错误！,haha GOTO语句*/
                goto TEMPTAG;
            }
			uint msgLen=[idata length];
			char length[2];
			QFDeviceRespond resp;
			
			//校验和
			resp.checkSum=msg[msgLen-1];
			
			char cS=GetCheckSum(msg, msgLen-1);
			
			//通信MAC
			resp.MAC[3]=msg[msgLen-2];
			resp.MAC[2]=msg[msgLen-3];
			resp.MAC[1]=msg[msgLen-4];
			resp.MAC[0]=msg[msgLen-5];
			
			//检查MAC
			length[0]=msg[1];
			length[1]=msg[2];
			uint l=BytesToInt(length)-4;
			
			//命令
			resp.command = msg[4];
			
			//子命令
            
			resp.subCommand = msg[5];

            /** 需要移动到QFKit中*/
			NSData *mac = [QFSecurity MACData:[NSData dataWithBytes:msg+3 length:l]];
            //NSLog(@"%@",mac);
            
			char *macbytes = (char*)[mac bytes];
            
            
            
			if (cS!=resp.checkSum) {
				
				if (retryTime>5) {
					[lastSendData release];
					lastSendData=nil;
					retryTime=0;
					QFAlert(@"刷卡器出错", @"请退出程序,重新插拔然后重试. 如果还有问题联系客服", @"确定");
				}else{
					//[self sendData:lastSendData];
					[self reGet];
					retryTime++;
					QFLog(@"校验和错误,数据可能被破坏");
				}
				
				return;
                
                
                
			}else if ((resp.command==0x02 && 
					  resp.subCommand!=0x00 )&&
					  (macbytes[0]!=resp.MAC[0] ||
					  macbytes[1]!=resp.MAC[1] ||
					  macbytes[2]!=resp.MAC[2] ||
					  macbytes[3]!=resp.MAC[3]) 
					  ) {
				QFLog(@"通信MAC错误");
			}
			retryTime = 0;
			[lastSendData release];
			lastSendData = nil;
			
			//数码MAC
			resp.dataMAC[7]=msg[msgLen-6];
			resp.dataMAC[6]=msg[msgLen-7];
			resp.dataMAC[5]=msg[msgLen-8];
			resp.dataMAC[4]=msg[msgLen-9];
			resp.dataMAC[3]=msg[msgLen-10];
			resp.dataMAC[2]=msg[msgLen-11];
			resp.dataMAC[1]=msg[msgLen-12];
			resp.dataMAC[0]=msg[msgLen-13];

			//响应码
			resp.respCode = msg[6];
            
			if (resp.respCode==0) {
				//有效数据长度
				
				length[0]=msg[7];
				length[1]=msg[8];
				l=BytesToInt(length);
                resp.length = l;
				//resp.length=l;

				//有效数据
				//char *mydata;
				//memcpy(mydata, msg+9, l);
				
                //Wired bug... ?
                //need fix?
                //workround 0904
                //
                @try {
                    resp.data = [idata subdataWithRange:NSMakeRange(9, l)];
                }
                @catch (NSException *exception) {
                    //ULog(@"%@\n\n程序可以继续运行,但是已经不稳定,建议您重新启动", [exception reason]);
                }
				
                /** 需要移动到QFKit中*/
				//NSLog(@"\n数据[%dB]:%@",l,[QFSecurity hexStringFromData:resp.data]);
			}
			
        TEMPTAG:
			[delegate onDeviceRespond:&resp];
//			self.delegate = nil;
			
			QFEvent(QFEventDeviceDidGetData, nil);
            
		}else{

            QFEvent(@"QFDeviceReturnDataError", nil);

			NSLog(@"刷卡器返回数据异常:%@", [idata description]);
		}		
//	} else {
//        QFEvent(@"QFDeviceReturnDataError", nil);
//        QFLog(@"%@ 不支持onDeviceRespond:",delegate);
//
//    }
}

/** 读数据时准备*/
-(void)prepareRead{
    
	OSStatus result=0;
	
	AudioQueueRef queue = {0};

    /* 使用之前先清空一下结构体*/
    memset(&inputStat, 0, sizeof(AudioQueueStat));
    
	inputStat.adapter=self;
	inputStat.data=[[NSMutableData alloc] init];
	inputStat.currentFrame=0;

    //重置
	reset();
	
    /** 创建新的队列用以Record Audio*/
	result= AudioQueueNewInput (&myPCMFormat, (AudioQueueInputCallback)audioInputCallback , &inputStat, NULL, NULL, 0, &queue);
	
    if (result) QFLog(@"不能开启音频输入: %ld", result);
	
	inputStat.queue=queue;

	for (int i=0; i<NUM_BUFFERS; i++) {
		result=AudioQueueAllocateBuffer(queue, 1024, &inputStat.buffers[i]);
		result=AudioQueueEnqueueBuffer (queue,inputStat.buffers[i], 0, NULL);
		if (result) QFLog(@"播放声音缓存问题 %u", result);
	}
}

/** 这个定时器是给谁用的？*/
-(void)onTimer{
    if (timeLeft==1) {
        NSLog(@"还有%02d秒设备超时",timeLeft);
    }
	
    timeLeft--;
	
	if (timeLeft==0) {
		[self stopReadData];
		
		if (isGettingID) {
            IS_PLUGIN=NO;
            //QFEvent(QFEventDevicePlugin, nil);
            
		}else{
			QFEvent(QFEventDeviceTimeout, nil);	
		}
	}
}

/** 对数据进行编码,调用encode()方法*/
-(NSData*)audioDataEncode:(NSData*)data{
	
    reset();
	
	char resultC[204800]; // 存储结果集的数组
	
    memset(resultC, 0, 204800);
	
    int resultLen=0; // 结果集长度
	
    /** 对数据进行编码*/
    encode((char*)[data bytes], [data length], resultC, &resultLen);
	
	return [[[NSData alloc] initWithBytes:&resultC length:resultLen] autorelease];
}

/** 静音数据*/
-(NSMutableData*)silentData{
	return [NSMutableData dataWithLength:512];
}

/** 刷卡接发送数据接口*/
-(BOOL)sendData:(NSData*)data{
    
	if (isBusy) {
		[self stopReadData];
		//return NO;
	}else{
		isBusy=YES;
	}
	
	if (![data isKindOfClass:[NSData class]]) {
		QFLog(@"数据错误 无法发送到刷卡器！");
		return NO;
	}
	
	//检查其它播放音源
	UInt32 iPodIsPlaying = 0; UInt32 size = sizeof(iPodIsPlaying);
    
	OSStatus result = AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &iPodIsPlaying);
	
    if (result) NSLog(@"Error getting other audio playing property! %ld", result);
	
	if (iPodIsPlaying) NSLog(@"其它程序正在使用音频");
	
    // 将date数据转换成音频数据
	NSData * endata=[self audioDataEncode:data];
	NSMutableData *all=[self silentData];
	[all appendData:endata];
	data = all;
	
    QFEvent(QFEventDeviceWillSendData, data);
	
	if ([data length]>0) {
		
        OSStatus result=0;
		
		AudioQueueRef queue = {0};
		
        /**使用时把outputStat重置一下 */
        memset(&outputStat, 0, sizeof(AudioQueueStat));
    
        /* adapter 是QFDevice的对象 */
		outputStat.adapter=self;

        /** 把数据放入AudioQueue中的data区*/
		outputStat.data=[[NSMutableData alloc] initWithData:data];
		
		outputStat.queue=queue;
		outputStat.currentFrame=0;

		result= AudioQueueNewOutput(&myPCMFormat, (AudioQueueOutputCallback)audioOutputCallback, &outputStat, NULL, NULL, 0, &queue);
        
		if (result) NSLog(@"不能开启音频输出: %ld", result);

		for (int i=0; i<1; i++) {
			result=AudioQueueAllocateBuffer(queue, SIZ_BUFFERS, &outputStat.buffers[i]);
			if (result) {
				NSLog(@"播放声音缓存问题 %ld", result);
				return NO;
			}
			audioOutputCallback(&outputStat, queue, outputStat.buffers[i]);
		}
		
        /** need fix? 此处可以指定第二个参数*/
        //打开程序
		result = AudioQueueStart(queue, NULL);
        
		if (result) {
			NSLog(@"播放声音无法开始 %ld", result);
			return NO;
		}
		
		NSLog(@"*开始发送声音数据");

        //v10code:0x0208命令激活计时器
        ///启动计时器
		if (timer) {
			[timer invalidate];
			timer = nil;
		}
		
		int i = DeviceTimeOut + 5;  //v12code
        
        //QFLog(@"timeout = %d", i);
		
		timeLeft = i;
		
		timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
		[timer fire];
        //v10code:end
        
		//准备好接收数据
		[self prepareRead];
		
	}else{
		NSLog(@"声音数据编码出错!");
	}
	
	return YES;
}

- (void)waitByOutTime:(NSInteger)timeout
{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    int i = DeviceTimeOut + 5;  //v12code
    
    QFLog(@"timeout = %d", i);
    
    timeLeft = i;
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
    [timer fire];
    //v10code:end
    
    //准备好接收数据
    [self prepareRead];
}

/** 向刷卡器发送命令*/
-(BOOL)sendMessage:(QFDeviceMessage*)msg{
    //char chardata[] = {0x4d,0x00,0x17,0x00,0x02,0x88,0x3c,0x00,0x0d,0x04,0x03,0x31,0x32,0x33,0x03,0x31,0x30,0x30,0x03,0x31,0x30,0x30,0x98,0x2e,0x1b,0x35,0x4e};
    
    
    
    
	NSData* data = PackMessage(msg);
    //NSData * data = [NSData dataWithBytes:chardata length:sizeof(chardata)];
    
    
	
	BOOL succ = [self sendData:data];
	
	if (succ) {
        
		///启动计时器
		if (timer) {
			[timer invalidate];
			timer = nil;
		}
		
		int i = msg->timeOrCode;
        
        QFLog(@"timeout = %d", i);
		
		timeLeft = i;
		
		timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
		[timer fire];
	}
	
	isGettingID = NO;
	return succ;
}

/** 数据完成发送后的消息响应*/
-(void)onSendDataFinish{
	[outputStat.data release];
	outputStat.data=nil;
	outputStat.currentFrame=0;
	outputStat.queue=nil;
	
	if ([delegate respondsToSelector:@selector(onDeviceSendDataFinish)]) {
		[delegate onDeviceSendDataFinish];
	}
}

/** 从音频队列中读取听到的数据*/
-(void)readData{
    
	OSStatus result = 0;
	
	if (nil == inputStat.queue) {
		[self prepareRead];
	}
    
	result = AudioQueueStart(inputStat.queue, NULL);
	
    NSLog(@"开始接收声音数据AudioQueueStart_result=%ld", result);
}

/** 读取数据*/
-(void)onReadData:(NSData*)idata{

	int msgLen = 0; // readMessage获得的数据长度
	char *msg;
	
    //调用codec()来取得数据
	dataIn((char*)[idata bytes], [idata length]);

	// readMessage测试
	msg = readMessage(&msgLen);
    
	if (msgLen>0) {
		//解析数据
		NSAutoreleasePool *pool=[NSAutoreleasePool new];
		[self stopReadData];
		NSData *outdata=[NSData dataWithBytes:msg length:msgLen];
		[self performSelectorOnMainThread:@selector(parserData:) withObject:outdata waitUntilDone:YES]; //在主线程中运行paserData:方法
		[pool release];
	}
}

/** 停止读数据，重置缓冲区及iOS Audio组件*/
-(void)stopReadData{
    
	[timer invalidate];
	timer=nil;

	AudioQueueRef inputQ=inputStat.queue;
	if (inputQ) {
		
		AudioQueueStop(inputQ, YES);
		for (int i=0; i<NUM_BUFFERS; i++) {
			AudioQueueFreeBuffer(inputQ, inputStat.buffers[i]);
		}
		
		if (inputStat.data) {
            
            //保存数据到磁盘中
			//[inputStat.data writeToFile:[QFKit dataFilePath:@"rec.dat"] atomically:YES];
			
			[inputStat.data release];
			inputStat.data=nil;
		}
		inputStat.currentFrame=0;
		inputStat.queue=nil;		
	}
    reset();
}

-(NSString*)getTerminalID
{
    return  self.id;
}

-(NSString*)getPsamID
{
    return self.psamid;
}

-(NSString*)getVersionID
{
    return [NSString stringWithFormat:@"%s",ZFT_SDK_VERSION];
}

-(NSString*)returnRardNum
{
    return self.CardNum;
}
@end
