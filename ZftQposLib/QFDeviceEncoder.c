//
//  QFDeviceEncoder.c
//  QFPOS 1.0 & 2.0
//
//  Created by Wang Xu on 10-17-12.
//  Copyright (c) 2011-2012年 QFPay. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "QFDeviceEncoder.h"

#define LOGI(fmt, args...)
#define LOGD(fmt, args...)
#define LOGE(fmt, args...)
#define LOGV(fmt, args...)

//#define LOGI(fmt, args...) printf(fmt, ##args)
//#define LOGD(fmt, args...) printf(fmt, ##args)
//#define LOGE(fmt, args...) printf(fmt, ##args)
//#define LOGV(fmt, args...) printf(fmt, ##args)

//static const char *TAG="VoiceModem";

typedef  unsigned char u8;
typedef  unsigned short u16;

int g_is_debug_on = 1;

/*
 enum codec_mode{FSK,NEW,MAN};
 enum  codec_mode g_codec_mode=NEW;
 */

/* 用于在外部自动切换工作模式*/
const int FSK = 0;
int g_codec_mode = 1;

int g_mode = 1;

float g_SAMPLES_PER_BITS = 36.75;
int g_auto_freq_cal=1;

int g_para_largest_negative =0;
int g_para_smallest_positive =0;
float g_para_one_positive=1;
float g_para_one_negative=1;
float g_para_zero_positive=1;
float g_para_zero_negative=1;

int g_para_enter_init_min=15;
int g_para_start_max=17;
int g_para_stop_exit_min  = 16;
int g_stop_exit_max=14;
int g_para_bit_one_min = 14;
int g_training_flag=0;

int g_para_THRESHOLD_VOL = 5000;



float positive_ratio=1;
float negative_ratio=1;
float g_freq_cal=0;


#define BUFFER_SIZE 2048
#define MAX_ENCODE_LEN 256
#define SAMPLENUM (44100.0/1200 * 6) * 2

char inBuf[BUFFER_SIZE];
int inBufIndex = 0;
char rltBuf[BUFFER_SIZE];
char encodeBinStrStart[201];
char encodeBinStrEnd[81];
char encode_buffer[MAX_ENCODE_LEN*10*37*2];
enum state_var{init, bit, stop,NEWLEN,NEWBYTE , ending, end, NEWSYNC,STATISTICS};
enum state_var state;

static inline void p_mem(void* addr, int len)
{
    int l;
    int c;
    unsigned char* p=addr;
    char asc[17];
    asc[16]=0;
    for (l=len;l>0;) {
        printf("%8x:",(unsigned int)p);
        for (c=0; c<16; c++) {
            int i;
            if (l>0){
                i=*p;
                printf(" %02x",i);
                asc[c]='.';
                if((i>=0x20) && (i<=0x7e))
                {
                    asc[c]=i;
                }
            } else {
                printf("   ");
                asc[c]=' ';
            }
            p++;
            l--;
        }
        printf(" %s\n",asc);
    }
}

