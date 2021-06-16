//
//  FUAvatar.h
//  P2A
//
//  Created by L on 2018/12/15.
//  Copyright © 2018年 L. All rights reserved.
//

#define fu_skin_color_progress @"skin_color_progress"


typedef enum : NSInteger {
    FUAvataClothTypeSuit,    // 套装
    FUAvataClothTypeUpperAndLower,  // 上衣+裤子
} FUAvataClothType;

typedef enum : NSInteger {
    FUAvataHairTypeHair,    // 正常头发
    FUAvataHairTypeHairHat, // 发帽
} FUAvataHairType;

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FUItemModel.h"

typedef enum : NSInteger {
    FUItemTypeController        = 0,
    FUItemTypeHead,
    FUItemTypeBody,
    
    FUItemTypeHair,
    FUItemTypeClothes,
    FUItemTypeUpper,   // 上衣
    FUItemTypeLower,   // 裤子
    FUItemTypeShoes,   // 鞋子
    FUItemTypeHat,
    FUItemTypeEyeLash,
    FUItemTypeEyeBrow,
    FUItemTypeBeard,
    FUItemTypeGlasses,
    FUItemTypeEyeShadow,
    FUItemTypeEyeLiner,
    FUItemTypePupil,
    FUItemTypeMakeFaceup,
    FUItemTypeLipGloss,
    // 配饰 大类 ，多选
    FUItemTypeDecoration_shou,  // 手饰
    FUItemTypeDecoration_jiao,  // 脚饰
    FUItemTypeDecoration_xianglian,  // 项链
    FUItemTypeDecoration_erhuan,  // 耳环
    FUItemTypeDecoration_toushi,  // 头饰
    
    
    
    FUItemTypeHairHat,  // 发帽
    FUItemTypeAnimation,
    FUItemTypeCamera,
    FUItemTypeBackground,     // 编辑页的背景选项
    FUItemTypeTmp,
    FUItemTypeARFilter,    // 用于编辑AR滤镜的句柄
    FUItemTypeEnd,   //用于定位枚举类型长度
} FUItemType;


@class FUP2AColor, FUAvatarChangeModel;
static const int tmpItemsCount  = 100;
@interface FUAvatar : NSObject<NSCopying>
{
    // 句柄数组
    int items[FUItemTypeEnd];
    // 临时记录的句柄数组
    int tmpItems[tmpItemsCount];

}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *uuid;
@property (nonatomic, assign) FUGender gender;
@property (nonatomic, copy) NSString *imagePath;

// 是否是新版本
@property (nonatomic, assign) BOOL isQType;


// 是否是预置模型
@property (nonatomic, assign) BOOL defaultModel;
// 当前是否穿的是女性衣服
@property (nonatomic, assign) BOOL wearFemaleClothes;
// 当前是穿的衣服类型
@property (nonatomic, assign) FUAvataClothType clothType;
@property (nonatomic, assign) FUAvataHairType hairType;

@property (nonatomic, strong) FUItemModel *hair;
@property (nonatomic, strong) FUItemModel *clothes;   // 套装
@property (nonatomic, strong) FUItemModel *upper;   // 上衣
@property (nonatomic, strong) FUItemModel *lower;   // 裤子
@property (nonatomic, strong) FUItemModel *glasses;
@property (nonatomic, strong) FUItemModel *beard;
@property (nonatomic, strong) FUItemModel *hat;
@property (nonatomic, strong) FUItemModel *shoes;    // 鞋子


