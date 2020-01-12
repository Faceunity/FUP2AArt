//
//  FUAvatar.m
//  P2A
//
//  Created by L on 2018/12/15.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUAvatar.h"
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
	FUItemTypeUpper,   // 上衣
	FUItemTypeLower,   // 裤子
	FUItemTypeShoes,   // 鞋子
	FUItemTypeDecorations,  // 配饰
	FUItemTypeAnimation,
	FUItemTypeEyeLash,
	FUItemTypeEyeBrow,
	FUItemTypeCamera,
	FUItemTypeTmp,
	FUItemTypeARFilter,    // 用于编辑AR滤镜的句柄
} FUItemType;

static const int tmpItemsCount  = 100;
@interface FUAvatar ()
{
	// 句柄数组
	int items[18] ;
	// 临时记录的句柄数组
	int tmpItems[tmpItemsCount] ;
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
/// 监听新老属性值变化
-(void)addPropertyObserver{
	NSArray * propertyArray =@[@"hairColorIndex",@"hair",@"skinColorProgress",@"irisLevel",@"lipsLevel",@"beard",@"glasses",@"glassColorIndex",@"glassFrameColorIndex",@"hat",@"clothes",@"upper",@"lower",@"shoes",@"decorations"];
   
	for (NSString * propertyStr in propertyArray) {
//		[self addObserver:self forKeyPath:propertyStr options:NSKeyValueObservingOptionNew context:NULL];
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
	// 本地化记录当前是否是否穿的是女性衣服，根据这个值做是否加载重新加载男女身体的判断
	avatar.wearFemaleClothes = [dict[@"wearFemaleClothes"] integerValue];
	// 当前穿的衣服类型
	avatar.clothType = (FUAvataClothType)[dict[@"clothType"] integerValue];
	avatar.hair = dict[@"hair"] ;
	if (dict[@"clothes"]) {
		avatar.clothes = dict[@"clothes"] ;
	}
	avatar.glasses = dict[@"glasses"] ;
	
	avatar.beard = dict[@"beard"] ;
	avatar.hat = dict[@"hat"] ;
	avatar.eyeLash = dict[@"eyeLash"] ;
	avatar.eyeBrow = dict[@"eyeBrow"] ;
	
	avatar.face = dict[@"face"] ;
	avatar.eyes = dict[@"eyes"] ;
	avatar.mouth = dict[@"mouth"] ;
	avatar.nose = dict[@"nose"] ;
	
	if (dict[@"upper"]) {
		avatar.upper = dict[@"upper"] ;    // 上衣
	}
	if (dict[@"lower"]) {
		avatar.lower = dict[@"lower"] ;    // 裤子
	}
	if (dict[@"shoes"]) {  // 鞋子
		avatar.shoes = dict[@"shoes"];
	}
	if (dict[@"decorations"]) {
		
		avatar.decorations = dict[@"decorations"] ;  // 配饰
	}
	
	
	avatar.hairLabel = [dict[@"hair_label"] intValue];
	avatar.bearLabel = [dict[@"beard_label"] intValue];
	
	avatar.skinColorProgress = [dict[fu_skin_color_progress] doubleValue];
	avatar.irisLevel = [dict[fu_iris_color_index] doubleValue];
	avatar.lipsLevel = [dict[fu_lip_color_index] doubleValue];
	
	
	
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
 加载 avatar 半身模型
 --  会加载 头、头发、身体、衣服、默认动作 四个道具。
 --  如果有 胡子、帽子、眼镜也会加载，没有则不加载。
 --  会设置 肤色、唇色、瞳色、发色(光头不设)。
 --  如果有 胡子、帽子、眼镜也会设置其对应颜色。
 
 @return 返回 controller 所在句柄
 */
- (int)loadHalfAvatar {
	
	// load controller
	if (items[FUItemTypeController] == 0) {
		items[FUItemTypeController] = [FUManager shareInstance].defalutQController;
	}
	
	
	// load Head
	NSString *headPath = [self.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
	[self loadItemWithtype:FUItemTypeHead filePath:headPath];
	
	// load Body
	NSString *bodyPath = [[NSBundle mainBundle] pathForResource:@"upperBody.bundle" ofType:nil];
	[self loadItemWithtype:FUItemTypeBody filePath:bodyPath];
	
	// load hair
	NSString *hairPath = [self.filePath stringByAppendingPathComponent:self.hair];
	[self reloadHairWithPath:hairPath];
	
	// load clothes
	NSString *clothes = @"male_cloth03_upper.bundle";
	NSString *clothesPath = [[NSBundle mainBundle] pathForResource:clothes ofType:nil] ;
	[self reloadClothesWithPath:clothesPath];
	
	// load glasses
	NSString *glasses = self.glasses;
	NSString *glassesPath = [[NSBundle mainBundle] pathForResource:glasses ofType: nil];
	[self reloadGlassesWithPath:glassesPath];
	
	// load hat
	NSString *hat = self.hat;
	NSString *hatPath = [[NSBundle mainBundle] pathForResource:hat ofType:nil];
	[self reloadHatWithPath:hatPath];
	
	// load beard
	NSString *beard = self.beard ;
	NSString *beardPath = [[NSBundle mainBundle] pathForResource:beard ofType:nil];
	[self reloadBeardWithPath:beardPath];
	
	// set colors
	[self setAvatarColors];
	
	return items[FUItemTypeController] ;
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
		items[FUItemTypeController] = [FUManager shareInstance].defalutQController;
	}
	
	
	// load Head
	NSString *headPath = [self.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
	[self loadItemWithtype:FUItemTypeHead filePath:headPath];
	
	// load Body
	NSString *bodyPath;
	if (self.isQType) {
		
		if (!self.wearFemaleClothes) {
			bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_male.bundle" ofType:nil] ;
		}else{
			bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_female.bundle" ofType:nil];
		}
	}else{
		bodyPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_body" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_body" ofType:@"bundle"];
	}
	[self loadItemWithtype:FUItemTypeBody filePath:bodyPath];
	
	// load hair
	NSString *hairPath = [self.filePath stringByAppendingPathComponent:self.hair];
	[self reloadHairWithPath:hairPath];
	if (self.isQType) {
		// load clothes
		if (self.clothType == FUAvataClothTypeSuit){
			
			NSString * clothesPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingFormat:@"/%@",self.clothes];
			[self reloadClothesWithPath:clothesPath];
		}else{
			NSString *upperPath = [[NSBundle mainBundle] pathForResource:self.upper ofType:nil];
			[self reloadUpperWithPath:upperPath];
			NSString *lowerPath = [[NSBundle mainBundle] pathForResource: self.lower ofType:nil] ;
			[self reloadLowerWithPath:lowerPath];
		}
	}else{
		
	}
	NSString *shoesPath = [[NSBundle mainBundle] pathForResource:self.shoes ofType:nil] ;
	
	[self reloadShoesWithPath:shoesPath];
	
	NSString *decorations = self.decorations;
	if (decorations != nil) {
		NSString *decorationsPath = [[NSBundle mainBundle] pathForResource:decorations ofType:nil] ;
		[self reloadDecorationsWithPath:decorationsPath];
	}
	
	
	
	// load glasses
	NSString *glasses = self.glasses;
	NSString *glassesPath = [[NSBundle mainBundle] pathForResource:glasses ofType: nil];
	[self reloadGlassesWithPath:glassesPath];
	
	// load hat
	NSString *hat = self.hat;
	NSString *hatPath = [[NSBundle mainBundle] pathForResource:hat ofType:nil];
	[self reloadHatWithPath:hatPath];
	
	// load beard
	NSString *beard = self.beard ;
	NSString *beardPath = [[NSBundle mainBundle] pathForResource:beard ofType:nil];
	[self reloadBeardWithPath:beardPath];
	
	// set colors
	[self setAvatarColors];
	
	return items[FUItemTypeController] ;
}

/**
 加载 明星avatar 模型
 --  会加载 头、头发、身体、衣服、默认动作 四个道具。
 --  如果有 胡子、帽子、眼镜也会加载，没有则不加载。
 --  会设置 肤色、唇色、瞳色、发色(光头不设)。
 --  如果有 胡子、帽子、眼镜也会设置其对应颜色。
 
 @return 返回 controller 所在句柄
 */
- (int)loadStarAvatar {
	
	// load controller
	if (items[FUItemTypeController] == 0) {
		items[FUItemTypeController] = [FUManager shareInstance].defalutQController;
	}
	
	
	// load Head
	
	
	// load Body
	NSString *bodyPath = [self.filePath stringByAppendingPathComponent:@"mg_star.bundle"];
	[self loadItemWithtype:FUItemTypeBody filePath:bodyPath];
	
	
	
	
	// set colors
	[self setAvatarColors];
	
	return items[FUItemTypeController] ;
}


/**
 avatar只加载头
 -- 默认加载头部装饰，包括：头、头发、胡子、眼镜、帽子
 -- 加载完毕之后会设置其相应颜色
 
 @return 返回 controller 句柄
 */
- (int)loadAvatarWithHeadOnly {
	
	// load controller
	if (items[FUItemTypeController] == 0) {
		items[FUItemTypeController] = [FUManager shareInstance].defalutQController;
	}
	
	
	// load Head
	NSString *headPath = [self.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
	[self loadItemWithtype:FUItemTypeHead filePath:headPath];
	
	// load Body
	[self loadItemWithtype:FUItemTypeBody filePath:nil];
	
	// load hair
	NSString *hairPath = [self.filePath stringByAppendingPathComponent:self.hair];
	[self reloadHairWithPath:hairPath];
	
	// load clothes
	[self reloadClothesWithPath:nil];
	
	// load glasses
	NSString *glasses = self.glasses;
	NSString *glassesPath = [[NSBundle mainBundle] pathForResource:glasses ofType: nil];
	[self reloadGlassesWithPath:glassesPath];
	
	// load hat
	NSString *hat = self.hat;
	NSString *hatPath = [[NSBundle mainBundle] pathForResource:hat ofType:nil];
	[self reloadHatWithPath:hatPath];
	
	// load beard
	NSString *beard = self.beard;
	NSString *beardPath = [[NSBundle mainBundle] pathForResource:beard ofType:nil];
	[self reloadBeardWithPath:beardPath];
	
	
	
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
#pragma mark --- 以下切换身体配饰

/**
 更换头发
 
 @param hairPath 新头发所在路径
 */
- (void)reloadHairWithPath:(NSString *)hairPath {
	[self loadItemWithtype:FUItemTypeHair filePath:hairPath];
}

/**
 更换身体
 
 @param bodyPath 新衣服所在路径
 */
- (void)reloadBodyWithPath:(NSString *)bodyPath {
	
	[self loadItemWithtype:FUItemTypeBody filePath:bodyPath];
}

/**
 更换衣服
 
 @param clothesPath 新衣服所在路径
 */
- (void)reloadClothesWithPath:(NSString *)clothesPath {
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    
    NSString * clothes = [[clothesPath lastPathComponent] stringByDeletingPathExtension];
    
	NSString * bodyPath;
	if ([[FUManager shareInstance].qMaleSuit containsObject:clothes]) {

		if (self.wearFemaleClothes) {
			bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_male.bundle" ofType:nil];
		}
		self.wearFemaleClothes = NO;
	}else if ([[FUManager shareInstance].qFemaleSuit containsObject:clothes])
	{

		if ( !self.wearFemaleClothes) {
			bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_female.bundle" ofType:nil];

		}
		self.wearFemaleClothes = YES;
	}


	if (clothesPath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:clothesPath])
    {
		dispatch_semaphore_signal(signal) ;
		return ;
	}
	
    // 创建套装道具
    int suitHandle = [FURenderer itemWithContentsOfFile:clothesPath];

	if (bodyPath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:bodyPath]) {
		
        [self destroyItemWithType:FUItemTypeUpper];
        [self destroyItemWithType:FUItemTypeLower];
		
		if (items[FUItemTypeController]) {
			[FURenderer bindItems:items[FUItemTypeController] items:&suitHandle itemsCount:1] ;
		}
		// 销毁套装道具
		[self destroyItemWithType:FUItemTypeClothes];
		// 绑定到 controller 上
		items[FUItemTypeClothes] = suitHandle;
        dispatch_semaphore_signal(signal) ;
		return ;
	}
	
	// 创建身体道具
	int bodyHandle = [FURenderer itemWithContentsOfFile:bodyPath];
	if (items[FUItemTypeController]) {
		[FURenderer bindItems:items[FUItemTypeController] items:&suitHandle itemsCount:1] ;
	}
	// 销毁套装道具
	[self destroyItemWithType:FUItemTypeClothes];
	// 绑定到 controller 上
	items[FUItemTypeClothes] = suitHandle;
	
	// 销毁身体道具
	[self destroyItemWithType:FUItemTypeBody];
	// 绑定到 controller 上
	items[FUItemTypeBody] = bodyHandle;
	if (items[FUItemTypeController]) {
		[FURenderer bindItems:items[FUItemTypeController] items:&items[FUItemTypeBody] itemsCount:1] ;
	}
    
    [self destroyItemWithType:FUItemTypeUpper];
    [self destroyItemWithType:FUItemTypeLower];
	
	dispatch_semaphore_signal(signal);
}


/**
 更换上衣
 
 @param upperPath 新上衣所在路径
 */
- (void)reloadUpperWithPath:(NSString *)upperPath {

	[self loadItemUpper:upperPath];
    [self destroyItemWithType:FUItemTypeClothes];
}

/**
 更换裤子
 
 @param lowerPath 新裤子所在路径
 */
- (void)reloadLowerWithPath:(NSString *)lowerPath {
    
	[self loadItemWithtype:FUItemTypeLower filePath:lowerPath];
    [self destroyItemWithType:FUItemTypeClothes];
}

/// 更换衣服和裤子
/// @param upperPath 新上衣的路径
/// @param lowerPath 新裤子的路径
- (void)reloadUpperWithPath:(NSString *)upperPath andLowerWithPath:(NSString *)lowerPath {
    
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    
    NSString * upper = [[upperPath lastPathComponent] stringByDeletingPathExtension];
    NSString * bodyPath;
    if ([[FUManager shareInstance].qMaleUpper containsObject:upper]) {
        
        if (self.wearFemaleClothes) {
            bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_male.bundle" ofType:nil];
        }
        self.wearFemaleClothes = NO;
    }else if ([[FUManager shareInstance].qFemaleUpper containsObject:upper])
    {
        
        if ( !self.wearFemaleClothes) {
            bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_female.bundle" ofType:nil];
        }
        self.wearFemaleClothes = YES;
    }
    
    
    if (upperPath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:upperPath]) {
        [self destroyItemWithType:FUItemTypeUpper];
        
        dispatch_semaphore_signal(signal) ;
        return ;
    }
    
    // 创建上衣道具
    int upperHandle = [FURenderer itemWithContentsOfFile:upperPath];
    // 创建裤子道具
    int lowerHandle = [FURenderer itemWithContentsOfFile:lowerPath];
    
    
    if (bodyPath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:bodyPath]) {
        
        if (items[FUItemTypeController]) {
            [FURenderer bindItems:items[FUItemTypeController] items:&upperHandle itemsCount:1] ;
        }
        // 销毁上衣道具
        [self destroyItemWithType:FUItemTypeUpper];
        // 绑定到 controller 上
        items[FUItemTypeUpper] = upperHandle;
        
        if (items[FUItemTypeController]) {
            [FURenderer bindItems:items[FUItemTypeController] items:&lowerHandle itemsCount:1] ;
        }
        // 销毁裤子道具
        [self destroyItemWithType:FUItemTypeLower];
        // 绑定到 controller 上
        items[FUItemTypeLower] = lowerHandle;
        [self destroyItemWithType:FUItemTypeClothes];
        NSLog(@"当前身体不存在---------");
        dispatch_semaphore_signal(signal) ;
        return ;
    }
    
