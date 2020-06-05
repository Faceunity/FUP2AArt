//
//  FUAvatar.m
//  P2A
//
//  Created by L on 2018/12/15.
//  Copyright © 2018年 L. All rights reserved.
//
#include "objc/runtime.h"

@interface FUAvatar ()
@property (nonatomic, strong) dispatch_semaphore_t signal ;
@end

@implementation FUAvatar
-(void)setEyeBrow:(FUItemModel *)eyeBrow{
   _eyeBrow = eyeBrow;
}
- (instancetype)init
{
	self = [super init];
	if (self)
	{
		self.signal = [FUManager shareInstance].signal;
	}
	return self ;
}

#pragma mark ------ SET/GET ------
// 图片路径
-(NSString *)imagePath
{
    if (!_imagePath)
    {
        _imagePath = [[self filePath] stringByAppendingPathComponent:@"image.png"];
    }
    return _imagePath ;
}

/**
 avatar 模型保存的根目录
 
 @return  avatar 模型保存的根目录
 */
- (NSString *)filePath
{
    NSString *filePath ;
    if (self.defaultModel)
    {
        filePath = [[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:self.name];
    }
    else
    {
        filePath = [documentPath stringByAppendingPathComponent:self.name];
    }
    return filePath ;
}

/**
 获取 controller 所在句柄
 
 @return 返回 controller 所在句柄
 */
- (int)getControllerHandle
{
    return  items[FUItemTypeController];
}

/**
 销毁此模型
 -- 包括 controller, head, body, hair, clothes, glasses, beard, hat, animatiom, arfilter.
 */
- (void)destroyAvatar {
    
    // 先销毁普通道具
    for (int i = 1 ; i < sizeof(items)/sizeof(int); i ++) {
        if (items[i] != 0) {
            
            // 先解绑
            fuUnbindItems(items[FUItemTypeController], &items[i], 1) ;
            // 再销毁
            [FURenderer destroyItem:items[i]];
            items[i] = 0 ;
        }
    }
    // 再销毁 controller
    [FURenderer destroyItem:items[FUItemTypeController]];
    items[FUItemTypeController] = 0 ;
}
/**
 销毁此模型,只包括avatar资源
 -- 包括 , head, body, hair, clothes, glasses, beard, hat, animatiom, arfilter.
 */
- (void)destroyAvatarResouce {
    
    // 先销毁普通道具
    for (int i = 1 ; i < sizeof(items)/sizeof(int); i ++) {
        if (items[i] != 0) {
            
            // 先解绑
            fuUnbindItems(items[FUItemTypeController], &items[i], 1) ;
            // 再销毁
            [FURenderer destroyItem:items[i]];
            items[i] = 0 ;
        }
    }
    // 销毁临时道具
    [self destoryAllTmpItems];
}


/**
 更新Cam道具

 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString * __nullable)camPath {
	[self loadItemWithtype:FUItemTypeCamera filePath:camPath];
}
/**
 更换动画
 
 @param animationPath 新动画所在路径
 */
- (void)reloadAnimationWithPath_NoSignal:(NSString *)animationPath
{
    [self loadItemWithtype:FUItemTypeAnimation filePath:animationPath];
}
/**
 更换动画
 
 @param animationPath 新动画所在路径
 */
- (void)reloadAnimationWithPath:(NSString *)animationPath
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER) ;
    [self loadItemWithtype:FUItemTypeAnimation filePath:animationPath];
	dispatch_semaphore_signal(self.signal) ;
}

/**
 更新辅助道具
 
 @param tmpPath 辅助道具路径
 */
- (void)reloadTmpItemWithPath:(NSString *)tmpPath
{
    [self loadItemWithtype:FUItemTypeTmp filePath:tmpPath];
}

// 加载controller道具
//- (void)reloadControllerItemFilePath:(NSString *)path {}
// 加载普通道具
- (void)loadItemWithtype:(FUItemType)itemType filePath:(NSString *)path {
    
        BOOL isDirectory;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    
    if (path == nil || !isExist || isDirectory) {
        
        [self destroyItemWithType:itemType];
        
                return ;
    }
    // 创建道具
    int tmpHandle = [FURenderer itemWithContentsOfFile:path];
    
    // 销毁同类道具
    [self destroyItemWithType:itemType];
    
    // 绑定到 controller 上
    items[itemType] = tmpHandle;
    
    if (items[FUItemTypeController] && itemType > 0) {
        [FURenderer bindItems:items[FUItemTypeController] items:&items[itemType] itemsCount:1] ;
    }
    
    }
// 添加普通道具，不销毁老的同类道具

/// 添加临时道具，不销毁老的同类道具
/// @param handle 记录当前的句柄
/// @param path 动画文件路径
- (void)addItemWithHandle:(int*)handle filePath:(NSString *)path {
    
        // 创建道具
    int tmpHandle = [FURenderer itemWithContentsOfFile:path];
    
    
    // 绑定到 controller 上
    *handle = tmpHandle;
    
    if (items[FUItemTypeController]) {
        [FURenderer bindItems:items[FUItemTypeController] items: handle itemsCount:1] ;
    }
        
}

/// 获取当前动画句柄
-(int)getCurrentAnimationHandle{
    return items[FUItemTypeAnimation];
}
/// 获取当前动画播放进度
/// 获取某个动画的播放进度
// 进度0-0.9999为第一次循环，1-1.9999为第二次循环，以此类推
// 即使play_animation_once,进度也会突破1.0，照常运行
//
// @param anim_id 当前动画的句柄
-(float)getAnimateProgress{
    int anim_id = [self getCurrentAnimationHandle];
    if (anim_id > 0) {
        
        NSString * paramDicStr = [NSString stringWithFormat:@"{\"name\":\"get_animation_progress\",\"anim_id\":%d}",anim_id];
        return  fuItemGetParamd(items[FUItemTypeController],paramDicStr.UTF8String);
    }else{
        return 0;
    }
}

