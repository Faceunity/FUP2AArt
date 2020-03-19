//
//  FUFigureView.m
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureView.h"
#import "FUP2AColor.h"
#import "FUFigureBottomCollection.h"
#import "FUFigureDecorationCollection.h"
#import "FUFigureColorCollection.h"
#import "FUFigureHorizCollection.h"
#import "FUFigureSlider.h"


@interface FUFigureView ()
<
UIGestureRecognizerDelegate,
FUFigureBottomCollectionDelegate,
//FUFigureDecorationCollectionDelegate,
//FUFigureColorCollectionDelegate,
FUFigureHorizCollectionDelegate,
FUGradientSliderDelegate
>
{
	CGFloat preScale; // 捏合比例
}

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet FUFigureBottomCollection *bottomCollection;

@property (weak, nonatomic) IBOutlet UIView *decorationView;
@property (weak, nonatomic) IBOutlet FUFigureDecorationCollection *decorationCollection;
@property (weak, nonatomic) IBOutlet FUFigureColorCollection *decorationColorCollection;

@property (weak, nonatomic) IBOutlet UIView *glassesView;
@property (weak, nonatomic) IBOutlet FUFigureHorizCollection *glassesCollection;
@property (weak, nonatomic) IBOutlet FUFigureColorCollection *glassesFrameCollection;
@property (weak, nonatomic) IBOutlet FUFigureColorCollection *glassesColorCollection;
@property (weak, nonatomic) IBOutlet UILabel *glassesLabel;
@property (weak, nonatomic) IBOutlet UILabel *glassesFrameLabel;

@property (weak, nonatomic) IBOutlet UIView *colorSliderSuperView;
@property (weak, nonatomic) IBOutlet FUGradientSlider *colorSlider;

@property (weak, nonatomic) IBOutlet UIView *doAndUndoView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *doAndUndoViewBottomConstriants;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomPlaceholderBottom; // 底部collection控件，距离底部的距离，默认是 -34
@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@property (weak, nonatomic) IBOutlet UIButton *redoBtn;

@property (nonatomic,assign)FUAvatarEditedDoModelType type;
@property (weak, nonatomic) IBOutlet UIView *testView;

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
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomAction:)];
    [self addGestureRecognizer:pinchGesture];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self addGestureRecognizer:tapGesture];
    tapGesture.delegate = self ;
    [pinchGesture requireGestureRecognizerToFail:tapGesture];
}

/// 添加通知监听
- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditManagerStackNotEmptyNotMethod) name:FUAvatarEditManagerStackNotEmptyNot object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];
}


-(void)FUAvatarEditManagerStackNotEmptyNotMethod{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (![FUAvatarEditManager sharedInstance].undoStack.isEmpty) {
			self.undoBtn.enabled = YES;
		}
		if (![FUAvatarEditManager sharedInstance].redoStack.isEmpty) {
			self.redoBtn.enabled = YES;
		}
	});
}

- (void)setupFigureView
{
    //撤销重做视图
    self.doAndUndoView.layer.shadowColor = [UIColor colorWithRed:35/255.0 green:53/255.0 blue:95/255.0 alpha:0.15].CGColor; //[UIColor redColor].CGColor;
    //[UIColor colorWithRed:35/255.0 green:53/255.0 blue:95/255.0 alpha:0.15].CGColor;
    self.doAndUndoView.layer.shadowOffset = CGSizeMake(0,1);
    self.doAndUndoView.layer.shadowOpacity = 1;
    self.doAndUndoView.layer.shadowRadius = 6;
    if (appManager.isXFamily) {
        self.bottomPlaceholderBottom.constant = 0;
    }
    
    [self bringSubviewToFront:self.colorSlider];
    [self sendSubviewToBack:self.doAndUndoView];
    
    //添加类别栏的代理监听
    self.bottomCollection.mDelegate = self;
    [self bottomCollectionDidSelectedIndex:0 show:YES animation:NO];
    
    //胡子列表代理
    self.glassesCollection.mDelegate = self;
    
    //颜色栏设置默认属性
    self.decorationColorCollection.currentType = FUFigureColorTypeHairColor ;
    self.decorationColorCollection.hidden = [[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_HAIR] integerValue] == 0 ;
    
    self.colorSlider.delegate = self;
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    self.colorSlider.value = avatar.skinColorProgress;
}

