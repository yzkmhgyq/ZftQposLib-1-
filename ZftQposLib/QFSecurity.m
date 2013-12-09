//
//  QFSecurity.m
//  QFApps
//
//  Created by Travis on 11-8-19.
//  Copyright 2011年 QFPay. All rights reserved.
//

#import "QFKit.h"
#import "QFSecurity.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <Security/Security.h>
#import <UIKit/UIDevice.h>
#import "QFTransaction.h"
#import "Utity.h"

static NSString *SFHFKeychainUtilsErrorDomain = @"SFHFKeychainUtilsErrorDomain";
static  char DES_KEY[] ={0x11, 0x22,  0x33,  0x44,  0x55,  0x66,  0x77,  0x88, 0x11,  0x22,  0x33,  0x44,  0x55,  0x66,  0x77,  0x88};

@interface QFSecurity(Keychain)
+ (NSString *) getPasswordForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error;
+ (void) storeUsername: (NSString *) username andPassword: (NSString *) password forServiceName: (NSString *) serviceName updateExisting: (BOOL) updateExisting error: (NSError **) error;
+ (void) deleteItemForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error;

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30000 && TARGET_IPHONE_SIMULATOR
+ (SecKeychainItemRef) getKeychainItemReferenceForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error;
#endif
@end

@implementation QFSecurity(Keychain)

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30000 && TARGET_IPHONE_SIMULATOR

+ (NSString *) getPasswordForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error {
	if (!username || !serviceName) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return nil;
	}
	
	SecKeychainItemRef item = [SFHFKeychainUtils getKeychainItemReferenceForUsername: username andServiceName: serviceName error: error];
	
	if (*error || !item) {
		return nil;
	}
	
	// from Advanced Mac OS X Programming, ch. 16
    UInt32 length;
    char *password;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;
	
    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecLabelItemAttr;
    attributes[3].tag = kSecModDateItemAttr;
    
    list.count = 4;
    list.attr = attributes;
    
    OSStatus status = SecKeychainItemCopyContent(item, NULL, &list, &length, (void **)&password);
	
	if (status != noErr) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
		return nil;
    }
	
	NSString *passwordString = nil;
	
	if (password != NULL) {
		char passwordBuffer[1024];
		
		if (length > 1023) {
			length = 1023;
		}
		strncpy(passwordBuffer, password, length);
		
		passwordBuffer[length] = '\0';
		passwordString = [NSString stringWithCString:passwordBuffer];
	}
	
	SecKeychainItemFreeContent(&list, password);
    
    CFRelease(item);
    
    return passwordString;
}

+ (void) storeUsername: (NSString *) username andPassword: (NSString *) password forServiceName: (NSString *) serviceName updateExisting: (BOOL) updateExisting error: (NSError **) error {	
	if (!username || !password || !serviceName) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return;
	}
	
	OSStatus status = noErr;
	
	SecKeychainItemRef item = [SFHFKeychainUtils getKeychainItemReferenceForUsername: username andServiceName: serviceName error: error];
	
	if (*error && [*error code] != noErr) {
		return;
	}
	
	*error = nil;
	
	if (item) {
		status = SecKeychainItemModifyAttributesAndData(item,
														NULL,
														strlen([password UTF8String]),
														[password UTF8String]);
		
		CFRelease(item);
	}
	else {
		status = SecKeychainAddGenericPassword(NULL,                                     
											   strlen([serviceName UTF8String]), 
											   [serviceName UTF8String],
											   strlen([username UTF8String]),                        
											   [username UTF8String],
											   strlen([password UTF8String]),
											   [password UTF8String],
											   NULL);
	}
	
	if (status != noErr) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
	}
}

+ (void) deleteItemForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error {
	if (!username || !serviceName) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: 2000 userInfo: nil];
		return;
	}
	
	*error = nil;
	
	SecKeychainItemRef item = [SFHFKeychainUtils getKeychainItemReferenceForUsername: username andServiceName: serviceName error: error];
	
	if (*error && [*error code] != noErr) {
		return;
	}
	
	OSStatus status;
	
	if (item) {
		status = SecKeychainItemDelete(item);
		
		CFRelease(item);
	}
	
	if (status != noErr) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
	}
}