// 销毁某个道具
- (void)destroyItemWithType:(FUItemType)itemType {
    
    if (items[itemType] != 0) {
        
        // 解绑
        if (items[FUItemTypeController] && itemType > 0) {
            [FURenderer unBindItems:items[FUItemTypeController] items:&items[itemType] itemsCount:1];
        }
        // 销毁
        [FURenderer destroyItem:items[itemType]];
        items[itemType] = 0;
    }
}

/// 获取 tmpItems 第一个空闲的位置
-(int)getTmpItemsNullIndex{
    for (int i = 0; i < tmpItemsCount; i++) {
        if (tmpItems[i] == 0) {
            return i;
        }
    }
    return tmpItemsCount - 1;
}
// 添加临时道具
- (void)addTmpItemFilePath:(NSString *)path{
    int validIndex = [self getTmpItemsNullIndex];
    [self addItemWithHandle:&tmpItems[validIndex] filePath:path];
}
/// 销毁所有的临时句柄
-(void)destoryAllTmpItems{
    for (int i = 0; i < tmpItemsCount; i++) {
        if (tmpItems[i] > 0) {
            
            // 解绑
            [FURenderer unBindItems:items[FUItemTypeController] items:&tmpItems[i] itemsCount:1];
            // 销毁
            [FURenderer destroyItem:tmpItems[i]];
            tmpItems[i] = 0;
        }
    }
}
// 销毁某个道具
- (void)destroyItemAnimationItemType{
    // 解绑
    [FURenderer unBindItems:items[FUItemTypeController] items:&items[FUItemTypeAnimation] itemsCount:1];
    // 销毁
    [FURenderer destroyItem:items[FUItemTypeAnimation]];
    items[FUItemTypeAnimation] = 0;
}





#pragma mark --- 以下面部追踪模式

/**
 进入面部追踪模式
 */
- (void)enterTrackFaceMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"enter_track_rotation_mode" value:@(1)];
}

/**
 退出面部追踪模式
 */
- (void)quitTrackFaceMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"quit_track_rotation_mode" value:@(1)];
}
#pragma mark --- 以下身体追踪模式

/**
 进入身体追踪模式
 */
- (void)enterTrackBodyMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"enter_human_pose_track_mode" value:@(1)];
}

/**
 退出身体追踪模式
 */
- (void)quitTrackBodyMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"quit_human_pose_track_mode" value:@(1)];
}
/**
 进入身体跟随模式
 */
- (void)enterFollowBodyMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"human_3d_track_is_follow" value:@(1)];
}

/**
 退出身体跟随模式
 */
- (void)quitFollowBodyMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"human_3d_track_is_follow" value:@(0)];
}
/**
 设置在身体动画和身体追踪数据之间过渡的时间，默认值为0.5（秒）
 */
- (void)setHuman3dAnimTransitionTime:(float)time{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"anim_transition_max_time_human_3d_track" value:@(time)];
}

/**
 进入DDE追踪模式
 */
- (void)enterDDEMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"open_dde" value:@(1)];
}

/**
 退出DDE追踪模式
 */
- (void)quitDDEMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"close_dde" value:@(1)];
}
/**
 去掉脖子
 */
- (void)removeNeck {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"hide_neck" value:@(1)];
}
/**
 重新加上脖子
 */
- (void)reAddNeck {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"hide_neck" value:@(0)];
}

/**
 打开Blendshape 混合
 */
- (void)enableBlendshape {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"enable_expression_blend" value:@(1)];
}
/**
 关闭Blendshape 混合
 */
- (void)disableBlendshape {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"enable_expression_blend" value:@(0)];
}
/**
 设置用户输入的bs系数数组
 */
- (void)setBlend_expression:(double*)blend_expression{
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"blend_expression" value:blend_expression length:57];
}
/**
 设置blend_expression的权重
 */
- (void)setExpression_wieght0:(double*)expression_wieght0{
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"expression_weight0" value:expression_wieght0 length:57];
    
}
/**
 设置blend_expression的权重
 */
- (void)setExpression_wieght1:(double*)expression_wieght1{
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"expression_weight1" value:expression_wieght1 length:57];
    
}
/// 向nama声明当前avatar时第几个avatar，在多个avatar同时存在时使用
/// @param index 声明当前avatar序号
-(void)setCurrentAvatarIndex:(int) index{
    self.currentInstanceId = index;
    [[FUManager shareInstance] setInstanceId:index];
}
#pragma mark ---- AR 滤镜模式

/**
 在 AR 滤镜模式下加载 avatar
 -- 默认加载头部装饰，包括：头、头发、胡子、眼镜、帽子
 -- 加载完毕之后会设置其相应颜色
 
 @return 返回 controller 句柄
 */
