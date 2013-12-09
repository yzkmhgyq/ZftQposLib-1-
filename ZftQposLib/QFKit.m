//
//  QFKit.m
//  QFKit
//
//  Created by Travis on 11-8-19.
//  Copyright (c) 2011年 QFPay. All rights reserved.
//

#import "QFKit.h"
#import "QFSecurity.h"
#import "QFTransaction.h"
static QFKit *sharedQFKit = nil; 
static NSBundle *QFKitBundle=nil;
void QFAlert(NSString *title, NSString *msg, NSString *buttonText){
	UIAlertView *av=[[UIAlertView alloc] initWithTitle:title
											   message:msg 
											  delegate:nil 
									 cancelButtonTitle:buttonText 
									 otherButtonTitles:nil];
	[av show];
	[av release];
}


//执行后 出现问题
void QFEvent(NSString *eventName,id data){
	[[NSNotificationCenter defaultCenter] postNotificationName:eventName object:data];
}
void QFListenEvent(NSString *eventName,id target,SEL method){
	[[NSNotificationCenter defaultCenter] addObserver:target selector:method name:eventName object:nil];
}
void QFForgetEvent(NSString *eventName,id target){
	[[NSNotificationCenter defaultCenter] removeObserver:target name:eventName object:nil];
}

NSString *QFString(NSString *key,NSString *table){
	NSBundle *bundle;
	bundle=[QFKit bundle];
	NSString *s= NSLocalizedStringFromTableInBundle(key, table, bundle, nil);
	//s=[bundle localizedStringForKey:key value:nil table:table];
	if ([key isEqualToString:s]) {
		return nil;
	}
	return s;
}


@interface QFKit(Private)
	
-(BOOL)refreshGPS_;

@end

@implementation QFKit(Private)
- (void)dealloc {
    [locationMgr release];
    [super dealloc];
}
-(BOOL)refreshGPS_{
	BOOL res=NO;
	
	if ([CLLocationManager locationServicesEnabled]) {
		[locationMgr startUpdatingLocation];
		res=YES;
	}
	
	return res;
}
/*
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	CLLocationCoordinate2D coor= newLocation.coordinate;
	[QFSecurity setObject:[NSNumber numberWithDouble:coor.longitude] forKey:kQFGPSLon];
	[QFSecurity setObject:[NSNumber numberWithDouble:coor.latitude]  forKey:kQFGPSLat];
	
	[locationMgr stopUpdatingLocation];
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
	[QFSecurity setObject:[NSNumber numberWithInt:0] forKey:kQFGPSLon];
	[QFSecurity setObject:[NSNumber numberWithInt:0] forKey:kQFGPSLat];
	[locationMgr stopUpdatingLocation];
	
	if ([[error domain] isEqualToString: kCLErrorDomain] && [error code] == kCLErrorDenied) {
        QFError *e=[QFError errorWithDomain:QFErrorDomainClient andCode:QFClientErrorForbidGPS];
		[e present];
    }
	
}
*/
@end



@implementation QFKit
@synthesize shouldActiveDevice,timeOffset;
@synthesize shouldRefresh;
@synthesize shouldBlockDeviceAlertView;

+(NSBundle*)bundle{
	if (QFKitBundle==nil) {
		NSString *path=[[NSBundle bundleForClass:[QFKit class]] pathForResource:@"QFResource" ofType:@"bundle"];
		QFKitBundle=[[NSBundle bundleWithPath:path] retain];
		
	}
	return QFKitBundle;
}

+(NSString*)bundleFilePath:(NSString*)fileNameOrRelPath{
	NSString *path=[[QFKit bundle] pathForResource:fileNameOrRelPath ofType:nil];
	//QFAssert(path!=nil, @"找不到资源位置 %@", path);
	return path;
}

+(NSString*)dataFilePath:(NSString*)fileNameOrRelPath{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [paths objectAtIndex:0];
	//QFAssert(path!=nil, @"找不到数据位置 %@", path);
	return [path stringByAppendingPathComponent:fileNameOrRelPath];
}

+(QFKit *)kit {             
    @synchronized(self) {                            
        if (sharedQFKit == nil) {             
            sharedQFKit = [[self alloc] init];                                               
            // QFAssert((sharedQFKit != nil), @"didn't catch singleton allocation");
		
        }                                              
    }                                                
    return sharedQFKit;                     
}



+(BOOL)refreshGPS{
	return [[QFKit kit] refreshGPS_];
}




+ (id)allocWithZone:(NSZone *)zone {               
    @synchronized(self) {                            
        if (sharedQFKit == nil) {             
            sharedQFKit = [super allocWithZone:zone]; 
            return sharedQFKit;                 
        }                                              
    }                                                
    
    // QFAssert(NO, @"use the singleton API, not alloc+init");
    return nil;                                      
}

+(void)reset{
	for (NSString *key in [QFSecurity keysShouldSave]) {
		[QFSecurity setObject:nil forKey:key];
	}
	NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
	//sharedQFKit.shouldActiveDevice=YES;
}

