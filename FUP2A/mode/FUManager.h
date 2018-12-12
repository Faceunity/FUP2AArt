//
//  FUManager.h
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FUAvatar.h"
#import "FUP2ADefine.h"

@interface FUManager : NSObject

@property (nonatomic, copy, readonly) NSString *appVersion ;
@property (nonatomic, copy, readonly) NSString *sdkVersion ;
@property (nonatomic, assign) BOOL isDeform ;
@property (nonatomic, assign) BOOL showDebugInfo ;

// 数据模型
@property (nonatomic, strong) NSMutableArray *avatars ;
@property (nonatomic, strong) NSArray *femaleHairs ;
@property (nonatomic, strong) NSArray *maleHairs ;
@property (nonatomic, strong) NSArray *femaleGlasses ;
@property (nonatomic, strong) NSArray *maleGlasses ;
@property (nonatomic, strong) NSArray *femaleClothes ;
@property (nonatomic, strong) NSArray *maleClothes ;
@property (nonatomic, strong) NSArray *maleBeards ;
@property (nonatomic, strong) NSArray *femaleHats ;
@property (nonatomic, strong) NSArray *maleHats ;

// 颜色值
@property (nonatomic, strong) NSArray *skinColorArray ;
@property (nonatomic, strong) NSArray *lipColorArray ;
@property (nonatomic, strong) NSArray *irisColorArray ;
@property (nonatomic, strong) NSArray *hairColorArray ;
@property (nonatomic, strong) NSArray *beardColorArray ;
@property (nonatomic, strong) NSArray *glassFrameArray ;
@property (nonatomic, strong) NSArray *glassColorArray ;
@property (nonatomic, strong) NSArray *hatColorArray ;

// 当前 avatar
@property (nonatomic, strong) FUAvatar *currentAvatar;

+ (instancetype)shareInstance ;

// 加载 avatar
- (void)loadAvatar:(FUAvatar *)avatar ;
// 根据路径加载道具
- (void)loadItemWithtype:(FUItemType)itemType filePath:(NSString *)path ;

// 检测人脸处理接口
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer ;

// Avatar 处理接口
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks;

//设置缩放参数
- (void)setScaleDelta:(float)scale ;

//设置旋转参数
- (void)setRotDelta:(float)rot Horizontal:(BOOL)hor ;

// creat avatar
- (FUAvatar *) createAvatarWithData:(NSData *)data FileName:(NSString *)fileName isMale:(BOOL)male ;

// 加载待机动画
- (void)loadStandbyAnimation ;
// 去除待机动画
- (void)removeStandbyAnimation ;
// 面部追踪 pose
- (void)loadPose ;
// 进入/退出 面部追踪
- (void)enterTrackAnimationMode ;
- (void)quitTrackAnimationMode ;

// 拍摄检测
- (int)photoDetectionAction ;

// 进入/退出 AR
- (void)enterARMode ;
- (void)quitARMode ;

// AR 滤镜 item
- (void)loadARFilter:(NSString *)filterName ;
// AR 滤镜 mode
- (void)loadARModel:(FUAvatar *)avatar ;

// AR滤镜 处理接口
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer ;

// 进入/退出 捏脸模式
- (void)enterFacepupMode ;
- (void)quitFacepupMode ;

/**    ---- 捏脸参数改变 ----     **/
// set face shape params
- (void)facepopSetShapParam:(NSString *)key level:(double)level ;
// get face shape params
- (double)getFacepopParamWith:(NSString *)key ;

// skin color index
- (int)getSkinColorIndex ;
// lip color index
- (int)getLipColorIndex ;
// iris color index
- (int)getIrisColorIndex ;

// set skin color
- (void)facepopSetSkinColor:(double*)color ;
// set lip color
- (void)facepopSetLipColor:(double*)color;
// set iris color
- (void)facepopSetIrisColor:(double*)color;
// set hair color
- (void)facepopSetHairColor:(double*)color intensity:(double)intensity ;
// set galsses color
- (void)facepopSetGlassesColor:(double*)color;
// set glasses frame color
- (void)facepopSetGlassesFrameColor:(double*)color;
// set beard color
- (void)facepopSetBeardColor:(double*)color;
// set hat color
- (void)facepopSetHatColor:(double*)color;

// set current avatar default color
- (void)setDefaultColorForAvatar:(FUAvatar *)avatar;

// 捏脸后 生成新的模型
- (BOOL)createPupAvatarWithCoeffi:(float *)coeffi colorIndex:(float)color DeformHead:(BOOL)deform ;

// 最大识别人脸数量
- (void)maxFace:(int)num ;

// 获取人脸框
- (CGRect)getFaceRect ;

@end
