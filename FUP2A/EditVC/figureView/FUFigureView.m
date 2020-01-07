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
FUFigureDecorationCollectionDelegate,
FUFigureColorCollectionDelegate,
FUFigureHorizCollectionDelegate
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
}


- (void)setupFigureView {
	
	UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomAction:)];
	[self addGestureRecognizer:pinchGesture];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
	[self addGestureRecognizer:tapGesture];
	tapGesture.delegate = self ;
	[pinchGesture requireGestureRecognizerToFail:tapGesture];  // decorationView.hidden
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditManagerStackNotEmptyNotMethod) name:FUAvatarEditManagerStackNotEmptyNot object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];
	self.type = Hair;
	[self loadSubViewData];
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


- (void)zoomAction:(UIPinchGestureRecognizer *)gesture {
	float curScale = gesture.scale;
	
	if (curScale < 1.0) {
		curScale = - fabsf(1 / curScale - 1);
	}else   {
		curScale -= 1;
	}
	
	float ds = curScale - preScale;
	preScale = curScale;
	
	if ([self.delegate respondsToSelector:@selector(figureViewDidReceiveZoomAction:)]) {
		[self.delegate figureViewDidReceiveZoomAction:ds];
	}
	
	if (gesture.state == UIGestureRecognizerStateEnded) {
		preScale = 0.0;
	}
}

- (void)tapClick:(UITapGestureRecognizer *)tap {
	[self.bottomCollection hiddenSelectedItem];
	
	if (!self.decorationView.hidden) {
        [self.delegate figureViewDidHiddenAllTypeViews];
	}
	[self hiddenAllTopViewsWithAnimation:YES];
	self.doAndUndoViewBottomConstriants.constant = 58;
	[self layoutIfNeeded];
}


