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
#import "FURenderer.h"
#import "FUFigureDefine.h"
#import "FUItemModel.h"

@class FUAvatar, FUP2AColor;
@interface FUManager : NSObject
{
    // render 句柄
    int mItems[7] ;
    // 同步信号量
    dispatch_semaphore_t signal;
    
    // ar模式下 render 句柄
    int arItems[2] ;
    // 输出 buffer
    CVPixelBufferRef renderTarget;
    // 截图
    CVPixelBufferRef screenShotTarget;
    // 图像宽高
    CGSize frameSize ;
    // 光线检测
    float lightingValue ;
    
    __block BOOL isCreatingAvatar ;
    
    int plane_mg_ptr;   // 全身驱动时的阴影句柄
    int hair_mask_ptr;  // hair_mask 句柄
    int q_controller_config_ptr;   // controller 配置文件道具句柄
    int q_controller_bg_ptr;   // 绑定在q_controller上的背景道具句柄
    int q_controller_cam;   // 绑定在q_controller上的_cam.bundle道具句柄
}

@property void* faceCapture ;
@property BOOL useFaceCapure;
@property BOOL isFaceCaptureEnabled;
@property (nonatomic, strong) FURotatedImage *rotatedImageManager;

@property (nonatomic, assign) BOOL isBindCloths;

@property (nonatomic, assign) int defalutQController;
// version info
@property (nonatomic, copy, readonly) NSString *appVersion;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
// 形象数据
@property (nonatomic, assign) FUAvatarStyle avatarStyle ;
@property (nonatomic, strong) NSMutableArray *avatarList ;
@property (nonatomic, strong) FUAvatar *beforeEditAvatar;

// 当前 avatar
@property (nonatomic, strong) NSMutableArray <FUAvatar *>*currentAvatars ;

// 编辑页数据
@property (nonatomic, assign) NSInteger itemTypeSelectIndex;  //选中的道具分类的序号
@property (nonatomic, strong) NSMutableArray *itemTypeArray; //道具类别列表
@property (nonatomic, strong) NSMutableArray *itemNameArray; //道具中文名称列表
@property (nonatomic, strong) NSMutableDictionary *itemsDict; //道具数组字典
@property (nonatomic, strong) NSMutableDictionary *selectedItemIndexDict; //道具选中字典
@property (nonatomic, strong) NSMutableDictionary *colorDict;  //颜色字典
@property (nonatomic, strong) NSMutableDictionary *selectedColorDict;  //颜色选中字典
@property (nonatomic, copy) NSString *shapeModeKey;  //捏脸模式类别

@property (nonatomic, strong) NSDictionary *qMeshPoints;


/// 获取实例
+ (instancetype)shareInstance;

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



#pragma mark ------ PixelBuffer
//创建一个空buffer
- (void)initPixelBuffer;

/**
 检测人脸接口
 
 @param sampleBuffer  图像数据
 @return              图像数据
 */
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer CurrentlLightingValue:(float *)currntLightingValue;

/**
 AR 滤镜处理接口 同时返回捕捉到的脸部点位
 
 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer Landmarks:(float *)landmarks LandmarksLength:(int)landmarksLength;

/**
 Avatar 处理接口
 
 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks LandmarksLength:(int)landmarksLength;

/**
 Avatar 处理接口
 
 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer HightResolution:(float)rate;

// 处理前置摄像头的图像
- (CVPixelBufferRef)dealTheFrontCameraPixelBuffer:(CVPixelBufferRef) pixelBuffer;

#pragma mark ------ 脸部识别
/// 重置脸部识别，切换摄像头时使用
- (void)faceCapureReset;

/// 是否识别到人脸
- (int)faceCaptureGetResultIsFace;




#pragma mark ------ 设置颜色 ------
/// 设置颜色
/// @param color 颜色模型
/// @param type 颜色类别
- (void)configColorWithColor:(FUP2AColor *)color ofType:(FUFigureColorType)type;


- (void)configSkinColorWithProgress:(double)progress  isPush:(BOOL)isPush;
#pragma mark ------ 绑定道具 ------
/// 绑定道具
/// @param model 道具相关信息
- (void)bindItemWithModel:(FUItemModel *)model;

#pragma mark ------ 背景 ------
/// 加载默认背景
- (void)loadDefaultBackGroundToController;

/// 绑定背景道具到controller
/// @param filePath 新背景道具路径
- (void)reloadBackGroundAndBindToController:(NSString *)filePath;

#pragma mark ------ Cam ------
/**
 更新Cam道具

 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString * __nullable)camPath ;

#pragma mark ------ hair_mask ------
/**
 绑定hair_mask.bundle
 */
- (void)bindHairMask ;

/**
 销毁hair_mask.bundle
 */
