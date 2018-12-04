//
//  FUManager.m
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUManager.h"
#import "FUP2ADefine.h"
#import "FURenderer.h"
#import "authpack.h"
#import <ZipArchive.h>
#import <FUP2AClient/FUP2AClient.h>
#import "FURequestManager.h"

@interface FUManager ()
{
    // 输出 buffer
    CVPixelBufferRef renderTarget;
    
    // 句柄数组
    int mItems[12];
    int arItems[2] ;
    
    // 旋转缩放参数
    NSMutableDictionary *p2aParams;
    
    CGSize frameSize ;
    float lightingValue ;
    dispatch_semaphore_t signal;
    dispatch_semaphore_t arSignal;
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
        signal = dispatch_semaphore_create(1);
        arSignal = dispatch_semaphore_create(1) ;
        [self initFaceUnity];
        
        // 设置旋转缩放参数
        p2aParams = [NSMutableDictionary dictionary];
        [self resetP2AParams];
        
        [self creatPixelBuffer];
        
        [self loadFxaa];
        [self loadBackgroundItem];
        // 加载 controller
        [self loadController];
        
        frameSize = CGSizeZero ;
        
        // p2a bin
        NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"p2a_client" ofType:@"bin"];
        NSData *data = [NSData dataWithContentsOfFile:dataPath];
        [FUP2AClient setupWithClientData:data];
        
        [self loadSubData];
    }
    return self ;
}

- (void)initFaceUnity {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"v3.bundle" ofType:nil];
    [[FURenderer shareRenderer] setupWithDataPath:path authPackage:&g_auth_package authSize:sizeof(g_auth_package) shouldCreateContext:YES];
    
    [FURenderer setMaxFaces:1];
}

-(NSString *)appVersion {
    return @"DigiMe Art v1.0.0" ;
}

-(NSString *)sdkVersion {
    return @"SDK v1.0.0";
}

/*------------ 数据 -----------*/
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
            
            FUFigureColor *color = [FUFigureColor colorWithDict:subValue];
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
}

-(NSMutableArray *)avatars {
    if (!_avatars) {
        _avatars = [NSMutableArray arrayWithCapacity:1];
        NSArray *dataArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Avatars.plist" ofType:nil]];
        for (NSDictionary *dict in dataArray) {
            FUAvatar *avatar = [[FUAvatar alloc] init];
            NSString *bundleName = dict[@"itemName"] ;
            avatar.bundleName = bundleName ;
            NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
            avatar.bundlePath = bundlePath ;
            BOOL isMale = [dict[@"isMale"] boolValue] ;
            avatar.isMale = isMale ;
            NSString *imagePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"png"];
            if (![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                imagePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"jpg"];
            }
            avatar.imagePath = imagePath ;
            
            avatar.hairArr = isMale ? self.maleHairs : self.femaleHairs ;
            
            avatar.defaultHair = dict[@"hair"] ;
            avatar.defaultClothes = isMale ? @"male_clothes" : @"female_clothes" ;
            avatar.defaultGlasses = @"glasses-noitem" ;
            avatar.defaultBeard = isMale ? dict[@"beard"] : @"beard-noitem" ;
            
            avatar.hairLabel = -1.0 ;
            avatar.bearLabel = -1.0 ;
            avatar.matchLabel = -1 ;
            
            [_avatars addObject:avatar];
        }
        NSMutableArray<FUAvatar *> *history = [NSKeyedUnarchiver unarchiveObjectWithFile:historyPath];
        if (history) {
            [_avatars addObjectsFromArray:history];
        }
    }
    return _avatars ;
}

- (void)creatPixelBuffer {
    
    CGSize size = [UIScreen mainScreen].currentMode.size;
    if (size.width > 800) {
        CGFloat a = 0.7;
        CGFloat w = (((int)(size.width*a) + 3)>>2) * 4;
        CGFloat h = (((int)(size.height*a) + 3)>>2) * 4;
        size = CGSizeMake(w, h);
    }
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
    [self loadItemWithtype:FUItemTypeFxaa filePath:filePath];
}