- (void)loadSubViewData {
	
	self.bottomCollection.mDelegate = self ;
	
	// decorations
	self.decorationCollection.hairArray = self.hairArray;
	self.decorationCollection.hair = self.hair ;
	
	self.decorationCollection.beardArray = self.beardArray ;
	self.decorationCollection.beard = self.beard ;
	
	self.decorationCollection.eyeBrowArray = self.eyeBrowArray ;
	self.decorationCollection.eyeBrow = self.eyeBrow ;
	
	self.decorationCollection.eyeLashArray = self.eyeLashArray ;
	self.decorationCollection.eyeLash = self.eyeLash ;
	
	self.decorationCollection.hatArray = self.hatArray ;
	self.decorationCollection.hat = self.hat ;
	
	self.decorationCollection.clothesArray = self.clothesArray ;
	self.decorationCollection.clothes = self.clothes ;
	// 上衣
	self.decorationCollection.upperArray = self.upperArray ;
	self.decorationCollection.upper = self.upper;
	// 裤子
	self.decorationCollection.lowerArray = self.lowerArray ;
	self.decorationCollection.lower = self.lower;
	// 鞋子
	self.decorationCollection.shoesArray = self.shoesArray ;
	self.decorationCollection.shoes = self.shoes ;
	// 配饰
	self.decorationCollection.decorationsArray = self.decorationsArray ;
	self.decorationCollection.decorations = self.decorations;
	
	
	
	// face shape
	self.decorationCollection.faceArray = self.faceArray ;
	self.decorationCollection.face = self.face ;
	
	self.decorationCollection.eyesArray = self.eyeArray ;
	self.decorationCollection.eyes = self.eyes ;
	
	self.decorationCollection.mouthArray = self.mouthArray ;
	self.decorationCollection.mouth = self.mouth ;
	
	self.decorationCollection.noseArray = self.noseArray ;
	self.decorationCollection.nose = self.nose ;
	
	self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHair ;
	
	[self.decorationCollection loadDecorationData];
	
	self.decorationCollection.mDelegate = self ;
	self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHair ;
	
	// color
	self.decorationColorCollection.hairColorArray = self.hairColorArray ;
	self.decorationColorCollection.hairColor = self.hairColor ;
	
	self.decorationColorCollection.skinColorArray = self.skinColorArray ;
	self.decorationColorCollection.skinColor = self.skinColorArray[(int)self.skinLevel];
	
	self.decorationColorCollection.irisColorArray = self.irisColorArray ;
	self.decorationColorCollection.irisColor = self.irisColorArray[(int)self.irisLevel] ;
	
	self.decorationColorCollection.lipsColorArray = self.lipsColorArray ;
	self.decorationColorCollection.lipsColor = self.lipsColorArray[(int)self.lipLevel] ;
	
	self.decorationColorCollection.beardColorArray = self.beardColorArray ;
	self.decorationColorCollection.beardColor = self.beardColor ;
	
	self.decorationColorCollection.hatColorArray = self.hatColorArray ;
	self.decorationColorCollection.hatColor = self.hatColor ;
	//
	//    self.decorationColorCollection.glassesColorArray = self.glassesColorArray ;
	//    self.decorationColorCollection.glassesColor = self.glassesColor ;
	//
	//    self.decorationColorCollection.glassesFrameColorArray = self.glassesFrameColorArray ;
	//    self.decorationColorCollection.glassesFrameColor = self.glassesFrameColor ;
	//
	[self.decorationColorCollection loadColorData];
	
	self.decorationColorCollection.mDelegate = self ;
	self.decorationColorCollection.currentType = FUFigureColorTypeHairColor ;
	
	self.decorationColorCollection.hidden = [self.hairArray indexOfObject:self.hair] == 0 ;
	
	
	self.glassesView.hidden = YES ;
	
	// glasses
	self.glassesCollection.glassesArray = self.glassesArray ;
	self.glassesCollection.glasses = self.glasses ;
	BOOL hidden = [self.glasses containsString:@"noitem"];
	if (self.glasses == nil || hidden == YES) {
		[self hiddenGlassColorViews:YES];
	}
	[self.glassesCollection loadCollectionData];
	self.glassesCollection.mDelegate = self ;
	
	// glasses color
	self.glassesColorCollection.glassesColorArray = self.glassesColorArray ;
	self.glassesColorCollection.glassesColor = self.glassesColor ;
	self.glassesColorCollection.glassColorIndex = self.glassColorIndex;
	[self.glassesColorCollection loadColorData];
	self.glassesColorCollection.mDelegate = self ;
	self.glassesColorCollection.currentType = FUFigureColorTypeGlassesColor ;
	
	self.glassesFrameCollection.glassesFrameColorArray = self.glassesFrameColorArray ;
	self.glassesFrameCollection.glassesFrameColor = self.glassesFrameColor ;
	self.glassesFrameCollection.glassFrameColorIndex = self.glassFrameColorIndex;
	[self.glassesFrameCollection loadColorData];
	self.glassesFrameCollection.mDelegate = self ;
	self.glassesFrameCollection.currentType = FUFigureColorTypeGlassesFrameColor ;
	
	if (self.decorationColorCollection.hidden) {
		self.doAndUndoViewBottomConstriants.constant = 240;
	}else{
		self.doAndUndoViewBottomConstriants.constant = 300;
	}
	[self layoutIfNeeded];
}
-(void)resetUI{
	
	//  [self.decorationCollection recoverCollectionViewUI];
	self.face = nil;
	self.mouth = nil;
	self.eyes = nil;
	self.nose = nil;
	
	
	
}
#pragma mark -- FUFigureBottomCollectionDelegate