- (int)loadAvatarWithARMode
{
    // load controller
    if (items[FUItemTypeController] == 0) {
        items[FUItemTypeController] = [FUManager shareInstance].defalutQController;
    }
    
    // 主要是设置参数，只要设置一次就好
    [self enterARMode];
    // load Head
    NSString *headPath = [self.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
    [self loadItemWithtype:FUItemTypeHead filePath:headPath];
    
    if (self.hairType == FUAvataHairTypeHair)
    {
        // load hair
        NSString *hairPath = [self.filePath stringByAppendingPathComponent:self.hair.name];
        [self bindItemWithType:FUItemTypeHair filePath:hairPath];
    }
    else
    {
        [self bindHairHatWithItemModel:self.hairHat];
    }
    
    [self bindGlassesWithItemModel:self.glasses];
    [self bindBeardWithItemModel:self.beard];
    [self bindHatWithItemModel:self.hat];
    [self bindEyeLashWithItemModel:self.eyeLash];
    [self bindEyebrowWithItemModel:self.eyeBrow];
    [self bindEyeShadowWithItemModel:self.eyeShadow];
    [self bindEyeLinerWithItemModel:self.eyeLiner];
    [self bindPupilWithItemModel:self.pupil];
    [self bindFaceMakeupWithItemModel:self.faceMakeup];
    [self bindLipGlossWithItemModel:self.lipGloss];
    
    // 耳环
    [self bindDecorationErhuanWithItemModel:self.decoration_erhuan];
    // 头饰
    [self bindDecorationToushiWithItemModel:self.decoration_toushi];
    
    [self loadAvatarColor];
    
    return items[FUItemTypeController] ;
}


- (void)loadHalfAvatar {
    fuItemSetParamd(items[FUItemTypeController],"human_3d_track_set_scene",0);
}
- (void)loadFullAvatar {
    fuItemSetParamd(items[FUItemTypeController],"human_3d_track_set_scene",1);
}
/// 在半身驱动时，身体追踪时，设置avatar向上的偏移量
/// @param y_offset 偏移量
- (void)human3dSetYOffset:(float)y_offset {
    fuItemSetParamd(items[FUItemTypeController],"human_3d_detector_set_y_offset",y_offset);
}

/**
 进入 AR滤镜 模式
 -- 会重置旋转缩放等参数
 -- 去除 身体、衣服、动画，但是不会销毁这些道具
 */
- (void)enterARMode {
    // 2、传参
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@1];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"enter_ar_mode" value:@(1)];
}

/**
 退出 AR滤镜 模式
 -- 会加上 身体、衣服、动画等。
 -- 销毁 ARFilter 道具
 */
- (void)quitARMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"quit_ar_mode" value:@(1)];
}


#pragma mark --- 捏脸模式

/**
 进入捏脸模式
 */
- (void)enterFacepupMode {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"enter_facepup_mode" value:@(1)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"animState" value:@2.0];
}

/**
 退出捏脸模式
 */
- (void)quitFacepupMode {
    //[self loadStandbyAnimation];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"quit_facepup_mode" value:@(1)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"animState" value:@1.0];
}

/**
 获取 mesh 顶点的坐标
 
 @param index   顶点序号
 @return        顶点坐标
 */
- (CGPoint)getMeshPointOfIndex:(NSInteger)index {
    
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"query_vert" value: @(index)];
    
    double x = [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:@"query_vert_x"];
    double y = [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:@"query_vert_y"];
    
    CGSize size = [UIScreen mainScreen].currentMode.size;
    
    return CGPointMake((1.0 - x/size.width) * [UIScreen mainScreen].bounds.size.width,(1.0 - y/size.height) * [UIScreen mainScreen].bounds.size.height) ;
}


/**
 获取 mesh 顶点的坐标
 
 @param index   顶点序号
 @return        顶点坐标
 */
- (CGPoint)getMeshPointOfIndex:(NSInteger)index PixelBufferW:(int)pixelBufferW PixelBufferH:(int)pixelBufferH {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"query_vert" value: @(index)];
    
    double x = [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:@"query_vert_x"];
    double y = [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:@"query_vert_y"];
    y = pixelBufferH - y;
    CGSize size = [UIScreen mainScreen].bounds.size;
    double realScreenWidth  = size.width;
    double realScreenHeight = size.height;
    double xR = realScreenWidth / pixelBufferW;
    double yR = realScreenHeight / pixelBufferH;
    
    if (xR < yR){
        x = x * xR;
        y = y*xR;// - (pixelBufferH*xR - realScreenHeight)/2;
    } else {
        
        //x = x*yR - (x*xR - size.width) / 2;
        //x =  x * yR + (size.width / 2.0 - pixelBufferW * yR) / 2.0;
        x = x* yR;// - (pixelBufferW * yR - realScreenWidth) / 2;
        y = y * yR;
    }
    
    
    
    //return.wCGPointMake((1.0 - x*xR/size.width) * [UIScreen mainScreen].bounds.size.width,(1.0 - y*yR/size.height) * [UIScreen mainScreen].bounds.size.height) ;
    return CGPointMake( x , y);
}

/**
 获取当前身体追踪状态，0.no_body,1.half_body,2.half_more_body,3.full_body
 */
- (int)getCurrentBodyTrackState{
    return [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:@"human_status"];
}
/**
 设置捏脸参数
 
 @param key     参数名
 @param level   参数
 */
- (void)facepupModeSetParam:(NSString *)key level:(double)level {
    key  = [NSString stringWithFormat:@"{\"name\":\"facepup\",\"param\":\"%@\"}", key];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:key value:@(level)];
}
/**
 获取捏脸参数
 
 @param key    参数名
 @return       参数
 */
- (double)getFacepupModeParamWith:(NSString *)key {
    key  = [NSString stringWithFormat:@"{\"name\":\"facepup\",\"param\":\"%@\"}", key];
    double level = [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:key];
    return level ;
}

/**
 捏脸模型下设置颜色
 -- key 具体参数如下：
 肤色：     skin_color
 唇色：     lip_color
 瞳色：     iris_color
 发色：     hair_color
 镜框颜色：  glass_color
 镜片颜色：  glass_frame_color
 胡子颜色：  beard_color
 帽子颜色：  hat_color
 
 
 @param color   颜色
 @param key     参数名
 */
