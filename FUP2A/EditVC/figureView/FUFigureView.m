//
//  FUFigureView.m
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureView.h"
#import "FUFigureBottomCollection.h"
#import "FUFigureDecorationCollection.h"
#import "FUFigureColorCollection.h"
#import "FUFigureHorizCollection.h"
#import "FUFigureSlider.h"
#import "FUAvatarEditManager.h"
#import "FUGradientSlider.h"


@interface FUFigureView ()
<
UIGestureRecognizerDelegate,
FUFigureBottomCollectionDelegate,
FUGradientSliderDelegate,
FUFigureHorizCollectionDelegate
>
{
	CGFloat preScale; // 捏合比例
}
@property (weak, nonatomic) IBOutlet UIButton *faceButton;
@property (weak, nonatomic) IBOutlet UIButton *makeupButton;
@property (weak, nonatomic) IBOutlet UIButton *clothButton;
@property (weak, nonatomic) IBOutlet UIButton *backgroundButton;
@property (weak, nonatomic) IBOutlet UIView *typeView;

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet FUFigureBottomCollection *bottomCollection;

@property (weak, nonatomic) IBOutlet UIView *decorationView;
@property (weak, nonatomic) IBOutlet FUFigureDecorationCollection *decorationCollection;

@property (weak, nonatomic) IBOutlet UIView *colorSuperView;
@property (weak, nonatomic) IBOutlet FUFigureColorCollection *decorationColorCollection;

@property (weak, nonatomic) IBOutlet UIView *switchSuperView;
@property (weak, nonatomic) IBOutlet UIButton *switchGlassesFrameButton;
@property (weak, nonatomic) IBOutlet UIButton *switchGlassesButton;

@property (weak, nonatomic) IBOutlet UIView *colorSliderSuperView;
@property (weak, nonatomic) IBOutlet FUGradientSlider *colorSlider;

@property (weak, nonatomic) IBOutlet UIView *doAndUndoView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *doAndUndoViewBottomConstriants;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPlaceholderBottom; // 底部collection控件，距离底部的距离，默认是 -34
@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@property (weak, nonatomic) IBOutlet UIButton *redoBtn;

@property (nonatomic,assign)FUAvatarEditedDoModelType type;
@property (weak, nonatomic) IBOutlet UIView *testView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *decCollectionHeight; //道具视图高度，默认高度180
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorSuperViewHeight; //道具颜色视图高度，默认高度50
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *decColorSliderHeight; //道具颜色滑条视图高度，默认高度50
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typeViewHeight; //编辑类型切换视图高度，默认高度40
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchSuperViewWidth;
//镜框镜片切换视图宽度，默认宽度110
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchLeading;
@property (weak, nonatomic) IBOutlet UIView *SwitchView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomXHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomCollectionWidth;
@end

@implementation FUFigureView

- (void)awakeFromNib {
	[super awakeFromNib];
    [FUManager shareInstance].isHiddenDecView = NO;
    [self addGesture];
    [self addNotification];
//    [self loadSubViewData];
    
    [self hiddenDecView];
    [self hiddenTypeView:NO];
    [self hiddenDecorationCollection:NO];
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

- (void)hiddenDecView
{
    [self hiddenTypeView:YES];
    [self hiddenColorSlierView:YES];
    [self hiddenDecorationCollection:YES];
    [self hiddenColorSuperView:YES];
    [self hiddenSwitchView:YES];
}

- (void)hiddenTypeView:(BOOL)hidden
{
    self.typeViewHeight.constant = hidden?0:40;
    self.typeView.hidden = hidden;
}

- (void)hiddenColorSlierView:(BOOL)hidden
{
    self.decColorSliderHeight.constant = hidden?0:50;
    self.colorSliderSuperView.hidden = hidden;
}

- (void)hiddenSwitchView:(BOOL)hidden
{
    self.switchSuperViewWidth.constant = hidden?0:110;
    self.switchSuperView.hidden = hidden;
}

- (void)hiddenColorSuperView:(BOOL)hidden
{
    self.colorSuperViewHeight.constant = hidden?0:50;
    self.colorSuperView.hidden = hidden;
    [self.colorSuperView setNeedsLayout];
    [self.colorSuperView layoutIfNeeded];
    self.decorationColorCollection.hidden = hidden;
}

- (void)hiddenDecorationCollection:(BOOL)hidden
{
    self.decCollectionHeight.constant = hidden?0:180;
    self.decorationCollection.hidden = hidden;
    [self.decorationCollection layoutIfNeeded];
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
	});
}