-(void)bottomCollectionDidSelectedIndex:(NSInteger)index show:(BOOL)show animation:(BOOL)animation {
	
	// record oldValue
	double old_doAndUndoViewBottomConstriants = self.doAndUndoViewBottomConstriants.constant;
	self.doAndUndoViewBottomConstriants.constant = 300;
	[self hiddenAllTopViewsWithAnimation:NO];
	UIView *subView = nil ;
	switch (index) {
		case 0:{    // 发型
			self.type = Hair;
			self.decorationColorCollection.hidden = [[FUManager shareInstance].currentAvatars.firstObject.hair containsString:@"noitem"];
            self.doAndUndoViewBottomConstriants.constant = self.decorationColorCollection.hidden?240:300;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHair ;
			self.decorationColorCollection.currentType = FUFigureColorTypeHairColor ;
			self.colorSliderSuperView.hidden = YES ;
		}
			break;
		case 1:{    // 脸型
			self.type = Face;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeFace ;
			self.decorationColorCollection.hidden = YES ;
			self.decorationColorCollection.currentType = FUFigureColorTypeSkinColor ;
			self.colorSliderSuperView.hidden = NO;
			self.colorSlider.value = self.skinProgress;
		}
			break;
		case 2:{    // 眼型
			self.type = Eyes;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeEyes ;
			self.decorationColorCollection.hidden = NO ;
			self.decorationColorCollection.currentType = FUFigureColorTypeirisColor ;
			self.colorSliderSuperView.hidden = YES ;
		}
			break;
		case 3:{    // 嘴型
			self.type = Mouth;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeMouth ;
			self.decorationColorCollection.hidden = NO ;
			self.decorationColorCollection.currentType = FUFigureColorTypeLipsColor ;
			self.colorSliderSuperView.hidden = YES ;
		}
			break;
		case 4:{    // 鼻子
			self.type = Nose;
			self.doAndUndoViewBottomConstriants.constant = 240;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeNose ;
			self.colorSliderSuperView.hidden = YES ;
		}
			break;
		case 5:{    // Q/male: 胡子 female:眉毛
			self.type = Beard;
			self.doAndUndoViewBottomConstriants.constant = 240;
			
			subView = self.decorationView ;
			self.colorSliderSuperView.hidden = YES ;
			if (self.avatarStyle == FUAvatarStyleNormal && self.avatarIsMale == NO) {
				self.decorationCollection.currentType = FUFigureDecorationCollectionTypeEyeBrow ;
			}else {
				self.decorationCollection.currentType = FUFigureDecorationCollectionTypeBeard ;
			}
		}
			break;
		case 6:{    // Q/male: 眉毛 female:睫毛
			self.type = Glasses;
			
			self.doAndUndoViewBottomConstriants.constant = 155;
			if (self.avatarStyle == FUAvatarStyleQ) {// Q:眼镜
				subView = self.glassesView ;
				if (![self.glasses containsString:@"noitem"]) {
					self.glassesFrameCollection.hidden = NO ;
					self.glassesColorCollection.hidden = NO ;
					self.glassesLabel.hidden = NO ;
					self.glassesFrameLabel.hidden = NO ;
					self.doAndUndoViewBottomConstriants.constant = 300;
                    
                    [self.glassesCollection scrollCurrentToCenterWithAnimation:NO];
				}else{
				}
			}else { // male: 眉毛 female:睫毛
				subView = self.decorationView ;
				self.colorSliderSuperView.hidden = YES ;
				self.decorationCollection.currentType = self.avatarStyle == FUAvatarStyleNormal && self.avatarIsMale == NO ? FUFigureDecorationCollectionTypeEyeLash : FUFigureDecorationCollectionTypeEyeBrow ;
			}
		}
			break;
//		case 7:{    // Q: 睫毛 normal: 眼镜
//			self.type = Hat;
//			if (self.avatarStyle == FUAvatarStyleQ) {   // Q: 帽子
//				subView = self.decorationView ;
//				self.colorSliderSuperView.hidden = YES ;
//				self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHat ;
//				self.doAndUndoViewBottomConstriants.constant = 240;
//
//				if (![self.hat containsString:@"noitem"]) {
//					self.decorationColorCollection.hidden = NO ;
//					self.doAndUndoViewBottomConstriants.constant = 300;
//					self.decorationColorCollection.currentType = FUFigureColorTypeHatColor ;
//				}
//			}else { //  normal: 眼镜
//				subView = self.glassesView ;
//				if ([self.glassesArray indexOfObject:self.glasses] != NSNotFound) {
//					self.glassesFrameCollection.hidden = NO ;
//					self.glassesColorCollection.hidden = NO ;
//					self.glassesLabel.hidden = NO ;
//					self.glassesFrameLabel.hidden = NO ;				}
//			}
//		}
			break;
		case 7:{    // Q: 眼镜 normal: 帽子
			self.type = Clothes;
			self.doAndUndoViewBottomConstriants.constant = 240;
			if (self.avatarStyle == FUAvatarStyleQ) {   // Q:衣服
				self.colorSliderSuperView.hidden = YES ;
				subView = self.decorationView ;
				self.decorationCollection.currentType = FUFigureDecorationCollectionTypeClothes ;
			}else { // 帽子
				subView = self.decorationView ;
				self.colorSliderSuperView.hidden = YES ;
				self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHat ;
				if ([self.hatArray indexOfObject:self.hat] != NSNotFound) {
					self.decorationColorCollection.hidden = NO ;
					self.decorationColorCollection.currentType = FUFigureColorTypeHatColor ;
				}
			}
		}
			break;
			
		case 8:{    // Q: 上衣
			self.type = Upper;
			self.doAndUndoViewBottomConstriants.constant = 240;
			self.colorSliderSuperView.hidden = YES ;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeUpper;
		}
			break;
		case 9:{    // Q: 裤子
			self.type = Lower;
			self.doAndUndoViewBottomConstriants.constant = 240;
			self.colorSliderSuperView.hidden = YES ;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeLower ;
		}
			break;
			
		case 10:{    // Q：鞋子
			self.type = Shoes;
			self.doAndUndoViewBottomConstriants.constant = 240;
			self.colorSliderSuperView.hidden = YES ;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeShoes ;
		}
			break;
		case 11:{    // Q: 配饰
			self.type = Decorations;
			self.doAndUndoViewBottomConstriants.constant = 240;
			self.colorSliderSuperView.hidden = YES ;
			subView = self.decorationView ;
			self.decorationCollection.currentType = FUFigureDecorationCollectionTypeDecorations ;
		}
			break;
			
		default:
			break;
	}
	
	subView.hidden = NO ;
	
	if (!show) {    // 隐藏
		[self.delegate figureViewDidHiddenAllTypeViews];
		subView.transform = CGAffineTransformIdentity ;
		[UIView animateWithDuration:0.35 animations:^{
			subView.transform = CGAffineTransformMakeTranslation(0, subView.frame.size.height) ;
		} completion:^(BOOL finished) {
			subView.hidden = YES ;
		}];
		
	}else {     // 显示
		
		if ([self.delegate respondsToSelector:@selector(figureViewDidSelectedTypeWithIndex:)]) {
			[self.delegate figureViewDidSelectedTypeWithIndex:index] ;
		}
		
		if (animation) {
			subView.transform = CGAffineTransformMakeTranslation(0, subView.frame.size.height) ;
			[UIView animateWithDuration:0.35 animations:^{
				subView.transform = CGAffineTransformIdentity ;
			}];
		}else {
			subView.transform = CGAffineTransformIdentity ;
		}
	}
	if(!show){
		self.doAndUndoViewBottomConstriants.constant = 58;
	}else if (self.decorationView.hidden &&  self.glassesView.hidden) {
		self.doAndUndoViewBottomConstriants.constant = old_doAndUndoViewBottomConstriants;
	}else{
		[self layoutIfNeeded];
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


#pragma mark --- FUFigureDecorationCollectionDelegate
- (void)decorationCollectionDidSelectedUpperItem:(NSString *)upperItemName lowerItem:(NSString *)lowerItemName {
    double old_doAndUndoViewBottomConstriants = self.doAndUndoViewBottomConstriants.constant;
    
    self.upper = [upperItemName stringByAppendingString:@".bundle"] ;
    self.lower = [lowerItemName stringByAppendingString:@".bundle"] ;
    self.clothes = @"clothes-noitem";
    
    if ([self.delegate respondsToSelector:@selector(figureViewDidChangeUpper:andLower:)]) {
        [self.delegate figureViewDidChangeUpper:upperItemName andLower:lowerItemName];
    }
    
    if (self.decorationView.hidden &&  self.glassesView.hidden) {
        self.doAndUndoViewBottomConstriants.constant = old_doAndUndoViewBottomConstriants;
    }
    [self layoutIfNeeded];
}

- (void)decorationCollectionDidSelectedItem:(NSString *)itemName index:(NSInteger)index decorationType:(FUFigureDecorationCollectionType)type {
	
	double old_doAndUndoViewBottomConstriants = self.doAndUndoViewBottomConstriants.constant;
	FUAvatar *currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
	switch (type) {
		case FUFigureDecorationCollectionTypeHair:{
			if([itemName isEqualToString:@"female_hair_q_12"] && ![currentAvatar.hat containsString:@"noitem"])
			{
				[SVProgressHUD showInfoWithStatus:@"此发型暂不支持帽子哦"];
				return;
			}
			self.hair = [itemName stringByAppendingString:@".bundle"] ;
			if ([FUAvatarEditManager sharedInstance].undo || [FUAvatarEditManager sharedInstance].redo) {
				if (self.type == [FUAvatarEditManager sharedInstance].type) {
					self.decorationColorCollection.hidden = [itemName containsString:@"noitem"];
					if (self.decorationColorCollection.hidden) {
						self.doAndUndoViewBottomConstriants.constant = 240;
					}else{
						self.doAndUndoViewBottomConstriants.constant = 300;
					}
				}
			}
			else{
				self.decorationColorCollection.hidden = [itemName containsString:@"noitem"];
				if (self.decorationColorCollection.hidden) {
					self.doAndUndoViewBottomConstriants.constant = 240;
				}else{
					self.doAndUndoViewBottomConstriants.constant = 300;
				}
			}
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHair:)]) {
				[self.delegate figureViewDidChangeHair:itemName];
			}
			
		}
			break;
		case FUFigureDecorationCollectionTypeFace:{
			self.face = itemName ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeFace:index:)]) {
				[self.delegate figureViewDidChangeFace:itemName index:index];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeEyes:{
			self.eyes = itemName ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeEyes:index:)]) {
				[self.delegate figureViewDidChangeEyes:itemName index:index];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeMouth:{
			self.mouth = itemName ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeMouth:index:)]) {
				[self.delegate figureViewDidChangeMouth:itemName index:index];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeNose:{
			self.nose = itemName ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeNose:index:)]) {
				[self.delegate figureViewDidChangeNose:itemName index:index];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeBeard:{
			self.beard = [itemName stringByAppendingString:@".bundle"] ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeBeard:)]) {
				[self.delegate figureViewDidChangeBeard:itemName];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeEyeBrow:{
			self.eyeBrow = itemName ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeEyeBrow:)]) {
				[self.delegate figureViewDidChangeEyeBrow:itemName];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeEyeLash:{
			self.eyeLash = itemName ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeeyeLash:)]) {
				[self.delegate figureViewDidChangeeyeLash:itemName];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeHat:{
			if([currentAvatar.hair isEqualToString:@"female_hair_q_12"] && ![itemName containsString:@"noitem"])
			{
				[SVProgressHUD showInfoWithStatus:@"此发型暂不支持帽子哦"];
				return;
			}
			self.hat = [itemName stringByAppendingString:@".bundle"] ;
			if ([FUAvatarEditManager sharedInstance].undo || [FUAvatarEditManager sharedInstance].redo) {
				if (self.type == [FUAvatarEditManager sharedInstance].type) {
					self.decorationColorCollection.hidden = [itemName containsString:@"noitem"];
					if (self.decorationColorCollection.hidden) {
						self.doAndUndoViewBottomConstriants.constant = 240;
					}else{
						self.doAndUndoViewBottomConstriants.constant = 300;
					}
				}
			}else{
				self.decorationColorCollection.hidden = [itemName containsString:@"noitem"];
				if (self.decorationColorCollection.hidden) {
					self.doAndUndoViewBottomConstriants.constant = 240;
				}else{
					self.doAndUndoViewBottomConstriants.constant = 300;
				}
			}
			self.decorationColorCollection.currentType = FUFigureColorTypeHatColor ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHat:)]) {
				[self.delegate figureViewDidChangeHat:itemName];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeClothes:{
			self.clothes = [itemName stringByAppendingString:@".bundle"] ;
            self.upper = @"upper-noitem.bundle";
            self.lower = @"lower-noitem.bundle";
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeClothes:)]) {
				[self.delegate figureViewDidChangeClothes:itemName];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeUpper:{
			self.upper = [itemName stringByAppendingString:@".bundle"] ;
            self.clothes = @"clothes-noitem.bundle";
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeClothes:)]) {
				[self.delegate figureViewDidChangeUpper:itemName];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeLower:{
			self.lower = [itemName stringByAppendingString:@".bundle"] ;
            self.clothes = @"clothes-noitem.bundle";
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeClothes:)]) {
				[self.delegate figureViewDidChangeLower:itemName];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeShoes:{
			self.shoes = [itemName stringByAppendingString:@".bundle"] ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeShoes:)]) {
				[self.delegate figureViewDidChangeShoes:itemName];
			}
		}
			break;
		case FUFigureDecorationCollectionTypeDecorations:{
			self.decorations = [itemName stringByAppendingString:@".bundle"] ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeClothes:)]) {
				[self.delegate figureViewDidChangeDecorations:itemName];
			}
		}
			break;
	}
	if (self.decorationView.hidden &&  self.glassesView.hidden) {
		self.doAndUndoViewBottomConstriants.constant = old_doAndUndoViewBottomConstriants;
	}
	[self layoutIfNeeded];
	
}

