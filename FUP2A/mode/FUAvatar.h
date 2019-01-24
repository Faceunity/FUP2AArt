//
//  FUAvatar.h
//  P2A
//
//  Created by L on 2018/12/15.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FUP2ADefine.h"

@class FUP2AColor ;
@interface FUAvatar : NSObject

@property (nonatomic, copy) NSString *name ;
@property (nonatomic, assign) FUGender gender ;
@property (nonatomic, copy) NSString *imagePath ;

// 是否是预置模型
@property (nonatomic, assign) BOOL defaultModel ;

@property (nonatomic, copy) NSString *hair ;
@property (nonatomic, copy) NSString *clothes ;
@property (nonatomic, copy) NSString *glasses ;
@property (nonatomic, copy) NSString *beard ;
@property (nonatomic, copy) NSString *hat ;
// make up
@property (nonatomic, copy) NSString *eyeLash ;
@property (nonatomic, copy) NSString *eyeBrow ;


@property (nonatomic, assign) double hairLabel ;
@property (nonatomic, assign) double bearLabel ;

// colors
@property (nonatomic, assign) double skinLevel ;
@property (nonatomic, strong) FUP2AColor *skinColor ;
@property (nonatomic, strong) FUP2AColor *lipColor ;
@property (nonatomic, strong) FUP2AColor *irisColor ;
@property (nonatomic, strong) FUP2AColor *hairColor ;
@property (nonatomic, strong) FUP2AColor *glassColor ;
@property (nonatomic, strong) FUP2AColor *glassFrameColor ;
@property (nonatomic, strong) FUP2AColor *beardColor ;
@property (nonatomic, strong) FUP2AColor *hatColor ;

/**
 用 JSON 文件初始化 avatar

 @param dict    从 JSON 文件中读取到的 info
 @return        avatar
 */
+(FUAvatar *)avatarWithInfoDic:(NSDictionary *)dict ;

/**
 avatar 模型保存的根目录

 @return  avatar 模型保存的根目录
 */
- (NSString *)filePath ;

/**
 加载 avatar 模型
    --  会加载 头、头发、身体、衣服 四个道具。
    --  如果有 胡子、帽子、眼镜、睫毛、眉毛也会加载，没有则不加载。
    --  会设置 肤色、唇色、瞳色、发色(光头不设)。
    --  如果有 胡子、帽子、眼镜也会设置其对应颜色。
 
 @return 返回 controller 所在句柄
 */
- (int)loadAvatar ;

/**
 获取 controller 所在句柄

 @return 返回 controller 所在句柄
 */
- (int)getControllerHandle ;

/**
 销毁此模型
 -- 包括 controller, head, body, hair, clothes, glasses, beard, hat, animatiom, arfilter.
 */
- (void)destroyAvatar ;


#pragma mark ----- 以下切换身体配饰

/**
 更换头发
 
 @param hairPath 新头发所在路径
 */
- (void)reloadHairWithPath:(NSString *)hairPath ;

/**
 更换衣服

 @param clothesPath 新衣服所在路径
 */
- (void)reloadClothesWithPath:(NSString *)clothesPath ;

/**
 更换眼镜

 @param glassesPath 新眼镜所在路径
 */
- (void)reloadGlassesWithPath:(NSString *)glassesPath ;

/**
 更换胡子

 @param beardPath 新胡子所在路径
 */
- (void)reloadBeardWithPath:(NSString *)beardPath ;

/**
 更换帽子

 @param hatPath 新帽子所在路径
 */
- (void)reloadHatWithPath:(NSString *)hatPath ;

/**
 加载待机动画
 */
- (void)loadStandbyAnimation ;

/**
 人脸追踪时加载 Pose
 */
- (void)loadTrackFaceModePose ;

/**
 更换动画

 @param animationPath 新动画所在路径
 */
- (void)reloadAnimationWithPath:(NSString *)animationPath ;

