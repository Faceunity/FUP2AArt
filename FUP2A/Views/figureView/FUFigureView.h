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
// 鞋子
- (void)figureViewDidChangeShoes:(NSString *)shoes ;
// 眼镜
- (void)figureViewDidChangeGlasses:(NSString *)glasses ;

// 发色
- (void)figureViewDidChangeHairColor:(FUP2AColor *)hairColor ;
// 肤色
- (void)figureViewDidChangeSkinColor:(FUP2AColor *)skinColor ;
// 瞳色
- (void)figureViewDidChangeIrisColor:(FUP2AColor *)irisColor ;
// 唇色
- (void)figureViewDidChangeLipsColor:(FUP2AColor *)lipsColor ;
// 胡色
- (void)figureViewDidChangeBeardColor:(FUP2AColor *)beardColor ;
// 帽色
- (void)figureViewDidChangeHatColor:(FUP2AColor *)hatColor ;
// 镜片色
- (void)figureViewDidChangeGlassesColor:(FUP2AColor *)glassesColor ;
// 镜框色
- (void)figureViewDidChangeGlassesFrameColor:(FUP2AColor *)glassesFrameColor ;
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
@property (nonatomic, strong) FUP2AColor *glassesColor ;
@property (nonatomic, strong) FUP2AColor *glassesFrameColor ;

@property (nonatomic, copy) NSString *hat ;
@property (nonatomic, strong) FUP2AColor *hatColor ;

@property (nonatomic, copy) NSString *clothes ;

@property (nonatomic, copy) NSString *shoes ;

// face shapes
@property (nonatomic, copy) NSString *face ;
@property (nonatomic, copy) NSString *eyes ;
@property (nonatomic, copy) NSString *mouth;
@property (nonatomic, copy) NSString *nose ;

// colors
@property (nonatomic, assign) double skinLevel ;
@property (nonatomic, assign) double lipLevel ;
@property (nonatomic, assign) double irisLevel ;


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

@property (nonatomic, strong) NSArray <NSString *>*shoesArray ;

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
@end
