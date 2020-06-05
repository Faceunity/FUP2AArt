//
//  FUFigureView.m
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureView.h"
#import "FUFigureDecorationCollection.h"
#import "FUFigureColorCollection.h"
#import "FUFigureHorizCollection.h"
#import "FUFigureSlider.h"
#import "FUAvatarEditManager.h"
#import "FUGradientSlider.h"

typedef NS_ENUM(NSInteger, FUFigureViewMiddleViewState){
    FUFigureViewMiddleViewState_Show           = 0,
    FUFigureViewMiddleViewState_Hide,
    FUFigureViewMiddleViewState_ShowColorSlider,
    FUFigureViewMiddleViewState_ShowOnlyColorCollection,
    FUFigureViewMiddleViewState_ShowColorCollectionWithSwitch,
	FUFigureViewMiddleViewState_ShowColorCollectionWithMakeup,
};

typedef NS_ENUM(NSInteger, FUDecorationViewState){
    FUDecorationViewState_Show           = 0,
    FUDecorationViewState_Hide,
    FUDecorationViewState_ShowCommon,  // 普通模式
    FUDecorationViewState_ShowMakeup,  // 美妆
};
@interface FUFigureView ()
<
UIGestureRecognizerDelegate,
FUFigureTopCollectionDelegate,
FUGradientSliderDelegate,
FUFigureHorizCollectionDelegate
>
{
	CGFloat preScale; // 捏合比例
}
// 当前选择的编辑按钮，捏脸，美妆，服饰
@property (strong, nonatomic)  UIButton *selectedEditButton;

@property (weak, nonatomic) IBOutlet FUFigureTopCollection *topCollection;
#define FUTopCollectionHeight 50
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topCollectionHeight;
@property (weak, nonatomic) IBOutlet UIView *decorationView;

@property (weak, nonatomic) IBOutlet FUFigureDecorationCollection *decorationCollection;
#define FUDecorationViewHeight 249
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *decorationViewHeight;

@property (weak, nonatomic) IBOutlet UIView *colorCollectionSuperView;
@property (weak, nonatomic) IBOutlet FUFigureColorCollection *decorationColorCollection;
#define FUDecorationColorCollectionLeading_OrignalConst 0
#define FUDecorationColorCollectionLeading_AheadConst -10
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *decorationColorCollectionLeading;

// glass 的 colorSwitch
@property (weak, nonatomic) IBOutlet UIView *switchSuperView;
@property (weak, nonatomic) IBOutlet UIButton *switchGlassesFrameButton;
@property (weak, nonatomic) IBOutlet UIButton *switchGlassesButton;
// 用于显示美妆标签名称
@property (weak, nonatomic) IBOutlet UILabel *makeupLabel;
@property (weak, nonatomic) IBOutlet UIView *makeupLabelSuperView;
#define FUSwitchSuperViewWidth 110
#define FUMakeupLabelSuperViewWidth 70
// colorCollectionSuperView 左侧的空间
@property (weak, nonatomic) IBOutlet UIView *colorLeftSubView;


@property (weak, nonatomic) IBOutlet UIView *colorSliderSuperView;
@property (weak, nonatomic) IBOutlet FUGradientSlider *colorSlider;
// 存放颜色相关控件
@property (weak, nonatomic) IBOutlet UIView *middleView;
#define FUMiddleViewHeight 50
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *middleViewHeight;



@property (weak, nonatomic) IBOutlet UIView *doAndUndoView;

@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@property (weak, nonatomic) IBOutlet UIButton *redoBtn;

@property (weak, nonatomic) IBOutlet UIView *testView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorLeftSubViewWidth;
//镜框镜片切换视图宽度，默认宽度110
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchLeading;
@property (weak, nonatomic) IBOutlet UIView *SwitchView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomXHeightConstraint;
@end

@implementation FUFigureView

- (void)awakeFromNib {
	[super awakeFromNib];
  
    [self addGesture];
    [self addNotification];
//    [self loadSubViewData];
    
}


/// 添加手势
- (void)addGesture
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self addGestureRecognizer:tapGesture];
    tapGesture.delegate = self ;
}

/// 添加通知监听
- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditManagerStackNotEmptyNotMethod) name:FUAvatarEditManagerStackNotEmptyNot object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];
}


-(void)FUAvatarEditManagerStackNotEmptyNotMethod
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (![FUAvatarEditManager sharedInstance].undoStack.isEmpty)
        {
			self.undoBtn.enabled = YES;
		}
		if (![FUAvatarEditManager sharedInstance].redoStack.isEmpty)
        {
			self.redoBtn.enabled = YES;
		}
		self.resetBtn.enabled = YES;
	});
}

