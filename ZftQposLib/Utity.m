//
//  Utity.m
//  ZFTSwiper
//
//  Created by rjb on 13-5-14.
//  Copyright (c) 2013年 zft. All rights reserved.
//

#include <stdio.h>
#include "Utity.h"

@implementation Utity


void HexToAscii(const char * hex, int length, char * ascii)
{
    for (int i = 0; i < length; i += 2)
    {
        if (hex[i] >= '0' && hex[i] <= '9')
            ascii[i / 2] = (hex[i] - '0') << 4;
        else if (hex[i] >= 'a' && hex[i] <= 'z')
            ascii[i / 2] = (hex[i] - 'a' + 10) << 4;
        else if (hex[i] >= 'A' && hex[i] <= 'Z')
            ascii[i / 2] = (hex[i] - 'A' + 10) << 4;
        
        if (hex[i + 1] >= '0' && hex[i + 1] <= '9')
            ascii[i / 2] += hex[i + 1] - '0';
        else if (hex[i + 1] >= 'a' && hex[i + 1] <= 'z')
            ascii[i / 2] += hex[i + 1] - 'a' + 10;
        else if (hex[i + 1] >= 'A' && hex[i + 1] <= 'Z')
            ascii[i / 2] += hex[i + 1] - 'A' + 10;
    }
}


void AsciiToHex(const char * ascii, int length, char * hex)
{
	static const char plate[] = "0123456789abcdef";
    
	for (int i = 0; i < length; i++)
	{
		hex[i * 2 + 1] = plate[ascii[i] & 0x0F];
		hex[i * 2] = plate[(ascii[i] >> 4) & 0x0F];
	}
}


void PushArg(NSString** strResult,const char* strFormat,...)
{
	char szTmp[1024]={0};
	va_list applist;
	va_start(applist,strFormat);
	vsprintf(szTmp,strFormat,applist);
	va_end(applist);
    *strResult = [NSString stringWithFormat:@"%s",szTmp];
}

short CalcCRCModBus(unsigned char cDataIn, short wCRCIn)
{
    short wCheck = 0;
    wCRCIn = wCRCIn ^ cDataIn;
    
    for(int i = 0; i < 8; i++)
    {
        wCheck = wCRCIn & 1;
        wCRCIn = wCRCIn >> 1;
        wCRCIn = wCRCIn & 0x7fff;
        if(wCheck == 1)
        {
            wCRCIn = wCRCIn ^ 0xa001;
        }
        wCRCIn = wCRCIn & 0xffff;
    }
    
    return wCRCIn;
}

void CheckCRCModBus(unsigned char* pDataIn, int iLenIn, short* pCRCOut)
{
    short wHi = 0;
    short wLo = 0;
    short wCRC;
    wCRC = 0xFFFF;
    
    for (int i = 0; i < iLenIn; i++)
    {
        wCRC = CalcCRCModBus(*pDataIn, wCRC);
        pDataIn++;
    }
    
    wHi = (wCRC &0xFF00)>>8;
    wLo = wCRC & 0xFF;
    wCRC = (wHi << 8) | wLo;
    *pCRCOut = wCRC;
}

+(NSString*)NSDataToChar:(NSData*)data andStartPos:(NSInteger)startPos andLen:(NSInteger) len
{  
    char szData[1024]={0};
    unsigned char* pBytes =(unsigned char*)(data == nil ? NULL: data.bytes);
    
    if(NULL != pBytes)
    {
        int  minLen = data.length  > len ? len : data.length;
        
        for (int i=0 ; i< minLen ; i++)
        {
            unsigned char tmp[16];
            sprintf((char*)tmp, "%c",pBytes[i + startPos]);
            strcat((char*)szData, (char*)tmp);
        }
        return [NSString stringWithFormat:@"%s",szData];
    }
    return nil;
    
}

+(NSInteger) NSDataGetOneByte:(NSData*)data andStartPos:(NSInteger)startPos
{
    unsigned char* pBytes =(unsigned char*)(data == nil ? NULL: data.bytes);
    return  *(pBytes + startPos);
}


+(NSString*) NSDataToHexString:(NSData*)data andStartPos:(NSInteger)startPos andLen:(NSInteger) len
{ 
    
    char szData[1024]={0};
    unsigned char* pBytes =(unsigned char*)(data == nil ? NULL: data.bytes);
    
    
    if(NULL != pBytes)
    {
        int  minLen = data.length  > len ? len : data.length;
        
        for(int i=0; i< minLen; i++)
        {
            unsigned char tmp[16];
            sprintf((char*)tmp, "%0.2X",pBytes[i + startPos]);
            strcat((char*)szData, (char*)tmp);
        }
        return [NSString stringWithFormat:@"%s",szData];
    }
    return nil;
}


+(void) DEBUG_SHOW:(unsigned char*)sendContex  andLenght:(int)len andTag:(const char*)tag
{
    unsigned char outStr[1024] = {0};
    for (int i=0 ; i<len ; i++)
    {
        unsigned char tmp[10];
        sprintf((char*)tmp, "%02X", sendContex[i]);
        strcat((char*)outStr, (char*)tmp);
    }
    NSString *s = [NSString stringWithFormat:@"%s=: %s", tag,outStr];
    NSLog(@"%@", s);    
}

@end