- (id)init {
    self = [super init];
    if (self) {
		//初始化加密引擎
		[QFSecurity shared];
        
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"NeedResetData"]) {
			[QFKit reset];
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NeedResetData"];
		}
		
        UIDevice *dvc=[UIDevice currentDevice];
		
		[QFSecurity setObject:[dvc model] forKey:kQFPhoneModel];
		[QFSecurity setObject:[dvc systemName] forKey:kQFPhoneOS];
		[QFSecurity setObject:[dvc systemVersion] forKey:kQFPhoneOSVersion];
		
		///程序版本号
		NSDictionary *info= [[NSBundle mainBundle] infoDictionary];
        NSString *b=[info objectForKey:@"CFBundleShortVersionString"];
        NSString *v=[info objectForKey:@"CFBundleVersion"];
        [QFSecurity setObject:[NSString stringWithFormat:@"%@.%@",b,v] forKey:kQFAppVersion];
		
        ///HASH版本号
		NSString *hash=[info objectForKey:@"CFBundleGitHashString"];
		
		if ([hash length]>7) {
			hash=[hash substringToIndex:7];
		}else{
			hash=@"ILLEGAL CLIENT";
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:hash forKey:@"HashVersion"];

		
		if ([QFSecurity getObjectForKey:kQFPhoneID]==nil) {
			//[QFSecurity setObject:[QFCM getMacAddress] forKey:kQFPhoneID];
		}
		
		locationMgr=[[CLLocationManager alloc] init];
		locationMgr.delegate=self;

		timeOffset=0;
		shouldRefresh=YES;
		
		///用于测试
#if TARGET_IPHONE_SIMULATOR	
		///模拟器 造一些假数据
		[QFSecurity setObject:@"00191220111228001013" forKey:kQFTerminalID];
		[QFSecurity setObject:@"3130303030303036" forKey:kQFPSAMID];
#else
		
		NSString *currTID=[QFSecurity getObjectForKey:kQFTerminalID];
		NSString *tck;
		
		if (currTID) {
			tck=[[NSUserDefaults standardUserDefaults] objectForKey:currTID];
		}else{
			NSLog(@"没有TID!!!!");
		}
		
		//shouldActiveDevice=(tck==nil || [QFSecurity getObjectForKey:kQFAppID]==nil );
#endif
		
		//初始化刷卡器驱动
		[QFDevice shared];

		[QFSecurity setObject:@"0000" forKey:kQFAppID];

#if QF_DEBUG_MODE>0
		float w=0;
#	if QF_DEBUG_MODE==1
		w=85;
#	elif QF_DEBUG_MODE==2
		w=320;
#	endif
		
		UIWindow *nw=[[UIWindow alloc] initWithFrame:CGRectMake(0, 0, w, 20)];
		nw.backgroundColor=[UIColor blackColor];
		nw.windowLevel=UIWindowLevelAlert;
		UILabel *testLable=[[UILabel alloc] initWithFrame:CGRectMake(0, -1, w, 20)];
		testLable.font=[UIFont systemFontOfSize:8];
		testLable.textColor=[UIColor whiteColor];
		testLable.numberOfLines=2;
		testLable.backgroundColor=[UIColor clearColor];
		testLable.text=[NSString stringWithFormat:@"QF DEBUG: %i\nAppVer: 1.0",QF_DEBUG_MODE];
		[nw insertSubview:[testLable autorelease] atIndex:2];
		[nw makeKeyAndVisible];
		[nw resignKeyWindow];
		
		NSOperationQueue *opQ = [[NSOperationQueue alloc] init];
		[[NSNotificationCenter defaultCenter] addObserverForName:@"QFDebugLog"
														  object:nil queue:opQ
													  usingBlock:^(NSNotification *notif) {
														  testLable.text=[notif object];
													  }];
		
#endif
    }
    return self;
}

@end


@protocol SBJsonParser

/**
 @brief Return the object represented by the given string.
 
 Returns the object represented by the passed-in string or nil on error. The returned object can be
 a string, number, boolean, null, array or dictionary.
 
 @param repr the json string to parse
 */
- (id)objectWithString:(NSString *)repr;

@end
@protocol SBJsonWriter

/**
 @brief Whether we are generating human-readable (multiline) JSON.
 
 Set whether or not to generate human-readable JSON. The default is NO, which produces
 JSON without any whitespace. (Except inside strings.) If set to YES, generates human-readable
 JSON with linebreaks after each array value and dictionary key/value pair, indented two
 spaces per nesting level.
 */
@property BOOL humanReadable;

/**
 @brief Whether or not to sort the dictionary keys in the output.
 
 If this is set to YES, the dictionary keys in the JSON output will be in sorted order.
 (This is useful if you need to compare two structures, for example.) The default is NO.
 */
@property BOOL sortKeys;

/**
 @brief Return JSON representation (or fragment) for the given object.
 
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p *error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 
 */
- (NSString*)stringWithObject:(id)value;

@end