    // 创建身体道具
    int bodyHandle = [FURenderer itemWithContentsOfFile:bodyPath];
    
    // 销毁上衣道具
    [self destroyItemWithType:FUItemTypeUpper];
    if (items[FUItemTypeController]) {
        [FURenderer bindItems:items[FUItemTypeController] items:&upperHandle itemsCount:1] ;
    }
    
    // 绑定到 controller 上
    items[FUItemTypeUpper] = upperHandle;
    
    // 销毁裤子道具
    [self destroyItemWithType:FUItemTypeLower];
    if (items[FUItemTypeController]) {
        [FURenderer bindItems:items[FUItemTypeController] items:&lowerHandle itemsCount:1] ;
    }

    // 绑定到 controller 上
    items[FUItemTypeLower] = lowerHandle;
    
    
    // 销毁身体道具
    [self destroyItemWithType:FUItemTypeBody];
    // 绑定到 controller 上
    items[FUItemTypeBody] = bodyHandle;
    if (items[FUItemTypeController]) {
        [FURenderer bindItems:items[FUItemTypeController] items:&items[FUItemTypeBody] itemsCount:1] ;
    }
    
    [self destroyItemWithType:FUItemTypeClothes];
    dispatch_semaphore_signal(signal);
}


/**
 更换配饰
 
 @param decorationsPath 新配饰所在路径
 */
