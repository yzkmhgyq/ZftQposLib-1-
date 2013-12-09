//
//  QFError.m
//  Apps
//
//  Created by Worm Travis on 11-8-22.
//  Copyright (c) 2011年 QFPay. All rights reserved.
//

#import "QFKit.h"

NSString* const QFEventLogout=@"QFEventLogout";


void QFLog(NSString *msg,...){
#if QF_DEBUG_MODE>0	
	va_list args;
    va_start(args, msg);
    NSString *str = [[NSString alloc] initWithFormat:msg arguments:args];
	
    va_end(args);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QFDebugLog object:str];
	printf("\nDEBUG: %s\n",[str UTF8String]);
    [str release];
#else
	//TODO: 保存给服务器
#endif
}



@implementation QFError
@synthesize errorDomain,level;
@synthesize extendMsg;
@synthesize retryInvocation;
@synthesize stringCode;

static NSDictionary *serverErrorCodes=nil;

-(BOOL)shouldReversal{
	switch (errorDomain) {
		default:
			break;
	}
	
	return YES;
}

+(NSString*)errorDomian:(QFErrorDomain)edomain{
    NSString *sdomain=nil;
    
    
    switch (edomain) {
        case QFErrorDomainConnect:
            sdomain=@"net.qfpay.connect";
            break;
            
        case QFErrorDomainService:
            sdomain=@"net.qfpay.service";
            break;
            
        case QFErrorDomainTerminal:
            sdomain=@"net.qfpay.terminal";
            break;
          
        case QFErrorDomainClient:
            sdomain=@"net.qfpay.client";
            break;
		case QFErrorDomainUser:
            sdomain=@"net.qfpay.userstat";
            break;	
        case QFErrorDomainUnknown:
        default:
            sdomain=@"net.qfpay.unknown";
            break;
    }
    return sdomain;
}

+(QFError *)errorWithDomain:(QFErrorDomain)edomain andCode:(NSInteger)ecode{
    
    QFError *error=[QFError errorWithDomain:[QFError errorDomian:edomain] code:ecode userInfo:nil];
    error.errorDomain=edomain;
    return error;
}

+(QFError *)errorWithDomain:(QFErrorDomain)edomain andStringCode:(NSString*)scode{
	QFError *error=[QFError errorWithDomain:[QFError errorDomian:edomain] code:0 userInfo:nil];
	error.stringCode=scode;
    error.errorDomain=edomain;
    return error;
}

+(QFError *)errorWithException:(NSException*)exception{
    QFError *error=[[exception userInfo] objectForKey:@"Error"];
    return error;
}
-(QFErrorLevel)level{
    QFErrorLevel l=QFErrorLevelAlert;
    
    switch (self.errorDomain) {
        case QFErrorDomainConnect:
		{
			switch ([self code]) {
				case 403:
				case 411:
				case 502:
				case 1001:	
		
					l=QFErrorLevelRetry;
					break;
					
				default:
					l=QFErrorLevelRetry;
					break;
			}
		}
            break;
            
		case QFErrorDomainService:
		{
			if ([[self stringCode] isEqualToString:@"1117"]) {
				QFEvent(QFEventLogout, [self localizedRecoverySuggestion]);
				break;
			}
		}
            break;
            
        case QFErrorDomainTerminal:
		{
			
		}
            break;
			
        case QFErrorDomainClient:
		{
			
		}
            break;
		case QFErrorDomainUser:
		{
			l=QFErrorLevelBroadcast;
		}
            break;	
        case QFErrorDomainUnknown:
        default:
            
            break;
    }
    
    return l;
}

-(NSString*)stringCode{
	if (stringCode!=nil) return stringCode;
	
	
	return [NSString stringWithFormat:@"%i",abs([self code])];
}

