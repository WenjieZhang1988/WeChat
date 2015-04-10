//
//  WJChatViewController.h
//  WeChat
//
//  Created by Kevin on 15/4/8.
//  Copyright (c) 2015年 Kevin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WJChatViewController : UIViewController

/** 当前聊天窗口 对方的JID */
@property (nonatomic, strong) XMPPJID *chatJID;
/** 聊天表格 */
@property (weak, nonatomic) IBOutlet UITableView *messageTable;
/** 发送消息框 */
@property (weak, nonatomic) IBOutlet UITextField *inputBox;
/** 信息结合 */
@property (nonatomic, strong) NSArray *chatHistory;
/** 发送信息框底部的自动布局 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLayout;

@end
