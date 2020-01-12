//
//  AppDelegate.m
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import "AppDelegate.h"
#import <SVProgressHUD.h>
#import "FUManager.h"

@interface AppDelegate ()
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) int number;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SVProgressHUD setMinimumDismissTimeInterval:2.0];
    return YES; 
}

static UIBackgroundTaskIdentifier _backIden ;
//app进入后台后保持运行
- (void)beginTask
{
    _backIden = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        //如果在系统规定时间3分钟内任务还没有完成，在时间到之前会调用到这个方法
        [self endBack];
    }];
}

//结束后台运行，让app挂起
- (void)endBack
{
    //切记endBackgroundTask要和beginBackgroundTaskWithExpirationHandler成对出现
    [[UIApplication sharedApplication] endBackgroundTask:_backIden];
    _backIden = UIBackgroundTaskInvalid;
}

//示例
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self beginTask];
}
-(void)applicationWillEnterForeground:(UIApplication *)application{
   [self endBack];
}
@end