- (void)facepupModeSetColor:(FUP2AColor *)color key:(NSString *)key {
    
    if ([key isEqualToString:@"lip_color"])
    {
        double c[3] = {
            color.r / 255.0 ,
            color.g / 255.0,
            color.b / 255.0
        } ;
        NSString * paramDicStr = [NSString stringWithFormat:@"{\"name\":\"global\",\"type\":\"face_detail\",\"param\":\"blend_color\",\"UUID\":%d}",items[FUItemTypeLipGloss]];
        [FURenderer itemSetParamdv:items[FUItemTypeController] withName:paramDicStr value:c length:3];
        return;
    }
    else if ([key isEqualToString:@"eyelash_color"])
    {
        double c[3] = {
            color.r / 255.0 ,
            color.g / 255.0,
            color.b / 255.0
        } ;
        NSString * paramDicStr = [NSString stringWithFormat:@"{\"name\":\"global\",\"type\":\"face_detail\",\"param\":\"blend_color\",\"UUID\":%d}",items[FUItemTypeEyeLash]];
        [FURenderer itemSetParamdv:items[FUItemTypeController] withName:paramDicStr value:c length:3];
        return;
    }
    else if ([key isEqualToString:@"eyeshadow_color"])
    {
        double c[3] = {
            color.r / 255.0 ,
            color.g / 255.0,
            color.b / 255.0
        } ;
        NSString * paramDicStr = [NSString stringWithFormat:@"{\"name\":\"global\",\"type\":\"face_detail\",\"param\":\"blend_color\",\"UUID\":%d}",items[FUItemTypeEyeShadow]];
        [FURenderer itemSetParamdv:items[FUItemTypeController] withName:paramDicStr value:c length:3];
        return;
    }
    
    
    double c[3] = {
        color.r ,
        color.g,
        color.b
    } ;
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:key value:c length:3];
    
    if ([key isEqualToString:@"hair_color"])
    {
        [FURenderer itemSetParam:items[FUItemTypeController] withName:@"hair_color_intensity" value:@(color.intensity)];
    }
}

- (void)facepupModeSetEyebrowColor:(FUP2AColor *)color
{
    double c[3] = {
        color.r / 255.0 ,
        color.g / 255.0,
        color.b / 255.0
    } ;
    NSString * paramDicStr = [NSString stringWithFormat:@"{\"name\":\"global\",\"type\":\"face_detail\",\"param\":\"blend_color\",\"UUID\":%d}",items[FUItemTypeEyeBrow]];
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:paramDicStr value:c length:3];
}



#pragma mark ----- 以下动画相关

/**
 获取动画总帧数
 
 @return 动画总帧数
 */
- (int)getAnimationFrameCount {
    int num = [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:@"frameNum"];
    return num ;
}

/**
 获取当前帧动画播放的位置
 
 @return    当前动画播放的位置
 */
- (int)getCurrentAnimationFrameIndex {
    int num = [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:@"animFrameId"];
    return num ;
}


/**
 重新开始播放动画
 */
- (void)restartAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后播放动画。
    fuItemSetParamd(items[FUItemTypeController],"stop_camera_animation",[self getCurrentAnimationHandle]);
    [self stopAnimation];
    fuItemSetParamd(items[FUItemTypeController], "play_animation", [self getCurrentAnimationHandle]);
    fuItemSetParamd(items[FUItemTypeController],"start_camera_animation",[self getCurrentAnimationHandle]);
}
/**
 播放动画
 */
- (void)startAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后播放动画。
    
    fuItemSetParamd(items[FUItemTypeController], "start_animation", [self getCurrentAnimationHandle]);
}
/**
 播放一次动画
 */
- (void)playOnceAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后播放动画。
    
    fuItemSetParamd(items[FUItemTypeController], "play_animation_once", [self getCurrentAnimationHandle]);
}
/**
 暂停动画
 */
- (void)pauseAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后暂停动画。
    //结束播放动画
    fuItemSetParamd(items[FUItemTypeController], "pause_animation", [self getCurrentAnimationHandle]);
}
/**
 结束动画
 */
- (void)stopAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后结束动画。
    //结束播放动画
    fuItemSetParamd(items[FUItemTypeController], "stop_animation",[self getCurrentAnimationHandle]);
}

/**
 启用相机动画
 */
- (void)enableCameraAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后播放动画。
    
    fuItemSetParamd(items[FUItemTypeController], "start_camera_animation",1);
}
/**
 停止相机动画
 */
- (void)stopCameraAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后播放动画。
    
    fuItemSetParamd(items[FUItemTypeController], "stop_camera_animation",1);
}
/**
 循环相机动画
 */
- (void)loopCameraAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后播放动画。
    fuItemSetParamd(items[FUItemTypeController], "camera_animation_loop",1);
}
/**
 停止循环相机动画
 */
- (void)stopLoopCameraAnimation {
    [self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后播放动画。
    fuItemSetParamd(items[FUItemTypeController], "camera_animation_loop",0);
}

-(NSString *)description
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    NSMutableString * descriptionString = [NSMutableString string];
    for(i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName)
        {
            NSString *propertyName = [NSString stringWithCString:propName
                                                        encoding:[NSString defaultCStringEncoding]];
            id value = [self valueForKey:propertyName];
            [descriptionString appendFormat:@"%@", [NSString stringWithFormat:@"%@:%@\n",propertyName,value]];
        }
    }
    free(properties);
    return descriptionString;
}
#pragma mark ----- 获取配置

-(id)copyWithZone:(NSZone *)zone
{
    FUAvatar * copyAvatar = [[FUAvatar alloc]init];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for(i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName)
        {
            NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
            
            id value = [self valueForKey:propertyName];
            
            [copyAvatar setValue:value forKey:propertyName];
        }
    }
    // 复制的对象  重新设置一些属性
    //	copyAvatar.defaultModel = NO;
    //	copyAvatar.imagePath = nil;
    free(properties);
    return copyAvatar;
}


- (void)openHairAnimation
{
    fuItemSetParamd(items[FUItemTypeController], "modelmat_to_bone",1);
}

- (void)closeHairAnimation
{
    fuItemSetParamd(items[FUItemTypeController], "modelmat_to_bone",0);
}



#pragma mark  ------ 捏脸 ------
- (NSArray *)getFacepupModeParamsWithLength:(int)length
{
    double level[length];
    [FURenderer itemGetParamdv:items[FUItemTypeController] withName:@"facepup_expression" buffer:level length:length];
    NSMutableArray *params = [[NSMutableArray alloc]init];
    for (int i = 0; i < length; i++)
    {
        [params addObject:[NSNumber numberWithDouble:level[i]]];
    }
    
    return params;
}

