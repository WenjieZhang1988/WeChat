//
//  WJContactsViewController.h
//  WeChat
//
//  Created by Kevin on 15/4/8.
//  Copyright (c) 2015年 Kevin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WJContactsViewController : UITableViewController <XMPPRosterDelegate>

/** 好友列表 */
@property (nonatomic, strong) NSArray *contacts;

/**
 *  添加好友
 *
 *  @param sender xml流
 */
- (IBAction)addFriend:(id)sender;

@end