- (void)setupFigureView
{
    self.faceButton.selected = YES;
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
    self.bottomCollection.mDelegate = self;
    [self bottomCollectionDidSelectedIndex:0 show:YES animation:NO];
   //颜色栏设置默认属性
    self.decorationColorCollection.currentType = FUFigureColorTypeHairColor;
    self.decorationColorCollection.hidden = [[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_HAIR] integerValue] == 0 ;

    
    self.colorSlider.delegate = self;
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    self.colorSlider.value = avatar.skinColorProgress;
}

- (void)didSelectedItem
{
    [self bottomCollectionDidSelectedIndex:[[FUManager shareInstance]getSubTypeSelectedIndex] show:YES animation:NO];
}

//
//#pragma mark -- FUFigureBottomCollectionDelegate
-(void)bottomCollectionDidSelectedIndex:(NSInteger)index show:(BOOL)show animation:(BOOL)animation
{
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    
    NSString *subType = [[FUManager shareInstance] getSubTypeKeyWithIndex:index];
    if (!show)
    {
        [self hiddenDecView];
        [avatar resetScaleToSmallBody_UseCam];
        return;
    }
    
    [self hiddenSwitchView:YES];
    [self hiddenTypeView:NO];
    [self hiddenDecorationCollection:NO];
    [self hiddenColorSlierView:YES];
    [self hiddenColorSuperView:YES];
    
    
    if ([subType isEqualToString:TAG_FU_ITEM_HAIR])
    {
        [self hiddenColorSuperView:[[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_HAIR] integerValue] == 0];
        self.decorationColorCollection.currentType = FUFigureColorTypeHairColor;
        
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_FACE])
    {
        [self hiddenColorSlierView:NO];
        self.decorationColorCollection.currentType = FUFigureColorTypeSkinColor;
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_EYE])
    {
        [self hiddenColorSuperView:NO];
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
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_SHOES])
    {
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_UPPER])
    {
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_LOWER])
    {
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_EYESHADOW])
    {
        [self hiddenColorSuperView:[[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_EYESHADOW] integerValue] == 0];
        self.decorationColorCollection.currentType = FUFigureColorTypeEyeshadowColor;
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_PUPIL])
    {
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_EYEBROW])
    {
        [self hiddenColorSuperView:[[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_EYEBROW] integerValue] == 0];
        self.decorationColorCollection.currentType = FUFigureColorTypeEyebrowColor;
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_EYELINER])
    {
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_EYELASH])
    {
        [self hiddenColorSuperView:[[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_EYELASH] integerValue] == 0];
        self.decorationColorCollection.currentType = FUFigureColorTypeEyelashColor;
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_FACEMAKEUP])
    {
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_LIPGLOSS])
    {
        [self hiddenColorSuperView:[[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_LIPGLOSS] integerValue] == 0];
        self.decorationColorCollection.currentType = FUFigureColorTypeLipsColor;

    }
    else if ([subType isEqualToString:TAG_FU_ITEM_BEARD])
    {
        
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_GLASSES])
    {
        [self hiddenSwitchView:NO];
        [self hiddenColorSuperView:[[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_GLASSES] integerValue] == 0];
        self.decorationColorCollection.currentType = [FUManager shareInstance].isGlassesColor?FUFigureColorTypeGlassesColor:FUFigureColorTypeGlassesFrameColor;
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_DECORATION])
    {
    }
    else if ([subType isEqualToString:TAG_FU_ITEM_HAIRHAT])
    {
        
    }
    
    
    [self.decorationCollection reloadData];
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