/// 设置捏脸参数
/// @param dict 捏脸参数字典
- (void)configFacepupParamWithDict:(NSDictionary *)dict
{
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop)
     {
        key  = [NSString stringWithFormat:@"{\"name\":\"facepup\",\"param\":\"%@\"}", key];
        [FURenderer itemSetParam:items[FUItemTypeController] withName:key value:@([obj doubleValue])];
    }];
}

/**
 加载ani_mg动画
 */
- (void)load_ani_mg_Animation
{
    NSString *animationPath = [[NSBundle mainBundle] pathForResource:@"ani_mg.bundle" ofType:nil];
    [self reloadAnimationWithPath:animationPath];
}

/**
 去除动画
 */
- (void)removeAnimation
{
    [self reloadAnimationWithPath:nil];
}



/**
 换装后回到首页动画
 */
- (void)loadAfterEditAnimation
{
    if (!self.isQType) return;
    
    NSString *animationPath = [[NSBundle mainBundle] pathForResource:@"ani_ok_mid.bundle" ofType:nil];
    
    [self reloadAnimationWithPath:animationPath];
    [self playOnceAnimation];
}

//换装界面动画
- (void)loadChangeItemAnimation
{
    if (!self.isQType) return;
    
    NSString *animationPath = [[NSBundle mainBundle] pathForResource:@"ani_change_01.bundle" ofType:nil];
    [self reloadAnimationWithPath:animationPath];
}

/**
 加载待机动画
 */
- (void)loadStandbyAnimation
{
    NSString *animationPath ;
    if (self.isQType)
    {
        animationPath = [[NSBundle mainBundle] pathForResource:@"ani_huxi_hi.bundle" ofType:nil];
    }
    else
    {
        animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_animation" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_animation" ofType:@"bundle"] ;
    }
    [self reloadAnimationWithPath:animationPath];
}
/**
 人脸追踪时加载 Pose 不带信号量
 */
- (void)loadTrackFaceModePose_NoSignal
{
    NSString *animationPath;
    if (self.isQType)
    {
        animationPath = [[NSBundle mainBundle] pathForResource:@"ani_pose.bundle" ofType:nil];
    }
    else
    {
        animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_pose" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_pose" ofType:@"bundle"] ;
    }
    [self reloadAnimationWithPath_NoSignal:animationPath];
}
/**
 人脸追踪时加载 Pose
 */
- (void)loadTrackFaceModePose
{
    NSString *animationPath;
    if (self.isQType)
    {
        animationPath = [[NSBundle mainBundle] pathForResource:@"ani_pose.bundle" ofType:nil];
    }
    else
    {
        animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_pose" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_pose" ofType:@"bundle"] ;
    }
    [self reloadAnimationWithPath:animationPath];
}
/**
呼吸动画,不带信号量
*/
- (void)loadIdleModePose_NoSignal
{
    NSString *animationPath;
    if (self.isQType)
    {
        animationPath = [[NSBundle mainBundle] pathForResource:@"ani_idle.bundle" ofType:nil];
    }else
    {
        animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_pose" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_pose" ofType:@"bundle"] ;
    }
    [self reloadAnimationWithPath_NoSignal:animationPath];
}
/**
 呼吸动画
 */
- (void)loadIdleModePose
{
    NSString *animationPath;
    if (self.isQType)
    {
        animationPath = [[NSBundle mainBundle] pathForResource:@"ani_idle.bundle" ofType:nil];
    }else
    {
        animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_pose" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_pose" ofType:@"bundle"] ;
    }
    [self reloadAnimationWithPath:animationPath];
}

/**
 身体追踪时加载 Pose
 */
- (void)loadTrackBodyModePose {
    NSString *animationPath;
    if (self.isQType) {
        animationPath = [[NSBundle mainBundle] pathForResource:@"anim_one1.bundle" ofType:nil];
    }else {
        animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_pose" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_pose" ofType:@"bundle"] ;
    }
    [self loadItemWithtype:FUItemTypeAnimation filePath:animationPath];
}

#pragma mark --- 以下缩放位移
/**
 设置缩放参数
 
 @param delta 缩放增量
 */
- (void)resetScaleDelta:(float)delta
{
    int const current_position_count = 3;
    double current_position[current_position_count];
    [FURenderer itemGetParamdv:items[FUItemTypeController] withName:@"current_position" buffer:current_position length:current_position_count];
        if ((current_position[2] > 20 && delta > 0) || (current_position[2] < -1400 && delta < 0)) return;
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"scale_delta" value:@(delta)];
}

/**
 设置旋转参数
 
 @param delta 旋转增量
 */
- (void)resetRotDelta:(float)delta
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"rot_delta" value:@(delta)];
}

/**
 设置垂直位移
 
 @param delta 垂直位移增量
 */
- (void)resetTranslateDelta:(float)delta {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"translate_delta" value:@(delta)];
}

/**
 缩放至面部正面
 */
- (void)resetScaleToFace {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-145)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(8)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至截图
 */
- (void)resetScaleToScreenShot
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(40)];   // 调整模型大小，值越小，模型越大
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-10)];  // 调整模型的上下位置，值越小，越靠下
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.0)];  // 调整模型的旋转角度
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(1)];       // 调用生效
}

/**
 捏脸模式缩放至面部正面
 */
- (void)resetScaleToShapeFaceFront
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(3)];
}

/**
 捏脸模式缩放至面部侧面
 */
- (void)resetScaleToShapeFaceSide
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.125)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(3)];
}

/**
 缩放至全身
 */
- (void)resetScaleToBody
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-150)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(2)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}


/**
 缩放至小比例的全身
 */
