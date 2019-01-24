//
//  FUFigureView.m
//  EditView
//
//  Created by L on 2018/11/2.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUFigureView.h"
#import "UIColor+FU.h"
#import "FUP2AColor.h"
#import "FUManager.h"
#import "FUAvatar.h"
#import <SVProgressHUD.h>

#import "FUFigureBottomCollection.h"
#import "FUFigureDecorationCollection.h"
#import "FUFigureDecorationColorCollection.h"
#import "FUFigureFaceCollection.h"
#import "FUFigureSlider.h"
#import "FUFigureDecorationHorizCollection.h"

@interface FUFigureView ()
<
UIGestureRecognizerDelegate,
FUFigureBottomCollectionDelegate,
FUFigureDecorationCollectionDelegate,
FUFigureDecorationColorCollectionDelegate,
FUFigureFaceCollectionDelegate,
FUFigureDecorationHorizCollectionDelegate
>
{
    BOOL isMale ;
    
    CGFloat preScale; // 捏合比例
}

@property (weak, nonatomic) IBOutlet FUFigureBottomCollection *bottomCollection;

@property (weak, nonatomic) IBOutlet UIView *decorationView;
@property (weak, nonatomic) IBOutlet FUFigureDecorationCollection *decorationCollection;
@property (weak, nonatomic) IBOutlet FUFigureDecorationColorCollection *decorationColorCollection;

@property (weak, nonatomic) IBOutlet UIView *faceView;
@property (weak, nonatomic) IBOutlet FUFigureFaceCollection *faceCollection;
@property (weak, nonatomic) IBOutlet UIView *faceSliderView;
@property (weak, nonatomic) IBOutlet FUFigureSlider *faceSlider;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *middleLabelLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *middleSliderLeft;
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;
@property (weak, nonatomic) IBOutlet FUFigureDecorationColorCollection *faceColorCollection;

@property (weak, nonatomic) IBOutlet UIView *glassesView;
@property (weak, nonatomic) IBOutlet FUFigureDecorationHorizCollection *glassesCollection;
@property (weak, nonatomic) IBOutlet UIView *glassesColorView;
@property (weak, nonatomic) IBOutlet FUFigureDecorationColorCollection *glassesFrameColorCollection;
@property (weak, nonatomic) IBOutlet FUFigureDecorationColorCollection *glassesColorCollection;

// face shape value
@property (nonatomic, assign) double headShrink0 ;
@property (nonatomic, assign) double headBoneStretch0  ;
@property (nonatomic, assign) double cheekNarrow0 ;
@property (nonatomic, assign) double jawboneNarrow0 ;
@property (nonatomic, assign) double jawLower0 ;
// eye shape value
@property (nonatomic, assign) double eyeUp0 ;
@property (nonatomic, assign) double eyeOutterUp0  ;
@property (nonatomic, assign) double eyeClose0 ;
@property (nonatomic, assign) double eyeBothIn0 ;
// mouth shape value
@property (nonatomic, assign) double mouthUp0 ;
@property (nonatomic, assign) double upperLipThick0  ;
@property (nonatomic, assign) double lowerLipThick0 ;
@property (nonatomic, assign) double lipCornerIn0 ;
// nose shape value
@property (nonatomic, assign) double noseUp0 ;
@property (nonatomic, assign) double nostrilIn0  ;
@property (nonatomic, assign) double noseTipUp0 ;

@end

@implementation FUFigureView

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setupFigureView  {
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomAction:)];
    [self addGestureRecognizer:pinchGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self addGestureRecognizer:tapGesture];
    tapGesture.delegate = self ;
    [pinchGesture requireGestureRecognizerToFail:tapGesture];
    
    [self loadData];
}

- (BOOL)figureViewIsChange {
    BOOL change = NO ;
    if (_headShrink != _headShrink0 ||
        _headBoneStretch != _headBoneStretch0 ||
        _cheekNarrow != _cheekNarrow0 ||
        _jawboneNarrow != _jawboneNarrow0 ||
        _jawLower != _jawLower0 ||
        _eyeUp != _eyeUp0 ||
        _eyeOutterUp != _eyeOutterUp0 ||
        _eyeClose != _eyeClose0 ||
        _eyeBothIn != _eyeBothIn0 ||
        _mouthUp != _mouthUp0 ||
        _upperLipThick != _upperLipThick0 ||
        _lowerLipThick != _lowerLipThick0 ||
        _lipCornerIn != _lipCornerIn0 ||
        _noseUp != _noseUp0 ||
        _nostrilIn != _nostrilIn0 ||
        _noseTipUp != _noseTipUp0 ) {

        change = YES ;
    }

    return change ;
}

- (void)tapClick:(UITapGestureRecognizer *)tap {
    
    [self.bottomCollection hiddenSelectedItem];
    
    if (!self.decorationView.hidden || !self.faceView.hidden || !self.glassesView.hidden) {
        if ([self.delegate respondsToSelector:@selector(figureViewDidHiddenAllTypeViews)]) {
            [self.delegate figureViewDidHiddenAllTypeViews];
        }
    }
    
    [self hiddenAllTopViewsWithAnimation:YES];
}

