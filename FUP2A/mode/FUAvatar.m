//
//  FUAvatar.m
//  P2A
//
//  Created by L on 2018/12/15.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUAvatar.h"
#import "funama.h"
#import "FURenderer.h"
#import "FUP2AColor.h"

typedef enum : NSInteger {
    FUItemTypeController        = 0,
    FUItemTypeHead,
    FUItemTypeBody,
    FUItemTypeHair,
    FUItemTypeClothes,
    FUItemTypeGlasses,
    FUItemTypeBeard,
    FUItemTypeHat,
    FUItemTypeShoes,
    FUItemTypeAnimation,
    FUItemTypeEyeLash,
    FUItemTypeEyeBrow,
    FUItemTypeCamera,
    FUItemTypeTmp,
} FUItemType;


@interface FUAvatar ()
{
    // 句柄数组
    int items[14] ;
    // 同步信号量
    dispatch_semaphore_t signal;
}
@end


@implementation FUAvatar

-(instancetype)init {
    self = [super init];
    if (self) {
        signal = dispatch_semaphore_create(1) ;
    }
    return self ;
}

/**
 用 JSON 文件初始化 avatar
 
 @param dict 从 JSON 文件中读取到的 info
 @return avatar
 */
+(FUAvatar *)avatarWithInfoDic:(NSDictionary *)dict {
    
    FUAvatar *avatar = [[FUAvatar alloc] init];
    
    avatar.name = dict[@"name"];
    avatar.gender = (FUGender)[dict[@"gender"] intValue] ;
    avatar.defaultModel = [dict[@"default"] boolValue] ;
    avatar.isQType = [dict[@"q_type"] integerValue];
    
    avatar.hair = dict[@"hair"] ;
    avatar.clothes = dict[@"clothes"] ;
    avatar.glasses = dict[@"glasses"] ;
    avatar.shoes = dict[@"shoes"];
    avatar.beard = dict[@"beard"] ;
    avatar.hat = dict[@"hat"] ;
    avatar.eyeLash = dict[@"eyeLash"] ;
    avatar.eyeBrow = dict[@"eyeBrow"] ;
    
    avatar.face = dict[@"face"] ;
    avatar.eyes = dict[@"eyes"] ;
    avatar.mouth = dict[@"mouth"] ;
    avatar.nose = dict[@"nose"] ;
    
    avatar.hairLabel = [dict[@"hair_label"] intValue];
    avatar.bearLabel = [dict[@"beard_label"] intValue];
    
    avatar.skinLevel = [dict[@"skin_level"] doubleValue];
    avatar.irisLevel = [dict[@"iris_level"] doubleValue];
    avatar.lipsLevel = [dict[@"lips_level"] doubleValue];
    
    avatar.skinColor = [FUP2AColor colorWithDict:dict[@"skin_color"]] ;
    avatar.lipColor = [FUP2AColor colorWithDict:dict[@"lip_color"]] ;
    avatar.irisColor = [FUP2AColor colorWithDict:dict[@"iris_color"]] ;
    avatar.hairColor = [FUP2AColor colorWithDict:dict[@"hair_color"]] ;
    avatar.glassColor = [FUP2AColor colorWithDict:dict[@"glass_color"]] ;
    avatar.glassFrameColor = [FUP2AColor colorWithDict:dict[@"glass_frame_color"]] ;
    avatar.beardColor = [FUP2AColor colorWithDict:dict[@"beard_color"]] ;
    avatar.hatColor = [FUP2AColor colorWithDict:dict[@"hat_color"]] ;
    
    return avatar ;
}

// 图片路径
-(NSString *)imagePath {
    if (!_imagePath) {
        _imagePath = [[self filePath] stringByAppendingPathComponent:@"image.png"];
    }
    return _imagePath ;
}

/**
 avatar 模型保存的根目录
 
 @return  avatar 模型保存的根目录
 */
