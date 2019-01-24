//
//  FUP2ADefine.h
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

typedef enum : NSInteger {
    FUGenderMale           = 0,
    FUGenderFemale         = 1,
    FUGenderUnKnow         = -1,
} FUGender;

typedef enum : NSInteger {
    FURenderCommonMode             = 0,
    FURenderPreviewMode            = 1,
} FURenderMode;

typedef enum : NSInteger {
    FUSceneryModeSingle             = 0,
    FUSceneryModeMultiple           = 1,
    FUSceneryModeAnimation          = 2,
} FUSceneryMode;

typedef enum : NSInteger {
    FUItemTypeController        = 0,
    FUItemTypeHead,
    FUItemTypeBody,
    FUItemTypeHair,
    FUItemTypeClothes,
    FUItemTypeGlasses,
    FUItemTypeBeard,
    FUItemTypeHat,
    FUItemTypeAnimation,
    FUItemTypeEyeLash,
    FUItemTypeEyeBrow,
} FUItemType;

#define URL     @"https://api2.faceunity.com:2339/api/upload/image"
//#define URL     @"http://192.168.0.86:20181/upload_nama"

#define documentPath    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

#define AvatarListPath  [documentPath stringByAppendingPathComponent:@"Avatars"]

#define VideoPath  [documentPath stringByAppendingPathComponent:@"video.mp4"]

#define DefaultAvatarNum    2

