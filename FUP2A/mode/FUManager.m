//
//  FUManager.m
//  P2A
//
//  Created by L on 2018/12/17.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUManager.h"
#import "authpack.h"
#import "FURequestManager.h"
#import "FUAvatar.h"
#import "FUP2AColor.h"
@interface FUManager ()
{
	// render 句柄
	int mItems[7] ;
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
	// 同步信号量
	dispatch_semaphore_t signal;
	
	__block BOOL isCreatingAvatar ;
	
	int plane_mg_ptr;   // 全身驱动时的阴影句柄
	int hair_mask_ptr;  // hair_mask 句柄
	int q_controller_config_ptr;   // controller 配置文件道具句柄
	int q_controller_bg_ptr;   // 绑定在q_controller上的背景道具句柄
	int q_controller_cam;   // 绑定在q_controller上的_cam.bundle道具句柄
	
}
@end

@implementation FUManager

static FUManager *fuManager = nil ;
+ (instancetype)shareInstance {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		fuManager = [[FUManager alloc] init];
	});
	return fuManager ;
}

-(instancetype)init {
	self = [super init];
	if (self) {
		
		[self initFaceUnity];
		// 生成空buffer
		[self creatPixelBuffer];
		// 设置鉴权
		[[FUP2AHelper shareInstance] setupHelperWithAuthPackage:&g_auth_package authSize:sizeof(g_auth_package)];
		// 加载抗锯齿
		[self loadFxaa];
		
		// 加载舌头
		NSData *tongueData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tongue.bundle" ofType:nil]];
		[FURenderer loadTongueModel:(void *)tongueData.bytes size:(int)tongueData.length];
		

		
		self.currentAvatars = [NSMutableArray arrayWithCapacity:1];
		
		frameSize = CGSizeZero ;
		
		signal = dispatch_semaphore_create(1);
		
		isCreatingAvatar = NO ;
		
		
		
		NSString *controller =   @"q_controller.bundle";
		NSString *controllerPath = [[NSBundle mainBundle] pathForResource:controller ofType:nil];
		self.defalutQController = [FURenderer itemWithContentsOfFile:controllerPath];
		
		NSString *controller_config_path = [[NSBundle mainBundle] pathForResource:@"controller_config" ofType:@"bundle"];
		[self reBindItemWithToController:controller_config_path withPtr:&q_controller_config_ptr];
		
		
		NSString *bgPath = [[NSBundle mainBundle] pathForResource:@"default_bg.bundle" ofType:nil];
		[self reloadBackGroundAndBindToController:bgPath];
		
		
	}
	return self ;
}
/// 获取当前q_controller 里面捏脸参数的值
-(float*)getCurrenShapeValue{
	int arrCount = 91;
	float *shapeArr = malloc(sizeof(float)  * arrCount);
	
	[FURenderer itemGetParamfv:self.defalutQController withName:@"facepup_expression" buffer:shapeArr length:arrCount];
	return shapeArr;
}
-(void)setAvatarStyle:(FUAvatarStyle)avatarStyle {
	_avatarStyle = avatarStyle ;
	
	[self loadSubData];
}

- (void)initFaceUnity {
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"v3.bundle" ofType:nil];
	[[FURenderer shareRenderer] setupWithDataPath:path authPackage:&g_auth_package authSize:sizeof(g_auth_package) shouldCreateContext:YES];
	
	[FURenderer setMaxFaces:1];
}

- (void)loadSubData {
	switch (self.avatarStyle) {
		case FUAvatarStyleNormal:{
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarListPath]) {
				[[NSFileManager defaultManager] createDirectoryAtPath:AvatarListPath withIntermediateDirectories:YES attributes:nil error:nil];
			}
			[self loadNormalTypeSubData];
		}
			break;
		case FUAvatarStyleQ:{
			if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarQPath]) {
				[[NSFileManager defaultManager] createDirectoryAtPath:AvatarQPath withIntermediateDirectories:YES attributes:nil error:nil];
			}
			[self loadQtypeAvatarData];
		}
			break ;
	}
}

- (void)loadClientDataWithFirstSetup:(BOOL)firstSetup {
	
	NSString *qPath ;
	switch (self.avatarStyle) {
		case FUAvatarStyleNormal:{
			if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarListPath]) {
				[[NSFileManager defaultManager] createDirectoryAtPath:AvatarListPath withIntermediateDirectories:YES attributes:nil error:nil];
			}
			qPath =[[NSBundle mainBundle] pathForResource:@"p2a_client_q" ofType:@"bin"];
		}
			break;
		case FUAvatarStyleQ:{
			if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarQPath]) {
				[[NSFileManager defaultManager] createDirectoryAtPath:AvatarQPath withIntermediateDirectories:YES attributes:nil error:nil];
			}
			qPath =[[NSBundle mainBundle] pathForResource:@"p2a_client_q1" ofType:@"bin"];
		}
			break ;
	}
	// p2a bin
	if (firstSetup) {
		NSString *corePath = [[NSBundle mainBundle] pathForResource:@"p2a_client_core" ofType:@"bin"];
		[[fuPTAClient shareInstance] setupCore:corePath authPackage:&g_auth_package authSize:sizeof(g_auth_package)];
	}
	[[fuPTAClient shareInstance] setupCustomData:qPath];
}

- (void)creatPixelBuffer {
	
	CGSize size = [UIScreen mainScreen].currentMode.size;
	int width = size.width - (int)size.width % 2;    // 将奇数的屏幕宽度改为偶数，解决录制视频右边绿线的问题，例如 iphoneX  size.width == 1125
	if (!renderTarget) {
		NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
												  @(kCVPixelFormatType_32BGRA),
											  (NSString*) kCVPixelBufferWidthKey : @(width),
											  (NSString*) kCVPixelBufferHeightKey : @(size.height),
											  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
											  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
		CVPixelBufferCreate(kCFAllocatorDefault,
							width, size.height,
							kCVPixelFormatType_32BGRA,
							(__bridge CFDictionaryRef)pixelBufferOptions,
							&renderTarget);
	}
	
	if (!screenShotTarget) {
		NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
												  @(kCVPixelFormatType_32BGRA),
											  (NSString*) kCVPixelBufferWidthKey : @(460),
											  (NSString*) kCVPixelBufferHeightKey : @(630),
											  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
											  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
		CVPixelBufferCreate(kCFAllocatorDefault,
							460, 630,
							kCVPixelFormatType_32BGRA,
							(__bridge CFDictionaryRef)pixelBufferOptions,
							&screenShotTarget);
	}
}

//加载抗锯齿
- (void)loadFxaa {
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"fxaa" ofType:@"bundle"];
	mItems[0] = [FURenderer itemWithContentsOfFile:filePath];
}
/// 绑定背景道具到controller
/// @param filePath 新背景道具路径
-(void)reloadBackGroundAndBindToController:(NSString *)filePath
{
    [self reBindItemWithToController:filePath withPtr:&q_controller_bg_ptr];
   
}

/*
 背景道具是否存在
 
 @return 是否存在
 */
- (BOOL)isBackgroundItemExist {
	return mItems[1] != 0 ;
}
/**
 更新Cam道具
 
 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString *)camPath {
	 [self reBindItemWithToController:camPath withPtr:&q_controller_cam];
}
#pragma mark ----- 以下数据
-(NSString *)appVersion {
	NSString* versionStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	return [NSString stringWithFormat:@"DigiMe Art v%@",versionStr];
}

-(NSString *)sdkVersion {
	NSString *version = [[fuPTAClient shareInstance] getVersion];
	return [NSString stringWithFormat:@"SDK v%@", version] ;
}

/**     normal data **/
- (void)loadNormalTypeSubData {
	
	// female hairs
	NSArray *ornamentArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AvatarDecoration.plist" ofType:nil]];
	NSDictionary *expDic = ornamentArray[0] ;
	NSArray *tmpArr0 = expDic[@"items"] ;
	NSMutableArray *tmpArr1 = [tmpArr0 mutableCopy];
	
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"male"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_femaleHairs = [tmpArr1 copy];
	
	// male hairs
	tmpArr1 = [tmpArr0 mutableCopy];
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"female"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_maleHairs = [tmpArr1 copy];
	
	// female glasses
	expDic = ornamentArray[1] ;
	tmpArr0 = expDic[@"items"] ;
	[tmpArr1 removeAllObjects];
	tmpArr1 = [tmpArr0 mutableCopy];
	
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"male"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_femaleGlasses = [tmpArr1 copy] ;
	
	// male glasses
	tmpArr1 = [tmpArr0 mutableCopy];
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"female"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_maleGlasses = [tmpArr1 copy] ;
	
	// female clothes
	expDic = ornamentArray[2] ;
	tmpArr0 = expDic[@"items"] ;
	[tmpArr1 removeAllObjects];
	tmpArr1 = [tmpArr0 mutableCopy];
	
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"male"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_femaleClothes = [tmpArr1 copy] ;
	
	// male clothes
	tmpArr1 = [tmpArr0 mutableCopy];
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"female"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_maleClothes = [tmpArr1 copy] ;
	
	
	// male beard
	expDic = ornamentArray[3] ;
	tmpArr0 = expDic[@"items"] ;
	_maleBeards = tmpArr0 ;
	
	// female hat
	expDic = ornamentArray[4] ;
	tmpArr0 = expDic[@"items"] ;
	[tmpArr1 removeAllObjects];
	tmpArr1 = [tmpArr0 mutableCopy];
	
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"male"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_femaleHats = [tmpArr1 copy] ;
	
	// male clothes
	tmpArr1 = [tmpArr0 mutableCopy];
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"female"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_maleHats = [tmpArr1 copy] ;
	
	
	// female eyelash
	expDic = ornamentArray[5] ;
	tmpArr0 = expDic[@"items"] ;
	_femaleEyeLashs = tmpArr0 ;
	
	// female eyeBrow
	expDic = ornamentArray[6] ;
	tmpArr0 = expDic[@"items"] ;
	[tmpArr1 removeAllObjects];
	tmpArr1 = [tmpArr0 mutableCopy];
	
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"male"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_femaleEyeBrows = [tmpArr1 copy] ;
	
	// male clothes
	tmpArr1 = [tmpArr0 mutableCopy];
	for (NSString *item in tmpArr0) {
		if ([item hasPrefix:@"female"]) {
			[tmpArr1 removeObject:item];
		}
	}
	_maleEyeBrows = [tmpArr1 copy] ;
	
	
	// mesh points
	NSData *meshData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MeshPoints" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *meshDict = [NSJSONSerialization JSONObjectWithData:meshData options:NSJSONReadingMutableContainers error:nil];
	
	self.maleMeshPoints = meshDict[@"male"] ;
	self.femaleMeshPoints = meshDict[@"female"] ;
	
	// color data
	NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"color" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
	
	NSArray *keys = dic.allKeys ;
	for (NSString *key in keys) {
		NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:1];
		NSDictionary *infoDic = [dic objectForKey:key];
		
		NSInteger count = infoDic.allKeys.count ;
		
		for (int i = 1; i < count + 1; i ++) {
			
			NSString *subKey = [NSString stringWithFormat:@"%d", i];
			NSDictionary *subValue = [infoDic objectForKey:subKey] ;
			
			FUP2AColor *color = [FUP2AColor colorWithDict:subValue];
			color.index = i ;
			[tmpArray addObject:color];
		}
		
		if ([key isEqualToString:@"lip_color"]) {
			self.lipColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"iris_color"]){
			self.irisColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"hair_color"]){
			self.hairColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"beard_color"]){
			self.beardColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"glass_frame_color"]){
			self.glassFrameArray = [tmpArray copy];
		}else if ([key isEqualToString:@"glass_color"]){
			self.glassColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"skin_color"]){
			self.skinColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"hat_color"]){
			self.hatColorArray = [tmpArray copy];
		}
	}
	
	[self loadAvatarList];
}

