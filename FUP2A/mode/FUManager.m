//
//  FUManager.m
//  P2A
//
//  Created by L on 2018/12/17.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUManager.h"
#import "authpack.h"
#import "FURenderer.h"
#import <FUP2AClient/FUP2AClient.h>
#import "FURequestManager.h"
#import "FUAvatar.h"
#import "FUP2AColor.h"
#import <FUP2AHelper/FUP2AHelper.h>

@interface FUManager ()
{
    // render 句柄
    int mItems[7] ;
    // ar模式下 render 句柄
    int arItems[2] ;
    // 输出 buffer
    CVPixelBufferRef renderTarget;
    // 图像宽高
    CGSize frameSize ;
    // 光线检测
    float lightingValue ;
    // 同步信号量
    dispatch_semaphore_t signal;
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

        [self creatPixelBuffer];

        [self loadTongueMode];

        // p2a bin
        NSString *corePath = [[NSBundle mainBundle] pathForResource:@"p2a_client_core" ofType:@"bin"];
        NSString *qPath = [[NSBundle mainBundle] pathForResource:@"p2a_client_q" ofType:@"bin"];
        [[FUP2AClient shareInstance] setupClientWithCoreDataPath:corePath customDataPath:qPath authPackage:&g_auth_package authSize:sizeof(g_auth_package)];
        
        [[FUP2AHelper shareInstance] setupHelperWithAuthPackage:&g_auth_package authSize:sizeof(g_auth_package)];

        [self loadFxaa];

        NSString *bgPath = [[NSBundle mainBundle] pathForResource:@"bg" ofType:@"bundle"];
        [self reloadBackGroundWithFilePath:bgPath];

        [self loadSubData];

        self.currentAvatars = [NSMutableArray arrayWithCapacity:1];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarListPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:AvatarListPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        frameSize = CGSizeZero ;
        
        signal = dispatch_semaphore_create(1);
    }
    return self ;
}

- (void)initFaceUnity {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"v3.bundle" ofType:nil];
    [[FURenderer shareRenderer] setupWithDataPath:path authPackage:&g_auth_package authSize:sizeof(g_auth_package) shouldCreateContext:YES];
    
    [FURenderer setMaxFaces:1];
}

- (void)creatPixelBuffer {
    
    CGSize size = [UIScreen mainScreen].currentMode.size;
    
    if (!renderTarget) {
        NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
                                                  @(kCVPixelFormatType_32BGRA),
                                              (NSString*) kCVPixelBufferWidthKey : @(size.width),
                                              (NSString*) kCVPixelBufferHeightKey : @(size.height),
                                              (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
                                              (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
        CVPixelBufferCreate(kCFAllocatorDefault,
                            size.width, size.height,
                            kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)pixelBufferOptions,
                            &renderTarget);
    }
}

// 加载舌头Mode
- (void)loadTongueMode {
    NSData *tongueData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tongue.bundle" ofType:nil]];
    [FURenderer loadTongueModel:(void *)tongueData.bytes size:(int)tongueData.length];
}

//加载抗锯齿
- (void)loadFxaa {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"fxaa" ofType:@"bundle"];
    mItems[0] = [FURenderer itemWithContentsOfFile:filePath];
}

/**
 加载背景道具
 
 @param filePath 背景道具所在路径
 */
- (void)reloadBackGroundWithFilePath:(NSString *)filePath {
    
    if (filePath == nil) {
        
        if (mItems[1] != 0) {
            [FURenderer destroyItem:mItems[1]];
            mItems[1] = 0 ;
        }
        return ;
    }
    
    int destroyItem = mItems[1] ;
    
    mItems[1] = [FURenderer itemWithContentsOfFile:filePath];
    
    if (destroyItem != 0) {
        
        [FURenderer destroyItem:destroyItem];
        destroyItem = 0 ;
    }
}

/**
 背景道具是否存在
 
 @return 是否存在
 */
- (BOOL)isBackgroundItemExist {
    return mItems[1] != 0 ;
}

#pragma mark ----- 以下数据
-(NSString *)appVersion {
    return @"DigiMe Art v1.4.0" ;
}

