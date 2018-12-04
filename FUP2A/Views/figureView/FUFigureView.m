//
//  FUFigureView.m
//  EditView
//
//  Created by L on 2018/11/2.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUFigureView.h"
#import "UIColor+FU.h"
#import "FUFigureColor.h"
#import "FUFigureSlider.h"
#import "FUFigureHairCollection.h"
#import "FUFigureGlassCollection.h"
#import "FUFigureGlassTypeCollection.h"
#import "FUManager.h"
#import "FUFigureShapeCollection.h"
#import <SVProgressHUD.h>

@interface FUFigureView ()
<
UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
FUFigureHairColorCollectionDelegate,
FUFigureHairMainCollectionDelegate,
FUFigureGlassCollectionDelegate,
FUFigureGlassTypeCollectionDelegate,
FUFigureShapeCollectionDelegate
>
{
    BOOL isMaleType ;
    
    NSInteger bottomSelectedIndex ;
    FUFigureGlassesCollectionType currentGlassColorType ;
}

@property (nonatomic, strong) NSMutableDictionary *selectedInfo ;

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (nonatomic, strong) NSArray *bottomDataArray ;
@property (weak, nonatomic) IBOutlet UICollectionView *bottomCollection;
@property (nonatomic, strong) UIView *bottomLine ;

@property (nonatomic, strong) NSArray *shapeArray ;
@property (weak, nonatomic) IBOutlet UICollectionView *middleCollection;

@property (weak, nonatomic) IBOutlet UIView *middleSliderView;
@property (weak, nonatomic) IBOutlet UILabel *middleSliderLable;
@property (weak, nonatomic) IBOutlet FUFigureSlider *middleSlider;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *middleSliderLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *middleSliderRight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *middleSliderLeading;

@property (weak, nonatomic) IBOutlet UIView *hairView;
@property (weak, nonatomic) IBOutlet FUFigureHairColorCollection *hairColorCollection;
@property (weak, nonatomic) IBOutlet FUFigureHairMainCollection *hairCollection;

@property (weak, nonatomic) IBOutlet UIView *glassesView;
@property (weak, nonatomic) IBOutlet FUFigureGlassCollection *glassesFrameCollection;
@property (weak, nonatomic) IBOutlet FUFigureGlassCollection *glassesCollection;
@property (weak, nonatomic) IBOutlet UIView *glassesSliderView;
@property (weak, nonatomic) IBOutlet FUFigureSlider *glassesSlider;
@property (weak, nonatomic) IBOutlet UILabel *currentGlassLabel;
@property (weak, nonatomic) IBOutlet FUFigureGlassTypeCollection *glassesTypeCollection;
@property (weak, nonatomic) IBOutlet UIView *glassColorView;

@property (weak, nonatomic) IBOutlet UIView *bearView;
@property (weak, nonatomic) IBOutlet FUFigureGlassCollection *beardColorCollection;
@property (weak, nonatomic) IBOutlet FUFigureHairMainCollection *beardCollection;

@property (weak, nonatomic) IBOutlet FUFigureHairMainCollection *clothCollection;

@property (weak, nonatomic) IBOutlet UIView *hatView;
@property (weak, nonatomic) IBOutlet FUFigureGlassCollection *hatColorCollection;
@property (weak, nonatomic) IBOutlet FUFigureHairMainCollection *hatCollection;

// tmp
@property (weak, nonatomic) IBOutlet FUFigureShapeCollection *shapeCollection;

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
    [self loadData];
    [self loadSubViews];
}