#pragma mark --- FUFigureColorCollectionDelegate

- (void)didSelectedColor:(FUP2AColor *)currentColor index:(NSInteger)index tyep:(FUFigureColorType)type {
	switch (type) {
		case FUFigureColorTypeHairColor:{
			self.hairColor = currentColor ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHairColor: index:)]) {
				[self.delegate figureViewDidChangeHairColor:currentColor index:index];
			}
		}
			break;
		case FUFigureColorTypeSkinColor: {
			self.skinLevel = index ;
			self.colorSlider.value = 0.0 ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor: index:)]) {
				[self.delegate figureViewDidChangeSkinColor:currentColor index:index];
			}
		}
			break;
		case FUFigureColorTypeirisColor: {
			self.irisLevel = index ;
			self.colorSlider.value = 0.0 ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeIrisColor: index:)]) {
				[self.delegate figureViewDidChangeIrisColor:currentColor index:index];
			}
		}
			break;
		case FUFigureColorTypeLipsColor: {
			self.lipLevel = index ;
			self.colorSlider.value = 0.0 ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeLipsColor: index:)]) {
				[self.delegate figureViewDidChangeLipsColor:currentColor index:index];
			}
		}
			break;
		case FUFigureColorTypeBeardColor: {
			self.beardColor = currentColor ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeBeard:)]) {
				[self.delegate figureViewDidChangeBeardColor:currentColor];
			}
		}
			break;
		case FUFigureColorTypeHatColor: {
			self.hatColor = currentColor ;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHat:)]) {
				[self.delegate figureViewDidChangeHatColor:currentColor];
			}
		}
			break;
		case FUFigureColorTypeGlassesColor: {
			self.glassesColor = currentColor ;
			self.glassColorIndex = index;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlassesColor: index:)]) {
				[self.delegate figureViewDidChangeGlassesColor:currentColor index:index];
			}
		}
			break;
		case FUFigureColorTypeGlassesFrameColor: {
			self.glassesFrameColor = currentColor ;
			self.glassFrameColorIndex = index;
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlassesFrameColor: index:)]) {
				[self.delegate figureViewDidChangeGlassesFrameColor:currentColor index:index];
			}
		}
			break;
	}
}