- (void)loadQtypeAvatarData {
	
	// hairs
	NSArray *ornamentArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AvatarQDecoration.plist" ofType:nil]];
	
	NSDictionary *expDic = ornamentArray[0] ;
	_qHairs = expDic[@"items"] ;
	
	// glasses
	expDic = ornamentArray[1] ;
	_qGlasses = expDic[@"items"] ;
	
	// clothes
	expDic = ornamentArray[2] ;
	_qClothes = expDic[@"items"] ;
    _qMaleSuit = @[@"taozhuang_2",@"taozhuang_3",@"taozhuang_6",@"taozhuang_jiaju_2",@"taozhuang_lifu_1",@"taozhuang_lifu_2"];
//  @[@"cloth_1",@"cloth_2",@"cloth_19",@"taozhuang_nanmicaifu"];
	_qFemaleSuit = @[@"taozhuang_5",@"taozhuang_8",@"taozhuang_jiaju_1"];
	
	// hats
	expDic = ornamentArray[3] ;
	_qHats = expDic[@"items"] ;
	
	// shoes
	expDic = ornamentArray[4] ;
	_qShoes = expDic[@"items"] ;
	
	// eyelash
	expDic = ornamentArray[5] ;
	_qEyeLash = expDic[@"items"] ;
	// eyebrow
	expDic = ornamentArray[6] ;
	_qEyeBrow = expDic[@"items"] ;
	
	expDic = ornamentArray[7] ;
	_qBeard = expDic[@"items"];
	
	expDic = ornamentArray[8] ;
	_qUpper = expDic[@"items"];
	_qMaleUpper = @[@"shangyi_chushi",@"shangyi_maoyi_2",@"waitao_3"];
//  @[@"shangyi_chushi",@"shangyi_POLO_1",@"shangyi_Txu_1",@"shangyi_chenshan_1",@"shangyi_chenshan_2",@"shangyi_chenshan_3",@"shangyi_maoyi_1",@"shangyi_maoyi_2",@"shangyi_weiyi_1",@"shangyi_weiyi_2",@"shangyi_weiyi_3",@"cloth_1_upper",@"cloth_2_upper",@"cloth_19_upper",@"taozhuang_nanmicaifu_upper"];
	_qFemaleUpper = @[@"shangyi_chenshan_6",@"shangyi_maoyi_3",@"waitao_2",@"waitao_4"];
    
//    @[@"shangyi_chenshan_4",@"shangyi_chenshan_5",@"shangyi_chenshan_6",@"shangyi_diaodai_1",@"shangyi_maoyi_3",@"cloth_12_upper",@"cloth_14_upper",@"cloth_18_upper"];
	expDic = ornamentArray[9] ;
	_qLower = expDic[@"items"];
	expDic = ornamentArray[10] ;
	_qShoes = expDic[@"items"];
	expDic = ornamentArray[11] ;
	_qDecorations = expDic[@"items"];
	
	
	
	
	// mesh points
	NSData *meshData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MeshPoints" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *meshDict = [NSJSONSerialization JSONObjectWithData:meshData options:NSJSONReadingMutableContainers error:nil];
	
	self.qMeshPoints = meshDict[@"mid"] ;
	
	// color data
	NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"color_q" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
	
	NSArray *keys = dic.allKeys ;
	for (NSString *key in keys) {
		NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:1];
		NSDictionary *infoDic = [dic objectForKey:key];
		
		NSInteger count = infoDic.allKeys.count ;
		
		for (int i = 1; i < count + 1; i ++) {
			
			NSString *subKey = [NSString stringWithFormat:@"%d", i];
			NSDictionary *subValue = [infoDic objectForKey:subKey] ;
			
			FUP2AColor *color = [FUP2AColor colorWithDict:subValue];
			color.index = i ;
			[tmpArray addObject:color];
		}
		
		if ([key isEqualToString:@"lip_color"]) {
			self.lipColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"iris_color"]){
			self.irisColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"hair_color"]){
			self.hairColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"beard_color"]){
			self.beardColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"glass_frame_color"]){
			self.glassFrameArray = [tmpArray copy];
		}else if ([key isEqualToString:@"glass_color"]){
			self.glassColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"skin_color"]){
			self.skinColorArray = [tmpArray copy];
		}else if ([key isEqualToString:@"hat_color"]){
			self.hatColorArray = [tmpArray copy];
		}
	}
	
	// shape data
	NSData *shapeJson = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shape_list" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *shapeDict = [NSJSONSerialization JSONObjectWithData:shapeJson options:NSJSONReadingMutableContainers error:nil];
	
	NSArray *shapeKeys = shapeDict.allKeys ;
	for (NSString *key in shapeKeys) {
		NSArray *paramsArray = [shapeDict objectForKey:key];
		
		if ([key isEqualToString:@"face"]) {
			self.qFaces = paramsArray ;
		}else if ([key isEqualToString:@"eye"]){
			self.qEyes = paramsArray ;
		}else if ([key isEqualToString:@"mouth"]){
			self.qMouths = paramsArray ;
		}else if ([key isEqualToString:@"nose"]){
			self.qNoses = paramsArray ;
		}
	}
	
	[self loadAvatarList];
}

- (void)loadAvatarList {
	if (_avatarList) {
		[_avatarList removeAllObjects];
		_avatarList = nil ;
	}
	
	if (!_avatarList) {
		_avatarList = [NSMutableArray arrayWithCapacity:1];
		
		NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Avatars" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
		NSArray *dataArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
		
		for (NSDictionary *dict in dataArray) {
			
			if ([dict[@"q_type"] integerValue] != self.avatarStyle) {
				continue ;
			}
			
			FUAvatar *avatar = [FUAvatar avatarWithInfoDic:dict];
			[avatar setThePrefabricateColors];
			[_avatarList addObject:avatar];
		}
		
		NSArray *array = self.avatarStyle == FUAvatarStyleNormal ? [[NSFileManager defaultManager] contentsOfDirectoryAtPath:AvatarListPath error:nil] : [[NSFileManager defaultManager] contentsOfDirectoryAtPath:AvatarQPath error:nil];
		array = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
			return [obj2 compare:obj1 options:NSNumericSearch] ;
		}];
		for (NSString *jsonName in array) {
			if (![jsonName hasSuffix:@".json"]) {
				continue ;
			}
			NSString *jsonPath =  [CurrentAvatarStylePath stringByAppendingPathComponent:jsonName];
			NSData *jsonData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
			NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
			
			FUAvatar *avatar = [FUAvatar avatarWithInfoDic:dic];
			[_avatarList addObject:avatar];
		}
	}
}

#pragma mark ----- 以下处理接口

/**
 普通模式下切换 Avatar
 
 @param avatar Avatar
 */
- (void)reloadRenderAvatar:(FUAvatar *)avatar {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	// 销毁上一个 avatar
	if (self.currentAvatars.count != 0) {
		FUAvatar *lastAvatar = self.currentAvatars.firstObject ;
		[lastAvatar destroyAvatar];
		[self.currentAvatars removeObject:lastAvatar];
	}
	
	// 创建新的
	[avatar loadAvatar];
	mItems[2] = self.defalutQController ;
	// 保存到当前 render 列表里面
	[self.currentAvatars addObject:avatar];
	
	dispatch_semaphore_signal(signal);
}



/**
 普通模式下切换 Avatar,不销毁controller.bundle
 
 @param avatar Avatar
 */