@property (nonatomic, strong) FUItemModel *face;
@property (nonatomic, strong) FUItemModel *eyes;
@property (nonatomic, strong) FUItemModel *mouth;
@property (nonatomic, strong) FUItemModel *nose;
@property (nonatomic, strong) FUItemModel *hairHat;   //发帽
@property (nonatomic, strong) FUItemModel *dress_2d;   //2d背景
// make up  美妆大类  多选
@property (nonatomic, strong) FUItemModel *eyeLash;  //睫毛
@property (nonatomic, strong) FUItemModel *eyeBrow;  //眉毛
@property (nonatomic, strong) FUItemModel *eyeShadow;  //眼影
@property (nonatomic, strong) FUItemModel *eyeLiner;  //眼线
@property (nonatomic, strong) FUItemModel *pupil;     //美瞳
@property (nonatomic, strong) FUItemModel *faceMakeup;  //脸妆
@property (nonatomic, strong) FUItemModel *lipGloss;   //唇妆
// 配饰 大类  多选
@property (nonatomic, strong) FUItemModel *decoration_shou;    // 手饰
@property (nonatomic, strong) FUItemModel *decoration_jiao;    // 脚饰
@property (nonatomic, strong) FUItemModel *decoration_xianglian;    // 项链
@property (nonatomic, strong) FUItemModel *decoration_erhuan;    // 耳环
@property (nonatomic, strong) FUItemModel *decoration_toushi;    // 头饰



@property (nonatomic, assign) double hairLabel;
@property (nonatomic, assign) double bearLabel;

// colors
@property (nonatomic, assign) NSInteger skinColorIndex;
@property (nonatomic, assign) double skinColorProgress;
@property (nonatomic, assign) NSInteger lipColorIndex;
@property (nonatomic, assign) NSInteger irisColorIndex;
@property (nonatomic, assign) NSInteger hairColorIndex;
@property (nonatomic, assign) NSInteger beardColorIndex;
@property (nonatomic, assign) NSInteger glassFrameColorIndex;
@property (nonatomic, assign) NSInteger glassColorIndex;
@property (nonatomic, assign) NSInteger hatColorIndex;
@property (nonatomic, assign) NSInteger eyebrowColorIndex;
@property (nonatomic, assign) NSInteger eyeshadowColorIndex;
@property (nonatomic, assign) NSInteger eyelashColorIndex;
@property (nonatomic, assign) int currentInstanceId;    // 当前avatar在nama底层的序号;

/**
 avatar 模型保存的根目录

 @return  avatar 模型保存的根目录
 */
- (NSString *)filePath;

/**
 获取 controller 所在句柄

 @return 返回 controller 所在句柄
 */
- (int)getControllerHandle;

/**
 销毁此模型
 -- 包括 controller, head, body, hair, clothes, glasses, beard, hat, animatiom, arfilter.
 */
- (void)destroyAvatar;
/**
 销毁此模型,只包括avatar资源
 -- 包括 , head, body, hair, clothes, glasses, beard, hat, animatiom, arfilter.
 */
- (void)destroyAvatarResouce;

#pragma mark ----- 以下切换身体配饰
- (void)loadItemWithtype:(FUItemType)itemType filePath:(NSString *)path;
/**
 更新Cam道具

 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString * __nullable)camPath ;
/**
 更换动画

 @param animationPath 新动画所在路径
 */
- (void)reloadAnimationWithPath:(NSString *)animationPath;
// 添加临时道具，
- (void)addTmpItemFilePath:(NSString *)path;
/// 获取当前动画句柄
- (int)getCurrentAnimationHandle;
/// 获取当前动画播放进度
/// 获取某个动画的播放进度
// 进度0-0.9999为第一次循环，1-1.9999为第二次循环，以此类推
// 即使play_animation_once,进度也会突破1.0，照常运行
//
// @param anim_id 当前动画的句柄
- (float)getAnimateProgress;

/**
 更新辅助道具

 @param tmpPath 辅助道具路径
 */
- (void)reloadTmpItemWithPath:(NSString *)tmpPath;



#pragma mark ----- 以下面部追踪模式

/**
 进入身体追踪模式
 */
- (void)enterTrackBodyMode;
/**
 退出身体追踪模式
 */
- (void)quitTrackBodyMode;
/**
 进入身体跟随模式
 */
- (void)enterFollowBodyMode;

/**
 退出身体跟随模式
 */
- (void)quitFollowBodyMode;
/**
 设置在身体动画和身体追踪数据之间过渡的时间，默认值为0.5（秒）
 */
- (void)setHuman3dAnimTransitionTime:(float)time;
/**
  去掉脖子
 */
- (void)removeNeck;
/**
  重新加上脖子
 */