/**
 更换睫毛
 
 @param eyelashPath 新睫毛所在路径
 */
- (void)reloadEyeLashWithPath:(NSString *)eyelashPath ;

/**
 更换眉毛
 
 @param eyebrowPath 新眉毛所在路径
 */
- (void)reloadEyeBrowWithPath:(NSString *)eyebrowPath ;

#pragma mark ----- 以下缩放位移

/**
 设置缩放参数

 @param delta 缩放增量
 */
- (void)resetScaleDelta:(float)delta ;

/**
 设置旋转参数

 @param delta 旋转增量
 */
- (void)resetRotDelta:(float)delta ;

/**
 设置垂直位移

 @param delta 垂直位移增量
 */
- (void)resetTranslateDelta:(float)delta ;


/**
 缩放至面部
 */
- (void)resetScaleToFace ;

/**
 缩放至全身
 */
- (void)resetScaleToBody ;

/**
 缩放至小比例的全身
 */
- (void)resetScaleToSmallBody ;


#pragma mark ----- 以下面部追踪模式

/**
 进入面部追踪模式
 */
- (void)enterTrackFaceMode ;

/**
 退出面部追踪模式
 */
- (void)quitTrackFaceMode ;


#pragma mark ----- AR 滤镜模式

/**
 在 AR 滤镜模式下加载 avatar
    -- 默认加载头部装饰，包括：头、头发、胡子、眼镜、帽子、眉毛、睫毛
    -- 加载完毕之后会设置其相应颜色
 
 @return 返回 controller 句柄
 */
- (int)loadAvatarWithARMode ;

/**
 进入 AR滤镜 模式
    -- 会重置旋转缩放等参数
    -- 去除 身体、衣服、动画，但是不会销毁这些道具
 */
- (void)enterARMode ;

/**
 退出 AR滤镜 模式
    -- 会加上 身体、衣服、动画等。
    -- 销毁 ARFilter 道具
 */
- (void)quitARMode ;


#pragma mark ----- 捏脸模式

/**
 进入捏脸模式
 */
- (void)enterFacepupMode ;

/**
 退出捏脸模式
 */
- (void)quitFacepupMode ;

/**
 设置捏脸参数

 @param key     参数名
 @param level   参数
 */
- (void)facepupModeSetParam:(NSString *)key level:(double)level ;

/**
 获取捏脸参数

 @param key    参数名
 @return       参数
 */
- (double)getFacepupModeParamWith:(NSString *)key ;

/**
 捏脸模型下设置颜色
    -- key 具体参数如下：
        肤色：     skin_color
        唇色：     lip_color
        瞳色：     iris_color
        发色：     hair_color
        镜框颜色：  glass_color
        镜片颜色：  glass_frame_color
        帽子颜色：  hat_color
 

 @param color   颜色
 @param key     参数名
 */
- (void)facepupModeSetColor:(FUP2AColor *)color key:(NSString *)key ;

/**
 获取色值 index
    -- key 具体参数如下：
        肤色： skin_color_index
        唇色： lip_color_index
 
 
 @param key  参数名
 @return     色值 index
 */
- (int)facePupGetColorIndexWithKey:(NSString *)key ;

/**
 设置颜色
    -- 默认设置 肤色、唇色、瞳色。
    -- 如果有 头发、眼镜、胡子、帽子等，会设置其相应的颜色，没有则不设
 */
- (void)setAvatarColors ;

/**
 设置参数

 @param key     参数名
 @param value   参数值
 */
- (void)avatarSetParamWithKey:(NSString *)key value:(double)value ;


#pragma mark ----- 以下动画相关

/**
 获取动画总帧数

 @return 动画总帧数
 */
- (int)getAnimationFrameCount ;

/**
 获取当前帧动画播放的位置

 @return    当前动画播放的位置
 */
- (int)getCurrentAnimationFrameIndex ;

@end