+ (SecKeychainItemRef) getKeychainItemReferenceForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error {
	if (!username || !serviceName) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return nil;
	}
	
	*error = nil;
	
	SecKeychainItemRef item;
	
	OSStatus status = SecKeychainFindGenericPassword(NULL,
													 strlen([serviceName UTF8String]),
													 [serviceName UTF8String],
													 strlen([username UTF8String]),
													 [username UTF8String],
													 NULL,
													 NULL,
													 &item);
	
	if (status != noErr) {
		if (status != errSecItemNotFound) {
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
		}
		
		return nil;		
	}
	
	return item;
}

#else

+ (NSString *) getPasswordForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error {
	if (!username || !serviceName) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return nil;
	}
	
	*error = nil;
	
	// Set up a query dictionary with the base query attributes: item type (generic), username, and service
	
	NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecAttrService, nil] autorelease];
	NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, username, serviceName, nil] autorelease];
	
	NSMutableDictionary *query = [[[NSMutableDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
	
	// First do a query for attributes, in case we already have a Keychain item with no password data set.
	// One likely way such an incorrect item could have come about is due to the previous (incorrect)
	// version of this code (which set the password as a generic attribute instead of password data).
	
	NSDictionary *attributeResult = NULL;
	NSMutableDictionary *attributeQuery = [query mutableCopy];
	[attributeQuery setObject: (id) kCFBooleanTrue forKey:(id) kSecReturnAttributes];
	OSStatus status = SecItemCopyMatching((CFDictionaryRef) attributeQuery, (CFTypeRef *) &attributeResult);
	
	[attributeResult release];
	[attributeQuery release];
	
	if (status != noErr) {
		// No existing item found--simply return nil for the password
		if (status != errSecItemNotFound) {
			//Only return an error if a real exception happened--not simply for "not found."
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
		}
		
		return nil;
	}
	
	// We have an existing item, now query for the password data associated with it.
	
	NSData *resultData = nil;
	NSMutableDictionary *passwordQuery = [query mutableCopy];
	[passwordQuery setObject: (id) kCFBooleanTrue forKey: (id) kSecReturnData];
	
	status = SecItemCopyMatching((CFDictionaryRef) passwordQuery, (CFTypeRef *) &resultData);
	
	[resultData autorelease];
	[passwordQuery release];
	
	if (status != noErr) {
		if (status == errSecItemNotFound) {
			// We found attributes for the item previously, but no password now, so return a special error.
			// Users of this API will probably want to detect this error and prompt the user to
			// re-enter their credentials.  When you attempt to store the re-entered credentials
			// using storeUsername:andPassword:forServiceName:updateExisting:error
			// the old, incorrect entry will be deleted and a new one with a properly encrypted
			// password will be added.
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -1999 userInfo: nil];			
		}
		else {
			// Something else went wrong. Simply return the normal Keychain API error code.
			*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
		}
		
		return nil;
	}
	
	NSString *password = nil;	
	
	if (resultData) {
		password = [[NSString alloc] initWithData: resultData encoding: NSUTF8StringEncoding];
	}
	else {
		// There is an existing item, but we weren't able to get password data for it for some reason,
		// Possibly as a result of an item being incorrectly entered by the previous code.
		// Set the -1999 error so the code above us can prompt the user again.
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -1999 userInfo: nil];		
	}
	
	return [password autorelease];
}