- (void)reAddNeck;
/**
  获取当前身体追踪状态，0.no_body,1.half_body,2.half_more_body,3.full_body
 */
- (int)getCurrentBodyTrackState;
/**
 进入DDE追踪模式
 */
- (void)enterDDEMode;

/**
 退出身体追踪模式
 */
- (void)quitDDEMode;


#pragma mark ----- AR 滤镜模式

/**
 在 AR 滤镜模式下加载 avatar
    -- 默认加载头部装饰，包括：头、头发、胡子、眼镜、帽子、眉毛、睫毛
    -- 加载完毕之后会设置其相应颜色
 
 @return 返回 controller 句柄
 */
- (int)loadAvatarWithARMode;

/**
 进入 AR滤镜 模式
    -- 会重置旋转缩放等参数
    -- 去除 身体、衣服、动画，但是不会销毁这些道具
 */
- (void)enterARMode;

/**
 退出 AR滤镜 模式
    -- 会加上 身体、衣服、动画等。
    -- 销毁 ARFilter 道具
 */
- (void)quitARMode;


/**
 打开Blendshape 混合
 */
- (void)enableBlendshape;

/**
 关闭Blendshape 混合
 */
- (void)disableBlendshape;
/**
 关闭Blendshape 混合
 */
/**
  设置用户输入的bs系数数组
*/
- (void)setBlend_expression:(double*)blend_expression;
/**
  设置blend_expression的权重
*/
- (void)setExpression_wieght0:(double*)expression_wieght0;
/**
 设置blend_expression的权重
 */
- (void)setExpression_wieght1:(double*)expression_wieght1;
/// 向nama声明当前avatar时第几个avatar，在多个avatar同时存在时使用
/// @param index 声明当前avatar序号
-(void)setCurrentAvatarIndex:(int) index;
#pragma mark ----- 捏脸模式

/**
 进入捏脸模式
 */
- (void)enterFacepupMode;

/**
 退出捏脸模式
 */
- (void)quitFacepupMode;
/**
 获取 mesh 顶点的坐标
 
 @param index   顶点序号
 @return        顶点坐标
 */
- (CGPoint)getMeshPointOfIndex:(NSInteger)index PixelBufferW:(int)pixelBufferW PixelBufferH:(int)pixelBufferH;
/**
 设置捏脸参数

 @param key     参数名
 @param level   参数
 */
- (void)facepupModeSetParam:(NSString *)key level:(double)level;

/**
 获取捏脸参数

 @param key    参数名
 @return       参数
 */
- (double)getFacepupModeParamWith:(NSString *)key;

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
- (void)facepupModeSetColor:(FUP2AColor *)color key:(NSString *)key;

- (void)facepupModeSetEyebrowColor:(FUP2AColor *)color;
#pragma mark ----- 以下动画相关

/**
 获取动画总帧数

 @return 动画总帧数
 */
- (int)getAnimationFrameCount;

/**
 获取当前帧动画播放的位置

 @return    当前动画播放的位置
 */
- (int)getCurrentAnimationFrameIndex;

/**
 重新开始播放动画
 */
- (void)restartAnimation;
/**
 播放动画
 */
- (void)startAnimation;
/**
 播放一次动画
 */
- (void)playOnceAnimation;
/**
 暂停动画
 */
- (void)pauseAnimation;
/**
 结束动画
 */
- (void)stopAnimation;
/**
 启用相机动画
 */
- (void)enableCameraAnimation;
/**
 停止相机动画
 */
- (void)stopCameraAnimation;
/**
 循环相机动画
 */
- (void)loopCameraAnimation;
/**
 停止循环相机动画
 */
- (void)stopLoopCameraAnimation;

- (void)setThePrefabricateColors;


- (void)openHairAnimation;

- (void)closeHairAnimation;

#pragma mark ----- 获取配置


#pragma mark  ------ 捏脸 ------
- (NSArray *)getFacepupModeParamsWithLength:(int)length;


/// 设置捏脸参数
/// @param dict 捏脸参数字典
- (void)configFacepupParamWithDict:(NSDictionary *)dict;

#pragma mark ------ 动画 ------

/**
 换装后回到首页动画
 */
