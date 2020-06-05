//
//  FUManager.h
//  P2A
//
//  Created by L on 2018/12/17.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FURenderer.h"
#import "FUFigureDefine.h"

@class FUAvatar, FUP2AColor;
@interface FUManager : NSObject
{
    // render 句柄
    int mItems[7] ;

    
    // ar模式下 render 句柄
    int arItems[2] ;
    @public void * _human3dPtr;
    // 输出 buffer
    CVPixelBufferRef renderTarget;
    // 截图
    CVPixelBufferRef screenShotTarget;
    // 截图
    CVPixelBufferRef bodyTrackBuffer;
    // 图像宽高
    CGSize frameSize ;
    // 光线检测
    float lightingValue ;
    
    __block BOOL isCreatingAvatar ;
    
    int zuojiao_plane_mg_ptr;   // 左脚的阴影句柄
    int youjiao_plane_mg_ptr;   // 右脚的阴影句柄
    int hair_mask_ptr;  // hair_mask 句柄
    int q_controller_config_ptr;   // controller 配置文件道具句柄
    int q_controller_bg_ptr;   // 绑定在q_controller上的背景道具句柄
    int q_controller_cam;   // 绑定在q_controller上的_cam.bundle道具句柄
    int light_ptr;   // 绑定在q_controller上的_cam.bundle道具句柄
}

@property void* faceCapture ;
@property BOOL useFaceCapure;
@property BOOL isFaceCaptureEnabled;
@property (nonatomic, strong) FURotatedImage *rotatedImageManager;

@property (nonatomic, assign) CGSize outPutSize;  //输出图片尺寸
// 同步信号量
@property (nonatomic, strong)dispatch_semaphore_t signal;
//@property (nonatomic, assign) BOOL isStopRefreshBuffer; //是否需要停止形象刷新，用于套装和上下衣、背景替换等情况，避免出现闪现中间动画

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
@property (nonatomic, strong) NSMutableDictionary *typeInfoDict;  //选中的道具分类的序号
@property (nonatomic, assign) BOOL isGlassesColor ; //是否是镜片颜色

@property (nonatomic, assign) FUEditType selectedEditType; //编辑大类
@property (nonatomic, strong) NSMutableDictionary *subTypeSelectedDict; //子类别选择字典
//@property (nonatomic, assign) BOOL isHiddenDecView ; //是否隐藏了道具列表
@property (nonatomic, assign) NSInteger iSelectedBgSubtypeIndex; //选择的背景子类别编号

@property (nonatomic, strong) NSMutableArray *itemTypeArray; //道具类别列表
@property (nonatomic, strong) NSMutableArray *itemNameArray; //道具中文名称列表
@property (nonatomic, strong) NSMutableDictionary *itemsDict; //道具数组字典
@property (nonatomic, strong) NSMutableDictionary *selectedItemIndexDict; //道具选中字典
@property (nonatomic, strong) NSMutableDictionary *colorDict;  //颜色字典
@property (nonatomic, strong) NSMutableDictionary *selectedColorDict;  //颜色选中字典
@property (nonatomic, copy) NSString *shapeModeKey;  //捏脸模式类别

@property (nonatomic, strong) NSDictionary *qMeshPoints;

@property (nonatomic, assign) BOOL isPlayingSpecialAni;  //是否正在进行特殊动画（出场动画，编辑页返回动画等仅播放一次的动画）
@property (nonatomic, copy) NSString *nextSpecialAni;  //等待播放的特殊动画，在当前特殊动画执行完成后执行
@property (nonatomic, assign) BOOL isEnterEditView;

// =======================   多选 类型 进行单独管理  ======================
// 美妆类型数组
@property (nonatomic, strong)NSArray * makeupTypeArray;
// 当前选中的美妆类型，仅限于主动选择和返回、撤销时的加载
@property (nonatomic, strong) NSString * currentSelectedMakeupType;
#define FUDecorationsString @"decorations"
// 配饰类型数组
@property (nonatomic, strong)NSArray * decorationTypeArray;
// 当前选中的配饰类型，仅限于主动选择和返回、撤销时的加载
@property (nonatomic, strong) NSString * currentSelectedDecorationType;

/// 获取实例
+ (instancetype)shareInstance;
- (CVPixelBufferRef)renderBodyTrackWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr RenderMode:(FURenderMode)renderMode;
/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @param human3dPtr  human3d.bundle 的句柄
 @param renderMode  FURenderCommonMode 为预览模式，FURenderPreviewMode为人脸追踪模式
 @param isLandscape 是否输出横屏视频
 @param landmarks 脸部点位
 @param landmarksLength 脸部点位数组的长度
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderBodyTrackAdjustAssginOutputSizeWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks LandmarksLength:(int)landmarksLength;
/**
 加载 client date
 b
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
//
///**
// AR 滤镜处理接口 同时返回捕捉到的脸部点位
//
// @param pixelBuffer 图像数据
// @return            处理之后的图像数据
// */
//- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer Landmarks:(float *)landmarks LandmarksLength:(int)landmarksLength;


