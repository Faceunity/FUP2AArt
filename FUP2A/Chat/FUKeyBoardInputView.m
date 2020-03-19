//
//  FUKeyBoardInputView.m
//  FUStaLiteDemo
//
//  Created by LEE on 4/2/19.
//  Copyright © 2019 ly-Mac. All rights reserved.
//

#import "FUKeyBoardInputView.h"
@interface FUKeyBoardInputView()
@property(nonatomic,assign)FUInputType inputType;
@end

@implementation FUKeyBoardInputView

-(instancetype)initWithType:(FUInputType)type{
	self.inputType = type;
	if(self = [super init]){
		switch (type) {
			case Voice:
				break;
			case Text:
				[self setupTextUI];
				break;
			case Music:
				
				break;
				
			default:
				break;
		}
		
	}
	return self;
}

-(void)drawRect:(CGRect)rect{
	[super drawRect:rect];
}


- (void)didMoveToSuperview{
	[super didMoveToSuperview];
	if (self.inputType == Voice){
		
	}
}
-(void)setupTextUI{
	self.backgroundColor =  [UIColor whiteColor];
	self.frame = CGRectMake(0, 0, WIDTH, FUKeyBoardInputViewH);
	_keyBoardHieght = 0;
	_changeTime = 0.25;
	
	
	
	//左侧按钮
	_mBackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	CGFloat mBackBtnW = 26;
	CGFloat mBackBtnH = mBackBtnW;
	CGFloat mBackBtnY = (FUKeyBoardInputViewH - mBackBtnH) / 2.0;
	CGFloat mBackBtnX = 15;
	_mBackBtn.frame = CGRectMake(mBackBtnX, mBackBtnY, mBackBtnW, mBackBtnH);
	_mBackBtn.tag  = 14;
	[self addSubview:_mBackBtn];
	[_mBackBtn setBackgroundImage:[UIImage imageNamed:@"icon_back_keyboardInput"] forState:UIControlStateNormal];
	[_mBackBtn setBackgroundImage:[UIImage imageNamed:@"icon_back_keyboardInput"] forState:UIControlStateSelected];
	_mBackBtn.selected = NO;
	[_mBackBtn addTarget:self action:@selector(backBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	
	
	
	
	CGFloat mTextViewTrail = 15;   // 距离父视图尾部的距离
	CGFloat mTextViewX = CGRectGetMaxX(_mBackBtn.frame) + 10;
	CGFloat mTextViewW = WIDTH - mTextViewTrail - mTextViewX;
	CGFloat mTextViewH = 36;
	CGFloat mTextViewY = (FUKeyBoardInputViewH - mTextViewH) / 2.0;
	
	_mTextView = [[FUPlaceholderTextView alloc]initWithFrame:CGRectMake(mTextViewX, mTextViewY, mTextViewW, mTextViewH)];
	
	_mTextView.textContainerInset = UIEdgeInsetsMake(7.5, 5, 5, 5);
	_mTextView.delegate = self;
	_mTextView.backgroundColor = [UIColor whiteColor];
	_mTextView.returnKeyType = UIReturnKeySend;
	_mTextView.font = [UIFont systemFontOfSize:15];
	_mTextView.showsHorizontalScrollIndicator = NO;
	_mTextView.showsVerticalScrollIndicator = NO;
	_mTextView.enablesReturnKeyAutomatically = YES;
	_mTextView.userInteractionEnabled = YES;
	_mTextView.layer.cornerRadius = mTextViewH / 2.0;
	_mTextView.layer.borderColor = [UIColor colorWithRed:246/255.0 green:248/255.0 blue:250/255.0 alpha:1.0].CGColor;
	_mTextView.layer.borderWidth = 1;
	_mTextView.scrollEnabled = YES;//是否可以拖动
	_mTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	[self addSubview:_mTextView];
	
	//键盘显示 回收的监听
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillHideNotification object:nil];
}
-(void)backBtnPressed:(UIButton *)sender{
    [self endEditing:YES];
	self.exitFromKeyBoardInput();
	
}
// 隐藏键盘
/// return 隐藏之前键盘是否已弹起
-(BOOL)hideKeyboard{
	if (self.keyBoardStatus == FUChatKeyBoardStatusEdit) {
		self.transform = CGAffineTransformIdentity;
		self.keyBoardStatus = FUChatKeyBoardStatusDefault;
		[self endEditing:YES];
		return YES;
	}else{
		return NO;
	}
}
//键盘显示监听事件
- (void)keyboardWillChange:(NSNotification *)noti{
	CGFloat height = [[[noti userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
	NSLog(@"height---------%f",height);
	if(noti.name == UIKeyboardWillHideNotification){
		self.transform = CGAffineTransformIdentity;
		self.keyBoardStatus = FUChatKeyBoardStatusDefault;
	}else{
		CGFloat transformY = -height;
		if (appManager.isXFamily) {
			transformY += 34;
		}
		self.transform = CGAffineTransformMakeTranslation(0,transformY);
		
		self.keyBoardStatus = FUChatKeyBoardStatusEdit;
	}
	self.showOrHideBlock(self.keyBoardStatus == FUChatKeyBoardStatusEdit, CGRectGetMinY(self.frame));
	[self freshLayer];
}

-(void)sendText:(void (^)(NSString*))textBlock{
	self.textBlock = textBlock;
}



//拦截发送按钮
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
	if ([text isEqualToString:@"\n"]) {
		[self startSendMessage];
		return NO;
	}
	return YES;
}

//开始发送消息
-(void)startSendMessage{
	NSString *message = [_mTextView.attributedText string];
	NSString *newMessage = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if(message.length==0){
		
	}
	if (self.textBlock && newMessage.length > 0) {
		self.textBlock(newMessage);
		[self hideKeyboard];
	}
	[_mTextView recover];
	_textString = _mTextView.text;
	_mTextView.contentSize = CGSizeMake(_mTextView.contentSize.width, 30);
	[_mTextView setContentOffset:CGPointZero animated:YES];
	[_mTextView scrollRangeToVisible:_mTextView.selectedRange];
	
	//	_textH = FUVoiceTextHeight;
	//	[self setNewSizeWithBootm:_textH];
}


-(void)freshLayer{
	UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft cornerRadii:CGSizeMake(10,10)];
	//创建 layer
	CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
	
	maskLayer.frame = self.bounds;
	//赋值
	maskLayer.path = maskPath.CGPath;
	self.layer.mask = maskLayer;
}
//监听输入框的操作 输入框高度动态变化
- (void)textViewDidChange:(UITextView *)textView{}


@end
