//
//  FUFigureSlider.m
//  FUP2A
//
//  Created by L on 2019/1/9.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUFigureSlider.h"
#import "UIColor+FU.h"

@implementation FUFigureSlider
{
    UILabel *tipLabel;
    UIImageView *bgImgView;
    
    UIView *middleView ;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setThumbImage:[UIImage imageNamed:@"figure-slider-dot"] forState:UIControlStateNormal];
    
    UIImage *bgImage = [UIImage imageNamed:@"figure-slider-tip-bg"];
    bgImgView = [[UIImageView alloc] initWithImage:bgImage];
    bgImgView.frame = CGRectMake(0, -bgImage.size.height, bgImage.size.width, bgImage.size.height);
    [self addSubview:bgImgView];
    
    tipLabel = [[UILabel alloc] initWithFrame:bgImgView.frame];
    tipLabel.text = @"";
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.font = [UIFont systemFontOfSize:12];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:tipLabel];
    
    bgImgView.hidden = YES;
    tipLabel.hidden = YES;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    if (!middleView) {
        middleView = [[UIView alloc] initWithFrame:CGRectMake(2, self.frame.size.height /2.0 - 1.5, 100, 3)];
        middleView.backgroundColor = [UIColor colorWithHexColorString:@"4C96FF"];
        [self insertSubview:middleView atIndex: self.subviews.count - 1];
    }
    CGFloat value = self.value ;
    [self setValue:value animated:NO];
}

-(void)setType:(FUFigureSliderType)type {
    _type = type ;
    switch (type) {
        case FUFigureSliderTypeShape:{
            [self setMaximumValue:1.0];
            [self setMinimumValue:-1.0];
        }
            break;
        case FUFigureSliderTypeOther:{
            [self setMaximumValue:0.99];
            [self setMinimumValue:0];
        }
            break ;
    }
    CGFloat value = self.value ;
    [self setValue:value animated:NO];
}

// 后设置 value
- (void)setValue:(float)value animated:(BOOL)animated   {
    [super setValue:value animated:animated];
    
    switch (self.type) {
        case FUFigureSliderTypeShape:{
            CGFloat width = value * (self.frame.size.width - 4) / 2.0;
            if (width < 0 ) {
                width = -width ;
            }
            CGFloat X = value > 0 ? self.frame.size.width / 2.0 : self.frame.size.width / 2.0 - width ;
            
            CGRect frame = middleView.frame ;
            frame = CGRectMake(X, frame.origin.y, width, frame.size.height) ;
            middleView.frame = frame ;
            
            tipLabel.text = [NSString stringWithFormat:@"%d",(int)(value * 100)];
            CGFloat tipX = (value + 1) * (self.frame.size.width - 20)/ 2.0 - tipLabel.frame.size.width * 0.5 + 10;
            CGRect tipFrame = tipLabel.frame;
            tipFrame.origin.x = tipX;
            bgImgView.frame = tipFrame;
            tipLabel.frame = tipFrame;
        }
            break;
        case FUFigureSliderTypeOther:{
            CGFloat width = value * (self.frame.size.width - 4);
            
            CGRect frame = middleView.frame ;
            frame = CGRectMake(0, frame.origin.y, width, frame.size.height) ;
            middleView.frame = frame ;
            
            
            tipLabel.text = [NSString stringWithFormat:@"%d",(int)(value * 100)];
            CGFloat tipX = value * (self.frame.size.width - 20) - tipLabel.frame.size.width * 0.5 + 10;
            CGRect tipFrame = tipLabel.frame;
            tipFrame.origin.x = tipX;
            bgImgView.frame = tipFrame;
            tipLabel.frame = tipFrame;
        }
            break ;
    }
    
    tipLabel.hidden = !self.tracking;
    bgImgView.hidden = !self.tracking;
}

@end
