//
//  WJXMPPTool.m
//  WeChat
//
//  Created by Kevin on 15/4/8.
//  Copyright (c) 2015年 Kevin. All rights reserved.
//

#import "WJXMPPTool.h"

@interface WJXMPPTool () <XMPPStreamDelegate,XMPPIncomingFileTransferDelegate>

/** 是否登陆 */
@property (assign, nonatomic) BOOL isRegister;

@end

@implementation WJXMPPTool

#pragma mark - 单例XMPP工具
static WJXMPPTool * _Instance;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _Instance = [WJXMPPTool new];
        // 控制台彩色打印
        [_Instance setUpDDLog];
    });
    return _Instance;
}

/**
 *  配置彩色打印
 */
- (void)setUpDDLog {
    // 步骤1:添加日志工具
    // 1.客户端发送给服务器的 以及 2.服务器返回给客户端
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:XMPP_LOG_FLAG_SEND_RECV];
    // 步骤2:开启DDTTYLoger的颜色输出模式并且在当前taget中点击edit schema 添加环境变量 XcoderColors=YES
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    // 步骤3:按级别设置颜色(发送的数据颜色)
    [[DDTTYLogger sharedInstance]setForegroundColor:[UIColor blueColor] backgroundColor:[UIColor whiteColor] forFlag:XMPP_LOG_FLAG_SEND];
    // 接受到的数据颜色
    [[DDTTYLogger sharedInstance]setForegroundColor:[UIColor redColor] backgroundColor:[UIColor whiteColor] forFlag:XMPP_LOG_FLAG_RECV_POST];
}

#pragma mark - 核心xml流
- (XMPPStream *)xmppStrem {
    if (!_xmppStrem) {
        _xmppStrem = [[XMPPStream alloc]init];
        
        // 因为XMPPFrameWork里面所有的委托都使用的是GCDMultiCastDelegate
        [_xmppStrem addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_xmppStrem setHostName:@"127.0.0.1"];
        [_xmppStrem setHostPort:5222];
        
        // 添加功能模块
        [self addModules];
    }
    return _xmppStrem;
}

/**
 *  添加功能模块
 */
- (void)addModules {
    // 1.心跳检测模块
    _xmppAutoPing = [[XMPPAutoPing alloc]initWithDispatchQueue:dispatch_get_main_queue()];
    [_xmppAutoPing setRespondsToQueries:YES];
    [_xmppAutoPing setPingInterval:360];
    [_xmppAutoPing setPingTimeout:5];
    
    // 2.自动重连模块
    _xmppReconnect = [[XMPPReconnect alloc]initWithDispatchQueue:dispatch_get_main_queue()];
    [_xmppReconnect setAutoReconnect:YES];
    
    // 3.好友模块
    //好友存储器使用单例获取,前提是这个APP不会进行账户切换(据个例子 张三的好友跟李四的好友会存放在一张表中引发问题)
    _xmppRoster = [[XMPPRoster alloc]initWithRosterStorage:[XMPPRosterCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    
    //好友模块有自动获取策略(登录成功之后)
    [_xmppRoster setAutoFetchRoster:NO];
    
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    
    // 4.聊天记录同步模块 这个模块很遗憾,没有委托
    _xmppMessageArchiving = [[XMPPMessageArchiving alloc]initWithMessageArchivingStorage:[XMPPMessageArchivingCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    
    // 5.文件接收模块
    _xmppIncomingFileTransfer = [[XMPPIncomingFileTransfer alloc]initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    [_xmppIncomingFileTransfer setAutoAcceptFileTransfers:YES];
    
    [_xmppIncomingFileTransfer addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    
    // 激活这些模块（所有的模块都需要激活 在不需要的时候 需要 deactive）
    [_xmppAutoPing activate:self.xmppStrem];
    [_xmppReconnect activate:self.xmppStrem];
    [_xmppRoster activate:self.xmppStrem];
    [_xmppMessageArchiving activate:self.xmppStrem];
    [_xmppIncomingFileTransfer activate:self.xmppStrem];
}

#pragma mark - 登陆
- (void)loginWithJID:(XMPPJID *)aJID andPassword:(NSString *)password {
    // 连接该方法必须在你知道自己的JID之后才能调用
    [self.xmppStrem setMyJID:aJID];
    self.myPassword = password;
    [self.xmppStrem connectWithTimeout:XMPPStreamTimeoutNone error:nil];
    self.isRegister = NO;
}

- (void)registerWithJID:(XMPPJID *)aJID andPassword:(NSString *)password {
    // 连接方法必须在你知道自己的JID之后才能调用
    [self.xmppStrem setMyJID:aJID];
    self.myPassword = password;
    [self.xmppStrem connectWithTimeout:XMPPStreamTimeoutNone error:nil];
    self.isRegister = YES;
}

#pragma mark - <XMPPStreamDelegate>
/**
 *  XMPP socket流成功建立后调用
 *
 *  @param sender socket流
 */
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    if (self.isRegister) {
        [self.xmppStrem registerWithPassword:self.myPassword error:nil];
    }else {
        [self.xmppStrem authenticateWithPassword:self.myPassword error:nil];
    }
}

/**
 *  账户验证成功时调用（认证+上线==登录）
 *
 *  @param sender xml流
 */
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    XMPPPresence *presence = [XMPPPresence presence];
    [presence addChild:[DDXMLElement elementWithName:@"show" stringValue:@"away"]];
    [self.xmppStrem sendElement:presence];
    // 跳转storyBoard
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"WeChat" bundle:nil];
    [[[[UIApplication sharedApplication]delegate]window]setRootViewController:storyBoard.instantiateInitialViewController];
}

/**
 *  当接受到新的(基本的聊天消息)消息时调用
 *
 *  @param sender  xml流
 *  @param message 消息对象
 */
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"新消息" message:message.body delegate:nil cancelButtonTitle:@"ok" otherButtonTitles: nil];
    [alert show];
}

/**
 *  出席时调用
 *
 *  @param sender   xml流
 *  @param presence 出席
 */
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    // 被别人添加为好友
    if ( [presence.type isEqualToString:@"subscribe"]) {
        [[WJXMPPTool sharedInstance].xmppRoster acceptPresenceSubscriptionRequestFrom:presence.from andAddToRoster:YES];
    }
}

#pragma mark - <XMPPIncomingFileTransferDelegate> 文件接收模块的代理
/**
 *  接收文件失败时调用
 *
 *  @param sender xml流
 *  @param error  错误
 */
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
                didFailWithError:(NSError *)error{
    
}

/**
 *  接收文件中断时调用
 *
 *  @param sender xml流
 *  @param offer  原因
 */
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
               didReceiveSIOffer:(XMPPIQ *)offer{
    
}

/**
 *  接收文件成功时调用
 *
 *  @param sender xml流
 *  @param data   文件二进制数据
 *  @param name   文件名
 */
- (void)xmppIncomingFileTransfer:(XMPPIncomingFileTransfer *)sender
              didSucceedWithData:(NSData *)data
                           named:(NSString *)name{
    // 虽然我们接收到了文件 但是呢由于文件传输并没有生成XMPPMessage 因此 MessageArchiving 模块 没有帮我们插入这个信息到数据库,因此聊天界面是看不到的
    // 因此我们要 自己创建一个XMPPMessage对象,然后呢 让我的消息存储器来存到数据库里面
}


@end
