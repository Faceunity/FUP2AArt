//
//  FUSwitch.m
//  FUP2A
//
//  Created by Chen on 2020/4/3.
//  Copyright © 2020 L. All rights reserved.
//

#import "FUSwitch.h"

#define DEFAULT_ON_COLOR UIColorFromRGB(0x1890FF)
#define DEFAULT_OFF_COLOR [UIColor colorWithHexColorString:@"000000" alpha:0.25]

@interface FUSwitch ()
@property (nonatomic, strong) UILabel *lblOn;
@property (nonatomic, strong) UILabel *lblOff;
@property (nonatomic, strong) UIView *tumbView;
@property (nonatomic, strong) UIView *bgView;

@end

@implementation FUSwitch

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self addSubview:self.bgView];
    [self addSubview:self.tumbView];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchView)]];
    self.onColor = DEFAULT_ON_COLOR;
    self.offColor = DEFAULT_OFF_COLOR;
}

- (void)setOn:(BOOL)on
{
    _on = on;
    self.tumbView.frame = CGRectMake(self.on?self.frame.size.width - self.tumbView.frame.size.width - 2:2, 2, self.frame.size.height-4, self.frame.size.height-4);
    
    self.lblOn.hidden = !self.on;
    self.lblOff.hidden = self.on;
    [self resetBackGroundColor];
}

- (void)touchView
{
    [UIView animateWithDuration:0.2f animations:^{
       self.on = !self.on;
    } completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(switchView:isOn:)])
        {
            [self.delegate switchView:self isOn:self.on];
        }
    }];
}

- (void)resetBackGroundColor
{
    self.bgView.backgroundColor = self.on?self.onColor:self.offColor;
}

- (void)setOnColor:(UIColor *)onColor
{
    _onColor = onColor;
    [self resetBackGroundColor];
}

- (void)setOffColor:(UIColor *)offColor
{
    _offColor = offColor;
    [self resetBackGroundColor];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.bgView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.bgView.layer.cornerRadius = frame.size.height/2;
    
    self.tumbView.frame = CGRectMake(2, 2, frame.size.height-4, frame.size.height-4);
    self.tumbView.layer.cornerRadius = frame.size.height/2 - 2;
}

- (void)setOnTitle:(NSString *)onTitle
{
    [self addSubview:self.lblOn];
    self.lblOn.frame = CGRectMake(0, 0, self.frame.size.height, self.frame.size.height);
    self.lblOn.text = onTitle;
}

- (void)setOffTitle:(NSString *)offTitle
{
    [self addSubview:self.lblOff];
    self.lblOff.frame = CGRectMake(self.frame.size.width - self.frame.size.height, 0, self.frame.size.height, self.frame.size.height);
    self.lblOff.text = offTitle;
}

- (UIView *)bgView
{
    if (!_bgView)
    {
        _bgView = ({
            UIView *view = UIView.new;
            view.backgroundColor = [UIColor colorWithRed:24.0/255.0 green:144.0/255.0 blue:1 alpha:1];
            
            view;
        });
    }
    return _bgView;
}

- (UIView *)tumbView
{
    if (!_tumbView)
    {
        _tumbView = ({
            UIView *view = UIView.new;
            view.backgroundColor = [UIColor whiteColor];
            
            view;
        });
    }
    return _tumbView;
}


- (UILabel *)lblOn
{
    if (!_lblOn)
    {
        _lblOn = ({
            UILabel *object = UILabel.new;
            object.textAlignment = NSTextAlignmentCenter;
            object.font = [UIFont systemFontOfSize:9];
            object.textColor = [UIColor whiteColor];
            
            object;
        });
    }
    
    return _lblOn;
}

- (UILabel *)lblOff
{
    if (!_lblOff)
    {
        _lblOff = ({
            UILabel *object = UILabel.new;
            object.textAlignment = NSTextAlignmentCenter;
            object.font = [UIFont systemFontOfSize:9];
            object.textColor = [UIColor whiteColor];
            
            object;
        });
    }
    
    return _lblOff;
}

@end