- (IBAction)undo:(UIButton *)sender {
	if ([self.delegate respondsToSelector:@selector(undo:)]) {
		[self.delegate undo:sender];
	}
}
- (IBAction)redo:(UIButton *)sender {
	if ([self.delegate respondsToSelector:@selector(redo:)]) {
		[self.delegate redo:sender];
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
- (void)tapClick:(UITapGestureRecognizer *)tap
{
    [FUManager shareInstance].isHiddenDecView = YES;
    [UIView animateWithDuration:2 animations:^{
        [self hiddenDecView];
        FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
        [avatar resetScaleToSmallBody_UseCam];
    }];
    
    [self.bottomCollection reloadData];
}

- (void)setButtonStateWithSender:(id)sender
{
    self.faceButton.selected = self.faceButton == sender?YES:NO;
    self.makeupButton.selected = self.makeupButton == sender?YES:NO;
    self.clothButton.selected = self.clothButton == sender?YES:NO;
    self.backgroundButton.selected = self.backgroundButton == sender?YES:NO;
}

- (IBAction)clickFaceButton:(id)sender
{
    self.bottomCollectionWidth.constant = [UIScreen mainScreen].bounds.size.width;
    [self.bottomView layoutIfNeeded];
    [FUManager shareInstance].selectedEditType = @"face";
    [self setButtonStateWithSender:sender];
    [self reloadBottomCollection];
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    [avatar loadIdleModePose];
}

- (IBAction)clickMakeupButton:(id)sender
{
    self.bottomCollectionWidth.constant = [UIScreen mainScreen].bounds.size.width;
    [self.bottomView layoutIfNeeded];
    [FUManager shareInstance].selectedEditType = @"makeup";
    [self setButtonStateWithSender:sender];
    [self reloadBottomCollection];
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    [avatar loadIdleModePose];
}

- (IBAction)clickClothButton:(id)sender
{
    self.bottomCollectionWidth.constant = [UIScreen mainScreen].bounds.size.width;
    [self.bottomView layoutIfNeeded];
    [FUManager shareInstance].selectedEditType = @"dress";
    [self setButtonStateWithSender:sender];
    [self reloadBottomCollection];
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    [avatar loadChangeItemAnimation];
}


- (IBAction)clickBackgroundButton:(id)sender
{
    self.bottomCollectionWidth.constant = 48+8+8;
    [self.bottomView layoutIfNeeded];
    [FUManager shareInstance].selectedEditType = @"background";
    [self setButtonStateWithSender:sender];
    [self reloadBottomCollection];
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    [avatar loadChangeItemAnimation];
}

- (void)reloadBottomCollection
{
    [self reloadCam];
    [self.bottomCollection reloadData];
    [self bottomCollectionDidSelectedIndex:[[FUManager shareInstance]getSubTypeSelectedIndex] show:YES animation:NO];
    [self.bottomCollection scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[[FUManager shareInstance]getSubTypeSelectedIndex] inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)reloadCam
{
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    if ([[FUManager shareInstance].selectedEditType isEqualToString:@"face"]||[[FUManager shareInstance].selectedEditType isEqualToString:@"makeup"])
    {
        [avatar resetScaleToBody_UseCam];
    }
    else if ([[FUManager shareInstance].selectedEditType isEqualToString:@"dress"]||[[FUManager shareInstance].selectedEditType isEqualToString:@"background"])
    {
        NSString *subType = [[FUManager shareInstance]getSubTypeKeyWithIndex:[[FUManager shareInstance]getSubTypeSelectedIndex]];
        if ([subType isEqualToString:TAG_FU_ITEM_HAIRHAT]||[subType isEqualToString:TAG_FU_ITEM_GLASSES])
        {
            [avatar resetScaleToBody_UseCam];
        }
        else
        {
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
@end
