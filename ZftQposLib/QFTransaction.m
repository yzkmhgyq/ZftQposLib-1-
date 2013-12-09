    //
    //  QFTransaction.m
    //  Apps
    //
    //  Created by Travis on 11-10-31.
    //  Copyright (c) 2011年 QFPay. All rights reserved.
    //

#import "QFTransaction.h"

#import "QFKit.h"

NSString* const kQFTransType		=@"busicd";		//业务代码
NSString* const kQFRespondCode		=@"respcd";		//回应码

NSString* const kQFMerchantID		=@"userid";		//商户编号
NSString* const kQFMerchantNum      =@"chnluserid"; //dev1中的商户编号
NSString* const kQFMerchantName		=@"mchntnm";	//商户名称 dev1:收款方：mchntnm
NSString* const kQFMerchantType		=@"usertype";	//商户类型
NSString* const kQFMerchantAccount	=@"useraccount";//商户账号(登录名)

NSString* const kQFMerchantProvider =@"chnlusernm"; //商户名称 dev1:chnlusernm
NSString* const kQFPassword			=@"password";	//登录密码

NSString* const kQFAmount			=@"txamt";		//金额
NSString* const kQFCurrency			=@"txcurrcd";	//货币类型

NSString* const kQFPhoneID			=@"udid";		//手机唯一号

NSString* const kQFPhoneModel		=@"phonemodel";	//手机型号
NSString* const kQFPhoneOS			=@"os";			//手机系统名
NSString* const kQFPhoneOSVersion	=@"osver";		//手机系统版本

NSString* const kQFTerminalID		=@"terminalid";	//终端编号
NSString* const kQFTerminalNum      =@"chnltermid"; //dev1中的终端号

NSString* const kQFPSAMID			=@"psamid";		//PSAM编号
NSString* const kQFEncTerminalID	=@"enctid";		//加密终端编号
NSString* const kQFEncPSAMID		=@"encpid";		//加密PSAM编号

NSString* const kQFGPSLon			=@"kQFGPSLon";	//经度
NSString* const kQFGPSLat			=@"kQFGPSLat";	//维度
NSString* const kQFGPS				=@"lnglat";		//经纬度

NSString* const kQFAppID			=@"appid";		//应用程序编号
NSString* const kQFAppVersion		=@"appver";		//客户端版本
NSString* const kQFAppUpdateLevel	=@"update";		//是否更新的级别
NSString* const kQFAppUpdateURL		=@"updateurl";	//新版本app下载地址
NSString* const kQFAppName          =@"app_name";   //增加应用名称（可选参数，供渠道使用）

NSString* const kQFSwipCount		=@"tcount";		//提交前的刷卡次数

NSString* const kQFSystemSN			=@"syssn";		//系统流水号

NSString* const kQFClientSN			=@"clisn";		//客户端水号

NSString* const kQFChannelSN        =@"chnlsn";     //dev1中的渠道参考号

NSString* const kQFNewsNotice		=@"news";		//新闻

NSString* const kQFNetworkType		=@"networkmode";//网络类型

NSString* const kQFServerRoot		=@"domain";		//服务器地址
NSString* const kQFMACKey			=@"tck";		//刷卡器通信密钥

NSString* const kQFTrackData		=@"trackdata";	//磁道信息
NSString* const kQFTrackFormat		=@"trackfmt";	//磁道格式

NSString* const kQFPinData		    =@"cardpin";	//密码信息
NSString* const kQFPinFormat		=@"cardpinfmt";	//密码格式

NSString* const kQFTime				=@"txdtm";		//交易时间
NSString* const kQFSession			=@"sessionid";	//Session

NSString* const kQFReuploadCount	=@"upload_retries";		//存根重试次数
NSString* const kQFReversalCount	=@"reversal_retries";	//冲正重试次数

NSString* const kQFQueryStart       =@"qstart";     //交易统计（历史记录）中分页查询时的起始条目
NSString* const kQFQueryLen         =@"qlen";       //交易查询时一次要查询的条目数

    //交易超时时间,冲正超时时间
NSString* const kQFOnlineTimeout    =@"online_timeout";     //交易超时时间
NSString* const kQFOfflineTimeout	=@"offline_timeout";    //冲正超时时间

    //卡卡转账
NSString* const kQFIncardcd         =@"incardcd";       //转入卡卡号


