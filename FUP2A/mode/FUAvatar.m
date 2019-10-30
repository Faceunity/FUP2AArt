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
		[self addPropertyObserver];
		signal = dispatch_semaphore_create(1) ;
		
	}
	return self ;
}
-(void)addPropertyObserver{
	NSArray * propertyArray = @[@"hairColorIndex",@"hair",@"skinColorProgress",@"face",@"irisLevel",@"eyes",@"lipsLevel",@"mouth",@"nose",@"beard",@"glasses",@"glassColorIndex",@"glassFrameColorIndex",@"hat",@"clothes"];
	for (NSString * propertyStr in propertyArray) {
		[self addObserver:self forKeyPath:propertyStr options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:propertyStr options:NSKeyValueObservingOptionOld context:NULL];
		
	}
	
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
	avatar.createdHairBundles = [dict[@"createdHairBundles"] integerValue];
	if (avatar.defaultModel || !avatar.isQType) {
		avatar.createdHairBundles = true;
	}
	if (!avatar.createdHairBundles) {
		[[FUManager shareInstance] reCreateHairBundles:avatar];
	}
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
	
	avatar.irisLevel = [dict[fu_iris_color_index] doubleValue];
	avatar.lipsLevel = [dict[fu_lip_color_index] doubleValue];
	
	avatar.skinColorProgress = [dict[fu_skin_color_progress] doubleValue];
	
	
	avatar.glassColorIndex = [dict[fu_glass_color_index] intValue];
	avatar.glassFrameColorIndex = [dict[fu_glass_frame_color_index] intValue];
	
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
	NSString *headPath = [self.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
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
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(100)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(10)];
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
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(230)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(60)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至显示 Q 版的鞋子
 */
- (void)resetScaleToShowShoes {
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(300)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(100)];
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
	NSString *headPath = [self.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
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
	if (!self.hairColor) {
		self.hairColor = [FUManager shareInstance].hairColorArray[0];
	}
	[self facepupModeSetColor:self.hairColor key:@"hair_color"];
	
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
-(void)setCreatedHairBundles:(BOOL)createdHairBundles{
	_createdHairBundles = createdHairBundles;
	NSString *jsonPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		[dic setObject:@(createdHairBundles) forKey:@"createdHairBundles"];
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}

-(void)setIrisLevel:(double)irisLevel{
	_irisLevel = irisLevel;
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		
		[dic setObject:@(irisLevel) forKey:fu_iris_color_index];
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}
-(void)setLipsLevel:(double)lipsLevel
{
	_lipsLevel = lipsLevel;
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		
		[dic setObject:@(lipsLevel) forKey:fu_lip_color_index];
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}
-(void)setSkinColorProgress:(double)skinColorProgress{
	_skinColorProgress = skinColorProgress;
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		
		[dic setObject:@(skinColorProgress) forKey:fu_skin_color_progress];
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}
-(void)setIrisColorProgress:(double)irisColorProgress
{
	_irisColorProgress = irisColorProgress;
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		
		
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}
-(void)setLipColorProgress:(double)lipColorProgress{
	_lipColorProgress = lipColorProgress;
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}


-(void)setSkinColor:(FUP2AColor *)skinColor {
	_skinColor = skinColor;
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
-(void)setGlassColorIndex:(int)glassColorIndex{
	_glassColorIndex = glassColorIndex;
	
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		[dic setObject:@(glassColorIndex) forKey:fu_glass_color_index];
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}
-(void)setGlassFrameColorIndex:(int)glassFrameColorIndex{
	_glassFrameColorIndex = glassFrameColorIndex;
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		[dic setObject:@(glassFrameColorIndex) forKey:fu_glass_frame_color_index];
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
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
	
	NSString *jsonPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
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

-(NSString *)description{
	unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList([self class], &outCount);
	NSMutableString * descriptionString = [NSMutableString string];
	for(i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		const char *propName = property_getName(property);
		if(propName) {
			NSString *propertyName = [NSString stringWithCString:propName
														encoding:[NSString defaultCStringEncoding]];
			id value = [self valueForKey:propertyName];
			[descriptionString appendFormat:@"%@", [NSString stringWithFormat:@"%@:%@\n",propertyName,value]];
		}
	}
	free(properties);
	return descriptionString;
	
}
-(void)setTheDefaultColors{
	
	NSDictionary * dict = @{
		@"iris_color": @{@"r":@(105), @"g":@(66), @"b":@(45)},
		@"hair_color" :@{@"r":@(31), @"g":@(31), @"b":@(31), @"intensity":@(1.0)},
		@"beard_color" :@{@"r":@(0), @"g":@(0), @"b":@(0)}
	};
	int skin_color_index = [self facePupGetColorIndexWithKey:@"skin_color_index"];
	self.skinColor = [FUManager shareInstance].skinColorArray[(skin_color_index >=0) ? skin_color_index : 0];
	self.skinColorProgress = skin_color_index * (1.0 / [FUManager shareInstance].skinColorArray.count);
	int fu_lip_color_index_t = [self facePupGetColorIndexWithKey:fu_lip_color_index];
	self.lipColor =[FUManager shareInstance].lipColorArray[(fu_lip_color_index_t >=0) ? fu_lip_color_index_t : 0];
	self.lipsLevel = fu_lip_color_index_t;
	//	self.lipColorProgress = fu_lip_color_index_t * (1.0 / [FUManager shareInstance].lipColorArray.count);
	self.irisColor = [FUP2AColor colorWithDict:dict[@"iris_color"]] ;
	self.hairColor = [FUP2AColor colorWithDict:dict[@"hair_color"]] ;
	self.glassColor = [FUP2AColor colorWithDict:dict[@"glass_color"]] ;
	self.glassFrameColor = [FUP2AColor colorWithDict:dict[@"glass_frame_color"]] ;
	self.beardColor = [FUP2AColor colorWithDict:dict[@"beard_color"]] ;
	self.hatColor = [FUP2AColor colorWithDict:dict[@"hat_color"]] ;
}
-(void)recordOriginalColors{
	NSArray * colorArray = @[@"hair",@"hairColorIndex",@"hair_color",@"skinColorProgress",@"skin_color",@"iris_color",@"lip_color",@"glasses",@"glass_color",@"glass_frame_color",@"hat",@"hat_color",@"irisLevel",@"lipsLevel",@"beard",@"clothes"];
	NSMutableDictionary * colorsDic = [NSMutableDictionary dictionary];
	for (NSString *name in colorArray) {
		NSRegularExpression *regularExpression1 = [NSRegularExpression regularExpressionWithPattern:
												                                         @"_c" options:0 error:nil];
		                                      
		         NSString * name1  = [regularExpression1 stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, name.length) withTemplate:@"C"];
		 		NSRegularExpression *regularExpression2 = [NSRegularExpression regularExpressionWithPattern:
														                                         @"_f" options:0 error:nil];
		NSString * name2  = [regularExpression2 stringByReplacingMatchesInString:name1 options:0 range:NSMakeRange(0, name1.length) withTemplate:@"F"];
		if ([self valueForKey:name2] == nil) {
			colorsDic[name2] = nil;
		}else{
			if ([[self valueForKey:name2] isKindOfClass:[FUP2AColor class]]) {
				FUP2AColor* color = [self valueForKey:name2];
				colorsDic[name2] = color;
			}else{
				NSNumber * level = [self valueForKey:name2];
				colorsDic[name2] = level;
			}
		}
	}
	self.orignalColorDic = colorsDic;
}
-(void)backToOriginalColors{
	NSArray * colorArray = @[@"hair",@"hairColorIndex",@"hair_color",@"skinColorProgress",@"skin_color",@"iris_color",@"lip_color",@"glasses",@"glass_color",@"glass_frame_color",@"hat",@"hat_color",@"irisLevel",@"lipsLevel",@"beard",@"clothes"];
	for (NSString *name in colorArray) {
		NSRegularExpression *regularExpression1 = [NSRegularExpression regularExpressionWithPattern:
												                                         @"_c" options:0 error:nil];
		                                      
		         NSString * name1  = [regularExpression1 stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, name.length) withTemplate:@"C"];
		 		NSRegularExpression *regularExpression2 = [NSRegularExpression regularExpressionWithPattern:
														                                         @"_f" options:0 error:nil];
		NSString * name2  = [regularExpression2 stringByReplacingMatchesInString:name1 options:0 range:NSMakeRange(0, name1.length) withTemplate:@"F"];
		id color = [self.orignalColorDic valueForKey:name2];
		[self setValue:color forKey:name2];
		
	}
	self.orignalColorDic = nil;
}

// 配置 “撤销”  和 “重做”
// 记录当前配置   用于在编辑时
-(NSDictionary*)recordCurrentStateConfig{
	NSDictionary * colorsDic = [self getColorsDictionary];
	NSMutableDictionary * infoDic = [NSMutableDictionary dictionaryWithDictionary:colorsDic];
	NSArray * propertyArray = @[@"hair",@"clothes",@"glasses",@"shoes",@"beard",@"hat",@"eyeLash",@"eyeBrow",@"face",@"eyes",@"mouth",@"nose"];
	for (NSString *name in propertyArray) {
		if ([name isEqualToString: @"beard"] ||[name isEqualToString:@"body"] ||[name isEqualToString:@"clothes"] ||[name isEqualToString:@"glasses"] ||[name isEqualToString:@"hair"] ||[name isEqualToString:@"hat"]) {
			NSString * value = [self valueForKey:name];
			//			NSString * valueStr = [self addBundleExtension:value];
			if ([value containsString:@"noitem"]) {
			}else{
				infoDic[name] = value;
			}
		}else{
			NSString * value = [self valueForKey:name];
			if ([value containsString:@"noitem"]) {
			}else{
				infoDic[name] = value;
			}
		}
	}
	return infoDic;
}
// 复原目标配置
-(void)backToTheConifg:(NSDictionary*)dict{
	self.hair = dict[@"hair"] ;
	self.clothes = dict[@"clothes"] ;
	self.glasses = dict[@"glasses"] ;
	self.shoes = dict[@"shoes"];
	self.beard = dict[@"beard"] ;
	self.hat = dict[@"hat"] ;
	self.eyeLash = dict[@"eyeLash"] ;
	self.eyeBrow = dict[@"eyeBrow"] ;
	
	self.face = dict[@"face"] ;
	self.eyes = dict[@"eyes"] ;
	self.mouth = dict[@"mouth"] ;
	self.nose = dict[@"nose"] ;
	
	self.hairLabel = [dict[@"hair_label"] intValue];
	self.bearLabel = [dict[@"beard_label"] intValue];
	
	self.irisLevel = [dict[fu_iris_color_index] doubleValue];
	self.lipsLevel = [dict[fu_lip_color_index] doubleValue];
	
	self.skinColorProgress = [dict[fu_skin_color_progress] doubleValue];
	
	self.glassColorIndex = [dict[fu_glass_color_index] intValue];
	self.glassFrameColorIndex = [dict[fu_glass_frame_color_index] intValue];
	
	self.skinColor = [FUP2AColor colorWithDict:dict[@"skin_color"]] ;
	self.lipColor = [FUP2AColor colorWithDict:dict[@"lip_color"]] ;
	self.irisColor = [FUP2AColor colorWithDict:dict[@"iris_color"]] ;
	self.hairColor = [FUP2AColor colorWithDict:dict[@"hair_color"]] ;
	self.glassColor = [FUP2AColor colorWithDict:dict[@"glass_color"]] ;
	self.glassFrameColor = [FUP2AColor colorWithDict:dict[@"glass_frame_color"]] ;
	self.beardColor = [FUP2AColor colorWithDict:dict[@"beard_color"]] ;
	self.hatColor = [FUP2AColor colorWithDict:dict[@"hat_color"]] ;
}
// 专门监听avatar的编辑活动
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	FUAvatarEditManager * editManager = [FUAvatarEditManager sharedInstance];
	if (!editManager.enterEditVC || editManager.undo || editManager.redo) {
		return;
	}
	NSLog(@"observeValueForKeyPath-------------change-----%@-------%@",change,keyPath);
	if (editManager.hadNotEdit) {
		NSMutableDictionary * oldConfig = [NSMutableDictionary dictionary];
		
		if (change[@"old"] == nil || [change[@"old"] isEqual:[NSNull null]]) {
			if ([keyPath isEqualToString:@"face"]) {
				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultHeadParams];
				oldConfig[keyPath] = faceParamDict;
			}else if ([keyPath isEqualToString:@"irisLevel"] || [keyPath isEqualToString:@"eyes"]) {
				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultEyesParams];
				oldConfig[@"eyes"] = faceParamDict;
				oldConfig[@"irisLevel"] = @(self.skinColorProgress);
				[editManager push:oldConfig];
			}else if ([keyPath isEqualToString:@"mouth"] || [keyPath isEqualToString:@"lipsLevel"]) {
				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultMouthParams];
				oldConfig[@"mouth"] = faceParamDict;
				oldConfig[@"lipsLevel"] = @(self.skinColorProgress);
				[editManager push:oldConfig];
			}else if ([keyPath isEqualToString:@"nose"]) {
				NSDictionary * noseParamDict = [[FUShapeParamsMode shareInstance] getDefaultNoseParams];
				oldConfig[keyPath] = noseParamDict;
			}else{
				oldConfig[keyPath] = change[@"old"];
			}
			editManager.orignalStateDic = oldConfig;
			
			
		}else{
			oldConfig[keyPath] = change[@"old"];
			editManager.orignalStateDic = oldConfig;
			
		}
		editManager.hadNotEdit = NO;
	}else if (change[@"old"] != nil){
		// lipsLevel
		NSMutableDictionary * oldConfig = [NSMutableDictionary dictionary];
		if ([keyPath isEqualToString:@"hairColorIndex"] || [keyPath isEqualToString:@"hair"]){
			if (![editManager exsit:@"hair"]) {
				oldConfig[keyPath] = change[@"old"];
				[editManager push:oldConfig];
			}
		}else if ([keyPath isEqualToString:@"skinColorProgress"] || [keyPath isEqualToString:@"face"]) {
			if (![editManager exsit:keyPath]) {
				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultHeadParams];
				oldConfig[@"face"] = faceParamDict;
				oldConfig[@"skinColorProgress"] = @(self.skinColorProgress);
				[editManager push:oldConfig];
			}
		}else if ([keyPath isEqualToString:@"irisLevel"] || [keyPath isEqualToString:@"eyes"]) {
			if (![editManager exsit:@"eyes"]) {
				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultEyesParams];
				oldConfig[@"eyes"] = faceParamDict;
				oldConfig[@"irisLevel"] = @(self.skinColorProgress);
				[editManager push:oldConfig];
			}
		}else if ([keyPath isEqualToString:@"mouth"] || [keyPath isEqualToString:@"lipsLevel"]) {
			if (![editManager exsit:@"mouth"]) {
				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultMouthParams];
				oldConfig[@"mouth"] = faceParamDict;
				oldConfig[@"lipsLevel"] = @(self.skinColorProgress);
				[editManager push:oldConfig];
			}
		}else if ([keyPath isEqualToString:@"nose"]) {
			if (![editManager exsit:@"nose"]) {
				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultNoseParams];
				oldConfig[keyPath] = faceParamDict;
				[editManager push:oldConfig];
			}
		}else if ([keyPath isEqualToString:@"beard"]) {
			if (![editManager exsit:@"beard"]) {
				oldConfig[keyPath] = change[@"old"];
				[editManager push:oldConfig];
			}
		}else if ([keyPath isEqualToString:@"glasses"] || [keyPath isEqualToString:@"glassColorIndex"] || [keyPath isEqualToString:@"glassFrameColorIndex"]) {
			if (![editManager exsit:@"glasses"]) {
				oldConfig[keyPath] = change[@"old"];
				[editManager push:oldConfig];
			}
		}else if ([keyPath isEqualToString:@"hat"]) {
			if (![editManager exsit:@"hat"]) {
				oldConfig[keyPath] = change[@"old"];
				[editManager push:oldConfig];
			}
		}else if ([keyPath isEqualToString:@"clothes"]) {
			if (![editManager exsit:@"clothes"]) {
				oldConfig[keyPath] = change[@"old"];
				[editManager push:oldConfig];
			}
		}
	}else if (change[@"new"] != nil){
		NSDictionary *newConfig;
		// lipsLevel
		if ([keyPath isEqualToString:@"hairColorIndex"] || [keyPath isEqualToString:@"hair"]){
			newConfig  = [NSDictionary dictionaryWithObjectsAndKeys:@(self.hairColorIndex),@"hairColorIndex",self.hair,@"hair", nil];
		}else if ([keyPath isEqualToString:@"skinColorProgress"] || [keyPath isEqualToString:@"face"]) {
			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:@(self.skinColorProgress),@"skinColorProgress",self.face,@"face",nil];
		}else if ([keyPath isEqualToString:@"irisLevel"] || [keyPath isEqualToString:@"eyes"]) {
			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:@(self.irisLevel),@"irisLevel",self.eyes,@"eyes",nil];
		}else if ([keyPath isEqualToString:@"mouth"] || [keyPath isEqualToString:@"lipsLevel"]) {
			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:@(self.lipsLevel),@"lipsLevel",self.mouth,@"mouth",nil];
		}else if ([keyPath isEqualToString:@"nose"]) {
			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.nose,@"nose",nil];
		}else if ([keyPath isEqualToString:@"beard"]) {
			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.beard,@"beard",nil];
		}else if ([keyPath isEqualToString:@"glasses"] || [keyPath isEqualToString:@"glassColorIndex"] || [keyPath isEqualToString:@"glassFrameColorIndex"]) {
			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:@(self.glassColorIndex),@"glassColorIndex",@(self.glassFrameColorIndex),@"glassFrameColorIndex",self.glasses,@"glasses", nil];
		}else if ([keyPath isEqualToString:@"hat"]) {
			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.hat,@"hat",nil];
		}
		else if ([keyPath isEqualToString:@"clothes"]) {
			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.clothes,@"clothes",nil];
		}
		[editManager push:newConfig];
	}
}

