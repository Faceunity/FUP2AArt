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
@property (nonatomic, strong) NSArray *qClothes ; ;
@property (nonatomic, strong) NSArray *qHats ;
@property (nonatomic, strong) NSArray *qShoes ;
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

// 当前 avatar
@property (nonatomic, strong) NSMutableArray <FUAvatar *>*currentAvatars ;

+ (instancetype)shareInstance ;

/**
 加载 client data
 
 @param firstSetup 是否初次 setup
 */
- (void)loadClientDataWithFirstSetup:(BOOL)firstSetup ;

/**
 加载背景道具

 @param filePath 背景道具所在路径
 */
- (void)reloadBackGroundWithFilePath:(NSString *)filePath ;

/**
 背景道具是否存在

 @return 是否存在
 */
- (BOOL)isBackgroundItemExist ;

/**
 普通模式下切换 Avatar

 @param avatar Avatar
 */
- (void)reloadRenderAvatar:(FUAvatar *)avatar ;

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
 检测人脸接口

 @param sampleBuffer  图像数据
 @return              图像数据
 */
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer ;


/**
 Avatar 处理接口

 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks;

/**
 AR 滤镜处理接口

 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer ;

/**
 Avatar 生成
 
 @param data    服务端拉流数据
 @param name    Avatar 名字
 @param gender  Avatar 性别
 @return        生成的 Avatar
 */
- (FUAvatar *)createAvatarWithData:(NSData *)data avatarName:(NSString *)name gender:(FUGender)gender ;

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

// 批量生成
- (void)batchCreatingAvatarsWithImageInfos:(NSArray *)imageInfos Completion:(void (^)(void))handle ;
@end
