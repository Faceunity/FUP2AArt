//
//  AppDelegate.m
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import "AppDelegate.h"
#import <SVProgressHUD.h>
#import <Photos/Photos.h>

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [SVProgressHUD setMinimumDismissTimeInterval:2.0];
    [self getAuthorityOfPhotoLibrary];
    return YES; 
}

- (void)getAuthorityOfPhotoLibrary {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    }];
}
@end
