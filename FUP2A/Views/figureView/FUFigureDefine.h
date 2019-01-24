//
//  FUFigureDefine.h
//  FUP2A
//
//  Created by L on 2019/1/8.
//  Copyright © 2019年 L. All rights reserved.
//

typedef enum : NSInteger {
    FUFigureDecorationTypeHair          = 1,
    FUFigureDecorationTypeBeard,
    FUFigureDecorationTypeEyeBrow,
    FUFigureDecorationTypeEyeLash,
    FUFigureDecorationTypeHat,
    FUFigureDecorationTypeClothes,
    FUFigureDecorationTypeIris,
    FUFigureDecorationTypeLips,
    FUFigureDecorationTypeGlassesFrame,
    FUFigureDecorationTypeGlasses,
} FUFigureDecorationType;

typedef enum : NSInteger {
    FUFigureFaceTypeSkinColor          = 1,
    FUFigureFaceTypeFace,
    FUFigureFaceTypeEyes,
    FUFigureFaceTypeLips,
    FUFigureFaceTypeNose,
} FUFigureFaceType;

typedef enum : NSInteger {
    FUFigureSliderTypeShape            = 1,
    FUFigureSliderTypeOther            = 2,
} FUFigureSliderType;


typedef enum : NSInteger {
    // face
    FigureShapeSelectedTypeHeadShrink        = 10, // 脸型长度
    FigureShapeSelectedTypeHeadBoneStretch   = 11, // 额头宽窄
    FigureShapeSelectedTypeCheekNarrow       = 12, // 脸颊宽度
    FigureShapeSelectedTypeJawboneNarrow     = 13, // 下颚宽度
    FigureShapeSelectedTypeJawLower          = 14, // 下巴高低
    
    // eye
    FigureShapeSelectedTypeEyeUp             = 20, // 眼镜位置
    FigureShapeSelectedTypeEyeOutterUp       = 21, // 眼角上下
    FigureShapeSelectedTypeEyeClose          = 22, // 眼睛高低
    FigureShapeSelectedTypeEyeBothIn         = 23, // 眼镜宽窄
    FigureShapeSelectedTypeEyesColor         = 24, // 瞳孔颜色
    
    // mouth
    FigureShapeSelectedTypeMouthUp           = 30, // 👄位置
    FigureShapeSelectedTypeUpperLipThick     = 31, // 上👄厚度
    FigureShapeSelectedTypeLowerLipThick     = 32, // 下👄厚度
    FigureShapeSelectedTypeLipCornerIn       = 33, // 👄宽度
    FigureShapeSelectedTypeLipsColor         = 34, // 👄颜色
    
    // nose
    FigureShapeSelectedTypeNoseUp            = 40, // 👃位置
    FigureShapeSelectedTypeNostrilIn         = 41, // 👃宽窄
    FigureShapeSelectedTypeNoseTipUp         = 42, // 👃高低
    
} FigureShapeSelectedType;