- (void)loadData {
    
    FUAvatar *currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
    isMale = currentAvatar.gender == FUGenderMale ;
    
    // bottom collection
    self.bottomCollection.isMale = isMale ;
    self.bottomCollection.mDelegate = self ;
    
    // middle decoration
    self.decorationCollection.mDelegate = self ;
    
    // middld decoration color
    self.decorationColorCollection.mDelegate = self ;
    self.decorationColorCollection.currentType = FUFigureDecorationTypeHair ;
    self.decorationColorCollection.hidden = [self.currentHair isEqualToString:@"hair-noitem"];
    
    // glasses collection
    self.glassesCollection.mDelegate = self ;
    if (currentAvatar.glasses && ![currentAvatar.glasses isEqualToString:@"glasses-noitem"]) {
        self.glassesCollection.glassesName = currentAvatar.glasses ;
        self.glassesColorView.hidden = NO ;
    }else {
        self.glassesColorView.hidden = YES ;
    }
    self.currentGlasses = currentAvatar.glasses ;
    self.glassesFrameColorCollection.mDelegate = self ;
    self.glassesColorCollection.mDelegate = self ;
    
    self.faceCollection.mDelegate = self ;
    if (currentAvatar.skinLevel != 0.0) {
        self.defaultSkinLevel = currentAvatar.skinLevel ;
        self.skinColor = currentAvatar.skinColor ;
        self.skinLevel = currentAvatar.skinLevel ;
        
        FUP2AColor *color = [FUManager shareInstance].skinColorArray[(int)self.skinLevel];
        self.faceCollection.currentSkinColor = color ;
    }else {
        
        self.defaultSkinLevel = [currentAvatar facePupGetColorIndexWithKey:@"skin_color_index"];
        self.skinColor = [FUManager shareInstance].skinColorArray[(int)_defaultSkinLevel] ;
        self.skinLevel = _defaultSkinLevel ;
        
        currentAvatar.skinLevel = self.skinLevel ;
        currentAvatar.skinColor = self.skinColor ;
        self.faceCollection.currentSkinColor = _skinColor ;
    }
    
    self.faceColorCollection.mDelegate = self ;
    

    // default params currentAvatar
    self.headShrink = [currentAvatar getFacepupModeParamWith:@"Head_shrink"];
    if (self.headShrink == 0) {
        self.headShrink = -fabs([currentAvatar getFacepupModeParamWith:@"Head_stretch"]);
    }
    self.headShrink0 = self.headShrink ;

    self.headBoneStretch = [currentAvatar getFacepupModeParamWith:@"Forehead_Wide"];
    if (self.headBoneStretch == 0) {
        self.headBoneStretch = -fabs([currentAvatar getFacepupModeParamWith:@"Forehead_Narrow"]);
    }
    self.headBoneStretch0 = self.headBoneStretch ;

    self.cheekNarrow = [currentAvatar getFacepupModeParamWith:@"cheek_narrow"];
    if (self.cheekNarrow == 0) {
        self.cheekNarrow = -fabs([currentAvatar getFacepupModeParamWith:@"Head_fat"]);
    }
    self.cheekNarrow0 = self.cheekNarrow ;

    self.jawboneNarrow = [currentAvatar getFacepupModeParamWith:@"jawbone_Narrow"];
    if (self.jawboneNarrow == 0) {
        self.jawboneNarrow = -fabs([currentAvatar getFacepupModeParamWith:@"jawbone_Wide"]);
    }
    self.jawboneNarrow0 = self.jawboneNarrow ;

    self.jawLower = [currentAvatar getFacepupModeParamWith:@"jaw_lower"];
    if (self.jawLower == 0) {
        self.jawLower = -fabs([currentAvatar getFacepupModeParamWith:@"jaw_up"]);
    }
    self.jawLower0 = self.jawLower;

    self.eyeUp = [currentAvatar getFacepupModeParamWith:@"Eye_up"];
    if (self.eyeUp == 0) {
        self.eyeUp = -fabs([currentAvatar getFacepupModeParamWith:@"Eye_down"]);
    }
    self.eyeUp0 = self.eyeUp ;

    self.eyeOutterUp = [currentAvatar getFacepupModeParamWith:@"Eye_outter_up"];
    if (self.eyeOutterUp == 0) {
        self.eyeOutterUp = -fabs([currentAvatar getFacepupModeParamWith:@"Eye_outter_down"]);
    }
    self.eyeOutterUp0 = self.eyeOutterUp ;

    self.eyeClose = [currentAvatar getFacepupModeParamWith:@"Eye_close"];
    if (self.eyeClose == 0) {
        self.eyeClose = -fabs([currentAvatar getFacepupModeParamWith:@"Eye_open"]);
    }
    self.eyeClose0 = self.eyeClose;

    self.eyeBothIn = [currentAvatar getFacepupModeParamWith:@"Eye_both_in"];
    if (self.eyeBothIn == 0) {
        self.eyeBothIn = -fabs([currentAvatar getFacepupModeParamWith:@"Eye_both_out"]);
    }
    self.eyeBothIn0 = self.eyeBothIn ;

    self.mouthUp = [currentAvatar getFacepupModeParamWith:@"mouth_Up"];
    if (self.mouthUp == 0) {
        self.mouthUp = -fabs([currentAvatar getFacepupModeParamWith:@"mouth_Down"]);
    }
    self.mouthUp0 = self.mouthUp ;

    self.upperLipThick = [currentAvatar getFacepupModeParamWith:@"upperLip_Thick"];
    if (self.upperLipThick == 0) {
        self.upperLipThick = -fabs([currentAvatar getFacepupModeParamWith:@"upperLip_Thin"]);
    }
    self.upperLipThick0 = self.upperLipThick ;

    self.lowerLipThick = [currentAvatar getFacepupModeParamWith:@"lowerLip_Thick"];
    if (self.lowerLipThick == 0) {
        self.lowerLipThick = -fabs([currentAvatar getFacepupModeParamWith:@"lowerLip_Thin"]);
    }
    self.lowerLipThick0 = self.lowerLipThick ;

    self.lipCornerIn = [currentAvatar getFacepupModeParamWith:@"lipCorner_In"];
    if (self.lipCornerIn == 0) {
        self.lipCornerIn = -fabs([currentAvatar getFacepupModeParamWith:@"lipCorner_Out"]);
    }
    self.lipCornerIn0 = self.lipCornerIn ;

    self.noseUp = [currentAvatar getFacepupModeParamWith:@"nose_UP"];
    if (self.noseUp == 0) {
        self.noseUp = -fabs([currentAvatar getFacepupModeParamWith:@"nose_Down"]);
    }
    self.noseUp0 = self.noseUp ;

    self.nostrilIn = [currentAvatar getFacepupModeParamWith:@"nostril_In"];
    if (self.nostrilIn == 0) {
        self.nostrilIn = -fabs([currentAvatar getFacepupModeParamWith:@"nostril_Out"]);
    }
    self.nostrilIn0 = self.nostrilIn ;

    self.noseTipUp = [currentAvatar getFacepupModeParamWith:@"noseTip_Up"];
    if (self.noseTipUp == 0) {
        self.noseTipUp = -fabs([currentAvatar getFacepupModeParamWith:@"noseTip_Down"]);
    }
    self.noseTipUp0 = self.noseTipUp ;
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

#pragma mark ---- bottom delegate

// 显示上半部
- (void)bottomCollectionDidSelectedIndex:(NSInteger)index show:(BOOL)show animation:(BOOL)animation {
    
    [self hiddenAllTopViewsWithAnimation:NO];
    
    UIView *subView = nil ;
    switch (index) {
        case 0:{     // 发型
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationTypeHair ;
            self.decorationColorCollection.hidden = [self.currentHair isEqualToString:@"hair-noitem"];
            self.decorationColorCollection.currentType = FUFigureDecorationTypeHair ;
        }
            break;
        case 1:{     // 肤色
            subView = self.faceView ;
            self.faceCollection.currentType = FUFigureFaceTypeSkinColor ;
            [self.faceCollection scrollCurrentToCenterWithAnimation:NO];
            self.faceSliderView.hidden = NO ;
            self.faceColorCollection.hidden = YES ;
            self.faceSlider.type = FUFigureSliderTypeOther ;
            self.faceSlider.value = self.skinLevel - (int)(self.skinLevel) ;
            self.middleLabelLeft.active = NO ;
            self.middleSliderLeft.active = YES ;
        }
            break;
        case 2:{     // 面部
            subView = self.faceView ;
            self.faceCollection.currentType = FUFigureFaceTypeFace ;
            [self.faceCollection scrollCurrentToCenterWithAnimation:NO];
            NSInteger selectedIndex = [[self.faceCollection.selectedDic objectForKey:@(FUFigureFaceTypeFace)] integerValue];
            if (selectedIndex == -1) {
                self.faceSliderView.hidden = YES ;
                self.faceColorCollection.hidden = YES ;
            }else {
                self.faceSlider.type = FUFigureSliderTypeShape ;
                
                FigureShapeSelectedType type = 10 + selectedIndex ;
                [self faceCollectionShapeParamChangedWithType:type];
            }
        }
            break;
        case 3:{     // 眼睛
            subView = self.faceView ;
            self.faceCollection.currentType = FUFigureFaceTypeEyes ;
            [self.faceCollection scrollCurrentToCenterWithAnimation:NO];
            NSInteger selectedIndex = [[self.faceCollection.selectedDic objectForKey:@(FUFigureFaceTypeEyes)] integerValue];
            if (selectedIndex == -1) {
                self.faceSliderView.hidden = YES ;
                self.faceColorCollection.hidden = YES ;
            }else {
                self.faceSlider.type = FUFigureSliderTypeShape ;
                
                FigureShapeSelectedType type = 20 + selectedIndex ;
                [self faceCollectionShapeParamChangedWithType:type];
            }
        }
            break;
        case 4:{     // 嘴唇
            subView = self.faceView ;
            self.faceCollection.currentType = FUFigureFaceTypeLips ;
            [self.faceCollection scrollCurrentToCenterWithAnimation:NO];
            NSInteger selectedIndex = [[self.faceCollection.selectedDic objectForKey:@(FUFigureFaceTypeLips)] integerValue];
            if (selectedIndex == -1) {
                self.faceSliderView.hidden = YES ;
                self.faceColorCollection.hidden = YES ;
            }else {
                self.faceSlider.type = FUFigureSliderTypeShape ;
                
                FigureShapeSelectedType type = 30 + selectedIndex ;
                [self faceCollectionShapeParamChangedWithType:type];
            }
        }
            break;
        case 5:{     // 鼻子
            subView = self.faceView ;
            self.faceCollection.currentType = FUFigureFaceTypeNose ;
            NSInteger selectedIndex = [[self.faceCollection.selectedDic objectForKey:@(FUFigureFaceTypeNose)] integerValue];
            if (selectedIndex == -1) {
                self.faceSliderView.hidden = YES ;
                self.faceColorCollection.hidden = YES ;
            }else {
                self.faceSlider.type = FUFigureSliderTypeShape ;
                
                FigureShapeSelectedType type = 40 + selectedIndex ;
                [self faceCollectionShapeParamChangedWithType:type];
            }
        }
            break;
        case 6:{     // 男胡子 && 女眉毛
            subView = self.decorationView ;
            self.decorationCollection.currentType = isMale ? FUFigureDecorationTypeBeard : FUFigureDecorationTypeEyeBrow ;
            self.decorationColorCollection.hidden = YES;
        }
            break;
        case 7:{     // 男眉毛 && 女睫毛
            subView = self.decorationView ;
            self.decorationCollection.currentType = isMale ? FUFigureDecorationTypeEyeBrow : FUFigureDecorationTypeEyeLash ;
            self.decorationColorCollection.hidden = YES;
        }
            break;
        case 8:{     // 眼镜
            subView = self.glassesView ;
        }
            break;
        case 9:{     // 帽子
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationTypeHat ;
            self.decorationColorCollection.hidden = [self.currentHat isEqualToString:@"hat-noitem"];
            self.decorationColorCollection.currentType = FUFigureDecorationTypeHat ;
        }
            break;
        case 10:{    // 衣服
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationTypeClothes ;
            self.decorationColorCollection.hidden = YES;
        }
            break;
            
        default:
            break;
    }
    
    subView.hidden = NO ;
    if (!show) {
        
        if ([self.delegate respondsToSelector:@selector(figureViewDidHiddenAllTypeViews)]) {
            [self.delegate figureViewDidHiddenAllTypeViews];
        }
        
        subView.transform = CGAffineTransformIdentity ;
        [UIView animateWithDuration:0.35 animations:^{
            subView.transform = CGAffineTransformMakeTranslation(0, subView.frame.size.height) ;
        }completion:^(BOOL finished) {
            subView.hidden = YES ;
        }];
    }else {
        if ([self.delegate respondsToSelector:@selector(figureViewDidSelectedTypeWithIndex:)]) {
            [self.delegate figureViewDidSelectedTypeWithIndex:index];
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
}

- (void)hiddenAllTopViewsWithAnimation:(BOOL)animation {
    
    if (animation) {
        [UIView animateWithDuration:0.35 animations:^{
            self.decorationView.transform = CGAffineTransformMakeTranslation(0, self.decorationView.frame.size.height) ;
            self.faceView.transform = CGAffineTransformMakeTranslation(0, self.faceView.frame.size.height) ;
            self.glassesView.transform = CGAffineTransformMakeTranslation(0, self.glassesView.frame.size.height) ;
        }completion:^(BOOL finished) {
            self.decorationView.hidden = YES ;
            self.faceView.hidden = YES ;
            self.glassesView.hidden = YES ;
        }];
    }else {
        self.decorationView.hidden = YES ;
        self.faceView.hidden = YES ;
        self.glassesView.hidden = YES ;
    }
}

#pragma mark ----- FUFigureDecorationCollectionDelegate

-(NSString *)currentHair {
    return self.decorationCollection.hair ;
}
-(NSString *)currentBeard {
    return self.decorationCollection.beard ;
}
-(NSString *)currentEyeBrow {
    return self.decorationCollection.eyeBrow ;
}
-(NSString *)currentEyeLash {
    return self.decorationCollection.eyeLash ;
}
-(NSString *)currentHat {
    return self.decorationCollection.hat ;
}
-(NSString *)currentCloth {
    return self.decorationCollection.clothes ;
}

-(FUP2AColor *)hairColor {
    return self.decorationColorCollection.hairColor ;
}
-(FUP2AColor *)irisColor {
    return self.faceColorCollection.irisColor ;
}
-(FUP2AColor *)lipColor {
    return self.faceColorCollection.lipsColor ;
}
- (FUP2AColor *)hatColor {
    return self.decorationColorCollection.hatColor ;
}
- (FUP2AColor *)glassesColor {
    return self.glassesColorCollection.glassesColor ;
}
-(FUP2AColor *)glassesFrameColor{
    return self.glassesFrameColorCollection.glassesFrameColor ;
}
//- (FUP2AColor *)beardColor {
//    return self.decorationColorCollection.beardColor ;
//}

- (BOOL)decorationCollectionDidSelectedType:(FUFigureDecorationType)type itemName:(NSString *)itemName {
    switch (type) {
        case FUFigureDecorationTypeHair:{
            
            NSArray *noArray = @[@"male_hair_t_2", @"male_hair_t_3", @"male_hair_t_4", @"female_hair_12", @"female_hair_t_1"];
            if (self.currentHat && ![self.currentHat isEqualToString:@"hat-noitem"] && [noArray containsObject:itemName]) {
                [SVProgressHUD dismiss];
                [SVProgressHUD showInfoWithStatus:@"此发型暂不支持帽子哦"];
                return NO;
            }
            
            self.decorationColorCollection.hidden = [itemName isEqualToString:@"hair-noitem"] ;
            self.decorationColorCollection.currentType = FUFigureDecorationTypeHair ;
            [self.decorationColorCollection scrollCurrentToCenterWithAnimation:NO];
            
            self.currentHair = itemName ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHair:)]) {
                [self.delegate figureViewDidChangeHair:itemName];
            }
        }
            break;
        case FUFigureDecorationTypeBeard:{
            
            self.decorationColorCollection.hidden = YES ;
            
            self.currentBeard = itemName ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeBeard:)]) {
                [self.delegate figureViewDidChangeBeard:itemName];
            }
        }
            break;
        case FUFigureDecorationTypeEyeBrow:{
            
            self.decorationColorCollection.hidden = YES ;
            
            self.currentEyeBrow = itemName ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeEyeBrow:)]) {
                [self.delegate figureViewDidChangeEyeBrow:itemName];
            }
        }
            break;
        case FUFigureDecorationTypeEyeLash:{
            
            self.decorationColorCollection.hidden = YES ;
            
            self.currentEyeLash = itemName ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeeyeLash:)]) {
                [self.delegate figureViewDidChangeeyeLash:itemName];
            }
        }
            break;
        case FUFigureDecorationTypeHat:{
            
            NSArray *noArray = @[@"male_hair_t_2", @"male_hair_t_3", @"male_hair_t_4", @"female_hair_12", @"female_hair_t_1"];
            if (self.currentHair && [noArray containsObject:self.currentHair] && ![itemName isEqualToString:@"hat-noitem"]) {
                [SVProgressHUD dismiss];
                [SVProgressHUD showInfoWithStatus:@"此发型暂不支持帽子哦"];
                return NO;
            }
            
            self.decorationColorCollection.hidden = [itemName isEqualToString:@"hat-noitem"] ;
            self.decorationColorCollection.currentType = FUFigureDecorationTypeHat ;
            [self.decorationColorCollection scrollCurrentToCenterWithAnimation:NO];
            
            self.currentHat = itemName ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHat:)]) {
                [self.delegate figureViewDidChangeHat:itemName];
            }
        }
            break;
        case FUFigureDecorationTypeClothes:{
            
            self.decorationColorCollection.hidden = YES ;
            
            self.currentCloth = itemName ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeClothes:)]) {
                [self.delegate figureViewDidChangeClothes:itemName];
            }
        }
            break;
        case FUFigureDecorationTypeIris:            // 瞳色 -- 此处用不到
        case FUFigureDecorationTypeLips:            // 唇色 -- 此处用不到
        case FUFigureDecorationTypeGlassesFrame:    // 镜框 -- 此处用不到
        case FUFigureDecorationTypeGlasses:         // 镜片 -- 此处用不到
            break;
    }
    return YES ;
}

