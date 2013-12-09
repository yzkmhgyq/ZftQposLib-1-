//
//  ViewController.h
//  ZftQposLibTest
//
//  Created by rjb on 13-8-1.
//  Copyright (c) 2013年 rjb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../inc/ZftQposLib.h"

@interface ViewController : UIViewController<ZftDelegate>
@property (retain, nonatomic) IBOutlet UILabel *PsamID;
@property (retain, nonatomic) IBOutlet UILabel *TerminalID;

@property (retain, nonatomic) IBOutlet UILabel *Mac;
@property (retain, nonatomic) IBOutlet UILabel *CardTrac;
@property (retain, nonatomic) IBOutlet UILabel *CardPin;

@property (retain, nonatomic) IBOutlet UITextField *Amount;




- (IBAction)Connection:(id)sender;





@end
