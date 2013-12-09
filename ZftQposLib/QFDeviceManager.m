//
//  QFDeviceManager.m
//  Apps
//
//  Created by Travis on 11-9-22.
//  Copyright 2009-2011年 QFPay. All rights reserved.
//

#import "QFDeviceManager.h"

@implementation QFDeviceManager

#pragma mark -
#pragma mark Singleton
#pragma mark -
static QFDeviceManager *sharedQFDeviceManager = nil;  
+ (QFDeviceManager *)shared {             
    @synchronized(self) {                            
        if (sharedQFDeviceManager == nil) {             
            /* Note that 'self' may not be the same as QFDeviceManager */                               
            /* first assignment done in allocWithZone but we must reassign in case init fails */      
            sharedQFDeviceManager = [[self alloc] init];                                               
            NSAssert((sharedQFDeviceManager != nil), @"didn't catch singleton allocation");       
        }                                              
    }                                                
    return sharedQFDeviceManager;                     
}                                                  
+ (id)allocWithZone:(NSZone *)zone {               
    @synchronized(self) {                            
        if (sharedQFDeviceManager == nil) {             
            sharedQFDeviceManager = [super allocWithZone:zone]; 
            return sharedQFDeviceManager;                 
        }                                              
    }                                                
    
    /* We can't return the shared instance, because it's been init'd */ 
    NSAssert(NO, @"use the singleton API, not alloc+init");        
    return nil;                                      
}                                                  
- (id)retain {                                     
    return self;                                     
}                                                  
- (NSUInteger)retainCount {                        
    return NSUIntegerMax;                            
}                                                  
                                               
- (id)autorelease {                                
    return self;                                     
}                                                  
- (id)copyWithZone:(NSZone *)zone {                
    return self;                                     
} 

#pragma mark -
#pragma mark Implementation
#pragma mark -
- (id)init
{
    self = [super init];
    if (self) {
        commandList=[NSMutableDictionary new];
		
		
    }
    
    return self;
}

- (void)dealloc
{
	[commandList release];
    [super dealloc];
}

-(void)swipeCardWithInfo:(NSDictionary*)info{
	
}

@end