#pragma mark ----- FUFigureDecorationColorCollectionDelegate

- (void)decorationColorCollectionDidChangeColor:(FUP2AColor *)color colorType:(FUFigureDecorationType)type {
    
    switch (type) {
        case FUFigureDecorationTypeHair:{   // 发色
            self.hairColor = color ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHairColor:)]) {
                [self.delegate figureViewDidChangeHairColor:color];
            }
        }
            break;
        case  FUFigureDecorationTypeHat:{   // 帽色
            self.hatColor = color ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHatColor:)]) {
                [self.delegate figureViewDidChangeHatColor:color];
            }
        }
            break ;
        case FUFigureDecorationTypeBeard:{  // 胡色
            self.beardColor = color;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHairColor:)]) {
                [self.delegate figureViewDidChangeBeardColor:color];
            }
        }
            break ;
        case FUFigureDecorationTypeIris:{  // 瞳色
            self.irisColor = color ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeIrisColor:)]) {
                [self.delegate figureViewDidChangeIrisColor:color];
            }
        }
            break ;
        case FUFigureDecorationTypeLips:{  // 唇色
            self.lipColor = color ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeLipsColor:)]) {
                [self.delegate figureViewDidChangeLipsColor:color];
            }
        }
            break ;
        case FUFigureDecorationTypeGlassesFrame:{   // 镜框
            self.glassesFrameColor = color ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlassesFrameColor:)]) {
                [self.delegate figureViewDidChangeGlassesFrameColor:color];
            }
        }
            break ;
        case FUFigureDecorationTypeGlasses: {       // 镜片
            self.glassesColor = color ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlassesColor:)]) {
                [self.delegate figureViewDidChangeGlassesColor:color];
            }
        }
            break ;
            
        default:
            break;
    }
}

