//
//  FUSwitch.h
//  FUP2A
//
//  Created by Chen on 2020/4/3.
//  Copyright © 2020 L. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FUSwitch;
@protocol FUSwitchDelegate <NSObject>

@optional
- (void)switchView:(FUSwitch *)switchView isOn:(BOOL)on;

@end

NS_ASSUME_NONNULL_BEGIN

@interface FUSwitch : UIView
@property (nonatomic, strong) UIColor *offColor;
@property (nonatomic, strong) UIColor *onColor;
@property (nonatomic, copy) NSString *onTitle;
@property (nonatomic, copy) NSString *offTitle;
@property (nonatomic, weak) id<FUSwitchDelegate> delegate;
@property (nonatomic, assign) BOOL on;  //右侧为开，左侧为关
@end

NS_ASSUME_NONNULL_END