- (void)loadData {
    
    FUAvatar *currentAvatar = [FUManager shareInstance].currentAvatar;
    isMaleType = currentAvatar.isMale ;
    
    // bottom data
    bottomSelectedIndex = 0 ;
    self.bottomDataArray = isMaleType ? @[@"美型", @"肤色", @"唇色", @"瞳色", @"发型", @"胡子", @"眼镜", @"帽子", @"衣服"] : @[@"美型", @"肤色", @"唇色", @"瞳色", @"发型", @"眼镜", @"帽子", @"衣服"];
    
    // selected info
    self.selectedInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    [self.selectedInfo setObject:@(-1) forKey:@"shapeIndex"];   // 美型选择
    
    self.shapeArray = @[@"瘦脸", @"大眼", @"嘴型", @"鼻子"];
    
    self.lipColorArray = [FUManager shareInstance].lipColorArray;
    self.irisColorArray = [FUManager shareInstance].irisColorArray;
    self.hairColorArray = [FUManager shareInstance].hairColorArray;
    self.beardColorArray = [FUManager shareInstance].beardColorArray;
    self.glassFrameArray = [FUManager shareInstance].glassFrameArray;
    self.glassColorArray = [FUManager shareInstance].glassColorArray;
    self.skinColorArray = [FUManager shareInstance].skinColorArray;
    
    // default params
    self.headShrink = [[FUManager shareInstance] getFacepopParamWith:@"Head_shrink"];
    if (self.headShrink == 0) {
        self.headShrink = -fabs([[FUManager shareInstance] getFacepopParamWith:@"Head_stretch"]);
    }
    self.headShrink0 = self.headShrink ;
    
    self.headBoneStretch = [[FUManager shareInstance] getFacepopParamWith:@"HeadBone_stretch"];
    if (self.headBoneStretch == 0) {
        self.headBoneStretch = -fabs([[FUManager shareInstance] getFacepopParamWith:@"Head_shrink"]);
    }
    self.headBoneStretch0 = self.headBoneStretch ;
    
    self.cheekNarrow = [[FUManager shareInstance] getFacepopParamWith:@"cheek_narrow"];
    if (self.cheekNarrow == 0) {
        self.cheekNarrow = -fabs([[FUManager shareInstance] getFacepopParamWith:@"Head_fat"]);
    }
    self.cheekNarrow0 = self.cheekNarrow ;
    
    self.jawboneNarrow = [[FUManager shareInstance] getFacepopParamWith:@"jawbone_Narrow"];
    if (self.jawboneNarrow == 0) {
        self.jawboneNarrow = -fabs([[FUManager shareInstance] getFacepopParamWith:@"jawbone_Wide"]);
    }
    self.jawboneNarrow0 = self.jawboneNarrow ;
    
    self.jawLower = [[FUManager shareInstance] getFacepopParamWith:@"jaw_lower"];
    if (self.jawLower == 0) {
        self.jawLower = -fabs([[FUManager shareInstance] getFacepopParamWith:@"jaw_up"]);
    }
    self.jawLower0 = self.jawLower;
    
    self.eyeUp = [[FUManager shareInstance] getFacepopParamWith:@"Eye_up"];
    if (self.eyeUp == 0) {
        self.eyeUp = -fabs([[FUManager shareInstance] getFacepopParamWith:@"Eye_down"]);
    }
    self.eyeUp0 = self.eyeUp ;
    
    self.eyeOutterUp = [[FUManager shareInstance] getFacepopParamWith:@"Eye_outter_up"];
    if (self.eyeOutterUp == 0) {
        self.eyeOutterUp = -fabs([[FUManager shareInstance] getFacepopParamWith:@"Eye_outter_down"]);
    }
    self.eyeOutterUp0 = self.eyeOutterUp ;
    
    self.eyeClose = [[FUManager shareInstance] getFacepopParamWith:@"Eye_close"];
    if (self.eyeClose == 0) {
        self.eyeClose = -fabs([[FUManager shareInstance] getFacepopParamWith:@"Eye_open"]);
    }
    self.eyeClose0 = self.eyeClose;
    
    self.eyeBothIn = [[FUManager shareInstance] getFacepopParamWith:@"Eye_both_in"];
    if (self.eyeBothIn == 0) {
        self.eyeBothIn = -fabs([[FUManager shareInstance] getFacepopParamWith:@"Eye_both_out"]);
    }
    self.eyeBothIn0 = self.eyeBothIn ;
    
    self.mouthUp = [[FUManager shareInstance] getFacepopParamWith:@"mouth_Up"];
    if (self.mouthUp == 0) {
        self.mouthUp = -fabs([[FUManager shareInstance] getFacepopParamWith:@"mouth_Down"]);
    }
    self.mouthUp0 = self.mouthUp ;
    
    self.upperLipThick = [[FUManager shareInstance] getFacepopParamWith:@"upperLip_Thick"];
    if (self.upperLipThick == 0) {
        self.upperLipThick = -fabs([[FUManager shareInstance] getFacepopParamWith:@"upperLip_Thin"]);
    }
    self.upperLipThick0 = self.upperLipThick ;
    
    self.lowerLipThick = [[FUManager shareInstance] getFacepopParamWith:@"lowerLip_Thick"];
    if (self.lowerLipThick == 0) {
        self.lowerLipThick = -fabs([[FUManager shareInstance] getFacepopParamWith:@"lowerLip_Thin"]);
    }
    self.lowerLipThick0 = self.lowerLipThick ;
    
    self.lipCornerIn = [[FUManager shareInstance] getFacepopParamWith:@"lipCorner_In"];
    if (self.lipCornerIn == 0) {
        self.lipCornerIn = -fabs([[FUManager shareInstance] getFacepopParamWith:@"lipCorner_Out"]);
    }
    self.lipCornerIn0 = self.lipCornerIn ;
    
    self.noseUp = [[FUManager shareInstance] getFacepopParamWith:@"nose_UP"];
    if (self.noseUp == 0) {
        self.noseUp = -fabs([[FUManager shareInstance] getFacepopParamWith:@"nose_Down"]);
    }
    self.noseUp0 = self.noseUp ;
    
    self.nostrilIn = [[FUManager shareInstance] getFacepopParamWith:@"nostril_In"];
    if (self.nostrilIn == 0) {
        self.nostrilIn = -fabs([[FUManager shareInstance] getFacepopParamWith:@"nostril_Out"]);
    }
    self.nostrilIn0 = self.nostrilIn ;
    
    self.noseTipUp = [[FUManager shareInstance] getFacepopParamWith:@"noseTip_Up"];
    if (self.noseTipUp == 0) {
        self.noseTipUp = -fabs([[FUManager shareInstance] getFacepopParamWith:@"noseTip_Down"]);
    }
    self.noseTipUp0 = self.noseTipUp ;
    
    
    // default value
    if (currentAvatar.skinColor) {
        _defaultSkinLevel = (int)currentAvatar.skinColor.index - 1;
        self.skinColor = currentAvatar.skinColor ;
    }else {
        _defaultSkinLevel = [[FUManager shareInstance] getSkinColorIndex];
        self.skinColor = self.skinColorArray[_defaultSkinLevel] ;
    }
    self.skinLevel = _defaultSkinLevel ;
    
    if (currentAvatar.lipColor) {
        _defaultLipLevel = (int)currentAvatar.lipColor.index - 1;
        self.lipColor = currentAvatar.lipColor ;
    }else {
        _defaultLipLevel = [[FUManager shareInstance] getLipColorIndex] ;
        self.lipColor = self.lipColorArray[_defaultLipLevel] ;
    }
    self.lipLevel = _defaultLipLevel ;
    
    if (currentAvatar.irisColor) {
        _defaultIrisLevel = (int)currentAvatar.irisColor.index - 1 ;
        self.irisColor = currentAvatar.irisColor ;
    }else {
        _defaultIrisLevel = [[FUManager shareInstance] getIrisColorIndex] ;
        self.irisColor = self.irisColorArray[_defaultIrisLevel];
    }
    self.irisLevel = _defaultIrisLevel ;
    
    [self.selectedInfo setObject:@(_defaultSkinLevel + 1) forKey:@"skinIndex"];   // 肤色选择
    [self.selectedInfo setObject:@(_defaultLipLevel) forKey:@"lipIndex"];   // 唇色选择
    [self.selectedInfo setObject:@(_defaultIrisLevel) forKey:@"irisIndex"];   // 瞳色选择
    
    // hair views
    self.hairCollection.hairArray = isMaleType ? [FUManager shareInstance].maleHairs : [FUManager shareInstance].femaleHairs ;
    self.hairCollection.currentHair = currentAvatar.defaultHair ;
    self.currentHair = currentAvatar.defaultHair ;
    
    // hair color view
    self.hairColorCollection.hairColorArray = self.hairColorArray ;
    NSInteger hairColorIndex = currentAvatar.hairColor ? currentAvatar.hairColor.index - 1 : 0 ;
    if (hairColorIndex == -1) {
        hairColorIndex = 0 ;
    }
    self.hairColorCollection.colorIndex = hairColorIndex ;
    self.hairColor = self.hairColorArray[hairColorIndex];
    self.hairColorCollection.hidden = self.currentHair == nil || [self.currentHair isEqualToString:@"hair-noitem"];
    
    // glasses color / glasses frame color collection
    self.glassesCollection.glassesArray = self.glassColorArray ;
    NSInteger glassesColorIndex = currentAvatar.glassColor ? currentAvatar.glassColor.index - 1 : 0 ;
    self.glassesCollection.glassesColorIndex = glassesColorIndex;
    self.glassesColor = self.glassColorArray[glassesColorIndex];
    
    
    self.glassesFrameCollection.glassesArray = self.glassFrameArray ;
    NSInteger glassesFrameColorIndex = currentAvatar.glassFrameColor ? currentAvatar.glassFrameColor.index - 1 : 0 ;
    self.glassesFrameCollection.glassesColorIndex = glassesFrameColorIndex ;
    self.glassesFrameColor = self.glassFrameArray[glassesFrameColorIndex];
    
    // glasses collection
    NSArray *glassesArray = isMaleType ? [FUManager shareInstance].maleGlasses : [FUManager shareInstance].femaleGlasses;
    NSInteger glassesIndex = 0 ;
    if (currentAvatar.defaultGlasses != nil) {
        if ([glassesArray containsObject:currentAvatar.defaultGlasses]) {
            glassesIndex = [glassesArray indexOfObject:currentAvatar.defaultGlasses];
            self.currentGlasses = currentAvatar.defaultGlasses ;
        }
    }
    self.glassesTypeCollection.glassesArray = glassesArray ;
    self.glassesTypeCollection.selectedIndex = glassesIndex ;
    self.glassColorView.hidden = self.glassesTypeCollection.selectedIndex == 0 ;
    
    
    // beard view
    if (isMaleType) {
        self.beardColorCollection.glassesArray = self.beardColorArray ;
        NSInteger beardColorIndex =  currentAvatar.beardColor ? currentAvatar.beardColor.index - 1 : 0  ;
        self.beardColorCollection.glassesColorIndex = beardColorIndex ;
        self.beardColor = self.beardColorArray[beardColorIndex] ;
        
        self.beardCollection.hairArray = [FUManager shareInstance].maleBeards ;
        self.beardCollection.currentHair = currentAvatar.defaultBeard ;
        
        self.beardColorCollection.hidden = self.currentBeard == nil || [self.currentBeard isEqualToString:@"beard-noitem"];
    }else {
        self.beardColor = nil ;
    }
    self.currentBeard = currentAvatar.defaultBeard ;
    
    
    // cloth views
    self.clothCollection.hairArray = isMaleType ? [FUManager shareInstance].maleClothes : [FUManager shareInstance].femaleClothes ;
    self.clothCollection.currentHair = currentAvatar.defaultClothes ;
    self.currentCloth = currentAvatar.defaultClothes ;
    
    // hat views
    self.hatCollection.hairArray = isMaleType ? [FUManager shareInstance].maleHats : [FUManager shareInstance].femaleHats ;
    self.hatCollection.currentHair = currentAvatar.defaultHat ;
    self.currentHat = currentAvatar.defaultHat ;
    
    self.hatColorCollection.glassesArray = [FUManager shareInstance].hatColorArray ;
    NSInteger hatColorIndex =  currentAvatar.hatColor ? currentAvatar.hatColor.index - 1 : 0  ;
    self.hatColorCollection.glassesColorIndex = hatColorIndex ;
    self.hatColor = [FUManager shareInstance].hatColorArray[hatColorIndex] ;
    self.hatColorCollection.hidden = self.currentHat == nil || [self.currentHat isEqualToString:@"hat-noitem"];
}

