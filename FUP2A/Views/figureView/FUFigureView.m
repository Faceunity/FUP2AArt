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
#import "FUFigureSlider.h"
#import "FUFigureDecorationHorizCollection.h"
#import "FUFigureColorCollection.h"
#import "FUFigureShapeCollection.h"

@interface FUFigureView ()
<
UIGestureRecognizerDelegate,
FUFigureBottomCollectionDelegate,
FUFigureDecorationCollectionDelegate,
FUFigureDecorationColorCollectionDelegate,
FUFigureDecorationHorizCollectionDelegate,
FUFigureColorCollectionDelegate,
FUFigureShapeCollectionDelegate
>
{
    BOOL isMale ;
    
    CGFloat preScale; // 捏合比例
    
    FUFigureShapeType currentShapeType ;
}

@property (weak, nonatomic) IBOutlet FUFigureBottomCollection *bottomCollection;

@property (weak, nonatomic) IBOutlet UIView *decorationView;
@property (weak, nonatomic) IBOutlet FUFigureDecorationCollection *decorationCollection;
@property (weak, nonatomic) IBOutlet FUFigureDecorationColorCollection *decorationColorCollection;

@property (weak, nonatomic) IBOutlet UIView *glassesView;
@property (weak, nonatomic) IBOutlet FUFigureDecorationHorizCollection *glassesCollection;
@property (weak, nonatomic) IBOutlet UIView *glassesColorView;
@property (weak, nonatomic) IBOutlet FUFigureDecorationColorCollection *glassesFrameColorCollection;
@property (weak, nonatomic) IBOutlet FUFigureDecorationColorCollection *glassesColorCollection;

// color collection
@property (weak, nonatomic) IBOutlet UIView *colorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorCollectionLeft;
@property (weak, nonatomic) IBOutlet FUFigureColorCollection *colorCollection;
@property (weak, nonatomic) IBOutlet UIView *colorSliderView;
@property (weak, nonatomic) IBOutlet FUFigureSlider *colorSlider;

// shape collection
@property (weak, nonatomic) IBOutlet FUFigureShapeCollection *shapeCollection;
@property (weak, nonatomic) IBOutlet UIButton *faceBtn;

@property (weak, nonatomic) IBOutlet UIView *shapeView;

@end

@implementation FUFigureView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    currentShapeType = FUFigureShapeTypeNoneFront ;
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