- (NSString *)filePath {
    
    NSString *filePath ;
    
    if (self.defaultModel) {
        
        filePath = [[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:self.name];
    }else {
        
        filePath = [documentPath stringByAppendingPathComponent:self.name];
    }
    
    return filePath ;
}

/**
 加载 avatar 模型
 --  会加载 头、头发、身体、衣服、默认动作 四个道具。
 --  如果有 胡子、帽子、眼镜也会加载，没有则不加载。
 --  会设置 肤色、唇色、瞳色、发色(光头不设)。
 --  如果有 胡子、帽子、眼镜也会设置其对应颜色。
 
 @return 返回 controller 所在句柄
 */
- (int)loadAvatar {
    
    // load controller
    if (items[FUItemTypeController] == 0) {
        NSString *controller = self.isQType ? @"q_controller.bundle" : @"controller.bundle" ;
        NSString *controllerPath = [[NSBundle mainBundle] pathForResource:controller ofType:nil];
        [self loadItemWithtype:FUItemTypeController filePath:controllerPath];
    }

    // load Head
    NSString *headPath = [self.filePath stringByAppendingPathComponent:@"head.bundle"];
    [self loadItemWithtype:FUItemTypeHead filePath:headPath];

    // load Body
    NSString *bodyPath = self.isQType ? [[NSBundle mainBundle] pathForResource:@"mid_body.bundle" ofType:nil] : (self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_body" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_body" ofType:@"bundle"]) ;
    [self loadItemWithtype:FUItemTypeBody filePath:bodyPath];

    // load hair
    NSString *hairPath = [[self.filePath stringByAppendingPathComponent:self.hair] stringByAppendingString:@".bundle"];
    [self reloadHairWithPath:hairPath];

    // load clothes
    NSString *clothes = [self.clothes stringByAppendingString:@".bundle"] ;
    NSString *clothesPath = [[NSBundle mainBundle] pathForResource:clothes ofType:nil] ;
    [self reloadClothesWithPath:clothesPath];

    // load glasses
    NSString *glasses = [self.glasses stringByAppendingString:@".bundle"];
    NSString *glassesPath = [[NSBundle mainBundle] pathForResource:glasses ofType: nil];
    [self reloadGlassesWithPath:glassesPath];

    // load hat
    NSString *hat = [self.hat stringByAppendingString:@".bundle"];
    NSString *hatPath = [[NSBundle mainBundle] pathForResource:hat ofType:nil];
    [self reloadHatWithPath:hatPath];

    // load beard
    NSString *beard = [self.beard stringByAppendingString:@".bundle"] ;
    NSString *beardPath = [[NSBundle mainBundle] pathForResource:beard ofType:nil];
    [self reloadBeardWithPath:beardPath];
    
    if (self.isQType){
//
//        // load shoes
//        NSString *shoes = [self.shoes stringByAppendingString:@".bundle"] ;
//        NSString *shoesPath = [[NSBundle mainBundle] pathForResource:shoes ofType:nil];
//        [self reloadShoesWithPath:shoesPath];
    }else {
        // eyelash
        NSString *lashPath = [[NSBundle mainBundle] pathForResource:[self.eyeLash stringByAppendingString:@".bundle"] ofType:nil];
        [self reloadEyeBrowWithPath:lashPath];

        // eyebrow
        NSString *browPath = [[NSBundle mainBundle] pathForResource:[self.eyeBrow stringByAppendingString:@".bundle"] ofType:nil];
        [self reloadEyeBrowWithPath:browPath];
    }


    // set colors
    [self setAvatarColors];
    
    return items[FUItemTypeController] ;
}

/**
 获取 controller 所在句柄
 
 @return 返回 controller 所在句柄
 */