#pragma mark -- FUFigureBottomCollectionDelegate
-(void)bottomCollectionDidSelectedIndex:(NSInteger)index show:(BOOL)show animation:(BOOL)animation
{
    [self.decorationCollection reloadData];

	self.doAndUndoViewBottomConstriants.constant = 300;
	[self hiddenAllTopViewsWithAnimation:NO];
	UIView *subView = nil ;
    
    NSString *type = [FUManager shareInstance].itemTypeArray[index];
    [self.delegate figureViewDidSelectedTypeWithIndex:index];
    subView = self.decorationView ;
    
    if ([type isEqualToString:TAG_FU_ITEM_HAIR])
    {
        self.decorationColorCollection.hidden = [[FUManager shareInstance].currentAvatars.firstObject.hair.name containsString:@"noitem"];
        self.doAndUndoViewBottomConstriants.constant = self.decorationColorCollection.hidden?240:300;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = NO ;
        self.decorationColorCollection.currentType = FUFigureColorTypeHairColor;
        
    }
    else if ([type isEqualToString:TAG_FU_ITEM_FACE])
    {
        self.colorSliderSuperView.hidden = NO;
        self.decorationColorCollection.hidden = YES ;
        self.decorationColorCollection.currentType = FUFigureColorTypeSkinColor;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_EYE])
    {
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = NO ;
        self.decorationColorCollection.currentType = FUFigureColorTypeirisColor;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_MOUTH])
    {
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = NO ;
        self.decorationColorCollection.currentType = FUFigureColorTypeLipsColor;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_NOSE])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_CLOTH])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_SHOES])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_UPPER])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_LOWER])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_HAT])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
        self.decorationColorCollection.currentType = FUFigureColorTypeHatColor;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_EYESHADOW])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_PUPIL])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_EYEBROW])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_EYELINER])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_EYELASH])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_FACEMAKEUP])
      {
          self.doAndUndoViewBottomConstriants.constant = 240;
          self.colorSliderSuperView.hidden = YES ;
          self.decorationColorCollection.hidden = YES ;
      }
    else if ([type isEqualToString:TAG_FU_ITEM_LIPGLOSS])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_BEARD])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
        self.decorationColorCollection.currentType = FUFigureColorTypeBeardColor;
    }
    else if ([type isEqualToString:TAG_FU_ITEM_GLASSES])
    {
        self.colorSliderSuperView.hidden = YES ;
        subView = self.glassesView ;
        self.glassesColorCollection.currentType = FUFigureColorTypeGlassesColor;
        self.glassesFrameCollection.currentType = FUFigureColorTypeGlassesFrameColor;
        self.glassesFrameCollection.hidden = NO ;
        self.glassesColorCollection.hidden = NO ;
        self.glassesLabel.hidden = NO ;
        self.glassesFrameLabel.hidden = NO ;
        NSInteger index = [[FUManager shareInstance].selectedItemIndexDict[TAG_FU_ITEM_GLASSES] integerValue];
        
        [self hiddenGlassColorViews:index == 0?YES:NO];
        [self.glassesCollection reloadData];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_DECORATION])
    {
        self.doAndUndoViewBottomConstriants.constant = 240;
        self.colorSliderSuperView.hidden = YES ;
        self.decorationColorCollection.hidden = YES ;
    }
    
    if (show)
    {
        [self.decorationCollection scrollCurrentToCenterWithAnimation:NO];
        
        subView.hidden = NO;
        if (animation)
        {
            subView.transform = CGAffineTransformMakeTranslation(0, subView.frame.size.height) ;
            [UIView animateWithDuration:0.35 animations:^{
                subView.transform = CGAffineTransformIdentity ;
            }];
        }
        else
        {
            subView.transform = CGAffineTransformIdentity ;
        }
    }
    else
    {
        subView.transform = CGAffineTransformIdentity ;
        [UIView animateWithDuration:0.35 animations:^{
            subView.transform = CGAffineTransformMakeTranslation(0, subView.frame.size.height) ;
            self.doAndUndoViewBottomConstriants.constant = 58;
        } completion:^(BOOL finished) {
            subView.hidden = YES;
        }];
    }
}

