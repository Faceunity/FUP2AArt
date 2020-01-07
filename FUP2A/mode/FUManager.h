//
//  FUManager.h
//  P2A
//
//  Created by L on 2018/12/17.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FUP2ADefine.h"

@class FUAvatar, FUP2AColor;
@interface FUManager : NSObject
@property (nonatomic, assign) int defalutQController;
// version info
@property (nonatomic, copy, readonly) NSString *appVersion ;
@property (nonatomic, copy, readonly) NSString *sdkVersion ;

@property (nonatomic, assign) FUAvatarStyle avatarStyle ;



@property (nonatomic, strong) NSMutableArray *avatarList ;
// 数据模型
@property (nonatomic, strong) NSArray *femaleHairs ;
@property (nonatomic, strong) NSArray *maleHairs ;
@property (nonatomic, strong) NSArray *femaleGlasses ;
@property (nonatomic, strong) NSArray *maleGlasses ;
@property (nonatomic, strong) NSArray *femaleClothes ;
@property (nonatomic, strong) NSArray *maleClothes ;
@property (nonatomic, strong) NSArray *maleBeards ;
@property (nonatomic, strong) NSArray *femaleHats ;
@property (nonatomic, strong) NSArray *maleHats ;
@property (nonatomic, strong) NSArray *femaleEyeLashs ;
@property (nonatomic, strong) NSArray *femaleEyeBrows ;
@property (nonatomic, strong) NSArray *maleEyeBrows ;

// Q数据模型
@property (nonatomic, strong) NSArray *qHairs ;
@property (nonatomic, strong) NSArray *qGlasses ;
@property (nonatomic, strong) NSArray *qClothes ;
@property (nonatomic, strong) NSArray *qMaleSuit ;  // 男套装
@property (nonatomic, strong) NSArray *qFemaleSuit ;  // 女套装
@property (nonatomic, strong) NSArray *qHats ;

@property (nonatomic, strong) NSArray *qUpper ;  // 上衣数组
@property (nonatomic, strong) NSArray *qMaleUpper ;  // 男上衣数组
@property (nonatomic, strong) NSArray *qFemaleUpper ;  // 女上衣数组
@property (nonatomic, strong) NSArray *qLower ;  // 裤子数组
@property (nonatomic, strong) NSArray *qShoes ;   // 鞋子数组
@property (nonatomic, strong) NSArray *qDecorations ; // 配饰数组


@property (nonatomic, strong) NSArray *qEyeBrow ;
@property (nonatomic, strong) NSArray *qEyeLash ;
@property (nonatomic, strong) NSArray *qBeard ;

@property (nonatomic, strong) NSArray *qFaces ;
@property (nonatomic, strong) NSArray *qEyes ;
@property (nonatomic, strong) NSArray *qMouths ;
@property (nonatomic, strong) NSArray *qNoses ;

// 颜色值
@property (nonatomic, strong) NSArray *skinColorArray ;
@property (nonatomic, strong) NSArray *lipColorArray ;
@property (nonatomic, strong) NSArray *irisColorArray ;
@property (nonatomic, strong) NSArray *hairColorArray ;
@property (nonatomic, strong) NSArray *beardColorArray ;
@property (nonatomic, strong) NSArray *glassFrameArray ;
@property (nonatomic, strong) NSArray *glassColorArray ;
@property (nonatomic, strong) NSArray *hatColorArray ;

@property (nonatomic, strong) NSDictionary *maleMeshPoints ;
@property (nonatomic, strong) NSDictionary *femaleMeshPoints ;
@property (nonatomic, strong) NSDictionary *qMeshPoints ;

@property(nonatomic,strong) NSDictionary * orginalFaceup;    // 原始的脸部点位，从defalut_facepup.json文件获取
// 当前 avatar
@property (nonatomic, strong) NSMutableArray <FUAvatar *>*currentAvatars ;

+ (instancetype)shareInstance ;
/// 绑定背景道具到controller
/// @param filePath 新背景道具路径
-(void)reloadBackGroundAndBindToController:(NSString *)filePath;
/// 获取当前q_controller 里面捏脸参数的值
-(float*)getCurrenShapeValue;
/**
 全身追踪绑定脚下阴影
 */
- (void)bindPlaneShadow;
/**
 解绑全身追踪绑定脚下阴影
 */
- (void)unBindPlaneShadow;
/**
 加载 client data
 
 @param firstSetup 是否初次 setup
 */