- (void)reloadRenderAvatarInSameController:(FUAvatar *)avatar {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	// 销毁上一个 avatar
	if (self.currentAvatars.count != 0) {
		FUAvatar *lastAvatar = self.currentAvatars.firstObject ;
		[lastAvatar destroyAvatarResouce];
		[self.currentAvatars removeObject:lastAvatar];
	}
	if (avatar == nil) {
		dispatch_semaphore_signal(signal) ;
		return ;
	}
	if ([avatar.name isEqualToString:@"Star"]) {   // 如何是明星模式，采用如下加载方式
		// 创建新的
		[avatar loadStarAvatar];
	}else{
		// 创建新的
		[avatar loadAvatar];
	}
	mItems[2] = self.defalutQController ;
	// 保存到当前 render 列表里面
	[self.currentAvatars addObject:avatar];
	[avatar loadIdleModePose];
	dispatch_semaphore_signal(signal);
}

/**
 普通模式下 新增 Avatar render
 
 @param avatar 新增的 Avatar
 */
- (void)addRenderAvatar:(FUAvatar *)avatar {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	// 创建新的
	[avatar loadAvatar];
	// 保存到当前 render 列表里面
	[self.currentAvatars addObject:avatar];
	
	mItems[2] = self.defalutQController ;
	
	dispatch_semaphore_signal(signal);
}

/**
 普通模式下 删除 Avatar render
 
 @param avatar 需要删除的 avatar
 */
- (void)removeRenderAvatar:(FUAvatar *)avatar {
	if (avatar == nil || ![self.currentAvatars containsObject:avatar]) {
		NSLog(@"---- avatar is nil or avatar is not rendering ~");
		return ;
	}
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	[avatar setCurrentAvatarIndex:avatar.currentInstanceId];    // 设置当前avatar的nama序号，使所有的操作都基于当前avatar
	
	NSInteger index = [self.currentAvatars indexOfObject:avatar];
	
	[avatar destroyAvatarResouce];
	
	

	
	[self.currentAvatars removeObject:avatar];
	
	dispatch_semaphore_signal(signal);
}


/**
 绑定hair_mask.bundle
 */
- (void)bindHairMask {
	NSString *hair_mask_Path = [[NSBundle mainBundle] pathForResource:@"hair_mask.bundle" ofType:nil];
	hair_mask_ptr = [self bindItemWithToController:hair_mask_Path];
}

/**
 销毁hair_mask.bundle
 */
- (void)destoryHairMask {
	if (hair_mask_ptr > 0) {
	// 解绑
	[FURenderer unBindItems:_defalutQController items:&hair_mask_ptr itemsCount:1];
	// 销毁
	[FURenderer destroyItem:hair_mask_ptr];
	}
}


/**
 进入 AR滤镜 模式
 -- 会切换 controller 所在句柄
 */
- (void)enterARMode {
	
	if (self.currentAvatars.count != 0) {
		FUAvatar *avatar = self.currentAvatars.firstObject ;
		int handle = [avatar getControllerHandle];
		arItems[0] = handle ;
	}
}
/**
 设置手势动画
 -- 会切换 controller 所在句柄
 */
- (void)loadPoseTrackAnim {
	
	NSString * anim_fistPath = [[NSBundle mainBundle] pathForResource:@"anim_fist.bundle" ofType:nil];
	[self bindItemWithToController:anim_fistPath];
	NSString * anim_mergePath = [[NSBundle mainBundle] pathForResource:@"anim_merge.bundle" ofType:nil];
	[self bindItemWithToController:anim_mergePath];
	NSString * anim_palmPath = [[NSBundle mainBundle] pathForResource:@"anim_palm.bundle" ofType:nil];
	[self bindItemWithToController:anim_palmPath];
	NSString * anim_twoPath = [[NSBundle mainBundle] pathForResource:@"anim_two.bundle" ofType:nil];
	[self bindItemWithToController:anim_twoPath];
	NSString * anim_heartPath = [[NSBundle mainBundle] pathForResource:@"anim_heart.bundle" ofType:nil];
	[self bindItemWithToController:anim_heartPath];
	NSString * anim_onePath = [[NSBundle mainBundle] pathForResource:@"anim_one.bundle" ofType:nil];
	[self bindItemWithToController:anim_onePath];
	NSString * anim_sixPath = [[NSBundle mainBundle] pathForResource:@"anim_six.bundle" ofType:nil];
	[self bindItemWithToController:anim_sixPath];
	
	NSString * anim_eightPath = [[NSBundle mainBundle] pathForResource:@"anim_eight.bundle" ofType:nil];
	[self bindItemWithToController:anim_eightPath];
	NSString * anim_okPath = [[NSBundle mainBundle] pathForResource:@"anim_ok.bundle" ofType:nil];
	[self bindItemWithToController:anim_okPath];
	NSString * anim_thumbPath = [[NSBundle mainBundle] pathForResource:@"anim_thumb.bundle" ofType:nil];
	[self bindItemWithToController:anim_thumbPath];
	NSString * anim_holdPath = [[NSBundle mainBundle] pathForResource:@"anim_hold.bundle" ofType:nil];
	[self bindItemWithToController:anim_holdPath];
	NSString * anim_korheartPath = [[NSBundle mainBundle] pathForResource:@"anim_korheart.bundle" ofType:nil];
	[self bindItemWithToController:anim_korheartPath];
	NSString * anim_rockPath = [[NSBundle mainBundle] pathForResource:@"anim_rock.bundle" ofType:nil];
	[self bindItemWithToController:anim_rockPath];
	
	
	
}

/**
 全身追踪绑定脚下阴影
 */

- (void)bindPlaneShadow {
	NSString *plane_mg_Path = [[NSBundle mainBundle] pathForResource:@"plane_mg.bundle" ofType:nil];
	plane_mg_ptr = [self bindItemWithToController:plane_mg_Path];
}
/**
 解绑全身追踪绑定脚下阴影
 */
- (void)unBindPlaneShadow {
	if (plane_mg_ptr > 0) {
		
		// 解绑
		
		[FURenderer unBindItems:_defalutQController items:&plane_mg_ptr itemsCount:1];
		// 销毁
		[FURenderer destroyItem:plane_mg_ptr];
	}
	
	
}
/// 重新绑定道具
/// @param filePath 新的道具路径
/// @param ptr 道具句柄
- (void)reBindItemWithToController:(NSString *)filePath withPtr:(int *)ptr{
	if (*ptr > 0) {

	// 解绑
	[FURenderer unBindItems:_defalutQController items:ptr itemsCount:1];
	// 销毁
	[FURenderer destroyItem:*ptr];
	
	}
	*ptr = [self bindItemWithToController:filePath];
	
}
- (int)bindItemWithToController:(NSString *)filePath {
	// 创建道具
	int tmpHandle = [FURenderer itemWithContentsOfFile:filePath];
	[FURenderer bindItems:_defalutQController items:&tmpHandle itemsCount:1];
	return tmpHandle;
}

/**
 在 AR滤镜 模式下切换 Avatar
 
 @param avatar Avatar
 */
- (void)reloadRenderAvatarInARMode:(FUAvatar *)avatar {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	// 销毁上一个 avatar
	if (self.currentAvatars.count != 0) {
		FUAvatar *lastAvatar = self.currentAvatars.firstObject ;
		[lastAvatar destroyAvatar];
		[self.currentAvatars removeObject:lastAvatar];
		arItems[0] = 0 ;
	}
	
	if (avatar == nil) {
		dispatch_semaphore_signal(signal) ;
		return ;
	}
	
	arItems[0] = [avatar loadAvatarWithARMode];
	// 保存到当前 render 列表里面
	[self.currentAvatars addObject:avatar];
	
	dispatch_semaphore_signal(signal);
}
/**
 在 AR滤镜 模式下切换 Avatar   不销毁controller
 
 @param avatar Avatar
 */
- (void)reloadRenderAvatarInARModeInSameController:(FUAvatar *)avatar {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	// 销毁上一个 avatar
	if (self.currentAvatars.count != 0) {
		FUAvatar *lastAvatar = self.currentAvatars.firstObject ;
		[lastAvatar destroyAvatarResouce];
		[self.currentAvatars removeObject:lastAvatar];
		arItems[0] = 0 ;
	}
	
	if (avatar == nil) {
		dispatch_semaphore_signal(signal) ;
		return ;
	}
	
	arItems[0] = [avatar loadAvatarWithARMode];
	// 保存到当前 render 列表里面
	[self.currentAvatars addObject:avatar];
	
	dispatch_semaphore_signal(signal);
}

/**
 切换 AR滤镜
 
 @param filePath AR滤镜 路径
 */
- (void)reloadARFilterWithPath:(NSString *)filePath {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	if (arItems[1] != 0) {
		[FURenderer destroyItem:arItems[1]];
		arItems[1] = 0 ;
	}
	
	if (filePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		
		dispatch_semaphore_signal(signal);
		return ;
	}
	
	arItems[1] = [FURenderer itemWithContentsOfFile:filePath];
	
	dispatch_semaphore_signal(signal);
}
/**
 在正常渲染avatar的模式下，切换AR滤镜
 
 @param filePath  滤镜 路径
 */
- (void)reloadFilterWithPath:(NSString *)filePath {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	if (mItems[3] != 0) {
		[FURenderer destroyItem:mItems[3]];
		mItems[3] = 0 ;
	}
	
	if (filePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		
		dispatch_semaphore_signal(signal);
		return ;
	}
	
	mItems[3] = [FURenderer itemWithContentsOfFile:filePath];
	
	dispatch_semaphore_signal(signal);
}