#pragma mark ----- FUFigureFaceCollectionDelegate

// 重置
- (IBAction)resetParamsAction:(UIButton *)sender {
    
    NSString *message = nil ;
    switch (self.faceCollection.currentType) {
        case FUFigureFaceTypeSkinColor:{
            if (_defaultSkinLevel == self.skinLevel) {
                return ;
            }
            message = @"确认将肤色恢复默认吗？" ;
        }
            break;
        case FUFigureFaceTypeFace:{
            if (_headShrink == _headShrink0 &&
                _headBoneStretch == _headBoneStretch0 &&
                _cheekNarrow == _cheekNarrow0 &&
                _jawboneNarrow == _jawboneNarrow0 &&
                _jawLower == _jawLower0 ) {
                return ;
            }
            message = @"确认将面部参数恢复默认吗？" ;
        }
            break ;
        case FUFigureFaceTypeEyes:{
            if (_eyeUp == _eyeUp0 &&
                _eyeOutterUp == _eyeOutterUp0 &&
                _eyeClose == _eyeClose0 &&
                _eyeBothIn == _eyeBothIn0 ) {
                return ;
            }
            message = @"确认将眼睛参数恢复默认吗？" ;
        }
            break ;
        case FUFigureFaceTypeLips:{
            if (_mouthUp == _mouthUp0 &&
                _upperLipThick == _upperLipThick0 &&
                _lowerLipThick == _lowerLipThick0 &&
                _lipCornerIn == _lipCornerIn0) {
                return ;
            }
            message = @"确认将嘴唇参数恢复默认吗？" ;
        }
            break ;
        case FUFigureFaceTypeNose:{
            if (_noseUp == _noseUp0 &&
                _nostrilIn == _nostrilIn0 &&
                _noseTipUp == _noseTipUp0) {
                return ;
            }
            message = @"确认将鼻子参数恢复默认吗？" ;
        }
            break ;
    }
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [cancle setValue:[UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1.0] forKey:@"titleTextColor"];
    __weak typeof(self)weakSelf = self ;
    UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf certainResetParamsWithType:weakSelf.faceCollection.currentType];
    }];
    [certain setValue:[UIColor colorWithHexColorString:@"4C96FF"] forKey:@"titleTextColor"];
    [alertC addAction:cancle];
    [alertC addAction:certain];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:^{
    }];
}