- (void)loadSubViews {
    
    // bottom views
    self.bottomCollection.dataSource = self ;
    self.bottomCollection.delegate = self ;
    
    self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(32, self.bottomCollection.frame.size.height - 2, 30, 2)];
    self.bottomLine.backgroundColor = [UIColor colorWithHexColorString:@"4C96FF"];
    [self.bottomCollection addSubview:self.bottomLine ];
    [self.bottomCollection reloadData];
    
    // middle views
    self.middleCollection.dataSource = self ;
    self.middleCollection.delegate = self ;
    
    // hair color views
    self.hairColorCollection.mDelegate = self ;
    
    // hair view
    self.hairCollection.mDelegate = self ;
    
    // glasses / glasses frame collection
    self.glassesCollection.mDelegate = self ;
    self.glassesFrameCollection.mDelegate = self ;
    
    // glasses collection
    self.glassesTypeCollection.mDelegate = self ;
    
    // beard views
    if (isMaleType) {
        self.beardColorCollection.mDelegate = self ;
        self.beardCollection.mDelegate = self ;
    }
    
    // cloth views
    self.clothCollection.mDelegate = self ;
    
    // shape collection
    self.shapeCollection.mDelegate = self ;
    
    self.hatCollection.mDelegate = self ;
    self.hatColorCollection.mDelegate = self ;
}