/**
 检测人脸接口
 
 @param sampleBuffer  图像数据
 @return              图像数据
 */
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
	
	CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
	
	void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) ;
	int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
	int width  = (int)CVPixelBufferGetWidth(pixelBuffer) ;
	
	[FURenderer trackFace:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:width height:height];
	
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
	
	if (CGSizeEqualToSize(frameSize, CGSizeZero)) {
		frameSize = CGSizeMake(width, height) ;
	}
	
	CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
	CFRelease(metadataDict);
	NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
	lightingValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
	
	dispatch_semaphore_signal(signal);
	return pixelBuffer ;
}
/**
 检测人脸接口
 
 @param sampleBuffer  图像数据
 @return              图像数据
 */
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer CurrentlLightingValue:(float *)currntLightingValue {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
	
	CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
	
	void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) ;
	int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
	int width  = (int)CVPixelBufferGetWidth(pixelBuffer) ;
	
	[FURenderer trackFace:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:width height:height];
	
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
	
	if (CGSizeEqualToSize(frameSize, CGSizeZero)) {
		frameSize = CGSizeMake(width, height) ;
	}
	
	CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
	CFRelease(metadataDict);
	NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
	lightingValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
	*currntLightingValue = lightingValue;
	dispatch_semaphore_signal(signal);
	return pixelBuffer ;
}

static int frameId = 0 ;
/**
 Avatar 处理接口
 
 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @param landmarks IsFrontCamera 当前是否是前置输入
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks IsFrontCamera:(BOOL)isFrontCamera {
	if (isFrontCamera) {
		CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
		pixelBuffer = mirrored_pixel;
	}else{
		[[FURenderer shareRenderer] setInputCameraMatrix:0 flip_y:0 rotate_mode:0];
	}
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	float expression[56] = {0};
	float translation[3] = {0};
	float rotation[4] = {0};
	rotation[3] = 1;
	float rotation_mode[1] = {0};
	float pupil_pos[2] = {0};
	int is_valid = 0 ;
	
	if (renderMode == FURenderPreviewMode) {
		CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
		
		void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) ;
		int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
		int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
		
		[FURenderer trackFaceWithTongue:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:stride/4 height:height];
		
		[FURenderer getFaceInfo:0 name:@"expression" pret:expression number:56];
		[FURenderer getFaceInfo:0 name:@"translation" pret:translation number:3];
		[FURenderer getFaceInfo:0 name:@"rotation" pret:rotation number:4];
		[FURenderer getFaceInfo:0 name:@"rotation_mode" pret:rotation_mode number:1];
		[FURenderer getFaceInfo:0 name:@"pupil_pos" pret:pupil_pos number:2];
		[FURenderer getFaceInfo:0 name:@"landmarks" pret:landmarks number:150];
		
		CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
		
		is_valid = [FURenderer isTracking];
	}
	
	//	TAvatarInfo info;
	//	info.p_translation = translation;
	//	info.p_rotation = rotation;
	//	info.p_expression = expression;
	//	info.rotation_mode = rotation_mode;
	//	info.pupil_pos = pupil_pos;
	//	info.is_valid = is_valid ;
	
	TAvatarInfo info;
	info.p_translation = translation;
	info.p_rotation = rotation;
	info.p_expression = expression;
	info.rotation_mode = rotation_mode;
	info.pupil_pos = pupil_pos;
	info.is_valid = is_valid;
	
	int nama_render_option = NAMA_RENDER_FEATURE_FULL | FU_FORMAT_GL_CURRENT_FRAMEBUFFER;
	
	CVPixelBufferLockBaseAddress(renderTarget, 0);
	
	void *bytes = (void *)CVPixelBufferGetBaseAddress(renderTarget);
	int stride1 = (int)CVPixelBufferGetBytesPerRow(renderTarget);
	int h1 = (int)CVPixelBufferGetHeight(renderTarget);
	[[FURenderer shareRenderer] renderBundles:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:bytes outFormat:FU_FORMAT_BGRA_BUFFER width:stride1/4 height:h1 frameId:frameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
	CVPixelBufferUnlockBaseAddress(renderTarget, 0);
	
	
	dispatch_semaphore_signal(signal);
	
	return renderTarget ;
}

/**
 Avatar 处理接口
 
 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	int h = (int)CVPixelBufferGetHeight(renderTarget);
	int w = (int)CVPixelBufferGetWidth(renderTarget);
	CVPixelBufferRef mirrored_pixel = NULL;
	NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
											  @(kCVPixelFormatType_32BGRA),
										  (NSString*) kCVPixelBufferWidthKey : @(w),
										  (NSString*) kCVPixelBufferHeightKey : @(h),
										  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
										  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
	CVPixelBufferCreate(kCFAllocatorDefault,
						w, h,
						kCVPixelFormatType_32BGRA,
						(__bridge CFDictionaryRef)pixelBufferOptions,
						&mirrored_pixel);
	
	CVPixelBufferLockBaseAddress(mirrored_pixel, 0);
	void* pod1 = (void *)CVPixelBufferGetBaseAddress(mirrored_pixel);
	
	float expression[56] = {0};
	float translation[3] = {0};
	float rotation[4] = {0};
	rotation[3] = 1;
	float rotation_mode[1] = {0};
	float pupil_pos[2] = {0};
	int is_valid = 0 ;
	
	if (renderMode == FURenderPreviewMode) {
		CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
		
		void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) ;
		int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
		int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
		
		[FURenderer trackFaceWithTongue:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:stride/4 height:height];
		
		[FURenderer getFaceInfo:0 name:@"expression_aligned" pret:expression number:56];
		[FURenderer getFaceInfo:0 name:@"translation" pret:translation number:3];
		[FURenderer getFaceInfo:0 name:@"rotation_aligned" pret:rotation number:4];
		[FURenderer getFaceInfo:0 name:@"rotation_mode" pret:rotation_mode number:1];
		[FURenderer getFaceInfo:0 name:@"pupil_pos" pret:pupil_pos number:2];
		[FURenderer getFaceInfo:0 name:@"landmarks" pret:landmarks number:150];
		
		CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
		
		is_valid = [FURenderer isTracking];
	}
	
	TAvatarInfo info;
	info.p_translation = translation;
	info.p_rotation = rotation;
	info.p_expression = expression;
	info.rotation_mode = rotation_mode;
	info.pupil_pos = pupil_pos;
	info.is_valid = is_valid;
	
	
	CVPixelBufferLockBaseAddress(renderTarget, 0);
	
	int stride1 = (int)CVPixelBufferGetBytesPerRow(renderTarget);
	int h1 = (int)CVPixelBufferGetHeight(renderTarget);
	[[FURenderer shareRenderer] renderBundles:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:pod1 outFormat:FU_FORMAT_BGRA_BUFFER width:stride1/4 height:h1 frameId:frameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
    void* pod0 = (void *)CVPixelBufferGetBaseAddress(renderTarget);
    
     for (int i = 0; i < h1; i++){
     	memcpy((uint8_t*)pod0 + stride1 * (h1-i-1),(uint8_t*)pod1 + stride1 * i, stride1);
	 }
	
	CVPixelBufferUnlockBaseAddress(renderTarget, 0);
	
	CVPixelBufferUnlockBaseAddress(mirrored_pixel, 0);
	CVPixelBufferRelease(mirrored_pixel);
	
	dispatch_semaphore_signal(signal);
	
	return renderTarget ;
}

/**
 Avatar 语音驱动模式下的处理接口
 
 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemInFUStaWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	
	
	int h = (int)CVPixelBufferGetHeight(renderTarget);
	int w = (int)CVPixelBufferGetWidth(renderTarget);
	CVPixelBufferRef mirrored_pixel = NULL;
	NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
											  @(kCVPixelFormatType_32BGRA),
										  (NSString*) kCVPixelBufferWidthKey : @(w),
										  (NSString*) kCVPixelBufferHeightKey : @(h),
										  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
										  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
	CVPixelBufferCreate(kCFAllocatorDefault,
						w, h,
						kCVPixelFormatType_32BGRA,
						(__bridge CFDictionaryRef)pixelBufferOptions,
						&mirrored_pixel);
	
	CVPixelBufferLockBaseAddress(mirrored_pixel, 0);
	int mirrored_h = (int)CVPixelBufferGetHeight(mirrored_pixel);
	int mirrored_w = (int)CVPixelBufferGetWidth(mirrored_pixel);
	void* pod1 = (void *)CVPixelBufferGetBaseAddress(mirrored_pixel);
	
	
	
	
	
	
	float expression[56] = {0};
	float translation[3] = {0};
	float rotation[4] = {0};
	rotation[3] = 1;
	float rotation_mode[1] = {0};
	float pupil_pos[2] = {0};
	int is_valid = 0 ;
	
	if (renderMode == FURenderPreviewMode) {
		CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
		
		void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) ;
		int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
		int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
		
		[FURenderer trackFaceWithTongue:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:stride/4 height:height];
		
		[FURenderer getFaceInfo:0 name:@"expression" pret:expression number:56];
		[FURenderer getFaceInfo:0 name:@"translation" pret:translation number:3];
		[FURenderer getFaceInfo:0 name:@"rotation" pret:rotation number:4];
		[FURenderer getFaceInfo:0 name:@"rotation_mode" pret:rotation_mode number:1];
		[FURenderer getFaceInfo:0 name:@"pupil_pos" pret:pupil_pos number:2];
		[FURenderer getFaceInfo:0 name:@"landmarks" pret:landmarks number:150];
		
		CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
		
		is_valid = [FURenderer isTracking];
	}
	
	
	TAvatarInfo info;
	info.p_translation = translation;
	info.p_rotation = rotation;
	info.p_expression = expression;
	info.rotation_mode = rotation_mode;
	info.pupil_pos = pupil_pos;
	info.is_valid = is_valid;
	
	int nama_render_option = NAMA_RENDER_FEATURE_FULL | FU_FORMAT_GL_CURRENT_FRAMEBUFFER;
	
	CVPixelBufferLockBaseAddress(renderTarget, 0);
	void *bytes = (void *)CVPixelBufferGetBaseAddress(renderTarget);
	int stride1 = (int)CVPixelBufferGetBytesPerRow(renderTarget);
	int w1 = (int)CVPixelBufferGetWidth(renderTarget);
	int h1 = (int)CVPixelBufferGetHeight(renderTarget);
	[[FURenderer shareRenderer] renderBundles:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:pod1 outFormat:FU_FORMAT_BGRA_BUFFER width:stride1/4 height:h1 frameId:frameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
	
	
	void* pod0 = (void *)CVPixelBufferGetBaseAddress(renderTarget);
	
	for (int i = 0; i < h1; i++)
	{
		memcpy((uint8_t*)pod0 + stride1 * (h1-i-1),(uint8_t*)pod1 + stride1 * i, stride1);
	}
	CVPixelBufferUnlockBaseAddress(renderTarget, 0);
	
	CVPixelBufferUnlockBaseAddress(mirrored_pixel, 0);
	CVPixelBufferRelease(mirrored_pixel);
	
	dispatch_semaphore_signal(signal);
	
	return renderTarget ;
}


static int screenshotFrameId = 0 ;
/**
 Avatar 截图
 
 @param pixelBuffer 图像数据
 @return            处理之后的图像
 */