- (void)destoryHairMask ;
//
//#pragma mark ------ 绑定底层方法 ------
///// 重新绑定道具
///// @param filePath 新的道具路径
///// @param ptr 道具句柄
//- (void)rebindItemToControllerWithFilepath:(NSString *)filePath withPtr:(int *)ptr;
//
///// 绑定道具
///// @param filePath 道具路径
//- (int)bindItemToControllerWithFilepath:(NSString *)filePath;




#pragma mark ------ 形象数据处理 ------
/// 进入编辑模式
- (void)enterEditMode;

/// 判断形象是否编辑过
- (BOOL)hasEditAvatar;

////如果是预制形象生成新的形象，如果不是预制模型保存新的信息
- (void)saveAvatar;

/// 将形象信息恢复到编辑前
- (void)reloadItemBeforeEdit;

#pragma mark ------ 道具编辑相关 ------
/// 获取当前选中的道具类别
- (NSString *)getSelectedType;
//
/// 获取当前类别的捏脸model
- (FUItemModel *)getNieLianModelOfSelectedType;

/// 获取当前类别选中的道具编号
- (NSInteger)getSelectedItemIndexOfSelectedType;
//
///// 设置选中道具编号
///// @param index 道具编号
//- (void)setSelectedItemIndex:(NSInteger)index;
//
/// 获取当前类别的道具数组
- (NSArray *_Nullable)getItemArrayOfSelectedType;

#pragma mark ------ 颜色 ------
- (FUP2AColor *)getSkinColorWithProgress:(double)progress;
/// 根据类别获取选中的颜色编号
/// @param type 颜色类别
- (NSInteger)getSelectedColorIndexWithType:(FUFigureColorType)type;
//
///// 根据类别获取选中的颜色
//- (FUP2AColor *)getSelectedColorWithType:(FUFigureColorType)type;
//
///// 设置对应类别的选中颜色编号
///// @param index 选中的颜色编号
///// @param type 颜色类别
//- (void)setSelectColorIndex:(NSInteger)index ofType:(FUFigureColorType)type;

/// 根据类别获取对应颜色数组的长度
/// @param type 颜色类别
- (NSInteger)getColorArrayCountWithType:(FUFigureColorType)type;
//
///// 根据类别获取对应颜色数组
///// @param type 颜色类别
//- (NSArray *)getColorArrayWithType:(FUFigureColorType)type;

/// 根据颜色类别获取颜色类别关键字
/// @param type 颜色类别
- (NSString *)getColorKeyWithType:(FUFigureColorType)type;

/// 获取颜色模型
/// @param type 颜色类别
/// @param index 颜色编号
- (FUP2AColor *)getColorWithType:(FUFigureColorType)type andIndex:(NSInteger)index;







///// 加载形象列表
//- (void)loadAvatarList;
//

#pragma mark  ------ 生成形象 ------
/// 根据形象信息字典生成形象模型
/// @param dict 形象信息字典
- (FUAvatar *)getAvatarWithInfoDic:(NSDictionary *)dict;


#pragma mark ------ 拍照生成新形象 ------
/**
 Avatar 生成
 
 @param data    服务端拉流数据
 @param name    Avatar 名字
 @param gender  Avatar 性别
 @return        生成的 Avatar
 */
- (FUAvatar *)createAvatarWithData:(NSData *)data avatarName:(NSString *)name gender:(FUGender)gender;


/// 生成并复制新的hairbundle
/// @param avatar 相关形象
- (void)createAndCopyAllHairBundlesWithAvatar:(FUAvatar *)avatar;

- (void)createAndCopyHairBundlesWithAvatar:(FUAvatar *)avatar withHairModel:(FUItemModel *)model;
//
//#pragma mark ------ 加载形象 ------
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

/// 加载形象
/// @param avatar 形象模型
- (void)reloadAvatarToControllerWithAvatar:(FUAvatar *)avatar;

/**

 普通模式下切换 Avatar,不销毁controller.bundle
 
 @param avatar Avatar
 */
- (void)reloadRenderAvatarInARModeInSameController:(FUAvatar *)avatar;
//
//
#pragma mark ------ 数据处理 ------
/**
 拍摄检测

 @return 检测结果
 */
- (NSString *)photoDetectionAction ;

/**
 获取人脸矩形框

 @return 人脸矩形框
 */
- (CGRect)getFaceRect ;


#pragma mark ----- AR
/**
 进入 AR滤镜 模式
 -- 会切换 controller 所在句柄
 */
- (void)enterARMode ;

/**
 设置最多识别人脸的个数

 @param num 最多识别人脸个数
 */
- (void)setMaxFaceNum:(int)num ;

/**
 切换 AR滤镜

 @param filePath AR滤镜 路径
 */
- (void)reloadARFilterWithPath:(NSString *)filePath;

/**
 在正常渲染avatar的模式下，切换AR滤镜
 
 @param filePath  滤镜 路径
 */
- (void)reloadFilterWithPath:(NSString *)filePath;



@end