enum {
    EUNSUPPORTED = 1,
    EPARSENUM,
    EPARSE,
    EFRAGMENT,
    ECTRL,
    EUNICODE,
    EDEPTH,
    EESCAPE,
    ETRAILCOMMA,
    ETRAILGARBAGE,
    EEOF,
    EINPUT
};

/**
 @brief Common base class for parsing & writing.
 
 This class contains the common error-handling code and option between the parser/writer.
 */
@interface SBJsonBase : NSObject {
    NSMutableArray *errorTrace;
	
@protected
    NSUInteger depth, maxDepth;
}

/**
 @brief The maximum recursing depth.
 
 Defaults to 512. If the input is nested deeper than this the input will be deemed to be
 malicious and the parser returns nil, signalling an error. ("Nested too deep".) You can
 turn off this security feature by setting the maxDepth value to 0.
 */
@property NSUInteger maxDepth;

/**
 @brief Return an error trace, or nil if there was no errors.
 
 Note that this method returns the trace of the last method that failed.
 You need to check the return value of the call you're making to figure out
 if the call actually failed, before you know call this method.
 */
@property(copy,readonly) NSArray* errorTrace;

/// @internal for use in subclasses to add errors to the stack trace
- (void)addErrorWithCode:(NSUInteger)code description:(NSString*)str;

/// @internal for use in subclasess to clear the error before a new parsing attempt
- (void)clearErrorTrace;

@end

@interface SBJsonParser : SBJsonBase <SBJsonParser> {
    
@private
    const char *c;
}

@end

// don't use - exists for backwards compatibility with 2.1.x only. Will be removed in 2.3.
@interface SBJsonParser (Private)
- (id)fragmentWithString:(id)repr;
@end

@interface SBJsonWriter : SBJsonBase <SBJsonWriter> {
	
@private
    BOOL sortKeys, humanReadable;
}

@end

// don't use - exists for backwards compatibility. Will be removed in 2.3.
@interface SBJsonWriter (Private)
- (NSString*)stringWithFragment:(id)value;
@end

/**
 @brief Allows generation of JSON for otherwise unsupported classes.
 
 If you have a custom class that you want to create a JSON representation for you can implement
 this method in your class. It should return a representation of your object defined
 in terms of objects that can be translated into JSON. For example, a Person
 object might implement it like this:
 
 @code
 - (id)jsonProxyObject {
 return [NSDictionary dictionaryWithObjectsAndKeys:
 name, @"name",
 phone, @"phone",
 email, @"email",
 nil];
 }
 @endcode
 
 */
@interface NSObject (SBProxyForJson)
- (id)proxyForJson;
@end


@interface SBJSON : SBJsonBase <SBJsonParser, SBJsonWriter> {
	
@private    
    SBJsonParser *jsonParser;
    SBJsonWriter *jsonWriter;
}


/// Return the fragment represented by the given string
- (id)fragmentWithString:(NSString*)jsonrep
                   error:(NSError**)error;

/// Return the object represented by the given string
- (id)objectWithString:(NSString*)jsonrep
                 error:(NSError**)error;

/// Parse the string and return the represented object (or scalar)
- (id)objectWithString:(id)value
           allowScalar:(BOOL)x
    			 error:(NSError**)error;


/// Return JSON representation of an array  or dictionary
- (NSString*)stringWithObject:(id)value
                        error:(NSError**)error;

/// Return JSON representation of any legal JSON value
- (NSString*)stringWithFragment:(id)value
                          error:(NSError**)error;

/// Return JSON representation (or fragment) for the given object
- (NSString*)stringWithObject:(id)value
                  allowScalar:(BOOL)x
    					error:(NSError**)error;


@end


@implementation SBJSON

- (id)init {
    self = [super init];
    if (self) {
        jsonWriter = [SBJsonWriter new];
        jsonParser = [SBJsonParser new];
        [self setMaxDepth:512];
		
    }
    return self;
}

- (void)dealloc {
    [jsonWriter release];
    [jsonParser release];
    [super dealloc];
}

#pragma mark Writer 


- (NSString *)stringWithObject:(id)obj {
    NSString *repr = [jsonWriter stringWithObject:obj];
    if (repr)
        return repr;
    
    [errorTrace release];
    errorTrace = [[jsonWriter errorTrace] mutableCopy];
    return nil;
}

/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p *error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 @param allowScalar wether to return json fragments for scalar objects
 @param error used to return an error by reference (pass NULL if this is not desired)
 
 @deprecated Given we bill ourselves as a "strict" JSON library, this method should be removed.
 */
- (NSString*)stringWithObject:(id)value allowScalar:(BOOL)allowScalar error:(NSError**)error {
    
    NSString *json = allowScalar ? [jsonWriter stringWithFragment:value] : [jsonWriter stringWithObject:value];
    if (json)
        return json;
	
    [errorTrace release];
    errorTrace = [[jsonWriter errorTrace] mutableCopy];
    
    if (error)
        *error = [errorTrace lastObject];
    return nil;
}