-(NSString *)sdkVersion {
    NSString *version = [[FUP2AClient shareInstance] getClientVersion];
    return [NSString stringWithFormat:@"SDK v%@", version] ;
}

- (void)loadSubData {
    
    // female hairs
    NSArray *ornamentArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Ornament.plist" ofType:nil]];
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
    
    // mesh points
    NSData *meshData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MeshPoints" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *meshDict = [NSJSONSerialization JSONObjectWithData:meshData options:NSJSONReadingMutableContainers error:nil];
    
    self.maleMeshPoints = meshDict[@"male"] ;
    self.femaleMeshPoints = meshDict[@"female"] ;
}

-(NSMutableArray *)avatarList {
    if (!_avatarList) {
        _avatarList = [NSMutableArray arrayWithCapacity:1];
        
        NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Avatars" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *dataArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        
        for (NSDictionary *dict in dataArray) {
            FUAvatar *avatar = [FUAvatar avatarWithInfoDic:dict];
            [_avatarList addObject:avatar];
        }
        
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:AvatarListPath error:nil];
        array = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj2 compare:obj1 options:NSNumericSearch] ;
        }];
        for (NSString *jsonName in array) {
            if (![jsonName hasSuffix:@".json"]) {
                continue ;
            }
            NSString *jsonPath = [AvatarListPath stringByAppendingPathComponent:jsonName];
            NSData *jsonData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            
            FUAvatar *avatar = [FUAvatar avatarWithInfoDic:dic];
            [_avatarList addObject:avatar];
        }
    }
    return _avatarList ;
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
        mItems[2] = 0 ;
    }
    
    // 创建新的
    mItems[2] = [avatar loadAvatar];
    // 保存到当前 render 列表里面
    [self.currentAvatars addObject:avatar];
    
    dispatch_semaphore_signal(signal);
}

/**
 普通模式下 新增 Avatar render
 
 @param avatar 新增的 Avatar
 */