- (void)certainResetParamsWithType:(FUFigureFaceType)type {
    switch (type) {
        case FUFigureFaceTypeSkinColor:{            // 肤色重置
            self.skinLevel = _defaultSkinLevel ;
            self.skinColor = [FUManager shareInstance].skinColorArray[(int)_defaultSkinLevel] ;
            self.faceSlider.type = FUFigureSliderTypeOther ;
            self.faceSlider.value = _defaultSkinLevel - (int)_defaultSkinLevel ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:)]) {
                [self.delegate figureViewDidChangeSkinColor:self.skinColor];
            }
            [self.faceCollection.selectedDic setObject:@(_defaultSkinLevel) forKey:@(type)];
            [self.faceCollection reloadData];
            [self.faceCollection scrollCurrentToCenterWithAnimation:YES];
        }
            break;
        case FUFigureFaceTypeFace:{             // 面部
            self.faceSliderView.hidden = YES ;
            self.faceColorCollection.hidden = YES ;
            [self.faceCollection.selectedDic setObject:@(-1) forKey:@(FUFigureFaceTypeFace)];
            [self.faceCollection reloadData];
            
            self.headShrink = _headShrink0 ;
            self.headBoneStretch = _headBoneStretch0 ;
            self.cheekNarrow = _cheekNarrow0 ;
            self.jawboneNarrow = _jawboneNarrow0 ;
            self.jawLower = _jawLower0 ;
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Head_shrink"        level: fabs(self.headShrink > 0 ? self.headShrink : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Head_stretch"       level: fabs(self.headShrink > 0 ? 0 : self.headShrink )];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"HeadBone_stretch"   level: fabs(self.headShrink > 0 ? 0 : self.headShrink)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"HeadBone_shrink"    level: fabs(self.headShrink > 0 ? self.headShrink : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Head_fat"           level: fabs(self.cheekNarrow > 0 ? 0 : self.cheekNarrow)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"cheek_narrow"       level: fabs(self.cheekNarrow > 0 ? self.cheekNarrow : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"jawbone_Narrow"     level: fabs(self.jawboneNarrow > 0 ? self.jawboneNarrow : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"jawbone_Wide"       level: fabs(self.jawboneNarrow > 0 ? 0 : self.jawboneNarrow )];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"jaw_lower"          level: fabs(self.jawLower > 0 ? self.jawLower : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"jaw_up"             level: fabs(self.jawLower > 0 ? 0 : self.jawLower)];
        }
            break ;
        case FUFigureFaceTypeEyes:{             // 眼镜
            self.faceSliderView.hidden = YES ;
            self.faceColorCollection.hidden = YES ;
            [self.faceCollection.selectedDic setObject:@(-1) forKey:@(FUFigureFaceTypeEyes)];
            [self.faceCollection reloadData];
            
            self.eyeUp = _eyeUp0 ;
            self.eyeOutterUp = _eyeOutterUp0 ;
            self.eyeClose = _eyeClose0 ;
            self.eyeBothIn = _eyeBothIn0 ;
            
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_up"             level: fabs(self.eyeUp > 0 ? self.eyeUp : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_down"           level: fabs(self.eyeUp > 0 ? 0 : self.eyeUp)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_outter_up"      level: fabs(self.eyeOutterUp > 0 ? self.eyeOutterUp : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_outter_down"    level: fabs(self.eyeOutterUp > 0 ? 0 : self.eyeOutterUp)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_close"          level: fabs(self.eyeClose > 0 ? self.eyeClose : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_open"           level: fabs(self.eyeClose > 0 ? 0 : self.eyeClose )];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_both_in"        level: fabs(self.eyeBothIn > 0 ? self.eyeBothIn : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_both_out"       level: fabs(self.eyeBothIn > 0 ? 0 : self.eyeBothIn)];
        }
            break ;
        case FUFigureFaceTypeLips:{             // 嘴唇
            self.faceSliderView.hidden = YES ;
            self.faceColorCollection.hidden = YES ;
            [self.faceCollection.selectedDic setObject:@(-1) forKey:@(FUFigureFaceTypeLips)];
            [self.faceCollection reloadData];
            
            self.mouthUp = _mouthUp0 ;
            self.upperLipThick = _upperLipThick0 ;
            self.lowerLipThick = _lowerLipThick0 ;
            self.lipCornerIn = _lipCornerIn0 ;
            
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"mouth_Up"           level: fabs(self.mouthUp > 0 ? self.mouthUp : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"mouth_Down"         level: fabs(self.mouthUp > 0 ? 0 : self.mouthUp)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"upperLip_Thick"     level: fabs(self.upperLipThick > 0 ? self.upperLipThick : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"upperLip_Thin"      level: fabs(self.upperLipThick > 0 ? 0 : self.upperLipThick )];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"lowerLip_Thick"     level: fabs(self.lowerLipThick > 0 ? self.lowerLipThick : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"lowerLip_Thin"      level: fabs(self.lowerLipThick > 0 ? 0 : self.lowerLipThick)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"lipCorner_In"       level: fabs(self.lipCornerIn > 0 ? self.lipCornerIn : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"lipCorner_Out"      level: fabs(self.lipCornerIn > 0 ? 0 : self.lipCornerIn)];
        }
            break ;
        case FUFigureFaceTypeNose:{             // 鼻子
            self.faceSliderView.hidden = YES ;
            self.faceColorCollection.hidden = YES ;
            [self.faceCollection.selectedDic setObject:@(-1) forKey:@(FUFigureFaceTypeNose)];
            [self.faceCollection reloadData];
            
            self.noseUp = _noseUp0 ;
            self.nostrilIn = _nostrilIn0 ;
            self.noseTipUp = _noseTipUp0 ;
            
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"nose_UP"            level: fabs(self.noseUp > 0 ? self.noseUp : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"nose_Down"          level: fabs(self.noseUp > 0 ? 0 : self.noseUp)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"nostril_In"         level: fabs(self.nostrilIn > 0 ? self.nostrilIn : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"nostril_Out"        level: fabs(self.nostrilIn > 0 ? 0 : self.nostrilIn)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"noseTip_Up"         level: fabs(self.noseTipUp > 0 ? self.noseTipUp : 0)];
            [self.delegate figureViewShapeParamsDidChangedWithKey:@"noseTip_Down"       level: fabs(self.noseTipUp > 0 ? 0 : self.noseTipUp)];
        }
            break ;
    }
}



- (IBAction)faceSliderValueChange:(FUFigureSlider *)sender {
    
    NSString *currentKey , *zeroKey ;
    double level = sender.value ;
    
    switch (self.faceCollection.currentType) {
        case FUFigureFaceTypeSkinColor:{
            
            FUP2AColor *color = self.faceCollection.currentSkinColor ;
            NSInteger index = [[FUManager shareInstance].skinColorArray indexOfObject: color];
            FUP2AColor *nextColor = [[FUManager shareInstance].skinColorArray objectAtIndex:index + 1];
            float scale = sender.value ;
            self.skinLevel = index + scale ;
            FUP2AColor *c = [FUP2AColor colorWithR:color.r + scale * (nextColor.r - color.r) g:color.g + scale * (nextColor.g - color.g) b:color.b + scale * (nextColor.b - color.b)];
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:)]) {
                [self.delegate figureViewDidChangeSkinColor:c];
            }
            return ;
        }
            break;
        case FUFigureFaceTypeFace:
        case FUFigureFaceTypeEyes:
        case FUFigureFaceTypeLips:
        case FUFigureFaceTypeNose:{
            
            switch (self.faceCollection.selectedType) {
                    // face
                case FigureShapeSelectedTypeHeadShrink:{ // 脸型长度
                    self.headShrink = level ;
                    currentKey = level > 0 ? @"Head_shrink" : @"Head_stretch" ;
                    zeroKey    = level > 0 ? @"Head_stretch" : @"Head_shrink" ;
                }
                    break;
                case FigureShapeSelectedTypeHeadBoneStretch:{ // 额头宽窄
                    self.headBoneStretch = level ;
                    currentKey = level > 0 ? @"Forehead_Wide" : @"Forehead_Narrow" ;
                    zeroKey    = level > 0 ? @"Forehead_Narrow" : @"Forehead_Wide" ;
                }
                    break;
                case FigureShapeSelectedTypeCheekNarrow:{ // 脸颊宽度
                    self.cheekNarrow = level ;
                    currentKey = level > 0 ? @"cheek_narrow" : @"Head_fat" ;
                    zeroKey    = level > 0 ? @"Head_fat" : @"cheek_narrow" ;
                }
                    break;
                case FigureShapeSelectedTypeJawboneNarrow:{ // 下颚宽度
                    self.jawboneNarrow = level ;
                    currentKey = level > 0 ? @"jawbone_Wide" : @"jawbone_Narrow" ;
                    zeroKey    = level > 0 ? @"jawbone_Narrow" : @"jawbone_Wide" ;
                }
                    break;
                case FigureShapeSelectedTypeJawLower:{ // 下巴高低
                    self.jawLower = level ;
                    currentKey = level > 0 ? @"jaw_lower" : @"jaw_up" ;
                    zeroKey    = level > 0 ? @"jaw_up" : @"jaw_lower" ;
                }
                    break;
                    
                    // eye
                case FigureShapeSelectedTypeEyeUp:{ // 眼镜位置
                    self.eyeUp = level ;
                    currentKey = level > 0 ? @"Eye_up" : @"Eye_down" ;
                    zeroKey    = level > 0 ? @"Eye_down" : @"Eye_up" ;
                }
                    break ;
                case FigureShapeSelectedTypeEyeOutterUp:{ // 眼角高低
                    self.eyeOutterUp = level ;
                    currentKey = level > 0 ? @"Eye_outter_up" : @"Eye_outter_down" ;
                    zeroKey    = level > 0 ? @"Eye_outter_down" : @"Eye_outter_up" ;
                }
                    break ;
                case FigureShapeSelectedTypeEyeClose:{ // 眼睛高低
                    self.eyeClose = level ;
                    currentKey = level > 0 ? @"Eye_close" : @"Eye_open" ;
                    zeroKey    = level > 0 ? @"Eye_open" : @"Eye_close" ;
                }
                    break ;
                case FigureShapeSelectedTypeEyeBothIn:{ // 眼睛宽窄
                    self.eyeBothIn = level ;
                    currentKey = level > 0 ? @"Eye_both_in" : @"Eye_both_out" ;
                    zeroKey    = level > 0 ? @"Eye_both_out" : @"Eye_both_in" ;
                }
                    break ;
                    
                    // nose
                case FigureShapeSelectedTypeNoseUp:{ // 👃位置
                    self.noseUp = level ;
                    currentKey = level > 0 ? @"nose_UP" : @"nose_Down" ;
                    zeroKey    = level > 0 ? @"nose_Down" : @"nose_UP" ;
                }
                    break ;
                case FigureShapeSelectedTypeNostrilIn:{ // 👃宽窄
                    self.nostrilIn = level ;
                    currentKey = level > 0 ? @"nostril_In" : @"nostril_Out" ;
                    zeroKey    = level > 0 ? @"nostril_Out" : @"nostril_In" ;
                }
                    break ;
                case FigureShapeSelectedTypeNoseTipUp:{ // 👃高低
                    self.noseTipUp = level ;
                    currentKey = level > 0 ? @"noseTip_Up" : @"noseTip_Down" ;
                    zeroKey    = level > 0 ? @"noseTip_Down" : @"noseTip_Up" ;
                }
                    break ;
                    
                    // mouth
                case FigureShapeSelectedTypeMouthUp:{  // 👄位置
                    self.mouthUp = level ;
                    currentKey = level > 0 ? @"mouth_Up" : @"mouth_Down" ;
                    zeroKey    = level > 0 ? @"mouth_Down" : @"mouth_Up" ;
                }
                    break ;
                case FigureShapeSelectedTypeUpperLipThick:{ // 上👄厚度
                    self.upperLipThick = level ;
                    currentKey = level > 0 ? @"upperLip_Thick" : @"upperLip_Thin" ;
                    zeroKey    = level > 0 ? @"upperLip_Thin" : @"upperLip_Thick" ;
                }
                    break ;
                case FigureShapeSelectedTypeLowerLipThick:{ // 下👄厚度
                    self.lowerLipThick = level ;
                    currentKey = level > 0 ? @"lowerLip_Thick" : @"lowerLip_Thin" ;
                    zeroKey    = level > 0 ? @"lowerLip_Thin" : @"lowerLip_Thick" ;
                }
                    break ;
                case FigureShapeSelectedTypeLipCornerIn:{ // 👄宽度
                    self.lipCornerIn = level ;
                    currentKey = level > 0 ? @"lipCorner_In" : @"lipCorner_Out" ;
                    zeroKey    = level > 0 ? @"lipCorner_Out" : @"lipCorner_In" ;
                }
                    break ;
                case FigureShapeSelectedTypeEyesColor:
                case FigureShapeSelectedTypeLipsColor: {
                    currentKey = @"" ;
                    zeroKey    = @"" ;
                    break;
                }
            }
        }
            break ;
    }
    
    if ([self.delegate respondsToSelector:@selector(figureViewShapeParamsDidChangedWithKey:level:)]) {
        [self.delegate figureViewShapeParamsDidChangedWithKey:zeroKey level:0.0];
        [self.delegate figureViewShapeParamsDidChangedWithKey:currentKey level:fabs(level)];
    }
}

