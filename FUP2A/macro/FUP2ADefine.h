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

#define TOKENURL        @"https://api2.faceunity.com:7070/token?company=faceunity"
#define UPLOADURL       @"https://api-ptoa.faceunity.com/api/p2a/upload"
#define DOWNLOADURL     @"https://api-ptoa.faceunity.com/api/p2a/download"


#define documentPath        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

#define AvatarListPath      [documentPath stringByAppendingPathComponent:@"Avatars"]

#define AvatarQPath         [documentPath stringByAppendingPathComponent:@"AvatarQs"]

#define CurrentAvatarStylePath ([FUManager shareInstance].avatarStyle == FUAvatarStyleNormal ? AvatarListPath : AvatarQPath)

#define VideoPath           [documentPath stringByAppendingPathComponent:@"video.mp4"]

#define DefaultAvatarNum    2

#define FU_HEAD_BUNDLE @"head.bundle"
#define FU_SERVER_BUNDLE @"server.bundle"

// ========================================================通知==============================================================
// 编辑基本设置  如发型、颜色的通知
#define FUAvatarEditManagerStackNotEmptyNot @"FUAvatarEditManagerStackNotEmptyNot"
// 编辑脸部点位时的通知
#define FUNielianEditManagerStackNotEmptyNot @"FUNielianEditManagerStackNotEmptyNot"

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

