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
@property (weak, nonatomic) IBOutlet FUFigureColorCollection *glassesColorCollection;
@property (weak, nonatomic) IBOutlet FUFigureColorCollection *glassesFrameCollection;
@property (weak, nonatomic) IBOutlet UILabel *glassesLabel;
@property (weak, nonatomic) IBOutlet UILabel *glassesFrameLabel;

@property (weak, nonatomic) IBOutlet FUFigureSlider *colorSlider;
@end

@implementation FUFigureView

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)setupFigureView {
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomAction:)];
    [self addGestureRecognizer:pinchGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self addGestureRecognizer:tapGesture];
    tapGesture.delegate = self ;
    [pinchGesture requireGestureRecognizerToFail:tapGesture];
    
    [self loadSubViewData];
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
        if ([self.delegate respondsToSelector:@selector(figureViewDidHiddenAllTypeViews)]) {
            [self.delegate figureViewDidHiddenAllTypeViews];
        }
    }
    [self hiddenAllTopViewsWithAnimation:YES];
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
    
    self.decorationCollection.shoesArray = self.shoesArray ;
    self.decorationCollection.shoes = self.shoes ;
    
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
    self.decorationColorCollection.skinColor = self.skinColorArray[(int)self.skinLevel] ;
    
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
    [self.glassesCollection loadCollectionData];
    self.glassesCollection.mDelegate = self ;
    
    // glasses color
    self.glassesColorCollection.glassesColorArray = self.glassesColorArray ;
    self.glassesColorCollection.glassesColor = self.glassesColor ;
    [self.glassesColorCollection loadColorData];
    self.glassesColorCollection.mDelegate = self ;
    self.glassesColorCollection.currentType = FUFigureColorTypeGlassesColor ;
    
    self.glassesFrameCollection.glassesFrameColorArray = self.glassesFrameColorArray ;
    self.glassesFrameCollection.glassesFrameColor = self.glassesFrameColor ;
    [self.glassesFrameCollection loadColorData];
    self.glassesFrameCollection.mDelegate = self ;
    self.glassesFrameCollection.currentType = FUFigureColorTypeGlassesFrameColor ;
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
    
    [self hiddenAllTopViewsWithAnimation:NO];
    
    UIView *subView = nil ;
    switch (index) {
        case 0:{    // 发型
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHair ;
            self.decorationColorCollection.hidden = NO ;
            self.decorationColorCollection.currentType = FUFigureColorTypeHairColor ;
            self.colorSlider.hidden = YES ;
        }
            break;
        case 1:{    // 脸型
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationCollectionTypeFace ;
            self.decorationColorCollection.hidden = NO ;
            self.decorationColorCollection.currentType = FUFigureColorTypeSkinColor ;
            self.colorSlider.hidden = NO ;
            self.colorSlider.value = self.skinLevel - (int)self.skinLevel ;
        }
            break;
        case 2:{    // 眼型
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationCollectionTypeEyes ;
            self.decorationColorCollection.hidden = NO ;
            self.decorationColorCollection.currentType = FUFigureColorTypeirisColor ;
            self.colorSlider.hidden = NO ;
            self.colorSlider.value = self.irisLevel - (int)self.irisLevel ;
        }
            break;
        case 3:{    // 嘴型
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationCollectionTypeMouth ;
            self.decorationColorCollection.hidden = NO ;
            self.decorationColorCollection.currentType = FUFigureColorTypeLipsColor ;
            self.colorSlider.hidden = NO ;
            self.colorSlider.value = self.lipLevel - (int)self.lipLevel ;
        }
            break;
        case 4:{    // 鼻子
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationCollectionTypeNose ;
            self.colorSlider.hidden = YES ;
        }
            break;
        case 5:{    // Q/male: 胡子 female:眉毛
            subView = self.decorationView ;
            self.colorSlider.hidden = YES ;
            if (self.avatarStyle == FUAvatarStyleNormal && self.avatarIsMale == NO) {
                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeEyeBrow ;
            }else {
                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeBeard ;
            }
        }
            break;
        case 6:{    // Q/male: 眉毛 female:睫毛
//            subView = self.decorationView ;
//            self.colorSlider.hidden = YES ;
//            self.decorationCollection.currentType = self.avatarStyle == FUAvatarStyleNormal && self.avatarIsMale == NO ? FUFigureDecorationCollectionTypeEyeLash : FUFigureDecorationCollectionTypeEyeBrow ;
            if (self.avatarStyle == FUAvatarStyleQ) {// Q:眼镜
                subView = self.glassesView ;
                if ([self.glassesArray indexOfObject:self.glasses] != 0) {
                    self.glassesFrameCollection.hidden = NO ;
                    self.glassesColorCollection.hidden = NO ;
                    self.glassesLabel.hidden = NO ;
                    self.glassesFrameLabel.hidden = NO ;
                }
            }else { // male: 眉毛 female:睫毛
                subView = self.decorationView ;
                self.colorSlider.hidden = YES ;
                self.decorationCollection.currentType = self.avatarStyle == FUAvatarStyleNormal && self.avatarIsMale == NO ? FUFigureDecorationCollectionTypeEyeLash : FUFigureDecorationCollectionTypeEyeBrow ;
            }
        }
            break;
        case 7:{    // Q: 睫毛 normal: 眼镜
//            if (self.avatarStyle == FUAvatarStyleQ) {
//                subView = self.decorationView ;
//                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeEyeLash ;
//                self.colorSlider.hidden = YES ;
//            }else {     // normal galsses
//                subView = self.glassesView ;
//                if ([self.glassesArray indexOfObject:self.glasses] != 0) {
//                    self.glassesFrameCollection.hidden = NO ;
//                    self.glassesColorCollection.hidden = NO ;
//                    self.glassesLabel.hidden = NO ;
//                    self.glassesFrameLabel.hidden = NO ;
//                }
//            }
            if (self.avatarStyle == FUAvatarStyleQ) {   // Q: 帽子
                subView = self.decorationView ;
                self.colorSlider.hidden = YES ;
                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHat ;
                if ([self.hatArray indexOfObject:self.hat] != 0) {
                    self.decorationColorCollection.hidden = NO ;
                    self.decorationColorCollection.currentType = FUFigureColorTypeHatColor ;
                }
            }else { //  normal: 眼镜
                subView = self.glassesView ;
                if ([self.glassesArray indexOfObject:self.glasses] != 0) {
                    self.glassesFrameCollection.hidden = NO ;
                    self.glassesColorCollection.hidden = NO ;
                    self.glassesLabel.hidden = NO ;
                    self.glassesFrameLabel.hidden = NO ;
                }
            }
        }
            break;
        case 8:{    // Q: 眼镜 normal: 帽子
            
//            if (self.avatarStyle == FUAvatarStyleQ) {   // Q :glasses
//                subView = self.glassesView ;
//                if ([self.glassesArray indexOfObject:self.glasses] != 0) {
//                    self.glassesFrameCollection.hidden = NO ;
//                    self.glassesColorCollection.hidden = NO ;
//                    self.glassesLabel.hidden = NO ;
//                    self.glassesFrameLabel.hidden = NO ;
//                }
//            }else {     // normal hats
//                subView = self.decorationView ;
//                self.colorSlider.hidden = YES ;
//                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHat ;
//                if ([self.hatArray indexOfObject:self.hat] != 0) {
//                    self.decorationColorCollection.hidden = NO ;
//                    self.decorationColorCollection.currentType = FUFigureColorTypeHatColor ;
//                }
//            }
            
            if (self.avatarStyle == FUAvatarStyleQ) {   // Q:衣服
                self.colorSlider.hidden = YES ;
                subView = self.decorationView ;
                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeClothes ;
            }else { // 帽子
                subView = self.decorationView ;
                self.colorSlider.hidden = YES ;
                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHat ;
                if ([self.hatArray indexOfObject:self.hat] != 0) {
                    self.decorationColorCollection.hidden = NO ;
                    self.decorationColorCollection.currentType = FUFigureColorTypeHatColor ;
                }
            }
        }
            break;
        case 9:{    // Q: 帽子 normal: 衣服
//            subView = self.decorationView ;
//            self.colorSlider.hidden = YES ;
//            switch (self.avatarStyle) {
//                case FUAvatarStyleQ:{
//                    self.decorationCollection.currentType = FUFigureDecorationCollectionTypeHat ;
//                    if ([self.hatArray indexOfObject:self.hat] != 0) {
//                        self.decorationColorCollection.hidden = NO ;
//                        self.decorationColorCollection.currentType = FUFigureColorTypeHatColor ;
//                    }
//                }
//                    break ;
//                case FUAvatarStyleNormal:{
//                    self.decorationCollection.currentType = FUFigureDecorationCollectionTypeClothes ;
//                }
//                    break;
//            }
            
            if (self.avatarStyle == FUAvatarStyleQ) {   // Q:鞋子
                self.colorSlider.hidden = YES ;
                subView = self.decorationView ;
                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeShoes ;
            }else { // 衣服
                subView = self.decorationView ;
                self.colorSlider.hidden = YES ;
                self.decorationCollection.currentType = FUFigureDecorationCollectionTypeClothes ;
            }
        }
            break;
        case 10:{    // Q: 衣服
            self.colorSlider.hidden = YES ;
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationCollectionTypeClothes ;
        }
            break;
        case 11:{    // Q：鞋子
            self.colorSlider.hidden = YES ;
            subView = self.decorationView ;
            self.decorationCollection.currentType = FUFigureDecorationCollectionTypeShoes ;
        }
            break;
            
        default:
            break;
    }
    
    subView.hidden = NO ;
    
    if (!show) {    // 隐藏
        
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

- (void)decorationCollectionDidSelectedItem:(NSString *)itemName index:(NSInteger)index decorationType:(FUFigureDecorationCollectionType)type {
    
    switch (type) {
        case FUFigureDecorationCollectionTypeHair:{
            self.hair = itemName ;
            self.decorationColorCollection.hidden = [itemName containsString:@"noitem"];
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
            self.beard = itemName ;
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
            self.hat = itemName ;
            self.decorationColorCollection.hidden = [itemName containsString:@"noitem"];
            self.decorationColorCollection.currentType = FUFigureColorTypeHatColor ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHat:)]) {
                [self.delegate figureViewDidChangeHat:itemName];
            }
        }
            break;
        case FUFigureDecorationCollectionTypeClothes:{
            self.clothes = itemName ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeClothes:)]) {
                [self.delegate figureViewDidChangeClothes:itemName];
            }
        }
            break;
        case FUFigureDecorationCollectionTypeShoes:{
            self.shoes = itemName ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeShoes:)]) {
                [self.delegate figureViewDidChangeShoes:itemName];
            }
        }
            break;
    }
}