- (CVPixelBufferRef)screenshotP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer{
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	float expression[56] = {0};
	float translation[3] = {0};
	float rotation[4] = {0};
	rotation[3] = 1;
	float rotation_mode[1] = {0};
	float pupil_pos[2] = {0};
	int is_valid = 0 ;
	
	
	
	TAvatarInfo info;
	info.p_translation = translation;
	info.p_rotation = rotation;
	info.p_expression = expression;
	info.rotation_mode = rotation_mode;
	info.pupil_pos = pupil_pos;
	info.is_valid = is_valid ;
	
	CVPixelBufferLockBaseAddress(screenShotTarget, 0);
	
	void *bytes = (void *)CVPixelBufferGetBaseAddress(screenShotTarget);
	int stride1 = (int)CVPixelBufferGetBytesPerRow(screenShotTarget);
	int h1 = (int)CVPixelBufferGetHeight(screenShotTarget);
	
	[[FURenderer shareRenderer] renderBundles:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:bytes outFormat:FU_FORMAT_BGRA_BUFFER width:stride1/4.0 height:h1 frameId:screenshotFrameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
	CVPixelBufferUnlockBaseAddress(screenShotTarget, 0);
	dispatch_semaphore_signal(signal);
	return screenShotTarget ;
}
// 处理前置摄像头的图像
-(CVPixelBufferRef)dealTheFrontCameraPixelBuffer:(CVPixelBufferRef) pixelBuffer{
	int h = (int)CVPixelBufferGetHeight(pixelBuffer);
	int w = (int)CVPixelBufferGetWidth(pixelBuffer);
	CVPixelBufferRef mirrored_pixel = NULL;
	NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
											  @(kCVPixelFormatType_32BGRA),
										  (NSString*) kCVPixelBufferWidthKey : @(w),
										  (NSString*) kCVPixelBufferHeightKey : @(h),
										  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
										  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
	CVPixelBufferCreate(kCFAllocatorDefault,
						w, h,
						kCVPixelFormatType_32BGRA,
						(__bridge CFDictionaryRef)pixelBufferOptions,
						&mirrored_pixel);
	
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	void* pod0 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	CVPixelBufferLockBaseAddress(mirrored_pixel, 0);
	void* pod1 = (void *)CVPixelBufferGetBaseAddress(mirrored_pixel);
	CVPixelBufferUnlockBaseAddress(mirrored_pixel, 0);
	
	fuRotateImage(
				  pod0, 0, w, h, 0, 1, 0, pod1,NULL);
	[[FURenderer shareRenderer] setInputCameraMatrix:0 flip_y:0 rotate_mode:0];
	return mirrored_pixel;
}
static int ARFilterID = 0 ;
/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer{
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	int h = (int)CVPixelBufferGetHeight(pixelBuffer);
	int w = (int)CVPixelBufferGetWidth(pixelBuffer);
	CVPixelBufferRef mirrored_pixel = NULL;
	NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
											  @(kCVPixelFormatType_32BGRA),
										  (NSString*) kCVPixelBufferWidthKey : @(w),
										  (NSString*) kCVPixelBufferHeightKey : @(h),
										  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
										  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
	CVPixelBufferCreate(kCFAllocatorDefault,
						w, h,
						kCVPixelFormatType_32BGRA,
						(__bridge CFDictionaryRef)pixelBufferOptions,
						&mirrored_pixel);
	
	CVPixelBufferLockBaseAddress(mirrored_pixel, 0);
	void* pod1 = (void *)CVPixelBufferGetBaseAddress(mirrored_pixel);
	
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	void* pod0 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
	int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
	int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
	void *bytes = CVPixelBufferGetBaseAddress(pixelBuffer) ;
	void *newbytes = NULL;
	// int fu3DBodyTrackerRun(void* model_ptr, int human_handle, void* img, int w, int h, int fu_image_format, int rotation_mode);
	int width = (int)CVPixelBufferGetWidth(pixelBuffer) ;
	
	[[FURenderer shareRenderer] renderBundles:bytes inFormat:FU_FORMAT_BGRA_BUFFER outPtr:pod1 outFormat:FU_FORMAT_BGRA_BUFFER width:stride/4 height:height frameId:ARFilterID ++ items:arItems itemCount:2];
	//	fuRenderBundles(FU_FORMAT_BGRA_BUFFER,bytes,FU_FORMAT_BGRA_BUFFER,bytes,width,height,ARFilterID++,arItems,2);
	
	
	
	// flip y because nama direct get data from opengl
	
	
	for (int i = 0; i < height; i++)
	{
		memcpy((uint8_t*)pod0 + stride * (height-i-1),(uint8_t*)pod1 + stride * i, stride);
	}
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	CVPixelBufferUnlockBaseAddress(mirrored_pixel, 0);
	CVPixelBufferRelease(mirrored_pixel);
	
	
	dispatch_semaphore_signal(signal);
	
	return pixelBuffer;
}

/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr {
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	int h = (int)CVPixelBufferGetHeight(pixelBuffer);
	int w = (int)CVPixelBufferGetWidth(pixelBuffer);
	CVPixelBufferRef mirrored_pixel = NULL;
	NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
											  @(kCVPixelFormatType_32BGRA),
										  (NSString*) kCVPixelBufferWidthKey : @(w),
										  (NSString*) kCVPixelBufferHeightKey : @(h),
										  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
										  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
	CVPixelBufferCreate(kCFAllocatorDefault,
						w, h,
						kCVPixelFormatType_32BGRA,
						(__bridge CFDictionaryRef)pixelBufferOptions,
						&mirrored_pixel);
	
	CVPixelBufferLockBaseAddress(mirrored_pixel, 0);
	void* pod1 = (void *)CVPixelBufferGetBaseAddress(mirrored_pixel);
	
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	void* pod0 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
	int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
	int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
	void *bytes = CVPixelBufferGetBaseAddress(pixelBuffer) ;
	void *newbytes = NULL;
	// int fu3DBodyTrackerRun(void* model_ptr, int human_handle, void* img, int w, int h, int fu_image_format, int rotation_mode);
	int width = (int)CVPixelBufferGetWidth(pixelBuffer) ;
    [FURenderer run3DBodyTracker:human3dPtr humanHandle:0 inPtr:bytes inFormat:FU_FORMAT_BGRA_BUFFER w:stride/4 h:height rotationMode:0];
	[[FURenderer shareRenderer] renderBundles:bytes inFormat:FU_FORMAT_BGRA_BUFFER outPtr:pod1 outFormat:FU_FORMAT_BGRA_BUFFER width:stride/4 height:height frameId:ARFilterID ++ items:arItems itemCount:2];
	//	fuRenderBundles(FU_FORMAT_BGRA_BUFFER,bytes,FU_FORMAT_BGRA_BUFFER,bytes,width,height,ARFilterID++,arItems,2);
	
	
	
	// flip y because nama direct get data from opengl
	
	
	fuRotateImage(pod1, 0, w, h, 0, 0, 1, pod0,NULL);
	
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	CVPixelBufferUnlockBaseAddress(mirrored_pixel, 0);
	CVPixelBufferRelease(mirrored_pixel);
	
	
	dispatch_semaphore_signal(signal);
	
	return pixelBuffer;
}

/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @param human3dPtr  human3d.bundle 的句柄
 @param renderMode  FURenderCommonMode 为预览模式，FURenderPreviewMode为人脸追踪模式
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr RenderMode:(FURenderMode)renderMode{
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	float expression[56] = {0};
	float translation[3] = {0};
	float rotation[4] = {0};
	rotation[3] = 1;
	float rotation_mode[1] = {0};
	float pupil_pos[2] = {0};
	int is_valid = 0 ;
	
	if (renderMode == FURenderPreviewMode) {
		CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
		void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) ;
		int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
		int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
		
		[FURenderer trackFaceWithTongue:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:stride/4 height:height];
		
		[FURenderer getFaceInfo:0 name:@"expression_aligned" pret:expression number:56];
		[FURenderer getFaceInfo:0 name:@"translation" pret:translation number:3];
		[FURenderer getFaceInfo:0 name:@"rotation_aligned" pret:rotation number:4];
		[FURenderer getFaceInfo:0 name:@"rotation_mode" pret:rotation_mode number:1];
		[FURenderer getFaceInfo:0 name:@"pupil_pos" pret:pupil_pos number:2];
		CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
		is_valid = [FURenderer isTracking];
	}
    
	TAvatarInfo info;
	info.p_translation = translation;
	info.p_rotation = rotation;
	info.p_expression = expression;
	info.rotation_mode = rotation_mode;
	info.pupil_pos = pupil_pos;
	info.is_valid = is_valid;
	
//	[FURenderer run3DBodyTracker:human3dPtr humanHandle:0 pixelBuffer:pixelBuffer fuImageFormat:FU_FORMAT_BGRA_BUFFER rotationMode:0];
	int h = (int)CVPixelBufferGetHeight(pixelBuffer);
	int w = (int)CVPixelBufferGetWidth(pixelBuffer);
	CVPixelBufferRef mirrored_pixel = NULL;
	NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
											  @(kCVPixelFormatType_32BGRA),
										  (NSString*) kCVPixelBufferWidthKey : @(w),
										  (NSString*) kCVPixelBufferHeightKey : @(h),
										  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
										  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
	CVPixelBufferCreate(kCFAllocatorDefault,
						w, h,
						kCVPixelFormatType_32BGRA,
						(__bridge CFDictionaryRef)pixelBufferOptions,
						&mirrored_pixel);
	
	CVPixelBufferLockBaseAddress(mirrored_pixel, 0);
	void* pod1 = (void *)CVPixelBufferGetBaseAddress(mirrored_pixel);

	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	void* pod0 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
	int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
	int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
	void *bytes = CVPixelBufferGetBaseAddress(pixelBuffer) ;
//    void *newbytes = NULL;
	// int fu3DBodyTrackerRun(void* model_ptr, int human_handle, void* img, int w, int h, int fu_image_format, int rotation_mode);
	int width = (int)CVPixelBufferGetWidth(pixelBuffer) ;
	
	//[[FURenderer shareRenderer] renderBundlesSplitView:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:pod1 outFormat:FU_FORMAT_BGRA_BUFFER width:width	 height:height frameId:frameId++ items:mItems itemCount:sizeof(mItems)/sizeof(int) flipx:NO imagePtr:bytes view0Ratio:0.5 marginInPixel:0 isVertical:1 isImageFirst:1 rotateAngleBeforeCrop:0 cropRatioTop:0.5];
	//	fuRenderBundles(FU_FORMAT_BGRA_BUFFER,bytes,FU_FORMAT_BGRA_BUFFER,bytes,width,height,ARFilterID++,arItems,2);
	TSplitViewInfo split_view_info;
	split_view_info.in_ptr=bytes;
	split_view_info.in_type=FU_FORMAT_BGRA_BUFFER;
	split_view_info.out_w=width;
	split_view_info.out_h=height;
	split_view_info.view_0_ratio=0.0f;
	split_view_info.margin_in_pixel=0;
	split_view_info.is_vertical= 1;
	split_view_info.is_image_first=1;
	split_view_info.rotation_mode_before_crop=FU_ROTATION_MODE_0;
	split_view_info.crop_ratio_top=0.5f;
    [FURenderer run3DBodyTracker:human3dPtr humanHandle:0 inPtr:bytes inFormat:FU_FORMAT_BGRA_BUFFER w:stride/4 h:height rotationMode:0];
	[[FURenderer shareRenderer] renderBundlesSplitView:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:pod1 outFormat:FU_FORMAT_BGRA_BUFFER width:width height:height frameId:frameId++ items:mItems itemCount:sizeof(mItems)/sizeof(int) splitViewInfoPtr:&split_view_info];
	
	// flip y because nama direct get data from opengl
	
	for (int i = 0; i < height; i++)
	{
	   memcpy((uint8_t*)pod0 + stride * (height-i-1),(uint8_t*)pod1 + stride * i, stride);
	}
//	fuRotateImage(pod1, 0, w, h, 0, 0, 1, pod0,NULL);
	
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	CVPixelBufferUnlockBaseAddress(mirrored_pixel, 0);
	CVPixelBufferRelease(mirrored_pixel);
	
	
	dispatch_semaphore_signal(signal);
	
	return pixelBuffer;
}
/**
 Avatar 生成
 
 @param data    服务端拉流数据
 @param name    Avatar 名字
 @param gender  Avatar 性别
 @return        生成的 Avatar
 */
