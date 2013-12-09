//
//  QFDeviceEncoder.h
//  Apps
//
//  Created by Travis on 11-9-24.
//  Copyright (c) 2011年 QFPay. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

/** @notification QFDevice GroupName Description */
extern NSString* const QFEventDevicePlugin;
extern NSString* const QFEventDeviceWillSendData;
extern NSString* const QFEventDeviceDidGetData;
extern NSString* const QFEventDeviceTimeout;
extern NSString* const QFEventDeviceChanged;

/** 缓冲区大小*/
#define NUM_BUFFERS 1
#define SIZ_BUFFERS 204800

/** 默认刷卡器指令的超时时间 */
#define DeviceTimeOut 60

@class QFDevice;
typedef struct AudioQueueSataID{
	NSMutableData *data;
	AudioQueueBufferRef buffers[NUM_BUFFERS];
	AudioStreamBasicDescription format;
	AudioQueueRef queue;
	NSUInteger	currentFrame;
	QFDevice *adapter;
}AudioQueueStat;


/** 定义刷卡器消息包 */
typedef struct QFDeviceMessageID{
	char command	;
	char subCommand	;
	char timeOrCode	;
	int  length		;
	char *data		;
}QFDeviceMessage;
typedef QFDeviceMessage* QFDeviceMessageRef;

/** 定义刷卡器请求 */
typedef struct QFDeviceRequestID{
	char command	;
	char subCommand	;
	char timeout	;
	char length		[2];
	void *data		;
}QFDeviceRequest;
typedef QFDeviceRequest* QFDeviceRequestRef;

/** 定义刷卡器响应 */
typedef struct QFDeviceRespondID{
	char command	;
	char subCommand	;
	char respCode	;
	void *data		;
	char MAC		[4];
	char dataMAC	[8];
	char checkSum	;
	int length;
}QFDeviceRespond;
typedef QFDeviceRespond* QFDeviceRespondRef;

/** 刷卡器回调委托 */
@protocol QFDeviceDelegate <NSObject>

@optional

/** 刷卡器发送完数据后回调 */
-(void)onDeviceSendDataFinish;

/** 刷卡器接收到数据后回调 
 *	@param idata 刷卡器传回的二进制数据
 */
-(void)onDeviceReadData:(NSData*)idata;

/** 刷卡器接收到数据后回调 
 *	@param resp 刷卡器传回的数据解析后的结构体
 */
-(void)onDeviceRespond:(QFDeviceRespondRef)resp;

@end

/** 刷卡器驱动
 * 负责所有刷卡器相关功能
 */
@interface QFDevice : NSObject<AVAudioSessionDelegate,NSCoding>{
	AudioStreamBasicDescription myPCMFormat;
	
	AudioQueueStat inputStat,outputStat;
	
	id<QFDeviceDelegate> delegate;
	
	AVAudioRecorder *rcd;
	NSString *id;
	NSString *psamid;
	BOOL isBusy,isGettingID;
	
	NSTimer *timer;
	int timeLeft;
    NSString * CardNum;
	
	NSData *lastSendData;
	int retryTime;
    
}

/** 刷卡器回调委托对象 */
@property(nonatomic,retain) id<QFDeviceDelegate> delegate;
@property(nonatomic,copy) NSString *id;
@property(nonatomic,copy) NSString *psamid;
@property(nonatomic,copy) NSString * CardNum;

/** 刷卡器单例*/
+(QFDevice *)shared;

/** 取得音频设备*/
+(NSString*)route;

/** 刷卡器是否已经插入*/
+ (BOOL)isPluggedIn;

/** 发送数据到刷卡器 是最底层的发送方式
 *	@param data 需要被发送的二进制数据
 */
-(BOOL)sendData:(NSData*)data;

/** 发送消息到刷卡器 
 *	@param msg 需要被发送的消息
 */
-(BOOL)sendMessage:(QFDeviceMessage*)msg;

/** 更新刷卡器密钥
 *  QPOS2.0
 */
-(void)doSecurityCommand:(NSData*)idata;
-(void)doVerifySecurityCommand;
- (void)TestSecurityCommandStatus;

/** 设置休眠时间
 * @param 休眠时间
*/
-(void)setSleepTime:(NSData*) idata;

/** 以下是一些便捷方法，可以得到刷卡器ID，卡号，磁道号等信息*/
-(void)readData;
-(void)stopReadData;
-(void)cancel;
-(void)getID;
-(void)getCardNumber;
-(void)getTrack;
-(void)poweroff;

-(NSString*)getTerminalID;
-(NSString*)getPsamID;
-(NSString*)getVersionID;
-(NSString*)returnRardNum;

-(void)prepareRead;


@end

#pragma mark ---Global Methods---
/** 全局方法*/
NSData* PackMessage(QFDeviceMessage* msg);
NSData* GetMAC(char* inData, uint dataLen, char* ckey);
char  GetCheckSum(char* inData, uint length);
int BytesToInt(char* b);

/** iOS音频全局方法*/
void audioRouteChangeListenerCallback (void *inUserData, AudioSessionPropertyID inPropertyID, UInt32 inPropertyValueSize, const void *inPropertyValue);

void interruptionListener(void *inClientData, UInt32  inInterruptionState);

void audioInputCallback (void *inUserData,AudioQueueRef inAQ,AudioQueueBufferRef inBuffer,const AudioTimeStamp                *inStartTime,UInt32 inNumberPacketDescriptions,AudioStreamPacketDescription  *inPacketDescs);

void audioOutputCallback (AudioQueueStat *mystat, AudioQueueRef inAQ, AudioQueueBufferRef  inBuffer);

void audioVolumeChangeListenerCallback (void *inUserData,AudioSessionPropertyID inPropertyID,UInt32 inPropertyValueSize,const void *inPropertyValue);
/** end*/