/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 @param error used to return an error by reference (pass NULL if this is not desired)
 
 @deprecated Given we bill ourselves as a "strict" JSON library, this method should be removed.
 */
- (NSString*)stringWithFragment:(id)value error:(NSError**)error {
    return [self stringWithObject:value
                      allowScalar:YES
                            error:error];
}

/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p error can be interrogated to find the cause of the error.
 
 @param value a NSDictionary or NSArray instance
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (NSString*)stringWithObject:(id)value error:(NSError**)error {
    return [self stringWithObject:value
                      allowScalar:NO
                            error:error];
}

#pragma mark Parsing

- (id)objectWithString:(NSString *)repr {
    id obj = [jsonParser objectWithString:repr];
    if (obj)
        return obj;
	
    [errorTrace release];
    errorTrace = [[jsonParser errorTrace] mutableCopy];
    
    return nil;
}

/**
 Returns the object represented by the passed-in string or nil on error. The returned object can be
 a string, number, boolean, null, array or dictionary.
 
 @param value the json string to parse
 @param allowScalar whether to return objects for JSON fragments
 @param error used to return an error by reference (pass NULL if this is not desired)
 
 @deprecated Given we bill ourselves as a "strict" JSON library, this method should be removed.
 */
- (id)objectWithString:(id)value allowScalar:(BOOL)allowScalar error:(NSError**)error {
	
    id obj = allowScalar ? [jsonParser fragmentWithString:value] : [jsonParser objectWithString:value];
    if (obj)
        return obj;
    
    [errorTrace release];
    errorTrace = [[jsonParser errorTrace] mutableCopy];
	
    if (error)
        *error = [errorTrace lastObject];
    return nil;
}

/**
 Returns the object represented by the passed-in string or nil on error. The returned object can be
 a string, number, boolean, null, array or dictionary.
 
 @param repr the json string to parse
 @param error used to return an error by reference (pass NULL if this is not desired)
 
 @deprecated Given we bill ourselves as a "strict" JSON library, this method should be removed. 
 */
- (id)fragmentWithString:(NSString*)repr error:(NSError**)error {
    return [self objectWithString:repr
                      allowScalar:YES
                            error:error];
}

/**
 Returns the object represented by the passed-in string or nil on error. The returned object
 will be either a dictionary or an array.
 
 @param repr the json string to parse
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (id)objectWithString:(NSString*)repr error:(NSError**)error {
    return [self objectWithString:repr
                      allowScalar:NO
                            error:error];
}



#pragma mark Properties - parsing

- (NSUInteger)maxDepth {
    return jsonParser.maxDepth;
}

- (void)setMaxDepth:(NSUInteger)d {
	jsonWriter.maxDepth = jsonParser.maxDepth = d;
}


#pragma mark Properties - writing

- (BOOL)humanReadable {
    return jsonWriter.humanReadable;
}

- (void)setHumanReadable:(BOOL)x {
    jsonWriter.humanReadable = x;
}

- (BOOL)sortKeys {
    return jsonWriter.sortKeys;
}

- (void)setSortKeys:(BOOL)x {
    jsonWriter.sortKeys = x;
}

@end

static NSString * SBJSONErrorDomain = @"im.imi.JSON.ErrorDomain";


@implementation SBJsonBase

@synthesize errorTrace;
@synthesize maxDepth;

- (id)init {
    self = [super init];
    if (self)
        self.maxDepth = 512;
    return self;
}

- (void)dealloc {
    [errorTrace release];
    [super dealloc];
}

- (void)addErrorWithCode:(NSUInteger)code description:(NSString*)str {
    NSDictionary *userInfo;
    if (!errorTrace) {
        errorTrace = [NSMutableArray new];
        userInfo = [NSDictionary dictionaryWithObject:str forKey:NSLocalizedDescriptionKey];
        
    } else {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    str, NSLocalizedDescriptionKey,
                    [errorTrace lastObject], NSUnderlyingErrorKey,
                    nil];
    }
    
    NSError *error = [NSError errorWithDomain:SBJSONErrorDomain code:code userInfo:userInfo];
	
    [self willChangeValueForKey:@"errorTrace"];
    [errorTrace addObject:error];
    [self didChangeValueForKey:@"errorTrace"];
}

- (void)clearErrorTrace {
    [self willChangeValueForKey:@"errorTrace"];
    [errorTrace release];
    errorTrace = nil;
    [self didChangeValueForKey:@"errorTrace"];
}

@end

@interface SBJsonParser ()

- (BOOL)scanValue:(NSObject **)o;

- (BOOL)scanRestOfArray:(NSMutableArray **)o;
- (BOOL)scanRestOfDictionary:(NSMutableDictionary **)o;
- (BOOL)scanRestOfNull:(NSNull **)o;
- (BOOL)scanRestOfFalse:(NSNumber **)o;
- (BOOL)scanRestOfTrue:(NSNumber **)o;
- (BOOL)scanRestOfString:(NSMutableString **)o;

// Cannot manage without looking at the first digit
- (BOOL)scanNumber:(NSNumber **)o;

- (BOOL)scanHexQuad:(unichar *)x;
- (BOOL)scanUnicodeChar:(unichar *)x;

- (BOOL)scanIsAtEnd;

@end

#define skipWhitespace(c) while (isspace(*c)) c++
#define skipDigits(c) while (isdigit(*c)) c++


@implementation SBJsonParser

static char ctrl[0x22];


+ (void)initialize {
    ctrl[0] = '\"';
    ctrl[1] = '\\';
    for (int i = 1; i < 0x20; i++)
        ctrl[i+1] = i;
    ctrl[0x21] = 0;    
}

/**
 @deprecated This exists in order to provide fragment support in older APIs in one more version.
 It should be removed in the next major version.
 */