char encodeBinStrStart[201];
char encodeBinStrEnd[81];
char cosValue0[] = { 119, 39, 22, 75, 99, 103, -98, 121, -2, 127,
    -26, 121, -20, 103, -46, 75, 85, 40, -23, 0, 103, -39, -88, -75,
    39, -103, -84, -122, 3, -128, -44, -123, -116, -105, 114, -77, -50,
    -42, 46, -2, -70, 37, -102, 73, 77, 102, 9, 121, -7, 127, 113, 122,
    -6, 104, 72, 77, 15, 42, -68, 2, 38, -37, 38, -73, 63, -102, 68,
    -121, 12, -128, 76, -123, -127, -106, -2, -79, 21, -43, 91, -4, -5,
    35, 26, 72, 50, 101, 110, 120, -18, 127, -10, 122, 2, 106, -70, 78,
    -58, 43, -114, 4, -26, -36, -88, -72, 93, -101, -30, -121, 27,
    -128, -54, -124, 123, -107, -114, -80, 94, -45, -120, -6, 58, 34,
    -106, 70, 18, 100, -51, 119, -37, 127, 116, 123, 5, 107, 41, 80,
    124, 45, 97, 6, -89, -34, 45, -70, -128, -100, -122, -120, 48,
    -128, 79, -124, 123, -108, 34, -81, -86, -47, -74, -8, 119, 32, 15,
    69, -20, 98, 37, 119, -62, 127, -20, 123, 3, 108, -110, 81, 47, 47,
    51, 8, 107, -32, -74, -69, -87, -99, 49, -119, 77, -128, -38, -125,
    -127, -109, -70, -83, -8, -49, -28, -10, -77, 30, -124, 67, -63,
    97, 120, 118, -93, 127, 94, 124, -6, 108, -8, 82, -32, 48, 5, 10,
    48, -30, 67, -67, -42, -98, -31, -119, 111, -128, 108, -125, -116,
    -110, 87, -84, 73, -50, 19, -11, -19, 28, -10, 65, -111, 96, -60,
    117, 125, 127, -55, 124, -20, 109, 89, 84, -114, 50, -42, 11, -9,
    -29, -45, -66, 8, -96, -104, -118, -103, -128, 4, -125, -99, -111,
    -8, -86, -100, -52, 66, -13, 37, 27, 100, 64, 93, 95, 10, 117, 80,
    127, 46, 125, -39, 110, -74, 85, 58, 52, -90, 13, -65, -27, 102,
    -64, 64, -95, 85, -117, -55, -128, -93, -126, -77, -112, -99, -87,
    -14, -54, 114, -15, 92, 25, -49, 62, 35, 94, 74, 116, 28, 127,
    -116, 125, -65, 111, 15, 87, -29, 53, 118, 15, -119, -25, -3, -63,
    124, -94, 24, -116, 0, -127, 72, -126, -48, -113, 71, -88, 74, -55,
    -94, -17, -110, 23, 54, 61, -28, 92, -124, 115, -30, 126, -29, 125,
    -96, 112, 99, 88, -119, 55, 69, 17, 84, -23, -105, -61, -67, -93,
    -31, -116, 61, -127, -13, -127, -14, -114, -11, -90, -91, -57, -44,
    -19, -58, 21, -101, 59, -96, 91, -72, 114, -94, 126, 52, 126, 123,
    113, -78, 89, 44, 57, 19, 19, 32, -21, 52, -59, 3, -91, -80, -115,
    -127, -127, -90, -127, 26, -114, -88, -91, 4, -58, 6, -20, -6, 19,
    -4, 57, 88, 90, -26, 113, 90, 126, 127, 126, 80, 114, -3, 90, -52,
    58, -32, 20, -19, -20, -44, -58, 78, -90, -123, -114, -52, -127,
    94, -127, 72, -115, 96, -92, 101, -60, 58, -22, 44, 18, 91, 56, 11,
    89, 14, 113, 13, 126, -61, 126, 31, 115, 67, 92, 105, 60, -84, 22,
    -69, -18, 119, -56, -99, -89, 96, -113, 29, -126, 30, -127, 124,
    -116, 28, -93, -54, -62, 110, -24, 94, 16, -74, 54, -71, 87, 48,
    112, -72, 125, 0, 127, -24, 115, -124, 93, 3, 62, 119, 24, -118,
    -16, 29, -54, -15, -88, 65, -112, 116, -126, -28, -128, -74, -117,
    -35, -95, 49, -63, -92, -26, -114, 14, 14, 53, 99, 86, 77, 111, 93,
    125, 55, 127, -85, 116, -64, 94, -102, 63, 65, 26, 90, -14, -58,
    -53, 74, -86, 39, -111, -46, -126, -80, -128, -10, -118, -93, -96,
    -100, -65, -37, -28, -66, 12, 100, 51, 8, 85, 99, 110, -4, 124,
    103, 127, 104, 117, -8, 95, 45, 65, 9, 28, 42, -12, 114, -51, -89,
    -85, 20, -110, 55, -125, -125, -128, 60, -118, 111, -97, 10, -66,
    19, -29, -19, 10, -73, 49, -87, 83, 116, 109, -108, 124, -111, 127,
    31, 118, 42, 97, -67, 66, -48, 29, -5, -11, 32, -49, 8, -83, 6,
    -109, -94, -125, 93, -128, -120, -119, 63, -98, 124, -68, 77, -31,
    28, 9, 8, 48, 70, 82, 127, 108, 38, 124, -77, 127, -49, 118, 87,
    98, 74, 68, -107, 31, -51, -9, -47, -48, 110, -82, -3, -109, 20,
    -124, 62, -128, -37, -120, 20, -99, -15, -70, -119, -33, 74, 7, 86,
    46, -34, 80, -123, 107, -79, 123, -48, 127, 122, 119, -128, 99,
    -45, 69, 89, 33, -97, -7, -124, -46, -41, -81, -5, -108, -116,
    -124, 37, -128, 51, -120, -18, -101, 106, -71, -58, -35, 120, 5,
    -94, 44, 114, 79, -123, 106, 54, 123, -27, 127, 30, 120, -93, 100,
    88, 71, 26, 35, 114, -5, 58, -44, 70, -79, -2, -107, 10, -123, 18,
    -128, -110, -121, -50, -102, -26, -73, 5, -36, -91, 3, -21, 42, 2,
    78, 127, 105, -76, 122, -12, 127, -68, 120, -63, 101, -38, 72, -38,
    36, 68, -3, -15, -43, -72, -78, 6, -105, -113, -123, 7, -128, -9,
    -122, -77, -103, 102, -74, 70, -38, -46, 1, 50, 41, -114, 76, 116,
    104, 44, 122, -3, 127, 84, 121, -39, 102, 88, 74, -103, 38, 23, -1,
    -85, -41, 46, -76, 20, -104, 26, -122, 2, -128, 98, -122, -99,
    -104, -22, -76, -119, -40 };


char cosValue0_1[36*2];
char cosValue0_2[37*2];
char cosValue0_3[36*2];
char cosValue0_4[37*2];
char cosValue0_5[37*2];
char cosValue0_6[37*2];

