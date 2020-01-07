//
//  FUFigureView.h
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUP2ADefine.h"

typedef enum : NSInteger {
    FUFigureShapeTypeNone           = -1 ,
    FUFigureShapeTypeFaceFront      = 0,
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
// 页面类型选择
- (void)figureViewDidSelectedTypeWithIndex:(NSInteger)typeIndex;
// 隐藏全部子页面
- (void)figureViewDidHiddenAllTypeViews;

// 头发
- (void)figureViewDidChangeHair:(NSString *)hair ;
// 脸型
- (void)figureViewDidChangeFace:(NSString *)face index:(NSInteger)index ;
// 眼睛
- (void)figureViewDidChangeEyes:(NSString *)eyes index:(NSInteger)index ;
// 嘴型
- (void)figureViewDidChangeMouth:(NSString *)mouth index:(NSInteger)index ;
// 鼻子
- (void)figureViewDidChangeNose:(NSString *)nose index:(NSInteger)index ;
// 胡子
- (void)figureViewDidChangeBeard:(NSString *)beard ;
// 眉毛
- (void)figureViewDidChangeEyeBrow:(NSString *)eyeBrow ;
// 睫毛
- (void)figureViewDidChangeeyeLash:(NSString *)eyeLash ;
// 帽子
- (void)figureViewDidChangeHat:(NSString *)hat ;
// 衣服
- (void)figureViewDidChangeClothes:(NSString *)clothes ;
// 上衣
- (void)figureViewDidChangeUpper:(NSString *)upper ;
// 裤子
- (void)figureViewDidChangeLower:(NSString *)lower ;
//同时替换上衣和下衣
- (void)figureViewDidChangeUpper:(NSString *)upper andLower:(NSString *)lower;
// 鞋子
- (void)figureViewDidChangeShoes:(NSString *)shoes ;
// 配饰
- (void)figureViewDidChangeDecorations:(NSString *)decorations ;
// 眼镜
- (void)figureViewDidChangeGlasses:(NSString *)glasses ;

// 发色
- (void)figureViewDidChangeHairColor:(FUP2AColor *)hairColor index:(int)index ;
// 肤色
- (void)figureViewDidChangeSkinColor:(FUP2AColor *)skinColor index:(int)index ;
// 瞳色
- (void)figureViewDidChangeIrisColor:(FUP2AColor *)irisColor index:(int)index ;
// 唇色
- (void)figureViewDidChangeLipsColor:(FUP2AColor *)lipsColor index:(int)index ;
// 胡色
- (void)figureViewDidChangeBeardColor:(FUP2AColor *)beardColor ;
// 帽色
- (void)figureViewDidChangeHatColor:(FUP2AColor *)hatColor ;
// 镜片色
- (void)figureViewDidChangeGlassesColor:(FUP2AColor *)glassesColor  index:(int)index ;
// 镜框色
- (void)figureViewDidChangeGlassesFrameColor:(FUP2AColor *)glassesFrameColor index:(int)index ;
// 撤销
-(void)undo:(UIButton*)btn;
// 重做
-(void)redo:(UIButton*)btn;
@end


@interface FUFigureView : UIView

#pragma mark --- output data

// decorations
@property (nonatomic, copy) NSString *hair ;
@property (nonatomic, strong) FUP2AColor *hairColor ;

@property (nonatomic, copy) NSString *beard ;
@property (nonatomic, strong) FUP2AColor *beardColor ;

@property (nonatomic, copy) NSString *eyeBrow ;

@property (nonatomic, copy) NSString *eyeLash ;

@property (nonatomic, copy) NSString *glasses ;
@property (nonatomic, strong) FUP2AColor *skinColor ;
-(FUP2AColor*)getSkinColor;
@property (nonatomic, strong) FUP2AColor *lipColor ;
-(FUP2AColor*)getLipColor;
@property (nonatomic, strong) FUP2AColor *irisColor ;
-(FUP2AColor*)getIrisColor;
@property (nonatomic, strong) FUP2AColor *glassesColor ;
@property (nonatomic, strong) FUP2AColor *glassesFrameColor ;

@property (nonatomic, assign) int glassColorIndex;
@property (nonatomic, assign) int glassFrameColorIndex ;

@property (nonatomic, copy) NSString *hat ;
@property (nonatomic, strong) FUP2AColor *hatColor ;

@property (nonatomic, copy) NSString *clothes ;


// face shapes
@property (nonatomic, copy) NSString *face ;
@property (nonatomic, copy) NSString *eyes ;
@property (nonatomic, copy) NSString *mouth;
@property (nonatomic, copy) NSString *nose ;

// colors
@property (nonatomic, assign) double skinLevel ;
@property (nonatomic, assign) double lipLevel ;
@property (nonatomic, assign) double irisLevel ;

// colors Progress
@property (nonatomic, assign) double skinProgress ;
@property (nonatomic, assign) double lipProgress ;
@property (nonatomic, assign) double irisProgress ;


#pragma mark --- data source
@property (nonatomic, assign) id<FUFigureViewDelegate>delegate ;

// avatar style
@property (nonatomic, assign) FUAvatarStyle avatarStyle ;
@property (nonatomic, assign) BOOL avatarIsMale;

// decorations
@property (nonatomic, strong) NSArray <NSString *>*hairArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*hairColorArray ;

@property (nonatomic, strong) NSArray <NSString *>*beardArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*beardColorArray ;

@property (nonatomic, strong) NSArray <NSString *>*eyeBrowArray ;

@property (nonatomic, strong) NSArray <NSString *>*eyeLashArray ;

@property (nonatomic, strong) NSArray <NSString *>*glassesArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*glassesColorArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*glassesFrameColorArray ;

@property (nonatomic, strong) NSArray <NSString *>*hatArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*hatColorArray ;

@property (nonatomic, strong) NSArray <NSString *>*clothesArray ;
@property (nonatomic, copy) NSString *upper;     // 当前上衣
@property (nonatomic, strong) NSArray <NSString *>*upperArray ;   // 上衣数组
@property (nonatomic, copy) NSString *lower;     // 当前裤子
@property (nonatomic, strong) NSArray <NSString *>*lowerArray ;   // 裤子数组
@property (nonatomic, copy) NSString *shoes;     // 当前鞋子
@property (nonatomic, strong) NSArray <NSString *>*shoesArray ;   // 鞋子数组
@property (nonatomic, copy) NSString *decorations;     // 当前配饰
@property (nonatomic, strong) NSArray <NSString *>*decorationsArray ;   // 配饰数组

// face shapes
@property (nonatomic, strong) NSArray <NSString *>*faceArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*skinColorArray ;
@property (nonatomic, strong) NSArray <NSString *>*eyeArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*irisColorArray ;
@property (nonatomic, strong) NSArray <NSString *>*mouthArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*lipsColorArray ;
@property (nonatomic, strong) NSArray <NSString *>*noseArray ;

- (void)setupFigureView ;
-(void)resetUI;
/**
 当touchMove的时候，判断是否需要隐藏view
 */
-(void)shouldHidePartViews;
@end