static NSDictionary *sharedTransTable=nil;
    //static NSDictionary *sharedKeyTable=nil;

@implementation QFTransaction
@synthesize type,usercd,userid,mac,originalTransaction,businessCode,api,clientSN;
@synthesize respondInfo,requestInfo;
@synthesize config;


+(id)transactionWithType:(QFTransactionType)aTransType{
    EMLog();
	if (sharedTransTable == nil) {
		sharedTransTable=[[NSDictionary alloc] initWithContentsOfFile:[[QFKit bundle] pathForResource:@"TransTable" ofType:@"plist"]];
	}
    
	NSDictionary *info=[sharedTransTable objectForKey:[NSString stringWithFormat:@"%d",aTransType]];
#if QF_DEBUG_MODE>0
	if (info==nil) {
		QFLog(@"不支持的交易类型：%ld",aTransType);
	}
#endif
    
	QFTransactionConfig *cfg = [[QFTransactionConfig alloc] initWithInfo:info];
	
	QFTransaction *trans = [QFTransaction new];
	trans.config = [cfg autorelease];
	trans.type = aTransType;
	
	if (trans.config.coreTransaction) {
        
            //第一步：取得本地GMT时间
        NSDate *current = [NSDate date];
        
            //第二步：服务器时间差
        double iOffset = [QFKit kit].timeOffset;
        
            //第三步：当地与GMT时间差
        NSTimeZone *currentZone = [NSTimeZone localTimeZone]; //[NSTimeZonesystemTimeZone]
        NSInteger iDiff2TMZone = [currentZone secondsFromGMTForDate: current];  //这是本地时间区GMT时间差(比如东京就是GMT+9,北京是GMT+8,纽约是GMT-5)
        
            //第四步：产生本地的00点00分基准字符串（用来产生Clisn）
            //        NSDateFormatter *df = [NSDateFormatter new];
            //		[df setDateFormat:@"yyyy-MM-dd"];
            //
            //        NSDate *tmpDate = [current dateByAddingTimeInterval:iDiff2TMZone+iOffset];
            //        NSString *strData = [df stringFromDate: tmpDate];
            //        [df setTimeZone:currentZone];
            //		NSDate *date0000 = [df dateFromString: strData];
        
            //第七步：产生一个交易时间
        NSDateFormatter *df2 = [NSDateFormatter new];
        [df2 setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
		[trans setObject:[df2 stringFromDate:[current dateByAddingTimeInterval:iOffset + 8*3600-iDiff2TMZone]] forKey:kQFTime];
        
            //第五步：产生一个流水号
        NSString *strTime = [trans objectForKey:kQFTime];
        int iH = 0;
        int iM = 0;
        int iS = 0;
        iH = [[strTime substringWithRange:NSMakeRange(strTime.length-8,2)] intValue];
        iM = [[strTime substringWithRange:NSMakeRange(strTime.length-5,2)] intValue];
        iS = [[strTime substringWithRange:NSMakeRange(strTime.length-2,2)] intValue];
        
        double cli = floor( iH*3600 + iM * 60 + iS );   //流水号时间
        
            //第六步：保存Clisn
        trans.clientSN = [NSString stringWithFormat:@"%06.0f",cli];
        
            //v6code:打印当前时间,输出流水号
        QFLog(@"--->clisn=%f,tm=%@", cli, [trans objectForKey:kQFTime]);
        
        [df2 release];
        
            //[df release];
        
        /*
         //注：服务器时间为GMT时间
         //
         //客户端流水号,current是GMT时间
         NSDate *current = [NSDate date];
         
         //NSDate *current = [[NSDate date] dateByAddingTimeInterval:[QFKit kit].timeOffset];
         
         //todo:
         //把current时间进行本地化
         //
         //TMZone
         NSTimeZone *currentZone = [NSTimeZone localTimeZone]; //[NSTimeZonesystemTimeZone]
         
         NSInteger iDiff2TMZone = [currentZone secondsFromGMTForDate: current];  //这是本地时间区GMT时间差(比如东京就是GMT+9,北京是GMT+8)
         
         // NSString* stringFromDateToday = [formatter stringFromDate: today];//转换成字符串并格式化时间格式。
         
         //NSDate *newtoday = [today dateByAddingTimeInterval: [currentZone secondsFromGMTForDate: date] + [QFKit kit].timeOffset];
         //
         
         NSDateFormatter *df = [NSDateFormatter new];
         [df setDateFormat:@"yyyy-MM-dd"];
         NSDate *date0000 = [df dateFromString:[df stringFromDate:current]];//服务器0点
         
         double cli = floor([current timeIntervalSinceDate:date0000]);   //流水号时间
         cli += [QFKit kit].timeOffset;
         
         trans.clientSN = [NSString stringWithFormat:@"%06.0f",cli];
         
         
         ///交易时间
         [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
         
         [trans setObject:[df stringFromDate:current] forKey:kQFTime];
         
         //v6code:打印当前时间,输出流水号
         QFLog(@"--->%@",[df stringFromDate:current]);
         
         [df release];
         */
	}
    
	return [trans autorelease];
}


+(id)transactionWithDump:(NSDictionary*)info{
	EMLog();
    QFTransaction *trans=nil;
	
    //NSLog(@"返回交易数据:\n%@",[info description]);
	
	QFTransactionType aTransType = [[info objectForKey:kQFTransType] integerValue];
	
	for (NSString *type in [sharedTransTable allKeys]) {
		if ([[[sharedTransTable objectForKey:type] objectForKey:@"businessCode"] integerValue]==aTransType) {
			aTransType = [type integerValue];
			break;
		}
	}
	
	trans = [QFTransaction transactionWithType:aTransType];
	trans.respondInfo = [NSDictionary dictionaryWithDictionary:info];
	trans.usercd = [info objectForKey:@"usercd"];
	
        // TODO: 检查MAC
	trans.mac=[info objectForKey:@"mac"];
	
	NSLog(@"\n\n");
	NSLog(@"====获取必填参数 >>%@====",trans.config.name);
	NSArray *params=trans.config.respondParams;
	
	NSMutableString *nilParms=[NSMutableString string];
	
	for (NSString *pk in params) {
		NSString *tv=[info objectForKey:pk];
		
		if (tv) {
			if ([tv isKindOfClass:[NSNumber class]]) {
				tv=[NSString stringWithFormat:@"%d",[tv integerValue]];
			}
			[QFSecurity setObject:tv forKey:pk];
			NSLog(@"Get '%@'\t='%@'",pk,tv);
		}else{
			[nilParms appendFormat:@"%@,",pk];
		}
	}
	
	
	if ([nilParms length]>2) {
		QFLog(@"没有返回的字段:\n%@",nilParms);
	}
	
	NSLog(@"\n\n");
	NSLog(@"====获取选填参数 >>%@====",trans.config.name);
	params = trans.config.optionalRespondParams;
	
	for (NSString *pk in params) {
		NSString *tv = [info objectForKey:pk];
		
		if (tv) {
			[QFSecurity setObject:tv forKey:pk];
			NSLog(@"Get '%@'\t='%@'",pk,tv);
		}
	}
	
	switch (aTransType) {
		case QFTransactionType_Init:		{
			[QFSecurity setObject:[info objectForKey:kQFServerRoot] forKey:kQFServerRoot];
			
                //对时
			NSString *remoteTimestamp = [info objectForKey:@"timestamp"];
			if ([remoteTimestamp length] > 9) {
                
                    //这是本地时间区GMT时间差(比如东京就是GMT+9,北京是GMT+8,纽约是GMT-5)
                NSInteger offset = [remoteTimestamp doubleValue] - [[[NSDate date]  dateByAddingTimeInterval:0] timeIntervalSince1970];
                
                NSString *s0a = [QFSecurity getObjectForKey:@"update_news"];
                if ([[[QFSecurity getObjectForKey:@"update_news"] substringFromIndex:s0a.length-1] isEqualToString:@"x"] ) {
                    ;
                } else {
                    goto TSR;
                }
				/*goto TSR*/;QFLog(@"本地时间差:%ld",offset);
                
                if (offset > 600 || offset < -600) {
                        //QFAlert(@"警告", @"系统时区错误，为了保证交易正常，请正确设置手机中的时区\ue337", @"确定");
                }TSR:
                
				[QFKit kit].timeOffset = offset;
			}
            
                //将上传存根及冲正重试次数保存在QFSecurity中
            [QFSecurity setObject:[info objectForKey:kQFReversalCount] forKey:kQFReversalCount];
            [QFSecurity setObject:[info objectForKey:kQFReuploadCount] forKey:kQFReuploadCount];
            
		}break;
		case QFTransactionType_Active:		{
			
                //[QFSecurity setObject:[info objectForKey:kQFAppID] forKey:kQFAppID];
			
			NSString *entck=[info objectForKey:kQFMACKey];
            
			if ([entck length]==32) {
                    //保存得到的当前刷卡器对应的TermID
				[[NSUserDefaults standardUserDefaults] setObject:entck forKey:[QFSecurity getObjectForKey:kQFTerminalID]];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}else{
                    //QFAlert(@"请服务器支持最新的32位TCK逻辑", @"目前只能支持2,8号刷卡器进行交易", @"确定");
				[[NSUserDefaults standardUserDefaults] setObject:@"A33A42CF5D1DA3C0C852AAF364E721D8" forKey:[QFSecurity getObjectForKey:kQFTerminalID]];
			}
			
		}break;
		case QFTransactionType_Login:		{
                ///记录登录返回的用户信息
			NSString *mid = [info objectForKey:kQFMerchantID];
			
            if ([mid isKindOfClass:[NSNumber class]]) {
				mid=[NSString stringWithFormat:@"%llu",[mid longLongValue]];
			}
			
            [QFSecurity setObject:mid forKey:kQFMerchantID];
            
			NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
			
			for (NSHTTPCookie *cook in [storage cookies]) {
				
				if([[cook domain] rangeOfString:@"qfpay"].length>0 ||/*&&*/ [[cook name] isEqualToString:kQFSession]) {
					
                    [QFSecurity setObject:[cook value] forKey:kQFSession];
					
                    break;
				}
			}
            
		}break;
		case QFTransactionType_Logout:		{
                //[QFKit reset];
		}break;
		case QFTransactionType_Stat:		{
			
		}break;
		case QFTransactionType_Sale:		{
			
		}break;
		case QFTransactionType_Balance:		{
			
		}break;
		case QFTransactionType_Receipt:		{
			
		}break;
		case QFTransactionType_Credit:		{
			
		}break;
		case QFTransactionType_Transform:	{
			
		}break;
		case QFTransactionType_Refund:	{
			
		}break;
		case QFTransactionType_Reversal:	{
			
		}break;
		case QFTransactionType_Feedback:	{
			
		}break;
		case QFTransactionType_History:	{
			
            [QFSecurity setObject:[info objectForKey:kQFMerchantName] forKey:kQFMerchantName];
			
			[QFSecurity setObject:[info objectForKey:@"txamtsum"] forKey:@"TotalAmount"];
			[QFSecurity setObject:[info objectForKey:@"txcnt"] forKey:@"TotalCount"];
		}break;
        case QFTransactionType_Cancel: {
            
        }break;
        case QFTransactionType_ChangePass:  {
            ;
        } break;
        case QFTransactionType_Sale2:   {
            
        }break;
        case QFTransactionType_Trade_Info: {
            
        }break;
		default:{
                //ULog(@"不支持的交易类型: %ld",aTransType);
			trans=nil;
		}break;
	}
    
	return trans;
}

+(NSString*)formatedAmount:(NSString*)amount andCurrency:(NSString*)currency{
	EMLog();
    NSString *amt = amount;
	
    int curr = [currency intValue];
	
    switch (curr) {
		case 156:
		default:
                //currency = @"¥";
			break;
	}
    
    float f = [amt intValue] / 100.0f;
    
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSString *formattedNumberString = [numberFormatter stringFromNumber:[NSNumber numberWithDouble:f]];
    
    return [NSString stringWithFormat:@"¥ %@", [formattedNumberString substringFromIndex:1]];
    
    /*
     //todo
     if ([amt length]>2) {
     
     }else{
     amt=[NSString stringWithFormat:@"%03d",[amt integerValue]];
     }
     
     NSString *a2 = [amt substringFromIndex:[amt length]-2];
     NSString *famount = [amt stringByReplacingCharactersInRange:NSMakeRange([amt length]-2, 2) withString:@"."];
     
     return [NSString stringWithFormat:@"%@ %@%@",currency,famount,a2];
     */
}

- (void)dealloc {
    EMLog();
    [originalTransaction release];
	originalTransaction=nil;
	
	[requestInfo release];
	requestInfo=nil;
	
	[cachedDump release];
	cachedDump=nil;
    [super dealloc];
}

- (id)init {
    EMLog();
    self = [super init];
    if (self) {
        self.requestInfo=[NSMutableDictionary dictionary];
    }
    return self;
}

-(NSString*)api{
    EMLog();
	return self.config.api;
}

-(NSString*)businessCode{
    EMLog();
	NSString *i=nil;
	
	i=self.config.businessCode;
	
	NSAssert(i!=nil, @"业务代码不能为空", nil);
	
	return i;
}

-(id)objectForKey:(NSString*)key{
    EMLog();
	return [requestInfo objectForKey:key];
}
-(void)setObject:(id)value forKey:(NSString *)key{
    EMLog();
	if (value!=nil) {
		[requestInfo setObject:value forKey:key];
	}else{
		[requestInfo removeObjectForKey:key];
	}
}

-(NSMutableDictionary*)preDump{
    EMLog();
	NSMutableDictionary *dump=[NSMutableDictionary dictionary];
	
        ///检查网络连接
	NSString *nt=@"";
	nt?[self setObject:nt forKey:kQFNetworkType]:[self setObject:@"-" forKey:kQFNetworkType];
	
        //  NSString *tmp = [QFSecurity getObjectForKey:kQFAppID];
	[dump setObject:[QFSecurity getObjectForKey:kQFAppID] forKey:kQFAppID];
    
        ///必填项
	[dump setObject:self.businessCode forKey:kQFTransType];
	
	if ((self.type==QFTransactionType_Reversal || self.type==QFTransactionType_Refund || self.type==QFTransactionType_Cancel) && self.originalTransaction!=nil) {
		self.requestInfo=self.originalTransaction.requestInfo;
		[dump setObject:self.originalTransaction.clientSN forKey:@"origclisn"];
		[dump setObject:self.originalTransaction.businessCode forKey:@"origbusicd"];
		[dump setObject:[requestInfo objectForKey:kQFTime] forKey:@"origdtm"];
		[dump setObject:[requestInfo objectForKey:kQFAmount] forKey:kQFAmount];
		[dump setObject:[requestInfo objectForKey:kQFCurrency] forKey:kQFCurrency];
		
		NSString *sys=[requestInfo objectForKey:kQFSystemSN];
		
		if (sys) {
			[dump setObject:sys forKey:kQFSystemSN];
		}
	}
    
	if (self.config.coreTransaction) {
		NSArray *gps=[NSArray arrayWithObjects:[[QFSecurity getObjectForKey:kQFGPSLon] stringValue], [[QFSecurity getObjectForKey:kQFGPSLat] stringValue],nil];
		if ([gps count]==2) {
			[dump setObject:gps forKey:kQFGPS];
		}else{
			QFLog(@"无法获取GPS信息");
		}
		
		if (self.clientSN) {
			[dump setObject:self.clientSN forKey:kQFClientSN];
		}
	}
	
	return dump;
}

-(NSMutableDictionary*)dump{
    EMLog();
	if (cachedDump) {
		return cachedDump;
	}
	NSMutableDictionary *dump=[self preDump];
	
    NSLog(@"\n\n");
	NSLog(@"====设置必填参数 >>%@====",self.config.name);
	NSArray *params=self.config.requestParams;
	for (NSString *pk in params) {
		NSString *tv=[requestInfo objectForKey:pk];
		if (tv==nil) {
			tv=[dump objectForKey:pk];
			if (tv==nil) {
				tv=[QFSecurity getObjectForKey:pk];
			}
		}
		
		if (tv) {
			[dump setObject:tv forKey:pk];
			NSLog(@"Set '%@'\t='%@'",pk,tv);
		}else {
			QFLog(@"*空值:%@",pk);
		}
	}
	
	NSLog(@"====设置选填参数 >>%@====",self.config.name);
	params=self.config.optionalRequestParams;
	for (NSString *pk in params) {
		NSString *tv=[requestInfo objectForKey:pk];
		if (tv==nil) {
			tv=[dump objectForKey:pk];
			if (tv==nil) {
				tv=[QFSecurity getObjectForKey:pk];
			}
		}
		
		if (tv) {
			[dump setObject:tv forKey:pk];
			NSLog(@"Set '%@'\t='%@'",pk,tv);
		}else {
			NSLog(@"opt空值:%@",pk);
		}
	}
	NSLog(@"====Finish Values====\n\n");
	
    cachedDump=[dump retain];
	return dump;
}
@end