char cosValue1[] = { -58, 21, -21, 42, -49, 62, -34, 80, -111, 96,
    116, 109, 37, 119, 93, 125, -18, 127, -61, 126, -26, 121, 123, 113,
    -63, 101, 15, 87, -45, 69, -114, 50, -48, 29, 51, 8, 90, -14, -26,
    -36, 119, -56, -88, -75, 3, -91, 6, -105, 24, -116, -116, -124,
    -103, -128, 93, -128, -38, -125, -10, -118, 123, -107, 28, -93,
    114, -77, 4, -58, 70, -38, -94, -17, 120, 5, 37, 27, 8, 48, -124,
    67, 8, 85, 18, 100, 48, 112, 9, 121, 90, 126, -3, 127, -29, 125,
    30, 120, -39, 110, 87, 98, -8, 82, 45, 65, 124, 45, 119, 24, -68,
    2, -19, -20, -85, -41, -105, -61, 70, -79, 64, -95, -3, -109, -31,
    -119, 55, -125, 48, -128, -28, -128, 76, -123, 72, -115, -99, -104,
    -11, -90, -26, -73, -14, -54, -119, -33, 19, -11, -19, 10, 119, 32,
    14, 53, 26, 72, 11, 89, 99, 103, -72, 114, -76, 122, 28, 127, -48,
    127, -55, 124, 31, 118, 3, 108, -64, 94, -70, 78, 105, 60, 85, 40,
    19, 19, 68, -3, -119, -25, -124, -46, -45, -66, 8, -83, -87, -99,
    39, -111, -30, -121, 29, -126, 3, -128, -90, -127, -9, -122, -48,
    -113, -18, -101, -8, -86, 124, -68, -8, -49, -37, -28, -120, -6,
    94, 16, -70, 37, -4, 57, -114, 76, -28, 92, -123, 106, 10, 117, 38,
    124, -93, 127, 103, 127, 116, 123, -24, 115, -6, 104, -3, 90, 88,
    74, -119, 55, 26, 35, -90, 13, -51, -9, 48, -30, 114, -51, 45, -70,
    -15, -88, 63, -102, -123, -114, 26, -122, 61, -127, 18, -128, -93,
    -126, -37, -120, -116, -110, 111, -97, 34, -81, 49, -63, 21, -43,
    58, -22, 0, 0, -58, 21, -21, 42, -49, 62, -34, 80, -111, 96, 116,
    109, 37, 119, 93, 125, -18, 127, -61, 126, -26, 121, 123, 113, -63,
    101, 15, 87, -45, 69, -114, 50, -48, 29, 51, 8, 90, -14, -26, -36,
    119, -56, -88, -75, 3, -91, 6, -105, 24, -116, -116, -124, -103,
    -128, 93, -128, -38, -125, -10, -118, 123, -107, 28, -93, 114, -77,
    4, -58, 70, -38, -94, -17, 120, 5, 37, 27, 8, 48, -124, 67, 8, 85,
    18, 100, 48, 112, 9, 121, 90, 126, -3, 127, -29, 125, 30, 120, -39,
    110, 87, 98, -8, 82, 45, 65, 124, 45, 119, 24, -68, 2, -19, -20,
    -85, -41, -105, -61, 70, -79, 64, -95, -3, -109, -31, -119, 55,
    -125, 48, -128, -28, -128, 76, -123, 72, -115, -99, -104, -11, -90,
    -26, -73, -14, -54, -119, -33, 19, -11, -19, 10, 119, 32, 14, 53,
    26, 72, 11, 89, 99, 103, -72, 114, -76, 122, 28, 127, -48, 127,
    -55, 124, 31, 118, 3, 108, -64, 94, -70, 78, 105, 60, 85, 40, 19,
    19, 68, -3, -119, -25, -124, -46, -45, -66, 8, -83, -87, -99, 39,
    -111, -30, -121, 29, -126, 3, -128, -90, -127, -9, -122, -48, -113,
    -18, -101, -8, -86, 124, -68, -8, -49, -37, -28, -120, -6, 94, 16,
    -70, 37, -4, 57, -114, 76, -28, 92, -123, 106, 10, 117, 38, 124,
    -93, 127, 103, 127, 116, 123, -24, 115, -6, 104, -3, 90, 88, 74,
    -119, 55, 26, 35, -90, 13, -51, -9, 48, -30, 114, -51, 45, -70,
    -15, -88, 63, -102, -123, -114, 26, -122, 61, -127, 18, -128, -93,
    -126, -37, -120, -116, -110, 111, -97, 34, -81, 49, -63, 21, -43,
    58, -22, 0, 0, -58, 21, -21, 42, -49, 62, -34, 80, -111, 96, 116,
    109, 37, 119, 93, 125, -18, 127, -61, 126, -26, 121, 123, 113, -63,
    101, 15, 87, -45, 69, -114, 50, -48, 29, 51, 8, 90, -14, -26, -36,
    119, -56, -88, -75, 3, -91, 6, -105, 24, -116, -116, -124, -103,
    -128, 93, -128, -38, -125, -10, -118, 123, -107, 28, -93, 114, -77,
    4, -58, 70, -38, -94, -17, 120, 5, 37, 27, 8, 48, -124, 67, 8, 85,
    18, 100, 48, 112, 9, 121, 90, 126, -3, 127, -29, 125, 30, 120, -39,
    110, 87, 98, -8, 82, 45, 65, 124, 45, 119, 24, -68, 2, -19, -20,
    -85, -41, -105, -61, 70, -79, 64, -95, -3, -109, -31, -119, 55,
    -125, 48, -128, -28, -128, 76, -123, 72, -115, -99, -104, -11, -90,
    -26, -73, -14, -54, -119, -33, 19, -11, -19, 10, 119, 32, 14, 53,
    26, 72, 11, 89, 99, 103, -72, 114, -76, 122, 28, 127, -48, 127,
    -55, 124, 31, 118, 3, 108, -64, 94, -70, 78, 105, 60, 85, 40, 19,
    19, 68, -3, -119, -25, -124, -46, -45, -66, 8, -83, -87, -99, 39,
    -111, -30, -121, 29, -126, 3, -128, -90, -127, -9, -122, -48, -113,
    -18, -101, -8, -86, 124, -68, -8, -49, -37, -28, -120, -6, 94, 16,
    -70, 37, -4, 57, -114, 76, -28, 92, -123, 106, 10, 117, 38, 124,
    -93, 127, 103, 127, 116, 123, -24, 115, -6, 104, -3, 90, 88, 74,
    -119, 55, 26, 35, -90, 13, -51, -9, 48, -30, 114, -51, 45, -70,
    -15, -88, 63, -102, -123, -114, 26, -122, 61, -127, 18, -128, -93,
    -126, -37, -120, -116, -110, 111, -97, 34, -81, 49, -63, 21, -43,
    58, -22 };

char cosValue1_1[36*2];
char cosValue1_2[37*2];
char cosValue1_3[36*2];
char cosValue1_4[37*2];
char cosValue1_5[37*2];
char cosValue1_6[37*2];

int sample_len = 0;
int sync_bits = 0;
char bits[1024] = {0};
int bitsLen = 0;
int max_len=0;
double samples_per_bit=0;
int encodedZeroCount = 0;
int negative=0;
int positive=0;
int max=0;
int count=0;
int zeros=0;
int last_len=0;
int decodingState = 0;

void lock(){
}

void unlock(){
}