+ (void) storeUsername: (NSString *) username andPassword: (NSString *) password forServiceName: (NSString *) serviceName updateExisting: (BOOL) updateExisting error: (NSError **) error {		
	if (!username || !password || !serviceName) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return;
	}
	
	// See if we already have a password entered for these credentials.
	
	NSString *existingPassword = [[self class] getPasswordForUsername: username andServiceName: serviceName error: error];
	
	if ([*error code] == -1999) {
		// There is an existing entry without a password properly stored (possibly as a result of the previous incorrect version of this code.
		// Delete the existing item before moving on entering a correct one.
		
		*error = nil;
		
		[self deleteItemForUsername: username andServiceName: serviceName error: error];
		
		if ([*error code] != noErr) {
			return;
		}
	}
	else if ([*error code] != noErr) {
		return;
	}
	
	*error = nil;
	
	OSStatus status = noErr;
	
	if (existingPassword) {
		// We have an existing, properly entered item with a password.
		// Update the existing item.
		
		if (![existingPassword isEqualToString:password] && updateExisting) {
			//Only update if we're allowed to update existing.  If not, simply do nothing.
			
			NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, 
							  kSecAttrService, 
							  kSecAttrLabel, 
							  kSecAttrAccount, 
							  nil] autorelease];
			
			NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, 
								 serviceName,
								 serviceName,
								 username,
								 nil] autorelease];
			
			NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];			
			
			status = SecItemUpdate((CFDictionaryRef) query, (CFDictionaryRef) [NSDictionary dictionaryWithObject: [password dataUsingEncoding: NSUTF8StringEncoding] forKey: (NSString *) kSecValueData]);
		}
	}
	else {
		// No existing entry (or an existing, improperly entered, and therefore now
		// deleted, entry).  Create a new entry.
		
		NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, 
						  kSecAttrService, 
						  kSecAttrLabel, 
						  kSecAttrAccount, 
						  kSecValueData, 
						  nil] autorelease];
		
		NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, 
							 serviceName,
							 serviceName,
							 username,
							 [password dataUsingEncoding: NSUTF8StringEncoding],
							 nil] autorelease];
		
		NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];			
		
		status = SecItemAdd((CFDictionaryRef) query, NULL);
	}
	
	if (status != noErr) {
		// Something went wrong with adding the new item. Return the Keychain error code.
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];
	}
}

