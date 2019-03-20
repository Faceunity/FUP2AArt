//
//  FUFigureView.h
//  EditView
//
//  Created by L on 2018/11/2.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    FUFigureShapeTypeNoneFront      = 0,
    FUFigureShapeTypeNoneSide,
    FUFigureShapeTypeFaceFront,
    FUFigureShapeTypeFaceSide,
    FUFigureShapeTypeEyesFront,
    FUFigureShapeTypeEyesSide,
    FUFigureShapeTypeLipsFront,
    FUFigureShapeTypeLipsSide,
    FUFigureShapeTypeNoseFront,
    FUFigureShapeTypeNoseSide,
} FUFigureShapeType;

@class FUP2AColor ;
@protocol FUFigureViewDelegate <NSObject>

@optional
// 捏合手势实现
- (void)figureViewDidReceiveZoomAction:(float)ds ;
// 头发
- (void)figureViewDidChangeHair:(NSString *)hairName ;
// 胡子
- (void)figureViewDidChangeBeard:(NSString *)beardName ;
// 眉毛
- (void)figureViewDidChangeEyeBrow:(NSString *)browName ;
// 睫毛
- (void)figureViewDidChangeeyeLash:(NSString *)lashName ;
// 帽子
- (void)figureViewDidChangeHat:(NSString *)hatName ;
// 衣服
- (void)figureViewDidChangeClothes:(NSString *)clothesName ;
// 眼镜
- (void)figureViewDidChangeGlasses:(NSString *)glassesName ;
// 发色
- (void)figureViewDidChangeHairColor:(FUP2AColor *)hairColor ;
// 胡色
- (void)figureViewDidChangeBeardColor:(FUP2AColor *)beardColor ;
// 帽色
- (void)figureViewDidChangeHatColor:(FUP2AColor *)hatColor ;
// 肤色
- (void)figureViewDidChangeSkinColor:(FUP2AColor *)skinColor ;
// 瞳色
- (void)figureViewDidChangeIrisColor:(FUP2AColor *)irisColor ;
// 唇色
- (void)figureViewDidChangeLipsColor:(FUP2AColor *)lipsColor ;
// 镜框色
- (void)figureViewDidChangeGlassesFrameColor:(FUP2AColor *)color ;
// 镜片色
- (void)figureViewDidChangeGlassesColor:(FUP2AColor *)color ;
// 美型参数改变
- (void)figureViewShapeParamsDidChangedWithKey:(NSString *)key level:(double)level ;
// 页面类型选择
- (void)figureViewDidSelectedTypeWithIndex:(NSInteger)typeIndex;
// 隐藏全部子页面
- (void)figureViewDidHiddenAllTypeViews;
// 捏脸点击页面
- (void)figureViewDidSelectShapeView:(FUFigureShapeType)shapeType ;
// 捏脸重置
- (void)figureViewShouldResetParamWithType:(NSInteger)typeIndex ;
@end


@interface FUFigureView : UIView

@property (nonatomic, assign) id<FUFigureViewDelegate>delegate ;

@property (nonatomic, copy) NSString *currentHair ;
@property (nonatomic, copy) NSString *currentBeard ;
@property (nonatomic, copy) NSString *currentCloth ;
@property (nonatomic, copy) NSString *currentHat ;
@property (nonatomic, copy) NSString *currentEyeLash ;
@property (nonatomic, copy) NSString *currentEyeBrow ;

@property (nonatomic, assign) double skinLevel ;
@property (nonatomic, strong) FUP2AColor *skinColor ;
@property (nonatomic, strong) FUP2AColor *lipColor ;
@property (nonatomic, strong) FUP2AColor *irisColor ;

@property (nonatomic, strong) FUP2AColor *hairColor ;

@property (nonatomic, strong) FUP2AColor *glassesColor ;

@property (nonatomic, strong) FUP2AColor *glassesFrameColor ;
@property (nonatomic, copy) NSString *currentGlasses ;

//@property (nonatomic, strong) FUP2AColor *beardColor ;
@property (nonatomic, strong) FUP2AColor *hatColor ;

// defauly value
@property (nonatomic, assign) double defaultSkinLevel ;

- (void)setupFigureView ;

@end
