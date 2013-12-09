
//
//  ViewController.m
//  ZftQposLibTest
//
//  Created by rjb on 13-8-1.
//  Copyright (c) 2013年 rjb. All rights reserved.
//

#import "ViewController.h"
#import "../inc/ZftQposLib.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
	// Do any additional setup after loading the view, typically from a nib.
    
    ZftQposLib *qsdk = [ZftQposLib getInstance];
    [qsdk setLister:self];
    
    [qsdk doGetTerminalID:1];
    //[self setTck];
    
    //激活QFSDK中的QFLoginC控制器
    //在这儿把QFSDK中创建出来的Controller返回出来，这样，就可以push进去到客户端的框架中。
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getCardNum:(NSString*)cardNum;
{
    //ZftQposLib *qsdk = [ZftQposLib getInstance];
   // self.CardNum.text = cardNum;//[[ZftQposLib getInstance] getCardNum];
}

-(IBAction)dogetTerminal
{
    [[ZftQposLib getInstance] doGetTerminalID:1];
    sleep(1);
    //[self getTerminal];
    
}

-(IBAction)getTerminal
{
    NSString * result = [[ZftQposLib getInstance] getTerminalID];
    NSLog(@"%@",result);
}

- (NSString*) NSDataToHexString:(NSData*)data andStartPos:(NSInteger)startPos andLen:(NSInteger) len
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


- (IBAction)doSecurityCommand:(NSString *)command
{
    NSString * str = @"5001000078310553B8D8BAD1F83BAE8AA6562837DF1FC2B372E7C343FC0F9066D989C6B552C141FB8E6E22597BFCB877172A80206A1D3609408776BF18629C7FEB79ED4ACE3F7EA9012A4CD5180EB682993AB2EC99D30EB1699D5474B9D409125D434FE333EB5244D0153848535710BA224D26A0B8D5B41CE7D5C117F72DF999280686BBD24D3697866636963007E5C269F3B6603619D3B2A98789993300C69BECAC4991DB4CB5E8341C33533A282CD82A2CCBEB2FF24CC349D36ED9E68FED493A1F3B3FA13480F5D3663E83B1ADC161BB3823FC1059A048CA32AA6A4FF9DAB51DB604DDF55D94E6C38F1BAC78A126CF45B7720D024C618EFA62A437EAC896ED29529674559584A27FA024725037CB2231B61DABA85CDD94BB1107E2E814D4CBB6BAD5AD5403DD21D3E598D6D7E2801435DAD134011621353A762C553072FB63EC04661A8019A60B59D79B960BB582DD3B5E26CBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
    
    
    [[ZftQposLib getInstance] doSecurityCommand:str];

    
}

- (IBAction)getTck:(id)sender
{
    NSData * Tck = [[ZftQposLib getInstance] getTCK];
    NSString * result = [self NSDataToHexString:Tck andStartPos:0 andLen:Tck.length];
    NSLog(@"%@",result);
}



-(void)onPlugin{
    NSLog(@"on Plugin");
}
-(void)onPlugOut{
    NSLog(@"On Plugout");
}

/**
 *调用waitUser成功后，使用此方法得到当前交易的磁道信息。此处得到的是密文。用户磁卡的磁道信息使用磁道加密专用密钥进行3DES加密。
 */
-(void)onSwiper:(NSString*)cardNum  andcardTrac:(NSString*)cardTrac andpin:(NSString*)cardPin
{
    NSLog(@"卡号%@\n 卡磁信息%@\n 加密密码：%@\n ",cardNum,cardTrac,cardPin);
    //self.CardNum.text = cardNum;
    self.CardTrac.text = cardTrac;
    self.CardPin.text = cardPin;
    
}
-(void)onTradeInfo:(NSString*)mac andpsam:(NSString*)psam andtids:(NSString*)tids{
    NSLog(@"MAC：%@\nPASM卡号：%@\n端口号：%@\n",mac,psam,tids);
    self.Mac.text = mac;
    self.PsamID.text = psam;
    self.TerminalID.text = tids;
}
-(void)onError:(NSString*)errmsg
{
    NSLog(@"%@",errmsg);
}

-(void)doSecurityCommandStatus:(NSString *) status
{
    NSLog(@"%@",status);
}

- (void)dealloc {
    [_PsamID release];
    [_TerminalID release];
    [_Mac release];
    [_CardTrac release];
    [_CardPin release];
    [_Amount release];
    [super dealloc];
}

- (IBAction)Connection:(id)sender {
    NSString * amount = [NSString stringWithFormat:@"%@",self.Amount.text];
    [[ZftQposLib getInstance] doTradeEx:amount andType:1 andRandom:@"123" andextraString:@"100" andTimesOut:60];
}

- (IBAction)setTck
{
    //3574554d658ba10dede0813e4a6311f1
    NSString * Tck = @"3574554d658ba10dede0813e4a6311f1";
    [[ZftQposLib getInstance] setDesKey:Tck];
}

- (void)viewDidUnload {
    [self setAmount:nil];
    [super viewDidUnload];
}
@end