- (void)reloadDecorationsWithPath:(NSString *)decorationsPath {
	[self loadItemWithtype:FUItemTypeDecorations filePath:decorationsPath];
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
 更换AR滤镜
 
 @param arFilterPath 新滤镜所在路径
 */
- (void)reloadARFilterWithPath:(NSString *)arFilterPath {
	[self loadItemWithtype:FUItemTypeARFilter filePath:arFilterPath];
}

/**
 去除动画
 */
- (void)removeAnimation {
	[self reloadAnimationWithPath:nil];
}

/**
 加载待机动画
 */
- (void)loadStandbyAnimation {
	NSString *animationPath ;
	if (self.isQType) {
		animationPath = [[NSBundle mainBundle] pathForResource:@"ani_huxi_hi.bundle" ofType:nil];
	}else {
		animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_animation" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_animation" ofType:@"bundle"] ;
	}
	[self reloadAnimationWithPath:animationPath];
}


/**
 加载ani_mg动画
 */
- (void)load_ani_mg_Animation {
	NSString *animationPath = [[NSBundle mainBundle] pathForResource:@"ani_mg.bundle" ofType:nil];
	[self reloadAnimationWithPath:animationPath];
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
	[self reloadAnimationWithPath:animationPath];
}
/**
 呼吸动画
 */