#pragma mark --- FUFigureColorCollectionDelegate

- (void)didSelectedColor:(FUP2AColor *)currentColor index:(NSInteger)index tyep:(FUFigureColorType)type {
    switch (type) {
        case FUFigureColorTypeHairColor:{
            self.hairColor = currentColor ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeHairColor:)]) {
                [self.delegate figureViewDidChangeHairColor:currentColor];
            }
        }
            break;
        case FUFigureColorTypeSkinColor: {
            self.skinLevel = index ;
            self.colorSlider.value = 0.0 ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:)]) {
                [self.delegate figureViewDidChangeSkinColor:currentColor];
            }
        }
            break;
        case FUFigureColorTypeirisColor: {
            self.irisLevel = index ;
            self.colorSlider.value = 0.0 ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeIrisColor:)]) {
                [self.delegate figureViewDidChangeIrisColor:currentColor];
            }
        }
            break;
        case FUFigureColorTypeLipsColor: {
            self.lipLevel = index ;
            self.colorSlider.value = 0.0 ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeLipsColor:)]) {
                [self.delegate figureViewDidChangeLipsColor:currentColor];
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
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlassesColor:)]) {
                [self.delegate figureViewDidChangeGlassesColor:currentColor];
            }
        }
            break;
        case FUFigureColorTypeGlassesFrameColor: {
            self.glassesFrameColor = currentColor ;
            if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlassesFrameColor:)]) {
                [self.delegate figureViewDidChangeGlassesFrameColor:currentColor];
            }
        }
            break;
    }
}

