//
//  QFError.h



#import <Foundation/Foundation.h>

extern NSString* const QFEventLogout;

/** @name 错误域 */
/** @enum QFError 错误域 Description */
typedef enum{
	/** 未知错误 */
    QFErrorDomainUnknown    =0,
	
	/** 网络错误 */
    QFErrorDomainConnect    =1,
	
	/** 服务器错误 */
    QFErrorDomainService    =2,
	
	/** 刷卡器错误 */
    QFErrorDomainTerminal   =3,
	
	/** 客户端错误 */
    QFErrorDomainClient     =4,
	
	/** 用户错误 */
    QFErrorDomainUser		=5,
    
	/** 客户端提醒 */
    QFErrorDomainClientAlert     =9,
}QFErrorDomain;

typedef enum{
    QFServiceErrorJSONFormat    =2000,
    QFServiceErrorMAC,
    QFServiceErrorDecrypt,
    QFServiceErrorDataFormat,
    QFServiceErrorDataNull,
	QFServiceErrorTraceCode,
	QFServiceErrorHandshake,
}QFServiceError;

typedef enum{
    QFClientErrorNullCallback    =1,
    QFClientErrorForbidGPS,
    QFClientErrorUnsupportTransType=100,
	
	QFClientErrorGPSDisable		=150,
	QFClientErrorGPSError		=151,
	
	QFClientErrorPublicKey		=200,
	
	QFClientErrorReversaling	=300,
}QFClientError;


typedef enum{
    QFErrorLevelLog,
    QFErrorLevelAlert,
    QFErrorLevelAlertWithSound,
    QFErrorLevelRetry,
	QFErrorLevelBroadcast,
    //需要服务器支持
    QFErrorLevelAlertAndCallback=100,
}QFErrorLevel;

/** 错误提醒系统
 *	
 */
@interface QFError : NSError{
    QFErrorDomain errorDomain;
    NSData *data;
	NSString *extendMsg,*stringCode;
	NSInvocation *retryInvocation;
}

/** 错误域 */
@property(nonatomic,assign) QFErrorDomain errorDomain;

/** 错误提醒级别 */
@property(nonatomic,assign) QFErrorLevel level;

/** 错误是否可以被恢复 */
@property(nonatomic,readonly) BOOL shouldReversal;

/** 错误产生的数据 */
@property(nonatomic,retain) NSData *data;

/** 扩展信息 */
@property(nonatomic,copy) NSString *extendMsg;

/** 字符串错误码信息 */
@property(nonatomic,copy) NSString *stringCode;

/** 重试的参数 */
@property(nonatomic,retain) NSInvocation *retryInvocation;


/** 产生一个错误 
 * @param edomain 错误域
 * @param ecode 错误码
 */
+(QFError *)errorWithDomain:(QFErrorDomain)edomain andCode:(NSInteger)ecode;


/** 产生一个错误 ,多用于服务器返回
 * @param edomain 错误域
 * @param scode 错误码
 */
+(QFError *)errorWithDomain:(QFErrorDomain)edomain andStringCode:(NSString*)scode;

/** 将错误展现出来 
 * 根据错误提醒级别 level 表现形式不同
 */
-(void)present;

@end

/** 针对 QFError 扩展异常 */
@interface NSException (QFError)

/** 产生异常
 * @param error 用于创建异常的错误
 */
+(NSException*)exceptionWithError:(QFError*)error;
@end

/** 纪录日志 */
void QFLog(NSString *msg,...);

#ifndef QF_DEBUG_MODE
#define QF_DEBUG_MODE 2
#endif

#ifdef QF_DEBUG_MODE
#	
#	
#	if   QF_DEBUG_MODE==0
#		define QFDebugLog @"QFDebugLogDismiss"
#		define NSLog(...) /* */
#       define EMLog(...) /* */
#
#	elif QF_DEBUG_MODE==1
#		define QFDebugLog @"QFDebugLog"
#       define EMLog(...)  /* */
#	elif QF_DEBUG_MODE==2
#		define QFDebugLog @"QFDebugLog"
#       define EMLog(...) NSLog(@"Executive Method: %s",__FUNCTION__);
#	endif
#else
#	define NSLog(...) /* */
#	define QFDebugLog @"QFDebugLogDismiss"
#endif
