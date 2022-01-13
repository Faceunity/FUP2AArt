//
//  AppDelegate.m
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,assign) int number;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   // [self qstyleSelected];
    [SVProgressHUD setMinimumDismissTimeInterval:2.0];
	
    return YES; 
}
- (void)qstyleSelected
{
    __weak typeof(self)weakSelf = self ;
  //  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf loadDefaultDataWithStyle:FUAvatarStyleQ];
  //  });
}

- (void)loadDefaultDataWithStyle:(FUAvatarStyle)style
{
    [[FUManager shareInstance] setAvatarStyle:style];
    
    [[FUManager shareInstance] loadClientDataWithFirstSetup:YES];
    
    __weak typeof(self)weakSelf = self ;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [weakSelf loadDefaultAvatar];
        dispatch_async(dispatch_get_main_queue(), ^{
          //  [SVProgressHUD dismiss];
           // [self performSegueWithIdentifier:@"showMainViewController" sender:nil];
        });
    });
}

- (void)loadDefaultAvatar
{
    FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
    [avatar setCurrentAvatarIndex:0];
    [[FUManager shareInstance] reloadAvatarToControllerWithAvatar:avatar];
    [avatar loadStandbyAnimation];
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

-(void)applicationWillEnterForeground:(UIApplication *)application
{
   [self endBack];
}
@end