- (id)fragmentWithString:(id)repr {
    [self clearErrorTrace];
    
    if (!repr) {
        [self addErrorWithCode:EINPUT description:@"Input was 'nil'"];
        return nil;
    }
    
    depth = 0;
    c = [repr UTF8String];
    
    id o;
    if (![self scanValue:&o]) {
        return nil;
    }
    
    // We found some valid JSON. But did it also contain something else?
    if (![self scanIsAtEnd]) {
        [self addErrorWithCode:ETRAILGARBAGE description:@"Garbage after JSON"];
        return nil;
    }
	
    NSAssert1(o, @"Should have a valid object from %@", repr);
    return o;    
}

- (id)objectWithString:(NSString *)repr {
	
    id o = [self fragmentWithString:repr];
    if (!o)
        return nil;
    
    // Check that the object we've found is a valid JSON container.
    if (![o isKindOfClass:[NSDictionary class]] && ![o isKindOfClass:[NSArray class]]) {
        [self addErrorWithCode:EFRAGMENT description:@"Valid fragment, but not JSON"];
        return nil;
    }
	
    return o;
}

/*
 In contrast to the public methods, it is an error to omit the error parameter here.
 */
- (BOOL)scanValue:(NSObject **)o
{
    skipWhitespace(c);
    
    switch (*c++) {
        case '{':
            return [self scanRestOfDictionary:(NSMutableDictionary **)o];
            break;
        case '[':
            return [self scanRestOfArray:(NSMutableArray **)o];
            break;
        case '"':
            return [self scanRestOfString:(NSMutableString **)o];
            break;
        case 'f':
            return [self scanRestOfFalse:(NSNumber **)o];
            break;
        case 't':
            return [self scanRestOfTrue:(NSNumber **)o];
            break;
        case 'n':
            return [self scanRestOfNull:(NSNull **)o];
            break;
        case '-':
        case '0'...'9':
            c--; // cannot verify number correctly without the first character
            return [self scanNumber:(NSNumber **)o];
            break;
        case '+':
            [self addErrorWithCode:EPARSENUM description: @"Leading + disallowed in number"];
            return NO;
            break;
        case 0x0:
            [self addErrorWithCode:EEOF description:@"Unexpected end of string"];
            return NO;
            break;
        default:
            [self addErrorWithCode:EPARSE description: @"Unrecognised leading character"];
            return NO;
            break;
    }
    
    NSAssert(0, @"Should never get here");
    return NO;
}

- (BOOL)scanRestOfTrue:(NSNumber **)o
{
    if (!strncmp(c, "rue", 3)) {
        c += 3;
        *o = [NSNumber numberWithBool:YES];
        return YES;
    }
    [self addErrorWithCode:EPARSE description:@"Expected 'true'"];
    return NO;
}

- (BOOL)scanRestOfFalse:(NSNumber **)o
{
    if (!strncmp(c, "alse", 4)) {
        c += 4;
        *o = [NSNumber numberWithBool:NO];
        return YES;
    }
    [self addErrorWithCode:EPARSE description: @"Expected 'false'"];
    return NO;
}

- (BOOL)scanRestOfNull:(NSNull **)o {
    if (!strncmp(c, "ull", 3)) {
        c += 3;
        *o = [NSNull null];
        return YES;
    }
    [self addErrorWithCode:EPARSE description: @"Expected 'null'"];
    return NO;
}

- (BOOL)scanRestOfArray:(NSMutableArray **)o {
    if (maxDepth && ++depth > maxDepth) {
        [self addErrorWithCode:EDEPTH description: @"Nested too deep"];
        return NO;
    }
    
    *o = [NSMutableArray arrayWithCapacity:8];
    
    for (; *c ;) {
        id v;
        
        skipWhitespace(c);
        if (*c == ']' && c++) {
            depth--;
            return YES;
        }
        
        if (![self scanValue:&v]) {
            [self addErrorWithCode:EPARSE description:@"Expected value while parsing array"];
            return NO;
        }
        
        [*o addObject:v];
        
        skipWhitespace(c);
        if (*c == ',' && c++) {
            skipWhitespace(c);
            if (*c == ']') {
                [self addErrorWithCode:ETRAILCOMMA description: @"Trailing comma disallowed in array"];
                return NO;
            }
        }        
    }
    
    [self addErrorWithCode:EEOF description: @"End of input while parsing array"];
    return NO;
}