// middle slider value changed
- (IBAction)middleSlidervalueChanged:(FUFigureSlider *)sender {
    
    switch (bottomSelectedIndex) {
        case 0:{            // 美型参数改变
            [self shapeViewSliderValueChanged:sender.value];
        }
            break;
        case 1:{            // 肤色
            NSInteger index = [[self.selectedInfo objectForKey:@"skinIndex"] integerValue];
            self.skinLevel = index + sender.value - 1.0;
            if ([self.delegate respondsToSelector:@selector(figureViewSkinColorDidChangedCurrentColor:nextColor:scale:)]){
                FUFigureColor *nextColor = self.skinColorArray[index] ;
                [self.delegate figureViewSkinColorDidChangedCurrentColor:self.skinColor nextColor:nextColor scale:sender.value];
            }
        }
            break ;
        case 2:{            // 唇色
            NSInteger index = [[self.selectedInfo objectForKey:@"lipIndex"] integerValue];
            self.lipLevel = index + sender.value - 1.0;
            if ([self.delegate respondsToSelector:@selector(figureViewLipColorDidChanged)]){
                [self.delegate figureViewLipColorDidChanged];
            }
        }
            break ;
        case 3:{            // 瞳色
            NSInteger index = [[self.selectedInfo objectForKey:@"irisIndex"] integerValue];
            self.irisLevel = index + sender.value - 1.0;
            if ([self.delegate respondsToSelector:@selector(figureViewIrisColorDidChanged)]){
                [self.delegate figureViewIrisColorDidChanged];
            }
        }
            break ;
            
        default:
            break;
    }
}

- (void)paramsResetActionWithShape:(BOOL)isShape {
    BOOL noChange = YES ;
    if (isShape) {
        noChange = ![self figureViewIsChange];
    }else {
        if (_defaultSkinLevel != self.skinLevel) {
            noChange = NO ;
        }
    }
    
    if (noChange) {
        return ;
    }
    
    NSString *message = isShape ? @"确认将所有参数恢复默认吗？" : @"确认将肤色恢复默认吗？" ;
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [cancle setValue:[UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1.0] forKey:@"titleTextColor"];
    __weak typeof(self)weakSelf = self ;
    UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf certainResetParamsWithShape:isShape];
    }];
    [certain setValue:[UIColor colorWithHexColorString:@"4C96FF"] forKey:@"titleTextColor"];
    [alertC addAction:cancle];
    [alertC addAction:certain];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:^{
    }];
}

- (void)certainResetParamsWithShape:(BOOL)isShape {
    if (isShape) {
        self.middleSliderView.hidden = YES;
        [self.selectedInfo setObject:@(-1) forKey:@"shapeIndex"];   // 美型选择
        [self.middleCollection reloadData];
        [self resetAllShapeParams];
        
    }else {
        self.skinLevel = _defaultSkinLevel ;
        self.skinColor = self.skinColorArray[_defaultSkinLevel] ;
        self.middleSlider.type = FUFigureSliderTypeOther ;
        self.middleSlider.value = 0.0 ;
        [self.selectedInfo setObject:@(_defaultSkinLevel + 1) forKey:@"skinIndex"];   // 肤色选择
        [self.middleCollection reloadData];
        
        // reset skin color
        double c[3] =  {
            self.skinColor.r,
            self.skinColor.g,
            self.skinColor.b
        };
        [[FUManager shareInstance] facepopSetSkinColor:c];
    }
}

- (void)changeMiddleSliderFrame {
    if (bottomSelectedIndex == 0 ){
        self.middleSliderRight.constant = 24 ;
        self.middleSliderLeft.active = YES ;
        self.middleSliderLeading.active = NO ;
        self.middleSliderLable.hidden = NO ;
//
//        self.shapeAdjustBtn.hidden = NO ;
//        self.shapeAdjustBtn.selected = NO ;
        NSInteger index = [[self.selectedInfo objectForKey:@"shapeIndex"] integerValue];
        switch (index) {
            case 1:{
                self.middleSliderView.hidden = NO ;
                self.middleSlider.type = FUFigureSliderTypeShape ;
//                self.middleSlider.value = self.faceLevel ;
            }
                break;
            case 2:{
                self.middleSliderView.hidden = NO ;
                self.middleSlider.type = FUFigureSliderTypeShape ;
//                self.middleSlider.value = self.eyeLevel ;
            }
                break;
            case 3:{
                self.middleSliderView.hidden = NO ;
                self.middleSlider.type = FUFigureSliderTypeShape ;
//                self.middleSlider.value = self.mouthLevel ;
            }
                break;
            case 4:{
                self.middleSliderView.hidden = NO ;
                self.middleSlider.type = FUFigureSliderTypeShape ;
//                self.middleSlider.value = self.noseLevel ;
            }
                break;
            default:{
                self.middleSliderView.hidden = YES ;
                self.middleSlider.type = FUFigureSliderTypeShape ;
//                self.shapeAdjustBtn.hidden = YES ;
//                self.shapeAdjustBtn.selected = NO ;
            }
                break;
        }
    }else if (bottomSelectedIndex == 1){
        self.middleSliderRight.constant = 60 ;
        self.middleSliderLeft.active = NO ;
        self.middleSliderLeading.active = YES ;
        self.middleSliderLable.hidden = YES ;
        
        self.middleSliderView.hidden = NO ;
        self.middleSlider.type = FUFigureSliderTypeOther ;
        self.middleSlider.value = 0 ;
        
//        self.shapeAdjustBtn.hidden = YES ;
//        self.shapeAdjustBtn.selected = NO ;
    }else {
//
//        self.middleSliderRight.constant = 60 ;
//        self.middleSliderLeft.active = NO ;
//        self.middleSliderLeading.active = YES ;
//        self.middleSliderLable.hidden = YES ;
        
        self.middleSliderView.hidden = YES ;
//        self.middleSlider.type = FUFigureSliderTypeOther ;
//        self.middleSlider.value = 0 ;
//
//        self.shapeAdjustBtn.hidden = YES ;
//        self.shapeAdjustBtn.selected = NO ;
    }
    
    [self.middleSliderView layoutIfNeeded];
}

// glasses color changed
- (IBAction)glassesColorValueChange:(FUFigureSlider *)sender {
    switch (currentGlassColorType) {
        case FUFigureGlassesCollectionTypeGlass:{
            self.glassesLevel = self.glassesCollection.glassesColorIndex + sender.value ;
            if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeGlassesColor)]) {
                [self.delegate figureViewDiaChangeGlassesColor];
            }
        }
            break;
        case FUFigureGlassesCollectionTypeFrame:{
            self.glassesFrameLevel = self.glassesFrameCollection.glassesColorIndex + sender.value ;
            if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeGlassesFrameColor)]) {
                [self.delegate figureViewDiaChangeGlassesFrameColor];
            }
        }
            break ;
        case FUFigureGlassesCollectionTypeBeard:{
            NSLog(@"---- there is no beard color slider ~");
        }
            break ;
        case FUFigureGlassesCollectionTypeHat: {
            NSLog(@"---- there is no hat color slider ~");
            break;
        }
    }
}