- (int)getControllerHandle {
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
#pragma mark --- 以下切换身体配饰

/**
 更换头发
 
 @param hairPath 新头发所在路径
 */
- (void)reloadHairWithPath:(NSString *)hairPath {
    [self loadItemWithtype:FUItemTypeHair filePath:hairPath];
}

/**
 更换衣服
 
 @param clothesPath 新衣服所在路径
 */
- (void)reloadClothesWithPath:(NSString *)clothesPath {
    [self loadItemWithtype:FUItemTypeClothes filePath:clothesPath];
}

/**
 更换眼镜
 
 @param glassesPath 新眼镜所在路径
 */
- (void)reloadGlassesWithPath:(NSString *)glassesPath {
    [self loadItemWithtype:FUItemTypeGlasses filePath:glassesPath];
}

/**
 更换胡子
 
 @param beardPath 新胡子所在路径
 */
- (void)reloadBeardWithPath:(NSString *)beardPath {
    [self loadItemWithtype:FUItemTypeBeard filePath:beardPath];
}

/**
 更换帽子
 
 @param hatPath 新帽子所在路径
 */
- (void)reloadHatWithPath:(NSString *)hatPath {
    [self loadItemWithtype:FUItemTypeHat filePath:hatPath];
}

/**
 加载待机动画
 */
- (void)loadStandbyAnimation {
    NSString *animationPath ;
    if (self.isQType) {
        animationPath = [[NSBundle mainBundle] pathForResource:@"ani_idle.bundle" ofType:nil];
    }else {
        animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_animation" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_animation" ofType:@"bundle"] ;
    }
    [self loadItemWithtype:FUItemTypeAnimation filePath:animationPath];
}

/**
 人脸追踪时加载 Pose
 */
- (void)loadTrackFaceModePose {
    NSString *animationPath;
    if (self.isQType) {
        animationPath = [[NSBundle mainBundle] pathForResource:@"ani_pose.bundle" ofType:nil];
    }else {
        animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_pose" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_pose" ofType:@"bundle"] ;
    }
    [self loadItemWithtype:FUItemTypeAnimation filePath:animationPath];
}

/**
 更换动画
 
 @param animationPath 新动画所在路径
 */
- (void)reloadAnimationWithPath:(NSString *)animationPath {
    [self loadItemWithtype:FUItemTypeAnimation filePath:animationPath];
}

/**
 更换睫毛
 
 @param eyelashPath 新睫毛所在路径
 */
- (void)reloadEyeLashWithPath:(NSString *)eyelashPath {
    [self loadItemWithtype:FUItemTypeEyeLash filePath:eyelashPath];
}

/**
 更换眉毛
 
 @param eyebrowPath 新眉毛所在路径
 */
- (void)reloadEyeBrowWithPath:(NSString *)eyebrowPath {
    [self loadItemWithtype:FUItemTypeEyeBrow filePath:eyebrowPath];
}

/**
 更换鞋子
 -- Q版专有
 
 @param shoesPath 新眉毛所在路径
 */
- (void)reloadShoesWithPath:(NSString *)shoesPath {
//    [self loadItemWithtype:FUItemTypeShoes filePath:shoesPath];
}
/**
 更新辅助道具
 
 @param tmpPath 辅助道具路径
 */
- (void)reloadTmpItemWithPath:(NSString *)tmpPath {
    [self loadItemWithtype:FUItemTypeTmp filePath:tmpPath];
}
/**
 更新Cam道具
 
 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString *)camPath {
    [self loadItemWithtype:FUItemTypeCamera filePath:camPath];
}

// 加载普通道具
- (void)loadItemWithtype:(FUItemType)itemType filePath:(NSString *)path {
    
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    
    if (path == nil || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        [self destroyItemWithType:itemType];
        
        dispatch_semaphore_signal(signal) ;
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
    
    dispatch_semaphore_signal(signal);
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


#pragma mark --- 以下缩放位移

/**
 设置缩放参数
 
 @param delta 缩放增量
 */
- (void)resetScaleDelta:(float)delta {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"scale_delta" value:@(delta)];
}

/**
 设置旋转参数
 
 @param delta 旋转增量
 */
- (void)resetRotDelta:(float)delta {
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
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(50)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(12)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
    
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(100)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(5)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(1)];
}