- (void)resetScaleToSmallBody
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-507)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(60)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}



- (void)resetPosition
{
    double position[3] = {0,0,0};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(0)];
}

/// 缩小至全身并在屏幕左边显示
- (void)resetScaleSmallBodyToLeft
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(60)];
    double position[3] = {-100,0,-1000};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/// 缩小至全身并在屏幕左边显示
- (void)resetScaleSmallBodyToRight
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(60)];
    double position[3] = {100,0,-1000};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/// 缩小至全身并在屏幕上边显示
- (void)resetScaleSmallBodyToUp
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-1000)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(120)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/// 缩小至全身并在屏幕下面显示
- (void)resetScaleSmallBodyToDown
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-1000)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至显示 Q 版的鞋子
 */
- (void)resetScaleToShowShoes
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-800)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(100)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至小比例的身体跟随
 */
- (void)resetScaleToFollowBody
{
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-5000)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(240)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}


/**
 将Avatar的位置设置为初始状态
 */
- (void)resetScaleToOriginal
{
    double position[3] = {0,0,0};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(1)];
}


/**
 使用相机bundle缩放至脸部特写
 */
- (void)resetScaleToFace_UseCam
{
    [self resetPosition];
    
    // 获取当前相机动画bundle路径
    NSString *camPath = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/page_cam/cam_texie.bundle"];
    // 将相机动画绑定到controller上
    [[FUManager shareInstance] reloadCamItemWithPath:camPath];
}
/**
 使用相机bundle缩放至脸部特写,不使用信号量，防止造成死锁
 */
- (void)resetScaleToFace_UseCamNoSignal
{
    [self resetPosition];
    
    // 获取当前相机动画bundle路径
    NSString *camPath = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/page_cam/cam_texie.bundle"];
    // 将相机动画绑定到controller上
    [[FUManager shareInstance] reloadCamItemNoSignalWithPath:camPath];
}

/**
 使用相机bundle缩放至小比例的全身
 */
- (void)resetScaleToSmallBody_UseCam
{
    [self resetPosition];
    
    // 获取当前相机动画bundle路径
    NSString *camPath = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/page_cam/cam_02.bundle"];
    // 将相机动画绑定到controller上
    [[FUManager shareInstance] reloadCamItemWithPath:camPath];
}

/**
 使用相机bundle缩放至全身
 */
- (void)resetScaleToBody_UseCam
{
    [self resetPosition];
    
    // 获取当前相机动画bundle路径
    NSString *camPath = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/page_cam/cam_35mm_full_80mm_jinjing.bundle"];
    // 将相机动画绑定到controller上
    [[FUManager shareInstance] reloadCamItemWithPath:camPath];
}

/**
 替换服饰时使用的cam
 */
- (void)resetScaleChange_UseCam
{
    [self resetPosition];
    
    // 获取当前相机动画bundle路径
    NSString *camPath = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/page_cam/cam_quanshen.bundle"];
    // 将相机动画绑定到controller上
    [[FUManager shareInstance] reloadCamItemWithPath:camPath];
}


/**
 缩放至全身追踪,驱动页未收起模型选择栏等工具栏的情况

 */