- (BOOL)scanRestOfDictionary:(NSMutableDictionary **)o 
{
    if (maxDepth && ++depth > maxDepth) {
        [self addErrorWithCode:EDEPTH description: @"Nested too deep"];
        return NO;
    }
    
    *o = [NSMutableDictionary dictionaryWithCapacity:7];
    
    for (; *c ;) {
        id k, v;
        
        skipWhitespace(c);
        if (*c == '}' && c++) {
            depth--;
            return YES;
        }    
        
        if (!(*c == '\"' && c++ && [self scanRestOfString:&k])) {
            [self addErrorWithCode:EPARSE description: @"Object key string expected"];
            return NO;
        }
        
        skipWhitespace(c);
        if (*c != ':') {
            [self addErrorWithCode:EPARSE description: @"Expected ':' separating key and value"];
            return NO;
        }
        
        c++;
        if (![self scanValue:&v]) {
            NSString *string = [NSString stringWithFormat:@"Object value expected for key: %@", k];
            [self addErrorWithCode:EPARSE description: string];
            return NO;
        }
        
        [*o setObject:v forKey:k];
        
        skipWhitespace(c);
        if (*c == ',' && c++) {
            skipWhitespace(c);
            if (*c == '}') {
                [self addErrorWithCode:ETRAILCOMMA description: @"Trailing comma disallowed in object"];
                return NO;
            }
        }        
    }
    
    [self addErrorWithCode:EEOF description: @"End of input while parsing object"];
    return NO;
}

- (BOOL)scanRestOfString:(NSMutableString **)o 
{
    *o = [NSMutableString stringWithCapacity:16];
    do {
        // First see if there's a portion we can grab in one go. 
        // Doing this caused a massive speedup on the long string.
        size_t len = strcspn(c, ctrl);
        if (len) {
            // check for 
            id t = [[NSString alloc] initWithBytesNoCopy:(char*)c
                                                  length:len
                                                encoding:NSUTF8StringEncoding
                                            freeWhenDone:NO];
            if (t) {
                [*o appendString:t];
                [t release];
                c += len;
            }
        }
        
        if (*c == '"') {
            c++;
            return YES;
            
        } else if (*c == '\\') {
            unichar uc = *++c;
            switch (uc) {
                case '\\':
                case '/':
                case '"':
                    break;
                    
                case 'b':   uc = '\b';  break;
                case 'n':   uc = '\n';  break;
                case 'r':   uc = '\r';  break;
                case 't':   uc = '\t';  break;
                case 'f':   uc = '\f';  break;                    
                    
                case 'u':
                    c++;
                    if (![self scanUnicodeChar:&uc]) {
                        [self addErrorWithCode:EUNICODE description: @"Broken unicode character"];
                        return NO;
                    }
                    c--; // hack.
                    break;
                default:
                    [self addErrorWithCode:EESCAPE description: [NSString stringWithFormat:@"Illegal escape sequence '0x%x'", uc]];
                    return NO;
                    break;
            }
            CFStringAppendCharacters((CFMutableStringRef)*o, &uc, 1);
            c++;
            
        } else if (*c < 0x20) {
            [self addErrorWithCode:ECTRL description: [NSString stringWithFormat:@"Unescaped control character '0x%x'", *c]];
            return NO;
            
        } else {
            NSLog(@"should not be able to get here");
        }
    } while (*c);
    
    [self addErrorWithCode:EEOF description:@"Unexpected EOF while parsing string"];
    return NO;
}

- (BOOL)scanUnicodeChar:(unichar *)x
{
    unichar hi, lo;
    
    if (![self scanHexQuad:&hi]) {
        [self addErrorWithCode:EUNICODE description: @"Missing hex quad"];
        return NO;        
    }
    
    if (hi >= 0xd800) {     // high surrogate char?
        if (hi < 0xdc00) {  // yes - expect a low char
            
            if (!(*c == '\\' && ++c && *c == 'u' && ++c && [self scanHexQuad:&lo])) {
                [self addErrorWithCode:EUNICODE description: @"Missing low character in surrogate pair"];
                return NO;
            }
            
            if (lo < 0xdc00 || lo >= 0xdfff) {
                [self addErrorWithCode:EUNICODE description:@"Invalid low surrogate char"];
                return NO;
            }
            
            hi = (hi - 0xd800) * 0x400 + (lo - 0xdc00) + 0x10000;
            
        } else if (hi < 0xe000) {
            [self addErrorWithCode:EUNICODE description:@"Invalid high character in surrogate pair"];
            return NO;
        }
    }
    
    *x = hi;
    return YES;
}