/**
 捏脸模式缩放至面部正面
 */
- (void)resetScaleToShapeFaceFront {
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-10)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-2.0)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.0)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(3)];
    
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(30)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-2.0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(3)];
}

/**
 捏脸模式缩放至面部侧面
 */
- (void)resetScaleToShapeFaceSide {
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-10)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-2.0)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(-1.0)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(3)];
    
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(30)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-2.0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(-1)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(3)];
}

/**
 缩放至全身
 */
- (void)resetScaleToBody {
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(220)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(70)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
    
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(50)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(5)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至小比例的全身
 */
- (void)resetScaleToSmallBody {
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(350)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(120)];
//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
    
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(220)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(70)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至显示 Q 版的鞋子
 */
- (void)resetScaleToShowShoes {
    
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(30)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(150)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
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

#pragma mark ---- AR 滤镜模式

/**
 在 AR 滤镜模式下加载 avatar
 -- 默认加载头部装饰，包括：头、头发、胡子、眼镜、帽子
 -- 加载完毕之后会设置其相应颜色
 
 @return 返回 controller 句柄
 */
- (int)loadAvatarWithARMode {
    
    // load controller
    if (items[FUItemTypeController] == 0) {
        NSString *controllerName = self.isQType ? @"q_controller.bundle" : @"controller.bundle" ;
        NSString *controllerPath = [[NSBundle mainBundle] pathForResource:controllerName ofType:nil];
        [self loadItemWithtype:FUItemTypeController filePath:controllerPath];
    }
    
    // 主要是设置参数，只要设置一次就好
    [self enterARMode];

    // load Head
    NSString *headPath = [self.filePath stringByAppendingPathComponent:@"head.bundle"];
    [self loadItemWithtype:FUItemTypeHead filePath:headPath];

    // load hair
    NSString *hairPath = [[self.filePath stringByAppendingPathComponent:self.hair] stringByAppendingString:@".bundle"];
    [self loadItemWithtype:FUItemTypeHair filePath:hairPath];
    
    // load glasses
    NSString *glasses = [self.glasses stringByAppendingString:@".bundle"];
    NSString *glassesPath = [[NSBundle mainBundle] pathForResource:glasses ofType: nil];
    [self loadItemWithtype:FUItemTypeGlasses filePath:glassesPath];
    
    // load beard
    NSString *beard = [self.beard stringByAppendingString:@".bundle"] ;
    NSString *beardPath = [[NSBundle mainBundle] pathForResource:beard ofType:nil];
    [self loadItemWithtype:FUItemTypeBeard filePath:beardPath];
    
    // load hat
    NSString *hat = [self.hat stringByAppendingString:@".bundle"];
    NSString *hatPath = [[NSBundle mainBundle] pathForResource:hat ofType:nil];
    [self loadItemWithtype:FUItemTypeHat filePath:hatPath];
    
    // load eye lash
    NSString *eyeLash = [self.eyeLash stringByAppendingString:@".bundle"];
    NSString *eyeLashPath = [[NSBundle mainBundle] pathForResource:eyeLash ofType:nil];
    [self loadItemWithtype:FUItemTypeEyeLash filePath:eyeLashPath];
    
    // load eyebrow
    NSString *eyeBrow = [self.eyeBrow stringByAppendingString:@".bundle"];
    NSString *eyeBrowPath = [[NSBundle mainBundle] pathForResource:eyeBrow ofType:nil];
    [self loadItemWithtype:FUItemTypeEyeBrow filePath:eyeBrowPath];
    
    // set colors
    [self setAvatarColors];

    return items[FUItemTypeController] ;
}

/**
 进入 AR滤镜 模式
 -- 会重置旋转缩放等参数
 -- 去除 身体、衣服、动画，但是不会销毁这些道具
 */
- (void)enterARMode {
    
    // 1、 unBind身体、衣服、动画、
    [self destroyItemWithType:FUItemTypeBody];
    [self destroyItemWithType:FUItemTypeClothes];
    [self destroyItemWithType:FUItemTypeAnimation];
    
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
    [self loadTrackFaceModePose];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"enter_facepup_mode" value:@(1)];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"animState" value:@2.0];
}