- (void)loadIdleModePose {
	NSString *animationPath;
	if (self.isQType) {
		animationPath = [[NSBundle mainBundle] pathForResource:@"ani_idle.bundle" ofType:nil];
	}else {
		animationPath = self.gender == FUGenderMale ? [[NSBundle mainBundle] pathForResource:@"male_pose" ofType:@"bundle"] : [[NSBundle mainBundle] pathForResource:@"female_pose" ofType:@"bundle"] ;
	}
	[self reloadAnimationWithPath:animationPath];
}

/**
 人脸追踪时加载 Pose
 */
- (void)loadPoseTrackAnim {}



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
	[self loadItemWithtype:FUItemTypeShoes filePath:shoesPath];
}
/**
 更新辅助道具
 
 @param tmpPath 辅助道具路径
 */
- (void)reloadTmpItemWithPath:(NSString *)tmpPath {
	[self loadItemWithtype:FUItemTypeTmp filePath:tmpPath];
}

// 加载controller道具
- (void)reloadControllerItemFilePath:(NSString *)path {}
// 加载普通道具
- (void)loadItemWithtype:(FUItemType)itemType filePath:(NSString *)path {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	BOOL isDirectory;
	BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
	
	if (path == nil || !isExist || isDirectory) {
		
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
// 添加普通道具，不销毁老的同类道具
- (int)addItemWithtype:(FUItemType)itemType filePath:(NSString *)path {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	if (path == nil || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		
		[self destroyItemWithType:itemType];
		
		dispatch_semaphore_signal(signal) ;
		return 0;
	}
	// 创建道具
	int tmpHandle = [FURenderer itemWithContentsOfFile:path];
	
	
	// 绑定到 controller 上
	items[itemType] = tmpHandle;
	
	if (items[FUItemTypeController] && itemType > 0) {
		[FURenderer bindItems:items[FUItemTypeController] items:&items[itemType] itemsCount:1] ;
	}
	return tmpHandle;
	dispatch_semaphore_signal(signal);
	
}
/// 添加临时道具，不销毁老的同类道具
/// @param handle 记录当前的句柄
/// @param path 动画文件路径
- (void)addItemWithHandle:(int*)handle filePath:(NSString *)path {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	// 创建道具
	int tmpHandle = [FURenderer itemWithContentsOfFile:path];
	
	
	// 绑定到 controller 上
	 *handle = tmpHandle;
	
	if (items[FUItemTypeController]) {
		[FURenderer bindItems:items[FUItemTypeController] items: handle itemsCount:1] ;
	}
	dispatch_semaphore_signal(signal);
	
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
// 加载上衣，解决与身体同时替换穿模的问题
- (void)loadItemUpper:(NSString *)upperPath {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    
	NSString * upper = [[upperPath lastPathComponent] stringByDeletingPathExtension];
	NSString * bodyPath;
	NSLog(@"loadItemUpper------upper-----%@-----",upperPath);
	if ([[FUManager shareInstance].qMaleUpper containsObject:upper]) {
		
		if (self.wearFemaleClothes) {
			bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_male.bundle" ofType:nil];
		}
		self.wearFemaleClothes = NO;
	}else if ([[FUManager shareInstance].qFemaleUpper containsObject:upper])
	{
		
		if ( !self.wearFemaleClothes) {
			bodyPath = [[NSBundle mainBundle] pathForResource:@"q_midBody_female.bundle" ofType:nil];
		}
		self.wearFemaleClothes = YES;
	}
	
	
	if (upperPath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:upperPath]) {
		[self destroyItemWithType:FUItemTypeUpper];
		
		dispatch_semaphore_signal(signal) ;
		return ;
	}
	
	// 创建上衣道具
	int upperHandle = [FURenderer itemWithContentsOfFile:upperPath];
	if (bodyPath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:bodyPath]) {
		
		
		if (items[FUItemTypeController]) {
			[FURenderer bindItems:items[FUItemTypeController] items:&upperHandle itemsCount:1] ;
		}
        // 销毁上衣道具
        [self destroyItemWithType:FUItemTypeUpper];
		// 绑定到 controller 上
		items[FUItemTypeUpper] = upperHandle;
		NSLog(@"当前身体不存在---------");
		dispatch_semaphore_signal(signal) ;
		return ;
	}
	
	// 创建身体道具
	int bodyHandle = [FURenderer itemWithContentsOfFile:bodyPath];
	

	if (items[FUItemTypeController]) {
		[FURenderer bindItems:items[FUItemTypeController] items:&upperHandle itemsCount:1] ;
	}
    // 销毁上衣道具
    [self destroyItemWithType:FUItemTypeUpper];
	// 绑定到 controller 上
	items[FUItemTypeUpper] = upperHandle;
	
	// 销毁身体道具
	[self destroyItemWithType:FUItemTypeBody];
    // 绑定到 controller 上
    items[FUItemTypeBody] = bodyHandle;
	if (items[FUItemTypeController]) {
		[FURenderer bindItems:items[FUItemTypeController] items:&items[FUItemTypeBody] itemsCount:1] ;
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




#pragma mark --- 以下缩放位移

/**
 设置缩放参数
 
 @param delta 缩放增量
 */
- (void)resetScaleDelta:(float)delta {
    int const current_position_count = 3;
    double current_position[current_position_count];
    [FURenderer itemGetParamdv:items[FUItemTypeController] withName:@"current_position" buffer:current_position length:current_position_count];
    NSLog(@"current_position[0]------------::%f----::%f----::%f",current_position[0],current_position[1],current_position[2]);
    if ((current_position[2] > 20 && delta > 0) || (current_position[2] < -1400 && delta < 0)) return;
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
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-145)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(8)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
	
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(100)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(5)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(1)];
}
/**
 缩放至截图
 */
- (void)resetScaleToScreenShot {
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(40)];   // 调整模型大小，值越小，模型越大
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-10)];  // 调整模型的上下位置，值越小，越靠下
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.0)];  // 调整模型的旋转角度
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(1)];       // 调用生效
	
}

/**
 捏脸模式缩放至面部正面
 */
- (void)resetScaleToShapeFaceFront {
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-10)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-2.0)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.0)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(3)];
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-15)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-12)];
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
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-15)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(-12)];
	//	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(-1)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0.125)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(3)];
}

/**
 缩放至全身
 */
- (void)resetScaleToBody {
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(220)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(70)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-150)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(2)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}


/**
 缩放至半身
 */
