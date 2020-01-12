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
	//self.transform =  CGAffineTransformMakeScale(1, 2);
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [self setValue:self.value animated:YES];
}

// 后设置 value
- (void)setValue:(float)value animated:(BOOL)animated   {
    [super setValue:value animated:animated];
	
	
    tipLabel.text = [NSString stringWithFormat:@"%d",(int)(value * 100)];
    CGFloat tipX = value * (self.frame.size.width - 20) - tipLabel.frame.size.width * 0.5 + 10;
    CGRect tipFrame = tipLabel.frame;
    tipFrame.origin.x = tipX;
    bgImgView.frame = tipFrame;
    tipLabel.frame = tipFrame;

    tipLabel.hidden = !self.isTracking ;
    bgImgView.hidden = !self.isTracking ;
}

@end