- (void)setupFigureView
{

//    //撤销重做视图
    self.doAndUndoView.layer.shadowColor = [UIColor colorWithRed:35/255.0 green:53/255.0 blue:95/255.0 alpha:0.15].CGColor; //[UIColor redColor].CGColor;
    //[UIColor colorWithRed:35/255.0 green:53/255.0 blue:95/255.0 alpha:0.15].CGColor;
    self.doAndUndoView.layer.shadowOffset = CGSizeMake(0,1);
    self.doAndUndoView.layer.shadowOpacity = 1;
    self.doAndUndoView.layer.shadowRadius = 6;
    
    self.decorationCollection.mDelegate = self;
    [self.decorationCollection scrollCurrentToCenterWithAnimation:NO];
    
    
    if (appManager.isXFamily) {
        self.bottomXHeightConstraint.constant = 34;
    }
    else
    {
        self.bottomXHeightConstraint.constant = 0;
    }

    //添加类别栏的代理监听
    self.topCollection.mDelegate = self;
    self.colorSlider.delegate = self;
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    self.colorSlider.value = avatar.skinColorProgress;
    // 将 捏脸 的 选项 初始化 为 头发 子项
    [[FUManager shareInstance]setSubTypeSelectedIndex:0 withEditType:FUEditTypeFace];
    // 点击默认的 “捏脸”  按钮
    UIButton * faceupButton = [self viewWithTag:300];
    [self editTypeClick:faceupButton];
}
/// 取消选择美妆类型
/// @param model
- (void)cancelSelectedItem
{
	[self freshMiddleView:FUFigureViewMiddleViewState_Hide];
}
- (void)didSelectedItem:(FUItemModel*)model
{
	if ([FUManager shareInstance].selectedEditType == FUEditTypeMakeup)
	{
		[self topCollectionDidSelectedMakeupModel:model];
	}else{
		[self topCollectionDidSelectedIndex:[[FUManager shareInstance]getSubTypeSelectedIndex] show:YES changeAnimation:NO];
	}
}


-(void)freshMiddleView:(FUFigureViewMiddleViewState)state{
	switch (state) {
		case FUFigureViewMiddleViewState_Show:
			self.middleViewHeight.constant = FUMiddleViewHeight;
			break;
		case FUFigureViewMiddleViewState_Hide:
			self.middleViewHeight.constant = 0;
			self.colorSliderSuperView.hidden = YES;
			self.colorCollectionSuperView.hidden = YES;
			self.colorLeftSubView.hidden = YES;
			break;
		case FUFigureViewMiddleViewState_ShowColorSlider:
			self.middleViewHeight.constant = FUMiddleViewHeight;
			self.colorSliderSuperView.hidden = NO;
			self.colorCollectionSuperView.hidden = YES;
			self.colorLeftSubView.hidden = YES;
			break;
		case FUFigureViewMiddleViewState_ShowOnlyColorCollection:
			self.middleView.hidden = NO;
			self.middleViewHeight.constant = FUMiddleViewHeight;
			self.colorSliderSuperView.hidden = YES;
			self.colorCollectionSuperView.hidden = NO;
			self.colorLeftSubViewWidth.constant = 0;
			self.colorLeftSubView.hidden = YES;
			self.decorationColorCollectionLeading.constant = FUDecorationColorCollectionLeading_AheadConst;
			break;
		case FUFigureViewMiddleViewState_ShowColorCollectionWithSwitch:
			self.middleView.hidden = NO;
			self.middleViewHeight.constant = FUMiddleViewHeight;
			self.colorSliderSuperView.hidden = YES;
			self.colorCollectionSuperView.hidden = NO;
			self.colorLeftSubViewWidth.constant = FUSwitchSuperViewWidth;
			self.colorLeftSubView.hidden = NO;
			self.switchSuperView.hidden = NO;
			self.makeupLabelSuperView.hidden = YES;
			self.decorationColorCollectionLeading.constant = FUDecorationColorCollectionLeading_OrignalConst;
			break;
			
		case FUFigureViewMiddleViewState_ShowColorCollectionWithMakeup:
			self.middleView.hidden = NO;
			self.middleViewHeight.constant = FUMiddleViewHeight;
			self.colorSliderSuperView.hidden = YES;
			self.colorCollectionSuperView.hidden = NO;
			self.colorLeftSubViewWidth.constant = FUMakeupLabelSuperViewWidth;
			self.colorLeftSubView.hidden = NO;
			self.switchSuperView.hidden = YES;
			self.makeupLabelSuperView.hidden = NO;
			self.decorationColorCollectionLeading.constant = FUDecorationColorCollectionLeading_AheadConst;
			break;
			
			
		default:
			break;
	}
}

