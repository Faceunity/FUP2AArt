//
//  AppManager.m
//  FUP2A
//
//  Created by LEE on 6/18/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "AppManager.h"

static AppManager *sharedInstance;
@implementation AppManager


+ (AppManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppManager alloc] init];
    });
    return sharedInstance;
}

-(void)checkSavePhotoAuth:(void (^)(PHAuthorizationStatus status))isAuthorizedCompletion{
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	
	if (status == PHAuthorizationStatusAuthorized) {
		// Access has been granted.
		isAuthorizedCompletion(PHAuthorizationStatusAuthorized);
	}
	
	else if (status == PHAuthorizationStatusDenied) {
		// Access has been denied.
		isAuthorizedCompletion(PHAuthorizationStatusDenied);
	}
	
	else if (status == PHAuthorizationStatusNotDetermined) {
		
		// Access has not been determined.
		[PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
			
			if (status == PHAuthorizationStatusAuthorized) {
				// Access has been granted.
				isAuthorizedCompletion(PHAuthorizationStatusAuthorized);
			}
			
			else {
				// Access has been denied.
				isAuthorizedCompletion(PHAuthorizationStatusDenied);
			}
		}];
	}
	
	else if (status == PHAuthorizationStatusRestricted) {
		// Restricted access - normally won't happen.
		isAuthorizedCompletion(PHAuthorizationStatusRestricted);
	}
}
// 跳转至app设置界面
-(void)openAppSettingView{
	NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
	if ([[UIApplication sharedApplication] canOpenURL:url])
	{
		[[UIApplication sharedApplication] openURL:url];
		
	}
}

@end
