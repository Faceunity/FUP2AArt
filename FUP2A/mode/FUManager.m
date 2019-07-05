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
    
    __block BOOL isCreatingAvatar ;
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
        
        [[FUP2AHelper shareInstance] setupHelperWithAuthPackage:&g_auth_package authSize:sizeof(g_auth_package)];

        [self loadFxaa];
        
        // 加载舌头
        NSData *tongueData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tongue.bundle" ofType:nil]];
        [FURenderer loadTongueModel:(void *)tongueData.bytes size:(int)tongueData.length];
        
        NSString *bgPath = [[NSBundle mainBundle] pathForResource:@"background" ofType:@"bundle"];
        [self reloadBackGroundWithFilePath:bgPath];

        self.currentAvatars = [NSMutableArray arrayWithCapacity:1];
        
        frameSize = CGSizeZero ;
        
        signal = dispatch_semaphore_create(1);
        
        isCreatingAvatar = NO ;
    }
    return self ;
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
            if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarQPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:AvatarQPath withIntermediateDirectories:YES attributes:nil error:nil];
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
        [[FUP2AClient shareInstance] setupClientWithCoreDataPath:corePath customDataPath:qPath authPackage:&g_auth_package authSize:sizeof(g_auth_package)];
    }else {
        [[FUP2AClient shareInstance] reSetupCustomData:qPath];
    }
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
    NSString* versionStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"DigiMe Art v%@",versionStr];
}

-(NSString *)sdkVersion {
    NSString *version = [[FUP2AClient shareInstance] getClientVersion];
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
    _qBeard = expDic[@"items"] ;
    
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
            NSString *jsonPath = self.avatarStyle == FUAvatarStyleNormal ? [AvatarListPath stringByAppendingPathComponent:jsonName] : [AvatarQPath stringByAppendingPathComponent:jsonName];
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
    
    isCreatingAvatar = YES ;
    

    
    FUAvatar *avatar = [[FUAvatar alloc] init];
    avatar.defaultModel = NO ;
    avatar.name = name;
    avatar.gender = gender ;
    BOOL isQ = self.avatarStyle == FUAvatarStyleQ ;
    avatar.isQType = isQ ;
    
    // create head
    NSData *finalBundleData = [[FUP2AClient shareInstance] createAvatarHeadWithData:data];
    [finalBundleData writeToFile:[[avatar filePath] stringByAppendingPathComponent:@"head.bundle"] atomically:YES];
    
    // 头发
    int hairLabel = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"hair_label"];
    avatar.hairLabel = hairLabel ;
    NSString *defaultHair = [self gethairNameWithNum:hairLabel];
//    if ([defaultHair isEqualToString:@"hair-noitem"]) {
//        defaultHair = gender == FUGenderMale ? @"male_hair_2" : @"female_td2" ;
//    }
//    if (isQ) {
//        defaultHair = gender == FUGenderMale ? @"male_hair_q_3" : @"female_hair_q_21" ;
//    }
	if (isQ) {
		NSString *string = defaultHair;
		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"_hair_" options:NSRegularExpressionCaseInsensitive error:&error];
		NSString *modifiedString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"_hair_q_"];
		NSLog(@"%@", modifiedString);
		defaultHair = modifiedString;
	}
    avatar.hair = defaultHair ;
    
    NSString *baseHairPath = [[NSBundle mainBundle] pathForResource:avatar.hair ofType:@"bundle"] ;
    NSData *baseHairData = [NSData dataWithContentsOfFile: baseHairPath];
    NSData *defaultHairData = [[FUP2AClient shareInstance] createAvatarHairWithServerData:data defaultHairData:baseHairData];
    NSString *defaultHairPath = [[[avatar filePath] stringByAppendingPathComponent:defaultHair] stringByAppendingString:@".bundle"];
    [defaultHairData writeToFile:defaultHairPath atomically:YES];
    
    // 眼镜
    int hasGlass = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"has_glasses"];
