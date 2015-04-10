//
//  WJContactsViewController.m
//  WeChat
//
//  Created by Kevin on 15/4/8.
//  Copyright (c) 2015年 Kevin. All rights reserved.
//

#import "WJContactsViewController.h"
#import "WJChatViewController.h"

@interface WJContactsViewController ()

@end

@implementation WJContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 异步获取一次好友花名册
    [[WJXMPPTool sharedInstance].xmppRoster addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    [[WJXMPPTool sharedInstance].xmppRoster fetchRoster];
}

#pragma mark - <UITableViewDelegate> 好友列表表格代理
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.contacts.count;
}

/**
 *  设置好友列表信息
 */
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
    XMPPUserCoreDataStorageObject *user=self.contacts[indexPath.row];
    
    UIImageView *avatar=(UIImageView *)[cell viewWithTag:10001];
    UILabel *nameLabel=(UILabel *)[cell viewWithTag:10002];
    if (user.photo) {
        //还没激活头像模块,因此头像是空的
        [avatar setImage:user.photo];
    }
    // 判断是否需要显示备注名
    if (user.nickname)
        [nameLabel setText:user.nickname];
    else
        [nameLabel setText:user.jidStr];
    return cell;
}

/**
 *  跳转至聊天界面
 *
 *  @param segue  连线
 *  @param sender 连线的触发者
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell *)sender {
    WJChatViewController * chatVC = segue.destinationViewController;
    long row = [self.tableView indexPathForCell:sender].row;
    XMPPUserCoreDataStorageObject *user = self.contacts[row];
    chatVC.chatJID= user.jid;
}

/**
 *  COREDATA存储器中取出所有好友列表
 */
- (void) fetchRosterFromCoreData{
    
    // 1.创建一个查询请求从存储器中取出好友列表(一组XMPPUserCoreDataStorageObject)
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // 2.创建实体描述器需要传一个实体名(与我们的模型文件中的实体名对应)
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext];
    [fetchRequest setEntity:entity];
    // 上面两步相当于SQL语句中的 select * from xxxTable where subscription = 'both'
    // 谓词 负责过滤 相当于where xxx  过滤出非双向好友(只留下 subscription 为 both的)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subscription = %@", @"both"];
    [fetchRequest setPredicate:predicate];
    
    // 3.排序器
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"jidStr"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    // 4.在这个上下中执行这个查询对象
    NSError *error = nil;
    NSArray *fetchedObjects = [[XMPPRosterCoreDataStorage sharedInstance].mainThreadManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // 查询好友列表为空时
    }
    
    // 5. 刷新UI
    self.contacts = fetchedObjects;
    [self.tableView reloadData];
}


#pragma mark - <XMPPRosterDelegate> 好友模块代理
/**
 *  清点人数完毕
 *
 *  @param sender 好友模块
 */
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender {
    
    // 必须在主线程操作好友列表
    dispatch_async(dispatch_get_main_queue(), ^{
        // 获取好友列表
        [self fetchRosterFromCoreData];
    });
}

/**
 *  收到好友请求 (别人要加你)  --接收好友请求这种事情就不要在通讯录这种第二页才加载的控制器里面做了
 *
 *  @param sender   好友模块
 *  @param presence 当前这一条好友请求
 */
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
    
}

/**
 *  添加好友与删除好友 都会进入这个代理方法
 *
 *  @param sender 好友模块
 *  @param iq     关于这次好友变化的那条INFO / Query
 */
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq {
    
    // 不管是我被删了 还是 有新的好友 我都直接跟数据库里面的好友列表同步一次
    dispatch_async(dispatch_get_main_queue(), ^{
        // 获取好友列表
        [self fetchRosterFromCoreData];
    });
}

- (IBAction)addFriend:(id)sender {
    // 这里的nickName是备注(添加好友的时候) 跟用户个人资料中的 昵称 是不一样的
    [[WJXMPPTool sharedInstance].xmppRoster addUser:[XMPPJID jidWithString:@"lisi@Kevin.local"] withNickname:@"李四"];
}

@end