- (void)resetScaleToTrackBodyWithToolBar
{
    double position[3] = {0,75,-700};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至全身追踪,驱动页收起模型选择栏等工具栏的情况

 */
- (void)resetScaleToTrackBodyWithoutToolBar
{
    double position[3] = {0,55,-520};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}


/**
缩放至全身追踪
使用场景：
1.导入视频后生成的画面
*/
- (void)resetScaleToImportTrackBody
{
    double position[3] = {0,75,-700};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至半身
 */
- (void)resetScaleToHalfBodyWithToolBar
{
    double position[3] = {0,15,-300};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至半身
 */
- (void)resetScaleToHalfBodyInput
{
    double position[3] = {0,0,-700};
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}


/// 根据传入的形象模型重设形象的信息
/// @param avatar 形象模型
- (void)resetValueFromBeforeEditAvatar:(FUAvatar *)avatar
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for(i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName)
        {
            NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
            
            id value = [avatar valueForKey:propertyName];
            [self setValue:value forKey:propertyName];
        }
    }
    free(properties);
}


- (NSString *)getBodyFilePathWithModel:(FUItemModel *)model
{
    NSString *bodyFilepath = @"midBody";
    bodyFilepath = [bodyFilepath stringByAppendingFormat:@"_%@",[model.gender integerValue]>0?@"female":@"male"];
    bodyFilepath = [bodyFilepath stringByAppendingFormat:@"%zi.bundle",[model.body_match_level integerValue]];
    bodyFilepath = [[NSBundle mainBundle]pathForResource:bodyFilepath ofType:nil];
    
    return bodyFilepath;
}



#pragma mark ------ 形象加载 ------
/**
 加载 avatar 模型
 --  会加载 头、头发、身体、衣服、默认动作 四个道具。
 --  如果有 胡子、帽子、眼镜也会加载，没有则不加载。
 --  会设置 肤色、唇色、瞳色、发色(光头不设)。
 --  如果有 胡子、帽子、眼镜也会设置其对应颜色。
 
 @return 返回 controller 所在句柄
 */
- (int)loadAvatarToController
{
  return [self loadAvatarToControllerWith:YES];
}

#pragma mark ------ 形象加载 ------
/**
 加载 avatar 模型
 --  会加载 头、头发、身体、衣服、默认动作 四个道具。
 --  如果有 胡子、帽子、眼镜也会加载，没有则不加载。
 --  会设置 肤色、唇色、瞳色、发色(光头不设)。
 --  如果有 胡子、帽子、眼镜也会设置其对应颜色。
 
 @return 返回 controller 所在句柄
 @param isBg 是否渲染模型自身的背景 bundle
 */
- (int)loadAvatarToControllerWith:(BOOL)isBg
{
    // load controller
    if (items[FUItemTypeController] == 0)
    {
        items[FUItemTypeController] = [FUManager shareInstance].defalutQController;
    }
    
    // load Head
    NSString *headPath = [self.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
    [self bindItemWithType:FUItemTypeHead filePath:headPath];

    if (self.skinColorProgress == -1)
    {
        NSString * paramDicStr = [NSString stringWithFormat:@"skin_color_index"];
        int index = fuItemGetParamd(items[FUItemTypeController],paramDicStr.UTF8String);
        self.skinColorProgress = index/10.0;
    }
    // load Body
    NSString *bodyPath;
    if (self.clothType == FUAvataClothTypeSuit)
    {
        bodyPath = [self getBodyFilePathWithModel:self.clothes];
    }
    else
    {
        bodyPath = [self getBodyFilePathWithModel:self.upper];
    }
    [self bindItemWithType:FUItemTypeBody filePath:bodyPath];
    
    if (self.hairType == FUAvataHairTypeHair)
    {
        // load hair
        NSString *hairPath = [self.filePath stringByAppendingPathComponent:self.hair.name];
        [self destroyItemWithType:FUItemTypeHairHat];
        [self bindItemWithType:FUItemTypeHair filePath:hairPath];
    }
    else
    {
        [self bindHairHatWithItemModel:self.hairHat];
    }
    
    
    if (self.isQType)
    {
        // load clothes
        if (self.clothType == FUAvataClothTypeSuit)
        {
            [self bindClothWithItemModel:self.clothes];
        }
        else
        {
            [self bindUpperWithItemModel:self.upper];
            [self bindLowerWithItemModel:self.lower];
        }
    }

    [self bindShoesWithItemModel:self.shoes];
    // 配饰 大类  多选
    [self bindDecorationShouWithItemModel:self.decoration_shou];
	[self bindDecorationJiaoWithItemModel:self.decoration_jiao];
	[self bindDecorationXianglianWithItemModel:self.decoration_xianglian];
	[self bindDecorationErhuanWithItemModel:self.decoration_erhuan];
	[self bindDecorationToushiWithItemModel:self.decoration_toushi];
      
    [self bindHatWithItemModel:self.hat];
    [self bindEyeLashWithItemModel:self.eyeLash];
    [self bindEyebrowWithItemModel:self.eyeBrow];
    [self bindBeardWithItemModel:self.beard];
    [self bindEyeShadowWithItemModel:self.eyeShadow];
    [self bindEyeLinerWithItemModel:self.eyeLiner];
    [self bindPupilWithItemModel:self.pupil];
    [self bindFaceMakeupWithItemModel:self.faceMakeup];
    [self bindLipGlossWithItemModel:self.lipGloss];
    [self bindGlassesWithItemModel:self.glasses];
    if(isBg)
    [self bindBackgroundWithItemModel:self.dress_2d];
    [self loadAvatarColor];
    return items[FUItemTypeController] ;
}


/// 加载形象颜色
- (void)loadAvatarColor
{
    for (int i = 0; i < FUFigureColorTypeEnd; i++)
    {
        NSString *key = [[FUManager shareInstance]getColorKeyWithType:(FUFigureColorType)i];
        
        NSString *indexProKey = [key stringByReplacingOccurrencesOfString:@"_c" withString:@"C"];
        indexProKey = [indexProKey stringByReplacingOccurrencesOfString:@"_f" withString:@"F"];
        indexProKey = [indexProKey stringByAppendingString:@"Index"];
        
        NSInteger index = [[self valueForKey:indexProKey] integerValue] -1;
        
        FUP2AColor *color = [[FUManager shareInstance].colorDict[key] objectAtIndex:index];
        
        if (i == FUFigureColorTypeSkinColor)
        {
            color = [[FUManager shareInstance]getSkinColorWithProgress:self.skinColorProgress];
        }
        
        [self facepupModeSetColor:color key:key];
    }
}

- (void)loadAvatarSkinColor
{
    NSString *key = @"skinColorIndex";
    NSInteger index = [[self valueForKey:key] integerValue] -1;
    FUP2AColor *color = [[FUManager shareInstance].colorDict[key] objectAtIndex:index];
    color = [[FUManager shareInstance]getSkinColorWithProgress:self.skinColorProgress];
    [self facepupModeSetColor:color key:@"skin_color"];
}

#pragma mark ------ 绑定道具 ------
- (void)bindClothWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
    NSString *bodyFilepath = [self getBodyFilePathWithModel:model];
    
	[self bindItemWithType:FUItemTypeBody filePath:bodyFilepath];
    [self destroyItemWithType:FUItemTypeUpper];
    [self destroyItemWithType:FUItemTypeLower];
    [self bindItemWithType:FUItemTypeClothes filePath:filepath];
    self.clothType = FUAvataClothTypeSuit;
}

/// 加载发型
/// @param model 发型数据
- (void)bindHairWithItemModel:(FUItemModel *)model
{
	NSString *filepath = [NSString stringWithFormat:@"%@/%@",[self filePath],model.name];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:filepath])
	{
		
		[[NSNotificationCenter defaultCenter] postNotificationName:FUCreatingHairBundleNot object:nil userInfo:@{@"show":@(1)}];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[[FUManager shareInstance]createAndCopyHairBundlesWithAvatar:self withHairModel:model];
			[[NSNotificationCenter defaultCenter] postNotificationName:FUCreatingHairBundleNot object:nil userInfo:@{@"show":@(0)}];
			
			[self destroyItemWithType:FUItemTypeHairHat];
			[self bindItemWithType:FUItemTypeHair filePath:filepath];
		});
		
	}
	else
	{
		[self destroyItemWithType:FUItemTypeHairHat];
		[self bindItemWithType:FUItemTypeHair filePath:filepath];
	}
}

