//
//  QFTransactionConfig.m
//  Apps
//
//  Created by Travis on 11-11-4.
//  Copyright (c) 2011年 QFPay. All rights reserved.
//

#import "QFTransactionConfig.h"

@implementation QFTransactionConfig
@synthesize visible,name,requestParams,respondParams,businessCode,api;
@synthesize configInfo,coreTransaction;
- (void)dealloc {
    self.configInfo=nil;
    [super dealloc];
}

- (id)initWithInfo:(NSDictionary*)info{
    self = [super init];
    if (self) {
        self.configInfo=info;
		coreTransaction=([[info objectForKey:@"api"] rangeOfString:@"trade"].length==5);
		visible=[[configInfo objectForKey:@"visible"] boolValue];
    }
    return self;
}

-(QFTransactionErrorRecovery)errorRecovery{
	return [[configInfo objectForKey:@"recovery"] intValue];
}
-(NSString*)businessCode{
	return [configInfo objectForKey:@"businessCode"];
}

-(NSString*)api{
	return [configInfo objectForKey:@"api"];
}
-(NSString*)name{
	NSDictionary *nameL=[configInfo objectForKey:@"name"];
	return [nameL objectForKey:@"zh_CN"]; 
}

-(NSArray*)requestParams{
	NSString *s=[configInfo objectForKey:@"mq"];
	NSArray *a=[s componentsSeparatedByString:@","];
	return a;
}
-(NSArray*)respondParams{
	NSString *s=[configInfo objectForKey:@"ma"];
	NSArray *a=[s componentsSeparatedByString:@","];
	return a;
}
-(NSArray*)optionalRequestParams{
	NSString *s=[configInfo objectForKey:@"cq"];
	NSArray *a=[s componentsSeparatedByString:@","];
	return a;
}
-(NSArray*)optionalRespondParams{
	NSString *s=[configInfo objectForKey:@"ca"];
	NSArray *a=[s componentsSeparatedByString:@","];
	return a;
}
@end