- (void)addRenderAvatar:(FUAvatar *)avatar {
    
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    
    // 创建新的
    int handle = [avatar loadAvatar];
    // 保存到当前 render 列表里面
    [self.currentAvatars addObject:avatar];
    
    mItems[self.currentAvatars.count + 1] = handle ;
    
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
    
    NSInteger index = [self.currentAvatars indexOfObject:avatar];
    
    [avatar destroyAvatar];
    
    mItems[index + 2] = 0 ;
    
    // 调整 render 顺序
    if (index < self.currentAvatars.count -1) {
        
        for (NSInteger i = index + 2; i < self.currentAvatars.count + 2; i ++) {
            mItems[i] = mItems[i + 1] ;
            mItems[i + 1] = 0 ;
            
            if (i == sizeof(mItems)/sizeof(int) - 1) {
                break ;
            }
        }
    }
    
    [self.currentAvatars removeObject:avatar];
    
    dispatch_semaphore_signal(signal);
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


static int frameId = 0 ;
/**
 Avatar 处理接口
 
 @param pixelBuffer 图像数据
 @param renderMode  render 模式
 @param landmarks   landmarks 数组
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks {
    
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    
    float expression[56] = {0};
    float translation[3] = {0};
    float rotation[4] = {0};
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
    info.is_valid = is_valid ;
    
    CVPixelBufferLockBaseAddress(renderTarget, 0);
    
    void *bytes = (void *)CVPixelBufferGetBaseAddress(renderTarget);
    int stride1 = (int)CVPixelBufferGetBytesPerRow(renderTarget);
    int h1 = (int)CVPixelBufferGetHeight(renderTarget);
    
    [[FURenderer shareRenderer] renderItems:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:bytes outFormat:FU_FORMAT_BGRA_BUFFER width:stride1/4 height:h1 frameId:frameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int) flipx:NO];
    
    CVPixelBufferUnlockBaseAddress(renderTarget, 0);
    
    dispatch_semaphore_signal(signal);
    
    return renderTarget ;
}


static int ARFilterID = 0 ;
/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer {
    
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
    int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
    void *bytes = CVPixelBufferGetBaseAddress(pixelBuffer) ;
    
    [[FURenderer shareRenderer] renderItems:bytes inFormat:FU_FORMAT_BGRA_BUFFER outPtr:bytes outFormat:FU_FORMAT_BGRA_BUFFER width:stride/4 height:height frameId:ARFilterID ++ items:arItems itemCount:2 flipx:NO];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    dispatch_semaphore_signal(signal);
    
    return pixelBuffer ;
}

/**
 Avatar 生成
 
 @param data    服务端拉流数据
 @param name    Avatar 名字
 @param gender  Avatar 性别
 @return        生成的 Avatar
 */
- (FUAvatar *)createAvatarWithData:(NSData *)data avatarName:(NSString *)name gender:(FUGender)gender {
    
    FUAvatar *avatar = [[FUAvatar alloc] init];
    avatar.defaultModel = NO ;
    avatar.name = name;
    avatar.gender = gender ;
    
    // create head
    NSData *finalBundleData = [[FUP2AClient shareInstance] createAvatarHeadWithData:data];
    [finalBundleData writeToFile:[[avatar filePath] stringByAppendingPathComponent:@"head.bundle"] atomically:YES];
    
    // 头发
    int hairLabel = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"hair_label"];
    avatar.hairLabel = hairLabel ;
    NSString *defaultHair = [self gethairNameWithNum:hairLabel];
    if ([defaultHair isEqualToString:@"hair-noitem"]) {
        defaultHair = gender == FUGenderMale ? @"male_hair_2" : @"female_td2" ;
    }
    avatar.hair = defaultHair ;
    
    NSData *baseHairData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:defaultHair ofType:@"bundle"]];
    NSData *defaultHairData = [[FUP2AClient shareInstance] createAvatarHairWithServerData:data defaultHairData:baseHairData];
    NSString *defaultHairPath = [[[avatar filePath] stringByAppendingPathComponent:defaultHair] stringByAppendingString:@".bundle"];
    [defaultHairData writeToFile:defaultHairPath atomically:YES];
    
    // 衣服
    avatar.clothes = gender == FUGenderMale ? @"male_clothes_1" : @"female_clothes_1" ;
    
    // 胡子
    int beardLabel = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"beard_label"];
    avatar.bearLabel = beardLabel ;
    avatar.beard = gender == FUGenderMale ? [self getBeardNameWithNum:beardLabel] : @"beard-noitem";
    
