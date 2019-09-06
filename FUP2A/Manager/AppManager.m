//
//  AppManager.m
//  FUP2A
//
//  Created by LEE on 6/18/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "AppManager.h"
@interface AppManager()
{
float _RStep;
float _GStep;
float _BStep;
}
@end
static AppManager *sharedInstance;
@implementation AppManager


+ (AppManager *)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AppManager alloc] init];
		int colorsCount = [FUManager shareInstance].skinColorArray.count;
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


-(UIColor *)returnFUGradientSliderColor:(float) progress{
// 获取颜色区间的位置
   double colorIndexDouble = progress / self.colorSliderStep;
	int colorIndex = colorIndexDouble;
	FUP2AColor * baseColor = [FUManager shareInstance].skinColorArray[colorIndex];
	UIColor * newColor;
	if (colorIndex >= [FUManager shareInstance].skinColorArray.count - 1) {
		newColor = baseColor.color;
}else{
	FUP2AColor * nextColor = [FUManager shareInstance].skinColorArray[colorIndex + 1];
	_RStep = (nextColor.r - baseColor.r);
	_GStep = (nextColor.g - baseColor.g);
	_BStep = (nextColor.b - baseColor.b);
	double colorInterval = colorIndexDouble - colorIndex;
	newColor = [UIColor colorWithRed:(baseColor.r + _RStep * colorInterval)/ 255.0 green:(baseColor.g + _GStep * colorInterval)/ 255.0 blue:(baseColor.b + _BStep * colorInterval)/ 255.0 alpha:1];
	}
	return newColor;
}
@end
