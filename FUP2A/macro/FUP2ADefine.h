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
#define UPLOADURL       @"https://api.faceunity.com/api/p2a/upload"
#define DOWNLOADURL     @"https://api.faceunity.com/api/p2a/download"


#define documentPath        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

#define AvatarListPath      [documentPath stringByAppendingPathComponent:@"Avatars"]

#define AvatarQPath         [documentPath stringByAppendingPathComponent:@"AvatarQs"]

#define VideoPath           [documentPath stringByAppendingPathComponent:@"video.mp4"]

#define DefaultAvatarNum    2