/// 加载上衣
/// @param model 上衣数据
- (void)bindUpperWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
    NSString *bodyFilepath = [self getBodyFilePathWithModel:model];
    
	[self destroyItemWithType:FUItemTypeClothes];
    [self bindItemWithType:FUItemTypeBody filePath:bodyFilepath];
    [self bindItemWithType:FUItemTypeUpper filePath:filepath];
    self.clothType = FUAvataClothTypeUpperAndLower;
    }

/// 加载下衣
/// @param model 下衣数据
- (void)bindLowerWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        
    [self destroyItemWithType:FUItemTypeClothes];
    [self bindItemWithType:FUItemTypeLower filePath:filepath];
    self.clothType = FUAvataClothTypeUpperAndLower;
    }

/// 加载鞋子
/// @param model 鞋子数据
- (void)bindShoesWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeShoes filePath:filepath];
    }

/// 加载帽子
/// @param model 帽子数据
- (void)bindHatWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeHat filePath:filepath];
    }

/// 加载睫毛
/// @param model 睫毛数据
- (void)bindEyeLashWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
	[self bindItemWithType:FUItemTypeEyeLash filePath:filepath];
    [self facepupModeSetColor:[[FUManager shareInstance] getSelectedColorWithType:FUFigureColorTypeEyelashColor] key:@"eyelash_color"];
    }

/// 加载眉毛
/// @param model 眉毛数据
- (void)bindEyebrowWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
	[self bindItemWithType:FUItemTypeEyeBrow filePath:filepath];
    [self facepupModeSetEyebrowColor:[[FUManager shareInstance] getSelectedColorWithType:FUFigureColorTypeEyebrowColor]];
    }

/// 加载胡子
/// @param model 胡子数据
- (void)bindBeardWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeBeard filePath:filepath];
    }

/// 加载眼镜
/// @param model 眼镜数据
- (void)bindGlassesWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeGlasses filePath:filepath];
    }

/// 加载眼影
/// @param model 眼影数据
- (void)bindEyeShadowWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeEyeShadow filePath:filepath];
    [self facepupModeSetColor:[[FUManager shareInstance] getSelectedColorWithType:FUFigureColorTypeEyeshadowColor] key:@"eyeshadow_color"];
    }

/// 加载眼线
/// @param model 眼线数据
- (void)bindEyeLinerWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeEyeLiner filePath:filepath];
    }

/// 加载美瞳
/// @param model 美瞳数据
- (void)bindPupilWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypePupil filePath:filepath];
    }

/// 加载脸妆
/// @param model 脸妆数据
- (void)bindFaceMakeupWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeMakeFaceup filePath:filepath];
    }

/// 加载唇妆
/// @param model 唇妆数据
- (void)bindLipGlossWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeLipGloss filePath:filepath];
    [self facepupModeSetColor:[[FUManager shareInstance] getSelectedColorWithType:FUFigureColorTypeLipsColor] key:@"lip_color"];
    }

/// 加载饰品
/// @param model 手饰品数据
- (void)bindDecorationShouWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeDecoration_shou filePath:filepath];
}
/// 加载饰品
/// @param model 脚饰品数据
- (void)bindDecorationJiaoWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeDecoration_jiao filePath:filepath];
}
/// 加载饰品
/// @param model 项链饰品数据
- (void)bindDecorationXianglianWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeDecoration_xianglian filePath:filepath];
}
/// 加载饰品
/// @param model 耳环饰品数据
- (void)bindDecorationErhuanWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
    
        [self bindItemWithType:FUItemTypeDecoration_erhuan filePath:filepath];
}
/// 加载饰品
/// @param model 头饰饰品数据
- (void)bindDecorationToushiWithItemModel:(FUItemModel *)model
{
	NSString *filepath = [model getBundlePath];
	[self bindItemWithType:FUItemTypeDecoration_toushi filePath:filepath];
}


/// 加载发帽
/// @param model 发帽数据
- (void)bindHairHatWithItemModel:(FUItemModel *)model
{
	
	NSString *filepath = [NSString stringWithFormat:@"%@/%@",[self filePath],model.name];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:filepath])
	{
		
		[[NSNotificationCenter defaultCenter] postNotificationName:FUCreatingHairHatBundleNot object:nil userInfo:@{@"show":@(1)}];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[[FUManager shareInstance]createAndCopyHairHatBundlesWithAvatar:self withHairHatModel:model];
			[[NSNotificationCenter defaultCenter] postNotificationName:FUCreatingHairHatBundleNot object:nil userInfo:@{@"show":@(0)}];
			
			[self destroyItemWithType:FUItemTypeHairHat];
			[self bindItemWithType:FUItemTypeHair filePath:filepath];
		});
		
	}
	else
	{
		[self destroyItemWithType:FUItemTypeHair];
		[self bindItemWithType:FUItemTypeHairHat filePath:filepath];
	}
}

/// 加载背景 FUItemModel
/// @param model 背景数据
- (void)bindBackgroundWithItemModel:(FUItemModel *)model
{
    NSString *filepath = [model getBundlePath];
	[self destroyItemWithType:FUItemTypeBackground];
    [self bindItemWithType:FUItemTypeBackground filePath:filepath];
    }



#pragma mark ------ 绑定底层方法 ------
- (void)bindItemWithType:(FUItemType)itemType filePath:(NSString *)path
{
    BOOL isDirectory;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    
    if (path == nil || !isExist || isDirectory)
    {
        [self destroyItemWithType:itemType];
        return ;
    }
    // 创建道具
    int tmpHandle = [FURenderer itemWithContentsOfFile:path];
    
    // 销毁同类道具
    [self destroyItemWithType:itemType];
    
    // 绑定到 controller 上
    items[itemType] = tmpHandle;
    
    if (items[FUItemTypeController] && itemType > 0) {
        [FURenderer bindItems:items[FUItemTypeController] items:&items[itemType] itemsCount:1] ;
    }
}

@end