//    // 眼镜
    int hasGlass = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"has_glasses"];
    if (hasGlass == 0) {
        avatar.glasses = @"glasses-noitem" ;
    }else {
        int shapeGlasses = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"shape_glasses"];
        int rimGlasses = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"rim_glasses"];
        NSString *glassName = [self getGlassesNameWithShape:shapeGlasses rim:rimGlasses male:gender == FUGenderMale];
        avatar.glasses = glassName ;
    }
    
    avatar.hat = @"hat-noitem" ;
    
    // avatar info
    NSMutableDictionary *avatarInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    
    [avatarInfo setObject:@(0) forKey:@"default"];
    [avatarInfo setObject:name forKey:@"name"];
    [avatarInfo setObject:@(gender) forKey:@"gender"];
    [avatarInfo setObject:@(hairLabel) forKey:@"hair_label"];
    [avatarInfo setObject:defaultHair forKey:@"hair"];
    [avatarInfo setObject:avatar.clothes forKey:@"clothes"];
    [avatarInfo setObject:avatar.glasses forKey:@"glasses"];
    [avatarInfo setObject:@(beardLabel) forKey:@"beard_label"];
    [avatarInfo setObject:avatar.beard forKey:@"beard"];
    [avatarInfo setObject:avatar.hat forKey:@"hat"];
    
    NSString *avatarInfoPath = [[AvatarListPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
    NSData *avatarInfoData = [NSJSONSerialization dataWithJSONObject:avatarInfo options:NSJSONWritingPrettyPrinted error:nil];
    [avatarInfoData writeToFile:avatarInfoPath atomically:YES];
    
    // create other hairs
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *hairs = gender == FUGenderMale ? self.maleHairs : self.femaleHairs ;
        for (NSString *hairName in hairs) {
            if ([hairName isEqualToString:@"hair-noitem"] || [hairName isEqualToString:defaultHair]) {
                continue ;
            }
            NSString *hairPath = [[NSBundle mainBundle] pathForResource:hairName ofType:@"bundle"];
            NSData *d0 = [NSData dataWithContentsOfFile:hairPath];
            
            NSData *d1 = [[FUP2AClient shareInstance] createAvatarHairWithServerData:data defaultHairData:d0];
            if (d1 == nil) {
                NSLog(@"---- error path: %@", hairPath);
            }
            NSString *hp = [[[avatar filePath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
            [d1 writeToFile:hp atomically:YES];
        }
    });
    
    
    return avatar ;
}

/**
 捏脸之后生成新的 Avatar
 
 @param coeffi  捏脸参数
 @param deform  是否 deform
 @return        新的 Avatar
 */
- (FUAvatar *)createPupAvatarWithCoeffi:(float *)coeffi DeformHead:(BOOL)deform {
    
    FUAvatar *currentAvatar = self.currentAvatars.firstObject ;
    
    NSData *headData = [NSData dataWithContentsOfFile:[[currentAvatar filePath] stringByAppendingPathComponent:@"head.bundle"]];
    
    if (deform) {
        headData = [[FUP2AClient shareInstance] deformAvatarHeadWithHeadData:headData deformParams:coeffi paramsSize:69];
    }
    
    NSString *avatarName = currentAvatar.defaultModel ? [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] : currentAvatar.name ;
    
    // 文件夹
    NSFileManager *fileManager = [NSFileManager defaultManager] ;
    NSString *filePath = [documentPath stringByAppendingPathComponent:avatarName];

    if (![fileManager fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    // Avatar
    FUAvatar *avatar = [[FUAvatar alloc] init];
    avatar.name = avatarName;
    avatar.gender = currentAvatar.gender ;

    // 图片 icon
    UIImage *image = [UIImage imageWithContentsOfFile:currentAvatar.imagePath];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0) ;
    [imageData writeToFile:avatar.imagePath atomically:YES];

    // 头
    [headData writeToFile:[[avatar filePath] stringByAppendingPathComponent:@"head.bundle"] atomically:YES];
    // 头发
    NSArray *hairs = currentAvatar.gender == FUGenderMale ? self.maleHairs : self.femaleHairs ;
    
    if (currentAvatar.defaultModel) { // 预置模型
        // copy json
        NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Avatars.json" ofType:nil] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *avatarsArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        NSData *avatarInfoData ;
        for (NSDictionary *avatarInfo in avatarsArray) {
            if ([avatarInfo[@"name"] isEqualToString:currentAvatar.name]) {

                [avatarInfo setValue:avatar.name forKey:@"name"];
                [avatarInfo setValue:@(0) forKey:@"default"];
                avatarInfoData = [NSJSONSerialization dataWithJSONObject:avatarInfo options:NSJSONWritingPrettyPrinted error:nil];
                break ;
            }
        }

        NSString *jsonPath = [[AvatarListPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
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
        
        return @" 请保持正面  " ;
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
        
        if (expression[i] > 0.50) {
            
            return @" 请保持面部无夸张表情  " ;
        }
    }
    
    // 5、光照均匀
    // 6、光照充足
    if (lightingValue < 0.0) {
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
- (NSString *)getBeardNameWithNum:(int)num {
    
    NSString *beardName = @"beard-noitem" ;
    
    if (num > 0 && num <= 2) {
        beardName = @"male_beard_4" ;
    }else if (num > 2 && num < 5){
        beardName = @"male_beard_5" ;
    }else if (num >= 5 && num < 7){
        beardName = @"male_beard_6" ;
    }else if (num >= 7 && num < 13){
        beardName = @"male_beard_1" ;
    }else if (num >= 12 && num < 19){
        beardName = @"male_beard_2" ;
    }else if (num >= 19 && num <= 37){
        beardName = @"male_beard_3" ;
    }
    return beardName ;
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
    
    return hairName ;
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

@end