-(void)freshDecorationView:(FUDecorationViewState)state{
	switch (state) {
		case FUDecorationViewState_Show:
			self.decorationViewHeight.constant = FUDecorationViewHeight;
			self.decorationView.hidden = NO;
			break;
		case FUDecorationViewState_Hide:
			self.decorationViewHeight.constant = 0;
			self.decorationView.hidden = YES;
			break;
		case FUDecorationViewState_ShowCommon:  // 美妆
			self.decorationViewHeight.constant = FUDecorationViewHeight;
			self.decorationView.hidden = NO;
			self.topCollectionHeight.constant = FUTopCollectionHeight;
			self.middleView.hidden = NO;
			break;
		case FUDecorationViewState_ShowMakeup:  // 美妆
			self.decorationViewHeight.constant = FUDecorationViewHeight;
			self.decorationView.hidden = NO;
			self.topCollectionHeight.constant = 0;
			self.middleView.hidden = YES;
			break;
		default:
			break;
	}
}
/// 选择美妆类型
/// @param model 美妆model
-(void)topCollectionDidSelectedMakeupModel:(FUMakeupItemModel*)model{
	NSString * subType = model.type;
	if (model.bundle.length == 0) {  // 如果是 第 0个 makeup model
		[self freshMiddleView:FUFigureViewMiddleViewState_Hide];
	}else{
		if ([subType isEqualToString:TAG_FU_ITEM_EYESHADOW])
		{
			if([[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_EYESHADOW] integerValue] > 0)
				[self freshMiddleView:FUFigureViewMiddleViewState_ShowColorCollectionWithMakeup];
				
			self.decorationColorCollection.currentType = FUFigureColorTypeEyeshadowColor;
		}
		else if ([subType isEqualToString:TAG_FU_ITEM_PUPIL])
		{
			[self freshMiddleView:FUFigureViewMiddleViewState_Hide];
		}
		else if ([subType isEqualToString:TAG_FU_ITEM_EYEBROW])
		{
			if([[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_EYEBROW] integerValue] > 0)
				[self freshMiddleView:FUFigureViewMiddleViewState_ShowColorCollectionWithMakeup];
			self.decorationColorCollection.currentType = FUFigureColorTypeEyebrowColor;
		}
		else if ([subType isEqualToString:TAG_FU_ITEM_EYELINER])
		{
			[self freshMiddleView:FUFigureViewMiddleViewState_Hide];
		}
		else if ([subType isEqualToString:TAG_FU_ITEM_EYELASH])
		{
			if([[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_EYELASH] integerValue] > 0)
				[self freshMiddleView:FUFigureViewMiddleViewState_ShowColorCollectionWithMakeup];
			self.decorationColorCollection.currentType = FUFigureColorTypeEyelashColor;
		}
		else if ([subType isEqualToString:TAG_FU_ITEM_FACEMAKEUP])
		{
			[self freshMiddleView:FUFigureViewMiddleViewState_Hide];
		}
		else if ([subType isEqualToString:TAG_FU_ITEM_LIPGLOSS])
		{
			if([[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_LIPGLOSS] integerValue] > 0)
				[self freshMiddleView:FUFigureViewMiddleViewState_ShowColorCollectionWithMakeup];
			self.decorationColorCollection.currentType = FUFigureColorTypeLipsColor;
			
		}
	}
	self.makeupLabel.text = model.title;
	[self.decorationCollection reloadData];
}
//
//#pragma mark -- FUFigureTopCollectionDelegate
- (void)topCollectionDidSelectedIndex:(NSInteger)index show:(BOOL)show changeAnimation:(BOOL)changeAnimation
{
	
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	NSString *subType = [[FUManager shareInstance] getSubTypeKeyWithIndex:index];
	if (!show)
	{
		
		[avatar resetScaleToSmallBody_UseCam];
		return;
	}
	
	[self freshMiddleView:FUFigureViewMiddleViewState_Hide];
	NSInteger currentTypeSelectedIndex = [[FUManager shareInstance].selectedItemIndexDict[subType] integerValue];
	if ([subType isEqualToString:TAG_FU_ITEM_HAIR])
	{
		if( currentTypeSelectedIndex> 0)
			[self freshMiddleView:FUFigureViewMiddleViewState_ShowOnlyColorCollection];
		self.decorationColorCollection.currentType = FUFigureColorTypeHairColor;
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_FACE])
	{
		[self freshMiddleView:FUFigureViewMiddleViewState_ShowColorSlider];
		self.decorationColorCollection.currentType = FUFigureColorTypeSkinColor;
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_EYE])
	{
		[self freshMiddleView:FUFigureViewMiddleViewState_ShowOnlyColorCollection];
		self.decorationColorCollection.currentType = FUFigureColorTypeirisColor;
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_MOUTH])
	{
		
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_NOSE])
	{
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_CLOTH])
	{
	    if(changeAnimation)
		[avatar loadChangeItemAnimation];
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_SHOES])
	{
	     if(changeAnimation)
		[avatar loadChangeItemAnimation];
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_UPPER])
	{
	     if(changeAnimation)
		[avatar loadChangeItemAnimation];
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_LOWER])
	{
	     if(changeAnimation)
		[avatar loadChangeItemAnimation];
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_BEARD])
	{
		
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_GLASSES])
	{
		if(currentTypeSelectedIndex > 0)
			[self freshMiddleView:FUFigureViewMiddleViewState_ShowColorCollectionWithSwitch];
		self.decorationColorCollection.currentType = [FUManager shareInstance].isGlassesColor?FUFigureColorTypeGlassesColor:FUFigureColorTypeGlassesFrameColor;
		 if(changeAnimation)
		[avatar loadIdleModePose];
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_DECORATION_SHOU])
	{
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_DECORATION_JIAO])
	{
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_DECORATION_XIANGLIAN])
	{
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_DECORATION_ERHUAN])
	{
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_DECORATION_TOUSHI])
	{
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_DECORATIONS])
	{
		 if(changeAnimation)
		 [avatar loadChangeItemAnimation];
	}
	else if ([subType isEqualToString:TAG_FU_ITEM_HAIRHAT])
	{
	     if(changeAnimation)
		[avatar loadIdleModePose];
	}
	[self.decorationCollection reloadData];
	// 多选状态，不允许滑动
	if (![subType isEqualToString:FUDecorationsString]) {
		if (currentTypeSelectedIndex>=0)
			[self.decorationCollection scrollCurrentToCenterWithAnimation:NO];
	}
}