- (void)loadAfterEditAnimation;

//换装界面动画
- (void)loadChangeItemAnimation;


/**
 加载ani_mg动画
 */
- (void)load_ani_mg_Animation;

/**
 去除动画
 */
- (void)removeAnimation;
//
/**
 加载待机动画
 */
- (void)loadStandbyAnimation;
/**
 人脸追踪时加载 Pose 不带信号量
 */
- (void)loadTrackFaceModePose_NoSignal;
/**
 人脸追踪时加载 Pose
 */
- (void)loadTrackFaceModePose;

/**
 呼吸动画
 */
- (void)loadIdleModePose;
/**
呼吸动画,不带信号量
*/
- (void)loadIdleModePose_NoSignal;

/**
 身体追踪时加载 Pose
 */
- (void)loadTrackBodyModePose;

/**
 将Avatar的位置设置为初始状态
 */
- (void)resetScaleToOriginal;

#pragma mark ----- 以下缩放位移
- (void)resetScaleDelta:(float)delta;

/**
 设置旋转参数

 @param delta 旋转增量
 */
- (void)resetRotDelta:(float)delta;

/**
 设置垂直位移

 @param delta 垂直位移增量
 */
- (void)resetTranslateDelta:(float)delta;

/**
 缩放至面部
 */
- (void)resetScaleToFace;
/**
 缩放至截图
 */
- (void)resetScaleToScreenShot;
/**
 捏脸模式缩放至面部正面
 */
- (void)resetScaleToShapeFaceFront;

/**
 捏脸模式缩放至面部侧面
 */
- (void)resetScaleToShapeFaceSide;

/**
 缩放至全身
 */
- (void)resetScaleToBody;

/**
 缩放至半身
 */
- (void)resetScaleToHalfBody;

/**
 缩放至小比例的全身
 */
- (void)resetScaleToSmallBody;
/// 缩小至全身并在屏幕左边显示
- (void)resetScaleSmallBodyToLeft;
/// 缩小至全身并在屏幕左边显示
- (void)resetScaleSmallBodyToRight;
/// 缩小至全身并在屏幕上边显示
- (void)resetScaleSmallBodyToUp;
/// 缩小至全身并在屏幕下面显示
- (void)resetScaleSmallBodyToDown;

/**
 缩放至显示 Q 版的鞋子
 */
- (void)resetScaleToShowShoes;
/**
 缩放至小比例的身体跟随
 */
- (void)resetScaleToFollowBody;


/**
 使用相机bundle缩放至脸部特写
 */
- (void)resetScaleToFace_UseCam;
/**
 使用相机bundle缩放至脸部特写,不使用信号量，防止造成死锁
 */
- (void)resetScaleToFace_UseCamNoSignal;

/**
 使用相机bundle缩放至小比例的全身
 */
- (void)resetScaleToSmallBody_UseCam;

/**
 使用相机bundle缩放至全身
 */
- (void)resetScaleToBody_UseCam;

/**
 替换服饰时使用的cam
 */
- (void)resetScaleChange_UseCam;

/**
 缩放至全身追踪,驱动页未收起模型选择栏等工具栏的情况

 */
- (void)resetScaleToTrackBodyWithToolBar;
/**
 缩放至全身追踪,驱动页收起模型选择栏等工具栏的情况

 */
- (void)resetScaleToTrackBodyWithoutToolBar;

/**
缩放至全身追踪
使用场景：
1.导入视频后生成的画面
*/
- (void)resetScaleToImportTrackBody;

/**
 缩放至半身
 */
- (void)resetScaleToHalfBodyWithToolBar;

/**
 缩放至半身
 */
- (void)resetScaleToHalfBodyInput;


#pragma mark ------ 形象加载 ------
/// 根据传入的形象模型重设形象的信息
/// @param avatar 形象模型
- (void)resetValueFromBeforeEditAvatar:(FUAvatar *)avatar;
/**
 加载 avatar 模型
 --  会加载 头、头发、身体、衣服、默认动作 四个道具。
 --  如果有 胡子、帽子、眼镜也会加载，没有则不加载。
 --  会设置 肤色、唇色、瞳色、发色(光头不设)。
 --  如果有 胡子、帽子、眼镜也会设置其对应颜色。
 
 @return 返回 controller 所在句柄
 @param isBg 是否渲染模型自身的背景 bundle
 */
