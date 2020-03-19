//
//  FUGradientSlider.h
//  FUP2A
//
//  Created by LEE on 7/8/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol FUGradientSliderDelegate <NSObject>

- (void)gradientSliderValueChangeFinished:(float)value;

@end
//IB_DESIGNABLE
@interface FUGradientSlider : UIControl

@property (nonatomic) IBInspectable BOOL isRainbow;
@property (nonatomic) IBInspectable CGFloat minValue;
@property (nonatomic) IBInspectable CGFloat maxValue;
@property (nonatomic) IBInspectable CGFloat value;
@property (nonatomic, strong) IBInspectable UIImage *minValueImage;
@property (nonatomic, strong) IBInspectable UIImage *maxValueImage;
@property (nonatomic) IBInspectable CGFloat thickness;
@property (nonatomic, strong) IBInspectable UIImage *thumbIcon;
@property (nonatomic) IBInspectable CGFloat thumbSize;
@property (nonatomic, strong, getter=thumbColor) IBInspectable UIColor *thumbColor;
@property (nonatomic, strong, getter=valueColor) UIColor *valueColor;

@property (nonatomic, strong) IBInspectable UIColor *thumbBorderColor;
@property (nonatomic) IBInspectable CGFloat thumbBorderWidth;
@property (nonatomic) IBInspectable CGFloat trackBorderWidth;
@property (nonatomic, strong) IBInspectable UIColor *trackBorderColor;
@property (nonatomic, weak) IBInspectable  id <FUGradientSliderDelegate> delegate;


@property (nonatomic, copy) void (^actionBlock)(FUGradientSlider *slider,CGFloat newValue, BOOL endTracking);

@end
