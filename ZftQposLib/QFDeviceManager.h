/**
 * @file	QFDeviceManager.h
 * @author	Travis
 * @date	11-9-22
 * @note	Copyright 2009-2011年 QFPay. All rights reserved.
 *
 * @brief	
 * @details	
 */


#import <Foundation/Foundation.h>
#import "QFDevice.h"

@interface QFDeviceManager : NSObject {
	@private
    NSMutableDictionary *commandList;
}

+(QFDeviceManager*)shared;

@end