#pragma mark --- FUFigureHorizCollectionDelegate
- (void)didChangeGlasses:(NSString *)glasses {
    self.glasses = glasses ;
    
    BOOL hidden = [glasses containsString:@"noitem"];
    self.glassesFrameCollection.hidden = hidden ;
    self.glassesColorCollection.hidden = hidden ;
    self.glassesLabel.hidden = hidden ;
    self.glassesFrameLabel.hidden = hidden ;
    
    if ([self.delegate respondsToSelector:@selector(figureViewDidChangeGlasses:)]) {
        [self.delegate figureViewDidChangeGlasses:glasses];
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
                if ([self.delegate respondsToSelector:@selector(figureViewDidChangeSkinColor:)]) {
                    [self.delegate figureViewDidChangeSkinColor:color];
                }
            }
                break;
            case FUFigureColorTypeirisColor:{
                self.irisLevel = sender.value + (int)self.irisLevel ;
                if ([self.delegate respondsToSelector:@selector(figureViewDidChangeIrisColor:)]) {
                    [self.delegate figureViewDidChangeIrisColor:color];
                }
            }
                break ;
            case FUFigureColorTypeLipsColor:{
                self.lipLevel = sender.value + (int)self.lipLevel ;
                if ([self.delegate respondsToSelector:@selector(figureViewDidChangeLipsColor:)]) {
                    [self.delegate figureViewDidChangeLipsColor:color];
                }
            }
                break ;
                
            default:
                break;
        }
    }
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
//            self.bottomCollection.dataArray = @[@"发型", @"脸型", @"眼型", @"嘴型", @"鼻型", @"胡子", @"眉毛", @"睫毛", @"眼镜", @"帽子", @"衣服", @"鞋子"] ;
            self.bottomCollection.dataArray = @[@"发型", @"脸型", @"眼型", @"嘴型", @"鼻型", @"胡子", @"眼镜", @"帽子", @"衣服"] ;
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

#pragma mark --- UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    for (UIView *view in self.subviews) {
        if ([touch.view isDescendantOfView:view] && touch.view != self.decorationView) {
            return NO ;
        }
    }
    return YES ;
}
@end
