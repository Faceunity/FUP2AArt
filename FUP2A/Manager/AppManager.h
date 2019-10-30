//
//  AppManager.h
//  FUP2A
//
//  Created by LEE on 6/18/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppManager : NSObject
@property (assign, nonatomic) BOOL OpenGLESCapture;
@property (assign, nonatomic) BOOL localizeHairBundlesSuccess;   // 本地发型bundles是否保存完成
@property (assign, nonatomic) BOOL isXFamily;   // 是不是iphonex家族
// 记录当前FUEditViewController 
@property (nonatomic,strong) FUEditViewController * editVC;
@property (nonatomic,assign) double colorSliderStep;   // 渐变色条  间隔
+ (AppManager *)sharedInstance;
-(void)checkSavePhotoAuth:(void (^)(PHAuthorizationStatus status))isAuthorizedCompletion;
-(void)openAppSettingView;
-(UIColor *)returnFUGradientSliderColor:(float) progress;

@end

NS_ASSUME_NONNULL_END