-(NSString*)errorKey{
    return [NSString stringWithFormat:@"%i_%@",self.errorDomain,[self stringCode]];
}
-(NSString*)errorSuggestKey{
    return [NSString stringWithFormat:@"%i_%@_",self.errorDomain,[self stringCode]];
}
-(NSString*)localizedFailureReason{
    /** 应产品需求，FailureReason统一发为“错误”*/
    
    return @"提示：";
    
	if (errorDomain==QFErrorDomainService) {
		return [NSString stringWithFormat:@"错误 %@",[self errorKey]];
	}
	
	NSString *errkey=[self errorKey];
    NSString *estring=QFString(errkey, @"Error");
	if (estring==nil) {
		return [NSString stringWithFormat:@"%@ %i_%i",QFString(@"0", @"Error"),self.errorDomain,[self code]];
	}else{
		//使用没有错误编码的提示语
        estring=@"";
        //estring=[estring stringByAppendingFormat:@" %i_%i",self.errorDomain,[self code]];
	}
    return estring;
}

-(NSString*)localizedRecoverySuggestion{
    NSString *estring=nil;
	
	if (errorDomain==QFErrorDomainService) {
		if (serverErrorCodes==nil) {
			
			NSString *s=[NSString stringWithContentsOfFile:[QFKit bundleFilePath:@"errcode.json"] encoding:NSUTF8StringEncoding error:nil];
			if (s) {
				serverErrorCodes=[[s JSONValue] retain];
			}
		}
		
		estring=[serverErrorCodes objectForKey:[self stringCode]];
		
		///只有调试模式显示extendMsg
		if (estring) {

#if QF_DEBUG_MODE
			if (extendMsg!=nil) {
				estring=[estring stringByAppendingFormat:@"\n%@",extendMsg];
			}
#endif			
			return estring;
		}
	}
	
	
	estring= QFString([self errorSuggestKey], @"Error");
	if (estring==nil) {
		estring=QFString(@"0_", @"Error");
	}
	
	
#if QF_DEBUG_MODE	
	if (extendMsg!=nil) {
		estring=[estring stringByAppendingFormat:@"\n%@",extendMsg];
	}
#endif	
	
	return estring;
}

-(void)present{
    switch (self.level) {
		default:
		case QFErrorLevelLog:
            NSLog(@"Error: %@",[self description]);
            break;
        case QFErrorLevelAlert:
            QFAlert([self localizedFailureReason],[self localizedRecoverySuggestion], @"确 定");
            break; 
        case QFErrorLevelAlertWithSound:
            NSLog(@"QFErrorLevelAlertWithSound: %@",[self description]);
            break;
		case QFErrorLevelRetry:
            NSLog(@"QFErrorLevelRetry: %@",[self description]);
			if (self.retryInvocation) {
				UIAlertView *alert=[[UIAlertView alloc] initWithTitle:[self localizedFailureReason] 
															  message:[self localizedRecoverySuggestion] 
															 delegate:self
													cancelButtonTitle:nil 
													otherButtonTitles:@"重试", nil];
				[alert show];
				[alert release];
				[self retain];
			}else{
				QFAlert([self localizedFailureReason],[self localizedRecoverySuggestion], @"确 定");
			}
            break;
        case QFErrorLevelAlertAndCallback:
            NSLog(@"QFErrorLevelAlertAndCallback: %@",[self description]);
            break; 
		case QFErrorLevelBroadcast:
            QFEvent(@"QFEventErrorBroadcast", self);
            break; 	
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (self.level==QFErrorLevelRetry) {
		
		[self.retryInvocation invoke];
		
	}else{
		
	}
	[self release];
}

-(void)setData:(id)d{
    [data release];
    data=[d retain];
}
-(id)data{
    return data;
}

- (void)dealloc {
	[retryInvocation release];
	retryInvocation=nil;
    [data release];
    [super dealloc];
}

@end

@implementation NSException (QFError)
+(NSException*)exceptionWithError:(QFError*)error{
	NSException *e=[NSException exceptionWithName:[QFError errorDomian:error.errorDomain] reason:[error localizedFailureReason] userInfo:[NSDictionary dictionaryWithObject:error forKey:@"Error"]];
	return e;
}
@end