#pragma mark --- UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.bottomCollection) {
        return self.bottomDataArray.count ;
    }else if (collectionView == self.middleCollection){
        switch (bottomSelectedIndex) {
            case 0:
                return self.shapeArray.count + 1;
                break;
            case 1:
                return self.skinColorArray.count;
                break;
            case 2:
                return self.lipColorArray.count;
                break;
            case 3:
                return self.irisColorArray.count;
                break;
                
            default:
                return 0 ;
                break;
        }
    }
    return 0 ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == self.bottomCollection) {
        FUFigureBottomCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureBottomCell" forIndexPath:indexPath];
        cell.titleLabel.text = self.bottomDataArray[indexPath.row] ;
        cell.titleLabel.textColor = bottomSelectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"] : [UIColor colorWithHexColorString:@"000000"] ;
        return cell ;
    }else if (collectionView == self.middleCollection){
        FUFigureMiddleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureMiddleCell" forIndexPath:indexPath];
        
        switch (bottomSelectedIndex) {
            case 0:{
                if (indexPath.row == 0) {
                    cell.imageView.image = [UIImage imageNamed:@"figure-重置"];
                    cell.imageView.backgroundColor = [UIColor clearColor];
                    cell.selectedImage.hidden = YES ;
                    return cell ;
                }
                NSString *imageName = self.shapeArray[indexPath.row - 1];
                imageName = [@"figure-" stringByAppendingString:imageName];
//
//                NSInteger index = [[self.selectedInfo objectForKey:@"shapeIndex"] integerValue];
//                if (indexPath.row == index && index != 0) {
//                    imageName = [imageName stringByAppendingString:@"-active"];
//                }
                
                cell.imageView.image = [UIImage imageNamed:imageName];
                cell.imageView.backgroundColor = [UIColor clearColor];
                cell.selectedImage.hidden = YES ;
            }
                break;
            case 1:{
                
                if (indexPath.row == 0) {
                    cell.imageView.image = [UIImage imageNamed:@"figure-重置"];
                    cell.imageView.backgroundColor = [UIColor clearColor];
                    cell.selectedImage.hidden = YES ;
                    return cell ;
                }
                
                cell.imageView.image = nil ;
                
                FUFigureColor *color = self.skinColorArray[indexPath.row - 1];
                cell.imageView.backgroundColor = color.color;
                
                NSInteger index = [[self.selectedInfo objectForKey:@"skinIndex"] integerValue];
                cell.selectedImage.hidden = indexPath.row != index ;
            }
                break;
            case 2:{
//
//                if (indexPath.row == 0) {
//                    cell.imageView.image = [UIImage imageNamed:@"figure-重置"];
//                    cell.imageView.backgroundColor = [UIColor clearColor];
//                    cell.selectedImage.hidden = YES ;
//                    return cell ;
//                }
//
                cell.imageView.image = nil ;
                
                FUFigureColor *color = self.lipColorArray[indexPath.row];
                cell.imageView.backgroundColor = color.color;
                
                NSInteger index = [[self.selectedInfo objectForKey:@"lipIndex"] integerValue];
                cell.selectedImage.hidden = indexPath.row != index ;
            }
                break ;
            case 3:{
//
//                if (indexPath.row == 0) {
//                    cell.imageView.image = [UIImage imageNamed:@"figure-重置"];
//                    cell.imageView.backgroundColor = [UIColor clearColor];
//                    cell.selectedImage.hidden = YES ;
//                    return cell ;
//                }
//
                cell.imageView.image = nil ;
                
                FUFigureColor *color = self.irisColorArray[indexPath.row];
                cell.imageView.backgroundColor = color.color;
                
                NSInteger index = [[self.selectedInfo objectForKey:@"irisIndex"] integerValue];
                cell.selectedImage.hidden = indexPath.row != index ;
            }
                break ;
                
            default:
                break;
        }
        return cell ;
    }
    return nil ;
}