- (void)resetScaleToHalfBody {
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(220)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(70)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-450)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(2)];
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
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-507)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(60)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}
/// 缩小至全身并在屏幕左边显示
- (void)resetScaleSmallBodyToLeft {
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(350)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(120)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-1000)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(60)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"translation_x" value:@(-1)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}
/// 缩小至全身并在屏幕左边显示
- (void)resetScaleSmallBodyToRight {
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(350)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(120)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-1000)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(60)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"translation_x" value:@(1)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}
/// 缩小至全身并在屏幕上边显示
- (void)resetScaleSmallBodyToUp {
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(350)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(120)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-1000)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(120)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}
/// 缩小至全身并在屏幕下面显示
- (void)resetScaleSmallBodyToDown {
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(350)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(120)];
	//    [FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-1000)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}


/**
 缩放至显示 Q 版的鞋子
 */
- (void)resetScaleToShowShoes {
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-800)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(100)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}
/**
 缩放至小比例的身体跟随
 */
- (void)resetScaleToFollowBody {
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-600)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(60)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}

/**
 缩放至小比例的身体追踪
 */
- (void)resetScaleToTrackBody {
	
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_scale" value:@(-800)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_trans" value:@(80)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"target_angle" value:@(0)];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(6)];
}
/**
 将Avatar的位置设置为初始状态
 */