//    avatar.glasses = hasGlass == 0 ? @"glasses-noitem" : (gender == FUGenderMale ? @"male_glass_1" : @"female_glass_1");
    if (hasGlass == 0) {
        avatar.glasses = @"glasses-noitem" ;
    }else {
		int shapeGlasses = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"shape_glasses"];
		int rimGlasses = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"rim_glasses"];
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
    
    if (avatar.isQType) {
        // 衣服
        avatar.clothes = @"mid_cloth0" ;
//        // 鞋子
//        avatar.shoes = self.qShoes[1] ;
//        [avatarInfo setObject:avatar.shoes forKey:@"shoes"];
    }else {
        // 衣服
        avatar.clothes = gender == FUGenderMale ? @"male_clothes_1" : @"female_clothes_1" ;
    }
    
    // 胡子
    int beardLabel = [[FUP2AClient shareInstance] getIntParamWithData:data key:@"beard_label"];
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
    [avatarInfo setObject:avatar.clothes forKey:@"clothes"];
    [avatarInfo setObject:avatar.glasses forKey:@"glasses"];
    [avatarInfo setObject:avatar.hat forKey:@"hat"];
    

    
    avatar.hairColor = self.hairColorArray[0] ;
    
    NSString *avatarInfoPath = self.avatarStyle == FUAvatarStyleNormal ? [[AvatarListPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"] : [[AvatarQPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
    NSData *avatarInfoData = [NSJSONSerialization dataWithJSONObject:avatarInfo options:NSJSONWritingPrettyPrinted error:nil];
    [avatarInfoData writeToFile:avatarInfoPath atomically:YES];
    appManager.localizeHairBundlesSuccess = false;
    // create other hairs
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *hairs ;
        if (avatar.isQType) {
            hairs = self.qHairs ;
        }else {
            hairs = gender == FUGenderMale ? self.maleHairs : self.femaleHairs ;
        }
        for (NSString *hairName in hairs) {
            if ([hairName isEqualToString:@"hair-noitem"] || [hairName isEqualToString:@"hair_q_noitem"] || [hairName isEqualToString:defaultHair]) {
                continue ;
            }
            NSString *hairPath = [[NSBundle mainBundle] pathForResource:hairName ofType:@"bundle"];
            NSData *d0 = [NSData dataWithContentsOfFile:hairPath];
            
//            CFAbsoluteTime startProcessHair1 = CFAbsoluteTimeGetCurrent() ;
            NSData *d1 = [[FUP2AClient shareInstance] createAvatarHairWithServerData:data defaultHairData:d0];
//            NSLog(@"------------ process hair time: %f ms - hair name: %@", (CFAbsoluteTimeGetCurrent() - startProcessHair1) * 1000.0, hairName);
            if (d1 == nil) {
                NSLog(@"---- error path: %@", hairPath);
            }
            NSString *hp = [[[avatar filePath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
            [d1 writeToFile:hp atomically:YES];
        }
		appManager.localizeHairBundlesSuccess = true;
		[[NSNotificationCenter defaultCenter] postNotificationName:HairsWriteToLocalSuccessNot object:nil];
        self->isCreatingAvatar = NO ;
    });
 
    return avatar ;
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
    avatar.isQType = currentAvatar.isQType ;
    avatar.gender = currentAvatar.gender ;

    // 图片 icon
    UIImage *image = [UIImage imageWithContentsOfFile:currentAvatar.imagePath];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0) ;
    [imageData writeToFile:avatar.imagePath atomically:YES];

    // 头
    [headData writeToFile:[[avatar filePath] stringByAppendingPathComponent:@"head.bundle"] atomically:YES];
    // 头发
    NSArray *hairs = avatar.isQType ? self.qHairs : (currentAvatar.gender == FUGenderMale ? self.maleHairs : self.femaleHairs) ;
    
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

        NSString *jsonPath = avatar.isQType ? [[AvatarQPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"] : [[AvatarListPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
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

// 获取Q风格默认眼镜
- (NSString *)getQGlassesNameWithShape:(int)shape rim:(int)rim male:(BOOL)male{
	
    if (shape == 1 && rim == 0) {
        return @"glass_14" ;
    }else if (shape == 0 && rim == 0){
        return @"glass_2";
    }else if (shape == 1 && rim == 1){
        return @"glass_8";
    }else if (shape == 1 && rim == 2){
        return @"glass_15";
    }
    return @"glasses-noitem" ;
}

// batch creat avatars
static dispatch_semaphore_t batchProcessSignal ;
- (void)batchCreatingAvatarsWithImageInfos:(NSArray *)imageInfos Completion:(void (^)(void))handle {
    
    if (!batchProcessSignal) {
        batchProcessSignal = dispatch_semaphore_create(1) ;
    }
    
    for (NSDictionary *infoDict in imageInfos) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSString *imagePath = infoDict[@"imagePath"] ;
            BOOL male = [infoDict[@"male"] boolValue] ;
            
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            if (image != nil) {
                
                dispatch_semaphore_wait(batchProcessSignal, DISPATCH_TIME_FOREVER) ;
                
                NSDictionary *params = @{ @"gender":male ? @(0) : @(1), @"is_q": @(1) };
                
                [[FURequestManager sharedInstance] createQAvatarWithImage:image Params:params CompletionWithData:^(NSData *data, NSError *error) {
                    if (!error) {
                        NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
                        NSString *fileName = [NSString stringWithFormat:@"%.0f", time];
                        NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
                        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
                        
                        NSData *imageData = UIImagePNGRepresentation(image) ;
                        NSString *imageDataPath = [filePath stringByAppendingPathComponent:@"image.png"] ;
                        [imageData writeToFile:imageDataPath atomically:YES];
                        
                        [data writeToFile:[filePath stringByAppendingPathComponent:@"server.bundle"] atomically:YES];
                        
                        FUAvatar *avatar = [[FUManager shareInstance] createAvatarWithData:data avatarName:fileName gender:male ? FUGenderMale : FUGenderFemale];
                        
                        [[FUManager shareInstance].avatarList insertObject:avatar atIndex:DefaultAvatarNum];
                        
                        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
                        NSLog(@"----------------------------------------------------------------------------------------------- process one completed~ ");
                        dispatch_semaphore_signal(batchProcessSignal);
                        
                        if ([imageInfos indexOfObject:infoDict] == imageInfos.count - 1) {
                            handle() ;
                        }
                    }else {
                        
                        NSDictionary *userInfo = error.userInfo;
                        NSHTTPURLResponse *response = userInfo[@"com.alamofire.serialization.response.error.response"];
                        NSInteger code = response.statusCode;
                        
                        NSString *message = @"网络访问错误" ;
                        if (code == 500) {
                            NSData *data = userInfo[@"com.alamofire.serialization.response.error.data"];
                            
                            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            
                            if ([str isEqualToString:@"server busy"]) {
                                message = @"服务器被占用" ;
                            }else if ([str isEqualToString:@"输入参数错误"]){
                                message = @"bad input" ;
                            }else {
                                int errIndex = [str intValue] ;
                                message = [self getErrorMessageWithIndex:errIndex];
                            }
                        }
                        NSLog(@"------ batch process error: %@", message);
                        
                        dispatch_semaphore_signal(batchProcessSignal);
                    }
                }];
            }
        });
    }
}

- (NSString *)getErrorMessageWithIndex:(int)errorIndex {
    NSString *message ;
    switch (errorIndex) {
        case 1:
            message = @"无法加载输入图片" ;
            break;
        case 2:
            message = @"未检测到人脸" ;
            break;
        case 3:
            message = @"检测到多个人脸" ;
            break;
        case 4:
            message = @"检测不到头发" ;
            break;
        case 5:
            message = @"输入图片不符合要求" ;
            break;
        case 6:
            message = @"非正脸图片" ;
            break;
        case 7:
            message = @"非清晰人脸" ;
            break;
        case 8:
            message = @"未找到匹配发型" ;
            break;
        case 9:
            message = @"未知错误" ;
            break;
        case 10:
            message = @"FOV错误" ;
            break;
            
        default:
            message = @"未知错误" ;
            break;
    }
    return message ;
}

@end