- (BOOL)scanHexQuad:(unichar *)x
{
    *x = 0;
    for (int i = 0; i < 4; i++) {
        unichar uc = *c;
        c++;
        int d = (uc >= '0' && uc <= '9')
        ? uc - '0' : (uc >= 'a' && uc <= 'f')
        ? (uc - 'a' + 10) : (uc >= 'A' && uc <= 'F')
        ? (uc - 'A' + 10) : -1;
        if (d == -1) {
            [self addErrorWithCode:EUNICODE description:@"Missing hex digit in quad"];
            return NO;
        }
        *x *= 16;
        *x += d;
    }
    return YES;
}

- (BOOL)scanNumber:(NSNumber **)o
{
    const char *ns = c;
    
    // The logic to test for validity of the number formatting is relicensed
    // from JSON::XS with permission from its author Marc Lehmann.
    // (Available at the CPAN: http://search.cpan.org/dist/JSON-XS/ .)
    
    if ('-' == *c)
        c++;
    
    if ('0' == *c && c++) {        
        if (isdigit(*c)) {
            [self addErrorWithCode:EPARSENUM description: @"Leading 0 disallowed in number"];
            return NO;
        }
        
    } else if (!isdigit(*c) && c != ns) {
        [self addErrorWithCode:EPARSENUM description: @"No digits after initial minus"];
        return NO;
        
    } else {
        skipDigits(c);
    }
    
    // Fractional part
    if ('.' == *c && c++) {
        
        if (!isdigit(*c)) {
            [self addErrorWithCode:EPARSENUM description: @"No digits after decimal point"];
            return NO;
        }        
        skipDigits(c);
    }
    
    // Exponential part
    if ('e' == *c || 'E' == *c) {
        c++;
        
        if ('-' == *c || '+' == *c)
            c++;
        
        if (!isdigit(*c)) {
            [self addErrorWithCode:EPARSENUM description: @"No digits after exponent"];
            return NO;
        }
        skipDigits(c);
    }
    
    id str = [[NSString alloc] initWithBytesNoCopy:(char*)ns
                                            length:c - ns
                                          encoding:NSUTF8StringEncoding
                                      freeWhenDone:NO];
    [str autorelease];
    if (str && (*o = [NSDecimalNumber decimalNumberWithString:str]))
        return YES;
    
    [self addErrorWithCode:EPARSENUM description: @"Failed creating decimal instance"];
    return NO;
}

- (BOOL)scanIsAtEnd
{
    skipWhitespace(c);
    return !*c;
}


@end


@interface SBJsonWriter ()

- (BOOL)appendValue:(id)fragment into:(NSMutableString*)json;
- (BOOL)appendArray:(NSArray*)fragment into:(NSMutableString*)json;
- (BOOL)appendDictionary:(NSDictionary*)fragment into:(NSMutableString*)json;
- (BOOL)appendString:(NSString*)fragment into:(NSMutableString*)json;

- (NSString*)indent;

@end

@implementation SBJsonWriter

static NSMutableCharacterSet *kEscapeChars;

+ (void)initialize {
	kEscapeChars = [[NSMutableCharacterSet characterSetWithRange: NSMakeRange(0,32)] retain];
	[kEscapeChars addCharactersInString: @"\"\\"];
}


@synthesize sortKeys;
@synthesize humanReadable;

/**
 @deprecated This exists in order to provide fragment support in older APIs in one more version.
 It should be removed in the next major version.
 */
- (NSString*)stringWithFragment:(id)value {
    [self clearErrorTrace];
    depth = 0;
    NSMutableString *json = [NSMutableString stringWithCapacity:128];
    
    if ([self appendValue:value into:json])
        return json;
    
    return nil;
}


- (NSString*)stringWithObject:(id)value {
    
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        return [self stringWithFragment:value];
    }
    
    if ([value respondsToSelector:@selector(proxyForJson)]) {
        NSString *tmp = [self stringWithObject:[value proxyForJson]];
        if (tmp)
            return tmp;
    }
	
	
    [self clearErrorTrace];
    [self addErrorWithCode:EFRAGMENT description:@"Not valid type for JSON"];
    return nil;
}


- (NSString*)indent {
    return [@"\n" stringByPaddingToLength:1 + 2 * depth withString:@" " startingAtIndex:0];
}

- (BOOL)appendValue:(id)fragment into:(NSMutableString*)json {
    if ([fragment isKindOfClass:[NSDictionary class]]) {
        if (![self appendDictionary:fragment into:json])
            return NO;
        
    } else if ([fragment isKindOfClass:[NSArray class]]) {
        if (![self appendArray:fragment into:json])
            return NO;
        
    } else if ([fragment isKindOfClass:[NSString class]]) {
        if (![self appendString:fragment into:json])
            return NO;
        
    } else if ([fragment isKindOfClass:[NSNumber class]]) {
        if ('c' == *[fragment objCType])
            [json appendString:[fragment boolValue] ? @"true" : @"false"];
        else
            [json appendString:[fragment stringValue]];
        
    } else if ([fragment isKindOfClass:[NSNull class]]) {
        [json appendString:@"null"];
    } else if ([fragment respondsToSelector:@selector(proxyForJson)]) {
        [self appendValue:[fragment proxyForJson] into:json];
        
    } else {
        [self addErrorWithCode:EUNSUPPORTED description:[NSString stringWithFormat:@"JSON serialisation not supported for %@", [fragment class]]];
        return NO;
    }
    return YES;
}