#pragma mark --- FUFigureHorizCollectionDelegate
- (void)didChangeGlasses:(NSString *)glasses {
	self.glasses = [glasses stringByAppendingString:@".bundle"] ;
	BOOL hidden = [glasses containsString:@"noitem"];
	[self hiddenGlassColorViews:hidden];
	
	if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlasses:)]) {
		[self.delegate figureViewDidChangeGlasses:glasses];
	}
}

-(void)hiddenGlassColorViews:(BOOL)hidden{
	self.glassesFrameCollection.hidden = hidden ;
	self.glassesColorCollection.hidden = hidden ;
	self.glassesLabel.hidden = hidden ;
	self.glassesFrameLabel.hidden = hidden ;
	if (self.decorationView.hidden &&  self.glassesView.hidden) {
		
	}else{
		if ([FUAvatarEditManager sharedInstance].undo || [FUAvatarEditManager sharedInstance].redo) {
			if (self.type == [FUAvatarEditManager sharedInstance].type) {
				if (hidden) {
					self.doAndUndoViewBottomConstriants.constant = 155;
				}else{
					self.doAndUndoViewBottomConstriants.constant = 300;
				}
			}
		}else{
			if (hidden) {
				self.doAndUndoViewBottomConstriants.constant = 155;
			}else{
				self.doAndUndoViewBottomConstriants.constant = 300;
			}
		}
	}
}