/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 @param rotationMode 旋转模式
 @param rotation_mode w.r.t to rotation the the camera view, 0=0^deg, 1=90^deg, 2=180^deg, 3=270^deg
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer rotationMode:(int)rotationMode;

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

/// 复制CVPixelBufferRef，需要外部调用负责释放返回值
/// @param pixelBuffer 输入的 CVPixelBufferRef
- (CVPixelBufferRef)copyPixelBuffer:(CVPixelBufferRef)pixelBuffer;
/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @param human3dPtr  human3d.bundle 的句柄
 @param renderMode  FURenderCommonMode 为预览模式，FURenderPreviewMode为人脸追踪模式
 @param isLandscape 是否输出横屏视频
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr RenderMode:(FURenderMode)renderMode landscape:(BOOL)isLandscape view0ratio:(CGFloat)view0ratio resolution:(double)resolution;

#pragma mark ------ 设置颜色 ------
/// 设置颜色
/// @param color 颜色模型
/// @param type 颜色类别
- (void)configColorWithColor:(FUP2AColor *)color ofType:(FUFigureColorType)type;


- (void)configSkinColorWithProgress:(double)progress  isPush:(BOOL)isPush;
/// 重置美妆类型
-(void)resetMakeupItems;
/// 在配饰界面，当选择第 0 个item，进行回退时，恢复之前多选状态
/// @param model 专门记录配饰多选状态的model
-(void)reserveMultipleDecorationItemState:(FUMultipleRecordItemModel*)model;
/// 重置配饰类型
-(void)resetDecorationItems;

/// @param oldModel 记录多状态的model
/// @param currentModel 当前model
/// @param isReversed 是否逆序
-(void)dealMutualExclusion:(FUMultipleRecordItemModel *)oldModel current:(FUMultipleRecordItemModel *)currentModel direction:(BOOL)isReversed;
///删除已经绑定道具
/// @param model 道具相关信息
- (void)removeItemWithModel:(FUItemModel *)model AndType:(NSString *)type;
#pragma mark ------ 绑定道具 ------
/// 在美妆界面，当选择第 0 个item，进行回退时，恢复之前多选状态
/// @param model 专门记录美妆多选状态的model
-(void)reserveMultipleMakeupItemState:(FUMultipleRecordItemModel*)model;
/// 绑定道具
/// @param model 道具相关信息
- (void)bindItemWithModel:(FUItemModel *)model;

#pragma mark ------ 背景 ------

/// 加载默认背景
- (void)loadDefaultBackGroundToController;


- (void)loadKetingBackGroundToController;

- (void)loadYuanlinBackGroundToController;

- (void)loadWuguanBackGroundToController;

/// 绑定背景道具到controller
/// @param filePath 新背景道具路径
- (void)reloadBackGroundAndBindToController:(NSString *)filePath;



#pragma mark ------ Cam ------
/**
 更新Cam道具

 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString * __nullable)camPath ;
/**
 更新Cam道具,不使用信号量，防止死锁
 
 @param camPath 辅助道具路径
 */
- (void)reloadCamItemNoSignalWithPath:(NSString *)camPath;

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


/**
 设置手势动画
 -- 会切换 controller 所在句柄
 */
- (void)loadPoseTrackAnim;
/**
 为形象的左脚和右脚分别添加脚下阴影
 */
- (void)bindPlaneShadow ;
/**
 分别解绑形象的左脚和右脚的脚下阴影
*/
- (void)unBindPlaneShadow ;
/**
* //AR模式下，为了支持旋转屏幕时，同时旋转头发遮罩
* //0表示设备未旋转，1表示逆时针旋转90度，2表示逆时针旋转180度，3表示逆时针旋转270度
@param orientation 当前设备的方向
*/
-(void)setScreenOrientation:(UIInterfaceOrientation)orientation;

#pragma mark ------ 形象数据处理 ------
/// 进入编辑模式
- (void)enterEditMode;
/// 获取当前形象的道具和颜色选中情况
- (void)getSelectedInfo;
/// 判断形象是否编辑过
- (BOOL)hasEditAvatar;

////如果是预制形象生成新的形象，如果不是预制模型保存新的信息
- (void)saveAvatar;

/// 将形象信息恢复到编辑前
- (void)reloadItemBeforeEdit;


