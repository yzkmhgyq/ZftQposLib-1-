/** 钱方刷卡器 iOS SDK
 *	
 *
 */

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "QFDevice.h"
#import "QFError.h"

#pragma mark -=QFKit接口设计=-
@interface QFKit : NSObject<CLLocationManagerDelegate>{
	CLLocationManager *locationMgr;
	
	@private
	BOOL shouldActiveDevice;
	BOOL shouldRefresh;
	BOOL shouldBlockDeviceAlertView;
	NSInteger timeOffset;
}

@property(nonatomic,assign) BOOL shouldActiveDevice;
@property(nonatomic,assign) BOOL shouldRefresh;
@property(nonatomic,assign) BOOL shouldBlockDeviceAlertView;

/** 本地与服务器的时间差 */
@property(nonatomic,assign) NSInteger timeOffset;

/** QFKit单体实例
 *	这是访问QFKit的唯一方法!!
 */
+(QFKit *)kit;
+(NSBundle*)bundle;

/** 获取QFPay的资源包内文件路径 
 *	@param fileNameOrRelPath 文件相对于bundle的路径
 */
+(NSString*)bundleFilePath:(NSString*)fileNameOrRelPath;

/** 返回数据文件路径 
 *	@param fileNameOrRelPath 文件相对于程序数据沙盒的路径
 */
+(NSString*)dataFilePath:(NSString*)fileNameOrRelPath;


/** 刷新GPS位置
 *	@return 返回是否可以刷新GPS位置
 */
+(BOOL)refreshGPS;

/** 重置所有数据 */
+(void)reset;
@end

/** 为 NSObject 扩展 JSON方法 */
@interface NSObject (NSObject_SBJSON)

/** 将对象转换为JSON字符串 */
- (NSString *)JSONString;

@end

/** 为 NSString 扩展 JSON方法 */
@interface NSString (NSString_SBJSON)

/** 将JSON字符串转换为对象 */
- (id)JSONValue;

@end


/** 快速弹出提醒窗口 */
void QFAlert(NSString *title, NSString *msg, NSString *buttonText);

/** 快速发送一个事件 */
void QFEvent(NSString *eventName,id data);

/** 快速注册事件侦听 */
void QFListenEvent(NSString *eventName,id target,SEL method);

/** 快速注销事件侦听 */
void QFForgetEvent(NSString *eventName,id target);


/** 获取本地化字符串
 *@param table 表名
 */
NSString *QFString(NSString *key,NSString *table);