- (void)resetScaleToOriginal {
	double position[3] = {0,0,0};
	[FURenderer itemSetParamdv:items[FUItemTypeController] withName:@"target_position" value:position length:3];
	[FURenderer itemSetParam:items[FUItemTypeController] withName:@"reset_all" value:@(0.1)];
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
	fuItemSetParamd([FUManager shareInstance].defalutQController , "current_instance_id", index);
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
		items[FUItemTypeController] = [FUManager shareInstance].defalutQController;
	}
	
	

	// 主要是设置参数，只要设置一次就好
	[self enterARMode];
	// load Head
	NSString *headPath = [self.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
	[self loadItemWithtype:FUItemTypeHead filePath:headPath];
	
	// load hair
	NSString *hairPath = [self.filePath stringByAppendingPathComponent:self.hair];
	[self loadItemWithtype:FUItemTypeHair filePath:hairPath];
	
	// load glasses
	NSString *glasses = self.glasses;
	NSString *glassesPath = [[NSBundle mainBundle] pathForResource:glasses ofType: nil];
	[self loadItemWithtype:FUItemTypeGlasses filePath:glassesPath];
	
	// load beard
	NSString *beard = self.beard;
	NSString *beardPath = [[NSBundle mainBundle] pathForResource:beard ofType:nil];
	[self loadItemWithtype:FUItemTypeBeard filePath:beardPath];
	
	// load hat
	NSString *hat = self.hat;
	NSString *hatPath = [[NSBundle mainBundle] pathForResource:hat ofType:nil];
	[self loadItemWithtype:FUItemTypeHat filePath:hatPath];
	
	// load eye lash
	NSString *eyeLash = self.eyeLash;
	NSString *eyeLashPath = [[NSBundle mainBundle] pathForResource:eyeLash ofType:nil];
	[self loadItemWithtype:FUItemTypeEyeLash filePath:eyeLashPath];
	
	// load eyebrow
	NSString *eyeBrow = self.eyeBrow;
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
	//	NSLog(@"getMeshPointOfIndex-----x---------%f-------y------%f",x,y);
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

// 本地化记录当前是否是否穿的是女性衣服，根据这个值做是否加载重新加载男女身体的判断
-(void)setWearFemaleClothes:(BOOL)wearFemaleClothes{
	_wearFemaleClothes = wearFemaleClothes;
	NSString *jsonPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		[dic setObject:@(wearFemaleClothes) forKey:@"wearFemaleClothes"];
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}

/// 本地化记录当前衣服的类型，更具这个来确定衣服的加载方式
/// @param clothType FUAvataClothTypeSuit是套装 FUAvataClothTypeUpper是上衣
-(void)setClothType:(FUAvataClothType)clothType{
	_clothType = clothType;
	NSString *jsonPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		[dic setObject:@(clothType) forKey:@"clothType"];
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
	
}

/// 本地化皮肤的颜色等级，为了在编辑页选择相应的颜色图标
/// @param skinLevel =
-(void)setSkinLevel:(double)skinLevel{
	_skinLevel = skinLevel;
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		
		[dic setObject:@(skinLevel) forKey:fu_skin_color_index];
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}
/// 本地化眼镜的颜色等级m，为了在编辑页选择相应的颜色图标
/// @param irisLevel
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
/// 本地化嘴唇的颜色等级m，为了在编辑页选择相应的颜色图标
/// @param irisLevel
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
/// 本地化设置皮肤颜色进度条的值，用于在编辑页设置皮肤颜色进度的位置
/// @param skinColorProgress 当前颜色进度条的值
-(void)setSkinColorProgress:(double)skinColorProgress{
	_skinColorProgress = skinColorProgress;
	NSString *jsonPath = [[AvatarQPath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}
/// 本地化设置眼睛颜色进度条的值，用于在编辑页设置眼睛颜色进度的位置
/// @param irisColorProgress 当前颜色进度条的值
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
/// 本地化设置嘴唇颜色进度条的值，用于在编辑页设置嘴唇颜色进度的位置
/// @param irisColorProgress 当前颜色进度条的值
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


/// 设置当前avatar皮肤的颜色
/// @param skinColor 颜色值
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
- (void)rewriteJsonInfoWithKey:(NSString *)key value:(id)value {
	
	NSString *jsonPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:self.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		
		[dic setObject:value forKey:key];
		
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
	[self setCurrentAvatarIndex:self.currentInstanceId];   // 设置为当前操作的avatar，然后播放动画。
	[self stopAnimation];
	fuItemSetParamd(items[FUItemTypeController], "play_animation", [self getCurrentAnimationHandle]);
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
	
	fuItemSetParamd(items[FUItemTypeController], "enable_camera_animation",1);
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
		@"hair_color" :@{@"r":@(31), @"g":@(31), @"b":@(31), @"intensity":@(0.5)},
		@"beard_color" :@{@"r":@(0), @"g":@(0), @"b":@(0)},
		@"hat_color" :@{@"r":@(217), @"g":@(179), @"b":@(134)},
		@"glass_color" :@{@"r":@(52), @"g":@(52), @"b":@(52)},
		@"glass_frame_color" :@{@"r":@(25), @"g":@(25), @"b":@(25)},
	};
	int skin_color_index = [self facePupGetColorIndexWithKey:@"skin_color_index"];
	self.skinColor = [FUManager shareInstance].skinColorArray[(skin_color_index >=0) ? skin_color_index : 0];
	self.skinColorProgress = skin_color_index * (1.0 / [FUManager shareInstance].skinColorArray.count);
	int fu_lip_color_index_t = [self facePupGetColorIndexWithKey:fu_lip_color_index];
	self.lipColor =[FUManager shareInstance].lipColorArray[(fu_lip_color_index_t >=0) ? fu_lip_color_index_t : 0];
	//self.lipColorProgress = fu_lip_color_index_t * (1.0 / [FUManager shareInstance].lipColorArray.count);
	self.lipsLevel = fu_lip_color_index_t;
	self.irisColor = [FUP2AColor colorWithDict:dict[@"iris_color"]] ;
	self.hairColor = [FUP2AColor colorWithDict:dict[@"hair_color"]] ;
	self.glassColor = [FUP2AColor colorWithDict:dict[@"glass_color"]] ;
	self.glassFrameColor = [FUP2AColor colorWithDict:dict[@"glass_frame_color"]] ;
	self.beardColor = [FUP2AColor colorWithDict:dict[@"beard_color"]] ;
	self.hatColor = [FUP2AColor colorWithDict:dict[@"hat_color"]] ;
	
	
	// avatar info
	[self rewriteJsonInfoWithKey:fu_skin_color_progress value:@(self.skinColorProgress)];
	
	
}
/// 设置预制模型的颜色
-(void)setThePrefabricateColors{
	
	NSDictionary * dict = @{
		@"iris_color": @{@"r":@(105), @"g":@(66), @"b":@(45)},
		@"hair_color" :@{@"r":@(31), @"g":@(31), @"b":@(31), @"intensity":@(0.5)},
		@"beard_color" :@{@"r":@(0), @"g":@(0), @"b":@(0)},
		@"hat_color" :@{@"r":@(217), @"g":@(179), @"b":@(134)},
		@"glass_color" :@{@"r":@(52), @"g":@(52), @"b":@(52)},
		@"glass_frame_color" :@{@"r":@(25), @"g":@(25), @"b":@(25)},
	};
	self.irisColor = [FUP2AColor colorWithDict:dict[@"iris_color"]] ;
	self.hairColor = [FUP2AColor colorWithDict:dict[@"hair_color"]] ;
	self.glassColor = [FUP2AColor colorWithDict:dict[@"glass_color"]] ;
	self.glassFrameColor = [FUP2AColor colorWithDict:dict[@"glass_frame_color"]] ;
	self.beardColor = [FUP2AColor colorWithDict:dict[@"beard_color"]] ;
	self.hatColor = [FUP2AColor colorWithDict:dict[@"hat_color"]] ;
}
-(void)recordOriginalColors{
	NSArray * colorArray = @[@"hair",@"hairColorIndex",@"hair_color",@"skin_color",@"iris_color",@"lip_color",@"glasses",@"glass_color",@"glassColorIndex",@"glass_frame_color",@"glassFrameColorIndex",@"hat",@"hat_color",@"skinColorProgress",@"irisLevel",@"lipsLevel",@"beard",@"clothes",@"clothType",@"upper",@"lower",@"shoes",@"decorations"];
	NSMutableDictionary * colorsDic = [NSMutableDictionary dictionary];
	for (NSString *name in colorArray) {
		NSRegularExpression *regularExpression1 = [NSRegularExpression regularExpressionWithPattern:
												                                         @"_c" options:0 error:nil];
		                                      
		         NSString * name1  = [regularExpression1 stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, name.length) withTemplate:@"C"];
		 		NSRegularExpression *regularExpression2 = [NSRegularExpression regularExpressionWithPattern:
														                                         @"_f" options:0 error:nil];
		NSString * name2 = [regularExpression2 stringByReplacingMatchesInString:name1 options:0 range:NSMakeRange(0, name1.length) withTemplate:@"F"];
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
	NSArray * colorArray = @[@"hair",@"hairColorIndex",@"hair_color",@"skin_color",@"iris_color",@"lip_color",@"glasses",@"glass_color",@"glassColorIndex",@"glass_frame_color",@"glassFrameColorIndex",@"hat",@"hat_color",@"skinColorProgress",@"irisLevel",@"lipsLevel",@"beard",@"clothes",@"clothType",@"upper",@"lower",@"shoes",@"decorations"];
	for (NSString *name in colorArray) {
		NSRegularExpression *regularExpression1 = [NSRegularExpression regularExpressionWithPattern:
												                                         @"_c" options:0 error:nil];
		                                      
		         NSString * name1  = [regularExpression1 stringByReplacingMatchesInString:name options:0 range:NSMakeRange(0, name.length) withTemplate:@"C"];
		 		NSRegularExpression *regularExpression2 = [NSRegularExpression regularExpressionWithPattern:
														                                         @"_f" options:0 error:nil];
		NSString * name2 = [regularExpression2 stringByReplacingMatchesInString:name1 options:0 range:NSMakeRange(0, name1.length) withTemplate:@"F"];
		id color = [self.orignalColorDic valueForKey:name2];
		NSLog(@"1--------color---------------%@-------name2------%@",color,name2);
		[self setValue:color forKey:name2];
		NSLog(@"2--------color---------------%@-------name2------%@",color,name2);
		
	}
	self.orignalColorDic = nil;
}

// 配置 “撤销”  和 “重做”
// 记录当前配置   用于在编辑时
-(NSDictionary*)recordCurrentStateConfig{
	NSDictionary * colorsDic = [self getColorsDictionary];
	NSMutableDictionary * infoDic = [NSMutableDictionary dictionaryWithDictionary:colorsDic];
	NSArray * propertyArray = @[@"hair",@"clothes",@"upper",@"lower",@"shoes",@"decorations",@"glasses",@"shoes",@"beard",@"hat",@"eyeLash",@"eyeBrow",@"face",@"eyes",@"mouth",@"nose"];
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
	self.upper = dict[@"upper"];
	self.lower = dict[@"lower"];
	self.decorations = dict[@"decorations"];
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
	
	self.skinColorProgress = [dict[fu_skin_color_progress] doubleValue];
	self.irisLevel = [dict[fu_iris_color_index] doubleValue];
	self.lipsLevel = [dict[fu_lip_color_index] doubleValue];
	
	
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
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	FUAvatarEditManager * editManager = [FUAvatarEditManager sharedInstance];
	if (!editManager.enterEditVC || editManager.undo || editManager.redo)
    {    // 如果正在编辑，则返回
		return;
	}
    FUAvatarChangeModel *model = [[FUAvatarChangeModel alloc]init];
    
    if ([keyPath isEqualToString:@"clothes"])
    {
        if ([change[@"old"] isEqual:[NSNull null]]||[change[@"old"] rangeOfString:@"clothes-noitem"].length > 0)
        {//从上衣+下衣切换到套装
            model.oldConfig[@"upper"] = self.upper;
            model.oldConfig[@"lower"] = self.lower;
            model.currentConfig[@"clothes"] = self.clothes;
            self.clothType = FUAvataClothTypeSuit;
        }
        else if ([self.clothes isEqualToString:@"clothes-noitem"])
        {//从套装切换到上下衣
            model.oldConfig[@"clothes"] = change[@"old"];
            model.currentConfig[@"upper"] = @"shangyi_chushi";
            model.currentConfig[@"lower"] = @"kuzi_chushi";
            _upper = @"shangyi_chushi";
            _lower = @"kuzi_chushi";
            self.clothType = FUAvataClothTypeUpperAndLower;
        }
        else
        {//套装之间切换
            model.oldConfig[@"clothes"] = change[@"old"];
            model.currentConfig[@"clothes"] = self.clothes;
            self.clothType = FUAvataClothTypeSuit;
        }
    }
    else if ([keyPath isEqualToString:@"upper"])
    {
        model.oldConfig[@"upper"] = change[@"old"];
        model.currentConfig[@"upper"] = self.upper;
        
        if (self.clothType == FUAvataClothTypeSuit)
        {
            model.currentConfig[@"lower"] = @"kuzi_chushi";
            _lower = @"kuzi_chushi";
            self.clothType = FUAvataClothTypeUpperAndLower;
        }
    }
    else if ([keyPath isEqualToString:@"lower"])
    {
        model.oldConfig[@"lower"] = change[@"old"];
        model.currentConfig[@"lower"] = self.lower;
        if (self.clothType == FUAvataClothTypeSuit)
        {
            model.currentConfig[@"upper"] = @"shangyi_chushi";
            _upper = @"shangyi_chushi";
            self.clothType = FUAvataClothTypeUpperAndLower;
        }
    }
    else
    {
        model.oldConfig[keyPath] = change[@"old"];
        model.currentConfig[keyPath] = [self valueForKey:keyPath];
    }
    [editManager push:model];
    
    
    
//	if (editManager.hadNotEdit) {
//		NSMutableDictionary * oldConfig = [NSMutableDictionary dictionary];
//
//		if (change[@"old"] == nil || [change[@"old"] isEqual:[NSNull null]]) {
//			if ([keyPath isEqualToString:@"skinColorProgress"] || [keyPath isEqualToString:@"face"]) {
//				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultHeadParams];
//				oldConfig[keyPath] = faceParamDict;
//			}else if ([keyPath isEqualToString:@"irisLevel"] || [keyPath isEqualToString:@"eyes"]) {
//				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultEyesParams];
//				oldConfig[@"eyes"] = faceParamDict;
//				oldConfig[@"irisLevel"] = @(self.irisLevel);
//				[editManager push:oldConfig];
//			}else if ([keyPath isEqualToString:@"mouth"] || [keyPath isEqualToString:@"lipsLevel"]) {
//				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultMouthParams];
//				oldConfig[@"mouth"] = faceParamDict;
//				oldConfig[@"lipsLevel"] = @(self.lipsLevel);
//				[editManager push:oldConfig];
//			}else if ([keyPath isEqualToString:@"nose"]) {
//				NSDictionary * noseParamDict = [[FUShapeParamsMode shareInstance] getDefaultNoseParams];
//				oldConfig[keyPath] = noseParamDict;
//			}else{
//				oldConfig[keyPath] = change[@"old"];
//			}
//			editManager.orignalStateDic = oldConfig;
//
//
//		}else{
//            //处理一开始是上衣+下衣，但是avatars.json里面默认cloth是cloth_0的情况
//           if ([keyPath isEqualToString:@"clothes"] && [change[@"old"] isEqualToString:@"cloth_0.bundle"])
//           {
//                oldConfig[@"upper"] = self.upper;
//                oldConfig[@"lower"] = self.lower;
//                editManager.orignalStateDic = oldConfig;
//            }
//            else
//            {
//                oldConfig[keyPath] = change[@"old"];
//                editManager.orignalStateDic = oldConfig;
//                NSLog(@"FUTest %@",editManager.orignalStateDic);
//            }
//
//		}
//		editManager.hadNotEdit = NO;
//	}else if (change[@"old"] != nil&& ![change[@"old"] isEqual:[NSNull null]]){
//		// lipsLevel
//		NSMutableDictionary * oldConfig = [NSMutableDictionary dictionary];
//		if ([keyPath isEqualToString:@"hairColorIndex"] || [keyPath isEqualToString:@"hair"]){
//			if (![editManager exsit:@"hair"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"skinColorProgress"] || [keyPath isEqualToString:@"face"]) {
//			if (![editManager exsit:@"face"] || ![editManager exsit:@"skinColorProgress"]) {
//				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] resetHeadParams];
//				oldConfig[@"face"] = faceParamDict;
//				oldConfig[@"skinColorProgress"] = @(self.skinColorProgress);
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"irisLevel"] || [keyPath isEqualToString:@"eyes"]) {
//			if (![editManager exsit:@"eyes"]) {
//				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultEyesParams];
//				oldConfig[@"eyes"] = faceParamDict;
//				oldConfig[@"irisLevel"] = @(self.irisLevel);
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"mouth"] || [keyPath isEqualToString:@"lipsLevel"]) {
//			if (![editManager exsit:@"mouth"]) {
//				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultMouthParams];
//				oldConfig[@"mouth"] = faceParamDict;
//				oldConfig[@"lipsLevel"] = @(self.lipsLevel);
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"nose"]) {
//			if (![editManager exsit:@"nose"]) {
//				NSDictionary * faceParamDict = [[FUShapeParamsMode shareInstance] getDefaultNoseParams];
//				oldConfig[keyPath] = faceParamDict;
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"beard"]) {
//			if (![editManager exsit:@"beard"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"glasses"] || [keyPath isEqualToString:@"glassColorIndex"] || [keyPath isEqualToString:@"glassFrameColorIndex"]) {
//			if (![editManager exsit:@"glasses"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"hat"]) {
//			if (![editManager exsit:@"hat"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"clothes"] && self.clothType == FUAvataClothTypeSuit) {
//
//           //处理一开始是上衣+下衣，但是avatars.json里面默认cloth是cloth_0的情况
//            if ([change[@"old"] isEqualToString:@"cloth_0.bundle"])
//            {
//                 oldConfig[@"upper"] = self.upper;
//                 oldConfig[@"lower"] = self.lower;
//                 [editManager push:oldConfig];
//            }
//			else if (![editManager exsit:@"clothes"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"upper"] && self.clothType == FUAvataClothTypeUpper) {
//			if (![editManager exsit:@"upper"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"lower"] && self.clothType == FUAvataClothTypeLower) {
//			if (![editManager exsit:@"lower"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"shoes"]) {
//			if (![editManager exsit:@"shoes"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}else if ([keyPath isEqualToString:@"decorations"]) {
//			if (![editManager exsit:@"decorations"]) {
//				oldConfig[keyPath] = change[@"old"];
//				[editManager push:oldConfig];
//			}
//		}
//
//	}else if (change[@"new"] != nil){
//		NSDictionary *newConfig;
//		// lipsLevel
//		if ([keyPath isEqualToString:@"hairColorIndex"] || [keyPath isEqualToString:@"hair"]){
//			newConfig  = [NSDictionary dictionaryWithObjectsAndKeys:@(self.hairColorIndex),@"hairColorIndex",self.hair,@"hair", nil];
//		}else if ([keyPath isEqualToString:@"skinColorProgress"] || [keyPath isEqualToString:@"face"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:@(self.skinColorProgress),@"skinColorProgress",self.face,@"face",nil];
//		}else if ([keyPath isEqualToString:@"irisLevel"] || [keyPath isEqualToString:@"eyes"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:@(self.irisLevel),@"irisLevel",self.eyes,@"eyes",nil];
//		}else if ([keyPath isEqualToString:@"mouth"] || [keyPath isEqualToString:@"lipsLevel"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:@(self.lipsLevel),@"lipsLevel",self.mouth,@"mouth",nil];
//		}else if ([keyPath isEqualToString:@"nose"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.nose,@"nose",nil];
//		}else if ([keyPath isEqualToString:@"beard"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.beard,@"beard",nil];
//		}else if ([keyPath isEqualToString:@"glasses"] || [keyPath isEqualToString:@"glassColorIndex"] || [keyPath isEqualToString:@"glassFrameColorIndex"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:@(self.glassColorIndex),@"glassColorIndex",@(self.glassFrameColorIndex),@"glassFrameColorIndex",self.glasses,@"glasses", nil];
//		}else if ([keyPath isEqualToString:@"hat"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.hat,@"hat",nil];
//		}
//		else if ([keyPath isEqualToString:@"clothes"] && self.clothType == FUAvataClothTypeSuit) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.clothes,@"clothes",nil];
//		}
//		else if ([keyPath isEqualToString:@"upper"] && self.clothType == FUAvataClothTypeUpper) {
//			NSDictionary * undoTopDic = editManager.undoStack.top;
//			BOOL lastIsChushi = NO;
//			for (NSString * valueStr in undoTopDic.allValues) {
//                if ([valueStr isKindOfClass:[NSString class]])
//                {
//                    if ([valueStr containsString:@"chushi"] && [self.upper containsString:@"chushi"]) {       // 如果上一个记录里面已经有默认初始的上衣和裤子，则移除，重新添加，避免存在重复的记录
//                        [editManager.undoStack pop];
//                        lastIsChushi = YES;
//                    }
//                }
//			}
//			if (lastIsChushi) {
//				newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.upper,@"upper",@"kuzi_chushi",@"lower",nil];
//			}else{
//				newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.upper,@"upper",nil];
//			}
//		}else if ([keyPath isEqualToString:@"lower"] && self.clothType == FUAvataClothTypeLower) {
//			NSDictionary * undoTopDic = editManager.undoStack.top;
//			BOOL lastIsChushi = NO;
//			for (NSString * valueStr in undoTopDic.allValues) {
//				if ([valueStr containsString:@"chushi"] && [self.lower containsString:@"chushi"]) {       // 如果上一个记录里面已经有默认初始的上衣和裤子，则移除，重新添加，避免存在重复的记录
//					[editManager.undoStack pop];
//					lastIsChushi = YES;
//				}
//			}
//			if (lastIsChushi) {
//				newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.lower,@"lower",@"shangyi_chushi",@"upper",nil];
//			}else{
//				newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.lower,@"lower",nil];
//			}
//		}
//		else if ([keyPath isEqualToString:@"shoes"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.shoes,@"shoes",nil];
//		}
//		else if ([keyPath isEqualToString:@"decorations"]) {
//			newConfig = [NSDictionary dictionaryWithObjectsAndKeys:self.decorations,@"decorations",nil];
//		}
//		if (newConfig != nil) {
//			[editManager push:newConfig];
//		}
//	}
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
	NSArray * propertyArray = @[@"name",@"hair",@"clothes",@"upper",@"lower",@"shoes",@"decorations",@"glasses",@"shoes",@"beard",@"hat",@"eyeLash",@"eyeBrow",@"face",@"eyes",@"mouth",@"nose",@"wearFemaleClothes",@"clothType"];
	for (NSString *name in propertyArray) {
		if ([name isEqualToString: @"gender"] || [name isEqualToString: @"wearFemaleClothes"] || [name isEqualToString: @"clothType"]){
			infoDic[name] = [self valueForKey:name];
		}else if ([name isEqualToString: @"beard"] ||[name isEqualToString:@"body"] ||[name isEqualToString:@"clothes"] ||[name isEqualToString:@"upper"] ||[name isEqualToString:@"lower"] ||[name isEqualToString:@"shoes"] ||[name isEqualToString:@"decorations"] ||[name isEqualToString:@"glasses"] ||[name isEqualToString:@"hair"] ||[name isEqualToString:@"hat"]) {
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
