    //
    //  QFTransaction.h
    //  Apps
    //
    //  Created by Travis on 11-10-31.
    //  Copyright (c) 2011年 QFPay. All rights reserved.
    //

#import <Foundation/Foundation.h>
#import "QFError.h"
#import "QFDevice.h"
#import "QFSecurity.h"
#import "QFTransactionConfig.h"

extern NSString* const kQFRespondCode;		///回应码
extern NSString* const kQFTransType;		///业务代码

/**dev1中修改的ID */
extern NSString* const kQFMerchantNum;
extern NSString* const kQFMerchantName;
extern NSString* const kQFMerchantProvider;
extern NSString* const kQFTerminalNum;
extern NSString* const kQFChannelSN;

extern NSString* const kQFMerchantID;		//商户编号
extern NSString* const kQFMerchantName;		//商户名称
extern NSString* const kQFMerchantType;		//商户类型
extern NSString* const kQFMerchantAccount;	//商户账号(登录名)

extern NSString* const kQFPassword;			//登录密码

extern NSString* const kQFAmount;			//金额
extern NSString* const kQFCurrency;			//货币类型

extern NSString* const kQFPhoneID;			//手机唯一号
extern NSString* const kQFPhoneModel;		//手机型号
extern NSString* const kQFPhoneOS;			//手机系统名
extern NSString* const kQFPhoneOSVersion;	//手机系统版本

extern NSString* const kQFTerminalID;		//终端编号
extern NSString* const kQFPSAMID;			//PSAM编号
extern NSString* const kQFEncTerminalID	;	//加密终端编号
extern NSString* const kQFEncPSAMID		;	//加密PSAM编号

extern NSString* const kQFGPSLon;			//经度
extern NSString* const kQFGPSLat;			//维度
extern NSString* const kQFGPS;				//经纬度

extern NSString* const kQFAppID;			//应用程序编号
extern NSString* const kQFAppVersion;		//客户端版本
extern NSString* const kQFAppUpdateLevel;	//是否更新的级别
extern NSString* const kQFAppUpdateURL;		//新版本app下载地址
extern NSString* const kQFSwipCount;		//提交前的刷卡次数
extern NSString* const kQFAppName;          //应用程序（可选参数，供渠道使用）

extern NSString* const kQFSystemSN;			//系统流水号
extern NSString* const kQFClientSN;			//客户端水号

extern NSString* const kQFNewsNotice;		//新闻

extern NSString* const kQFNetworkType;		//网络类型

extern NSString* const kQFServerRoot;		//服务器地址

extern NSString* const kQFMACKey;			//刷卡器通信密钥

extern NSString* const kQFTrackData;		//磁道信息
extern NSString* const kQFTrackFormat	;	//磁道格式
extern NSString* const kQFPinData;			//密码信息
extern NSString* const kQFPinFormat		;	//密码格式

extern NSString* const kQFTime;				//交易时间

extern NSString* const kQFSession;			//Session
extern NSString* const kQFReuploadCount;	//存根重试次数
extern NSString* const kQFReversalCount;	//冲正重试次数

    //交易超时时间,冲正超时时间
extern NSString* const kQFOnlineTimeout;	//交易超时时间
extern NSString* const kQFOfflineTimeout;	//冲正超时时间

extern NSString* const kQFQueryStart;       //交易统计中的开始条目
extern NSString* const kQFQueryLen;         //交易统计中的一次要查询的条目数

    //卡卡转账
extern NSString* const kQFIncardcd;         //转入卡卡号