- (void)faceCollectionDidSelectedSkinIndex:(NSInteger)skinIndex {
    if (skinIndex < [FUManager shareInstance].skinColorArray.count) {
        self.skinLevel = skinIndex ;
        self.faceSlider.value = 0.0 ;
        self.skinColor = [FUManager shareInstance].skinColorArray[skinIndex];
        if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:)]) {
            [self.delegate figureViewDidChangeSkinColor:self.skinColor];
        }
    }
}

- (void)faceCollectionShapeParamChangedWithType:(FigureShapeSelectedType)type {
    NSString *message ;
    double level = 0.0 ;
    
    switch (type) {
        case FigureShapeSelectedTypeEyesColor: {    // 瞳色
            self.faceSliderView.hidden = YES ;
            self.faceColorCollection.hidden = NO ;
            self.faceColorCollection.currentType = FUFigureDecorationTypeIris ;
            [self.faceColorCollection scrollCurrentToCenterWithAnimation:NO];
            return ;
        }
            break;
        case FigureShapeSelectedTypeLipsColor: {    // 唇色
            self.faceSliderView.hidden = YES ;
            self.faceColorCollection.hidden = NO ;
            self.faceColorCollection.currentType = FUFigureDecorationTypeLips ;
            [self.faceColorCollection scrollCurrentToCenterWithAnimation:NO];
            return ;
        }
            break;
            // face
        case FigureShapeSelectedTypeHeadShrink:{ // 脸型长度
            message = @"脸型长度" ;
            level = self.headShrink ;
        }
            break;
        case FigureShapeSelectedTypeHeadBoneStretch:{ // 额头宽窄
            message = @"额头宽窄" ;
            level = self.headBoneStretch ;
        }
            break;
        case FigureShapeSelectedTypeCheekNarrow:{ // 脸颊宽度
            message = @"脸颊宽度" ;
            level = self.cheekNarrow ;
        }
            break;
        case FigureShapeSelectedTypeJawboneNarrow:{ // 下颚宽度
            message = @"下颚宽度" ;
            level = self.jawboneNarrow ;
        }
            break;
        case FigureShapeSelectedTypeJawLower:{ // 下巴高低
            message = @"下巴高低" ;
            level = self.jawLower ;
        }
            break;
            
            // eye
        case FigureShapeSelectedTypeEyeUp:{ // 眼镜位置
            message = @"眼睛位置" ;
            level = self.eyeUp ;
        }
            break ;
        case FigureShapeSelectedTypeEyeOutterUp:{ // 眼角上下
            message = @"眼角高低" ;
            level = self.eyeOutterUp ;
        }
            break ;
        case FigureShapeSelectedTypeEyeClose:{ // 眼睛高低
            message = @"眼睛高低" ;
            level = self.eyeClose ;
        }
            break ;
        case FigureShapeSelectedTypeEyeBothIn:{ // 眼睛宽窄
            message = @"眼睛宽窄" ;
            level = self.eyeBothIn ;
        }
            break ;
            
            // nose
        case FigureShapeSelectedTypeNoseUp:{ // 👃位置
            message = @"鼻子位置" ;
            level = self.noseUp ;
        }
            break ;
        case FigureShapeSelectedTypeNostrilIn:{ // 👃宽窄
            message = @"鼻翼宽窄" ;
            level = self.nostrilIn ;
        }
            break ;
        case FigureShapeSelectedTypeNoseTipUp:{ // 👃高低
            message = @"鼻头高低" ;
            level = self.noseTipUp ;
        }
            break ;
            
            // mouth
        case FigureShapeSelectedTypeMouthUp:{  // 👄位置
            message = @"嘴部位置" ;
            level = self.mouthUp ;
        }
            break ;
        case FigureShapeSelectedTypeUpperLipThick:{ // 上👄厚度
            message = @"上唇厚度" ;
            level = self.upperLipThick ;
        }
            break ;
        case FigureShapeSelectedTypeLowerLipThick:{ // 下👄厚度
            message = @"下唇厚度" ;
            level = self.lowerLipThick ;
        }
            break ;
        case FigureShapeSelectedTypeLipCornerIn:{ // 👄宽度
            message = @"嘴唇宽度" ;
            level = self.lipCornerIn ;
        }
            break ;
    }
    
    self.faceCollection.selectedType = type ;
    self.middleLabelLeft.active = YES ;
    self.middleSliderLeft.active = NO ;
    self.faceSliderView.hidden = NO ;
    self.faceColorCollection.hidden = YES ;
    self.sliderLabel.text = message ;
    self.faceSlider.value = level ;
    self.faceSlider.type = FUFigureSliderTypeShape ;
}

#pragma mark -----  FUFigureDecorationHorizCollectionDelegate
-(void)didChangeGlasses:(NSString *)glassesName {
    self.currentGlasses = glassesName ;
    if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlasses:)]) {
        [self.delegate figureViewDidChangeGlasses:glassesName];
    }
    
    self.glassesColorView.hidden = [glassesName isEqualToString:@"glasses-noitem"];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    for (UIView *view in self.subviews) {
        if ([touch.view isDescendantOfView:view]) {
            return NO ;
        }
    }
    return YES ;
}

@end