- (void)hiddenAllMiddleViews {
    self.middleSliderView.hidden = YES ;
    self.middleCollection.hidden = YES ;
    self.hairView.hidden = YES ;
    self.glassesView.hidden = YES ;
    self.bearView.hidden = YES ;
    self.clothCollection.hidden = YES ;
    self.hatView.hidden = YES ;
    
    self.middleCollection.transform = CGAffineTransformIdentity ;
    self.shapeCollection.hidden = YES ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == self.bottomCollection) {
        
        if (indexPath.row == bottomSelectedIndex) {
            return ;
        }
        
        bottomSelectedIndex = indexPath.row ;
        FUFigureBottomCell *cell = (FUFigureBottomCell *)[collectionView cellForItemAtIndexPath:indexPath];
        CGFloat centerX = cell.center.x ;
        CGPoint center = self.bottomLine.center ;
        center.x = centerX ;
        [UIView animateWithDuration:0.35 animations:^{
            self.bottomLine.center = center ;
        }];
        
        [collectionView reloadData];
        [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        
        if (indexPath.row < 4) {
            [self changeMiddleSliderFrame];
            [self.middleCollection reloadData];
            
            self.middleCollection.hidden = NO ;
            self.hairView.hidden = YES ;
            self.glassesView.hidden = YES ;
            self.bearView.hidden = YES ;
            self.clothCollection.hidden = YES ;
        }
        
        switch (indexPath.row) {
            case 0:{
                NSInteger index = [[self.selectedInfo objectForKey:@"shapeIndex"] integerValue];
                if (index != -1) {
                    self.middleCollection.transform = CGAffineTransformMakeTranslation(-self.frame.size.width, 0) ;
                    self.shapeCollection.hidden = NO ;
                    if (self.shapeCollection.selectedIndex == -1) {
                        self.middleSliderView.hidden = YES ;
                    }else {
                        self.middleSliderView.hidden = NO ;
                        [self changeShapeSliderMessageAndValue];
                    }
                }
            }
                break;
            case 1:{            // 肤色
                self.middleCollection.transform = CGAffineTransformIdentity ;
                self.shapeCollection.hidden = YES ;
                NSString *selectedType = @"skinIndex" ;
                NSInteger index = [[self.selectedInfo objectForKey:selectedType] integerValue];
                [self.middleCollection scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            }
                break;
            case 2:{            // 唇色
                self.middleCollection.transform = CGAffineTransformIdentity ;
                self.shapeCollection.hidden = YES ;
                NSString *selectedType = @"lipIndex" ;
                NSInteger index = [[self.selectedInfo objectForKey:selectedType] integerValue];
                [self.middleCollection scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            }
                break;
            case 3:{            // 瞳色
                self.middleCollection.transform = CGAffineTransformIdentity ;
                self.shapeCollection.hidden = YES ;
                NSString *selectedType = @"irisIndex" ;
                NSInteger index = [[self.selectedInfo objectForKey:selectedType] integerValue];
                [self.middleCollection scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
            }
                break;
            case 4:{            // 发型
                [self hiddenAllMiddleViews];
                self.hairView.hidden = NO ;
            }
                break;
            case 5:{
                if (isMaleType) {       // 男胡子
                    [self hiddenAllMiddleViews];
                    self.bearView.hidden = NO ;
                    self.beardColorCollection.hidden = (self.currentBeard == nil || [self.currentBeard isEqualToString:@"beard-noitem"]);
                }else {                 // 女眼镜
                    [self hiddenAllMiddleViews];
                    self.glassesView.hidden = NO ;
                }
            }
                break ;
            case 6:{
                
                if (isMaleType) {        // 男眼镜
                    [self hiddenAllMiddleViews];
                    self.glassesView.hidden = NO ;
                }else {                 // 女帽子
                    [self hiddenAllMiddleViews];
                    self.hatView.hidden = NO ;
                }
            }
                break ;
            case 7:{
                if (isMaleType) {        // 男帽子
                    [self hiddenAllMiddleViews];
                    self.hatView.hidden = NO ;
                }else {                  // 女 衣服
                    [self hiddenAllMiddleViews];
                    self.clothCollection.hidden = NO ;
                }
            }
                break ;
            case 8:{            // 男 衣服
                [self hiddenAllMiddleViews];
                self.clothCollection.hidden = NO ;
            }
                break ;
                
            default:
                break;
        }
        
    }else if (collectionView == self.middleCollection) {
        
        switch (bottomSelectedIndex) {
            case 0:{        // 美型
                
                if (indexPath.row == 0 ){
                    [self paramsResetActionWithShape:YES];
                }else {
//                    NSInteger index = [[self.selectedInfo objectForKey:@"shapeIndex"] integerValue];
//                    if (index == indexPath.row){
//                        return ;
//                    }
                    [self.selectedInfo setObject:@(indexPath.row) forKey:@"shapeIndex"];
                    [self.middleCollection reloadData];
                    
                    self.shapeCollection.type = indexPath.row ;
                    [self showFaceShapCollection:YES];
                }
            }
                break;
            case 1:{        // 肤色
                
                if (indexPath.row == 0) {
                    [self paramsResetActionWithShape:NO];
                    return ;
                }
                
                NSInteger index = [[self.selectedInfo objectForKey:@"skinIndex"] integerValue];
                if (index == indexPath.row){
                    return ;
                }
                [self.selectedInfo setObject:@(indexPath.row) forKey:@"skinIndex"];
                [self.middleCollection reloadData];
                
                self.skinLevel = (double)indexPath.row - 1.0;
                self.middleSlider.value = 0.0 ;
                self.skinColor = self.skinColorArray[indexPath.row - 1] ;
                if ([self.delegate respondsToSelector:@selector(figureViewSkinColorDidChangedCurrentColor:nextColor:scale:)]){
                    [self.delegate figureViewSkinColorDidChangedCurrentColor:self.skinColor nextColor:nil scale:0.0];
                }
                
            }
                break;
            case 2:{        // 唇色
//
//                if (indexPath.row == 0) {
//                    [self shapeParamsResetAction];
//                    return ;
//                }
//
                NSInteger index = [[self.selectedInfo objectForKey:@"lipIndex"] integerValue];
                if (index == indexPath.row){
                    return ;
                }
                [self.selectedInfo setObject:@(indexPath.row) forKey:@"lipIndex"];
                [self.middleCollection reloadData];
                
                self.lipLevel = (double)indexPath.row;
                self.middleSlider.value = 0.0 ;
                self.lipColor = self.lipColorArray[indexPath.row] ;
                if ([self.delegate respondsToSelector:@selector(figureViewLipColorDidChanged)]){
                    
                    [self.delegate figureViewLipColorDidChanged];
                }
            }
                break;
            case 3:{        // 瞳色
//
//                if (indexPath.row == 0) {
//                    [self shapeParamsResetAction];
//                    return ;
//                }
                
                NSInteger index = [[self.selectedInfo objectForKey:@"irisIndex"] integerValue];
                if (index == indexPath.row){
                    return ;
                }
                [self.selectedInfo setObject:@(indexPath.row) forKey:@"irisIndex"];
                [self.middleCollection reloadData];
                
                self.irisLevel = (double)indexPath.row;
                self.middleSlider.value = 0.0 ;
                self.irisColor = self.irisColorArray[indexPath.row] ;
                if ([self.delegate respondsToSelector:@selector(figureViewIrisColorDidChanged)]){
                    [self.delegate figureViewIrisColorDidChanged];
                }
            }
                break;
            
            default:
                break;
        }
        
    }
}

- (void)showFaceShapCollection:(BOOL)show {
    if (show) {
        self.shapeCollection.transform = CGAffineTransformMakeTranslation(self.frame.size.width, 0) ;
        self.shapeCollection.hidden = NO ;
        [UIView animateWithDuration:0.3 animations:^{
            self.shapeCollection.transform = CGAffineTransformIdentity ;
            self.middleCollection.transform = CGAffineTransformMakeTranslation(-self.frame.size.width, 0) ;
        }];
    }else {
        self.middleSliderView.hidden = YES ;
        [UIView animateWithDuration:0.3 animations:^{
            self.shapeCollection.transform = CGAffineTransformMakeTranslation(self.frame.size.width, 0) ;
            self.middleCollection.transform = CGAffineTransformIdentity ;
        }completion:^(BOOL finished) {
            self.shapeCollection.hidden = YES ;
            [self.selectedInfo setObject:@(-1) forKey:@"shapeIndex"];
        }];
    }
}


- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.middleCollection) {
        if (bottomSelectedIndex == 0){    // 重置
            FUFigureMiddleCell *cell = (FUFigureMiddleCell *)[collectionView cellForItemAtIndexPath:indexPath];
            if (indexPath.row == 0) {
                cell.imageView.image = [UIImage imageNamed:@"figure-重置-active"];
            }else {
                
                NSString *imageName = self.shapeArray[indexPath.row - 1];
                imageName = [[@"figure-" stringByAppendingString:imageName] stringByAppendingString:@"-active"];
                cell.imageView.image = [UIImage imageNamed:imageName];
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.middleCollection) {
        if (bottomSelectedIndex == 0){    // 重置
            FUFigureMiddleCell *cell = (FUFigureMiddleCell *)[collectionView cellForItemAtIndexPath:indexPath];
            if (indexPath.row == 0) {
                cell.imageView.image = [UIImage imageNamed:@"figure-重置"];
            }else {
                NSString *imageName = self.shapeArray[indexPath.row - 1];
                imageName = [@"figure-" stringByAppendingString:imageName];
                cell.imageView.image = [UIImage imageNamed:imageName];
            }
        }
    }
}

#pragma mark ---- hair color
- (void)didChangeHairColor:(NSInteger)colorIndex color:(FUFigureColor *)color{
    self.hairColorIndex = colorIndex ;
    self.hairColor = color ;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeHairColor)]) {
        [self.delegate figureViewDiaChangeHairColor];
    }
}