- (IBAction)valueChanged:(FUGradientSlider *)sender {
	FUP2AColor *currentColor = nil, *nextColor = nil ;
	switch (self.decorationColorCollection.currentType) {
		case FUFigureColorTypeSkinColor:{
			self.skinProgress = sender.value;
			FUP2AColor * color = [FUP2AColor color:[appManager returnFUGradientSliderColor:self.skinProgress]];
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:index:)]) {
				[self.delegate figureViewDidChangeSkinColor:color index:0];
			}
		}
			break;
		default:
			break;
	}
}
- (IBAction)sliderValueChange:(FUFigureSlider *)sender {
	FUP2AColor *currentColor = nil, *nextColor = nil ;
	switch (self.decorationColorCollection.currentType) {
		case FUFigureColorTypeSkinColor:{
			int index = (int)self.skinLevel ;
			currentColor = self.skinColorArray[index] ;
			nextColor = self.skinColorArray[index + 1] ;
		}
			break;
		case FUFigureColorTypeirisColor:{
			int index = (int)self.irisLevel ;
			currentColor = self.irisColorArray[index] ;
			nextColor = self.irisColorArray[index + 1] ;
		}
			break ;
		case FUFigureColorTypeLipsColor:{
			int index = (int)self.lipLevel ;
			currentColor = self.lipsColorArray[index] ;
			nextColor = self.lipsColorArray[index + 1] ;
		}
			break ;
			
		default:
			break;
	}
	
	if (currentColor && nextColor) {
		
		double scale = sender.value ;
		
		FUP2AColor *color = [FUP2AColor colorWithR:(nextColor.r - currentColor.r) * scale + currentColor.r
												 g:(nextColor.g - currentColor.g) * scale + currentColor.g
												 b:(nextColor.b - currentColor.b) * scale + currentColor.b];
		
		switch (self.decorationColorCollection.currentType) {
			case FUFigureColorTypeSkinColor:{
				self.skinLevel = sender.value + (int)self.skinLevel;
				if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:index:)]) {
					[self.delegate figureViewDidChangeSkinColor:color index:self.skinLevel];
				}
			}
				break;
			case FUFigureColorTypeirisColor:{
				self.irisLevel = sender.value + (int)self.irisLevel ;
				if ([self.delegate respondsToSelector:@selector(figureViewDidChangeIrisColor:index:)]) {
					[self.delegate figureViewDidChangeIrisColor:color index:self.irisLevel];
				}
			}
				break ;
			case FUFigureColorTypeLipsColor:{
				self.lipLevel = sender.value + (int)self.lipLevel ;
				if ([self.delegate respondsToSelector:@selector(figureViewDidChangeLipsColor:index:)]) {
					[self.delegate figureViewDidChangeLipsColor:color index:self.lipLevel];
				}
			}
				break ;
				
			default:
				break;
		}
	}
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

