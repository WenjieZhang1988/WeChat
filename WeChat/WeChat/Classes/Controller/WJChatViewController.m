//
//  WJChatViewController.m
//  WeChat
//
//  Created by Kevin on 15/4/8.
//  Copyright (c) 2015年 Kevin. All rights reserved.
//

#import "WJChatViewController.h"

@interface WJChatViewController () <UITableViewDataSource,UITextFieldDelegate,XMPPStreamDelegate>


@end

@implementation WJChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.chatJID.bare;
    [[WJXMPPTool sharedInstance].xmppStrem addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
    // 加载聊天记录
    [self fetchChatHistoryFromCoreData];
}

/**
 *  将聊天记录滚动到最后一条
 */
- (void)scrollToBottom {
    // 聊天记录小于2行的时候列表就不用支持滚动了
    if (self.chatHistory.count>2) {
        [self.messageTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.chatHistory.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

/**
 *  加载聊天记录
 */
- (void)fetchChatHistoryFromCoreData {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        XMPPMessageArchivingCoreDataStorage * storage =  [XMPPMessageArchivingCoreDataStorage sharedInstance];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:storage.mainThreadManagedObjectContext];
        [fetchRequest setEntity:entity];
        // 筛选条件怎么写? 所有的聊天记录中 筛选出 与当前的这个聊天窗口的JID相等的那些聊天记录
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr = %@", self.chatJID.bare];
        [fetchRequest setPredicate:predicate];
        // Specify how the fetched objects should be sorted
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                       ascending:YES];
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [storage.mainThreadManagedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            // 聊天记录为空时什么也不做
        }else{
            self.chatHistory = fetchedObjects;
            [self.messageTable reloadData];
            [self scrollToBottom];
        }
    });
}

#pragma mark - <UITableViewDataSource> 表格数据源
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chatHistory.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    XMPPMessageArchiving_Message_CoreDataObject * message = self.chatHistory[indexPath.row];
    NSString * identifier = message.isOutgoing?@"MessageCellRight":@"MessageCellLeft";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    UIImageView *avatar=(UIImageView *)[cell viewWithTag:10001];
    UILabel *contentLabel=(UILabel *)[cell viewWithTag:10002];
    
    [contentLabel setText:message.body];
    return cell;
}

#pragma mark - 键盘事件
- (void)keyboardWillChangeFrame:(NSNotification *)noti{
    CGRect keyboardFrame = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _bottomLayout.constant = keyboardFrame.size.height;
    CGFloat duration= [noti.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
    [self scrollToBottom];
}

- (void)keyboardWillHide{
    _bottomLayout.constant = 0;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
    [self scrollToBottom];
}

#pragma mark - <UITextFieldDelegate> 文本框代理
/**
 *  文本框按下发送键
 *
 *  @param textField 文本输入框
 *
 *  @return 是否发送
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    XMPPMessage * message = [XMPPMessage messageWithType:@"chat" to:self.chatJID];
    [message addBody:textField.text];
    [[WJXMPPTool sharedInstance].xmppStrem sendElement:message];
    [textField setText:@""];
    [self.view endEditing:YES];
    return YES;
}

#pragma mark - <XMPPStreamDelegate> xml流代理
/**
 *  当接受到新的(基本的聊天消息)消息时进入的委托
 *
 *  @param sender  xml流
 *  @param message 消息对象
 */
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    //当这条消息的from是这个self.chatJID
    if ([message.from.bare isEqualToString:self.chatJID.bare]){
        [self fetchChatHistoryFromCoreData];
    }
}

/**
 *  消息发出时调用
 *
 *  @param sender  xml流
 *  @param message 消息对象
 */
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message{
    if ([message.to.bare isEqualToString:self.chatJID.bare]){
        [self fetchChatHistoryFromCoreData];
    }
}

@end