- (FUAvatar *)createAvatarWithData:(NSData *)data avatarName:(NSString *)name gender:(FUGender)gender {
	
	isCreatingAvatar = YES ;
	
	
	
	FUAvatar *avatar = [[FUAvatar alloc] init];
	avatar.defaultModel = NO ;
	avatar.name = name;
	avatar.gender = gender ;
	BOOL isQ = self.avatarStyle == FUAvatarStyleQ ;
	avatar.isQType = isQ ;

	
	[data writeToFile:[[avatar filePath] stringByAppendingPathComponent:FU_HEAD_BUNDLE] atomically:YES];
	[[fuPTAClient shareInstance] setHeadData:data];
	// 头发
	int hairLabel = [[fuPTAClient shareInstance] getInt:@"hair_label"];
	avatar.hairLabel = hairLabel ;
	NSString *defaultHair = [self gethairNameWithNum:hairLabel andGender:gender];
	avatar.hair = defaultHair ;
	
	NSString *baseHairPath = [[NSBundle mainBundle] pathForResource:avatar.hair ofType:nil] ;
	NSData *baseHairData = [NSData dataWithContentsOfFile: baseHairPath];
	NSData *defaultHairData = [[fuPTAClient shareInstance] createHairWithHeadData:data defaultHairData:baseHairData];
	NSString *defaultHairPath = [[avatar filePath] stringByAppendingPathComponent:defaultHair];
	[defaultHairData writeToFile:defaultHairPath atomically:YES];
	[[fuPTAClient shareInstance] setHeadData:data];
	// 眼镜
	int hasGlass = [[fuPTAClient shareInstance] getInt:@"has_glasses"];
	//    avatar.glasses = hasGlass == 0 ? @"glasses-noitem" : (gender == FUGenderMale ? @"male_glass_1" : @"female_glass_1");
	if (hasGlass == 0) {
		avatar.glasses = @"glasses-noitem.bundle" ;
	}else {
		int shapeGlasses = [[fuPTAClient shareInstance] getInt:@"shape_glasses"];
		int rimGlasses = [[fuPTAClient shareInstance] getInt:@"rim_glasses"];
		if (avatar.isQType) {
			NSLog(@"---------Q-Style--- shape_glasses: %d - rim_glasses:%d", shapeGlasses, rimGlasses);
			NSString *glassName = [self getQGlassesNameWithShape:shapeGlasses rim:rimGlasses male:gender == FUGenderMale];
			avatar.glasses = glassName ;
		}else {
			
			NSLog(@"--------- shape_glasses: %d - rim_glasses:%d", shapeGlasses, rimGlasses);
			NSString *glassName = [self getGlassesNameWithShape:shapeGlasses rim:rimGlasses male:gender == FUGenderMale];
			avatar.glasses = glassName ;
		}
	}
	
	avatar.hat = @"hat-noitem" ;
	
	// avatar info
	NSMutableDictionary *avatarInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	
	// 衣服
	if (avatar.gender == FUGenderMale) {
		avatar.upper = @"shangyi_chushi.bundle";
		avatar.wearFemaleClothes = NO;
	}else{
		avatar.upper = @"shangyi_chenshan_6.bundle";
		avatar.wearFemaleClothes = YES;
	}
	avatar.lower = @"kuzi_chushi.bundle";
	avatar.shoes = @"xiezi_fanbu.bundle";
	avatar.clothType = FUAvataClothTypeUpperAndLower;
	
	// 胡子
	int beardLabel = [[fuPTAClient shareInstance] getInt:@"beard_label"];
	avatar.bearLabel = beardLabel ;
	avatar.beard = [self getBeardNameWithNum:beardLabel Qtype:avatar.isQType male:avatar.gender == FUGenderMale];
	
	[avatarInfo setObject:@(beardLabel) forKey:@"beard_label"];
	[avatarInfo setObject:avatar.beard forKey:@"beard"];
	
	[avatarInfo setObject:@(0) forKey:@"default"];
	[avatarInfo setObject:@(avatar.isQType) forKey:@"q_type"];
	[avatarInfo setObject:name forKey:@"name"];
	[avatarInfo setObject:@(gender) forKey:@"gender"];
	[avatarInfo setObject:@(hairLabel) forKey:@"hair_label"];
	[avatarInfo setObject:defaultHair forKey:@"hair"];
	[avatarInfo setObject:@(avatar.clothType) forKey:@"clothType"];
	[avatarInfo setObject:avatar.upper forKey:@"upper"];
	[avatarInfo setObject:avatar.lower forKey:@"lower"];
	[avatarInfo setObject:avatar.shoes forKey:@"shoes"];
	[avatarInfo setObject:avatar.glasses forKey:@"glasses"];
	[avatarInfo setObject:avatar.hat forKey:@"hat"];
	
	
	
	
	NSString *avatarInfoPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
	NSData *avatarInfoData = [NSJSONSerialization dataWithJSONObject:avatarInfo options:NSJSONWritingPrettyPrinted error:nil];
	[avatarInfoData writeToFile:avatarInfoPath atomically:YES];
	appManager.localizeHairBundlesSuccess = false;
	
	[[fuPTAClient shareInstance] releaseHeadData];
	return avatar ;
}
-(void)createHairBundles:(FUAvatar *)avatar WithData:(NSData *)data{
	if (data == nil) {
		return;
	}
	NSString *defaultHair = avatar.hair;
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSArray *hairs ;
		hairs = self.qHairs ;
		for (NSString *hairName in hairs) {
			if ([hairName isEqualToString:@"hair-noitem"] || [hairName isEqualToString:@"hair_q_noitem"] || [hairName isEqualToString:defaultHair]) {
				continue ;
			}
			NSString *hairPath = [[NSBundle mainBundle] pathForResource:hairName ofType:@"bundle"];
			NSData *d0 = [NSData dataWithContentsOfFile:hairPath];
			
			//            CFAbsoluteTime startProcessHair1 = CFAbsoluteTimeGetCurrent() ;
			NSData *d1 = [[fuPTAClient shareInstance] createHairWithHeadData:data defaultHairData:d0];
			//            NSLog(@"------------ process hair time: %f ms - hair name: %@", (CFAbsoluteTimeGetCurrent() - startProcessHair1) * 1000.0, hairName);
			if (d1 == nil) {
				NSLog(@"---- error path: %@", hairPath);
			}
			NSString *hp = [[[avatar filePath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
			[d1 writeToFile:hp atomically:YES];
		}
		dispatch_sync(dispatch_get_main_queue(), ^{
			appManager.localizeHairBundlesSuccess = true;
		});
		[[NSNotificationCenter defaultCenter] postNotificationName:HairsWriteToLocalSuccessNot object:nil];
		self->isCreatingAvatar = NO ;
	});
}
/// 根据单个发型名称去deform头发
/// @param avatar 需要deform的avatar
/// @param hairName 需要deform的发型名称
-(void)createHairBundles:(FUAvatar *)avatar WithHairName:(NSString *)hairName{
	NSString *headPath = [avatar.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
	NSData * data = [NSData dataWithContentsOfFile:headPath];
	if (data == nil) {
		return;
	}
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSArray *hairs ;
		hairs = self.qHairs ;
		if ([hairName isEqualToString:@"hair-noitem"] || [hairName isEqualToString:@"hair_q_noitem"] ) {
			return ;
		}
		NSString *hairPath = [[NSBundle mainBundle] pathForResource:hairName ofType:@"bundle"];
		NSData *d0 = [NSData dataWithContentsOfFile:hairPath];
		
		//            CFAbsoluteTime startProcessHair1 = CFAbsoluteTimeGetCurrent() ;
		NSData *d1 = [[fuPTAClient shareInstance] createHairWithHeadData:data defaultHairData:d0];
		//            NSLog(@"------------ process hair time: %f ms - hair name: %@", (CFAbsoluteTimeGetCurrent() - startProcessHair1) * 1000.0, hairName);
		if (d1 == nil) {
			NSLog(@"---- error path: %@", hairPath);
		}
		NSString *hp = [[[avatar filePath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
		[d1 writeToFile:hp atomically:YES];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:HairsWriteToLocalSuccessNot object:nil];
	});
}
// 如果用户在生成头发时强退，下次重新进入将会重新生成头发bundles
-(void)reCreateHairBundles:(FUAvatar *)avatar{
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		//		NSString * serverPath = [[avatar filePath] stringByAppendingPathComponent:FU_SERVER_BUNDLE];
		NSString * serverPath = [[avatar filePath] stringByAppendingPathComponent:FU_HEAD_BUNDLE];
		NSData * serverBundleData = [NSData dataWithContentsOfFile: serverPath];
		[self createHairBundles:avatar WithData:serverBundleData];
	});
}


