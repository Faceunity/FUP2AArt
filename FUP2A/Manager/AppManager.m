//
//  AppManager.m
//  FUP2A
//
//  Created by LEE on 6/18/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "../AppDelegate.h"
@interface AppManager()
{
float _RStep;
float _GStep;
float _BStep;
}
@end
static AppManager *sharedInstance;
@implementation AppManager

-(BOOL)checkIsXFamily{
	if (@available(iOS 11.0, *)) {
	return [UIApplication sharedApplication].delegate.window.safeAreaInsets.top > 20;
	} else {
		// Fallback on earlier versions
	}
	return false;
}
+ (AppManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppManager alloc] init];
        sharedInstance.isXFamily = [sharedInstance checkIsXFamily];
        
		NSInteger colorsCount = [[FUManager shareInstance] getColorArrayCountWithType:FUFigureColorTypeSkinColor];;
		double step = 1.0 / (colorsCount - 1);
        sharedInstance.colorSliderStep = step;
		float minColorArr[3] = FUGradientSlider_minColorArr;
	    float maxColorArr[3] = FUGradientSlider_maxColorArr;
		sharedInstance->_RStep = maxColorArr[0] - minColorArr[0];
		sharedInstance->_GStep = maxColorArr[1] - minColorArr[1];
		sharedInstance->_BStep = maxColorArr[2] - minColorArr[2];
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
// 以iphone11 作为参照物，来降低高分辨率，解决高分辨率手机卡顿问题
+(CGSize)getSuitablePixelBufferSizeForCurrentDevice{
	int iphone11_w = 750;
	int iphone11_h = 1624;
	CGSize size = [UIScreen mainScreen].currentMode.size;
	CGFloat current_iphone_w = size.width;
	CGFloat current_iphone_h = size.height;
	CGFloat scale = [UIScreen mainScreen].scale;
	if (current_iphone_w * current_iphone_h > iphone11_w * iphone11_h && scale == 3) {   // 以iphone11 作为参照物，来降低高分辨率，解决高分辨率手机卡顿问题
		CGFloat new_current_iphone_w = size.width / 3 * 2;
		CGFloat new_current_iphone_h = size.height / 3 * 2;
		return CGSizeMake(new_current_iphone_w, new_current_iphone_h);
	}
	return size;
}
@end
