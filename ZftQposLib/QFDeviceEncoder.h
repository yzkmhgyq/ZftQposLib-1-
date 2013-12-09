//
//  QFDeviceEncoder.h
//  Apps
//
//  Created by Travis on 11-9-24.
//  Modified by Alex on 10-17-12.
//  Copyright (c) 2011-2012年 QFPay. All rights reserved.
//

#ifndef Apps_QFDeviceEncoder_h
#define Apps_QFDeviceEncoder_h

void init_encode();
void reset();

char *encode(char *toEncodeStr, int toEncodeStrLen, char *resultStr, int *resultStrLen);
void encode2(char *toEncodeStr, int toEncodeStrLen, char *resultStr, int *resultStrLen);

void decode(char *inputBuf, int inputBufLen);
void dataIn(char *inputBuf, int inputBufLen);

char *readMessage(int *rltBufLen);
void readMessage2(char* msg, int* rltBufLen);

#endif