#pragma mark --- hair name

- (BOOL)didChangeHair:(NSString *)hairName {
    
    NSArray *noArray = @[@"male_hair_t_2", @"male_hair_t_3", @"male_hair_t_4", @"female_hair_12", @"female_hair_t_1"];
    if (self.currentHat && ![self.currentHat isEqualToString:@"hat-noitem"] && [noArray containsObject:hairName]) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showInfoWithStatus:@"此发型暂不支持帽子哦"];
        return NO;
    }
    
    self.currentHair = hairName ;
    
    self.hairColorCollection.hidden = hairName == nil || [hairName isEqualToString:@"hair-noitem"] ;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeHair:)]) {
        [self.delegate figureViewDiaChangeHair:hairName];
    }
    return YES ;
}

#pragma mark ---- hat
- (BOOL)didChangeHat:(NSString *)hatName {
    
    NSArray *noArray = @[@"male_hair_t_2", @"male_hair_t_3", @"male_hair_t_4", @"female_hair_12", @"female_hair_t_1"];
    if (self.currentHair && [noArray containsObject:self.currentHair] && ![hatName isEqualToString:@"hat-noitem"]) {
        [SVProgressHUD dismiss];
        [SVProgressHUD showInfoWithStatus:@"此发型暂不支持帽子哦"];
        return NO;
    }

    self.currentHat = hatName ;
    self.hatColorCollection.hidden = hatName == nil || [hatName isEqualToString:@"hat-noitem"] ;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeHat:)]) {
        [self.delegate figureViewDiaChangeHat:hatName];
    }
    return YES ;
}

- (void)didChangeHatColor:(NSInteger)colorIndex color:(FUFigureColor *)color {
    self.hatColor = color ;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeHatColor)]) {
        [self.delegate figureViewDiaChangeHatColor];
    }
}

#pragma mark ---- glasses color
- (void)didChangeGlassesColor:(NSInteger)colorIndex color:(FUFigureColor *)color{
    
    self.glassesLevel = colorIndex ;
    currentGlassColorType = FUFigureGlassesCollectionTypeGlass ;
    self.currentGlassLabel.text = @"镜片颜色" ;
    self.glassesSlider.value = 0.0 ;
    if (self.glassesSliderView.hidden) {
        self.glassesSliderView.hidden = NO ;
    }
    self.glassesColor = color ;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeGlassesColor)]) {
        [self.delegate figureViewDiaChangeGlassesColor];
    }
}

- (void)didChangeGlassesFrameColor:(NSInteger)colorIndex color:(FUFigureColor *)color{
    self.glassesFrameLevel = colorIndex ;
    currentGlassColorType = FUFigureGlassesCollectionTypeFrame ;
    self.currentGlassLabel.text = @"镜框颜色" ;
    self.glassesSlider.value = 0.0 ;
    if (self.glassesSliderView.hidden) {
        self.glassesSliderView.hidden = NO ;
    }
    self.glassesFrameColor = color ;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeGlassesFrameColor)]) {
        [self.delegate figureViewDiaChangeGlassesFrameColor];
    }
}

- (void)didChangeGlasses:(NSString *)glassesName {
    _currentGlasses = glassesName ;
    
    self.glassColorView.hidden = glassesName == nil || [glassesName isEqualToString:@"glasses-noitem"] ;
    
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeGlasses:)]) {
        [self.delegate figureViewDiaChangeGlasses:glassesName];
    }
}

#pragma mark ---- beard
- (void)didChangeBearColor:(NSInteger)colorIndex color:(FUFigureColor *)color{
    self.beardLevel = colorIndex ;
    self.beardColor = color ;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeBeardColor)]) {
        [self.delegate figureViewDiaChangeBeardColor];
    }
}

- (void)didChangeBeard:(NSString *)beardName {
    self.currentBeard = beardName ;
    self.beardColorCollection.hidden = beardName == nil || [beardName isEqualToString:@"beard-noitem"] ;;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeBeard:)]) {
        [self.delegate figureViewDiaChangeBeard:beardName];
    }
}