- (void)tapClick:(UITapGestureRecognizer *)tap {
    
    [self.bottomCollection hiddenSelectedItem];
    
    if (!self.decorationView.hidden || !self.glassesView.hidden) {
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
    
    
    self.colorCollection.mDelegate = self ;
    
    // skin color
    self.colorCollection.skinColorArray = [FUManager shareInstance].skinColorArray;
    if (currentAvatar.skinLevel != 0.0) {
        self.defaultSkinLevel = currentAvatar.skinLevel ;
        self.skinColor = currentAvatar.skinColor ;
        self.skinLevel = currentAvatar.skinLevel ;

        FUP2AColor *color = [FUManager shareInstance].skinColorArray[(int)self.skinLevel];
        self.colorCollection.skinColor = color ;
        
        self.colorSlider.value = self.skinLevel - (int)self.skinLevel ;
    }else {

        self.defaultSkinLevel = [currentAvatar facePupGetColorIndexWithKey:@"skin_color_index"];
        self.skinColor = [FUManager shareInstance].skinColorArray[(int)_defaultSkinLevel] ;
        self.skinLevel = _defaultSkinLevel ;
        
        currentAvatar.skinLevel = self.skinLevel ;
        currentAvatar.skinColor = self.skinColor ;
        self.colorCollection.skinColor = _skinColor ;
        
        self.colorSlider.value = 0.0 ;
    }
    
    // iris color
    self.colorCollection.irisColorArray = [FUManager shareInstance].irisColorArray;
    if (currentAvatar.irisColor == nil) {
        currentAvatar.irisColor = [FUManager shareInstance].irisColorArray[0];
    }
    self.colorCollection.irisColor = [self getColorOfColorList:[FUManager shareInstance].irisColorArray color:currentAvatar.irisColor] ;
    
    // lips color
    self.colorCollection.lipsColorArray = [FUManager shareInstance].lipColorArray;
    if (currentAvatar.lipColor == nil) {
        currentAvatar.lipColor = [FUManager shareInstance].lipColorArray[0];
    }
    self.colorCollection.lipsColor = [self getColorOfColorList:[FUManager shareInstance].lipColorArray color:currentAvatar.lipColor] ; ;
    
    self.colorCollection.type = FUFigureColorTypeSkinColor ;
    
    self.shapeCollection.mDelegate = self ;
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
            subView = self.colorView ;
            self.colorCollection.type = FUFigureColorTypeSkinColor ;
            self.colorCollectionLeft.constant = 70.0 ;
            [self.colorView layoutIfNeeded];
            self.colorSliderView.hidden = NO ;
        }
            break;
        case 2:{     // 捏脸
            subView = self.shapeView ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidSelectShapeView:)]) {
                [self.delegate figureViewDidSelectShapeView:currentShapeType];
            }
        }
            break;
        case 3:{     // 瞳色
            subView = self.colorView ;
            self.colorCollection.type = FUFigureColorTypeirisColor ;
            self.colorCollectionLeft.constant = 0.0 ;
            [self.colorView layoutIfNeeded];
            self.colorSliderView.hidden = YES ;
        }
            break;
        case 4:{     // 唇色
            subView = self.colorView ;
            self.colorCollection.type = FUFigureColorTypeLipsColor ;
            self.colorCollectionLeft.constant = 0.0 ;
            [self.colorView layoutIfNeeded];
            self.colorSliderView.hidden = YES ;
        }
            break;
        case 5:{     // 男胡子 && 女眉毛
            subView = self.decorationView ;
            self.decorationCollection.currentType = isMale ? FUFigureDecorationTypeBeard : FUFigureDecorationTypeEyeBrow ;
            self.decorationColorCollection.hidden = YES;
        }
            break;
        case 6:{     // 男眉毛 && 女睫毛
            subView = self.decorationView ;
            self.decorationCollection.currentType = isMale ? FUFigureDecorationTypeEyeBrow : FUFigureDecorationTypeEyeLash ;
            self.decorationColorCollection.hidden = YES;
        }
            break;
        case 7:{     // 眼镜
            subView = self.glassesView ;
        }
            break;
        case 8:{     // 帽子
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationTypeHat ;
            self.decorationColorCollection.hidden = [self.currentHat isEqualToString:@"hat-noitem"];
            self.decorationColorCollection.currentType = FUFigureDecorationTypeHat ;
        }
            break;
        case 9:{    // 衣服
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
        
        if (index != 2) {
            if ([self.delegate respondsToSelector:@selector(figureViewDidHiddenAllTypeViews)]) {
                [self.delegate figureViewDidHiddenAllTypeViews];
            }
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
            self.colorView.transform = CGAffineTransformMakeTranslation(0, self.colorView.frame.size.height) ;
            self.glassesView.transform = CGAffineTransformMakeTranslation(0, self.glassesView.frame.size.height) ;
            self.shapeView.transform = CGAffineTransformMakeTranslation(0, self.shapeView.frame.size.height) ;
        }completion:^(BOOL finished) {
            self.decorationView.hidden = YES ;
            self.colorView.hidden = YES ;
            self.glassesView.hidden = YES ;
            self.shapeView.hidden = YES ;
        }];
    }else {
        self.decorationView.hidden = YES ;
        self.colorView.hidden = YES ;
        self.glassesView.hidden = YES ;
        self.shapeView.hidden = YES ;
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
    return self.colorCollection.irisColor ;
}
-(FUP2AColor *)lipColor {
    return self.colorCollection.lipsColor ;
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
//            self.beardColor = color;
//            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHairColor:)]) {
//                [self.delegate figureViewDidChangeBeardColor:color];
//            }
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

#pragma mark ----- FUFigureColorCollectionDelegate

// 肤色点击
- (void)colorCollectionDidSelectedSkinColor:(FUP2AColor *)skinColor {
    
    NSUInteger skinIndex = [[FUManager shareInstance].skinColorArray indexOfObject:skinColor];
    self.skinLevel = (double)skinIndex ;
    self.skinColor = skinColor ;
    
    self.colorSlider.value = 0.0 ;
    if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:)]) {
        [self.delegate figureViewDidChangeSkinColor:skinColor];
    }
}

// 唇色点击
- (void)colorCollectionDidSelectedLipsColor:(FUP2AColor *)lipsColor {
    self.lipColor = lipsColor ;
    if ([self.delegate respondsToSelector:@selector(figureViewDidChangeLipsColor:)]) {
        [self.delegate figureViewDidChangeLipsColor:lipsColor];
    }
}

// 瞳色点击
- (void)colorCollectionDidSelectedIrisColor:(FUP2AColor *)irisColor {
    self.irisColor = irisColor ;
    if ([self.delegate respondsToSelector:@selector(figureViewDidChangeIrisColor:)]) {
        [self.delegate figureViewDidChangeIrisColor:irisColor];
    }
}

// skin slider changed
- (IBAction)colorSliderChanged:(FUFigureSlider *)sender {
    
    FUP2AColor *skinColor = self.colorCollection.skinColor ;
    NSInteger index = [[FUManager shareInstance].skinColorArray indexOfObject: skinColor];
    FUP2AColor *nextColor = [[FUManager shareInstance].skinColorArray objectAtIndex:index + 1];
    float scale = sender.value ;
    
    FUP2AColor *color = [FUP2AColor colorWithR:skinColor.r + scale * (nextColor.r - skinColor.r) g:skinColor.g + scale * (nextColor.g - skinColor.g) b:skinColor.b + scale * (nextColor.b - skinColor.b)];
    
    if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:)]) {
        [self.delegate figureViewDidChangeSkinColor:color];
    }
}