-(FUP2AColor*)getSkinColor{
	return [FUP2AColor color:[appManager returnFUGradientSliderColor:self.skinProgress]];
}
-(FUP2AColor *)getLipColor{
	return self.lipsColorArray[(int)self.lipLevel];
}
-(FUP2AColor *)getIrisColor{
	return self.irisColorArray[(int)self.irisLevel];
}
#pragma mark --- input data source

-(void)setAvatarStyle:(FUAvatarStyle)avatarStyle {
	_avatarStyle = avatarStyle ;
	
	switch (avatarStyle) {
		case FUAvatarStyleNormal:{
			self.bottomCollection.dataArray = self.avatarIsMale ? @[@"发型", @"脸型", @"眼型", @"嘴型", @"鼻型", @"胡子", @"眉毛", @"眼镜", @"帽子", @"衣服"] : @[@"发型", @"脸型", @"眼型", @"嘴型", @"鼻型", @"眉毛", @"睫毛", @"眼镜", @"帽子", @"衣服"] ;
		}
			break;
		case FUAvatarStyleQ:{
			self.bottomCollection.dataArray = @[@"发型", @"脸型", @"眼型", @"嘴型", @"鼻型", @"胡子", @"眼镜", @"衣服", @"上衣", @"下衣", @"鞋子",@"配饰"] ;
		}
			break ;
	}
}