typedef enum {
	
	QFTransactionType_Init		=309001,	//启动
	QFTransactionType_Active	=309002,	//激活
	QFTransactionType_Login		=309003,	//登录
	QFTransactionType_Stat		=309004,	//错误统计
	QFTransactionType_Feedback	=309005,	//用户反馈
	QFTransactionType_Logout	=309007,	//登出
    QFTransactionType_ChangePass=309006,    //修改密码
	
	
	QFTransactionType_Sale		=911001,	//消费
	QFTransactionType_Balance	=911002,	//余额查询
	QFTransactionType_Refund	=911003,	//退货
	QFTransactionType_Reversal	=911004,    //冲正
	QFTransactionType_Receipt	=911005,	//存根
	QFTransactionType_History	=911006,	//历史交易
    QFTransactionType_Cancel    =911007,    //交易撤销
    QFTransactionType_Sale2     =911008,    //消费+存根,2合1
    
    QFTransactionType_Cancel2   =911009,    //交易撤销+存根,2合1
    QFTransactionType_Cancel_Reversal    =911010,    //撤销冲正,之前没做，坑啊!
    QFTransactionType_Trade_Info    =911011,    //如果交易失败，可以有一次检查交易的机会
    
	QFTransactionType_Transform	=911012,    //转账
	QFTransactionType_Credit	=911013,    //信用卡还款
	QFTransactionType_Topup_Phone =70,	//手机充值
	
}QFTransactionType;


@class QFTransaction;

/** 交易操作刷卡器委托
 *
 */
@protocol QFDeviceOperateDelegate <NSObject>

/** 当交易收到刷卡器响应后回调
 *	@param trans 当前交易
 *  @param error 错误信息
 */
-(void)onTransaction:(QFTransaction*)trans finishOperateDeviceWithError:(QFError*)error;

@end


/** 基本交易类型
 *	我们把每一个服务器请求都看作一种交易
 */

@interface QFTransaction : NSObject{
	QFTransactionType type;
	NSString *txdir;
	NSString *respcd;
	NSString *usercd;
	NSString *userid;
	
	NSString *appid;
	NSString *udid;
	
	NSString *mac;
	
	NSString *clientSN;
	
@private
	
	QFTransaction *originalTransaction;
	NSDictionary  *respondInfo;
	NSMutableDictionary  *requestInfo;
	
	QFTransactionConfig *config;
	
	NSMutableDictionary *cachedDump;
}


/** 交易类型 */
@property(nonatomic,assign)	QFTransactionType type;

/** 业务类型 */
@property(nonatomic,readonly) NSString *businessCode;

/** 接口地址 */
@property(nonatomic,readonly) NSString *api;

/** 用户状态码 */
@property(nonatomic,copy)	NSString *usercd;

/** 客户端流水号 */
@property(nonatomic,copy)	NSString *clientSN;

/** 用户编号码 */
@property(nonatomic,copy)	NSString *userid;

/** 签名 */
@property(nonatomic,copy)	NSString *mac;


/** 交易响应数据 */
@property(nonatomic,retain)	NSDictionary  *respondInfo;

/** 交易请求数据 */
@property(nonatomic,retain)	NSMutableDictionary  *requestInfo;

/** 配置信息 */
@property(nonatomic,retain)	QFTransactionConfig *config;


/** 原始交易 */
@property(nonatomic,retain)	QFTransaction *originalTransaction;

/** 此交易对应的冲正交易 */
    //@property(nonatomic,readonly)	QFTransaction *reservalTransaction;


+(id)transactionWithType:(QFTransactionType)aTransType;

/** 用返回数据和交易请求来实例化返回交易结果
 * @param info 交易返回的json解析后的数据
 */
+(id)transactionWithDump:(NSDictionary*)info;

+(NSString*)formatedAmount:(NSString*)amount andCurrency:(NSString*)currency;

/** 用返回某一域内的值
 * @param key 域的名称, 如:`38`为客户端流水号
 * @return 某一域内的值
 */
-(id)objectForKey:(NSString*)key;

/** 设置某一域内的值
 * @param key 域的名称, 如:`38`为客户端流水号的域
 * @param value 域的值, 如:`001892`客户端流水号
 */
-(void)setObject:(id)value forKey:(NSString *)key;

-(NSMutableDictionary*)dump;


@end