//加载背景道具
- (void)loadBackgroundItem {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"bg" ofType:@"bundle"];
    [self loadItemWithtype:FUItemTypeBackground filePath:filePath];
}

// 加载 controller
- (void)loadController {
    if (mItems[FUItemTypeController] == 0) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"controller" ofType:@"bundle"];
        [self loadItemWithtype:FUItemTypeController filePath:filePath];
    }
}

// 加载 avatar
- (void)loadAvatar:(FUAvatar *)avatar {
    self.currentAvatar = avatar ;
    
    [self loadItemWithtype:FUItemTypeAvatar filePath:avatar.bundlePath];
    
    [self loadAvatarBody];
    
    [self loadAvatarHair];
    
    [self loadAvatarClothes];
    
    [self loadAvatarGlasses];
    
    [self loadAvatarBeard];
    
    [self loadAvatarHat];
    
    [self setDefaultColorForAvatar:avatar];
}

- (void)loadAvatarHair {
    
    NSString *hairPath = nil ;
    if (self.currentAvatar.defaultHair) {
        NSString *hairName = self.currentAvatar.defaultHair ;
        if (self.currentAvatar.time) {      // 生成的
            hairPath = [[[self.currentAvatar avatarPath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
        }else {             // 预置模型
            hairPath = [[[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:self.currentAvatar.bundleName] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
        }
    }
    [self loadItemWithtype:FUItemTypeHair filePath:hairPath];
}

- (void)loadAvatarBody {
    NSString *bundleName = self.currentAvatar.isMale ? @"male_body" : @"female_body" ;
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
    [self loadItemWithtype:FUItemTypeBody filePath:bundlePath];
}

- (void)loadAvatarClothes {
    
    NSString *clothName = self.currentAvatar.defaultClothes ;
    NSString *clothPath = [[NSBundle mainBundle] pathForResource:clothName ofType:@"bundle"];
    [self loadItemWithtype:FUItemTypeClothes filePath:clothPath];
}

- (void)loadAvatarGlasses {
    NSString *glassesPath = nil;
    if (self.currentAvatar.defaultGlasses && ![self.currentAvatar.defaultGlasses isEqualToString:@"glasses-noitem"]) {
        NSString *glasses = self.currentAvatar.isMale ? @"male_glass_01" : @"female_glass_01" ;
        glassesPath = [[NSBundle mainBundle] pathForResource:glasses ofType:@"bundle"];
    }
    [self loadItemWithtype:FUItemTypeGlasses filePath:glassesPath];
}

- (void)loadAvatarBeard {
    NSString *glassesPath = nil ;
    if (self.currentAvatar.defaultBeard) {
        glassesPath = [[NSBundle mainBundle] pathForResource:self.currentAvatar.defaultBeard ofType:@"bundle"];
    }
    [self loadItemWithtype:FUItemTypeBeard filePath:glassesPath];
}

- (void)loadAvatarHat {
    NSString *hatPath = nil ;
    if (self.currentAvatar.defaultHat) {
        hatPath = [[NSBundle mainBundle] pathForResource:self.currentAvatar.defaultHat ofType:@"bundle"];
    }
    [self loadItemWithtype:FUItemTypeHat filePath:hatPath];
}

- (void)loadItemWithtype:(FUItemType)itemType filePath:(NSString *)path {
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    if (path == nil ) {
        
        // 销毁此道具
        [self destroyItemWithType:itemType];
        dispatch_semaphore_signal(signal);
        return ;
    }
    
    int tmpHandle = [FURenderer itemWithContentsOfFile:path];
    
    // 销毁同类道具
    [self destroyItemWithType:itemType];
    
    // 绑定到 controller
    mItems[itemType] = tmpHandle;
    
    if (mItems[FUItemTypeController] && itemType > 2) {
        int tmp[1] = {tmpHandle} ;
        fuBindItems(mItems[FUItemTypeController], tmp, 1) ;
    }
    dispatch_semaphore_signal(signal);
}

// 销毁某个道具
- (void)destroyItemWithType:(FUItemType)itemType {
    
    if (mItems[itemType] != 0) {
        
        // 解绑
        if (mItems[FUItemTypeController] && itemType > 2) {
            int tmp[1];
            tmp[0]  = mItems[itemType];
            fuUnbindItems(mItems[FUItemTypeController], tmp, 1) ;
        }
        // 销毁
        [FURenderer destroyItem:mItems[itemType]];
        mItems[itemType] = 0;
    }
}

// creat avatar
- (FUAvatar *) createAvatarWithData:(NSData *)data FileName:(NSString *)fileName isMale:(BOOL)male {
    
    // create avatar
    FUAvatar *avatar = [[FUAvatar alloc] init];
    avatar.time = fileName;
    avatar.isMale = male ;
    avatar.bearLabel = -1 ;
    avatar.matchLabel = -1 ;
    
    NSData *finalBundleData = [FUP2AClient createAvatarHeadWithData:data];
    
    // save head
    [finalBundleData writeToFile:avatar.bundlePath atomically:YES];
    
    // 胡子
    int beardLabel = [FUP2AClient getIntParamWithData:data key:@"beard_label"];
    avatar.bearLabel = beardLabel ;
    avatar.defaultBeard = male ? [self getBeardNameWithNum:beardLabel] : @"beard-noitem";
    
    // match
    int matchLabel = [FUP2AClient getIntParamWithData:data key:@"id_match_facewarehouse"];
    avatar.matchLabel = matchLabel ;
    
    // create default hair
    NSString *baseHair = nil;
    
    // 默认头发
    int hairLabel = [FUP2AClient getIntParamWithData:data key:@"hair_label"];
    baseHair = [self gethairNameWithNum:hairLabel isMale:male];
    avatar.hairLabel = hairLabel ;
    if (!baseHair || baseHair.length == 0) {
        baseHair = male ? @" male_hair_2" : @"female_td2" ;
    }
    avatar.defaultHair = baseHair ;
    
    NSArray *skinColorInfo = [FUP2AClient getParamsArrayWithData:data key:@"dst_transfer_color"];
    avatar.mobileSkinColor = [self getColorWithColorInfo:skinColorInfo colorList:self.skinColorArray];
    avatar.serverSkinColor = [FUFigureColor colorWithR:[skinColorInfo[0] floatValue] g:[skinColorInfo[1] floatValue] b:[skinColorInfo[2] floatValue]];
    
    NSArray *lipColorInfo = [FUP2AClient getParamsArrayWithData:data key:@"mouth_color"];
    avatar.mobileLipColor = [self getColorWithColorInfo:lipColorInfo colorList:self.lipColorArray];
    avatar.serverLipColor = [FUFigureColor colorWithR:[lipColorInfo[0] floatValue] g:[lipColorInfo[1] floatValue] b:[lipColorInfo[2] floatValue]];
    
    NSData *baseHairData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:baseHair ofType:@"bundle"]];
    
    NSData *defaultHairData = [FUP2AClient createAvatarHairWithServerData:data defaultHairData:baseHairData];
    
    // save default hair
    NSString *defaultHairPath = [[[avatar avatarPath] stringByAppendingPathComponent:baseHair] stringByAppendingString:@".bundle"];
    [defaultHairData writeToFile:defaultHairPath atomically:YES];
    
    // other info
    avatar.defaultClothes = male ? @"male_clothes" : @"female_clothes" ;
    
    int hasGlass = [FUP2AClient getIntParamWithData:data key:@"has_glasses"];
    avatar.defaultGlasses = hasGlass == 0 ? @"glasses-noitem" : (male ? @"male_glass_01" : @"female_glass_01");
    
    // create other hairs
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray *hairs = male ? self.maleHairs : self.femaleHairs ;
        for (NSString *hairName in hairs) {
            if ([hairName isEqualToString:@"hair-noitem"] || [hairName isEqualToString:baseHair]) {
                continue ;
            }
            NSString *hairPath = [[NSBundle mainBundle] pathForResource:hairName ofType:@"bundle"];
            NSData *d0 = [NSData dataWithContentsOfFile:hairPath];
            
            NSData *d1 = [FUP2AClient createAvatarHairWithServerData:data defaultHairData:d0];
        
            NSString *hp = [[[avatar avatarPath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
            [d1 writeToFile:hp atomically:YES];
        }
    });
    
    return avatar ;
}

// 重置旋转缩放参数
- (void)resetP2AParams {
    p2aParams[@"rot_delta"] = @(0);
    p2aParams[@"scale_delta"] = @(0);
    p2aParams[@"translate_delta"] = @(0);
}

//设置移动参数
- (void)setRotDelta:(float)rot Horizontal:(BOOL)hor {
    
    if (hor) {      // 设置左右旋转参数
        float tmpRot = [p2aParams[@"rot_delta"] floatValue];
        tmpRot += rot;
        p2aParams[@"rot_delta"] = @(tmpRot);
    }else {      // 设置上下移动参数
        float td = [p2aParams[@"translate_delta"] floatValue];
        td -= rot;
        p2aParams[@"translate_delta"] = @(td);
    }
}

//设置缩放参数
- (void)setScaleDelta:(float)scale  {
    float tmpScale = [p2aParams[@"scale_delta"] floatValue];
    tmpScale += scale;
    p2aParams[@"scale_delta"] = @(tmpScale);
}

// 检测人脸处理
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer ;{
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

// Avatar 处理接口
static int frameid = 0 ;
- (CVPixelBufferRef) renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks{
    dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
    // 设置旋转 缩放
    float rot = [p2aParams[@"rot_delta"] floatValue];
    float scale = [p2aParams[@"scale_delta"] floatValue];
    float td = [p2aParams[@"translate_delta"] floatValue];
    [self resetP2AParams];
    
    [FURenderer itemSetParam:mItems[FUItemTypeController] withName:@"rot_delta" value:@(rot)];
    [FURenderer itemSetParam:mItems[FUItemTypeController] withName:@"scale_delta" value:@(scale)];
    [FURenderer itemSetParam:mItems[FUItemTypeController] withName:@"translate_delta" value:@(td)];
    [FURenderer itemSetParam:mItems[FUItemTypeController] withName:@"tile" value:@(6)];
    
    float expression[46] = {0};
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
        
        [FURenderer trackFace:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:stride/4 height:height];
        [FURenderer getFaceInfo:0 name:@"expression" pret:expression number:46];
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
    
    [[FURenderer shareRenderer] renderItems:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:bytes outFormat:FU_FORMAT_BGRA_BUFFER width:stride1/4 height:h1 frameId:frameid items:mItems itemCount:3 flipx:NO];
    
    CVPixelBufferUnlockBaseAddress(renderTarget, 0);

    frameid++;
    dispatch_semaphore_signal(signal);
    return renderTarget ;
}

// 加载待机动画
- (void)loadStandbyAnimation {
    NSString *bundleName = self.currentAvatar.isMale ? @"male_animation" : @"female_animation" ;
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
    [self loadItemWithtype:FUItemTypeStandbyAnimation filePath:bundlePath];
}
// 去除待机动画
- (void)removeStandbyAnimation {
    [self destroyItemWithType:FUItemTypeStandbyAnimation];
}
- (void)enterTrackAnimationMode {
    [FURenderer itemSetParam:mItems[FUItemTypeController] withName:@"enter_track_rotation_mode" value:@(1)];
}

- (void)loadPose {
    NSString *bundleName = self.currentAvatar.isMale ? @"male_pose" : @"female_pose" ;
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle"];
    [self loadItemWithtype:FUItemTypeStandbyAnimation filePath:bundlePath];
}

- (void)quitTrackAnimationMode {
    [FURenderer itemSetParam:mItems[FUItemTypeController] withName:@"quit_track_rotation_mode" value:@(1)];
}

// 拍摄检测
static float DetectionAngle = 20.0 ;
static float CenterScale = 0.3 ;
- (int)photoDetectionAction  {
    
    // 1、保证单人脸输入
    int faceNum = [FURenderer isTracking];
    if (faceNum != 1) {
        return 1 ;
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

        return 2 ;
    }

    // 3、保证人脸在中心区域
    CGPoint faceCenter = [self getFaceCenterInFrameSize:frameSize];
    
    if (faceCenter.x < 0.5 - CenterScale / 2.0 || faceCenter.x > 0.5 + CenterScale / 2.0
        || faceCenter.y < 0.4 - CenterScale / 2.0 || faceCenter.y > 0.4 + CenterScale / 2.0) {

        return 3 ;
    }
    
    // 4、夸张表情
    float expression[46] ;
    [FURenderer getFaceInfo:0 name:@"expression" pret:expression number:46];
    
    for (int i = 0 ; i < 46; i ++) {
        
        if (expression[i] > 0.50) {
            
            return 4 ;
        }
    }

    // 5、光照均匀
    // 6、光照充足
    if (lightingValue < 0.0) {
        return 6 ;
    }
    
    return 0 ;
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

// 进入/退出 AR
- (void)enterARMode {
    [FURenderer itemSetParam:mItems[FUItemTypeController] withName:@"reset_all" value:@1];
    // 1、 unBind身体、衣服、动画、
    int unBindItems[4] = {mItems[FUItemTypeBody],mItems[FUItemTypeClothes],mItems[FUItemTypeStandbyAnimation]};
    [FURenderer unBindItems:mItems[FUItemTypeController] items:unBindItems itemsCount:sizeof(unBindItems)/sizeof(int)];
    
    // 2、传参
    fuItemSetParamd(mItems[FUItemTypeController], "enter_ar_mode", 1) ;
    
    arItems[0] = mItems[FUItemTypeController] ;
}

- (void)quitARMode {
    fuItemSetParamd(mItems[FUItemTypeController], "quit_ar_mode", 1) ;
    arItems[0] = 0 ;
    if (arItems[1] != 0) {
        [FURenderer destroyItem:arItems[1]] ;
        arItems[1] = 0 ;
    }
    
    // bind身体、衣服、动画、
    int bindItems[4] = {mItems[FUItemTypeBody],mItems[FUItemTypeClothes],mItems[FUItemTypeStandbyAnimation]};
    [FURenderer bindItems:mItems[FUItemTypeController] items:bindItems itemsCount:sizeof(bindItems)/sizeof(int)];
}

// AR 滤镜 item
- (void)loadARFilter:(NSString *)filterName {
    dispatch_semaphore_wait(arSignal, DISPATCH_TIME_FOREVER);
    int destoryItem = mItems[FUItemTypeARFilter];

    if (filterName != nil && ![filterName isEqual:@"noitem"]) {
        /**先创建道具句柄*/
        NSString *path = [[NSBundle mainBundle] pathForResource:filterName ofType:@"bundle"];
        mItems[FUItemTypeARFilter] = [FURenderer itemWithContentsOfFile:path];
    }else{
        /**为避免道具句柄被销毁会后仍被使用导致程序出错，这里需要将存放道具句柄的items[1]设为0*/
        mItems[FUItemTypeARFilter] = 0;
    }

    if (destoryItem != 0)   {
        [FURenderer destroyItem:destoryItem];
    }
    
    arItems[1] = mItems[FUItemTypeARFilter] ;
    dispatch_semaphore_signal(arSignal);
}
// AR 滤镜 mode
- (void)loadARModel:(FUAvatar *)avatar {
    
    dispatch_semaphore_wait(arSignal, DISPATCH_TIME_FOREVER);

    if (avatar == nil) {
        // 头，头发，眼镜, 帽子
        [self loadItemWithtype:FUItemTypeAvatar filePath:nil];
        [self loadItemWithtype:FUItemTypeHair filePath:nil];
        if (mItems[FUItemTypeGlasses] != 0) {
            [self loadItemWithtype:FUItemTypeGlasses filePath:nil];
        }
        if (mItems[FUItemTypeHat] != 0) {
            [self loadItemWithtype:FUItemTypeHat filePath:nil];
        }
        dispatch_semaphore_signal(arSignal);
        return ;
    }
    
    // load head/hair/gless/beard/hat
    [self loadItemWithtype:FUItemTypeAvatar filePath:avatar.bundlePath];
    
    NSString *hairPath = nil ;
    if (avatar.defaultHair) {
        NSString *hairName = avatar.defaultHair ;
        if (avatar.time) {
            hairPath = [[[avatar avatarPath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
        }else {
            hairPath = [[[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:avatar.bundleName] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
        }
    }
    [self loadItemWithtype:FUItemTypeHair filePath:hairPath];
    
    NSString *glessPath ;
    if (avatar.defaultGlasses == nil || [avatar.defaultGlasses isEqualToString:@"glasses-noitem"]) {
        glessPath = nil ;
    }else {
        glessPath = [[NSBundle mainBundle] pathForResource:avatar.defaultGlasses ofType:@"bundle"];
    }
    [self loadItemWithtype:FUItemTypeGlasses filePath:glessPath];
    
    NSString *beardPath = nil ;
    if (avatar.defaultBeard == nil || [avatar.defaultBeard isEqualToString:@"beard-noitem"]) {
        beardPath = nil ;
    }else {
        beardPath = [[NSBundle mainBundle] pathForResource:avatar.defaultBeard ofType:@"bundle"];
    }
    [self loadItemWithtype:FUItemTypeBeard filePath:beardPath];
    
    NSString *hatPath = nil ;
    if (avatar.defaultHat == nil || [avatar.defaultHat isEqualToString:@"hat-noitem"]) {
        hatPath = nil ;
    }else {
        hatPath = [[NSBundle mainBundle] pathForResource:avatar.defaultHat ofType:@"bundle"];
    }
    [self loadItemWithtype:FUItemTypeHat filePath:hatPath];
    
    // load skin color / lip color / hair color
    [self setDefaultColorForAvatar:avatar];
    
    arItems[0] = mItems[FUItemTypeController];
    
    dispatch_semaphore_signal(arSignal);
}

// AR滤镜 处理接口
static int ARFilterID = 0 ;
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer {
    
    dispatch_semaphore_wait(arSignal, DISPATCH_TIME_FOREVER);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
    int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
    void *bytes = CVPixelBufferGetBaseAddress(pixelBuffer) ;
    
    [[FURenderer shareRenderer] renderItems:bytes inFormat:FU_FORMAT_BGRA_BUFFER outPtr:bytes outFormat:FU_FORMAT_BGRA_BUFFER width:stride/4 height:height frameId:ARFilterID items:arItems itemCount:2 flipx:NO];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    ARFilterID ++ ;
    
    dispatch_semaphore_signal(arSignal);
    
    return pixelBuffer ;
}

// 进入/退出 捏脸模式
- (void)enterFacepupMode {
    fuItemSetParamd(mItems[FUItemTypeController], "enter_facepup_mode", 1) ;
}
- (void)quitFacepupMode {
    fuItemSetParamd(mItems[FUItemTypeController], "quit_facepup_mode", 1) ;
}

- (int)getSkinColorIndex {
    double currentColor = fuItemGetParamd(mItems[FUItemTypeController], "skin_color_index");
    return (int)currentColor;
}

// lip color index
- (int)getLipColorIndex {
    double currentColor = fuItemGetParamd(mItems[FUItemTypeController], "lip_color_index");
    return (int)currentColor;
}

// iris color index
- (int)getIrisColorIndex {
    return 0 ;
}

// set skin color
- (void)facepopSetSkinColor:(double*)color {
    fuItemSetParamdv(mItems[FUItemTypeController], "skin_color", color, 3) ;
}

// set lip color
- (void)facepopSetLipColor:(double*)color{
    fuItemSetParamdv(mItems[FUItemTypeController], "lip_color", color, 3) ;
}
// set iris color
- (void)facepopSetIrisColor:(double*)color {
    fuItemSetParamdv(mItems[FUItemTypeController], "iris_color", color, 3) ;
}
// set hair color
- (void)facepopSetHairColor:(double*)color intensity:(double)intensity {
    fuItemSetParamdv(mItems[FUItemTypeController], "hair_color", color, 3) ;
    fuItemSetParamd(mItems[FUItemTypeController], "hair_color_intensity", intensity) ;
}
// set galsses color
- (void)facepopSetGlassesColor:(double*)color {
    fuItemSetParamdv(mItems[FUItemTypeController], "glass_color", color, 3) ;
}
// set glasses frame color
- (void)facepopSetGlassesFrameColor:(double*)color {
    fuItemSetParamdv(mItems[FUItemTypeController], "glass_frame_color", color, 3) ;
}
// set beard color
- (void)facepopSetBeardColor:(double*)color {
    fuItemSetParamdv(mItems[FUItemTypeController], "beard_color", color, 3) ;
}
// set hat color
- (void)facepopSetHatColor:(double*)color {
    fuItemSetParamdv(mItems[FUItemTypeController], "hat_color", color, 3) ;
}

// face shape params
- (void)facepopSetShapParam:(NSString *)key level:(double)level {
    key  = [NSString stringWithFormat:@"{\"name\":\"facepup\",\"param\":\"%@\"}", key];
    fuItemSetParamd(mItems[FUItemTypeController], [key UTF8String], level) ;
}

- (double)getFacepopParamWith:(NSString *)key {
    NSString * realKey  = [NSString stringWithFormat:@"{\"name\":\"facepup\",\"param\":\"%@\"}", key];
    double level = fuItemGetParamd(mItems[FUItemTypeController], [realKey UTF8String]) ;
    return level ;
}

// 生成新的
- (BOOL)createPupAvatarWithCoeffi:(float *)coeffi colorIndex:(float)color DeformHead:(BOOL)deform {
    
    NSString *bundlePath = self.currentAvatar.bundlePath ;
    NSData *bundleData = [NSData dataWithContentsOfFile:bundlePath];
    
    if (deform) {
        bundleData = [FUP2AClient deformAvatarHeadWithHeadData:bundleData deformParams:coeffi paramsSize:36];
    }
    
    NSString *fileName ;
    if (self.currentAvatar.time) {// 非预置模型
        fileName = self.currentAvatar.time;
    }else {             // 预置模型
        NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
        fileName = [NSString stringWithFormat:@"%.0f", time];
    }
    // 文件夹
    NSFileManager *fileManager = [NSFileManager defaultManager] ;
    NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
    
    if (![fileManager fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // Avatar
    FUAvatar *avatar = [[FUAvatar alloc] init];
    avatar.time = fileName;
    avatar.isMale = self.currentAvatar.isMale ;
    
    // 图片 icon
    UIImage *image = [UIImage imageWithContentsOfFile:self.currentAvatar.imagePath];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0) ;
    [imageData writeToFile:avatar.imagePath atomically:YES];
    
    // 头
    [bundleData writeToFile:avatar.bundlePath atomically:YES];
    // 头发
    NSArray *hairs = self.currentAvatar.hairArr ;
    if (hairs == nil || hairs.count == 0) {
        hairs = self.currentAvatar.isMale ? self.maleHairs : self.femaleHairs ;
    }
    NSString *hairPath ;
    if (!self.currentAvatar.time) { // 预置模型
        hairPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:self.currentAvatar.bundleName];
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
    
    avatar.hairArr = hairs ;
    
    self.currentAvatar = avatar ;
    
    return YES ;
}

// set current avatar default color
- (void)setDefaultColorForAvatar:(FUAvatar *)avatar {
    
    double c[3] ;
    if (avatar.skinColor) {
        c[0] = avatar.skinColor.r ;
        c[1] = avatar.skinColor.g ;
        c[2] = avatar.skinColor.b ;
        [self facepopSetSkinColor:c];
    }
    
    if (avatar.lipColor) {
        c[0] = avatar.lipColor.r ;
        c[1] = avatar.lipColor.g ;
        c[2] = avatar.lipColor.b ;
        
        [self facepopSetLipColor:c];
    }
    
    if (avatar.irisColor) {
        double c[3] = {
            avatar.irisColor.r,
            avatar.irisColor.g,
            avatar.irisColor.b,
        };
        [self facepopSetIrisColor:c];
    }
    if (avatar.defaultHair != nil && ![avatar.defaultHair isEqualToString:@"hair-noitem"]) {
        if (avatar.hairColor) {
            c[0] = avatar.hairColor.r ;
            c[1] = avatar.hairColor.g ;
            c[2] = avatar.hairColor.b ;
        }else {
            FUFigureColor *color = self.hairColorArray[0] ;
            c[0] = color.r ;
            c[1] = color.g ;
            c[2] = color.b ;
        }
        [self facepopSetHairColor:c intensity:avatar.hairColor.intensity];
    }
    if (avatar.defaultGlasses != nil && ![avatar.defaultGlasses isEqualToString:@"glasses-noitem"]) {
         if (avatar.glassFrameColor) {
            c[0] = avatar.glassFrameColor.r ;
            c[1] = avatar.glassFrameColor.g ;
            c[2] = avatar.glassFrameColor.b ;
        }else {
            FUFigureColor *color = self.glassFrameArray[0] ;
            c[0] = color.r ;
            c[1] = color.g ;
            c[2] = color.b ;
        }
        [self facepopSetGlassesFrameColor:c];
        if (avatar.glassColor) {
            c[0] = avatar.glassColor.r ;
            c[1] = avatar.glassColor.g ;
            c[2] = avatar.glassColor.b ;
        }else {
            FUFigureColor *color = self.glassColorArray[0] ;
            c[0] = color.r ;
            c[1] = color.g ;
            c[2] = color.b ;
        }
        [self facepopSetGlassesColor:c];
    }
    if (avatar.defaultBeard != nil && ![avatar.defaultBeard isEqualToString:@"berad-noitem"]) {
       if (avatar.beardColor) {
            c[0] = avatar.beardColor.r ;
            c[1] = avatar.beardColor.g ;
            c[2] = avatar.beardColor.b ;
        }else {
            FUFigureColor *color = self.beardColorArray[0] ;
            c[0] = color.r ;
            c[1] = color.g ;
            c[2] = color.b ;
        }
        [self facepopSetBeardColor:c];
    }
    if (avatar.defaultHat != nil && ![avatar.defaultHat isEqualToString:@"hat-noitem"]) {
        if (avatar.hatColor) {
            c[0] = avatar.hatColor.r ;
            c[1] = avatar.hatColor.g ;
            c[2] = avatar.hatColor.b ;
        }else {
            FUFigureColor *color = self.hatColorArray[0] ;
            c[0] = color.r ;
            c[1] = color.g ;
            c[2] = color.b ;
        }
        [self facepopSetHatColor:c];
    }
}

- (void)maxFace:(int)num {
    [FURenderer setMaxFaces:num];
}

// 获取人脸框
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

// 获取默认头发
- (NSString *)gethairNameWithNum:(int)num isMale:(BOOL)male{
    NSString *hairName ;
    
    if (num < 7) {
        hairName = [NSString stringWithFormat:@"male_hair_%d", num];
    }else if (num == 7 ||
              (num >= 10 && num < 14) ||
              (num > 14 && num < 17) ||
              (num > 20 && num < 24) ){
        hairName = [NSString stringWithFormat:@"female_hair_%d", num];
    }else if (num == 8){
        hairName = @"female_hair_7";
    }else if (num == 9){
        hairName = @"female_hair_16";
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
    }
    
    return hairName ;
}

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

- (FUFigureColor *)getColorWithColorInfo:(NSArray *)colorInfo colorList:(NSArray *)list {
    
    float r = [colorInfo[0] floatValue];
    float g = [colorInfo[1] floatValue];
    float b = [colorInfo[2] floatValue];
    
    NSInteger index = 0 ;
    double min_distance = 1000.0 ;
    
    for (FUFigureColor *des_color in list) {
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

@end
