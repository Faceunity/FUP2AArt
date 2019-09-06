//
//  FUAvatar.h
//  P2A
//
//  Created by L on 2018/12/15.
//  Copyright © 2018年 L. All rights reserved.
//


#define fu_iris_color_index @"iris_color_index"
#define fu_lip_color_index @"lip_color_index"

#define fu_skin_color_progress @"skin_color_progress"

#define fu_glass_color_index @"glass_color_index"
#define fu_glass_frame_color_index @"glass_frame_color_index"


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FUP2ADefine.h"

@class FUP2AColor ;
@interface FUAvatar : NSObject<NSCopying>

@property (nonatomic, copy) NSString *name ;
@property (nonatomic, copy) NSString *uuid ;
@property (nonatomic, assign) FUGender gender ;
@property (nonatomic, copy) NSString *imagePath ;

// 是否是新版本
@property (nonatomic, assign) BOOL isQType ;
// 是否创建了所有的匹配发型，针对自定义生成的avatar
@property (nonatomic, assign) BOOL createdHairBundles;

// 是否是预置模型
@property (nonatomic, assign) BOOL defaultModel ;

@property (nonatomic, copy) NSString *hair ;
@property (nonatomic, copy) NSString *clothes ;
@property (nonatomic, copy) NSString *glasses ;
@property (nonatomic, copy) NSString *beard ;
@property (nonatomic, copy) NSString *hat ;
@property (nonatomic, copy) NSString *shoes ;

@property (nonatomic, copy) NSString *face ;
@property (nonatomic, copy) NSString *eyes ;
@property (nonatomic, copy) NSString *mouth ;
@property (nonatomic, copy) NSString *nose ;
// make up
@property (nonatomic, copy) NSString *eyeLash ;
@property (nonatomic, copy) NSString *eyeBrow ;


@property (nonatomic, assign) double hairLabel ;
@property (nonatomic, assign) double bearLabel ;

// colors
@property (nonatomic, assign) double irisLevel ;
@property (nonatomic, assign) double lipsLevel ;


@property (nonatomic, assign) double skinColorProgress;
@property (nonatomic, assign) double irisColorProgress;
@property (nonatomic, assign) double lipColorProgress;
@property (nonatomic, strong) FUP2AColor *skinColor ;
@property (nonatomic, strong) FUP2AColor *lipColor ;
@property (nonatomic, strong) FUP2AColor *irisColor ;
@property (nonatomic, strong) FUP2AColor *hairColor ;
@property (nonatomic, assign) int hairColorIndex ;
@property (nonatomic, strong) FUP2AColor *glassColor ;
@property (nonatomic, strong) FUP2AColor *glassFrameColor ;
@property (nonatomic, assign) int glassColorIndex;
@property (nonatomic, assign) int glassFrameColorIndex ;
@property (nonatomic, strong) FUP2AColor *beardColor ;
@property (nonatomic, strong) FUP2AColor *hatColor;
@property (nonatomic, strong) NSMutableDictionary *orignalColorDic;   // 记录初始状态颜色值，在编辑失败时重新赋值

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

/**
 更换鞋子
    -- Q版专有
 
 @param shoesPath 新眉毛所在路径
 */
- (void)reloadShoesWithPath:(NSString *)shoesPath ;

/**
 更新辅助道具

 @param tmpPath 辅助道具路径
 */
- (void)reloadTmpItemWithPath:(NSString *)tmpPath ;

/**
 更新Cam道具
 
 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString *)camPath ;

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
 捏脸模式缩放至面部正面
 */
- (void)resetScaleToShapeFaceFront ;

/**
 捏脸模式缩放至面部侧面
 */
- (void)resetScaleToShapeFaceSide ;

/**
 缩放至全身
 */
- (void)resetScaleToBody ;

/**
 缩放至小比例的全身
 */
- (void)resetScaleToSmallBody ;

/**
 缩放至显示 Q 版的鞋子
 */
- (void)resetScaleToShowShoes ;

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
 获取 mesh 顶点的坐标

 @param index   顶点序号
 @return        顶点坐标
 */
- (CGPoint)getMeshPointOfIndex:(NSInteger)index ;

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

/**
 重新开始播放动画
 */
- (void)restartAnimation ;
-(void)setTheDefaultColors;
/**
 记录默认的颜色状态；
 */
-(void)recordOriginalColors;
/**
 在编辑失败时，返回默认的颜色状态；
 */
- (void)backToOriginalColors;


#pragma mark ----- 获取配置
-(NSDictionary*)getColorDicFromFUP2AColor:(FUP2AColor*)color;
-(NSDictionary*)getColorsDictionary;
-(NSDictionary*)getInfoDictionary;
@end


