//
//  FUFigureShapeCollection.h
//  FUP2A
//
//  Created by L on 2018/11/9.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    FUFigureShapeCollectionFace            = 1,
    FUFigureShapeCollectionEyes            = 2,
    FUFigureShapeCollectionMouth           = 3,
    FUFigureShapeCollectionNose            = 4,
} FUFigureShapeCollectionType;


typedef enum : NSInteger {
    // face
    FigureShapeSelectedTypeHeadShrink        = 11, // 脸型长度
    FigureShapeSelectedTypeHeadBoneStretch    = 10, // 额头高低 ---- 暂时去掉
    FigureShapeSelectedTypeCheekNarrow            = 12, // 脸颊宽度
    FigureShapeSelectedTypeJawboneNarrow        = 13, // 下颚宽度
    FigureShapeSelectedTypeJawLower           = 14, // 下巴高低
    
    // eye
    FigureShapeSelectedTypeEyeUp            = 21, // 眼镜位置
    FigureShapeSelectedTypeEyeOutterUp      = 22, // 眼角上下
    FigureShapeSelectedTypeEyeClose           = 23, // 眼睛高低
    FigureShapeSelectedTypeEyeBothIn          = 24, // 眼镜宽窄
    
    // mouth
    FigureShapeSelectedTypeMouthUp         = 31, // 👄位置
    FigureShapeSelectedTypeUpperLipThick      = 32, // 上👄厚度
    FigureShapeSelectedTypeLowerLipThick      = 33, // 下👄厚度
    FigureShapeSelectedTypeLipCornerIn        = 34, // 👄宽度
    
    // nose
    FigureShapeSelectedTypeNoseUp           = 41, // 👃位置
    FigureShapeSelectedTypeNostrilIn          = 42, // 👃宽窄
    FigureShapeSelectedTypeNoseTipUp        = 43, // 👃高低
    
} FigureShapeSelectedType;


@protocol FUFigureShapeCollectionDelegate <NSObject>

@optional
- (void)shouldHiddShapeCollection ;
- (void)didSelectedShapeType:(FigureShapeSelectedType)type ;
@end

@interface FUFigureShapeCollection : UICollectionView

@property (nonatomic, assign) id<FUFigureShapeCollectionDelegate>mDelegate ;

@property (nonatomic, assign) FUFigureShapeCollectionType type ;


@property (nonatomic, assign) FigureShapeSelectedType currentSubType ;

@property (nonatomic, assign) NSInteger selectedIndex ;
@end


@interface FUFigureShapeCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
