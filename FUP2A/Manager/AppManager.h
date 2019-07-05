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
+ (AppManager *)sharedInstance;
-(void)checkSavePhotoAuth:(void (^)(PHAuthorizationStatus status))isAuthorizedCompletion;
-(void)openAppSettingView;
@end

NS_ASSUME_NONNULL_END
