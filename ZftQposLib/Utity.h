//
//  Utity.h
//  ZFTSwiper
//
//  Created by rjb on 13-5-14.
//  Copyright (c) 2013年 zft. All rights reserved.
//

#ifndef ZFTSwiper_Utity_h
#define ZFTSwiper_Utity_h

@interface Utity : NSObject 
void HexToAscii(const char * hex, int length, char * ascii);
void AsciiToHex(const char * ascii, int length, char * hex);
void PushArg(NSString** strResult,const char* strFormat,...);
short CalcCRCModBus(unsigned char cDataIn, short wCRCIn);
void CheckCRCModBus(unsigned char* pDataIn, int iLenIn, short* pCRCOut);
+(NSString*)NSDataToChar:(NSData*)data andStartPos:(NSInteger)startPos andLen:(NSInteger) len;
+(NSInteger) NSDataGetOneByte:(NSData*)data andStartPos:(NSInteger)startPos;
+(NSString*) NSDataToHexString:(NSData*)data andStartPos:(NSInteger)startPos andLen:(NSInteger) len;
+(void) DEBUG_SHOW:(unsigned char*)sendContex  andLenght:(int)len andTag:(const char*)tag;

@end



#endif