- (BOOL)appendArray:(NSArray*)fragment into:(NSMutableString*)json {
    if (maxDepth && ++depth > maxDepth) {
        [self addErrorWithCode:EDEPTH description: @"Nested too deep"];
        return NO;
    }
    [json appendString:@"["];
    
    BOOL addComma = NO;    
    for (id value in fragment) {
        if (addComma)
            [json appendString:@","];
        else
            addComma = YES;
        
        if ([self humanReadable])
            [json appendString:[self indent]];
        
        if (![self appendValue:value into:json]) {
            return NO;
        }
    }
    
    depth--;
    if ([self humanReadable] && [fragment count])
        [json appendString:[self indent]];
    [json appendString:@"]"];
    return YES;
}

- (BOOL)appendDictionary:(NSDictionary*)fragment into:(NSMutableString*)json {
    if (maxDepth && ++depth > maxDepth) {
        [self addErrorWithCode:EDEPTH description: @"Nested too deep"];
        return NO;
    }
    [json appendString:@"{"];
    
    NSString *colon = [self humanReadable] ? @" : " : @":";
    BOOL addComma = NO;
    NSArray *keys = [fragment allKeys];
    if (self.sortKeys)
        keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    
    for (id value in keys) {
        if (addComma)
            [json appendString:@","];
        else
            addComma = YES;
        
        if ([self humanReadable])
            [json appendString:[self indent]];
        
        if (![value isKindOfClass:[NSString class]]) {
            [self addErrorWithCode:EUNSUPPORTED description: @"JSON object key must be string"];
            return NO;
        }
        
        if (![self appendString:value into:json])
            return NO;
        
        [json appendString:colon];
        if (![self appendValue:[fragment objectForKey:value] into:json]) {
            [self addErrorWithCode:EUNSUPPORTED description:[NSString stringWithFormat:@"Unsupported value for key %@ in object", value]];
            return NO;
        }
    }
    
    depth--;
    if ([self humanReadable] && [fragment count])
        [json appendString:[self indent]];
    [json appendString:@"}"];
    return YES;    
}

- (BOOL)appendString:(NSString*)fragment into:(NSMutableString*)json {
    
    [json appendString:@"\""];
    
    NSRange esc = [fragment rangeOfCharacterFromSet:kEscapeChars];
    if ( !esc.length ) {
        // No special chars -- can just add the raw string:
        [json appendString:fragment];
        
    } else {
        NSUInteger length = [fragment length];
        for (NSUInteger i = 0; i < length; i++) {
            unichar uc = [fragment characterAtIndex:i];
            switch (uc) {
                case '"':   [json appendString:@"\\\""];       break;
                case '\\':  [json appendString:@"\\\\"];       break;
                case '\t':  [json appendString:@"\\t"];        break;
                case '\n':  [json appendString:@"\\n"];        break;
                case '\r':  [json appendString:@"\\r"];        break;
                case '\b':  [json appendString:@"\\b"];        break;
                case '\f':  [json appendString:@"\\f"];        break;
                default:    
                    if (uc < 0x20) {
                        [json appendFormat:@"\\u%04x", uc];
                    } else {
                        CFStringAppendCharacters((CFMutableStringRef)json, &uc, 1);
                    }
                    break;
                    
            }
        }
    }
    
    [json appendString:@"\""];
    return YES;
}


@end


@implementation NSObject (NSObject_SBJSON)

- (NSString *)JSONString {
    SBJsonWriter *jsonWriter = [SBJsonWriter new];
    NSString *json = [jsonWriter stringWithFragment:self];    
    if (!json)
        NSLog(@"-JSONFragment failed. Error trace is: %@", [jsonWriter errorTrace]);
    [jsonWriter release];
    return json;
}

- (NSString *)JSONRepresentation {
    SBJsonWriter *jsonWriter = [SBJsonWriter new];    
    NSString *json = [jsonWriter stringWithObject:self];
    if (!json)
        NSLog(@"-JSONRepresentation failed. Error trace is: %@", [jsonWriter errorTrace]);
    [jsonWriter release];
    return json;
}

@end


@implementation NSString (NSString_SBJSON)

- (id)JSONFragmentValue
{
    SBJsonParser *jsonParser = [SBJsonParser new];    
    id repr = [jsonParser fragmentWithString:self];    
    if (!repr)
        NSLog(@"-JSONFragmentValue failed. Error trace is: %@", [jsonParser errorTrace]);
    [jsonParser release];
    return repr;
}

- (id)JSONValue
{
    SBJsonParser *jsonParser = [SBJsonParser new];
    id repr = [jsonParser objectWithString:self];
    if (!repr)
        NSLog(@"-JSONValue failed. Error trace is: %@", [jsonParser errorTrace]);
    [jsonParser release];
    return repr;
}

@end