/**
 退出捏脸模式
 */
- (void)quitFacepupMode {
    [self loadStandbyAnimation];
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
    
    return CGPointMake((1.0 - x/size.width) * [UIScreen mainScreen].bounds.size.width, y/size.height * [UIScreen mainScreen].bounds.size.height) ;
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
    
    double c[3] = {
        color.r ,
        color.g,
        color.b
    } ;
    [FURenderer itemSetParamdv:items[FUItemTypeController] withName:key value:c length:3];
    
    if ([key isEqualToString:@"hair_color"]) {
        [FURenderer itemSetParam:items[FUItemTypeController] withName:@"hair_color_intensity" value:@(color.intensity)];
    }
}

/**
 获取色值 index
 -- key 具体参数如下：
     肤色： skin_color_index
     唇色： lip_color_index
 
 @param key  参数名
 @return     色值 index
 */
- (int)facePupGetColorIndexWithKey:(NSString *)key {
    
    double index = [FURenderer getDoubleParamFromItem:items[FUItemTypeController] withName:key];
    return (int)index ;
}

/**
 设置颜色
 -- 默认设置 肤色、唇色、瞳色。
 -- 如果有 头发、眼镜、胡子、帽子等，会设置其相应的颜色，没有则不设
 */
- (void)setAvatarColors {
    
    // skin color
    if (self.skinColor) {
        [self facepupModeSetColor:self.skinColor key:@"skin_color"];
    }
    
    // lip color
    if (self.lipColor) {
        [self facepupModeSetColor:self.lipColor key:@"lip_color"];
    }
    
    // iris color
    if (self.irisColor) {
        [self facepupModeSetColor:self.irisColor key:@"iris_color"];
    }
    
    // hair color
    if (self.hairColor) {
        [self facepupModeSetColor:self.hairColor key:@"hair_color"];
    }
    
    // glasses color
    if (self.glassColor) {
        [self facepupModeSetColor:self.glassColor key:@"glass_color"];
    }
    
    // glasses frame color
    if (self.glassFrameColor) {
        [self facepupModeSetColor:self.glassFrameColor key:@"glass_frame_color"];
    }
    
    // beard color
    if (self.beardColor) {
        [self facepupModeSetColor:self.beardColor key:@"beard_color"];
    }
    
    // hat color
    if (self.hatColor) {
        [self facepupModeSetColor:self.hatColor key:@"hat_color"];
    }
}


#pragma mark ----- setter