- (void)updateSliderWithValue:(double)value
{
    self.colorSlider.value = value;
}

- (IBAction)valueChanged:(FUGradientSlider *)sender
{
    [[FUManager shareInstance]configSkinColorWithProgress:sender.value isPush:NO];
}

- (void)gradientSliderValueChangeFinished:(float)value
{
    [[FUManager shareInstance]configSkinColorWithProgress:value isPush:YES];
    [FUManager shareInstance].currentAvatars.firstObject.skinColorProgress = value;
}
- (IBAction)reset:(UIButton *)sender {
	self.resetBtn.enabled = NO;
	self.undoBtn.enabled = NO;
	self.redoBtn.enabled = NO;
	if ([self.delegate respondsToSelector:@selector(undo:)]) {
		[self.delegate reset:sender];
	}
	[self reloadTopCollection:NO];
}
- (IBAction)undo:(UIButton *)sender {
	if ([self.delegate respondsToSelector:@selector(undo:)]) {
		[self.delegate undo:sender];
		[self reloadTopCollection:NO];
	}
}
- (IBAction)redo:(UIButton *)sender {
	if ([self.delegate respondsToSelector:@selector(redo:)]) {
		[self.delegate redo:sender];
		[self reloadTopCollection:NO];
	}
}

#pragma mark --- UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

	for (UIView *view in self.subviews)
    {
		if ([touch.view isDescendantOfView:view] && touch.view != self.decorationView)
        {
			return NO ;
		}
	}
	return YES ;
}
#pragma mark ------ Events ------

