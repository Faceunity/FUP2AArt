//
//  FUAvatar.h
//  FU P2A
//
//  Created by 刘洋 on 2017/3/14.
//  Copyright © 2017年 刘洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FUP2ADefine.h"
#import "FUFigureColor.h"


@interface FUAvatar : NSObject

@property (nonatomic, assign) BOOL isMale;

@property (nonatomic, copy) NSString *time;

@property (nonatomic, copy) NSString *imagePath;

@property (nonatomic, copy) NSString *bundleName;

@property (nonatomic, copy) NSString *bundlePath;

@property (nonatomic, copy) NSArray *hairArr;           // 头发列表
@property (nonatomic, copy) NSString *defaultHair ;     // 默认头发
@property (nonatomic, copy) NSString *defaultGlasses ;  // 默认眼镜
@property (nonatomic, copy) NSString *defaultClothes ;  // 默认衣服
@property (nonatomic, copy) NSString *defaultBeard ;    // 默认胡子
@property (nonatomic, copy) NSString *defaultHat   ;    // 默认帽子

@property (nonatomic, assign) double hairLabel ;
@property (nonatomic, assign) double bearLabel ;
@property (nonatomic, assign) int matchLabel ;

@property (nonatomic, strong) FUFigureColor *serverSkinColor ;
@property (nonatomic, strong) FUFigureColor *serverLipColor ;
@property (nonatomic, strong) FUFigureColor *mobileSkinColor ;
@property (nonatomic, strong) FUFigureColor *mobileLipColor ;

@property (nonatomic, strong) FUFigureColor *skinColor ;
@property (nonatomic, assign) double skinLevel ;
@property (nonatomic, strong) FUFigureColor *lipColor ;
@property (nonatomic, strong) FUFigureColor *irisColor ;
@property (nonatomic, strong) FUFigureColor *hairColor ;
@property (nonatomic, strong) FUFigureColor *glassColor ;
@property (nonatomic, strong) FUFigureColor *glassFrameColor ;
@property (nonatomic, strong) FUFigureColor *beardColor ;
@property (nonatomic, strong) FUFigureColor *hatColor ;

- (NSString *)avatarPath;
@end