void fsk_init_encode()
{
	int i = 0;
	int start1 = 0;
	int start2 = 30*2;
	int start3 = 24*2;
	int start4 = 18*2;
	int start5 = 12*2;
	int start6 = 6*2;
    
	for (i = 0; i < 160; i=i+2)
	{
		encodeBinStrStart[i] = '0';
		encodeBinStrStart[i+1] = '1';
	}
	for (i = 160; i < 200; i++)
	{
		encodeBinStrStart[i] = '1';
	}
    
	for (i = 0; i < 80; i++)
	{
		encodeBinStrEnd[i] = '1';
	}
    
	for (i = 0; i < SAMPLENUM; i++)
	{
		if (i < 36*2) {
			cosValue0_1[i] = cosValue0[i];
		} else if (i < 36*2 + 37*2) {
			cosValue0_2[i-36*2] = cosValue0[i];
		} else if (i < 36*2 + 37*2 + 36*2) {
			cosValue0_3[i-36*2-37*2] = cosValue0[i];
		} else if (i < 36*2 + 37*2 + 36*2 + 37*2) {
			cosValue0_4[i-36*2-37*2-36*2] = cosValue0[i];
		} else if (i < 36*2 + 37*2 + 36*2 + 37*2 + 37*2) {
			cosValue0_5[i-36*2-37*2-36*2-37*2] = cosValue0[i];
		} else if (i < 36*2 + 37*2 + 36*2 + 37*2 + 37*2 + 37*2) {
			cosValue0_6[i-36*2-37*2-36*2-37*2-37*2] = cosValue0[i];
		}
	}
    
	for (i = start1; i < start1 + 36*2; i++) {
		cosValue1_1[i] = cosValue1[i];
	}
    
	for (i = start2; i < start2 + 37*2; i++) {
		cosValue1_2[i-start2] = cosValue1[i];
	}
    
	for (i = start3; i < start3 + 36*2; i++) {
		cosValue1_3[i-start3] = cosValue1[i];
	}
    
	for (i = start4; i < start4 + 37*2; i++) {
		cosValue1_4[i-start4] = cosValue1[i];
	}
    
	for (i = start5; i < start5 + 37*2; i++) {
		cosValue1_5[i-start5] = cosValue1[i];
	}
    
	for (i = start6; i < start6 + 37*2; i++) {
		cosValue1_6[i-start6] = cosValue1[i];
	}
	
	LOGD("init_encode executed");
}

char *fskEncodeChar(char c){
    
	int encodedZeroRemainder = encodedZeroCount % 6;
    
	static char *result = "";
    
   	if ('0' == c) {
   		
		if (0 == encodedZeroRemainder) {
			encodedZeroCount += 1;
			sample_len = 36*2;
			return (cosValue0_1);
		} else if (1 == encodedZeroRemainder) {
			encodedZeroCount += 1;
			sample_len = 37*2;
			return (cosValue0_2);
		} else if (2 == encodedZeroRemainder) {
			encodedZeroCount += 1;
			sample_len = 36*2;
			return (cosValue0_3);
		} else if (3 == encodedZeroRemainder) {
			encodedZeroCount += 1;
			sample_len = 37*2;
			return (cosValue0_4);
		} else if (4 == encodedZeroRemainder) {
			encodedZeroCount += 1;
			sample_len = 37*2;
			return (cosValue0_5);
		} else if (5 == encodedZeroRemainder) {
			encodedZeroCount += 1;
			sample_len = 37*2;
			return (cosValue0_6);
		}
   	}
   	
   	if ('1' == c) {
   		
   		if (0 == encodedZeroRemainder) {
			sample_len = 36*2;
			return (cosValue1_1);
		} else if (1 == encodedZeroRemainder) {
			sample_len = 37*2;
			return (cosValue1_2);
		} else if (2 == encodedZeroRemainder) {
			sample_len = 36*2;
			return (cosValue1_3);
		} else if (3 == encodedZeroRemainder) {
			sample_len = 37*2;
			return (cosValue1_4);
		} else if (4 == encodedZeroRemainder) {
			sample_len = 37*2;
			return (cosValue1_5);
		} else if (5 == encodedZeroRemainder) {
			sample_len = 37*2;
			return (cosValue1_6);
		}
   	}
   	return result;
}

char *charToBinStr(char b, char *result) {
    int i;
    for ( i=0;i<8;i++){
        if ((b>>i) & 1) {
            result[i]='1';
        } else {
            result[i]='0';
        }
	}
	return result;
}

char* fsk_encode(char *toEncodeStr, int toEncodeStrLen, char *resultStr, int *resultStrLen) {
	
    char binStr[4096] = {0};
	int i,j;
	char charToBinStr_rlt[9] = {0};
	char *tmpP;
	*resultStrLen = 0;
    
	fsk_init_encode();
	strcat(binStr, encodeBinStrStart);
    
	for (i = 0; i < toEncodeStrLen; i++) {
		strcat(binStr, "0");
		for (j = 0; j < 9; j++) {
			charToBinStr_rlt[j] = 0;
		}
		strcat(binStr, charToBinStr(toEncodeStr[i], charToBinStr_rlt));
		strcat(binStr, "1");
	}
	
	strcat(binStr, encodeBinStrEnd);
    
	for (i = 0; i < (int)strlen(binStr); i++) {
		
		tmpP = fskEncodeChar(binStr[i]);
        
		for (j = 0; j < sample_len; j++) {
			resultStr[j+(*resultStrLen)] = tmpP[j];
		}
        
		(*resultStrLen) += sample_len;
	}
	return resultStr;
}

int findStartBitTime(int n){
	switch(n){
		case 8:
			return 9;
		case 9:
			return 9;
		case 10:
			return 10;
		case 11:
			return 9;
		case 12:
			return 8;
		case 13:
			return 6;
		case 14:
			return 5;
		case 15:
			return 4;
		case 16:
			return 3;
		case 17:
			return 2;
		case 18:
			return 0;
		case 19:
			return 0;
		case 20:
			return 0;
		case 21:
			return 0;
	}
	return 0;
}

