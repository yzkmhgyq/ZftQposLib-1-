

#import <Foundation/Foundation.h>
#import "QFError.h"

/**
 * 所有安全与加密相关操作	
 */
@interface QFSecurity : NSObject{
	
}
+(QFSecurity*)shared;

+(NSArray*)keysShouldSave;

/** @name 加密相关 */



/** 获取用于刷卡器交互的TCK 
 * @warning *重要:* 需要满足条件: 1.有TerminalID 2.有加密过的TCK
 */
+(NSData*)getTCK;

/** 写入TCK
 *
 *
*/
+(NSInteger ) setDesKey:(NSString *)key;

/** 用密钥签名数据 
 *	@param indata 需要被签名的数据
 */
+(NSData*)MACData:(NSData*)indata;

/* 用密钥验证签名是否有效 
+(BOOL)verifyMAC:(NSString*)mac withString:(NSString*)string;
*/

/** 验证公钥是否可用 */
+(BOOL)verifyPublicKey;

/** 用公钥加密数据
 *	@param indata 需要被加密的数据
 *	@exception 公钥加密异常 userInfo.Error有详细错误信息
 */
//+(NSData*)publicKeyEncpty:(NSData*)indata;


/** 用任意密钥加密数据 
 *	@param indata 需要被加密的数据
 *	@param key	密码
 */
+(NSData*)encryptData:(NSData*)indata withKey:(NSString*)key;

/** 用任意密钥解密数据 
 *	@param indata 需要被加密的数据
 *	@param key	密码
 */
+(NSData*)decryptData:(NSData*)indata withKey:(NSString*)key;

/** @name 辅助方法 */

/** 把二进制数据按位异或
 * @param indata 需要异或的二进制数据
 * @param l 异或的位数
 */
+(NSData*)XOR:(NSData*)indata useBytesLength:(int)l;


/** 获取当前时间戳 */
+(NSString*)timestamp;

/** 得到字符串的MD5值 
 * @param s 需要计算MD5的字符串
 */
+(NSString*)MD5:(NSString*)s;

/** 得到字符串的SHA1值 
 * @param str 需要计算SHA1的字符串
 */
+(NSString *)SHA1:(NSString *)str;

/** 得到data的16进制字符串 
 * @param data 需要计算HEX的二进制数据
 */
+(NSString*)hexStringFromData:(NSData*)data;

/** 得到HEX的二进制数据
 * @param hexString 需要计算16进制字符串
 */
+(NSData *) dataFromHexString:(NSString*)hexString;

/** 存储数据 
 *	不用关心数据的存放位置和加密，系统自动判断是否加密和存储
 * @param key 存储数据用的字段名,建议是字符串类型
 * @param obj 任意数据
 */
+(void)setObject:(id)obj forKey:(id)key;

/** 取得数据 
 * @param key 存储数据用的字段名,一般是字符串类型
 */
+(id)getObjectForKey:(id)key;

@end



/** Base64编解码相关 用于网络传输 */
@interface Base64 : NSObject

/** 解码Base64 
 * @param string base64字符串
 */
+ (NSData*) decode:(NSString*) string;

/** 编码Base64 
 * @param rawBytes 需要编码的二进制数据
 */
+ (NSString*) encode:(NSData*) rawBytes;
@end