+ (void) deleteItemForUsername: (NSString *) username andServiceName: (NSString *) serviceName error: (NSError **) error {
	if (!username || !serviceName) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: -2000 userInfo: nil];
		return;
	}
	
	*error = nil;
	
	NSArray *keys = [[[NSArray alloc] initWithObjects: (NSString *) kSecClass, kSecAttrAccount, kSecAttrService, kSecReturnAttributes, nil] autorelease];
	NSArray *objects = [[[NSArray alloc] initWithObjects: (NSString *) kSecClassGenericPassword, username, serviceName, kCFBooleanTrue, nil] autorelease];
	
	NSDictionary *query = [[[NSDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
	
	OSStatus status = SecItemDelete((CFDictionaryRef) query);
	
	if (status != noErr) {
		*error = [NSError errorWithDomain: SFHFKeychainUtilsErrorDomain code: status userInfo: nil];		
	}
}

#endif

@end


@implementation QFSecurity

static NSData *myCertData=nil;

static QFSecurity *sharedQFSecurity=nil;

static NSMutableDictionary *dictSec;

static const char hexdigits[] = "0123456789ABCDEF";

static NSArray *sharedKeys=nil;

+(NSArray*)keysShouldSave{
	if (sharedKeys==nil) {
		sharedKeys=[[NSArray arrayWithObjects:
					 kQFAppID,
					 kQFTerminalID,
					 kQFPSAMID,
					 kQFMerchantID, 
					 kQFMerchantAccount,
					 kQFSwipCount,
					 kQFClientSN,
					 nil] retain];
	}
	return sharedKeys;
}

+(void)setObject:(id)obj forKey:(id)key{
	if ([[QFSecurity keysShouldSave] containsObject:key]) {
		NSError *error=nil;
		if (obj) {
			[QFSecurity storeUsername:key andPassword:obj forServiceName:@"QFSecurity" updateExisting:YES error:&error];
		}else{
			[QFSecurity deleteItemForUsername:key andServiceName:@"QFSecurity" error:&error];
		}
		
		if (error && [error code]!=-25300) {
			NSLog(@"安全数据存储发生错误! key:%@",key);
		}
	}else{
		if (obj) {
			[dictSec setObject:obj forKey:key];
		}else{
			[dictSec removeObjectForKey:key];
		}
	}
	
}
+(id)  getObjectForKey:(id)key{
	if ([[QFSecurity keysShouldSave] containsObject:key]) {
		NSError *error=nil;
		return [QFSecurity getPasswordForUsername:key andServiceName:@"QFSecurity" error:&error];
	}
	return [dictSec objectForKey:key];
}



unsigned char strToChar (char a, char b);
unsigned char strToChar (char a, char b)
{
    char encoder[3] = {'\0','\0','\0'};
    encoder[0] = a;
    encoder[1] = b;
    return (char) strtol(encoder,NULL,16);
}

+ (NSData *) dataFromHexString:(NSString*)hexString{
    const char * bytes = [hexString UTF8String];
    NSUInteger length = strlen(bytes);
    unsigned char * r = (unsigned char *) malloc(length / 2 + 1);
    unsigned char * index = r;
	
    while ((*bytes) && (*(bytes +1))) {
		char a=(*bytes);
		char b=(*(bytes +1));
        *index = strToChar(a, b);
        index++;
        bytes+=2;
    }
    *index = '\0';
	
    NSData * result = [NSData dataWithBytes: r length: length / 2];
    free(r);
	
    return result;
}
+(NSString*)hexStringFromData:(NSData*)data{
	int numBytes = [data length];
	const unsigned char* bytes = [data bytes];
	char *strbuf = (char *)malloc(numBytes * 2 + 1);
	char *hex = strbuf;
	NSString *hexBytes = nil;
	
	for (int i = 0; i<numBytes; ++i){
		const unsigned char c = *bytes++;
		*hex++ = hexdigits[(c >> 4) & 0xF];
		*hex++ = hexdigits[(c ) & 0xF];
	}
    
	*hex = 0;
	hexBytes = [NSString stringWithUTF8String:strbuf];
	free(strbuf);
	return hexBytes;
}


+(NSData*)desData:(NSData*)adata withData:(NSData*)bdata flag:(BOOL)enOrDe{
	///DES
	CCCryptorStatus ccStatus;
	
	char *bufferPtr1 = NULL;    
    size_t bufferPtrSize1 = 0;    
    size_t movedBytes1 = 0;    
    
	bufferPtrSize1 = (8 + kCCBlockSizeDES) & ~(kCCBlockSizeDES -1);    
    bufferPtr1 = malloc(bufferPtrSize1 * sizeof(char));    
    memset(bufferPtr1, 0x00, bufferPtrSize1); 
	
	CCOperation opt=enOrDe?kCCEncrypt:kCCDecrypt;
	
    ccStatus = CCCrypt(opt, // CCOperation op    
                       kCCAlgorithmDES, // CCAlgorithm alg    
                       kCCOptionECBMode,
                       [bdata bytes], // const void *key    
                       kCCKeySizeDES, //密钥长度
                       NULL, // const void *iv    
                       [adata bytes], // const void *dataIn
                       [adata length],  // size_t dataInLength    
                       (void *)bufferPtr1, // void *dataOut    
                       bufferPtrSize1,     // size_t dataOutAvailable 
                       &movedBytes1);      // size_t *dataOutMoved
	
    if (ccStatus!=kCCSuccess) {
        NSString *result;
        
        switch (ccStatus) {
            case kCCParamError:
                result=@"PARAM ERROR";
                break;
            case kCCBufferTooSmall:
                result=@"BUFFER TOO SMALL";
                break;
				
            case kCCMemoryFailure:
                result=@"MEMORY FAILURE";
                break;
				
            case kCCAlignmentError:
                result=@"ALIGNMENT";
                break;
            case kCCDecodeError:
                result=@"DECODE ERROR";
                break;
                
            default:
                result=@"UNIMPLEMENTED";
                break;
        }
        //QFAssert(NO, result, nil);
		//ULog(@"解密失败：%@",result);
        return nil;
    }
	NSData *mad=[NSData dataWithBytes:bufferPtr1 length:bufferPtrSize1];
	return mad;
}

+(NSData*)XOR:(NSData*)indata useBytesLength:(int)l{
	//char outData[l];
	
	char * inData=(char*)[indata bytes];
	int dataLen=[indata length];
	
    int padding_len = 8 - dataLen % 8;
    int len = dataLen + padding_len;
	
    char * payload1 = (char *)malloc(len);
    //payload 负责装载纯数据
    for (int i = 0; i < dataLen; i++) {
        payload1[i] = inData[i];
        //NSLog(@"%x",payload1[i]);
    }
    // 将补齐的区域都填充为0
    for (int i = dataLen; i < len; i++) {
        payload1[i] = 0;
    }
    
    char payload[] = { 0,0,0,0,0,0,0,0};
    for (int i = 0; i < len; i++) {
        payload[i % 8] =  (payload[i % 8] ^ payload1[i]);
    }
    
    
    
//	int	i , j;
//	
//	memset(initData, 0x00, sizeof(initData)/sizeof(char));
//	
//	for( i = 0 ;i < iNum ; i++)
//		for( j = 0 ; j < l ; j++ )
//			initData[ j ] ^= inData[ i * l + j ] ;
//	if( iRemain )
//		for( j = 0; j < iRemain ; j++ )
//			initData[ j ] ^= inData[ i * l + j ] ;
//	memcpy(outData, initData, l );
//
    
	
	NSData *tck=[NSData dataWithBytes:payload length:l];
	return tck;
}

+(NSData*)decodeTCK:(NSString*)entck withTID:(NSString*)tid{
	if (tid && entck) {
		
		NSData *tckdata=[QFSecurity dataFromHexString:entck];
		
		NSData *key=[QFSecurity dataFromHexString:[QFSecurity MD5:tid]];
		NSData *k1=[key subdataWithRange:NSMakeRange(0, 8)];
		NSData *k2=[key subdataWithRange:NSMakeRange(8, 8)];
		
		NSData *intermedia=tckdata;
		intermedia=[QFSecurity desData:intermedia withData:k1 flag:NO];
		intermedia=[QFSecurity desData:intermedia withData:k2 flag:YES];
		intermedia=[QFSecurity desData:intermedia withData:k1 flag:NO];
		
		if (intermedia) {
			return [QFSecurity XOR:intermedia useBytesLength:8];
		}
	}
	return nil;
}

+(NSData*)getTCK{
	NSData *mytck=nil;
    char deskey[8] = {0};
	
	NSString *tid=[QFSecurity getObjectForKey:kQFTerminalID];
	if (tid) {
		NSString *entck=[[NSUserDefaults standardUserDefaults] stringForKey:tid];
		
		mytck=[QFSecurity decodeTCK:entck withTID:tid];
	}
	if (mytck==nil) {
		//static  char DES_KEY[] ={0x11, 0x22,  0x33,  0x44,  0x55,  0x66,  0x77,  0x88, 0x11,  0x22,  0x33,  0x44,  0x55,  0x66,  0x77,  0x88};
        
        if (sizeof(DES_KEY) == 16) {
            
            for (int i = 0; i<8; i++) {
                deskey[i] = DES_KEY[i]^DES_KEY[i+8];
            }
            
        }
		
		mytck= [NSData dataWithBytes:deskey length:8];
	}
    
    
	return mytck;
}

+ (NSInteger)setDesKey:(NSString*)key
{
    if (key.length != 32)
        return 1;
    NSData * data = [self dataFromHexString:key];


    const char * des = [data bytes];
    for (int i = 0; i<16; i++) {
        DES_KEY[i] = des[i];
    }
    return 0;
}

+(NSString*)timestamp{
	return [NSString stringWithFormat:@"%0.0f",[[NSDate date] timeIntervalSince1970]];
}
+(NSString*)MD5:(NSString*)s{
    const char *cStr = [s UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    return [[NSString stringWithFormat:
             @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3], 
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString]; 
}

+(NSString *)SHA1:(NSString *)str {
    const char *cStr = [str UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cStr, strlen(cStr), result);
    NSString *s = [NSString  stringWithFormat:
                   @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   result[0], result[1], result[2], result[3], result[4],
                   result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11], result[12],
                   result[13], result[14], result[15],
                   result[16], result[17], result[18], result[19]
                   ];
    
    return s;
}

+(NSData*)publicKeyData{
	if (myCertData) {
		return myCertData;
	}
	NSString *newcerpath=[QFKit bundleFilePath:@"QFPay.der"];
	
    NSData *myCertData = [NSData dataWithContentsOfFile:newcerpath];
	//QFAssert(myCertData!=nil, @"无法加载公钥 %@", newcerpath);
	
	return myCertData;
}

/*
+(SecKeyRef)copyPublicKey{
	SecCertificateRef cert = SecCertificateCreateWithData (NULL, (CFDataRef)[QFSecurity publicKeyData]); 
    
    SecPolicyRef myPolicy = SecPolicyCreateBasicX509();
    SecTrustRef myTrust;
    OSStatus status = SecTrustCreateWithCertificates(cert, myPolicy, &myTrust);
    OSStatusCheck(status);
    SecTrustResultType trustResult;
	
	
	SecTrustSetAnchorCertificates (myTrust, ( CFArrayRef ) [ NSArray arrayWithObject :( id ) cert]);
	
	
	status =SecTrustEvaluate(myTrust, &trustResult);
    OSStatusCheck(status);
	
    
    SecKeyRef publicKey = SecTrustCopyPublicKey(myTrust);

	SecTrustSetAnchorCertificatesOnly (myTrust, NO );
    
	CFRelease(myPolicy);
    CFRelease(myTrust);
    CFRelease(cert);
    
	return publicKey;
}
*/
+(BOOL)verifyPublicKey{
	return YES;
	NSData *myCertData = [QFSecurity publicKeyData];
	if (myCertData!=nil) {
		SecCertificateRef cert = SecCertificateCreateWithData (NULL, (CFDataRef)myCertData); 
		if (cert) {
			CFStringRef certSummary = SecCertificateCopySubjectSummary(cert);  // 2
                                                                               //SLog(@"证书信息：%@",(NSString*)certSummary);
			
			CFRelease(certSummary);
			
			return YES;
		}else{
			//ULog(@"公钥证书数据错误");
		}

	}else{
        //	SLog(@"无法加载证书");
	}
	   
   
    return NO;
}

/*
+(NSData*)publicKeyEncpty:(NSData*)indata{
	QFError *error=nil;
	const uint8_t *bytes=[indata bytes];
	NSUInteger len=[indata length];
	
	SecKeyRef key = [QFSecurity copyPublicKey];
	
	size_t cipherBufferSize = SecKeyGetBlockSize(key);
	
	uint8_t *cipherBuffer = NULL;
	
	cipherBuffer = malloc(cipherBufferSize * sizeof(uint8_t));
	
	
	
	//NSData *plainTextBytes = indata;
	
	int blockSize = cipherBufferSize-12;
	
	int numBlock = (int)ceil(len / (double)blockSize);
	
	NSMutableData *encryptedData = [[[NSMutableData alloc] init] autorelease];
	
	for (int i=0; i<numBlock; i++) {
		memset((void *)cipherBuffer, 0x0, cipherBufferSize);
		int bufferSize = MIN(blockSize,len-i * blockSize);
		
		
//		OSStatus status = SecKeyEncrypt(key, 
//										kSecPaddingPKCS1,
//										bytes,
//										[buffer length], 
//										cipherBuffer,
//										&cipherBufferSize);
		
		OSStatus status = SecKeyEncrypt(key, 
										kSecPaddingPKCS1,
										bytes,
										bufferSize, 
										cipherBuffer,
										&cipherBufferSize);
		
		bytes+=bufferSize;
		
		if (status == noErr){
			
			NSData *encryptedBytes = [[[NSData alloc]
									   
									   initWithBytes:(const void *)cipherBuffer
									   
									   length:cipherBufferSize] autorelease];
			
			[encryptedData appendData:encryptedBytes];
			
		}else{
			
			error = [QFError errorWithDomain:QFErrorDomainClient andCode:status];
			
			break;
			
		}
		
	}
	CFRelease(key);
	if (cipherBuffer)free(cipherBuffer);
	
	
	if (error) {
		NSException *ex=[NSException exceptionWithError:error];
		[ex raise];
	}
	
	NSLog(@"公钥加密数据(%dB)",[encryptedData length]);

	return encryptedData;
}
 
 */

+(BOOL)verifyMAC:(NSString*)mac withString:(NSString*)string{
    return YES;
    
//    NSString *should=[QFSecurity MAC:[string dataUsingEncoding:NSUTF8StringEncoding] withKey:[QFSecurity key]];
//    return [should isEqualToString:mac];
}


#pragma mark -
#pragma mark 3DES
#pragma mark -

+(NSData*)MACData:(NSData*)indata{
	/*char outData[8];
	
    char * inData=(char*)[indata bytes];
	int dataLen=[indata length];
	///XOR
	char	initData[ 8 + 1 ];	
	uint 	iRemain = dataLen % 8 ;
	uint	iNum = dataLen / 8;
	
	int	i , j ;
	
	memset(initData, 0x00, sizeof(initData));
	
	for( i = 0 ;i < iNum ; i++)
		for( j = 0 ; j < 8 ; j++ )
			initData[ j ] ^= inData[ i * 8 + j ] ;
	if( iRemain )
		for( j = 0; j < iRemain ; j++ )
			initData[ j ] ^= inData[ i * 8 + j ] ;
	memcpy(outData, initData, 8 );
	*/
    
	char *outData=(char*)[[QFSecurity XOR:indata useBytesLength:8] bytes];
	
	///DES
	CCCryptorStatus ccStatus;
	
	char *bufferPtr1 = NULL;    
    size_t bufferPtrSize1 = 0;    
    size_t movedBytes1 = 0;    
    
	bufferPtrSize1 = (8 + kCCBlockSizeDES) & ~(kCCBlockSizeDES -1);    
    
    bufferPtr1 = malloc(bufferPtrSize1 * sizeof(char));    
    
    memset(bufferPtr1, 0x00, bufferPtrSize1);    
    
    ccStatus = CCCrypt(kCCEncrypt, // CCOperation op    
                       kCCAlgorithmDES, // CCAlgorithm alg    
                       kCCOptionPKCS7Padding,
                       [[QFSecurity getTCK]bytes], // const void *key    
                       kCCKeySizeDES, //密钥长度
                       NULL, // const void *iv    
                       outData, // const void *dataIn
                       8,  // size_t dataInLength    
                       (void *)bufferPtr1, // void *dataOut    
                       bufferPtrSize1,     // size_t dataOutAvailable 
                       &movedBytes1);      // size_t *dataOutMoved
	
    if (ccStatus!=kCCSuccess) {
        NSString *result;
        
        switch (ccStatus) {
            case kCCParamError:
                result=@"PARAM ERROR";
                break;
            case kCCBufferTooSmall:
                result=@"BUFFER TOO SMALL";
                break;
				
            case kCCMemoryFailure:
                result=@"MEMORY FAILURE";
                break;
				
            case kCCAlignmentError:
                result=@"ALIGNMENT";
                break;
            case kCCDecodeError:
                result=@"DECODE ERROR";
                break;
                
            default:
                result=@"UNIMPLEMENTED";
                break;
        }
        //QFAssert(NO, result, nil);
        //	ULog(@"解密失败：%@",result);
        return nil;
    }
	NSData *mad=[NSData dataWithBytes:bufferPtr1 length:bufferPtrSize1];
    //NSLog(@"MAC: %@",[QFSecurity hexStringFromData:mad]);
	return mad;
}

+(NSData*)cryptData:(NSData*)indata withKey:(NSString*)key flag:(CCOperation)encryptOrDecrypt{
    CCCryptorStatus ccStatus;
     
	const char *ckey;
	if ([key isKindOfClass:[NSString class]]) {
		 ckey = [key cStringUsingEncoding:NSUTF8StringEncoding];
	}else if ([key isKindOfClass:[NSData class]]){
		ckey =[(NSData*)key bytes];
	}
   
    
	uint8_t *bufferPtr1 = NULL;    
    size_t bufferPtrSize1 = 0;
    size_t movedBytes1 = 0;    
    
	bufferPtrSize1 = ([indata length] + kCCBlockSize3DES) & ~(kCCBlockSize3DES -1);    
    bufferPtr1 = malloc(bufferPtrSize1 * sizeof(uint8_t));    
    memset((void *)bufferPtr1, 0x00, bufferPtrSize1);    
    ccStatus = CCCrypt(encryptOrDecrypt, // CCOperation op    
                       kCCAlgorithm3DES, // CCAlgorithm alg    
                       kCCOptionECBMode,
                       ckey, // const void *key    
                       kCCKeySize3DES, //密钥长度
                       NULL, // 偏移向量    
                       [indata bytes], // const void *dataIn
                       [indata length],  // size_t dataInLength    
                       (void *)bufferPtr1, // void *dataOut    
                       bufferPtrSize1,     // size_t dataOutAvailable 
                       &movedBytes1);      // size_t *dataOutMoved

	
    if (ccStatus!=kCCSuccess) {
        NSString *result;
        
        switch (ccStatus) {
            case kCCParamError:
                result=@"PARAM ERROR";
                break;
            case kCCBufferTooSmall:
                result=@"BUFFER TOO SMALL";
                break;

            case kCCMemoryFailure:
                result=@"MEMORY FAILURE";
                break;

            case kCCAlignmentError:
                result=@"ALIGNMENT";
                break;
            case kCCDecodeError:
                result=@"DECODE ERROR";
                break;
                
            default:
                result=@"UNIMPLEMENTED";
                break;
        }
        //QFAssert(NO, result, nil);
		//SLog(@"解密失败：%@",result);
        return nil;
    }
    
    return [NSData dataWithBytes:(const void *)bufferPtr1 length:(NSUInteger)movedBytes1];
}

+(NSData*)encryptData:(NSData*)indata withKey:(NSString*)key{
    NSData *data=[QFSecurity cryptData:indata withKey:key flag:kCCEncrypt];
    return data;
}
+(NSData*)decryptData:(NSData*)indata withKey:(NSString*)key{
    NSData *data=[QFSecurity cryptData:indata withKey:key flag:kCCDecrypt];
    return data;
}

+(void)keepCertData:(NSData*)cerData{
	if (myCertData) {
		[myCertData release];
		myCertData=nil;
	}
	if (cerData!=nil) {
		myCertData=[[NSData alloc] initWithData:cerData];
	}
	
}

#pragma mark -
#pragma mark Hankshake
#pragma mark -

+(QFSecurity*)shared{
	if (sharedQFSecurity==nil) {
		dictSec=[NSMutableDictionary new];
		sharedQFSecurity=[QFSecurity new];
	}
	return sharedQFSecurity;
}


@end

@implementation Base64
#define ArrayLength(x) (sizeof(x)/sizeof(*(x)))

static char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static char decodingTable[128];

+ (void) initialize {
	if (self == [Base64 class]) {
		memset(decodingTable, 0, ArrayLength(decodingTable));
		for (NSInteger i = 0; i < ArrayLength(encodingTable); i++) {
			decodingTable[encodingTable[i]] = i;
		}
	}
}


+ (NSString*) encode:(const uint8_t*) input length:(NSInteger) length {
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
	
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
			
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
		
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    encodingTable[(value >> 18) & 0x3F];
        output[index + 1] =                    encodingTable[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? encodingTable[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? encodingTable[(value >> 0)  & 0x3F] : '=';
    }
	
    return [[[NSString alloc] initWithData:data
                                  encoding:NSASCIIStringEncoding] autorelease];
}


+ (NSString*) encode:(NSData*) rawBytes {
    return [self encode:(const uint8_t*) rawBytes.bytes length:rawBytes.length];
}


+ (NSData*) decode:(const char*) string length:(NSInteger) inputLength {
	if ((string == NULL) || (inputLength % 4 != 0)) {
		return nil;
	}
	
	while (inputLength > 0 && string[inputLength - 1] == '=') {
		inputLength--;
	}
	
	NSInteger outputLength = inputLength * 3 / 4;
	NSMutableData* data = [NSMutableData dataWithLength:outputLength];
	uint8_t* output = data.mutableBytes;
	
	NSInteger inputPoint = 0;
	NSInteger outputPoint = 0;
	while (inputPoint < inputLength) {
		char i0 = string[inputPoint++];
		char i1 = string[inputPoint++];
		char i2 = inputPoint < inputLength ? string[inputPoint++] : 'A'; /* 'A' will decode to \0 */
		char i3 = inputPoint < inputLength ? string[inputPoint++] : 'A';
		
		output[outputPoint++] = (decodingTable[i0] << 2) | (decodingTable[i1] >> 4);
		if (outputPoint < outputLength) {
			output[outputPoint++] = ((decodingTable[i1] & 0xf) << 4) | (decodingTable[i2] >> 2);
		}
		if (outputPoint < outputLength) {
			output[outputPoint++] = ((decodingTable[i2] & 0x3) << 6) | decodingTable[i3];
		}
	}
	
	return data;
}


+ (NSData*) decode:(NSString*) string {
	return [self decode:[string cStringUsingEncoding:NSASCIIStringEncoding] length:string.length];
}




@end
