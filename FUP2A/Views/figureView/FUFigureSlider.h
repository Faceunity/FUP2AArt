//
//  FUFigureSlider.h
//  EditView
//
//  Created by L on 2018/11/5.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    FUFigureSliderTypeShape            = 0,
    FUFigureSliderTypeOther            = 1,
} FUFigureSliderType;

@interface FUFigureSlider : UISlider

@property (nonatomic, assign) FUFigureSliderType type ;
@end
