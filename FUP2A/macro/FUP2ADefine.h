//
//  FUP2ADefine.h
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//


typedef enum : NSInteger {
    FUItemTypeFxaa             = 0,
    FUItemTypeBackground,
    FUItemTypeController,
    FUItemTypeAvatar,
    FUItemTypeBody,
    FUItemTypeHair,
    FUItemTypeGlasses,
    FUItemTypeBeard,
    FUItemTypeClothes,
    FUItemTypeHat,
    FUItemTypeStandbyAnimation,
    FUItemTypeARFilter,
} FUItemType;

typedef enum : NSInteger {
    FURenderCommonMode             = 0,
    FURenderPreviewMode            = 1,
} FURenderMode;

typedef enum : NSInteger {
    FUGenderMale           = 0,
    FUGenderFemale         = 1,
    FUGenderUnKnow         = -1,
} FUGender;

#define URL @"https://api2.faceunity.com:2339/api/upload/image"


#define documentPath NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject

#define historyPath [documentPath stringByAppendingPathComponent:@"history.data"]


#define DefaultAvatarNum    2