/**
 是否正在生成 Avatar 模型
 
 @return 是否正在生成
 */
- (BOOL)isCreatingAvatar {
	return isCreatingAvatar ;
}

/**
 捏脸之后生成新的 Avatar
 
 @param coeffi  捏脸参数
 @param deform  是否 deform
 @return        新的 Avatar
 */
- (FUAvatar *)createPupAvatarWithCoeffi:(float *)coeffi DeformHead:(BOOL)deform {
	
	FUAvatar *currentAvatar = self.currentAvatars.firstObject ;
	
	NSData *headData = [NSData dataWithContentsOfFile:[[currentAvatar filePath] stringByAppendingPathComponent:FU_HEAD_BUNDLE]];
	
	if (deform) {
		headData = [[fuPTAClient shareInstance] deformHeadWithHeadData:headData deformParams:coeffi paramsSize:90 withExprOnly:NO withLowp:NO].bundle;
	}
	
	NSString *avatarName = currentAvatar.defaultModel ? [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] : currentAvatar.name ;
	
	// 文件夹
	NSFileManager *fileManager = [NSFileManager defaultManager] ;
	NSString *filePath = [documentPath stringByAppendingPathComponent:avatarName];
	
	if (![fileManager fileExistsAtPath:filePath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	NSLog(@"avatar----1-----%@",currentAvatar);
	// Avatar
	
	FUAvatar *avatar = [currentAvatar copy];
	avatar.name = avatarName;
	NSLog(@"avatar----2-----%@",avatar);
	
	
	
	// 图片 icon
	UIImage *image = [UIImage imageWithContentsOfFile:currentAvatar.imagePath];
	NSData *imageData = UIImageJPEGRepresentation(image, 1.0) ;
	[imageData writeToFile:avatar.imagePath atomically:YES];
	
	// 头
	[headData writeToFile:[[avatar filePath] stringByAppendingPathComponent:FU_HEAD_BUNDLE] atomically:YES];
	// 头发
	NSArray *hairs = avatar.isQType ? self.qHairs : (currentAvatar.gender == FUGenderMale ? self.maleHairs : self.femaleHairs) ;
	
	if (currentAvatar.defaultModel) { // 预置模型
		// copy json
		NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Avatars.json" ofType:nil] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
		NSArray *avatarsArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
		NSData *avatarInfoData ;
		for (NSDictionary *avatarInfo in avatarsArray) {
			if ([avatarInfo[@"name"] isEqualToString:currentAvatar.name]) {
				NSMutableDictionary * colorDic = [avatar getInfoDictionary];
				//				[colorDic setValue:avatar.name forKey:@"name"];
				//				[colorDic setValue:@(0) forKey:@"default"];
				avatarInfoData = [NSJSONSerialization dataWithJSONObject:colorDic options:NSJSONWritingPrettyPrinted error:nil];
				break ;
			}
		}
		
		NSString *jsonPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
		[avatarInfoData writeToFile:jsonPath atomically:YES];
		
		// copy resource
		NSString *hairPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:currentAvatar.name];
		NSMutableArray *hairArr = [NSMutableArray arrayWithCapacity:1];
		
		for (NSString *hair in hairs) {
			if ([hair isEqualToString:@"hair-noitem"]) {
				continue ;
			}
			NSString *hairSource =  [[hairPath stringByAppendingPathComponent:hair] stringByAppendingString:@".bundle"];
			if ([fileManager fileExistsAtPath:hairSource]) {
				[fileManager copyItemAtPath:hairSource toPath:[[filePath stringByAppendingPathComponent:hair] stringByAppendingString:@".bundle"] error:nil];
				[hairArr addObject:hair];
			}
		}
	}
	return avatar ;
}



static float DetectionAngle = 20.0 ;
static float CenterScale = 0.3 ;
/**
 拍摄检测
 
 @return 检测结果
 */
- (NSString *)photoDetectionAction {
	
	// 1、保证单人脸输入
	int faceNum = [FURenderer isTracking];
	if (faceNum != 1) {
		return @" 请保持1个人输入  " ;
	}
	
	// 2、保证正脸
	float rotation[4] ;
	[FURenderer getFaceInfo:0 name:@"rotation" pret:rotation number:4];
	
	float xAngle = atanf(2 * (rotation[3] * rotation[0] + rotation[1] * rotation[2]) / (1 - 2 * (rotation[0] * rotation[0] + rotation[1] * rotation[1]))) * 180 / M_PI;
	float yAngle = asinf(2 * (rotation[1] * rotation[3] - rotation[0] * rotation[2])) * 180 / M_PI;
	float zAngle = atanf(2 * (rotation[3] * rotation[2] + rotation[0] * rotation[1]) / (1 - 2 * (rotation[1] * rotation[1] + rotation[2] * rotation[2]))) * 180 / M_PI;
	
	if (xAngle < -DetectionAngle || xAngle > DetectionAngle
		|| yAngle < -DetectionAngle || yAngle > DetectionAngle
		|| zAngle < -DetectionAngle || zAngle > DetectionAngle) {
		
		return @" 识别失败，需要人物正脸完整出镜哦~  " ;
	}
	
	// 3、保证人脸在中心区域
	CGPoint faceCenter = [self getFaceCenterInFrameSize:frameSize];
	
	if (faceCenter.x < 0.5 - CenterScale / 2.0 || faceCenter.x > 0.5 + CenterScale / 2.0
		|| faceCenter.y < 0.4 - CenterScale / 2.0 || faceCenter.y > 0.4 + CenterScale / 2.0) {
		
		return @" 请将人脸对准虚线框  " ;
	}
	
	// 4、夸张表情
	float expression[46] ;
	[FURenderer getFaceInfo:0 name:@"expression" pret:expression number:46];
	
	for (int i = 0 ; i < 46; i ++) {
		
		if (expression[i] > 1) {
			
			return @" 请保持面部无夸张表情  " ;
		}
	}
	
	// 5、光照均匀
	// 6、光照充足
	if (lightingValue < -1.0) {
		return @" 光线不充足  " ;
	}
	
	return @" 完美  " ;
}

/**
 设置最多识别人脸的个数
 
 @param num 最多识别人脸个数
 */
- (void)setMaxFaceNum:(int)num {
	[FURenderer setMaxFaces:num];
}

/**
 获取人脸矩形框
 
 @return 人脸矩形框
 */
- (CGRect)getFaceRect {
	
	float faceRect[4];
	int ret = [FURenderer getFaceInfo:0 name:@"face_rect" pret:faceRect number:4];
	if (!ret) {
		return CGRectZero ;
	}
	// 计算出中心点的坐标值
	CGFloat centerX = (faceRect[0] + faceRect[2]) * 0.5;
	CGFloat centerY = (faceRect[1] + faceRect[3]) * 0.5;
	
	// 将坐标系转换成以左上角为原点的坐标系
	centerX = frameSize.width - centerX;
	centerY = frameSize.height - centerY;
	
	CGRect rect = CGRectZero ;
	if (frameSize.width < frameSize.height) {
		CGFloat w = frameSize.width ;
		rect.size = CGSizeMake(w, w) ;
		rect.origin = CGPointMake(0, centerY - w/2.0) ;
	}else {
		CGFloat w = frameSize.height ;
		rect.size = CGSizeMake(w, w) ;
		rect.origin = CGPointMake(centerX - w / 2.0, 0) ;
	}
	
	CGPoint origin = rect.origin ;
	if (origin.x < 0) {
		origin.x = 0 ;
	}
	if (origin.y < 0) {
		origin.y = 0 ;
	}
	rect.origin = origin ;
	
	return rect ;
}

/**获取图像中人脸中心点*/
- (CGPoint)getFaceCenterInFrameSize:(CGSize)frameSize{
	
	static CGPoint preCenter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		preCenter = CGPointMake(0.49, 0.5);
	});
	
	// 获取人脸矩形框，坐标系原点为图像右下角，float数组为矩形框右下角及左上角两个点的x,y坐标（前两位为右下角的x,y信息，后两位为左上角的x,y信息）
	float faceRect[4];
	int ret = [FURenderer getFaceInfo:0 name:@"face_rect" pret:faceRect number:4];
	
	if (ret == 0) {
		return preCenter;
	}
	
	// 计算出中心点的坐标值
	CGFloat centerX = (faceRect[0] + faceRect[2]) * 0.5;
	CGFloat centerY = (faceRect[1] + faceRect[3]) * 0.5;
	
	// 将坐标系转换成以左上角为原点的坐标系
	centerX = frameSize.width - centerX;
	centerX = centerX / frameSize.width;
	
	centerY = frameSize.height - centerY;
	centerY = centerY / frameSize.height;
	
	CGPoint center = CGPointMake(centerX, centerY);
	
	preCenter = center;
	
	return center;
}