- (void)hiddenAllTopViewsWithAnimation:(BOOL)animation {
	
	if (animation) {
		
		[UIView animateWithDuration:0.35 animations:^{
			self.decorationView.transform = CGAffineTransformMakeTranslation(0, self.decorationView.frame.size.height);
			self.glassesView.transform = CGAffineTransformMakeTranslation(0, self.glassesView.frame.size.height) ;
		}completion:^(BOOL finished) {
			self.decorationView.hidden = YES ;
			self.decorationColorCollection.hidden = YES ;
			self.glassesView.hidden = YES ;
		}];
		
	}else {
		self.decorationColorCollection.hidden = YES ;
		self.decorationView.hidden = YES ;
		self.glassesView.hidden = YES ;
	}
}

#pragma mark --- FUFigureHorizCollectionDelegate
- (void)didChangeGlassesWithHiddenColorViews:(BOOL)hidden
{
    [self hiddenGlassColorViews:hidden];
}

-(void)hiddenGlassColorViews:(BOOL)hidden
{
	self.glassesFrameCollection.hidden = hidden ;
	self.glassesColorCollection.hidden = hidden ;
	self.glassesLabel.hidden = hidden ;
	self.glassesFrameLabel.hidden = hidden ;

    if ([FUAvatarEditManager sharedInstance].undo || [FUAvatarEditManager sharedInstance].redo)
    {
        if (self.type == [FUAvatarEditManager sharedInstance].type)
        {
            if (hidden)
            {
                self.doAndUndoViewBottomConstriants.constant = 155;
            }
            else
            {
                self.doAndUndoViewBottomConstriants.constant = 300;
            }
        }
    }
    else
    {
        if (hidden)
        {
            self.doAndUndoViewBottomConstriants.constant = 155;
        }
        else
        {
            self.doAndUndoViewBottomConstriants.constant = 300;
        }
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

- (IBAction)sliderValueChange:(FUFigureSlider *)sender {
//	FUP2AColor *currentColor = nil, *nextColor = nil ;
//	switch (self.decorationColorCollection.currentType) {
//		case FUFigureColorTypeSkinColor:{
//			int index = (int)self.skinLevel ;
//			currentColor = self.skinColorArray[index] ;
//			nextColor = self.skinColorArray[index + 1] ;
//		}
//			break;
//		case FUFigureColorTypeirisColor:{
//			int index = (int)self.irisLevel ;
//			currentColor = self.irisColorArray[index] ;
//			nextColor = self.irisColorArray[index + 1] ;
//		}
//			break ;
//		case FUFigureColorTypeLipsColor:{
//			int index = (int)self.lipLevel ;
//			currentColor = self.lipsColorArray[index] ;
//			nextColor = self.lipsColorArray[index + 1] ;
//		}
//			break ;
//
//		default:
//			break;
//	}
//
//	if (currentColor && nextColor) {
//
//		double scale = sender.value ;
//
//		FUP2AColor *color = [FUP2AColor colorWithR:(nextColor.r - currentColor.r) * scale + currentColor.r
//												 g:(nextColor.g - currentColor.g) * scale + currentColor.g
//												 b:(nextColor.b - currentColor.b) * scale + currentColor.b];
//
//		switch (self.decorationColorCollection.currentType) {
//			case FUFigureColorTypeSkinColor:{
//				self.skinLevel = sender.value + (int)self.skinLevel;
//				if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:index:)]) {
//					[self.delegate figureViewDidChangeSkinColor:color index:self.skinLevel];
//				}
//			}
//				break;
//			case FUFigureColorTypeirisColor:{
//				self.irisLevel = sender.value + (int)self.irisLevel ;
//				if ([self.delegate respondsToSelector:@selector(figureViewDidChangeIrisColor:index:)]) {
//					[self.delegate figureViewDidChangeIrisColor:color index:self.irisLevel];
//				}
//			}
//				break ;
//			case FUFigureColorTypeLipsColor:{
//				self.lipLevel = sender.value + (int)self.lipLevel ;
//				if ([self.delegate respondsToSelector:@selector(figureViewDidChangeLipsColor:index:)]) {
//					[self.delegate figureViewDidChangeLipsColor:color index:self.lipLevel];
//				}
//			}
//				break ;
//
//			default:
//				break;
//		}
//	}
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
#pragma mark --- input data source

/**
 当touchMove的时候，判断是否需要隐藏view
 */
//-(void)shouldHidePartViews{
//	if ((self.decorationCollection.currentType == FUFigureDecorationCollectionTypeClothes || self.decorationCollection.currentType == FUFigureDecorationCollectionTypeShoes) &&  self.decorationView.hidden == NO) {
//			[[FUManager shareInstance].currentAvatars.firstObject resetScaleToFace];
//	}
//}
// ==============================================根据指定名称滚动到相应图标==================================
-(void)FUAvatarEditedDoNotMethod:(NSNotification *)not{
//	FUAvatarEditedDoModel * model = [not object];
//	switch (model.type) {
//		case SkinColorProgress:
//		{
//			//	[self scrollToTheHair:model.obj];
//			float progress = [(NSNumber *)model.obj floatValue];
//			self.colorSlider.value = progress;
//			FUP2AColor * color = [FUP2AColor color:[appManager returnFUGradientSliderColor:progress]];
//			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor: index:)]) {
//				[self.delegate figureViewDidChangeSkinColor:color index:0];
//			}
//		}
//			break;
//
//		default:
//			break;
//	}
}

-(void)dealloc
{
	NSLog(@"FUFigureView销毁了------");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint undoBtnPoint = [self convertPoint:point toView:self.undoBtn];
    if ([self.undoBtn pointInside:undoBtnPoint withEvent:event])
    {
         return self.undoBtn;
    }
    
    CGPoint redoBtnPoint = [self convertPoint:point toView:self.redoBtn];
    if ([self.redoBtn pointInside:redoBtnPoint withEvent:event])
    {
         return self.redoBtn;
    }
    
    return [super hitTest:point withEvent:event];
}

#pragma mark ------ Events ------
- (void)zoomAction:(UIPinchGestureRecognizer *)gesture
{
    float curScale = gesture.scale;
    
    if (curScale < 1.0)
    {
        curScale = - fabsf(1 / curScale - 1);
    }
    else
    {
        curScale -= 1;
    }
    
    float ds = curScale - preScale;
    preScale = curScale;
    
    if ([self.delegate respondsToSelector:@selector(figureViewDidReceiveZoomAction:)])
    {
        [self.delegate figureViewDidReceiveZoomAction:ds];
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        preScale = 0.0;
    }
}

- (void)tapClick:(UITapGestureRecognizer *)tap
{
    [self.bottomCollection hiddenSelectedLine];
    
    if (!self.decorationView.hidden)
    {
        [self.delegate figureViewDidHiddenAllTypeViews];
    }
    [self hiddenAllTopViewsWithAnimation:YES];
    self.doAndUndoViewBottomConstriants.constant = 58;
    [self layoutIfNeeded];
}



@end
