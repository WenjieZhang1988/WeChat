//
//  ViewController.m
//  WeChat
//
//  Created by Kevin on 15/4/7.
//  Copyright (c) 2015年 Kevin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 用户登陆
    [[WJXMPPTool sharedInstance] loginWithJID:[XMPPJID jidWithUser:@"lisi" domain:@"Kevin.local" resource:@"iOS"] andPassword:@"lisi"];
}

@end