#pragma mark ------ 颜色 ------
- (FUP2AColor *)getSkinColorWithProgress:(double)progress;
/// 根据类别获取选中的颜色编号
/// @param type 颜色类别
- (NSInteger)getSelectedColorIndexWithType:(FUFigureColorType)type;
//
///// 根据类别获取选中的颜色
- (FUP2AColor *)getSelectedColorWithType:(FUFigureColorType)type;
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
- (NSArray *)getColorArrayWithType:(FUFigureColorType)type;

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
/// 生成并复制发帽到形象目录
/// @param avatar 形象模型
- (void)createAndCopyHairHatBundlesWithAvatar:(FUAvatar *)avatar withHairHatModel:(FUItemModel *)model;
/**
 
 普通模式下 新增 Avatar render
 
 @param avatar 新增的 Avatar
 */
- (void)addRenderAvatar:(FUAvatar *)avatar :(BOOL)isBg;
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

/// 重新加载avatar的所有资源
/// @param avatar 目标avatar
/// @param isBg 是否渲染背景
- (void)reloadAvatarToControllerWithAvatar:(FUAvatar *)avatar :(BOOL)isBg;
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
/// 设置instanceId
/// @param _id instanceId
-(void)setInstanceId:(int)_id;
/// 设置背景的instanceId，用于多人模式下
-(void)setBackgroundInstanceId;
#pragma mark - 特殊动画
///  设置一个等待执行的特殊动画
- (void)setNextSpecialAnimation;

/// 清除正在等待执行的特殊动画
- (void)removeNextSpecialAnimation;

/// 播放在等待中的特殊动画
- (void)playNextSpecialAnimation;

/// 立即播放一个特殊动画
- (void)playSpecialAnimation;

-(CVPixelBufferRef)dealTheFrontCameraPixelBuffer:(CVPixelBufferRef) pixelBuffer returnNewBuffer:(BOOL)returnNewBuffer;
/// 选择 CVPixelbuffer 的方法
/// @param pixelBuffer 输入源
/// @param rotationMode 旋转模式 FURotationMode0 FURotationMode90 FURotationMode180 FURotationMode270
/// @param flipX 是否水平镜像
/// @param flipY 是否垂直镜像
/// @param returnNewBuffer 是否创建新的buffer，YES为创建，则需要外部销毁返回值，NO为 不创建，不需要外部销毁返回值
-(CVPixelBufferRef)rotateImage:(CVPixelBufferRef) pixelBuffer rotationMode:(int)rotationMode flipX:(BOOL)flipX flipY:(BOOL)flipY returnNewBuffer:(BOOL)returnNewBuffer;
#pragma mark ----- 编辑
- (void)configEditInfo;
- (NSArray *)getCurrentTypeArray;
- (NSString *)getSubTypeNameWithIndex:(NSInteger)index;
- (void)setSubTypeSelectedIndex:(NSInteger)index;
/// 美妆类型，当前选中的美妆
- (FUMakeupItemModel*)getMakeupCurrentSelectedModel;
- (void)setSubTypeSelectedIndex:(NSInteger)index withEditType:(FUEditType)type;
- (NSInteger)getSubTypeSelectedIndex;
- (NSString *)getSubTypeKeyWithIndex:(NSInteger)index;
/// 获取当前类别的道具数组
- (NSArray *)getItemArrayOfSelectedSubType;
/// 获取美妆选中的道具编号  多选
- (NSArray<NSNumber*>*)getSelectedItemIndexOfMakeup;
/// makeup 类型存在有效的选项
-(BOOL)makeupHasValiedSeletedItem;
/// 获取配饰选中的道具编号  多选
- (NSArray<NSNumber*>*)getSelectedItemIndexOfDecoration;
/// 配饰 类型存在有效的选项
-(BOOL)decorationHasValiedSeletedItem;
- (NSInteger)getSelectedItemIndexOfSelectedSubType;
/// 从编辑大类数组里面获取图片名称
/// @param index 子类在编辑大类中的序号
/// @param array 大类数组
- (NSString *)getSubTypeImageNameWithIndex:(NSInteger)index  currentTypeArr:(NSArray *)array;
/// 获取当前选中的道具类别
- (NSString *)getSelectedType;
//
/// 获取当前类别的捏脸model
- (FUItemModel *)getNieLianModelOfSelectedType;


#pragma mark - Resolution
/// 设置输出精度与相机输入一致，目前相机设置为720*1280
- (void)setOutputResolutionAdjustCamera;
/// 根据屏幕尺寸设置输出精度
- (void)setOutputResolutionAdjustScreen;
/// 设置指定输出尺寸
/// @param width 指定图像宽
/// @param height 指定图像高
- (void)setOutputResolutionWithWidth:(CGFloat)width height:(CGFloat)height;

@end