#pragma mark ----- 获取配置
// 将颜色FUP2AColor转为NSDictionary
-(NSDictionary*)getColorDicFromFUP2AColor:(FUP2AColor*)color{
	return @{@"r":@(color.r),@"g":@(color.g),@"b":@(color.b),@"intensity":@(color.intensity)};
}
// 获取avart所有的颜色字典
-(NSDictionary*)getColorsDictionary{
	NSArray * colorArray = @[@"skin_color",@"hair_color",@"beard_color",@"iris_color",@"lip_color",@"glass_color",@"glass_frame_color",@"hat_color"];
	NSMutableDictionary * colorsDic = [NSMutableDictionary dictionary];
	for (NSString *name in colorArray) {
		NSRegularExpression *regularExpression1 = [NSRegularExpression regularExpressionWithPattern:
												                                         @"_c" options:0 error:nil];
		                                      
		         NSString * name1  = [regularExpression1 stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, name.length) withTemplate:@"C"];
		 		NSRegularExpression *regularExpression2 = [NSRegularExpression regularExpressionWithPattern:
														                                         @"_f" options:0 error:nil];
		NSString * name2  = [regularExpression2 stringByReplacingMatchesInString:name1 options:0 range:NSMakeRange(0, name1.length) withTemplate:@"F"];
		FUP2AColor *color = [self valueForKey:name2];
		colorsDic[name] = [self getColorDicFromFUP2AColor:color];
	}
	
	NSArray * colorLevelArray = @[fu_iris_color_index,fu_lip_color_index,fu_skin_color_progress,fu_glass_color_index,fu_glass_frame_color_index];
	for (NSString *name in colorLevelArray) {
		NSNumber * level;
		if ([name isEqualToString:fu_iris_color_index]) {
			level = [self valueForKey:@"irisLevel"];
		}else if ([name isEqualToString:fu_lip_color_index]) {
			level = [self valueForKey:@"lipsLevel"];
		}else if ([name isEqualToString:fu_skin_color_progress]) {
			level = [self valueForKey:@"skinColorProgress"];
		}else if ([name isEqualToString:fu_glass_color_index]) {
			level = [self valueForKey:@"glassColorIndex"];
		}else if ([name isEqualToString:fu_glass_frame_color_index]) {
			level = [self valueForKey:@"glassFrameColorIndex"];
		}
		colorsDic[name] = level;
	}
	return colorsDic;
}
// 获取avart所有的配置字典
-(NSDictionary*)getInfoDictionary{
	NSDictionary * colorsDic = [self getColorsDictionary];
	NSMutableDictionary * infoDic = [NSMutableDictionary dictionaryWithDictionary:colorsDic];
	NSArray * propertyArray = @[@"name",@"hair",@"clothes",@"glasses",@"shoes",@"beard",@"hat",@"eyeLash",@"eyeBrow",@"face",@"eyes",@"mouth",@"nose"];
	for (NSString *name in propertyArray) {
		if ([name isEqualToString: @"gender"]){
			infoDic[name] = [self valueForKey:name];
		}else if ([name isEqualToString: @"beard"] ||[name isEqualToString:@"body"] ||[name isEqualToString:@"clothes"] ||[name isEqualToString:@"glasses"] ||[name isEqualToString:@"hair"] ||[name isEqualToString:@"hat"]) {
			NSString * value = [self valueForKey:name];
			//			NSString * valueStr = [self addBundleExtension:value];
			if ([value containsString:@"noitem"]) {
			}else{
				infoDic[name] = value;
			}
		}else{
			NSString * value = [self valueForKey:name];
			if ([value containsString:@"noitem"]) {
			}else{
				infoDic[name] = value;
			}
		}
	}
	infoDic[@"q_type"] = @(self.isQType);
	return infoDic;
}

-(id)copyWithZone:(NSZone *)zone{
	FUAvatar * copyAvatar = [[FUAvatar alloc]init];
	unsigned int outCount, i;
	objc_property_t *properties = class_copyPropertyList([self class], &outCount);
	for(i = 0; i < outCount; i++) {
		objc_property_t property = properties[i];
		const char *propName = property_getName(property);
		if(propName) {
			NSString *propertyName = [NSString stringWithCString:propName
														encoding:[NSString defaultCStringEncoding]];
			id value = [self valueForKey:propertyName];
			[copyAvatar setValue:value forKey:propertyName];
		}
	}
	// 复制的对象  重新设置一些属性
	copyAvatar.defaultModel = NO;
	copyAvatar.imagePath = nil;
	free(properties);
	return copyAvatar;
}
@end