// 根据 beardLabel 获取 beard name
- (NSString *)getBeardNameWithNum:(int)num Qtype:(BOOL)q male:(BOOL)male {
	
	NSString *beardName = @"beard-noitem" ;
	if (!q && !male) {
		return beardName ;
	}
	
	if (num > 0 && num <= 2) {
		beardName = q ? @"beard04" : @"male_beard_4" ;
	}else if (num > 2 && num < 5){
		beardName = q ? @"beard05" : @"male_beard_5" ;
	}else if (num >= 5 && num < 7){
		beardName = q ? @"beard06" : @"male_beard_6" ;
	}else if (num >= 7 && num < 13){
		beardName = q ? @"beard01" : @"male_beard_1" ;
	}else if (num >= 12 && num < 19){
		beardName = q ? @"beard02" : @"male_beard_2" ;
	}else if (num >= 19 && num <= 37){
		beardName = q ? @"beard03" : @"male_beard_3" ;
	}
	return [beardName  stringByAppendingString:@".bundle"];
}

// 根据 hairLabel 获取 hair name
- (NSString *)gethairNameWithNum:(int)num {
	
	NSString *hairName = @"hair-noitem" ;
	
	if (num < 7) {
		hairName = [NSString stringWithFormat:@"male_hair_%d", num];
	}else if (num == 7 ||
			  (num >= 10 && num < 12) ||
			  num == 12              ||
			  (num > 14 && num < 17) ||
			  (num > 20 && num < 24) ){
		hairName = [NSString stringWithFormat:@"female_hair_%d", num];
	}else if (num == 8){
		hairName = @"female_hair_7";
	}else if (num == 9){
		hairName = @"female_hair_9";
	}else if (num == 14){
		hairName = @"female_hair_13";
	}else if (num == 17){
		hairName = @"female_hair_16";
	}else if (num == 18){
		hairName = @"female_hair_13";
	}else if (num == 19){
		hairName = @"female_hair_12";
	}else if (num == 24){
		hairName = @"female_hair_13";
	}else if (num == 20){
		hairName = @"female_hair_21";
	}else if (num == 12){
		hairName = @"female_hair_t_1";
	}
	
	return [hairName  stringByAppendingString:@".bundle"];
}

- (NSString *)gethairNameWithNum:(int)num andGender:(FUGender)g{
	
	    
    NSString *hairName = @"hair-noitem" ;
    
    switch (num) {
        case -1:
            if (g == FUGenderMale) {
                NSArray * hairArr = @[@"male_hair_1",@"male_hair_1_t1",@"male_hair_1_t2",@"male_hair_1_t3",@"male_hair_1_t4"];
                int value = arc4random() % hairArr.count;
                hairName = hairArr[value];
            }else if (g == FUGenderFemale) {
                hairName = @"female_hair_11";
            }
            
        case 0:
            hairName = @"male_hair_0";
            break;
            
        case 1:{
            NSArray * hairArr = @[@"male_hair_1",@"male_hair_1_t1",@"male_hair_1_t2",@"male_hair_1_t3",@"male_hair_1_t4"];
            int value = arc4random() % hairArr.count;
            hairName = hairArr[value];
        }
            break;
        case 2:
        case 3:
            hairName = [NSString stringWithFormat:@"male_hair_%d", num];
            break;
        case 4:{
            NSArray * hairArr = @[@"male_hair_4",@"male_hair_4_t1",@"male_hair_4_t2"];
            int value = arc4random() % hairArr.count;
            hairName = hairArr[value];
        }
            break;
        case 5:
        case 6:
            hairName = [NSString stringWithFormat:@"male_hair_%d", num];
            break;
        case 7:
        case 8:
        case 9:
        case 10:
            hairName = [NSString stringWithFormat:@"female_hair_%d", num];
            break;
        case 11:
        case 12:
            hairName = [NSString stringWithFormat:@"female_hair_%d", num];
            break;
        case 13:
        case 14:
            hairName = @"female_hair_13";
            break;
        case 15:
        case 16:
            hairName = [NSString stringWithFormat:@"female_hair_%d", num];
            break;
        case 17:
        case 18:
            hairName = @"female_hair_17";
            break;
        case 19:
        case 20:
            hairName = [NSString stringWithFormat:@"female_hair_%d", num];
            break;
        case 21:
        {
            NSArray * hairArr = @[@"female_hair_21",@"female_hair_21_t1",@"female_hair_21_t2",@"female_hair_21_t3",@"female_hair_21_t4"];
            int value = arc4random() % hairArr.count;
            hairName = hairArr[value];
        }
            break;
            
        case 22:
            hairName = @"female_hair_22";
            
        case 23:
        case 24:
            hairName = @"female_hair_23";
            break;
            
            
        default:
            break;
    }
	
	return [hairName stringByAppendingString:@".bundle"] ;
}

// 从色卡列表获取最相近的颜色
- (FUP2AColor *)getColorWithColorInfo:(NSArray *)colorInfo colorList:(NSArray *)list {
	
	float r = [colorInfo[0] floatValue];
	float g = [colorInfo[1] floatValue];
	float b = [colorInfo[2] floatValue];
	
	NSInteger index = 0 ;
	double min_distance = 1000.0 ;
	
	for (FUP2AColor *des_color in list) {
		double distance = sqrt((r - des_color.r) * (r - des_color.r) + (g - des_color.g) * (g - des_color.g) + (b - des_color.b) * (b - des_color.b)) ;
		if (distance < min_distance) {
			min_distance = distance ;
			index = [list indexOfObject:des_color];
		}
	}
	if (index == list.count - 1) {
		index -- ;
	}
	return list[index] ;
}

// 获取默认眼镜
- (NSString *)getGlassesNameWithShape:(int)shape rim:(int)rim male:(BOOL)male{
	
	if (shape == 1 && rim == 0) {
		return male ? @"male_glass_1" : @"female_glass_1" ;
	}else if (shape == 0 && rim == 0){
		return male ? @"male_glass_2" : @"female_glass_2" ;
	}else if (shape == 1 && rim == 1){
		return male ? @"male_glass_8" : @"female_glass_8" ;
	}else if (shape == 1 && rim == 2){
		return male ? @"male_glass_15" : @"female_glass_15" ;
	}
	return @"glasses-noitem" ;
}

// 获取Q风格默认眼镜
- (NSString *)getQGlassesNameWithShape:(int)shape rim:(int)rim male:(BOOL)male{
	NSString * glassesName = @"glass_13";
	if (shape == 1 && rim == 0) {
		glassesName = @"glass_14" ;
	}else if (shape == 0 && rim == 0){
		glassesName = @"glass_2";
	}else if (shape == 1 && rim == 1){
		glassesName = @"glass_8";
	}else if (shape == 1 && rim == 2){
		glassesName = @"glass_15";
	}
	return [glassesName stringByAppendingString:@".bundle"];
}



@end