- (void)loadClientDataWithFirstSetup:(BOOL)firstSetup ;

/**
 背景道具是否存在

 @return 是否存在
 */
- (BOOL)isBackgroundItemExist ;
/**
 更新Cam道具
 
 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString *)camPath ;
/**
 普通模式下切换 Avatar

 @param avatar Avatar
 */
- (void)reloadRenderAvatar:(FUAvatar *)avatar ;

/**
 普通模式下切换 Avatar,不销毁controller.bundle
 
 @param avatar Avatar
 */
- (void)reloadRenderAvatarInSameController:(FUAvatar *)avatar;
- (void)reloadRenderAvatarInARModeInSameController:(FUAvatar *)avatar;
/**
 普通模式下 新增 Avatar render

 @param avatar 新增的 Avatar
 */
- (void)addRenderAvatar:(FUAvatar *)avatar ;

/**
 普通模式下 删除 Avatar render

 @param avatar 需要删除的 avatar
 */
- (void)removeRenderAvatar:(FUAvatar *)avatar ;

/**
 绑定hair_mask.bundle
 */
- (void)bindHairMask ;

/**
 销毁hair_mask.bundle
 */
- (void)destoryHairMask ;
/**
 设置手势动画
 -- 会切换 controller 所在句柄
 */
- (void)loadPoseTrackAnim;
/**
 进入 AR滤镜 模式
 -- 会切换 controller 所在句柄
 */
- (void)enterARMode ;

/**
 在 AR滤镜 模式下切换 Avatar
 
 @param avatar Avatar
 */
- (void)reloadRenderAvatarInARMode:(FUAvatar *)avatar ;

/**
 切换 AR滤镜

 @param filePath AR滤镜 路径
 */
- (void)reloadARFilterWithPath:(NSString *)filePath ;
/**
 在正常渲染avatar的模式下，切换AR滤镜
 
 @param filePath  滤镜 路径
 */
- (void)reloadFilterWithPath:(NSString *)filePath ;

/// 根据单个发型名称去deform头发
/// @param avatar 需要deform的avatar
/// @param hairName 需要deform的发型名称
-(void)createHairBundles:(FUAvatar *)avatar WithHairName:(NSString *)hairName;
/**
 检测人脸接口

 @param sampleBuffer  图像数据
 @return              图像数据
 */
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer ;
/**
 检测人脸接口
 
 @param sampleBuffer  图像数据
 @return              图像数据
 */
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer CurrentlLightingValue:(float *)currntLightingValue;
// 处理前置摄像头的图像
-(CVPixelBufferRef)dealTheFrontCameraPixelBuffer:(CVPixelBufferRef) pixelBuffer;
/**
 Avatar 处理接口

 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks;
/**
 Avatar 语音驱动模式下的处理接口
 
 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemInFUStaWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks;
/**
 Avatar 截图
 
 @param pixelBuffer 图像数据
 @return            处理之后的图像
 */
- (CVPixelBufferRef)screenshotP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;
/**
 AR 滤镜处理接口

 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer ;
/**
 AR 滤镜处理接口

 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr;
/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @param human3dPtr  human3d.bundle 的句柄
 @param renderMode  FURenderCommonMode 为预览模式，FURenderPreviewMode为人脸追踪模式
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr RenderMode:(FURenderMode)renderMode;
/**
 Avatar 生成
 
 @param data    服务端拉流数据
 @param name    Avatar 名字
 @param gender  Avatar 性别
 @return        生成的 Avatar
 */
- (FUAvatar *)createAvatarWithData:(NSData *)data avatarName:(NSString *)name gender:(FUGender)gender ;


-(void)reCreateHairBundles:(FUAvatar *)avatar;
/**
 是否正在生成 Avatar 模型

 @return 是否正在生成
 */
- (BOOL)isCreatingAvatar ;

/**
 捏脸之后生成新的 Avatar

 @param coeffi  捏脸参数
 @param deform  是否 deform
 @return        新的 Avatar
 */
- (FUAvatar *)createPupAvatarWithCoeffi:(float *)coeffi DeformHead:(BOOL)deform ;

/**
 拍摄检测

 @return 检测结果
 */
- (NSString *)photoDetectionAction ;

/**
 设置最多识别人脸的个数

 @param num 最多识别人脸个数
 */
- (void)setMaxFaceNum:(int)num ;

/**
 获取人脸矩形框

 @return 人脸矩形框
 */
- (CGRect)getFaceRect ;

@end