-(void)setAvatarIsMale:(BOOL)avatarIsMale {
	_avatarIsMale = avatarIsMale ;
	if (self.avatarStyle == FUAvatarStyleNormal) {
		self.bottomCollection.dataArray = avatarIsMale ? @[@"发型", @"脸型", @"眼型", @"嘴型", @"鼻型", @"胡子", @"眉毛", @"眼镜", @"帽子", @"衣服"] : @[@"发型", @"脸型", @"眼型", @"嘴型", @"鼻型", @"眉毛", @"睫毛", @"眼镜", @"帽子", @"衣服"] ;
	}
}
/**
 当touchMove的时候，判断是否需要隐藏view
 */
-(void)shouldHidePartViews{
	if ((self.decorationCollection.currentType == FUFigureDecorationCollectionTypeClothes || self.decorationCollection.currentType == FUFigureDecorationCollectionTypeShoes) &&  self.decorationView.hidden == NO) {
			[[FUManager shareInstance].currentAvatars.firstObject resetScaleToFace];
	}
}
// ==============================================根据指定名称滚动到相应图标==================================
-(void)FUAvatarEditedDoNotMethod:(NSNotification *)not{
	FUAvatarEditedDoModel * model = [not object];
	switch (model.type) {
		case SkinColorProgress:
		{
			//	[self scrollToTheHair:model.obj];
			float progress = [(NSNumber *)model.obj floatValue];
			self.colorSlider.value = progress;
			FUP2AColor * color = [FUP2AColor color:[appManager returnFUGradientSliderColor:progress]];
			if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor: index:)]) {
				[self.delegate figureViewDidChangeSkinColor:color index:0];
			}
		}
			break;
			
		default:
			break;
	}
}

-(void)dealloc{
	NSLog(@"FUFigureView销毁了------");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark --- UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	
	for (UIView *view in self.subviews) {
		if ([touch.view isDescendantOfView:view] && touch.view != self.decorationView) {
			return NO ;
		}
	}
	return YES ;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint undoBtnPoint = [self convertPoint:point toView:self.undoBtn];
    if ([self.undoBtn pointInside:undoBtnPoint withEvent:event]) {
         return self.undoBtn;
    }
    
    CGPoint redoBtnPoint = [self convertPoint:point toView:self.redoBtn];
    if ([self.redoBtn pointInside:redoBtnPoint withEvent:event])
    {
         return self.redoBtn;
    }
    
    return [super hitTest:point withEvent:event];
}
@end