void fsk_process_one_frame(float n) {
    
	char tmp1 = 0;
	int i;
	unsigned int x = 1;
    
	if (n<6 || n>27){
		if (state == bit) {
			LOGE("Codec  Error Frame Size %i,\t%f,\t%i,\t%f",state,n,max_len,samples_per_bit);
		} else if (state == ending) {
			state = end;
		    LOGD("Codec post info %i,\t%f,\t%i,\t%s,\t%f",state,n,max_len,bits,samples_per_bit);
		}
		return;
	}
    
	if (state == init) {
		if (n > g_para_enter_init_min ) {
			sync_bits += 1;
		    if (sync_bits>=10){
				g_freq_cal +=n;
			}
		} else if (n < g_para_start_max && sync_bits > 30) {
			state = bit;
			if (g_auto_freq_cal){
				g_SAMPLES_PER_BITS = (g_freq_cal / (sync_bits-9) )*2;
				LOGI("Calculated Freq = %f ", g_SAMPLES_PER_BITS);
			}
			sync_bits = 0;
		    g_freq_cal=0;
			samples_per_bit=findStartBitTime((int) n);
			max_len=(int) samples_per_bit;
			LOGD("Move to bit state with samples %f ", samples_per_bit);
		} else {
			sync_bits = 0;
		}
	} else if (state == stop) {
		samples_per_bit +=n;
		if ((last_len>g_stop_exit_max) && n <g_para_stop_exit_min){
			n=findStartBitTime(n);
			max_len=n;
            
			LOGD("Move to bit state with samples %f ", samples_per_bit);
            
			samples_per_bit=n;
			state=bit;
		} else {
			last_len=n;
		}
		if (samples_per_bit>72){
			state =ending;
            
			LOGD("End of frame, go to ending ");
		}
	} else if (state == bit) {
		samples_per_bit = samples_per_bit + n;
		
		if(samples_per_bit>g_SAMPLES_PER_BITS){
			n= (int) (g_SAMPLES_PER_BITS-(samples_per_bit-n));
			if (max_len<n){
				max_len=n;
			}
			if (max_len>g_para_bit_one_min){
                
				for (i = bitsLen; i > 0; i--) {
					bits[i] = bits[i - 1];
				}
                
				bits[0] = '1';
				bitsLen++;
			} else {
                
				for (i = bitsLen; i > 0; i--) {
					bits[i] = bits[i - 1];
				}
				bits[0] = '0';
				bitsLen++;
			}
            
			samples_per_bit = (samples_per_bit-g_SAMPLES_PER_BITS);
			max_len = (int) samples_per_bit;
			if (bitsLen == 9) {
				
				for (i = 7; i >= 0; i--) {
                    
					if ('0' == bits[i]) {
						x = (1<<(7-i)) - 1;
						tmp1 = tmp1 & x;
					}
					if ('1' == bits[i]) {
						x = 1<<(7-i);
						tmp1 = tmp1 | x;
					}
				}
			    if ('1' == bits[8] ) {
                    if ( tmp1 == 0xff) {
                        LOGE("Error decoding, the start bit should NOT be 1, go to end");
                        state = ending;
                        return;
                    } else {
                        LOGE("Error decoding, the start bit should NOT be 1, ignore");
                    }
				}
                
			    lock();
                
				inBuf[inBufIndex++] = tmp1;
                
				unlock();
                
				LOGD("added %2x inBufsize: %d", tmp1, inBufIndex);
                
				max_len = (int) samples_per_bit;
                
				for (i = 0; i < bitsLen; i++) {
					bits[i] = 0;
				}
				bitsLen = 0;
                
				last_len = (int) samples_per_bit;
				state=stop;
			}
		} else {
			if (max_len<n){
				max_len=n;
			}
		}
	}
	
	LOGD("Codec post info %i,\t%f,\t%i,\t%s,\t%f,\t%i",state,n,max_len,bits,samples_per_bit,inBufIndex);
}

void fsk_process_one_sample(int n) {
    
	static int zeros=0;
	count = count + 1;
    
	if (n > g_para_smallest_positive) {
        
		positive += 1;
        
		if (negative > 0 && max > g_para_THRESHOLD_VOL) {
			fsk_process_one_frame(count*negative_ratio);
			negative = 0;
			count = 0;
			max = 0;
			zeros=0;
		}
	} else if (n <g_para_largest_negative) {
        
		negative += 1;
		if (positive > 0 && max > g_para_THRESHOLD_VOL) {
			fsk_process_one_frame(count*positive_ratio);
			positive = 0;
			count = 0;
			max = 0;
		    zeros=0;
		}
	}  else {
	    zeros ++;
	}
    
	if ((zeros > 100) || (count > 1000)) {
		
		if(state==ending) state=end;
	}
	if (fabs(n) > max) {
		max = (int)fabs(n);
	}
}

void fsk_reset()
{
	int i;
    
    lock();
    
	for (i = 0; i < BUFFER_SIZE; i++) {
		inBuf[i] = 0;
	}
    
	inBufIndex = 0;
    
	state = init;
	sync_bits = 0;
    
	for (i = 0; i < bitsLen; i++) {
		bits[i] = 0;
	}
    
	bitsLen = 0;
	max_len=0;
	samples_per_bit=0;
	encodedZeroCount = 0;
	negative=0;
	positive=0;
	max=0;
	count =0;
	zeros=0;
	last_len=0;
	decodingState=1;
    
    unlock();
    
	LOGD("reset executed");
	LOGD("g_para_enter_init_min %d",g_para_enter_init_min);
	LOGD("g_para_start_max %d",g_para_start_max);
	LOGD("g_stop_exit_max %d",g_stop_exit_max);
	LOGD("g_para_stop_exit_min %d",g_para_stop_exit_min);
	LOGD("g_para_bit_one_min %d",g_para_bit_one_min);
}

