//
//  FULoadingView.h
//  FUP2A
//
//  Created by L on 2018/10/25.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUP2ADefine.h"

@protocol FULoadingViewDelegate <NSObject>
@optional
- (void)shouldCreateAvatarWithGender:(FUGender)gender ;
@end

@interface FULoadingView : UIView

@property (nonatomic, assign) id<FULoadingViewDelegate>mDelegate ;

// 开始加载
- (void)startLoading ;
// 停止加载
- (void)stopLoading ;

@end
