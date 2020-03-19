
//
//  FUPlaceholderTextView.m
//  FUStaLiteDemo
//
//  Created by LEE on 4/2/19.
//  Copyright © 2019 ly-Mac. All rights reserved.
//

#import "FUPlaceholderTextView.h"

@implementation FUPlaceholderTextView

- (void)setPlaceholder:(NSString *)placeholder{
	_placeholder = placeholder;
	[self setNeedsDisplay];
}
-(void)setPlaceholderColor:(UIColor *)placeholderColor{
	_placeholderColor = placeholderColor;
	[self setNeedsDisplay];
}
- (instancetype)initWithFrame:(CGRect)frame{
	if (self = [super initWithFrame:frame]) {
		[self setUPUI];
	}
	return self;
}
-(void)setUPUI{
	self.font = [UIFont systemFontOfSize:16];
	self.placeholder = @"在这里输入文字驱动形象";
	self.placeholderColor = [UIColor colorWithRed:137/255.0 green:143/255.0 blue:149/255.0 alpha:1.0];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:nil];
}
-(void)textDidChange:(NSNotification*)not{
	// 会重新调用drawRect:方法
	[self setNeedsDisplay];
}
-(void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	if (self.hasText){
		return;
	}
	CGFloat wRectW = 120;
	CGFloat wRectX = 15;
	CGFloat wRectY = 9;
	CGFloat wRectH = 30;
	CGRect wRect = CGRectMake(wRectX, wRectY, wRectW, wRectH);
	[_placeholder drawInRect:wRect withAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"PingFang-SC-Medium" size: 16],NSForegroundColorAttributeName: [UIColor colorWithRed:137/255.0 green:143/255.0 blue:149/255.0 alpha:1.0]}];
}
-(void)recover{
	self.text = nil;
	[self setNeedsDisplay];
}
-(void)layoutSubviews{
	[super layoutSubviews];
	[self setNeedsDisplay];
}
-(void)dealloc{
	[NSNotificationCenter.defaultCenter removeObserver:self];
}
@end