unsigned char width0=6;
unsigned char width1=12;
unsigned char duration0=4;
unsigned char duration1=4;
unsigned char width2=0;
unsigned char duration2=0;
unsigned int jitter_threshold=1;
unsigned int samples0_min=18;
unsigned int samples0_max=28;
unsigned int samples1_min=32;
unsigned int samples1_max=64;

unsigned int samples0=0;
unsigned int samples1=0;
unsigned int samples2=0;

void new_reset();

void new_train(){
}

void new_reset(){
    
	inBufIndex = 0;
	state = init;
	decodingState=1;
	samples0 = width0 * duration0;
	samples1 = width1 * duration1;
	samples2 = width2 * duration2;
    
	LOGD("w0 %d, w1 %d ws %d d0 %d d1 %d ds %d",width0,width1,width2,duration0,duration1,duration2);
	LOGD("s0 %d, s1 %d, s2 %d, jitter %d, s0min %d, s0max %d, s1min %d, s1max %d",samples0,samples1,samples2,jitter_threshold,samples0_min,samples0_max,samples1_min,samples1_max);
}

void p_stat(int count, char b){
	switch (count){
        case 0:
            LOGD("STAT protocol version %x",b);
            break;
        case 1:
            LOGD("STAT stat_ul_char_ignored %x",b);
            break;
        case 2:
            LOGD("STAT stat_dl_han_error %x",b);
            break;
        case 3:
            LOGD("STAT width0 %x",b);
            break;
        case 4:
            LOGD("STAT duration0 %x",b);
            break;
        case 5:
            LOGD("STAT width1 %x",b);
            break;
        case 6:
            LOGD("STAT duration1 %x",b);
            break;
        case 7:
            LOGD("STAT widthS %x",b);
            break;
        case 8:
            LOGD("STAT durationS %x",b);
            break;
        default:
            LOGD("STAT unknown %x %x",count,b);
            break;
	}
}

int new_within(int n, int low, int high){
	if ((n>=low) && (n<=high)) {
		return 1;
	}
	return 0;
}

int new_bit_sync(int* history){
    
	static int sync0=65535;
	static int sync1=0;
	int sync=0;
	int i;
	int tmp;
    
	for(i=0;i<duration1;i++){
		sync=history[i]+sync;
	}
    
	LOGV("[init] sync0 %d sync1 %d sync %d",sync0,sync1,sync);
    
	if (new_within(sync1, samples1_min, samples1_max )){
		if ((sync < sync1) && (sync0<sync1)){
			sync0=65535;
			tmp = sync1;
			sync1=0;
			return tmp;
		}
	}
    
	sync0=sync1;
	sync1=sync;
	return 0;
}

#define HISTORY_SIZE 64

int new_analyze(int n){
    
	static int frame_history[HISTORY_SIZE];
	static int frame_count=0;
	static int samples_received=0;
	static int current_level=0;
	static int bit_width_count=0;
	static int bit_width=0;
    
	if(n==-1){
		bit_width = bit_width_count/12;
		LOGI("bit_width_count == %d bit_width = %d", bit_width_count,bit_width);
		bit_width_count=0;
		return -1;
	}
    
	if(bit_width_count){
		bit_width_count += n;
	}
    
	current_level = 1-current_level;
    
	if (n<=jitter_threshold && !frame_count){
		return -1;
	}
    
	samples_received=samples_received+n;
	LOGV("[%d] %d %d %d",state,n,samples_received,frame_count);
    
	if (n<=jitter_threshold){
		frame_history[0]=frame_history[0]+n;
		if (state != init){
			LOGD("NEW Found noise %d",n);
		}
		return -1;
	}
    
	int i;
    
	for (i=HISTORY_SIZE-1;i>0;i--){
		frame_history[i]=frame_history[i-1];
	}
    
	frame_history[0]=n;
	frame_count++;
    
	if ((state ==  init) && (duration0 != 1)){
		bit_width_count = new_bit_sync(frame_history);
		if (bit_width_count) {
			frame_count=1;
			samples_received = frame_history[0];
			return 1;
		} else {
			return -1;
		}
	}
    
	if (frame_count == duration0 ){
        
		if (new_within(samples_received, samples0_min,samples0_max )) {
			frame_count=0;
			samples_received =0;
			return 0;
		}
		if (new_within(samples_received, samples1_min,samples1_max )) {
			frame_count=0;
			samples_received =0;
			return 1;
		}
        
		frame_count--;
        
		samples_received = samples_received - frame_history[frame_count];
        
		return 255;
	}
    
	return -1;
}

#define SYNCBYTE 0x99

void new_process_one_byte(unsigned char b){
    
	static int stat_count=0;
	static u8 len1=0;
	static u8 len2=0;
	static u8 len3=0;
	static u8 len_count=0;
	static u8 new_len=0;
    
	switch (state){
		case init:
			LOGE("Should not in INIT state when processing byte");
			break;
		case NEWSYNC:
			if (b==SYNCBYTE){
				state=NEWLEN;
	    		new_analyze(-1);
				len_count=0;
				len1=0;
				len2=0;
				len3=0;
				LOGD("State change to NEWLEN");
			} else {
				state=init;
				LOGD("Sync byte not found, it was %x",b);
			}
			break;
		case NEWLEN:
			LOGD("Ln == %x",b);
	    	len_count++;
	    	if (len_count==1){
	    		len1=b;
	    	} else if (len_count==2){
	    		len2=b;
	    	} else if (len_count==3){
	    		len3=b;
	    		if (len1==len2){
	    			new_len=len1;
	    		} else if (len2==len3){
	    			new_len=len2;
	    		} else if (len1==len3){
	    			new_len=len3;
	    		} else {
	    			state=init;
	    			LOGV("Resetting to init... LEN = %d ?",b);
	    			return;
	    		}
	    		
	    		state=NEWBYTE;
	    		LOGD("State change to NEWBYTE, LEN == %d",new_len);
	    	}
			break;
		case NEWBYTE:
			if(new_len-->0){
				
				inBuf[inBufIndex++] =b;
				LOGD("-----------------------------------------------------byte==%x , %d bytes remaining",b,new_len);
			} else {
				state = STATISTICS;
				stat_count=0;
				LOGD("State change to STATISTICS");
			}
			break;
		case STATISTICS:
			p_stat(stat_count,b);
			stat_count++;
			break;
		case end:
			break;
		default:
			LOGE("State %d is unknown",state);
	}
}

