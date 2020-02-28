//
//  FUP2ADefine.h
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

typedef NS_ENUM(NSInteger, FUAvatarStyle){
    FUAvatarStyleNormal           = 0,
    FUAvatarStyleQ                = 1,
};

typedef NS_ENUM(NSInteger, FUGender){
    FUGenderMale           = 0,
    FUGenderFemale         = 1,
    FUGenderUnKnow         = -1,
};

typedef NS_ENUM(NSInteger, FURenderMode){
    FURenderCommonMode             = 0,
    FURenderPreviewMode            = 1,
};
typedef NS_ENUM(NSInteger, FUVideoRecordState){
    Original             = 0,
    Recording            = 1,
	Completed            = 2,
};
// Sta音频的播放状态
typedef NS_ENUM(NSInteger, FUStaPlayState){
    StaOriginal             = 0,
    StaPlaying            = 1,
	StaCompleted            = 2,
};
typedef NS_ENUM(NSInteger, FUSceneryMode) {
    FUSceneryModeSingle             = 0,
    FUSceneryModeMultiple           = 1,
    FUSceneryModeAnimation          = 2,
};

typedef NS_ENUM(NSInteger, FUMeshPiontDirection) {
    FUMeshPiontDirectionHorizontal       = 0,   // 左右
    FUMeshPiontDirectionVertical         = 1,   // 上下
    FUMeshPiontDirectionAll              = 2,   // 0 && 1
};

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

//#define TOKENURL        @"https://api2.faceunity.com:7070/token?company=faceunity"
//#define UPLOADURL       @"https://api-ptoa.faceunity.com/api/p2a/upload"
//#define DOWNLOADURL     @"https://api-ptoa.faceunity.com/api/p2a/download"


#define documentPath        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

#define AvatarListPath      [documentPath stringByAppendingPathComponent:@"Avatars"]

#define AvatarQPath         [documentPath stringByAppendingPathComponent:@"AvatarQs"]

//#define CurrentAvatarStylePath ([FUManager shareInstance].avatarStyle == FUAvatarStyleNormal ? AvatarListPath : AvatarQPath)
#define CurrentAvatarStylePath  AvatarQPath
#define VideoPath           [documentPath stringByAppendingPathComponent:@"video.mp4"]

#define DefaultAvatarNum    2

#define FU_HEAD_BUNDLE @"head.bundle"
#define FU_SERVER_BUNDLE @"server.bundle"

#define FUAppConfig @"FUAppConfig.json"

// ========================================================通知==============================================================
// 编辑基本设置  如发型、颜色的通知
#define FUAvatarEditManagerStackNotEmptyNot @"FUAvatarEditManagerStackNotEmptyNot"
// 编辑脸部点位时的通知
#define FUNielianEditManagerStackNotEmptyNot @"FUNielianEditManagerStackNotEmptyNot"
// 进入捏脸模式通知
#define FUEnterNileLianNot @"FUEnterNileLianNot"
// 生成头发中
#define FUCreatingHairBundleNot @"FUCreatingHairBundleNot"
// 撤销重做的通知
#define FUAvatarEditedDoNot @"FUAvatarEditedDoNot"

// 获得RGB颜色
#define kColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]

// 获得随机RGB颜色
#define randomColor [UIColor colorWithRed:arc4random()%255 / 255.0 green:arc4random()%255 / 255.0 blue:arc4random()%255 / 255.0 alpha:1]


//设置RGB颜色 0xffffff
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define FUGradientSlider_minColorArr {246,192,167}
#define FUGradientSlider_maxColorArr {70, 37, 21}

//屏幕的高度
#define HEIGHT [UIScreen mainScreen].bounds.size.height
//屏幕的宽度
#define WIDTH  [UIScreen mainScreen].bounds.size.width

#define BubbleImageViewY_Macro 20

#pragma mark ===================错误码================
static int const FUAppVersionInvalid = 3001;



#pragma mark ------ itemKey ------

//#define TAG_FU_ITEM_HAIR  @"发型"
//#define TAG_FU_ITEM_FACE  @"脸型"
//#define TAG_FU_ITEM_MOUTH  @"嘴型"
//#define TAG_FU_ITEM_EYE  @"眼型"
//#define TAG_FU_ITEM_NOSE  @"鼻型"
//#define TAG_FU_ITEM_CLOTH  @"套装"
//#define TAG_FU_ITEM_UPPER  @"上衣"
//#define TAG_FU_ITEM_LOWER  @"下衣"
//#define TAG_FU_ITEM_SHOES  @"鞋子"
//#define TAG_FU_ITEM_HAT  @"帽子"
//#define TAG_FU_ITEM_EYELASH  @"睫毛"
//#define TAG_FU_ITEM_EYEBROW  @"眉毛"
//#define TAG_FU_ITEM_BEARD  @"胡子"
//#define TAG_FU_ITEM_GLASSES  @"眼镜"
//#define TAG_FU_ITEM_EYESHADOW  @"眼影"
//#define TAG_FU_ITEM_EYELINER  @"眼线"
//#define TAG_FU_ITEM_PUPIL  @"美瞳"
//#define TAG_FU_ITEM_FACEMAKEUP  @"脸妆"
//#define TAG_FU_ITEM_LIPGLOSS  @"唇妆"
//#define TAG_FU_ITEM_DECORATION  @"饰品"
#define TAG_FU_ITEM_HAIR  @"hair"
#define TAG_FU_ITEM_FACE  @"face"
#define TAG_FU_ITEM_MOUTH  @"mouth"
#define TAG_FU_ITEM_EYE  @"eyes"
#define TAG_FU_ITEM_NOSE  @"nose"
#define TAG_FU_ITEM_CLOTH  @"clothes"
#define TAG_FU_ITEM_UPPER  @"upper"
#define TAG_FU_ITEM_LOWER  @"lower"
#define TAG_FU_ITEM_SHOES  @"shoes"
#define TAG_FU_ITEM_HAT  @"hat"
#define TAG_FU_ITEM_EYELASH  @"eyeLash"
#define TAG_FU_ITEM_EYEBROW  @"eyeBrow"
#define TAG_FU_ITEM_BEARD  @"beard"
#define TAG_FU_ITEM_GLASSES  @"glasses"
#define TAG_FU_ITEM_EYESHADOW  @"eyeShadow"
#define TAG_FU_ITEM_EYELINER  @"eyeLiner"
#define TAG_FU_ITEM_PUPIL  @"pupil"
#define TAG_FU_ITEM_FACEMAKEUP  @"faceMakeup"
#define TAG_FU_ITEM_LIPGLOSS  @"lipGloss"
#define TAG_FU_ITEM_DECORATION  @"decorations"


#define TAG_FU_SKIN_COLOR_PROGRESS  @"skin_color_progress"
