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

@property (nonatomic, strong) NSTimer *timer ;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SVProgressHUD setMinimumDismissTimeInterval:2.0];
    return YES; 
}

static UIBackgroundTaskIdentifier _backId ;
-(void)applicationDidEnterBackground:(UIApplication *)application {
    
    // 正在生成，开辟后台保证生成完成
    if ([[FUManager shareInstance] isCreatingAvatar]) {
        
        _backId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            
            [[UIApplication sharedApplication] endBackgroundTask:_backId];
            _backId = UIBackgroundTaskInvalid;
        }];
        
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil ;
        }
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(checkTask) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

-(void)applicationDidBecomeActive:(UIApplication *)application {
    [self endCheckTask];
}

static int checkTimers = 0 ;
- (void)checkTask {
    
    checkTimers ++ ;
    // 生成完成 || 180s 内 结束
    if (![[FUManager shareInstance] isCreatingAvatar] || checkTimers > 55) {
        [self endCheckTask] ;
    }
}

- (void)endCheckTask {
    [self.timer invalidate];
    self.timer = nil ;
    [[UIApplication sharedApplication] endBackgroundTask:_backId];
    _backId = UIBackgroundTaskInvalid;
    
    checkTimers = 0 ;
}

@end