void new_process_one_bit(int n){
	
	static u8 last_byte_data=0xFF;
	static char last_byte_bits=0;
	
	if(n == -1){
		last_byte_data=0xFF;
		last_byte_bits=0;
		return;
	}
    
	if (n==0){
		last_byte_data=last_byte_data>>1;
		last_byte_data &=0x7f;
	} else if (n==1) {
		last_byte_data=last_byte_data>>1;
		last_byte_data |=0x80;
	} else {
		LOGE("got bit %d",n);
	}
    
	last_byte_bits++;
    
	if (last_byte_bits == 8){
		new_process_one_byte(last_byte_data);
		last_byte_bits = 0;
		last_byte_data=0xFF;
	}
}

void new_process_one_frame(int n){
    
	int i = new_analyze(n);
    
	switch (i) {
        case 0:
            if (state ==  init){
                return;
            }
            new_process_one_bit(0);
            break;
        case 1:
            if(state == init) {
                state = NEWSYNC;
                new_process_one_bit(-1);
            }
            new_process_one_bit(1);
            break;
        case 2:
            new_process_one_bit(2);
            break;
        case -1:
            break;
        case 255:
            switch (state){
                case NEWBYTE:
                    LOGE("ERROR bit, re-receive");
                    state=init;
                    break;
                case NEWLEN:
                    state=init;
                    break;
                case NEWSYNC:
                    state=init;
                    break;
                case STATISTICS:
                    state=end;
                    break;
                default:
                    break;
            }
            break;
        default:
            LOGE("Unknown analyze result %d", i);
	}
}

#define POSITIVE 1
#define NEGATIVE -1

void new_process_one_sample(int n) {
    
	static int count=0;
	static int last_level = 0;
    
	int current_level;
    
	if (state==end){
		return;
	}
    
	count++;
    
	if (n > g_para_smallest_positive ) {
		current_level = POSITIVE;
	} else {
		current_level = NEGATIVE;
	}
    
	if (last_level != current_level){
		new_process_one_frame(count);
		count = 0;
		last_level=current_level;
	}
}

u8 const Han_code_book[16] =
{
	0x00, 0x1e, 0x26, 0x38,
	0x4c, 0x52, 0x6a, 0x74,
	0x8a, 0x94, 0xac, 0xb2,
	0xc6, 0xd8, 0xe0, 0xfe
};

void Han_encode(u8 pin[], u8 pout[], u8 len)
{
	int i, code;
	for(i = 0; i < len; i++)
	{
		code = pin[i];
		pout[2*i]   = Han_code_book[(code>>4) & 0x0f];
		pout[2*i+1] = Han_code_book[code & 0x0f];
	}
}

u8 const Han_err_map[8] = {0x00, 0x02,0x04,0x20, 0x08,0x80,0x40,0x10};

u8 Han_one_cnt(u8 code)
{
	code = (code & 0x55) +  ((code>>1) & 0x55);
	code = (code & 0x33) +  ((code>>2) & 0x33);
	code = (code & 0x0f) +  ((code>>4) & 0x0f);
	return (code & 0x01);
}

void Han_decode(u8 pin[], u8 pout[], u8 len)
{
	u8 i, code1, code2, errbit;
	for(i = 0; i < len; i++)
	{
		code1 = pin[2*i];
		errbit = Han_one_cnt(code1&0xd8)*4 + Han_one_cnt(code1&0x74)*2 + Han_one_cnt(code1&0xb2);
		if(errbit > 0)	code1 ^= Han_err_map[(int)errbit];
        
		code2 = pin[2*i+1];
		errbit = Han_one_cnt(code2&0xd8)*4 + Han_one_cnt(code2&0x74)*2 + Han_one_cnt(code2&0xb2);
		if(errbit > 0)	code2 ^= Han_err_map[(int)errbit];
		pout[(int)i]   = (code1&0xf0) | (code2>>4);
	}
}

int new_add_HIGH_inner(char* buf, int offset){
	*(buf+offset)=0xff;
	*(buf+offset+1)=0x7f;
	return offset+2;
}

int new_add_LOW_inner(char* buf,int offset){
	*(buf+offset)=0x00;
	*(buf+offset+1)=0x80;
	return offset+2;
}

int new_add_ZERO_inner(char* buf,int offset){
	*(buf+offset)=0x00;
	*(buf+offset+1)=0x00;
	return offset+2;
}

static int new_dl_unit_width=4;
static int current_high_level=0;

int new_add_HIGH(char* buf, int offset){
    
	int offset_,i;
	offset_=offset;
	current_high_level=1;
	
	i=0;
    
	while (i++<new_dl_unit_width){
		offset_=new_add_HIGH_inner(buf,offset_);
	}
    
	return offset_;
}

int new_add_LOW(char* buf,int offset){
    
	int offset_,i;
	offset_=offset;
	current_high_level=0;
	
	i=0;
    
	while (i++<new_dl_unit_width){
		offset_=new_add_LOW_inner(buf,offset_);
	}
    
	return offset_;
}

int new_add_ZERO_(char* buf,int offset){
    
	int offset_,i;
	offset_=offset;
	i=0;
	current_high_level=0;
    
	while (i++<new_dl_unit_width){
		offset_=new_add_ZERO_inner(buf,offset_);
	}
    
	return offset_;
}

