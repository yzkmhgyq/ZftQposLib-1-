//
//  QFTransactionConfig.h
//  Apps
//
//  Created by Travis on 11-11-4.
//  Copyright (c) 2011年 QFPay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
	QFTransactionErrorRecovery_Nothing	=0,
	QFTransactionErrorRecovery_Retry	=1,
	QFTransactionErrorRecovery_Reversal	=2,
}QFTransactionErrorRecovery;

@interface QFTransactionConfig : NSObject{
	NSDictionary *configInfo;
	BOOL coreTransaction,visible;
}
@property(nonatomic,readonly) QFTransactionErrorRecovery errorRecovery;
@property(nonatomic,readonly) BOOL coreTransaction;
@property(nonatomic,readonly) BOOL visible;
@property(nonatomic,readonly) NSString *name;
@property(nonatomic,readonly) NSString *api;
@property(nonatomic,readonly) NSString *businessCode;
@property(nonatomic,readonly) NSArray *requestParams;
@property(nonatomic,readonly) NSArray *respondParams;
@property(nonatomic,readonly) NSArray *optionalRequestParams;
@property(nonatomic,readonly) NSArray *optionalRespondParams;

@property(nonatomic,retain) NSDictionary *configInfo;

- (id)initWithInfo:(NSDictionary*)info;

@end