#pragma mark --- cloth
- (void)didChangeCloth:(NSString *)clothName {
    self.currentCloth = clothName ;
    if ([self.delegate respondsToSelector:@selector(figureViewDiaChangeCloth:)]) {
        [self.delegate figureViewDiaChangeCloth:clothName];
    }
}

#pragma mark ---- face shape

- (void)shouldHiddShapeCollection {
    [self showFaceShapCollection:NO];
}

-(void)didSelectedShapeType:(FigureShapeSelectedType)type {
    self.middleSliderView.hidden = NO ;
    [self changeShapeSliderMessageAndValue];
}

- (void)changeShapeSliderMessageAndValue {
    
    NSString *message ;
    double level = 0.0 ;
    switch (self.shapeCollection.currentSubType) {
            // face
        case FigureShapeSelectedTypeHeadShrink:{ // 脸型长度
            message = @"脸型长度" ;
            level = self.headShrink ;
        }
            break;
        case FigureShapeSelectedTypeHeadBoneStretch:{ // 额头高低
            message = @"额头高低" ;
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
    
    self.middleSliderLable.text = message ;
    self.middleSlider.value = level ;
}


- (void)shapeViewSliderValueChanged:(double)level {
    NSString *currentKey , *zeroKey ;
    switch (self.shapeCollection.currentSubType) {
            // face
        case FigureShapeSelectedTypeHeadShrink:{ // 脸型长度
            self.headShrink = level ;
            currentKey = level > 0 ? @"Head_shrink" : @"Head_stretch" ;
            zeroKey    = level > 0 ? @"Head_stretch" : @"Head_shrink" ;
        }
            break;
        case FigureShapeSelectedTypeHeadBoneStretch:{ // 额头高低
            self.headBoneStretch = level ;
            currentKey = level > 0 ? @"HeadBone_stretch" : @"HeadBone_shrink" ;
            zeroKey    = level > 0 ? @"HeadBone_shrink" : @"HeadBone_stretch" ;
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
            currentKey = level > 0 ? @"jawbone_Narrow" : @"jawbone_Wide" ;
            zeroKey    = level > 0 ? @"jawbone_Wide" : @"jawbone_Narrow" ;
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
    }
    
    if ([self.delegate respondsToSelector:@selector(figureViewShapeParamsDidChangedWithKey:level:)]) {
        [self.delegate figureViewShapeParamsDidChangedWithKey:zeroKey level:0.0];
        [self.delegate figureViewShapeParamsDidChangedWithKey:currentKey level:fabs(level)];
    }
}

- (void)resetAllShapeParams {
    
    self.headShrink = _headShrink0 ;
    self.headBoneStretch = _headBoneStretch0 ;
    self.cheekNarrow = _cheekNarrow0 ;
    self.jawboneNarrow = _jawboneNarrow0 ;
    self.jawLower = _jawLower0 ;
    self.eyeUp = _eyeUp0 ;
    self.eyeOutterUp = _eyeOutterUp0 ;
    self.eyeClose = _eyeClose0 ;
    self.eyeBothIn = _eyeBothIn0 ;
    self.noseUp = _noseUp0 ;
    self.nostrilIn = _nostrilIn0 ;
    self.noseTipUp = _noseTipUp0 ;
    self.mouthUp = _mouthUp0 ;
    self.upperLipThick = _upperLipThick0 ;
    self.lowerLipThick = _lowerLipThick0 ;
    self.lipCornerIn = _lipCornerIn0 ;
    if ([self.delegate respondsToSelector:@selector(figureViewShapeParamsDidChangedWithKey:level:)]) {
        
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
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_up"             level: fabs(self.eyeUp > 0 ? self.eyeUp : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_down"           level: fabs(self.eyeUp > 0 ? 0 : self.eyeUp)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_outter_up"      level: fabs(self.eyeOutterUp > 0 ? self.eyeOutterUp : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_outter_down"    level: fabs(self.eyeOutterUp > 0 ? 0 : self.eyeOutterUp)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_close"          level: fabs(self.eyeClose > 0 ? self.eyeClose : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_open"           level: fabs(self.eyeClose > 0 ? 0 : self.eyeClose )];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_both_in"        level: fabs(self.eyeBothIn > 0 ? self.eyeBothIn : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"Eye_both_out"       level: fabs(self.eyeBothIn > 0 ? 0 : self.eyeBothIn)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"nose_UP"            level: fabs(self.noseUp > 0 ? self.noseUp : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"nose_Down"          level: fabs(self.noseUp > 0 ? 0 : self.noseUp)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"nostril_In"         level: fabs(self.nostrilIn > 0 ? self.nostrilIn : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"nostril_Out"        level: fabs(self.nostrilIn > 0 ? 0 : self.nostrilIn)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"noseTip_Up"         level: fabs(self.noseTipUp > 0 ? self.noseTipUp : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"noseTip_Down"       level: fabs(self.noseTipUp > 0 ? 0 : self.noseTipUp)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"mouth_Up"           level: fabs(self.mouthUp > 0 ? self.mouthUp : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"mouth_Down"         level: fabs(self.mouthUp > 0 ? 0 : self.mouthUp)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"upperLip_Thick"     level: fabs(self.upperLipThick > 0 ? self.upperLipThick : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"upperLip_Thin"      level: fabs(self.upperLipThick > 0 ? 0 : self.upperLipThick )];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"lowerLip_Thick"     level: fabs(self.lowerLipThick > 0 ? self.lowerLipThick : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"lowerLip_Thin"      level: fabs(self.lowerLipThick > 0 ? 0 : self.lowerLipThick)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"lipCorner_In"       level: fabs(self.lipCornerIn > 0 ? self.lipCornerIn : 0)];
        [self.delegate figureViewShapeParamsDidChangedWithKey:@"lipCorner_Out"      level: fabs(self.lipCornerIn > 0 ? 0 : self.lipCornerIn)];
    }
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

@end

@interface FUFigureMiddleCell ()

@end

#pragma mark ---- middle cell
@implementation FUFigureMiddleCell

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = self.frame.size.width / 2.0 ;
    }
    return self;
}
@end


#pragma mark ---- bottom cell
@implementation FUFigureBottomCell
@end