int new_add_one(char* buf, int offset){
    
	if(!current_high_level){
		offset=new_add_HIGH(buf,offset);
		offset=new_add_HIGH(buf,offset);
	} else {
		offset=new_add_LOW(buf,offset);
		offset=new_add_LOW(buf,offset);
	}
    
	return offset;
}

int new_add_zero(char* buf, int offset){
    
	if(!current_high_level){
		offset=new_add_HIGH(buf,offset);
	} else {
		offset=new_add_LOW(buf,offset);
	}
    
	return offset;
}

int new_add_byte(char* buf, int offset, unsigned char b){
    
    int i;
    
    for ( i=0;i<8;i++){
        if ((b>>i) & 1) {
            offset=new_add_one(buf,offset);
        } else {
            offset=new_add_zero(buf,offset);
        }
	}
    
    return offset;
}

int new_add_FEC_byte(char* buf, int offset, unsigned char byte){
    
	char low = byte & 0x0f;
	char high = (byte >>4)&0x0f;
	
	offset=new_add_byte(buf,offset,Han_code_book[(int)high]);
	offset=new_add_byte(buf,offset,Han_code_book[(int)low]);
	
	return offset;
}

void new_init_encode(){
}

char* new_encode(char *toEncodeStr, int toEncodeStrLen, char *resultStr, int *resultStrLen) {
    
	int offset =0;
	int i =0;
	
	for (i=0;i<1024;i++){
		offset=new_add_ZERO_(resultStr,offset);
	}
    
	offset=new_add_HIGH(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
    
	offset=new_add_one(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_zero(resultStr,offset);
	offset=new_add_one(resultStr,offset);
	
	LOGD("encode string len %d",toEncodeStrLen);
	offset=new_add_FEC_byte(resultStr,offset,(unsigned char)toEncodeStrLen);
	offset=new_add_FEC_byte(resultStr,offset,(unsigned char)toEncodeStrLen);
	offset=new_add_FEC_byte(resultStr,offset,(unsigned char)toEncodeStrLen);
    
	for (i=0;i<toEncodeStrLen;i++){
		offset=new_add_FEC_byte(resultStr,offset,(unsigned char)toEncodeStr[i]);
	}
    
	for (i=0;i<2;i++){
		offset=new_add_zero(resultStr,offset);
	}
    
	for (i=0;i<1024;i++){
		offset=new_add_ZERO_(resultStr,offset);
	}
    
	(*resultStrLen) = offset;
    
	return resultStr;
}

char* new_encode_with_ul_coding_scheme(char *toEncodeStr, int toEncodeStrLen, char *resultStr, int *resultStrLen) {
    
	char ulcoding[10];   //fixed by Alex!,before is 8 and now is 9.
	ulcoding[0]='C';
	ulcoding[1]='U';
	ulcoding[2]=width0*1.5;
	ulcoding[3]=duration0;
	ulcoding[4]=width1*1.5;
	ulcoding[5]=duration1;
	ulcoding[6]=width2*1.5;
	ulcoding[7]=duration2;
	ulcoding[8]=0;
    ulcoding[9]=0;		    /*1 means auto power off when audio cable disconnect*/

	int resultArraySize0 = 0;
	int resultArraySize1 = 0;
    
	new_encode(ulcoding,10/*8,fixed by Alex, updated againg by WangXu*/,resultStr,&resultArraySize0);
	new_encode(toEncodeStr,toEncodeStrLen,resultStr+resultArraySize0,&resultArraySize1);
	*resultStrLen=resultArraySize0+resultArraySize1;
    
	return resultStr;
}

void reset(){
    
    LOGI("codec %s %s reset",__DATE__,__TIME__);
    
	if(g_codec_mode==FSK){
		fsk_reset();
	} else {
		new_reset();
	}
}

void init_encode(){
    
	if(g_codec_mode==FSK){
		fsk_init_encode();
	} else {
		new_init_encode();
	}
}

char* encode(char *toEncodeStr, int toEncodeStrLen, char *resultStr, int *resultStrLen) {
    
	if(g_codec_mode==FSK){
		return fsk_encode(toEncodeStr, toEncodeStrLen, resultStr, resultStrLen);
	} else {
		return new_encode_with_ul_coding_scheme(toEncodeStr, toEncodeStrLen, resultStr, resultStrLen);
	}
}

void encode2(char *toEncodeStr, int toEncodeStrLen, char *resultStr, int *resultStrLen){
	encode(toEncodeStr,toEncodeStrLen,resultStr,resultStrLen);
}

void process_one_sample(int n) {
	if(g_codec_mode==FSK){
		fsk_process_one_sample(n);
	} else {
		new_process_one_sample(n);
	}
}

void decode(char *inputBuf, int inputBufLen) {
	
	short n = 0;
	int i;
	union
	{
		short s;
		char c[2];
	} sc;
    
	if (!decodingState) {
		return;
	}
    
	for (i = 0; i < inputBufLen - 1; i = i + 2) {
	    sc.c[1]=inputBuf[i+1];
	    sc.c[0]=inputBuf[i];
	    n=sc.s;
		process_one_sample(n);
	}
}

void dataIn(char *inputBuf, int inputBufLen) {
	decode(inputBuf, inputBufLen);
}

void readMessage2(char* msg, int* rltBufLen){
    
	int i = 0;
    *rltBufLen =0;
    
	if ((state==end) || (state==STATISTICS)){
		LOGD("readMessage state: end");
		lock();
		for (i = 0; i < BUFFER_SIZE; i++) {
			msg[i] = inBuf[i];
			inBuf[i] = 0;
		}
		*rltBufLen = inBufIndex;
		LOGD( "%d chars copied from falgo", inBufIndex);
		inBufIndex = 0;
		decodingState=0;
		unlock();
	}
}

char *readMessage(int *rltBufLen) {
	readMessage2(rltBuf,rltBufLen);
	return rltBuf;
}

void recaculate_paras(){
}