- (IBAction)editTypeClick:(UIButton *)sender {
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	switch (sender.tag) {
		case 300:  // 捏脸
		{
	    	[FUManager shareInstance].selectedEditType = FUEditTypeFace;
			[avatar loadIdleModePose];
			[self freshDecorationView:FUDecorationViewState_ShowCommon];
		}
			break;
		case 301:  // 美妆
		{
		    [FUManager shareInstance].selectedEditType = FUEditTypeMakeup;
			[avatar loadIdleModePose];
			[self freshDecorationView:FUDecorationViewState_ShowMakeup];
		}
			break;
		case 302:  // 服饰
		{
		    [FUManager shareInstance].selectedEditType = FUEditTypeDress;
			[avatar loadChangeItemAnimation];
			[self freshDecorationView:FUDecorationViewState_ShowCommon];
		}
			break;
			
			
		default:
			break;
	}
	
	[self reloadTopCollection];
	[self reloadCam];
	self.selectedEditButton.selected = NO;
	sender.selected = YES;
	self.selectedEditButton = sender;
	// 在设置 NSLayoutConstraint 后，需要重新绘制子view，否则会显示不全
	[self layoutSubviews];
}
- (void)tapClick:(UITapGestureRecognizer *)tap
{
	
	if (self.decorationView.isHidden) {
		[self freshDecorationView:FUDecorationViewState_Show];
		[self reloadTopCollection];
		[self reloadCam];
		[self layoutSubviews];
	}else{
		[self freshDecorationView:FUDecorationViewState_Hide];
		[UIView animateWithDuration:2 animations:^{
			FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
			[avatar resetScaleToSmallBody_UseCam];
		}];
	}

	
}



- (void)reloadTopCollection
{
	  [self reloadTopCollection:YES];
}


- (void)reloadTopCollection:(BOOL)changeAnimation
{
	
	[self.topCollection reloadData];
	if ([FUManager shareInstance].selectedEditType == FUEditTypeMakeup)
	{
		[self topCollectionDidSelectedMakeupModel:[[FUManager shareInstance]getMakeupCurrentSelectedModel]];
	}else{
		[self topCollectionDidSelectedIndex:[[FUManager shareInstance]getSubTypeSelectedIndex] show:YES changeAnimation:changeAnimation];
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{  // 异步处理，解决 self.topCollection  不能显示所有项目的bug
	[self.topCollection scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[[FUManager shareInstance]getSubTypeSelectedIndex] inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
	});
}


- (void)reloadCam
{
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	if ([FUManager shareInstance].selectedEditType == FUEditTypeFace||[FUManager shareInstance].selectedEditType == FUEditTypeMakeup)
	{
		[avatar resetScaleToBody_UseCam];
	}
	else if ([FUManager shareInstance].selectedEditType == FUEditTypeDress)
	{
		NSString *subType = [[FUManager shareInstance]getSubTypeKeyWithIndex:[[FUManager shareInstance]getSubTypeSelectedIndex]];
		if ([subType isEqualToString:TAG_FU_ITEM_HAIRHAT]||[subType isEqualToString:TAG_FU_ITEM_GLASSES])
		{
			if(!self.decorationView.hidden)  // 隐藏模式时，进行撤销、回退 不进行 重置 相机的 操作
				[avatar resetScaleToBody_UseCam];
		}
		else
		{
			if(!self.decorationView.hidden)  // 隐藏模式时，进行撤销、回退 不进行 重置 相机的 操作
				[avatar resetScaleChange_UseCam];
			
		}
	}
}


- (IBAction)clickGlassesButton:(id)sender
{
    self.switchGlassesButton.selected = YES;
    self.switchGlassesFrameButton.selected = NO;
    self.decorationColorCollection.currentType = FUFigureColorTypeGlassesColor;
    [FUManager shareInstance].isGlassesColor = YES;
    [self.decorationColorCollection reloadData];
    
    [UIView animateWithDuration:0.4 animations:^{
        [self.SwitchView.superview removeConstraint:self.switchLeading];
        self.switchLeading = [NSLayoutConstraint constraintWithItem:self.SwitchView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.SwitchView.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
        [self.SwitchView.superview addConstraint:self.switchLeading];
        [self.SwitchView.superview layoutIfNeeded];
    }];
}

- (IBAction)clickGlassesFrameButton:(id)sender
{
    self.switchGlassesFrameButton.selected = YES;
    self.switchGlassesButton.selected = NO;
    self.decorationColorCollection.currentType = FUFigureColorTypeGlassesFrameColor;
    [self.decorationColorCollection reloadData];
    [FUManager shareInstance].isGlassesColor = NO;
    [UIView animateWithDuration:0.4 animations:^{
        [self.SwitchView.superview removeConstraint:self.switchLeading];
        self.switchLeading = [NSLayoutConstraint constraintWithItem:self.SwitchView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.SwitchView.superview attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
        
        [self.SwitchView.superview addConstraint:self.switchLeading];
        [self.SwitchView.superview layoutIfNeeded];
    }];
    
}
-(void)dealloc{
   NSLog(@"FUFigureView----销毁了");
}
@end