-(void)setSkinLevel:(double)skinLevel {
    _skinLevel = skinLevel ;
    
    NSString *jsonPath = [[AvatarListPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
    NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    if (tmpData != nil) {
        NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
        
        [dic setObject:@(skinLevel) forKey:@"skin_level"];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        [jsonData writeToFile:jsonPath atomically:YES];
    }
}

-(void)setSkinColor:(FUP2AColor *)skinColor {
    _skinColor = skinColor ;
    
    if (skinColor != nil) {
        NSDictionary *dicInfo = @{@"r":@(skinColor.r), @"g":@(skinColor.g), @"b":@(skinColor.b), @"intensity":@(skinColor.intensity), @"index":@(skinColor.index)};
        [self rewriteJsonInfoWithKey:@"skin_color" dict:dicInfo];
    }
}

-(void)setLipColor:(FUP2AColor *)lipColor {
    _lipColor = lipColor ;
    
    if (lipColor != nil) {
        NSDictionary *dicInfo = @{@"r":@(lipColor.r), @"g":@(lipColor.g), @"b":@(lipColor.b), @"intensity":@(lipColor.intensity), @"index":@(lipColor.index)};
        [self rewriteJsonInfoWithKey:@"lip_color" dict:dicInfo];
    }
}

-(void)setIrisColor:(FUP2AColor *)irisColor {
    _irisColor = irisColor ;
    
    if (irisColor != nil) {
        NSDictionary *dicInfo = @{@"r":@(irisColor.r), @"g":@(irisColor.g), @"b":@(irisColor.b), @"intensity":@(irisColor.intensity), @"index":@(irisColor.index)};
        [self rewriteJsonInfoWithKey:@"iris_color" dict:dicInfo];
    }
}

-(void)setHairColor:(FUP2AColor *)hairColor {
    _hairColor = hairColor ;
    
    if (hairColor != nil) {
        NSDictionary *dicInfo = @{@"r":@(hairColor.r), @"g":@(hairColor.g), @"b":@(hairColor.b), @"intensity":@(hairColor.intensity), @"index":@(hairColor.index)};
        [self rewriteJsonInfoWithKey:@"hair_color" dict:dicInfo];
    }
}

-(void)setGlassColor:(FUP2AColor *)glassColor {
    _glassColor = glassColor ;
    
    if (glassColor != nil) {
        NSDictionary *dicInfo = @{@"r":@(glassColor.r), @"g":@(glassColor.g), @"b":@(glassColor.b), @"intensity":@(glassColor.intensity), @"index":@(glassColor.index)};
        [self rewriteJsonInfoWithKey:@"glass_color" dict:dicInfo];
    }
}

-(void)setGlassFrameColor:(FUP2AColor *)glassFrameColor {
    _glassFrameColor = glassFrameColor ;
    
    if (glassFrameColor != nil) {
        NSDictionary *dicInfo = @{@"r":@(glassFrameColor.r), @"g":@(glassFrameColor.g), @"b":@(glassFrameColor.b), @"intensity":@(glassFrameColor.intensity), @"index":@(glassFrameColor.index)};
        [self rewriteJsonInfoWithKey:@"glass_frame_color" dict:dicInfo];
    }
}

-(void)setBeardColor:(FUP2AColor *)beardColor {
    _beardColor = beardColor ;
    
    if (beardColor != nil) {
        NSDictionary *dicInfo = @{@"r":@(beardColor.r), @"g":@(beardColor.g), @"b":@(beardColor.b), @"intensity":@(beardColor.intensity), @"index":@(beardColor.index)};
        [self rewriteJsonInfoWithKey:@"beard_color" dict:dicInfo];
    }
}

-(void)setHatColor:(FUP2AColor *)hatColor {
    _hatColor = hatColor ;
    
    if (hatColor != nil) {
        NSDictionary *dicInfo = @{@"r":@(hatColor.r), @"g":@(hatColor.g), @"b":@(hatColor.b), @"intensity":@(hatColor.intensity), @"index":@(hatColor.index)};
        [self rewriteJsonInfoWithKey:@"hat_color" dict:dicInfo];
    }
}

- (void)rewriteJsonInfoWithKey:(NSString *)key dict:(NSDictionary *)dict {
    
    NSString *jsonPath = [[AvatarListPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
    NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    if (tmpData != nil) {
        NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
        
        [dic setObject:dict forKey:key];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        [jsonData writeToFile:jsonPath atomically:YES];
    }
}


/**
 设置参数
 
 @param key     参数名
 @param value   参数值
 */
- (void)avatarSetParamWithKey:(NSString *)key value:(double)value {
    [FURenderer itemSetParam:items[FUItemTypeController] withName:key value:@(value)];
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
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"animFrameId" value:@0];
    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"animState" value:@1.0];
}

-(NSString *)eyeLash {
    if (!_eyeLash) {
        _eyeLash = @"eyelash-noitem" ;
    }
    return _eyeLash ;
}

-(NSString *)eyeBrow {
    if (!_eyeBrow) {
        _eyeBrow = @"eyebrow-noitem" ;
    }
    return _eyeBrow ;
}

@end