- (IBAction)resetSkinColor:(UIButton *)sender {
    
    if (self.skinLevel != _defaultSkinLevel) {
        __weak typeof(self)weakSelf = self ;
        [self showAlterWithMessage:@"确认将肤色恢复默认吗？" certainAction:^(UIAlertAction * _Nonnull action) {
            
            weakSelf.skinLevel = self->_defaultSkinLevel ;
            weakSelf.skinColor = [FUManager shareInstance].skinColorArray[(int)self->_defaultSkinLevel] ;
            
            self.colorSlider.value = self->_defaultSkinLevel - (int)self->_defaultSkinLevel ;
            
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:)]) {
                [self.delegate figureViewDidChangeSkinColor:self.skinColor];
            }
            
            self.colorCollection.skinColor = weakSelf.skinColor;
        }];
    }
}

- (void)showAlterWithMessage:(NSString *)message certainAction:(void (^)(UIAlertAction * _Nonnull action))action {
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [cancle setValue:[UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1.0] forKey:@"titleTextColor"];
    
    
    UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:action];
    [certain setValue:[UIColor colorWithHexColorString:@"4C96FF"] forKey:@"titleTextColor"];
    [alertC addAction:cancle];
    [alertC addAction:certain];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertC animated:YES completion:^{
    }];
}

#pragma mark ----- FUFigureShapeCollectionDelegate

- (void)shapeCollectionDidSelectIndex:(NSInteger)index {
    
    FUFigureShapeType type = 0;
    switch (index) {
        case 0:{        // 面部
            type = self.faceBtn.selected ? FUFigureShapeTypeFaceSide : FUFigureShapeTypeFaceFront ;
        }
            break;
        case 1:{        // 眼睛
            type = self.faceBtn.selected ? FUFigureShapeTypeEyesSide : FUFigureShapeTypeEyesFront ;
        }
            break;
        case 2:{        // 嘴巴
            type = self.faceBtn.selected ? FUFigureShapeTypeLipsSide : FUFigureShapeTypeLipsFront ;
        }
            break;
        case 3:{        // 鼻子
            type = self.faceBtn.selected ? FUFigureShapeTypeNoseSide : FUFigureShapeTypeNoseFront ;
        }
            break;
        default:{       // 取消
            type = self.faceBtn.selected ? FUFigureShapeTypeNoneSide : FUFigureShapeTypeNoneFront ;
        }
            break;
    }
    currentShapeType = type ;
    if ([self.delegate respondsToSelector:@selector(figureViewDidSelectShapeView:)]) {
        [self.delegate figureViewDidSelectShapeView:type];
    }
}

- (IBAction)faceBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected ;
    
    FUFigureShapeType type ;
    if (sender.selected) {
        switch (self.shapeCollection.selectedIndex) {
            case 0:{        // 面部侧面
                type = FUFigureShapeTypeFaceSide ;
            }
                break;
            case 1:{        // 眼睛侧面
                type = FUFigureShapeTypeEyesSide ;
            }
                break;
            case 2:{        // 嘴巴侧面
                type = FUFigureShapeTypeLipsSide ;
            }
                break;
            case 3:{        // 鼻子侧面
                type = FUFigureShapeTypeNoseSide ;
            }
                break;
            default:{        // 侧面无角度
                type = FUFigureShapeTypeNoneSide ;
            }
                break;
        }
    } else {
        
        switch (self.shapeCollection.selectedIndex) {
            case 0:{        // 面部正面
                type = FUFigureShapeTypeFaceFront ;
            }
                break;
            case 1:{        // 眼睛正面
                type = FUFigureShapeTypeEyesFront ;
            }
                break;
            case 2:{        // 嘴巴正面
                type = FUFigureShapeTypeLipsFront ;
            }
                break;
            case 3:{        // 鼻子正面
                type = FUFigureShapeTypeNoseFront ;
            }
                break;
            default:{        // 正面无角度
                type = FUFigureShapeTypeNoneFront ;
            }
                break;
        }
    }
    currentShapeType = type ;
    if ([self.delegate respondsToSelector:@selector(figureViewDidSelectShapeView:)]) {
        [self.delegate figureViewDidSelectShapeView:type];
    }
}

- (IBAction)faceShapeResetAction:(UIButton *)sender {
    
    NSInteger typeIndex = self.shapeCollection.selectedIndex ;
    if ([self.delegate respondsToSelector:@selector(figureViewShouldResetParamWithType:)]) {
        [self.delegate figureViewShouldResetParamWithType:typeIndex];
    }
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

- (FUP2AColor *)getColorOfColorList:(NSArray *)list color:(FUP2AColor *)color {
    NSInteger index = 0 ;
    for (FUP2AColor *c in list) {
        if (c.r == color.r
            && c.g == color.g
            && c.b == color.b) {
            index = [list indexOfObject:c];
            break ;
        }
    }
    return [list objectAtIndex:index] ;
}

@end
