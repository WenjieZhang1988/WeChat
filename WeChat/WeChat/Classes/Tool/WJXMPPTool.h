//
//  WJXMPPTool.h
//  WeChat
//
//  Created by Kevin on 15/4/8.
//  Copyright (c) 2015年 Kevin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPLogging.h"
#import "DDLog.h"
#import "DDTTYLogger.h"


@interface WJXMPPTool : NSObject

/** 用户密码 */
@property (nonatomic, copy) NSString *myPassword;
/** 核心xml流 */
@property (nonatomic, strong) XMPPStream *xmppStrem;
/** 心跳检测模块 */
@property (nonatomic, strong) XMPPAutoPing *xmppAutoPing;
/** 自动重连模块 */
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
/** 好友(花名册)模块 */
@property (nonatomic, strong) XMPPRoster *xmppRoster;
/** 聊天记录同步模块 */
@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchiving;
/** 文件接收模块 */
@property (nonatomic, strong) XMPPIncomingFileTransfer *xmppIncomingFileTransfer;

/**
 *  控制所有XMPP模块操作
 *
 *  @return WJXMPPTool单例
 */
+ (instancetype)sharedInstance;
/**
 *  用户登陆（zhangsan@Kevin.local）
 *
 *  @param aJID     自己的Jabber ID账户：用户名+域名+资源名
 *  @param password 密码
 */
- (void)loginWithJID:(XMPPJID *)aJID andPassword:(NSString *)password;
/**
 *  带内注册用户（zhangsan@Kevin.local）
 *
 *  @param aJID     Jabber ID账户：用户名+域名+资源名
 *  @param password 密码
 */
- (void)registerWithJID:(XMPPJID *)aJID andPassword:(NSString *)password;


@end