- (int)loadAvatarToControllerWith:(BOOL)isBg;
/**
 加载 avatar 模型
 --  会加载 头、头发、身体、衣服、默认动作 四个道具。
 --  如果有 胡子、帽子、眼镜也会加载，没有则不加载。
 --  会设置 肤色、唇色、瞳色、发色(光头不设)。
 --  如果有 胡子、帽子、眼镜也会设置其对应颜色。
 
 @return 返回 controller 所在句柄
 */
- (int)loadAvatarToController;

/// 加载形象颜色
- (void)loadAvatarColor;

#pragma mark ------ 绑定道具 ------
/// 加载发型
/// @param model 发型数据
- (void)bindHairWithItemModel:(FUItemModel *)model;

/// 加载套装
/// @param model 套装数据
- (void)bindClothWithItemModel:(FUItemModel *)model;

/// 加载上衣
/// @param model 上衣数据
- (void)bindUpperWithItemModel:(FUItemModel *)model;

/// 加载下衣
/// @param model 下衣数据
- (void)bindLowerWithItemModel:(FUItemModel *)model;

/// 加载鞋子
/// @param model 鞋子数据
- (void)bindShoesWithItemModel:(FUItemModel *)model;

/// 加载帽子
/// @param model 帽子数据
- (void)bindHatWithItemModel:(FUItemModel *)model;

/// 加载睫毛
/// @param model 睫毛数据
- (void)bindEyeLashWithItemModel:(FUItemModel *)model;

/// 加载眉毛
/// @param model 眉毛数据
- (void)bindEyebrowWithItemModel:(FUItemModel *)model;

/// 加载胡子
/// @param model 胡子数据
- (void)bindBeardWithItemModel:(FUItemModel *)model;

/// 加载眼镜
/// @param model 眼镜数据
- (void)bindGlassesWithItemModel:(FUItemModel *)model;

/// 加载眼影
/// @param model 眼影数据
- (void)bindEyeShadowWithItemModel:(FUItemModel *)model;

/// 加载眼线
/// @param model 眼线数据
- (void)bindEyeLinerWithItemModel:(FUItemModel *)model;

/// 加载美瞳
/// @param model 美瞳数据
- (void)bindPupilWithItemModel:(FUItemModel *)model;

/// 加载脸妆
/// @param model 脸妆数据
- (void)bindFaceMakeupWithItemModel:(FUItemModel *)model;

/// 加载唇妆
/// @param model 唇妆数据
- (void)bindLipGlossWithItemModel:(FUItemModel *)model;


//   ========================= 饰品大类  多选  ==============
 
/// 加载饰品
/// @param model 手饰品数据
- (void)bindDecorationShouWithItemModel:(FUItemModel *)model;
/// 加载饰品
/// @param model 脚饰品数据
- (void)bindDecorationJiaoWithItemModel:(FUItemModel *)model;
/// 加载饰品
/// @param model 项链饰品数据
- (void)bindDecorationXianglianWithItemModel:(FUItemModel *)model;
/// 加载饰品
/// @param model 耳环饰品数据
- (void)bindDecorationErhuanWithItemModel:(FUItemModel *)model;
/// 加载饰品
/// @param model 头饰饰品数据
- (void)bindDecorationToushiWithItemModel:(FUItemModel *)model;


/// 加载发帽
/// @param model 发帽数据
- (void)bindHairHatWithItemModel:(FUItemModel *)model;
/// 加载背景 FUItemModel
/// @param model 背景数据
- (void)bindBackgroundWithItemModel:(FUItemModel *)model;
- (void)bindItemWithType:(FUItemType)itemType filePath:(NSString *)path;


- (void)loadHalfAvatar ;
- (void)loadFullAvatar;
/// 在半身驱动时，身体追踪时，设置avatar向上的偏移量
/// @param y_offset 偏移量
- (void)human3dSetYOffset:(float)y_offset;

@end


