//
//  FUManager.m
//  P2A
//
//  Created by L on 2018/12/17.
//  Copyright © 2018年 L. All rights reserved.
//




@interface FUManager ()
{
       
}


@end

@implementation FUManager
#pragma mark ----- LifeCycle
static FUManager *fuManager = nil;
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fuManager = [[FUManager alloc] init];
    });
    return fuManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self initFaceUnity];
        [self initLibrary];
        // 生成空buffer
        [self initPixelBuffer];
        
        [self initProperty];
        [self initDefaultItem];
        
        self.rotatedImageManager = [[FURotatedImage alloc]init];
        
        [self initFaceCapture];
        [self initHuman3D];
        // 关闭nama的打印
        [FURenderer itemSetParam:self.defalutQController withName:@"FUAI_VLogSetLevel" value:@(0)];
        // 绑定全局的 human3d.bundle

        // 美妆类型数组
		self.makeupTypeArray = @[TAG_FU_ITEM_EYELASH,TAG_FU_ITEM_EYELINER,TAG_FU_ITEM_EYESHADOW,TAG_FU_ITEM_EYEBROW,
		TAG_FU_ITEM_PUPIL,TAG_FU_ITEM_LIPGLOSS,TAG_FU_ITEM_FACEMAKEUP];
        // 配饰类型数组
		self.decorationTypeArray = @[TAG_FU_ITEM_DECORATION_SHOU,TAG_FU_ITEM_DECORATION_JIAO,TAG_FU_ITEM_DECORATION_XIANGLIAN,
		TAG_FU_ITEM_DECORATION_ERHUAN,TAG_FU_ITEM_DECORATION_TOUSHI];
		// 设置相机动画过渡时间
		[self SetCameraTransitionTime:0];
		
    }
    return self;
}



- (void)enableHuman3D:(int)enable
{
    fuItemSetParamd(self.defalutQController, "enable_human_processor", enable);
}

- (void)destoryHuman3D
{
    fuReleaseAIModel(FUAITYPE_HUMAN_PROCESSOR);
}
/// 设置相机切换动画过渡时间
/// @param duration 间隔
-(void)SetCameraTransitionTime:(float)duration{
	[FURenderer itemSetParam:self.defalutQController withName:@"camera_animation_transition_time" value:@(duration)];
}

#pragma mark ----- 初始化 ------
- (void)initProperty
{
    self.currentAvatars = [NSMutableArray arrayWithCapacity:1];
    frameSize = CGSizeZero;
    self.signal = dispatch_semaphore_create(1);
    isCreatingAvatar = NO;

}

- (void)initLibrary
{
    // 设置鉴权
    [[FUP2AHelper shareInstance] setupHelperWithAuthPackage:&g_auth_package authSize:sizeof(g_auth_package)];

    [FUP2AHelper shareInstance].saveVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fup2a_video.mp4"];
    [[FUP2AHelper shareInstance] startRecordWithType:FUP2AHelperRecordTypeVoicedVideo];
}

//初始化FaceUnity
- (void)initFaceUnity
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"v3.bundle" ofType:nil];
    int ret =  [[FURenderer shareRenderer] setupWithDataPath:path authPackage:&g_auth_package authSize:sizeof(g_auth_package) shouldCreateContext:YES];
        [FURenderer setMaxFaces:1];
}

//加载默认数据
- (void)initDefaultItem
{
    // 加载抗锯齿
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"fxaa" ofType:@"bundle"];
    mItems[0] = [FURenderer itemWithContentsOfFile:filePath];
    
    // 加载舌头
    NSData *tongueData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"tongue.bundle" ofType:nil]];
    [FURenderer loadTongueModel:(void *)tongueData.bytes size:(int)tongueData.length];
    
    //加载controller
    NSString *controllerPath = [[NSBundle mainBundle] pathForResource:@"controller_cpp" ofType:@"bundle"];
    self.defalutQController = [FURenderer itemWithContentsOfFile:controllerPath];
    
    //加载controller_config
    NSString *controller_config_path = [[NSBundle mainBundle] pathForResource:@"controller_config" ofType:@"bundle"];
    [self rebindItemToControllerWithFilepath:controller_config_path withPtr:&q_controller_config_ptr];
    
    NSString *lighting_Path = [[NSBundle mainBundle] pathForResource:@"light" ofType:@"bundle"];
    [self rebindItemToControllerWithFilepath:lighting_Path withPtr:&light_ptr];
}

//初始化P2AClient库
- (void)loadClientDataWithFirstSetup:(BOOL)firstSetup
{
    NSString *qPath;
    switch (self.avatarStyle)
    {
        case FUAvatarStyleNormal:
        {
            if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarListPath])
            {
                [[NSFileManager defaultManager] createDirectoryAtPath:AvatarListPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            qPath =[[NSBundle mainBundle] pathForResource:@"p2a_client_q" ofType:@"bin"];
        }
            break;
        case FUAvatarStyleQ:
        {
            if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarQPath])
            {
                [[NSFileManager defaultManager] createDirectoryAtPath:AvatarQPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            qPath =[[NSBundle mainBundle] pathForResource:@"p2a_client_q1" ofType:@"bin"];
        }
            break;
    }
    // p2a bin
    if (firstSetup)
    {
        NSString *corePath = [[NSBundle mainBundle] pathForResource:@"p2a_client_core" ofType:@"bin"];
        [[fuPTAClient shareInstance] setupCore:corePath authPackage:&g_auth_package authSize:sizeof(g_auth_package)];
    }
    [[fuPTAClient shareInstance] setupCustomData:qPath];
}

#pragma mark ------ 图像 ------
/// 复制CVPixelBufferRef，需要外部调用负责释放返回值
/// @param pixelBuffer 输入的 CVPixelBufferRef
- (CVPixelBufferRef)copyPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // Copy the pixel buffer
    CVPixelBufferRef pixelBufferCopy = [self createEmptyPixelBuffer:CGSizeMake(bufferWidth, bufferHeight)];
    //CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, kCVPixelFormatType_32BGRA, NULL, &pixelBufferCopy);
    CVPixelBufferLockBaseAddress(pixelBufferCopy, 0);
    uint8_t *copyBaseAddress = CVPixelBufferGetBaseAddress(pixelBufferCopy);
    memcpy(copyBaseAddress, baseAddress, bufferHeight * bytesPerRow);
    CVPixelBufferUnlockBaseAddress(pixelBufferCopy, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return pixelBufferCopy;
}

/// 初始化空白buffer
- (void)initPixelBuffer
{
    if (!renderTarget)
    {
	   CGSize size = [UIScreen mainScreen].currentMode.size;
		//CGSize size = CGSizeMake(720, 1280);
        renderTarget=[self createEmptyPixelBuffer:size];
    }
    if (!screenShotTarget)
    {
        screenShotTarget=[self createEmptyPixelBuffer:CGSizeMake(460, 630)];
    }
}

/// 创建空白buffer
/// @param size buffer的大小
- (CVPixelBufferRef)createEmptyPixelBuffer:(CGSize)size
{
    CVPixelBufferRef ret;
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
                        &ret);
    return ret;
}

/**
 检测人脸接口
 
 @param sampleBuffer  图像数据
 @return              图像数据
 */
- (CVPixelBufferRef)trackFaceWithBuffer:(CMSampleBufferRef)sampleBuffer CurrentlLightingValue:(float *)currntLightingValue
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    
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
    dispatch_semaphore_signal(self.signal);
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
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks LandmarksLength:(int)landmarksLength
{
	dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
	
    int renderTarget_h = (int)CVPixelBufferGetHeight(renderTarget);
    int renderTarget_stride = (int)CVPixelBufferGetBytesPerRow(renderTarget);
    int renderTarget_w = renderTarget_stride/4;
//	 int w = 750;/
    CVPixelBufferLockBaseAddress(renderTarget, 0);
    void* renderTarget_pod = (void *)CVPixelBufferGetBaseAddress(renderTarget);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* pixelBuffer_pod = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
	
    int pixelBuffer_h = (int)CVPixelBufferGetHeight(pixelBuffer);
    int pixelBuffer_stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    int pixelBuffer_w = pixelBuffer_stride/4;
	if (renderMode == FURenderPreviewMode)
	{
		[[FURenderer shareRenderer] renderBundles:pixelBuffer_pod inFormat:FU_FORMAT_BGRA_BUFFER outPtr:renderTarget_pod outFormat:FU_FORMAT_BGRA_BUFFER width:pixelBuffer_w height:pixelBuffer_h frameId:frameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
	}else
	{
		
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
		info.is_valid = is_valid;
		
		[[FURenderer shareRenderer] renderBundles:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:renderTarget_pod outFormat:FU_FORMAT_BGRA_BUFFER width:renderTarget_w height:renderTarget_h frameId:frameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
	}
	
	[FURenderer getFaceInfo:0 name:@"landmarks" pret:landmarks number:landmarksLength];
	[self rotateImage:renderTarget_pod inFormat:FU_FORMAT_BGRA_BUFFER w:renderTarget_w h:renderTarget_h rotationMode:FU_ROTATION_MODE_0 flipX:NO flipY:YES];
	memcpy(renderTarget_pod, self.rotatedImageManager.mData, renderTarget_w*renderTarget_h*4);
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	CVPixelBufferUnlockBaseAddress(renderTarget, 0);
	
	dispatch_semaphore_signal(self.signal);
	
	return renderTarget;
}

/**
 Avatar 处理接口
 
 @param pixelBuffer 图像数据
 @param rate  缩放比例
 
 @return            处理之后的图像
 */
- (CVPixelBufferRef)renderP2AItemWithPixelBuffer:(CVPixelBufferRef)pixelBuffer HightResolution:(float)rate
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int h = (int)CVPixelBufferGetHeight(pixelBuffer) * rate;
    int w = (int)CVPixelBufferGetWidth(pixelBuffer) * rate;
    CVPixelBufferRef rendered_pixel = [self createEmptyPixelBuffer:CGSizeMake(w, h)];
    CVPixelBufferLockBaseAddress(rendered_pixel, 0);
    void* rendered_pixel_pod = (void *)CVPixelBufferGetBaseAddress(rendered_pixel);
    
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
    info.is_valid = is_valid;
  
    [[FURenderer shareRenderer] renderBundles:&info inFormat:FU_FORMAT_AVATAR_INFO outPtr:rendered_pixel_pod outFormat:FU_FORMAT_BGRA_BUFFER width:w height:h frameId:frameId++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
    [self rotateImage:rendered_pixel_pod inFormat:FU_FORMAT_BGRA_BUFFER w:w h:h rotationMode:FU_ROTATION_MODE_0 flipX:NO flipY:YES];
    memcpy(rendered_pixel_pod, self.rotatedImageManager.mData, w*h*4);
    CVPixelBufferUnlockBaseAddress(rendered_pixel, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    dispatch_semaphore_signal(self.signal);
    return rendered_pixel ;
}

static int ARFilterID = 0 ;
/**
 AR 滤镜处理接口
 
 @param pixelBuffer 图像数据
 @return            处理之后的图像数据
 @param rotationMode 旋转模式
 @param rotation_mode w.r.t to rotation the the camera view, 0=0^deg, 1=90^deg, 2=180^deg, 3=270^deg
 */
- (CVPixelBufferRef)renderARFilterItemWithBuffer:(CVPixelBufferRef)pixelBuffer rotationMode:(int)rotationMode
{
//    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
//
//    int h = (int)CVPixelBufferGetHeight(pixelBuffer);
//    int w = (int)CVPixelBufferGetWidth(pixelBuffer);
//    CVPixelBufferRef mirrored_pixel = NULL;
//    NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
//                                              @(kCVPixelFormatType_32BGRA),
//                                          (NSString*) kCVPixelBufferWidthKey : @(w),
//                                          (NSString*) kCVPixelBufferHeightKey : @(h),
//                                          (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
//                                          (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
//    CVPixelBufferCreate(kCFAllocatorDefault,
//                        w, h,
//                        kCVPixelFormatType_32BGRA,
//                        (__bridge CFDictionaryRef)pixelBufferOptions,
//                        &mirrored_pixel);
//
//    CVPixelBufferLockBaseAddress(mirrored_pixel, 0);
//    void* pod1 = (void *)CVPixelBufferGetBaseAddress(mirrored_pixel);
//
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//    void* pod0 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
//    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
//    int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
//    void *bytes = CVPixelBufferGetBaseAddress(pixelBuffer) ;
//    void *newbytes = NULL;
//    // int fu3DBodyTrackerRun(void* model_ptr, int human_handle, void* img, int w, int h, int fu_image_format, int rotation_mode);
//    int width = (int)CVPixelBufferGetWidth(pixelBuffer) ;
//
//    [[FURenderer shareRenderer] renderBundles:bytes inFormat:FU_FORMAT_BGRA_BUFFER outPtr:pod1 outFormat:FU_FORMAT_BGRA_BUFFER width:stride/4 height:height frameId:ARFilterID ++ items:arItems itemCount:2];
//    //    fuRenderBundles(FU_FORMAT_BGRA_BUFFER,bytes,FU_FORMAT_BGRA_BUFFER,bytes,width,height,ARFilterID++,arItems,2);
//
//
//
//    // flip y because nama direct get data from opengl
//
//
//    for (int i = 0; i < height; i++)
//    {
//        memcpy((uint8_t*)pod0 + stride * (height-i-1),(uint8_t*)pod1 + stride * i, stride);
//    }
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//    CVPixelBufferUnlockBaseAddress(mirrored_pixel, 0);
//    CVPixelBufferRelease(mirrored_pixel);
//
//
//    dispatch_semaphore_signal(self.signal);
//
//    return pixelBuffer;
    
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);

    int h = (int)CVPixelBufferGetHeight(pixelBuffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    int w = stride/4;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* pod0 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
    [[FURenderer shareRenderer] renderBundles:pod0 inFormat:FU_FORMAT_BGRA_BUFFER outPtr:pod0 outFormat:FU_FORMAT_BGRA_BUFFER width:w height:h frameId:ARFilterID++ items:arItems itemCount:2];

    [self rotateImage:pod0 inFormat:FU_FORMAT_BGRA_BUFFER w:w h:h rotationMode:FU_ROTATION_MODE_0 flipX:NO flipY:YES];
    memcpy(pod0, self.rotatedImageManager.mData, w*h*4);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    dispatch_semaphore_signal(self.signal);

    return pixelBuffer;
}

/// 捕获人脸接口
/// @param pixelBuffer 输入源
/// @param rotationMode 旋转模式
//@param rotation_mode w.r.t to rotation the the camera view, 0=0^deg, 1=90^deg, 2=180^deg, 3=270^deg
- (void)trackFace:(CVPixelBufferRef)pixelBuffer rotationMode:(int)rotationMode
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0) ;
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) ;
    int height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
//    if(YES == self.useFaceCapure){
//        [self runFaceCapture:baseAddress imageFormat:FU_FORMAT_BGRA_BUFFER width:stride/4 height:height rotateMode:rotationMode];
//    } else {
        [FURenderer trackFaceWithTongue:FU_FORMAT_BGRA_BUFFER inputData:baseAddress width:stride/4 height:height];
//    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0) ;
}


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
- (CVPixelBufferRef)renderBodyTrackAdjustAssginOutputSizeWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks LandmarksLength:(int)landmarksLength
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    
    int h = (int)CVPixelBufferGetHeight(pixelBuffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    int w = stride/4;

    if (!bodyTrackBuffer)
    {
        bodyTrackBuffer = [self createEmptyPixelBuffer:CGSizeMake(self.outPutSize.width, self.outPutSize.height)];
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* pod1 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
    CVPixelBufferLockBaseAddress(bodyTrackBuffer, 0);
    void* pod0 = (void *)CVPixelBufferGetBaseAddress(bodyTrackBuffer);

    [[FURenderer shareRenderer] renderBundles:pod1 inFormat:FU_FORMAT_BGRA_BUFFER outPtr:pod0 outFormat:FU_FORMAT_BGRA_BUFFER width:w height:h frameId:frameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
    [FURenderer getFaceInfo:0 name:@"landmarks" pret:landmarks number:landmarksLength];

    [self rotateImage:pod0 inFormat:FU_FORMAT_BGRA_BUFFER w:self.outPutSize.width h:self.outPutSize.height rotationMode:FU_ROTATION_MODE_0 flipX:NO flipY:YES];
    memcpy(pod0, self.rotatedImageManager.mData, self.outPutSize.width*self.outPutSize.height*4);

    CVPixelBufferUnlockBaseAddress(bodyTrackBuffer, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    dispatch_semaphore_signal(self.signal);

    return bodyTrackBuffer;
}
 
- (CVPixelBufferRef)renderBodyTrackWithBuffer:(CVPixelBufferRef)pixelBuffer ptr:(void *)human3dPtr RenderMode:(FURenderMode)renderMode Landmarks:(float *)landmarks LandmarksLength:(int)landmarksLength
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
     
    int h = (int)CVPixelBufferGetHeight(pixelBuffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    int w = stride/4;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* pod0 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    [[FURenderer shareRenderer] renderBundles:pod0 inFormat:FU_FORMAT_BGRA_BUFFER outPtr:pod0 outFormat:FU_FORMAT_BGRA_BUFFER width:w height:h frameId:frameId ++ items:mItems itemCount:sizeof(mItems)/sizeof(int)];
    
    [self rotateImage:pod0 inFormat:FU_FORMAT_BGRA_BUFFER w:w h:h rotationMode:FU_ROTATION_MODE_0 flipX:NO flipY:YES];
    memcpy(pod0, self.rotatedImageManager.mData, w*h*4);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    dispatch_semaphore_signal(self.signal);
    
    return pixelBuffer;

}

-(CVPixelBufferRef)dealTheFrontCameraPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
    return [self dealTheFrontCameraPixelBuffer:pixelBuffer returnNewBuffer:YES];
}

-(CVPixelBufferRef)dealTheFrontCameraPixelBuffer:(CVPixelBufferRef) pixelBuffer returnNewBuffer:(BOOL)returnNewBuffer
{
    return [self rotateImage:pixelBuffer rotationMode:FU_ROTATION_MODE_0 flipX:YES flipY:NO returnNewBuffer:returnNewBuffer];
}

-(void)rotateImage:(void*)inPtr inFormat:(int)inFormat w:(int)w h:(int)h rotationMode:(int)rotationMode flipX:(BOOL)flipX flipY:(BOOL)flipY
{
    [[FURenderer shareRenderer] rotateImage:self.rotatedImageManager inPtr:inPtr inFormat:FU_FORMAT_BGRA_BUFFER width:w height:h rotationMode:rotationMode flipX:flipX flipY:flipY];
}

-(CVPixelBufferRef)rotateImage:(CVPixelBufferRef) pixelBuffer rotationMode:(int)rotationMode flipX:(BOOL)flipX flipY:(BOOL)flipY returnNewBuffer:(BOOL)returnNewBuffer
{
    int h = (int)CVPixelBufferGetHeight(pixelBuffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    int w = stride/4;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* pod0 = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
    [self rotateImage:pod0 inFormat:FU_FORMAT_BGRA_BUFFER w:w h:h rotationMode:rotationMode flipX:flipX flipY:flipY];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    CVPixelBufferRef ret;
    if(returnNewBuffer){
        ret=[self createEmptyPixelBuffer:CGSizeMake((int)CVPixelBufferGetWidth(pixelBuffer), h)];
    } else {
        ret=pixelBuffer;
    }
    CVPixelBufferLockBaseAddress(ret, 0);
    void* pod1 = (void *)CVPixelBufferGetBaseAddress(ret);
    memcpy(pod1, self.rotatedImageManager.mData, w*h*4);
    CVPixelBufferUnlockBaseAddress(ret, 0);
    return ret;
}

#pragma mark ----- 脸部识别
/// 初始化脸部识别
- (void)initFaceCapture
{
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ai_face_processor.bundle" ofType:nil]];
//    fuLoadAIModelFromPackage((void *)data.bytes , (int) data.length, FUAITYPE_FACEPROCESSOR);
    [FURenderer loadAIModelFromPackage:(void *)data.bytes size:(int) data.length aitype:FUAITYPE_FACEPROCESSOR];
}

- (void)initHuman3D
{
    NSData *human3dData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ai_human_processor.bundle" ofType:nil]];
    [FURenderer loadAIModelFromPackage:(void *)human3dData.bytes size:(int)human3dData.length aitype:FUAITYPE_HUMAN_PROCESSOR];
}
- (void)destroyFaceCapture
{
    fuReleaseAIModel(FUAITYPE_FACEPROCESSOR);
}

- (void)enableFaceCapture:(int)enable
{
   fuItemSetParamd(self.defalutQController, "enable_face_processor", enable);
}

#pragma mark ------ 加载道具 ------
/// 加载道具等信息
- (void)loadSubData
{
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:AvatarQPath])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:AvatarQPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	[self loadQtypeAvatarData];
	
}

/// 加载Q版道具数据
- (void)loadQtypeAvatarData
{
	self.typeInfoDict = [[NSMutableDictionary alloc]init];
	
	NSMutableArray *typeInfoArray = [NSMutableArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FUQItems.plist" ofType:nil]];
	
	
	self.itemNameArray = [[NSMutableArray alloc]init];
	self.itemTypeArray = [[NSMutableArray alloc]init];
	self.itemsDict = [[NSMutableDictionary alloc]initWithCapacity:1];
	
	
	for (int i = 0; i < typeInfoArray.count; i++)
	{
		FUEditTypeModel *model = [[FUEditTypeModel alloc]init];
		
		[model setValuesForKeysWithDictionary:typeInfoArray[i]];
		[self.typeInfoDict setValue:model forKey:model.type];
		if ([model.type isEqualToString:@"makeup"]){ // 如果是美妆类型
			NSString *configPath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"Resource/QItems/makeup/config.json"];
			
			
			NSData *tmpData = [[NSString stringWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
			
			NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
			NSArray *itemList = dic[@"list"];
			NSMutableArray *itemArray = [[NSMutableArray alloc]init];
			for (int m = 0; m < itemList.count; m++)
			{
				NSDictionary *item = itemList[m];
				
				if (itemArray.count > 0 && [item[@"icon"] isEqualToString:@"none"])
				{
					continue;
				}
				
				FUMakeupItemModel *itemModel = [[FUMakeupItemModel alloc]init];
				
				itemModel.path = [NSString stringWithFormat:@"QItems/%@",model.type];
				
				[item enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
					[itemModel setValue:obj forKey:key];
				}];
				
				[itemArray addObject:itemModel];
			}
			[self.itemsDict setObject:itemArray forKey:model.type];
		}else{
			for (int j = 0; j < model.subTypeArray.count; j++)
			{
				NSMutableArray *itemArray = [[NSMutableArray alloc]init];
				
				NSDictionary *dictItem = model.subTypeArray[j];
				NSString *type = dictItem[@"type"];
				NSArray *paths = dictItem[@"path"];
				
				if (paths.count == 0)
				{
					continue;
				}
				if ([type isEqualToString:FUDecorationsString]){  // 配饰类不再被使用，代替的是 配饰 大类，含有多种类型的配饰
					for (int n = 0; n < paths.count; n++)
					{
						NSString *path = paths[n];
						NSString *configPath = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/%@/config.json",path];
						
						NSData *tmpData = [[NSString stringWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
						
						NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
						NSArray *itemList = dic[@"list"];
						for (int m = 0; m < itemList.count; m++)
						{
							NSDictionary *item = itemList[m];
							
							if (itemArray.count > 0 && [item[@"icon"] isEqualToString:@"none"])
							{
								continue;
							}
							
							FUDecorationItemModel *itemModel = [[FUDecorationItemModel alloc]init];
							itemModel.path = path;
							[item enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
								[itemModel setValue:obj forKey:key];
							}];
							
							[itemArray addObject:itemModel];
						}
					}
				}else{
				[self.itemTypeArray addObject:type];
					[self.itemNameArray addObject:dictItem[@"name"]];
					
					for (int n = 0; n < paths.count; n++)
					{
						NSString *path = paths[n];
						NSString *configPath = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/%@/config.json",path];
						
						NSData *tmpData = [[NSString stringWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
						
						NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
						NSArray *itemList = dic[@"list"];
						for (int m = 0; m < itemList.count; m++)
						{
							NSDictionary *item = itemList[m];
							
							if (itemArray.count > 0 && [item[@"icon"] isEqualToString:@"none"])
							{
								continue;
							}
							
							FUItemModel *itemModel = [[FUItemModel alloc]init];
							itemModel.type = type;
							itemModel.path = path;
							
							[item enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
								[itemModel setValue:obj forKey:key];
							}];
							
							[itemArray addObject:itemModel];
						}
					}
				}
				[self.itemsDict setObject:itemArray forKey:type];
			}
		}
	}
	
	[self loadColorList];
	[self loadMeshPoints];
	[self loadShapeList];
	
	[self loadAvatarList];
}

/// 加载捏脸点位信息
- (void)loadMeshPoints
{
    // mesh points
    NSData *meshData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MeshPoints" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *meshDict = [NSJSONSerialization JSONObjectWithData:meshData options:NSJSONReadingMutableContainers error:nil];

    self.qMeshPoints = meshDict[@"mid"] ;
}

/// 加载颜色列表
- (void)loadColorList
{
    // color data
    NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"color_q" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *colorDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    self.colorDict = [[NSMutableDictionary alloc]init];
    
    __block NSMutableDictionary *newColorDict = [[NSMutableDictionary alloc]init];
    
    [colorDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        NSMutableArray *newTypeColorArray = [[NSMutableArray alloc]init];
        NSMutableDictionary *enumTypeColorDict = (NSMutableDictionary *)obj;

        for (int i = 0 ; i < enumTypeColorDict.allKeys.count; i++)
        {
            NSString *indexKey = [NSString stringWithFormat:@"%d",i+1];
            FUP2AColor *color = [FUP2AColor colorWithDict:[enumTypeColorDict valueForKey:indexKey]];
            
            [newTypeColorArray addObject:color];
        }
        
        [newColorDict setValue:newTypeColorArray forKey:key];
    }];
    
    self.colorDict = newColorDict;
}

/// 加载脸型列表
- (void)loadShapeList
{
    // shape data
    NSData *shapeJson = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"shape_list" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *shapeDict = [NSJSONSerialization JSONObjectWithData:shapeJson options:NSJSONReadingMutableContainers error:nil];
    
    
    for (int i = 0; i < shapeDict.allKeys.count; i++)
    {
        NSString *key = shapeDict.allKeys[i];
        NSArray *array = [shapeDict objectForKey:key];
        
        NSMutableArray *itemArray = [[NSMutableArray alloc]init];

        FUItemModel *nlModel = [[FUItemModel alloc]init];
        nlModel.type = key;
        nlModel.icon =  @"捏脸";
        nlModel.name = @"捏脸";
        [itemArray addObject:nlModel];
        
        for (int n = 0; n < array.count; n++)
        {
            NSMutableDictionary *item = array[n];
            
            FUItemModel *model = [[FUItemModel alloc]init];
            model.type = key;
            model.icon = [item[@"icon"] stringByReplacingOccurrencesOfString:@"icon/PTA_nl" withString:@""];
            model.name = [item[@"icon"] stringByReplacingOccurrencesOfString:@"icon/PTA_nl" withString:@""];
            [item removeObjectForKey:@"icon"];
            model.shapeDict = [item mutableCopy];
            
            [itemArray addObject:model];
        }
        
        [self.itemsDict setObject:itemArray forKey:key];
    }
}

/// 加载形象列表
- (void)loadAvatarList
{
    if (self.avatarList)
    {
        [self.avatarList removeAllObjects];
        self.avatarList = nil ;
    }
    
    if (!self.avatarList)
    {
        self.avatarList = [NSMutableArray arrayWithCapacity:1];
        
        NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Avatars" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *dataArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        
        for (NSDictionary *dict in dataArray) {
            
            if ([dict[@"q_type"] integerValue] != self.avatarStyle) {
                continue ;
            }
            
            FUAvatar *avatar = [self getAvatarWithInfoDic:dict];
//            [avatar setThePrefabricateColors];
            [self.avatarList addObject:avatar];
        }
        
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:AvatarQPath error:nil];
//        self.avatarStyle == FUAvatarStyleNormal ? [[NSFileManager defaultManager] contentsOfDirectoryAtPath:AvatarListPath error:nil] :
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
            
            FUAvatar *avatar = [self getAvatarWithInfoDic:dic];
            [self.avatarList addObject:avatar];
        }
    }
}

#pragma mark ------ 设置颜色 ------
/// 设置颜色
/// @param color 颜色模型
/// @param type 颜色类别
- (void)configColorWithColor:(FUP2AColor *)color ofType:(FUFigureColorType)type
{
    NSString *key = [self getColorKeyWithType:type];
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    
    BOOL undoOrRedo = [FUAvatarEditManager sharedInstance].undo||[FUAvatarEditManager sharedInstance].redo;
    
    if (!undoOrRedo)
    {
        FUP2AColor *oldColor = [self getSelectedColorWithType:type];
        
        NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
        [editDict setObject:color forKey:@"currentConfig"];
        [editDict setObject:oldColor forKey:@"oldConfig"];
        [editDict setObject:[NSNumber numberWithInteger:type] forKey:@"colorType"];
        
        [[FUAvatarEditManager sharedInstance]push:editDict];
    }
    
    [FUAvatarEditManager sharedInstance].undo = NO;
    [FUAvatarEditManager sharedInstance].redo = NO;
    if (type == FUFigureColorTypeEyebrowColor)
    {
        [avatar facepupModeSetEyebrowColor:color];
    }
    else
    {
        [avatar facepupModeSetColor:color key:key];
    }
    
    
    NSInteger index = [self.colorDict[key] indexOfObject:color];
    [self setSelectColorIndex:index ofType:type];
}


/// 配置肤色
/// @param progress 颜色进度
/// @param isPush 是否加入撤销的堆栈
- (void)configSkinColorWithProgress:(double)progress isPush:(BOOL)isPush
{
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    
    BOOL undoOrRedo = [FUAvatarEditManager sharedInstance].undo||[FUAvatarEditManager sharedInstance].redo;
    
    FUP2AColor *newColor = [self getSkinColorWithProgress:progress];
    
    if (!undoOrRedo && isPush)
    {
        double oldeSkinColorProgress = avatar.skinColorProgress;
        FUP2AColor *oldColor = [self getSkinColorWithProgress:oldeSkinColorProgress];
        
        NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
        [editDict setObject:newColor forKey:@"currentConfig"];
        [editDict setObject:oldColor forKey:@"oldConfig"];
        [editDict setObject:[NSNumber numberWithDouble:oldeSkinColorProgress] forKey:@"oldSkinColorProgress"];
        [editDict setObject:[NSNumber numberWithDouble:progress] forKey:@"skinColorProgress"];
        [editDict setObject:[NSNumber numberWithInteger:FUFigureColorTypeSkinColor] forKey:@"colorType"];
        
        [[FUAvatarEditManager sharedInstance]push:editDict];
    }

    [FUAvatarEditManager sharedInstance].undo = NO;
    [FUAvatarEditManager sharedInstance].redo = NO;

    [avatar facepupModeSetColor:newColor key:[self getColorKeyWithType:FUFigureColorTypeSkinColor]];

    [self setSelectColorIndex:0 ofType:FUFigureColorTypeSkinColor];
}

#pragma mark ------ 绑定道具 ------
/// 在美妆界面，当选择第 0 个item，进行回退时，恢复之前多选状态
/// @param model 专门记录美妆多选状态的model
-(void)reserveMultipleMakeupItemState:(FUMultipleRecordItemModel*)model
{
	NSArray * makeupSeletedArray = model.multipleSelectedArr;
	NSArray * makeupArr = self.itemsDict[FUEditTypeKey(FUEditTypeMakeup)];
	for (NSNumber *indexN in makeupSeletedArray) {
		int idx = [indexN intValue];
		if (idx > 0) {
			FUMakeupItemModel * makeupModel = makeupArr[idx];
			[FUAvatarEditManager sharedInstance].undo = YES;
			[FUAvatarEditManager sharedInstance].redo = YES;
			[self bindItemWithModel:makeupModel];
		}
	}
}
/// 重置美妆类型
-(void)resetMakeupItems{
	for (NSString * type in self.makeupTypeArray) {
		[self removeItemWithModel:nil AndType:type];
	}
	self.currentSelectedMakeupType = nil;
}

/// 在配饰界面，当选择第 0 个item，进行回退时，恢复之前多选状态
/// @param model 专门记录配饰多选状态的model
-(void)reserveMultipleDecorationItemState:(FUMultipleRecordItemModel*)model
{
	NSArray * decorationSeletedArray = model.multipleSelectedArr;
	NSArray * decorationArr = self.itemsDict[FUDecorationsString];
	for (NSNumber *indexN in decorationSeletedArray) {
		int idx = [indexN intValue];
		if (idx > 0) {
			FUDecorationItemModel * decorationModel = decorationArr[idx];
			[FUAvatarEditManager sharedInstance].undo = YES;
			[FUAvatarEditManager sharedInstance].redo = YES;
			[self bindItemWithModel:decorationModel];
		}
	}
}
/// 重置配饰类型
-(void)resetDecorationItems{
	for (NSString * type in self.decorationTypeArray) {
		[self removeItemWithModel:nil AndType:type];
	}
}


/// @param oldModel 记录多状态的model
/// @param currentModel 当前model
/// @param isReversed 是否逆序
-(void)dealMutualExclusion:(FUMultipleRecordItemModel *)oldModel current:(FUMultipleRecordItemModel *)currentModel direction:(BOOL)isReversed
{
	dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
	[FUAvatarEditManager sharedInstance].undo = NO;
	[FUAvatarEditManager sharedInstance].redo = NO;
	FUAvatar * avatar = self.currentAvatars.firstObject;
	if(isReversed){
		for (id obj in currentModel.multipleSelectedArr) {
			if ([obj isKindOfClass:[NSNumber class]])
			{
				
			}else{
				FUItemModel * m = obj;
				NSString * type = m.type;
				if (type == nil) {
					type = TAG_FU_ITEM_DECORATION_TOUSHI;
				}
				[self removeItemWithModel:nil AndType:type];
			}
		}
		// 不调用 bindItemWithModel ，防止循环调用
		for (id obj in oldModel.multipleSelectedArr) {
			if ([obj isKindOfClass:[NSNumber class]])
			{
				avatar.hairType = [obj intValue];
			}else{
				FUItemModel * m = obj;
				NSString * bundlePath = [m getBundlePath];
				FUItemType t ;
				NSString * type = m.type;
				if ([m.type isEqualToString:TAG_FU_ITEM_HAIR])
				{
					t = FUItemTypeHair;
					// 指向 deform 后 头发路径
					bundlePath = [NSString stringWithFormat:@"%@/%@",[avatar filePath],m.name];
				}else if ([m.type isEqualToString:TAG_FU_ITEM_HAIRHAT])
				{
					t = FUItemTypeHairHat;
					// 指向 deform 后 发帽路径
					bundlePath = [NSString stringWithFormat:@"%@/%@",[avatar filePath],m.name];
				}else if ([m.type isEqualToString:TAG_FU_ITEM_DECORATION_TOUSHI])
				{
					t = FUItemTypeDecoration_toushi;
				}
				if (type == nil) {
					if ([m.path containsString:@"hair"]) {
						type = TAG_FU_ITEM_HAIR;
						m.type = type;
						t = FUItemTypeHair;
						
					}else  if ([m.path containsString:@"decoration"]) {
						type = TAG_FU_ITEM_DECORATION_TOUSHI;
						m.type = type;
						t = FUItemTypeDecoration_toushi;
					}
				}
				[avatar bindItemWithType:t filePath:bundlePath];
				//设置选中索引
				[self setItemIndexWithModel:m];
				
				//修改模型信息的参数
				[avatar setValue:m forKey:type];
			}
		}
		
	}else{
		for (id obj in oldModel.multipleSelectedArr) {
			if ([obj isKindOfClass:[NSNumber class]])
			{
				
			}else{
				FUItemModel * m = obj;
				NSString * type = m.type;
				if (type == nil) {
					type = TAG_FU_ITEM_DECORATION_TOUSHI;
				}
				[self removeItemWithModel:nil AndType:type];
			}
		}
		// 不调用 bindItemWithModel ，防止循环调用
		for (id obj in currentModel.multipleSelectedArr){
			if ([obj isKindOfClass:[NSNumber class]])
			{
				avatar.hairType = [obj intValue];
			}else{
				FUItemModel * m = obj;
				NSString * bundlePath = [m getBundlePath];
				FUItemType t ;
				NSString * type = m.type;
				if ([m.type isEqualToString:TAG_FU_ITEM_HAIR])
				{
					t = FUItemTypeHair;
					// 指向 deform 后 头发路径
					bundlePath = [NSString stringWithFormat:@"%@/%@",[avatar filePath],m.name];
				}else if ([m.type isEqualToString:TAG_FU_ITEM_HAIRHAT])
				{
					t = FUItemTypeHairHat;
					// 指向 deform 后 发帽路径
					bundlePath = [NSString stringWithFormat:@"%@/%@",[avatar filePath],m.name];
				}else if ([m.type isEqualToString:TAG_FU_ITEM_DECORATION_TOUSHI])
				{
					t = FUItemTypeDecoration_toushi;
				}
				if (type == nil) {
					if ([m.path containsString:@"hair"]) {
						type = TAG_FU_ITEM_HAIR;
						m.type = type;
						t = FUItemTypeHair;
						
					}else  if ([m.path containsString:@"decoration"]) {
						type = TAG_FU_ITEM_DECORATION_TOUSHI;
						m.type = type;
						t = FUItemTypeDecoration_toushi;
					}
				}
				[avatar bindItemWithType:t filePath:bundlePath];
				//设置选中索引
				[self setItemIndexWithModel:m];
				
				//修改模型信息的参数
				[avatar setValue:m forKey:type];
			}
		}
		
	}
	// 根据当前 发帽、头饰  确实当前 头发模式是 发型还是 发帽  ， 解决 撤销、回退 然后保存后 光头的bug
	//	if (![avatar.hairHat.name containsString:@"noitem"]) {
	//		avatar.hairType = FUAvataHairTypeHairHat;
	//	}else if (![avatar.decoration_toushi.name containsString:@"noitem"]) {
	//		avatar.hairType = FUAvataHairTypeHair;
	//	}
	dispatch_semaphore_signal(self.signal);
}

///删除已经绑定道具
/// @param model 道具相关信息
- (void)removeItemWithModel:(FUItemModel *)model AndType:(NSString *)type
{
     NSAssert(type, @"type 不可为 nil");
     FUAvatar *avatar = self.currentAvatars.firstObject;
     FUItemModel *noItem = self.itemsDict[type][0];
	if ([type isEqualToString:TAG_FU_ITEM_HAIR])
    {
       
        [avatar bindHairWithItemModel:noItem];
		//修改模型信息的参数
		[avatar setValue:nil forKey:type];
    }else if ([type isEqualToString:TAG_FU_ITEM_HAIRHAT])
    {
        [avatar bindHairHatWithItemModel:noItem];
    }else if ([type isEqualToString:TAG_FU_ITEM_EYELASH])
    {
        if(model)
		noItem = [[FUMakeupNoItemModel alloc]initWithItemModel:model];
        [avatar bindEyeLashWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_EYEBROW])
    {
        if(model)
        noItem = [[FUMakeupNoItemModel alloc]initWithItemModel:model];
        [avatar bindEyebrowWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_EYESHADOW])
    {
        if(model)
        noItem = [[FUMakeupNoItemModel alloc]initWithItemModel:model];
        [avatar bindEyeShadowWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_EYELINER])
    {
        if(model)
        noItem = [[FUMakeupNoItemModel alloc]initWithItemModel:model];
        [avatar bindEyeLinerWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_PUPIL])
    {
        if(model)
        noItem = [[FUMakeupNoItemModel alloc]initWithItemModel:model];
        [avatar bindPupilWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_FACEMAKEUP])
    {
        if(model)
        noItem = [[FUMakeupNoItemModel alloc]initWithItemModel:model];
        [avatar bindFaceMakeupWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_LIPGLOSS])
    {
        if(model)
        noItem = [[FUMakeupNoItemModel alloc]initWithItemModel:model];
        [avatar bindLipGlossWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_DECORATION_SHOU])
    {
        [avatar bindDecorationShouWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_DECORATION_JIAO])
    {
        [avatar bindDecorationJiaoWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_DECORATION_XIANGLIAN])
    {
        [avatar bindDecorationXianglianWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_DECORATION_ERHUAN])
    {
        [avatar bindDecorationErhuanWithItemModel:noItem];
    }
    else if ([type isEqualToString:TAG_FU_ITEM_DECORATION_TOUSHI])
    {
        noItem = self.itemsDict[FUDecorationsString][0];
        [avatar bindDecorationToushiWithItemModel:noItem];

    }
    //设置选中索引
    [self removeItemIndexWithType:type];
	//修改模型信息的参数
	[avatar setValue:noItem forKey:type];
    self.currentSelectedMakeupType = nil;
}
/// 绑定道具
/// @param model 道具相关信息
- (void)bindItemWithModel:(FUItemModel *)model
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    BOOL undoOrRedo = [FUAvatarEditManager sharedInstance].undo||[FUAvatarEditManager sharedInstance].redo;
    // 监控 undo 为空，redo有数据的状态
    BOOL isUndoEmpty = [FUAvatarEditManager sharedInstance].undoStackEmpty && ![FUAvatarEditManager sharedInstance].redoStackEmpty;
	NSMutableDictionary *redoTopDic = [FUAvatarEditManager sharedInstance].redoStackTop;
    if ([model.type isEqualToString:TAG_FU_ITEM_HAIR])
    {
        [avatar bindHairWithItemModel:model];
        if (!undoOrRedo)
        {
			NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
			
			FUMultipleRecordItemModel * oldRecordItemModel = [[FUMultipleRecordItemModel alloc]init];
			NSMutableArray * oldArr = [NSMutableArray array];
			FUMultipleRecordItemModel * currentRecordItemModel = [[FUMultipleRecordItemModel alloc]init];
			NSMutableArray * currentArr = [NSMutableArray array];
			
			[oldArr addObject:avatar.hair];
			[oldArr addObject:avatar.decoration_toushi];
			[oldArr addObject:avatar.hairHat];
			// 记录当前头发类型
			[oldArr addObject:@(avatar.hairType)];

			avatar.hairHat = self.itemsDict[TAG_FU_ITEM_HAIRHAT][0];
			//设置选中索引
			[self setItemIndexWithModel:avatar.hairHat];
		//	[avatar bindHairHatWithItemModel:avatar.hairHat];
			
			[currentArr addObject:model];
			[currentArr addObject:avatar.hairHat];
			[currentArr addObject:avatar.decoration_toushi];
			avatar.hairType = FUAvataHairTypeHair;
			[currentArr addObject:@(avatar.hairType)];
			
			oldRecordItemModel.multipleSelectedArr = oldArr;
			currentRecordItemModel.multipleSelectedArr = currentArr;
			editDict[@"oldConfig"] = oldRecordItemModel;
			editDict[@"currentConfig"] = currentRecordItemModel;
			[[FUAvatarEditManager sharedInstance]push:editDict];
        }
       
        
        
        
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_HAIRHAT])
	{
		
		
		[avatar bindHairHatWithItemModel:model];
		
		if (!undoOrRedo)
		{
			NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
			
			FUMultipleRecordItemModel * oldRecordItemModel = [[FUMultipleRecordItemModel alloc]init];
			NSMutableArray * oldArr = [NSMutableArray array];
			FUMultipleRecordItemModel * currentRecordItemModel = [[FUMultipleRecordItemModel alloc]init];
			NSMutableArray * currentArr = [NSMutableArray array];
			
			[oldArr addObject:avatar.hair];
			[oldArr addObject:avatar.decoration_toushi];
			[oldArr addObject:avatar.hairHat];
			// 记录当前头发类型
			[oldArr addObject:@(avatar.hairType)];
			
			avatar.decoration_toushi = self.itemsDict[FUDecorationsString][0];
			//设置选中索引
			[self setItemIndexWithModel:avatar.decoration_toushi];
			[avatar bindDecorationToushiWithItemModel:avatar.decoration_toushi];
			avatar.hair = self.itemsDict[TAG_FU_ITEM_HAIR][0];
			//设置选中索引
			[self setItemIndexWithModel:avatar.hair];
			[currentArr addObject:model];
			[currentArr addObject:avatar.hair];
			[currentArr addObject:avatar.decoration_toushi];
			avatar.hairType = FUAvataHairTypeHairHat;
			[currentArr addObject:@(avatar.hairType)];
			

			oldRecordItemModel.multipleSelectedArr = oldArr;
			currentRecordItemModel.multipleSelectedArr = currentArr;
			editDict[@"oldConfig"] = oldRecordItemModel;
			editDict[@"currentConfig"] = currentRecordItemModel;
			[[FUAvatarEditManager sharedInstance]push:editDict];
		}
		
		
		
	}
    else if ([model.type isEqualToString:TAG_FU_ITEM_FACE])
    {
        if ([model.name isEqualToString:@"捏脸"]&&!undoOrRedo)
        {
            self.shapeModeKey = [model.type stringByAppendingString:@"_front"];
            [[NSNotificationCenter defaultCenter] postNotificationName:FUEnterNileLianNot object:nil];
			//设置选中索引
			[self setItemIndexWithModel:model];
			dispatch_semaphore_signal(self.signal);
            return;
        }
        else
        {
            [[FUShapeParamsMode shareInstance]getOrignalParamsWithAvatar:self.currentAvatars.firstObject];
            [avatar configFacepupParamWithDict:model.shapeDict];
			//[[FUShapeParamsMode shareInstance]getCurrentParamsWithAvatar:self.currentAvatars.firstObject];
        }
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_MOUTH])
    {
        if ([model.name isEqualToString:@"捏脸"]&&!undoOrRedo)
        {
            self.shapeModeKey = [model.type stringByAppendingString:@"_front"];
            [[NSNotificationCenter defaultCenter] postNotificationName:FUEnterNileLianNot object:nil];
			//设置选中索引
			[self setItemIndexWithModel:model];
			dispatch_semaphore_signal(self.signal);
            return;
        }
        else
        {
            [[FUShapeParamsMode shareInstance]getOrignalParamsWithAvatar:self.currentAvatars.firstObject];
            [avatar configFacepupParamWithDict:model.shapeDict];
           // [[FUShapeParamsMode shareInstance]getCurrentParamsWithAvatar:self.currentAvatars.firstObject];
        }
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_EYE])
    {
        if ([model.name isEqualToString:@"捏脸"]&&!undoOrRedo)
        {
            self.shapeModeKey = [model.type stringByAppendingString:@"_front"];
            [[NSNotificationCenter defaultCenter] postNotificationName:FUEnterNileLianNot object:nil];
			//设置选中索引
			[self setItemIndexWithModel:model];
			dispatch_semaphore_signal(self.signal);
            return;
        }
        else
        {
            [[FUShapeParamsMode shareInstance]getOrignalParamsWithAvatar:self.currentAvatars.firstObject];
            [avatar configFacepupParamWithDict:model.shapeDict];
           // [[FUShapeParamsMode shareInstance]getCurrentParamsWithAvatar:self.currentAvatars.firstObject];
        }
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_NOSE])
    {
        if ([model.name isEqualToString:@"捏脸"]&&!undoOrRedo)
        {
            self.shapeModeKey = [model.type stringByAppendingString:@"_front"];
            [[NSNotificationCenter defaultCenter] postNotificationName:FUEnterNileLianNot object:nil];
			//设置选中索引
			[self setItemIndexWithModel:model];
			dispatch_semaphore_signal(self.signal);
            return;
        }
        else
        {
            [[FUShapeParamsMode shareInstance]getOrignalParamsWithAvatar:self.currentAvatars.firstObject];
            [avatar configFacepupParamWithDict:model.shapeDict];
          //  [[FUShapeParamsMode shareInstance]getCurrentParamsWithAvatar:self.currentAvatars.firstObject];
        }
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_CLOTH])
    {
     
        if (undoOrRedo&&[model.bundle isEqualToString:@""])
        {//撤销或恢复时，如果恢复到裸体，说明之前穿的是上下衣，恢复到之前的上下衣
            [avatar bindLowerWithItemModel:avatar.lower];
            [avatar bindUpperWithItemModel:avatar.upper];
            
            [self setItemIndexWithModel:avatar.lower];
            [self setItemIndexWithModel:avatar.upper];
        }
        else
        {
            [avatar bindClothWithItemModel:model];
            
            [self.selectedItemIndexDict setObject:@(0) forKey:TAG_FU_ITEM_UPPER];
            [self.selectedItemIndexDict setObject:@(0) forKey:TAG_FU_ITEM_LOWER];
        }

    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_UPPER])
    {
	
        
        if (undoOrRedo&&[model.bundle isEqualToString:@""])
        {//撤销或恢复时，如果恢复到裸体，说明之前穿的是套装，恢复到之前的套装
            [avatar bindClothWithItemModel:avatar.clothes];
            
            [self.selectedItemIndexDict setObject:@(0) forKey:TAG_FU_ITEM_LOWER];
            [self setItemIndexWithModel:avatar.clothes];
        }
        else
        {
            if (avatar.clothType == FUAvataClothTypeSuit)
            {
            FUItemModel *lowerModel;
				if (avatar.gender == FUGenderMale){
					lowerModel = [FUManager shareInstance].itemsDict[TAG_FU_ITEM_LOWER][6];
					[avatar bindLowerWithItemModel:lowerModel];
					[self.selectedItemIndexDict setObject:@(0) forKey:TAG_FU_ITEM_CLOTH];
					[self.selectedItemIndexDict setObject:@(6) forKey:TAG_FU_ITEM_LOWER];
				}else if (avatar.gender == FUGenderFemale){
					lowerModel = [FUManager shareInstance].itemsDict[TAG_FU_ITEM_LOWER][1];
					[avatar bindLowerWithItemModel:lowerModel];
					[self.selectedItemIndexDict setObject:@(0) forKey:TAG_FU_ITEM_CLOTH];
					[self.selectedItemIndexDict setObject:@(1) forKey:TAG_FU_ITEM_LOWER];
				}
				//修改模型信息的参数
					[avatar setValue:lowerModel forKey:TAG_FU_ITEM_LOWER];
            }
            [avatar bindUpperWithItemModel:model];
        }
        
	
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_LOWER])
    {
	
        if (undoOrRedo&&[model.bundle isEqualToString:@""])
        {//撤销或恢复时，如果恢复到裸体，说明之前穿的是套装，恢复到之前的套装
            [avatar bindClothWithItemModel:avatar.clothes];
            
            [self.selectedItemIndexDict setObject:@(0) forKey:TAG_FU_ITEM_LOWER];
            [self setItemIndexWithModel:avatar.clothes];
        }
        else
		{
			if (avatar.clothType == FUAvataClothTypeSuit)
			{
			FUItemModel *upperModel;
				if (avatar.gender == FUGenderMale){
					upperModel = [FUManager shareInstance].itemsDict[TAG_FU_ITEM_UPPER][4];
					[avatar bindUpperWithItemModel:upperModel];
					[self.selectedItemIndexDict setObject:@(0) forKey:TAG_FU_ITEM_CLOTH];
					[self.selectedItemIndexDict setObject:@(4) forKey:TAG_FU_ITEM_UPPER];

					
				}else if (avatar.gender == FUGenderFemale){
					upperModel = [FUManager shareInstance].itemsDict[TAG_FU_ITEM_UPPER][6];
					[avatar bindUpperWithItemModel:upperModel];
					[self.selectedItemIndexDict setObject:@(0) forKey:TAG_FU_ITEM_CLOTH];
					[self.selectedItemIndexDict setObject:@(6) forKey:TAG_FU_ITEM_UPPER];
				}
				
				//修改模型信息的参数
				[avatar setValue:upperModel forKey:TAG_FU_ITEM_UPPER];
			}
			[avatar bindLowerWithItemModel:model];
		}
        
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_SHOES])
    {
        [avatar bindShoesWithItemModel:model];
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_HAT])
    {
        [avatar bindHatWithItemModel:model];
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_EYELASH])
	{
		id _exitCurrentModel = redoTopDic[@"currentConfig"];
		if ([_exitCurrentModel isKindOfClass:[FUItemModel class]]){
			FUItemModel *exitCurrentModel = _exitCurrentModel;
			if ([exitCurrentModel.type isEqualToString:model.type]){
				redoTopDic[@"oldConfig"] = model;
			}
		}
		[avatar bindEyeLashWithItemModel:model];
		self.currentSelectedMakeupType = TAG_FU_ITEM_EYELASH;
	}
    else if ([model.type isEqualToString:TAG_FU_ITEM_EYEBROW])
	{
		id _exitCurrentModel = redoTopDic[@"currentConfig"];
		if ([_exitCurrentModel isKindOfClass:[FUItemModel class]]){
			FUItemModel *exitCurrentModel = _exitCurrentModel;
			if ([exitCurrentModel.type isEqualToString:model.type]){
				redoTopDic[@"oldConfig"] = model;
			}
		}
		[avatar bindEyebrowWithItemModel:model];
		self.currentSelectedMakeupType = TAG_FU_ITEM_EYEBROW;
	}
    else if ([model.type isEqualToString:TAG_FU_ITEM_BEARD])
    {
        [avatar bindBeardWithItemModel:model];
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_GLASSES])
    {
        [avatar bindGlassesWithItemModel:model];
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_EYESHADOW])
	{
		id _exitCurrentModel = redoTopDic[@"currentConfig"];
		if ([_exitCurrentModel isKindOfClass:[FUItemModel class]]){
			FUItemModel *exitCurrentModel = _exitCurrentModel;
			if ([exitCurrentModel.type isEqualToString:model.type]){
				redoTopDic[@"oldConfig"] = model;
			}
		}
		[avatar bindEyeShadowWithItemModel:model];
		
		self.currentSelectedMakeupType = TAG_FU_ITEM_EYESHADOW;
	}
    else if ([model.type isEqualToString:TAG_FU_ITEM_EYELINER])
	{
		id _exitCurrentModel = redoTopDic[@"currentConfig"];
		if ([_exitCurrentModel isKindOfClass:[FUItemModel class]]){
			FUItemModel *exitCurrentModel = _exitCurrentModel;
			if ([exitCurrentModel.type isEqualToString:model.type]){
				redoTopDic[@"oldConfig"] = model;
			}
		}
		[avatar bindEyeLinerWithItemModel:model];
		self.currentSelectedMakeupType = TAG_FU_ITEM_EYELINER;
	}
    else if ([model.type isEqualToString:TAG_FU_ITEM_PUPIL])
	{
		id _exitCurrentModel = redoTopDic[@"currentConfig"];
		if ([_exitCurrentModel isKindOfClass:[FUItemModel class]]){
			FUItemModel *exitCurrentModel = _exitCurrentModel;
			if ([exitCurrentModel.type isEqualToString:model.type]){
				redoTopDic[@"oldConfig"] = model;
			}
		}
		[avatar bindPupilWithItemModel:model];
		self.currentSelectedMakeupType = TAG_FU_ITEM_PUPIL;
	}
    else if ([model.type isEqualToString:TAG_FU_ITEM_FACEMAKEUP])
	{
		id _exitCurrentModel = redoTopDic[@"currentConfig"];
		if ([_exitCurrentModel isKindOfClass:[FUItemModel class]]){
			FUItemModel *exitCurrentModel = _exitCurrentModel;
			if ([exitCurrentModel.type isEqualToString:model.type]){
				redoTopDic[@"oldConfig"] = model;
			}
		}
		[avatar bindFaceMakeupWithItemModel:model];
		self.currentSelectedMakeupType = TAG_FU_ITEM_FACEMAKEUP;
	}
    else if ([model.type isEqualToString:TAG_FU_ITEM_LIPGLOSS])
	{
		id _exitCurrentModel = redoTopDic[@"currentConfig"];
		if ([_exitCurrentModel isKindOfClass:[FUItemModel class]]){
			FUItemModel *exitCurrentModel = _exitCurrentModel;
			if ([exitCurrentModel.type isEqualToString:model.type]){
				redoTopDic[@"oldConfig"] = model;
			}
		}
		[avatar bindLipGlossWithItemModel:model];
		self.currentSelectedMakeupType = TAG_FU_ITEM_LIPGLOSS;
	}
    //  饰品 大类 多选
    else if ([model.type isEqualToString:TAG_FU_ITEM_DECORATION_SHOU])
    {
        [avatar bindDecorationShouWithItemModel:model];
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_DECORATION_JIAO])
    {
        [avatar bindDecorationJiaoWithItemModel:model];
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_DECORATION_XIANGLIAN])
    {
        [avatar bindDecorationXianglianWithItemModel:model];
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_DECORATION_ERHUAN])
    {
        [avatar bindDecorationErhuanWithItemModel:model];
    }
    else if ([model.type isEqualToString:TAG_FU_ITEM_DECORATION_TOUSHI])
    {
        [avatar bindDecorationToushiWithItemModel:model];
        if (!undoOrRedo)
		{
			BOOL useFUMultipleRecordItemModel = NO;  //是否 使用 FUMultipleRecordItemModel 对象进行记录
			NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
			
			FUMultipleRecordItemModel * oldRecordItemModel = [[FUMultipleRecordItemModel alloc]init];
			FUMultipleRecordItemModel *currentRecordItemModel = [[FUMultipleRecordItemModel alloc]init];
			NSMutableArray * oldArr = [NSMutableArray array];
			NSMutableArray * currentArr = [NSMutableArray array];
			[oldArr addObject:avatar.decoration_toushi];
			[oldArr addObject:avatar.hairHat];
			// 如果存在 发帽，需要将 头发重置为 第1个
			BOOL exitHairHat = ![avatar.hairHat.name containsString:@"noitem"];
			avatar.hairHat = [FUManager shareInstance].itemsDict[TAG_FU_ITEM_HAIRHAT][0];
			//设置选中索引
			[self setItemIndexWithModel:avatar.hairHat];
			[avatar bindHairHatWithItemModel:avatar.hairHat];
			[oldArr addObject:avatar.hair];

			
			if (exitHairHat){
				avatar.hair = self.itemsDict[TAG_FU_ITEM_HAIR][1];
				//设置选中索引
				[self setItemIndexWithModel:avatar.hair];
				avatar.hairType = FUAvataHairTypeHair;
			}
			[avatar bindHairWithItemModel:avatar.hair];
			[currentArr addObject:avatar.hair];
			[currentArr addObject:model];
			[currentArr addObject:avatar.hairHat];
			useFUMultipleRecordItemModel = YES;
			oldRecordItemModel.multipleSelectedArr = oldArr;
			currentRecordItemModel.multipleSelectedArr = currentArr;
			editDict[@"oldConfig"] = oldRecordItemModel;
			editDict[@"currentConfig"] = currentRecordItemModel;
			[[FUAvatarEditManager sharedInstance]push:editDict];
		}
    }
    
    
    else if ([model.type isEqualToString:TAG_FU_ITEM_DRESS_2D])
    {
       [avatar bindBackgroundWithItemModel:model];
    }
    
    
    //设置undo堆栈
    if (!undoOrRedo&&![model.type isEqualToString:TAG_FU_ITEM_HAIR] &&![model.type isEqualToString:TAG_FU_ITEM_HAIRHAT]  &&![model.type isEqualToString:TAG_FU_ITEM_DECORATION_TOUSHI])
    {
        NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
        
        FUItemModel *oldModel = [avatar valueForKey:model.type];
        if ([oldModel.name isEqualToString:@"捏脸"]&&!oldModel.shapeDict)
        {
            oldModel.shapeDict = [FUShapeParamsMode shareInstance].orginalFaceup;
        }
        editDict[@"oldConfig"] = oldModel;
        editDict[@"currentConfig"] = model;

        [[FUAvatarEditManager sharedInstance]push:editDict];
    }
    
    [FUAvatarEditManager sharedInstance].undo = NO;
    [FUAvatarEditManager sharedInstance].redo = NO;

    //设置选中索引
    [self setItemIndexWithModel:model];
    
    //修改模型信息的参数
    [avatar setValue:model forKey:model.type];
    dispatch_semaphore_signal(self.signal);
}

/// 删除 index
/// @param model 目标model
- (void)removeItemIndexWithType:(NSString *)type
{
	// 设置默认的 0
	[self.selectedItemIndexDict setObject:@(0) forKey:type];
	
}

- (void)setItemIndexWithModel:(FUItemModel *)model
{
	if ([model isKindOfClass:[FUMakeupItemModel class]]) {  // 美妆类型
		//设置选中索引
		NSArray *array = self.itemsDict[FUEditTypeKey(FUEditTypeMakeup)];
		NSInteger index = [array containsObject:model]?[array indexOfObject:model]:0;
		
		[self.selectedItemIndexDict setObject:@(index) forKey:model.type];
	}else if ([model isKindOfClass:[FUDecorationItemModel class]]) {  // 配饰类型
		//设置选中索引
		NSArray *array = self.itemsDict[FUDecorationsString];
		NSInteger index = [array containsObject:model]?[array indexOfObject:model]:0;
		
		[self.selectedItemIndexDict setObject:@(index) forKey:model.type];
	}
	else{
		//设置选中索引
		NSArray *array = self.itemsDict[model.type];
		NSInteger index = [array containsObject:model]?[array indexOfObject:model]:0;
		
		[self.selectedItemIndexDict setObject:@(index) forKey:model.type];
	}
}


#pragma mark ------ 背景 ------
/// 加载默认背景
- (void)loadDefaultBackGroundToController
{
    
    NSString *default_bg_Path = [[NSBundle mainBundle] pathForResource:@"default_bg" ofType:@"bundle"];
    [self reloadBackGroundAndBindToController:default_bg_Path];
}

- (void)loadKetingBackGroundToController
{
    NSString *default_bg_Path = [[NSBundle mainBundle] pathForResource:@"ketingB" ofType:@"bundle"];
    [self reloadBackGroundAndBindToController:default_bg_Path];
}

/// 绑定背景道具到controller
/// @param filePath 新背景道具路径
- (void)reloadBackGroundAndBindToController:(NSString *)filePath
{
	
	[self rebindItemToControllerWithFilepath:filePath withPtr:&q_controller_bg_ptr];
}

#pragma mark ------ hair_mask ------
/**
 绑定hair_mask.bundle
 */
- (void)bindHairMask
{
    NSString *hair_mask_Path = [[NSBundle mainBundle] pathForResource:@"hair_mask.bundle" ofType:nil];
    hair_mask_ptr = [self bindItemToControllerWithFilepath:hair_mask_Path];
}

/**
 销毁hair_mask.bundle
 */
- (void)destoryHairMask
{
    if (hair_mask_ptr > 0)
    {
        // 解绑
        [FURenderer unBindItems:self.defalutQController items:&hair_mask_ptr itemsCount:1];
        // 销毁
        [FURenderer destroyItem:hair_mask_ptr];
        hair_mask_ptr = 0;
    }
}

/**
 设置手势动画
 -- 会切换 controller 所在句柄
 */
- (void)loadPoseTrackAnim {
    
    NSString * anim_fistPath = [[NSBundle mainBundle] pathForResource:@"anim_fist.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_fistPath];
    NSString * anim_mergePath = [[NSBundle mainBundle] pathForResource:@"anim_merge.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_mergePath];
    NSString * anim_palmPath = [[NSBundle mainBundle] pathForResource:@"anim_palm.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_palmPath];
    NSString * anim_twoPath = [[NSBundle mainBundle] pathForResource:@"anim_two.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_twoPath];
    NSString * anim_heartPath = [[NSBundle mainBundle] pathForResource:@"anim_heart.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_heartPath];
    NSString * anim_onePath = [[NSBundle mainBundle] pathForResource:@"anim_one.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_onePath];
    NSString * anim_sixPath = [[NSBundle mainBundle] pathForResource:@"anim_six.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_sixPath];
    
    NSString * anim_eightPath = [[NSBundle mainBundle] pathForResource:@"anim_eight.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_eightPath];
    NSString * anim_okPath = [[NSBundle mainBundle] pathForResource:@"anim_ok.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_okPath];
    NSString * anim_thumbPath = [[NSBundle mainBundle] pathForResource:@"anim_thumb.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_thumbPath];
    NSString * anim_holdPath = [[NSBundle mainBundle] pathForResource:@"anim_hold.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_holdPath];
    NSString * anim_korheartPath = [[NSBundle mainBundle] pathForResource:@"anim_korheart.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_korheartPath];
    NSString * anim_rockPath = [[NSBundle mainBundle] pathForResource:@"anim_rock.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_rockPath];
    
    NSString * anim_greetPath = [[NSBundle mainBundle] pathForResource:@"anim_greet.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_greetPath];
    NSString * anim_gunPath = [[NSBundle mainBundle] pathForResource:@"anim_gun.bundle" ofType:nil];
    [self bindItemToControllerWithFilepath:anim_gunPath];
    //    NSString * anim_unknownPath = [[NSBundle mainBundle] pathForResource:@"anim_unknown.bundle" ofType:nil];
    //    [self bindItemWithToController:anim_unknownPath];
}

/**
 为形象的左脚和右脚分别添加脚下阴影
 */
- (void)bindPlaneShadow {
	if (zuojiao_plane_mg_ptr <= 0) {
		NSString *zuojiao_plane_mg_Path = [[NSBundle mainBundle] pathForResource:@"zuojiao_plane_shadow.bundle" ofType:nil];
		zuojiao_plane_mg_ptr = [self bindItemToControllerWithFilepath:zuojiao_plane_mg_Path];
	}
	if (youjiao_plane_mg_ptr <= 0) {
		NSString *youjiao_plane_mg_Path = [[NSBundle mainBundle] pathForResource:@"youjiao_plane_shadow.bundle" ofType:nil];
		youjiao_plane_mg_ptr = [self bindItemToControllerWithFilepath:youjiao_plane_mg_Path];
	}
}
/**
 分别解绑形象的左脚和右脚的脚下阴影
*/
- (void)unBindPlaneShadow {
	if (zuojiao_plane_mg_ptr > 0) {
		// 解绑
		[FURenderer unBindItems:_defalutQController items:&zuojiao_plane_mg_ptr itemsCount:1];
		// 销毁
		[FURenderer destroyItem:zuojiao_plane_mg_ptr];
		zuojiao_plane_mg_ptr = 0;
	}
	if (youjiao_plane_mg_ptr > 0) {
		// 解绑
		[FURenderer unBindItems:_defalutQController items:&youjiao_plane_mg_ptr itemsCount:1];
		// 销毁
		[FURenderer destroyItem:youjiao_plane_mg_ptr];
		youjiao_plane_mg_ptr = 0;
	}
}
/**
 * //AR模式下，为了支持旋转屏幕时，同时旋转头发遮罩
 * //0表示设备未旋转，1表示逆时针旋转90度，2表示逆时针旋转180度，3表示逆时针旋转270度
 @param orientation 当前设备的方向
 */
-(void)setScreenOrientation:(UIInterfaceOrientation)orientation
{
    /*
     UIInterfaceOrientationUnknown            = UIDeviceOrientationUnknown,
     UIInterfaceOrientationPortrait           = UIDeviceOrientationPortrait,
     UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,
     UIInterfaceOrientationLandscapeLeft      = UIDeviceOrientationLandscapeRight,
     UIInterfaceOrientationLandscapeRight     = UIDeviceOrientationLandscapeLeft
     */
    int or = 0;
    switch (orientation) {
        case UIInterfaceOrientationUnknown:
            
            break;
        case UIInterfaceOrientationPortrait:
            or = 0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            or = 2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            or = 1;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            or = 3;
            break;
        default:
            break;
    }
    fuSetDefaultRotationMode(or);
}

#pragma mark ------ Cam ------
/**
 更新Cam道具
 
 @param camPath 辅助道具路径
 */
- (void)reloadCamItemWithPath:(NSString *)camPath
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    [self rebindItemToControllerWithFilepath:camPath withPtr:&q_controller_cam];
    dispatch_semaphore_signal(self.signal);
}
/**
 更新Cam道具,不使用信号量，防止死锁
 
 @param camPath 辅助道具路径
 */
- (void)reloadCamItemNoSignalWithPath:(NSString *)camPath
{
    [self rebindItemToControllerWithFilepath:camPath withPtr:&q_controller_cam];
}

#pragma mark ------ 绑定底层方法 ------
/// 重新绑定道具
/// @param filePath 新的道具路径
/// @param ptr 道具句柄
- (void)rebindItemToControllerWithFilepath:(NSString *)filePath withPtr:(int *)ptr
{
    if (*ptr > 0)
    {
        // 解绑并销毁旧道具
        [FURenderer unBindItems:self.defalutQController items:ptr itemsCount:1];
        [FURenderer destroyItem:*ptr];
    }
    //绑定新道具
    *ptr = [self bindItemToControllerWithFilepath:filePath];
    
}

/// 绑定道具
/// @param filePath 道具路径
- (int)bindItemToControllerWithFilepath:(NSString *)filePath
{
    int tmpHandle = [FURenderer itemWithContentsOfFile:filePath];
    [FURenderer bindItems:self.defalutQController items:&tmpHandle itemsCount:1];
    return tmpHandle;
}

#pragma mark ------ 形象数据处理 ------

/// 进入编辑模式
- (void)enterEditMode
{
    [self getSelectedInfo];
    [self recordItemBeforeEdit];
}

/// 获取当前形象的道具和颜色选中情况
- (void)getSelectedInfo
{
    self.selectedItemIndexDict = [self getSelectedItemIndexDictWithAvatar:self.currentAvatars.lastObject];
    self.selectedColorDict = [self getSelectedColorIndexDictWithAvatar:self.currentAvatars.lastObject];
}

/// 记录编辑前的形象信息
- (void)recordItemBeforeEdit
{
    self.beforeEditAvatar = [self.currentAvatars.firstObject copy];
}

/// 将形象信息恢复到编辑前
- (void)reloadItemBeforeEdit
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    //还原形象
    [self.currentAvatars.firstObject resetValueFromBeforeEditAvatar:self.beforeEditAvatar];
    [self.currentAvatars.firstObject loadAvatarToController];
    dispatch_semaphore_signal(self.signal);
}

/// 判断形象是否编辑过
- (BOOL)hasEditAvatar
{
    __block BOOL hasChanged = NO;
    
	[self.selectedItemIndexDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		FUAvatar *avatar = self.beforeEditAvatar;
		FUItemModel *selectedModel;
		if([self.makeupTypeArray containsObject:key]){  // 如果是美妆类型
			NSArray *itemArray = self.itemsDict[FUEditTypeKey(FUEditTypeMakeup)];
			selectedModel = [itemArray objectAtIndex:[obj integerValue]];
			
		}else if([self.decorationTypeArray containsObject:key]){  // 如果是配饰类型
			NSArray *itemArray = self.itemsDict[FUDecorationsString];
			selectedModel = [itemArray objectAtIndex:[obj integerValue]];
		}
		else{
			selectedModel = [self.itemsDict[key] objectAtIndex:[obj integerValue]];
			
		}
		if (selectedModel && ![selectedModel isEqual:[avatar valueForKey:key]])
		{
			hasChanged = YES;
			*stop = YES;
		}
	}];
    
    if (hasChanged)
    {
        return hasChanged;
    }
    
    NSMutableDictionary *selectedColorIndexDict_beforeEdit = [self getSelectedColorIndexDictWithAvatar:self.beforeEditAvatar];
    
    [self.selectedColorDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
       
        NSInteger index = [selectedColorIndexDict_beforeEdit[key] integerValue];
        
        if (index != [obj integerValue] && ![key isEqualToString:@"skin_color"])
        {
            hasChanged = YES;
            *stop = YES;
        }
    }];
    
    if (hasChanged)
    {
        return hasChanged;
    }
    
    
    if (![[NSNumber numberWithDouble:self.beforeEditAvatar.skinColorProgress] isEqualToNumber: [NSNumber numberWithDouble:self.currentAvatars.firstObject.skinColorProgress]])
    {
        return YES;
    }
    
    
    return hasChanged;
}

- (BOOL)faceHasChanged
{
    BOOL change = NO;
    if (self.beforeEditAvatar.face == self.currentAvatars.firstObject.face)
    {
        return YES;
    }
    
    if (self.beforeEditAvatar.eyes == self.currentAvatars.firstObject.eyes)
    {
        return YES;
    }
    
    if (self.beforeEditAvatar.mouth == self.currentAvatars.firstObject.mouth)
    {
        return YES;
    }
    
    if (self.beforeEditAvatar.nose == self.currentAvatars.firstObject.nose)
    {
        return YES;
    }
    
    return change;
}

//如果是预制形象生成新的形象，如果不是预制模型保存新的信息
- (void)saveAvatar
{
	FUAvatar *currentAvatar = self.currentAvatars.lastObject;
	BOOL deformHead = [[FUShapeParamsMode shareInstance]propertiesIsChanged]||[self faceHasChanged];
	
	//获取保存形象的名字
	NSString *avatarName = currentAvatar.defaultModel ? [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]] : currentAvatar.name;
	
	//获取文件路径
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filePath = [documentPath stringByAppendingPathComponent:avatarName];
	
	if (![fileManager fileExistsAtPath:filePath])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	//拷贝head.bundle,如果需要重新生成头拷贝新的head.bundle
	NSData *headData = [NSData dataWithContentsOfFile:[[currentAvatar filePath] stringByAppendingPathComponent:FU_HEAD_BUNDLE]];
	if (deformHead)
	{//deformHead 决定是否生成新头
		NSArray *params = [[FUShapeParamsMode shareInstance]getShapeParamsWithAvatar:self.currentAvatars.firstObject];
		
		float coeffi[100];
		for (int i = 0 ; i < 100; i ++)
		{
			coeffi[i] = [params[i] floatValue];
		}
		//重新生成head.bundle
		headData = [[fuPTAClient shareInstance] deformHeadWithHeadData:headData deformParams:coeffi paramsSize:100 withExprOnly:NO withLowp:NO].bundle;
	}
	[headData writeToFile:[filePath stringByAppendingPathComponent:@"/head.bundle"] atomically:YES];
	
	if (deformHead)
	{
		[currentAvatar bindItemWithType:FUItemTypeHead filePath:[filePath stringByAppendingPathComponent:@"/head.bundle"]];
	}
	
	if (currentAvatar.defaultModel)
	{//如果是预制模型，拷贝头像
		UIImage *image = [UIImage imageWithContentsOfFile:currentAvatar.imagePath];
		NSData *imageData = UIImageJPEGRepresentation(image, 1.0) ;
		[imageData writeToFile:[filePath stringByAppendingString:@"/image.png"] atomically:YES];
	}
	
	//获取并写入数据json
	NSMutableDictionary *avatarDict = [[NSMutableDictionary alloc]init];
	[avatarDict setValue:avatarName forKey:@"name"];
	[avatarDict setValue:@(currentAvatar.gender) forKey:@"gender"];
	[avatarDict setValue:@(0) forKey:@"default"];
	[avatarDict setValue:@(1) forKey:@"q_type"];
	[avatarDict setValue:@(currentAvatar.clothType) forKey:@"clothType"];
	[avatarDict setValue:@(currentAvatar.hairType) forKey:@"hairType"];
	[avatarDict setValue:@(currentAvatar.skinColorProgress) forKey:TAG_FU_SKIN_COLOR_PROGRESS];
	
	[self.selectedItemIndexDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		
			if([self.makeupTypeArray containsObject:key]){  // 如果是美妆类型
				NSArray *itemArray = self.itemsDict[FUEditTypeKey(FUEditTypeMakeup)];
				FUItemModel *model = [itemArray objectAtIndex:[obj integerValue]];
				
				if (!currentAvatar.defaultModel)
				{
					[currentAvatar setValue:model forKey:key];
				}
				
				[avatarDict setValue:model.name forKey:key];
			}else if([self.decorationTypeArray containsObject:key]){  // 如果是配饰类型
				NSArray *itemArray = self.itemsDict[FUDecorationsString];
				FUItemModel *model = [itemArray objectAtIndex:[obj integerValue]];
				
				if (!currentAvatar.defaultModel)
				{
					[currentAvatar setValue:model forKey:key];
				}
				[avatarDict setValue:model.name forKey:key];
			}
			else{
				NSArray *itemArray = self.itemsDict[key];
				FUItemModel *model = [itemArray objectAtIndex:[obj integerValue]];
				
				if (!currentAvatar.defaultModel)
				{
					[currentAvatar setValue:model forKey:key];
				}
				
				[avatarDict setValue:model.name forKey:key];
			}
		
	}];
	
	[self.selectedColorDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
		
		NSString *colorIndexKey = [key stringByReplacingOccurrencesOfString:@"_c" withString:@"C"];
		colorIndexKey = [colorIndexKey stringByReplacingOccurrencesOfString:@"_f" withString:@"F"];
		colorIndexKey = [colorIndexKey stringByAppendingString:@"Index"];
		
		[avatarDict setValue:[NSNumber numberWithInteger:[obj integerValue]] forKey:colorIndexKey];
		[currentAvatar setValue:[NSNumber numberWithInteger:[obj integerValue]] forKey:colorIndexKey];
	}];
	
	NSData *avatarData = [NSJSONSerialization dataWithJSONObject:avatarDict options:NSJSONWritingPrettyPrinted error:nil];
	NSString *jsonPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:avatarName] stringByAppendingString:@".json"];
	
	[avatarData writeToFile:jsonPath atomically:YES];
	
	//defaultModel 决定是否生成新的形象
	if (currentAvatar.defaultModel)
	{
		FUAvatar *newAvatar = [self getAvatarWithInfoDic:avatarDict];
		
		///拷贝头发
		BOOL shouldDeformHair = [[FUShapeParamsMode shareInstance]shouldDeformHair];
		
		if (shouldDeformHair)
		{
			[self createAndCopyHairBundlesWithAvatar:newAvatar withHairModel:newAvatar.hair];
			[self createAndCopyHairHatBundlesWithAvatar:newAvatar withHairHatModel:newAvatar.hairHat];
		}
		else
		{
			for (FUItemModel *model in self.itemsDict[TAG_FU_ITEM_HAIR])
			{
				if ([model.name rangeOfString:@"noitem"].length > 0)
				{
					continue ;
				}
				
				NSString *hairSource = [model getBundlePath];
				if ([fileManager fileExistsAtPath:hairSource])
				{
					[fileManager copyItemAtPath:hairSource toPath:[filePath stringByAppendingPathComponent:model.name] error:nil];
				}
			}
			// 拷贝发帽
			for (FUItemModel *model in self.itemsDict[TAG_FU_ITEM_HAIRHAT])
			{
				if ([model.name rangeOfString:@"noitem"].length > 0)
				{
					continue ;
				}
				
				NSString *hairSource = [model getBundlePath];
				if ([fileManager fileExistsAtPath:hairSource])
				{
					[fileManager copyItemAtPath:hairSource toPath:[filePath stringByAppendingPathComponent:model.name] error:nil];
				}
			}
		}
		
		[[FUManager shareInstance].avatarList insertObject:newAvatar atIndex:DefaultAvatarNum];
		[currentAvatar resetValueFromBeforeEditAvatar:self.beforeEditAvatar];
		[currentAvatar quitFacepupMode];
		[[FUManager shareInstance] reloadAvatarToControllerWithAvatar:newAvatar];
	}
	else
	{
		[self.currentAvatars.firstObject quitFacepupMode];
		[self.currentAvatars.firstObject loadAvatarColor];
		///拷贝头发
		BOOL shouldDeformHair = [[FUShapeParamsMode shareInstance]shouldDeformHair];
		
		if (shouldDeformHair)
		{
			[self createAndCopyHairBundlesWithAvatar:self.currentAvatars.firstObject withHairModel:self.currentAvatars.firstObject.hair];
		    [self createAndCopyHairHatBundlesWithAvatar:self.currentAvatars.firstObject withHairHatModel:self.currentAvatars.firstObject.hairHat];
		}
	}
}


#pragma mark ------ 颜色编辑相关 ------
/// 获取颜色选中字典
/// @param avatar 形象模型
- (NSMutableDictionary *)getSelectedColorIndexDictWithAvatar:(FUAvatar *)avatar
{
    NSMutableDictionary *selectedColorDict = [[NSMutableDictionary alloc]init];
    
    for (int i = 0; i < FUFigureColorTypeEnd; i++)
    {
        NSString *key = [[FUManager shareInstance]getColorKeyWithType:(FUFigureColorType)i];
        
        NSString *indexProKey = [key stringByReplacingOccurrencesOfString:@"_c" withString:@"C"];
        indexProKey = [indexProKey stringByReplacingOccurrencesOfString:@"_f" withString:@"F"];
        indexProKey = [indexProKey stringByAppendingString:@"Index"];
        
        NSInteger index = [[avatar valueForKey:indexProKey] integerValue];
        
        [selectedColorDict setValue:@(index) forKey:key];
    }
    
    return selectedColorDict;
}

- (FUP2AColor *)getSkinColorWithProgress:(double)progress
{
    NSInteger colorsCount = [[FUManager shareInstance] getColorArrayCountWithType:FUFigureColorTypeSkinColor];
    double step = 1.0/(colorsCount - 1);
    if (progress < 0)
        progress = 0;
    double colorIndexDouble = progress / step;
    int colorIndex = colorIndexDouble;
    
    FUP2AColor * baseColor = [[FUManager shareInstance] getColorWithType:FUFigureColorTypeSkinColor andIndex:colorIndex];
    
    UIColor * newColor;
    
    if (colorIndex >= colorsCount - 1)
    {
        newColor = baseColor.color;
    }
    else
    {
        FUP2AColor * nextColor = [[FUManager shareInstance] getColorWithType:FUFigureColorTypeSkinColor andIndex:colorIndex+1];
        double RStep = (nextColor.r - baseColor.r);
        double GStep = (nextColor.g - baseColor.g);
        double BStep = (nextColor.b - baseColor.b);
        double colorInterval = colorIndexDouble - colorIndex;
        newColor = [UIColor colorWithRed:(baseColor.r + RStep * colorInterval)/ 255.0 green:(baseColor.g + GStep * colorInterval)/ 255.0 blue:(baseColor.b + BStep * colorInterval)/ 255.0 alpha:1];
    }
    
    return [FUP2AColor color:newColor];
}

/// 根据类别获取选中的颜色编号
/// @param type 颜色类别
- (NSInteger)getSelectedColorIndexWithType:(FUFigureColorType)type
{
    return [[self.selectedColorDict objectForKey:[self getColorKeyWithType:type]] intValue]-1;
}

/// 根据类别获取选中的颜色
- (FUP2AColor *)getSelectedColorWithType:(FUFigureColorType)type
{
    NSArray *selectedColorArray = self.colorDict[[self getColorKeyWithType:type]];
    NSInteger index = [[self.selectedColorDict objectForKey:[self getColorKeyWithType:type]] intValue]-1;
    if (index >= 0)
    {
        FUP2AColor *color = [selectedColorArray objectAtIndex:index];
        return color;
    }

    return nil;
}

/// 设置对应类别的选中颜色编号
/// @param index 选中的颜色编号
/// @param type 颜色类别
- (void)setSelectColorIndex:(NSInteger)index ofType:(FUFigureColorType)type
{
    [self.selectedColorDict setValue:@(index+1) forKey:[self getColorKeyWithType:type]];
}

/// 根据类别获取对应颜色数组的长度
/// @param type 颜色类别
- (NSInteger)getColorArrayCountWithType:(FUFigureColorType)type
{
    NSArray *array = self.colorDict[[self getColorKeyWithType:type]];

    return array.count;
}

/// 根据类别获取对应颜色数组
/// @param type 颜色类别
- (NSArray *)getColorArrayWithType:(FUFigureColorType)type
{
    return self.colorDict[[self getColorKeyWithType:type]];
}

/// 根据颜色类别获取颜色类别关键字
/// @param type 颜色类别
- (NSString *)getColorKeyWithType:(FUFigureColorType)type
{
    NSString *key;
    
    switch (type)
    {
        case FUFigureColorTypeSkinColor:
            key = @"skin_color";
            break;
        case FUFigureColorTypeLipsColor:
            key = @"lip_color";
            break;
        case FUFigureColorTypeirisColor:
            key = @"iris_color";
            break;
        case FUFigureColorTypeHairColor:
            key = @"hair_color";
            break;
        case FUFigureColorTypeBeardColor:
            key = @"beard_color";
            break;
        case FUFigureColorTypeGlassesFrameColor:
            key = @"glass_frame_color";
            break;
        case FUFigureColorTypeGlassesColor:
            key = @"glass_color";
            break;
        case FUFigureColorTypeHatColor:
            key = @"hat_color";
            break;
        case FUFigureColorTypeEyebrowColor:
            key = @"eyebrow_color";
            break;
        case FUFigureColorTypeEyeshadowColor:
            key = @"eyeshadow_color";
            break;
        case FUFigureColorTypeEyelashColor:
            key = @"eyelash_color";
            break;
        default:
            break;
    }
    
    return key;
}

/// 获取颜色模型
/// @param type 颜色类别
/// @param index 颜色编号
- (FUP2AColor *)getColorWithType:(FUFigureColorType)type andIndex:(NSInteger)index
{
    FUP2AColor *color = [[self getColorArrayWithType:type]objectAtIndex:index];
    
    return color;
}


#pragma mark  ------ 生成形象 ------
/// 根据形象信息字典生成形象模型
/// @param dict 形象信息字典
- (FUAvatar *)getAvatarWithInfoDic:(NSDictionary *)dict
{
    FUAvatar *avatar = [[FUAvatar alloc] init];
    
    avatar.name = dict[@"name"];
    avatar.gender = (FUGender)[dict[@"gender"] intValue];
    avatar.defaultModel = [dict[@"default"] boolValue];
    
    avatar.isQType = [dict[@"q_type"] integerValue];
    avatar.clothType = (FUAvataClothType)[dict[@"clothType"] integerValue];
    avatar.hairType = (FUAvataHairType)[dict[@"hairType"] integerValue];
    
    avatar.clothes = [self getItemModelWithKey:TAG_FU_ITEM_CLOTH andDict:dict];
    avatar.upper = [self getItemModelWithKey:TAG_FU_ITEM_UPPER andDict:dict];
    avatar.lower = [self getItemModelWithKey:TAG_FU_ITEM_LOWER andDict:dict];
    avatar.hair = [self getItemModelWithKey:TAG_FU_ITEM_HAIR andDict:dict];
    avatar.face = [self getItemModelWithKey:TAG_FU_ITEM_FACE andDict:dict];
    avatar.eyes = [self getItemModelWithKey:TAG_FU_ITEM_EYE andDict:dict];
    avatar.mouth = [self getItemModelWithKey:TAG_FU_ITEM_MOUTH andDict:dict];
    avatar.nose = [self getItemModelWithKey:TAG_FU_ITEM_NOSE andDict:dict];
    avatar.shoes = [self getItemModelWithKey:TAG_FU_ITEM_SHOES andDict:dict];
    avatar.hat = [self getItemModelWithKey:TAG_FU_ITEM_HAT andDict:dict];
    avatar.eyeLash = [self getItemModelWithKey:TAG_FU_ITEM_EYELASH andDict:dict];
    avatar.eyeBrow = [self getItemModelWithKey:TAG_FU_ITEM_EYEBROW andDict:dict];
    avatar.beard = [self getItemModelWithKey:TAG_FU_ITEM_BEARD andDict:dict];
    avatar.glasses = [self getItemModelWithKey:TAG_FU_ITEM_GLASSES andDict:dict];
    avatar.eyeShadow = [self getItemModelWithKey:TAG_FU_ITEM_EYESHADOW andDict:dict];
    avatar.eyeLiner = [self getItemModelWithKey:TAG_FU_ITEM_EYELINER andDict:dict];
    avatar.pupil = [self getItemModelWithKey:TAG_FU_ITEM_PUPIL andDict:dict];
    avatar.faceMakeup = [self getItemModelWithKey:TAG_FU_ITEM_FACEMAKEUP andDict:dict];
    avatar.lipGloss = [self getItemModelWithKey:TAG_FU_ITEM_LIPGLOSS andDict:dict];
    // 配饰大类 多选
    avatar.decoration_shou = [self getItemModelWithKey:TAG_FU_ITEM_DECORATION_SHOU andDict:dict];
    avatar.decoration_jiao = [self getItemModelWithKey:TAG_FU_ITEM_DECORATION_JIAO andDict:dict];
    avatar.decoration_xianglian = [self getItemModelWithKey:TAG_FU_ITEM_DECORATION_XIANGLIAN andDict:dict];
    avatar.decoration_erhuan = [self getItemModelWithKey:TAG_FU_ITEM_DECORATION_ERHUAN andDict:dict];
    avatar.decoration_toushi = [self getItemModelWithKey:TAG_FU_ITEM_DECORATION_TOUSHI andDict:dict];
    
    avatar.hairHat = [self getItemModelWithKey:TAG_FU_ITEM_HAIRHAT andDict:dict];
    avatar.dress_2d = [self getItemModelWithKey:TAG_FU_ITEM_DRESS_2D andDict:dict];
    
    avatar.skinColorIndex = [self getIndexWithColorTypeKey:@"skin" andDict:dict];
    avatar.lipColorIndex = [self getIndexWithColorTypeKey:@"lip" andDict:dict];
    avatar.irisColorIndex = [self getIndexWithColorTypeKey:@"iris" andDict:dict];
    avatar.hairColorIndex = [self getIndexWithColorTypeKey:@"hair" andDict:dict];
    avatar.beardColorIndex = [self getIndexWithColorTypeKey:@"beard" andDict:dict];
    avatar.glassFrameColorIndex = [self getIndexWithColorTypeKey:@"glassFrame" andDict:dict] ;
    avatar.glassColorIndex = [self getIndexWithColorTypeKey:@"glass" andDict:dict];
    avatar.hatColorIndex = [self getIndexWithColorTypeKey:@"hat" andDict:dict];
    avatar.eyebrowColorIndex = [self getIndexWithColorTypeKey:@"eyebrow" andDict:dict];
    avatar.eyeshadowColorIndex = [self getIndexWithColorTypeKey:@"eyeshadow" andDict:dict];
    avatar.eyelashColorIndex = [self getIndexWithColorTypeKey:@"eyelash" andDict:dict];
    avatar.skinColorProgress = [dict[TAG_FU_SKIN_COLOR_PROGRESS] doubleValue];
    
    return avatar;
}

/**
 Avatar 生成
 
 @param data    服务端拉流数据
 @param name    Avatar 名字
 @param gender  Avatar 性别
 @return        生成的 Avatar
 */
- (FUAvatar *)createAvatarWithData:(NSData *)data avatarName:(NSString *)name gender:(FUGender)gender {
    
    isCreatingAvatar = YES;
    
    FUAvatar *avatar = [[FUAvatar alloc] init];
    avatar.defaultModel = NO;
    avatar.name = name;
    avatar.gender = gender;
    avatar.isQType = self.avatarStyle == FUAvatarStyleQ;
    
    
    [data writeToFile:[[avatar filePath] stringByAppendingPathComponent:FU_HEAD_BUNDLE] atomically:YES];
    [[fuPTAClient shareInstance] setHeadData:data];
    // 头发
    int hairLabel = [[fuPTAClient shareInstance] getInt:@"hair_label"];
    avatar.hairLabel = hairLabel;
    FUItemModel *defaultHairModel = [self gethairNameWithNum:hairLabel andGender:gender];
    avatar.hair = defaultHairModel;
    
    NSString *baseHairPath = [defaultHairModel getBundlePath];
    NSData *baseHairData = [NSData dataWithContentsOfFile:baseHairPath];
    NSData *defaultHairData = [[fuPTAClient shareInstance] createHairWithHeadData:data defaultHairData:baseHairData];
    NSString *defaultHairPath = [[avatar filePath] stringByAppendingPathComponent:avatar.hair.name];
    
    [defaultHairData writeToFile:defaultHairPath atomically:YES];
    [[fuPTAClient shareInstance] setHeadData:data];
    // 眼镜
    int hasGlass = [[fuPTAClient shareInstance] getInt:@"has_glasses"];
    //    avatar.glasses = hasGlass == 0 ? @"glasses-noitem" : (gender == FUGenderMale ? @"male_glass_1" : @"female_glass_1");
    if (hasGlass == 0)
    {
        avatar.glasses = self.itemsDict[TAG_FU_ITEM_GLASSES][0];
    }
    else
    {
        int shapeGlasses = [[fuPTAClient shareInstance] getInt:@"shape_glasses"];
        int rimGlasses = [[fuPTAClient shareInstance] getInt:@"rim_glasses"];
        if (avatar.isQType)
        {
                        avatar.glasses = [self getQGlassesNameWithShape:shapeGlasses rim:rimGlasses male:gender == FUGenderMale];
        }
        else
        {

                        avatar.glasses = [self getGlassesNameWithShape:shapeGlasses rim:rimGlasses male:gender == FUGenderMale];
        }
    }
    
    avatar.hat = self.itemsDict[TAG_FU_ITEM_UPPER][0];
    
    // avatar info
    NSMutableDictionary *avatarInfo = [NSMutableDictionary dictionaryWithCapacity:1];
	avatar.wearFemaleClothes = avatar.gender;
	if (avatar.gender == FUGenderMale) {
	    avatar.upper = self.itemsDict[TAG_FU_ITEM_UPPER][4];
		avatar.lower = self.itemsDict[TAG_FU_ITEM_LOWER][6];
		avatar.clothes = self.itemsDict[TAG_FU_ITEM_CLOTH][0];
		avatar.clothType = FUAvataClothTypeUpperAndLower;
	}else if (avatar.gender == FUGenderFemale)
	{
	    avatar.upper = self.itemsDict[TAG_FU_ITEM_UPPER][0];
		avatar.lower = self.itemsDict[TAG_FU_ITEM_LOWER][0];
		avatar.clothes = self.itemsDict[TAG_FU_ITEM_CLOTH][10];
		avatar.clothType = FUAvataClothTypeSuit;
	}
	avatar.shoes = self.itemsDict[TAG_FU_ITEM_SHOES][9];
    avatar.lipGloss = self.itemsDict[FUEditTypeKey(FUEditTypeMakeup)][10]; // 从美妆大类里面，取出口红
    // 背景
     avatar.dress_2d = self.itemsDict[TAG_FU_ITEM_DRESS_2D][1];
    // 胡子
    
    int beardLabel = [[fuPTAClient shareInstance] getInt:@"beard_label"];
    avatar.bearLabel = beardLabel;
    avatar.beard = [self getBeardNameWithNum:beardLabel Qtype:avatar.isQType male:avatar.gender == FUGenderMale];

    [avatarInfo setObject:@(0) forKey:@"default"];
    [avatarInfo setObject:@(avatar.isQType) forKey:@"q_type"];
    [avatarInfo setObject:name forKey:@"name"];
    [avatarInfo setObject:@(gender) forKey:@"gender"];

    [avatarInfo setObject:@(hairLabel) forKey:@"hair_label"];
    [avatarInfo setObject:avatar.hair.name forKey:@"hair"];
    [avatarInfo setObject:@(beardLabel) forKey:@"beard_label"];
    [avatarInfo setObject:avatar.beard.name forKey:@"beard"];
    
    [avatarInfo setObject:@(avatar.clothType) forKey:@"clothType"];
    [avatarInfo setObject:avatar.upper.name forKey:@"upper"];
    [avatarInfo setObject:avatar.lower.name forKey:@"lower"];
    [avatarInfo setObject:avatar.shoes.name forKey:@"shoes"];
    [avatarInfo setObject:avatar.hat.name forKey:@"hat"];
    [avatarInfo setObject:avatar.clothes.name forKey:@"clothes"];
    [avatarInfo setObject:avatar.glasses.name forKey:@"glasses"];
    [avatarInfo setObject:avatar.lipGloss.name forKey:@"lipGloss"];
	[avatarInfo setObject:avatar.dress_2d.name forKey:@"dress_2d"];
   
    [avatarInfo setValue:@(-1) forKey:@"skin_color_progress"];
    if (gender == FUGenderFemale)
    {
        [avatarInfo setValue:@(2) forKey:@"lipColorIndex"];
    }
    else
    {
        [avatarInfo setValue:@(7) forKey:@"lipColorIndex"];
    }
    
    NSString *avatarInfoPath = [[CurrentAvatarStylePath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
    NSData *avatarInfoData = [NSJSONSerialization dataWithJSONObject:avatarInfo options:NSJSONWritingPrettyPrinted error:nil];
    [avatarInfoData writeToFile:avatarInfoPath atomically:YES];
    appManager.localizeHairBundlesSuccess = false;
    
    [[fuPTAClient shareInstance] releaseHeadData];
    
    FUAvatar *newAvatar = [self getAvatarWithInfoDic:avatarInfo];
    [self createAndCopyHairBundlesWithAvatar:newAvatar withHairModel:avatar.hair];
    [self createAndCopyHairHatBundlesWithAvatar:newAvatar withHairHatModel:newAvatar.hairHat];
    
    return newAvatar;
}


/// 生成并复制头发到形象目录
/// @param avatar 形象模型
- (void)createAndCopyHairBundlesWithAvatar:(FUAvatar *)avatar withHairModel:(FUItemModel *)model
{
    NSString *headPath = [avatar.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
    NSData *headData = [NSData dataWithContentsOfFile:headPath];
    
    //获取文件路径
    NSString *filePath = [documentPath stringByAppendingPathComponent:avatar.name];
    
    NSString *hairPath = [model getBundlePath];
    NSData *hairData = [NSData dataWithContentsOfFile:hairPath];
    
    if (hairData != nil)
    {
        NSData *newHairData = [[fuPTAClient shareInstance]createHairWithHeadData:headData defaultHairData:hairData];
        NSString *newHairPath = [filePath stringByAppendingPathComponent:model.name];
        
        [newHairData writeToFile:newHairPath atomically:YES];
    }
}

/// 生成并复制头发到形象目录
/// @param avatar 形象模型
- (void)createAndCopyAllHairBundlesWithAvatar:(FUAvatar *)avatar
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *hairArray = self.itemsDict[TAG_FU_ITEM_HAIR];
        NSString *headPath = [avatar.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
        NSData *headData = [NSData dataWithContentsOfFile:headPath];
        
        //获取文件路径
        NSString *filePath = [documentPath stringByAppendingPathComponent:avatar.name];
        
        [hairArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            FUItemModel *enumModel = (FUItemModel *)obj;
            NSString *hairPath = [enumModel getBundlePath];
            NSData *hairData = [NSData dataWithContentsOfFile:hairPath];
            
            if (hairData != nil)
            {
                NSData *newHairData = [[fuPTAClient shareInstance]createHairWithHeadData:headData defaultHairData:hairData];
                NSString *newHairPath = [filePath stringByAppendingPathComponent:enumModel.name];
                
                [newHairData writeToFile:newHairPath atomically:YES];
            }
        }];
    });
}

/// 生成并复制发帽到形象目录
/// @param avatar 形象模型
- (void)createAndCopyHairHatBundlesWithAvatar:(FUAvatar *)avatar withHairHatModel:(FUItemModel *)model
{
    NSString *headPath = [avatar.filePath stringByAppendingPathComponent:FU_HEAD_BUNDLE];
    NSData *headData = [NSData dataWithContentsOfFile:headPath];
    
    //获取文件路径
    NSString *filePath = [documentPath stringByAppendingPathComponent:avatar.name];
    
    NSString *hairPath = [model getBundlePath];
    NSData *hairData = [NSData dataWithContentsOfFile:hairPath];
    
    if (hairData != nil)
    {
        NSData *newHairData = [[fuPTAClient shareInstance]createHairWithHeadData:headData defaultHairData:hairData];
        NSString *newHairPath = [filePath stringByAppendingPathComponent:model.name];
        
        [newHairData writeToFile:newHairPath atomically:YES];
    }
}

#pragma mark ------ 加载形象 ------
/// 加载形象
/// @param avatar 形象模型
- (void)reloadAvatarToControllerWithAvatar:(FUAvatar *)avatar
{
   [self reloadAvatarToControllerWithAvatar:avatar :YES];
}

/// 重新加载avatar的所有资源
/// @param avatar 目标avatar
/// @param isBg 是否渲染背景
- (void)reloadAvatarToControllerWithAvatar:(FUAvatar *)avatar :(BOOL)isBg
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    
    // 销毁上一个 avatar
    if (self.currentAvatars.count != 0)
    {
        FUAvatar *lastAvatar = self.currentAvatars.firstObject ;
        [lastAvatar destroyAvatarResouce];
        [self.currentAvatars removeObject:lastAvatar];
    }
    
    if (avatar == nil)
    {
        dispatch_semaphore_signal(self.signal) ;
        return ;
    }

    // 创建新的
    [avatar loadAvatarToControllerWith:isBg];
    [avatar openHairAnimation];
    mItems[2] = self.defalutQController ;
    
    // 保存到当前 render 列表里面
    [self.currentAvatars addObject:avatar];
    [avatar loadIdleModePose_NoSignal];

    dispatch_semaphore_signal(self.signal);
}
/**
 
 普通模式下 新增 Avatar render
 
 @param avatar 新增的 Avatar
 */
- (void)addRenderAvatar:(FUAvatar *)avatar {
   [self addRenderAvatar:avatar :YES];
}
/**
 
 普通模式下 新增 Avatar render
 
 @param avatar 新增的 Avatar
 */
- (void)addRenderAvatar:(FUAvatar *)avatar :(BOOL)isBg{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    
    // 创建新的
    [avatar loadAvatarToControllerWith:isBg];
    // 保存到当前 render 列表里面
    [self.currentAvatars addObject:avatar];
    
    mItems[2] = self.defalutQController;

    dispatch_semaphore_signal(self.signal);
}

/**
 普通模式下 删除 Avatar render
 
 @param avatar 需要删除的 avatar
 */
- (void)removeRenderAvatar:(FUAvatar *)avatar
{//gcz
    if (avatar == nil || ![self.currentAvatars containsObject:avatar])
    {
                return;
    }
    
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    [avatar setCurrentAvatarIndex:avatar.currentInstanceId];    // 设置当前avatar的nama序号，使所有的操作都基于当前avatar
    
    NSInteger index = [self.currentAvatars indexOfObject:avatar];
    
    [avatar destroyAvatarResouce];
    [self.currentAvatars removeObject:avatar];
    dispatch_semaphore_signal(self.signal);
}




/**
 在 AR滤镜 模式下切换 Avatar   不销毁controller
 
 @param avatar Avatar
 */
- (void)reloadRenderAvatarInARModeInSameController:(FUAvatar *)avatar {
    
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    
    // 销毁上一个 avatar
    if (self.currentAvatars.count != 0) {
        FUAvatar *lastAvatar = self.currentAvatars.firstObject;
        [lastAvatar destroyAvatarResouce];
        [self.currentAvatars removeObject:lastAvatar];
        arItems[0] = 0;
    }
    
    if (avatar == nil) {
        dispatch_semaphore_signal(self.signal);
        return;
    }
    
    arItems[0] = [avatar loadAvatarWithARMode];
    [avatar closeHairAnimation];
    // 保存到当前 render 列表里面
    [self.currentAvatars addObject:avatar];
    
    dispatch_semaphore_signal(self.signal);
}



#pragma mark ------ 数据处理 ------
/// 获取颜色编号
/// @param key 颜色类别
/// @param dict 形象信息字典
- (NSInteger)getIndexWithColorTypeKey:(NSString *)key andDict:(NSDictionary *)dict
{
    NSString *levelKey = [key stringByAppendingString:@"Level"];
    
    if ([dict.allKeys containsObject:levelKey])
    {
        return [dict[levelKey] integerValue];
    }
    
    NSString *indexKey = [key stringByAppendingString:@"ColorIndex"];
    
    if ([dict.allKeys containsObject:indexKey])
    {
        return [dict[indexKey] integerValue];
    }
    
    NSString *colorKey = [key stringByAppendingString:@"_color"];
    
    if ([dict.allKeys containsObject:colorKey])
    {
        FUP2AColor *color = [FUP2AColor colorWithDict:dict[colorKey]];
        NSArray *currentColorArray = self.colorDict[colorKey];
        
        __block NSInteger index = 0;
        
        [currentColorArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            FUP2AColor *enumColor = (FUP2AColor *)obj;
            
            if ([enumColor colorIsEqualTo:color])
            {
                index = idx;
                *stop = YES;
            }
        }];
        return index+1;
    }

    return 1;
}

/// 获取道具模型
/// @param key 道具类别
/// @param dict 形象信息字典
- (FUItemModel *)getItemModelWithKey:(NSString *)key andDict:(NSDictionary *)dict
{
	
	NSArray *array;
	if ([self.makeupTypeArray containsObject:key]){
		array = [FUManager shareInstance].itemsDict[FUEditTypeKey(FUEditTypeMakeup)];
	}else if ([self.decorationTypeArray containsObject:key]){
		array = [FUManager shareInstance].itemsDict[FUDecorationsString];
	}
	else {
		array = [FUManager shareInstance].itemsDict[key];
	}
	NSString *bundle = dict[key];
	
	if (bundle == nil)
	{
		return  array[0];
	}
	
	__block FUItemModel *model;
	
	[array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		
		FUItemModel *currentModel = (FUItemModel *)obj;
		
		if ([currentModel.name rangeOfString:bundle].length > 0)
		{
			model = currentModel;
			*stop = YES;
		}
	}];
	
	if (model == nil)
	{
		return array[0];
	}
	
	return model;
}


// 获取默认眼镜
- (FUItemModel *)getGlassesNameWithShape:(int)shape rim:(int)rim male:(BOOL)male{
    
    __block FUItemModel *model = self.itemsDict[TAG_FU_ITEM_GLASSES][0];
    NSString *glass;
    if (shape == 1 && rim == 0) {
        glass = male ? @"male_glass_1" : @"female_glass_1";
    }else if (shape == 0 && rim == 0){
        glass = male ? @"male_glass_2" : @"female_glass_2";
    }else if (shape == 1 && rim == 1){
        glass = male ? @"male_glass_8" : @"female_glass_8";
    }else if (shape == 1 && rim == 2){
        glass = male ? @"male_glass_15" : @"female_glass_15";
    }
    
    [self.itemsDict[TAG_FU_ITEM_GLASSES] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        FUItemModel *enumModel = (FUItemModel *)obj;
        
        if ([enumModel.name isEqualToString:glass])
        {
            model = enumModel;
            *stop = YES;
        }
        
    }];
    
    return model;
}

// 获取Q风格默认眼镜
- (FUItemModel *)getQGlassesNameWithShape:(int)shape rim:(int)rim male:(BOOL)male
{
    __block FUItemModel *model = self.itemsDict[TAG_FU_ITEM_GLASSES][0];
    
    NSString * glassesName = @"glass_13";
    
    if (shape == 1 && rim == 0)
    {
        glassesName = @"glass_14";
    }
    else if (shape == 0 && rim == 0)
    {
        glassesName = @"glass_2";
    }
    else if (shape == 1 && rim == 1)
    {
        glassesName = @"glass_8";
    }
    else if (shape == 1 && rim == 2)
    {
        glassesName = @"glass_15";
    }
    
    
    [self.itemsDict[TAG_FU_ITEM_GLASSES] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        FUItemModel *enumModel = (FUItemModel *)obj;
        
        if ([enumModel.name containsString:glassesName])
        {
            model = enumModel;
            *stop = YES;
        }
        
    }];
    
    return model;
}

- (FUItemModel *)gethairNameWithNum:(int)num andGender:(FUGender)g
{
    NSArray *hairArray = self.itemsDict[TAG_FU_ITEM_HAIR];
    FUItemModel *model = hairArray[0];
    
    NSMutableArray *matchHairArray = [[NSMutableArray alloc]init];

        [hairArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            FUItemModel *enumModel = (FUItemModel *)obj;
            
            if ([enumModel.gender_match integerValue] == g&&[enumModel.label containsObject:[NSNumber numberWithInt:num]])
            {
                [matchHairArray addObject:enumModel];
            }
        }];
    
    if (matchHairArray.count == 1)
    {
        model = matchHairArray[0];
    }
    else if (matchHairArray.count > 1)
    {
        model = matchHairArray[arc4random() % matchHairArray.count];
    }
    
    return model;
}

// 根据 beardLabel 获取 beard name
- (FUItemModel *)getBeardNameWithNum:(int)num Qtype:(BOOL)q male:(BOOL)male
{
    NSArray *beardArray = self.itemsDict[TAG_FU_ITEM_BEARD];
    FUItemModel *model = beardArray[0];
    
    NSMutableArray *matchBeardArray = [[NSMutableArray alloc]init];
    
    [beardArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        FUItemModel *enumModel = (FUItemModel *)obj;
        
        if ([enumModel.gender_match integerValue] == (male ? FUGenderMale : FUGenderFemale)&&[enumModel.label containsObject:[NSNumber numberWithInt:num]])
        {
            [matchBeardArray addObject:enumModel];
        }
    }];
    
    if (matchBeardArray.count == 1)
    {
        model = matchBeardArray[0];
    }
    else if (matchBeardArray.count == 1)
    {
        model = matchBeardArray[arc4random() % matchBeardArray.count];
    }
    
    return model;
}

#pragma mark ------ 拍照识别 ------
static float DetectionAngle = 20.0;
static float CenterScale = 0.3;
/**
 拍摄检测
 
 @return 检测结果
 */
- (NSString *)photoDetectionAction
{
    // 1、保证单人脸输入
    int faceNum = [FURenderer isTracking];
    if (faceNum != 1)
    {
        return @" 请保持1个人输入  ";
    }

    // 2、保证正脸
    float rotation[4];
    [FURenderer getFaceInfo:0 name:@"rotation" pret:rotation number:4];

    float xAngle = atanf(2 * (rotation[3] * rotation[0] + rotation[1] * rotation[2]) / (1 - 2 * (rotation[0] * rotation[0] + rotation[1] * rotation[1]))) * 180 / M_PI;
    float yAngle = asinf(2 * (rotation[1] * rotation[3] - rotation[0] * rotation[2])) * 180 / M_PI;
    float zAngle = atanf(2 * (rotation[3] * rotation[2] + rotation[0] * rotation[1]) / (1 - 2 * (rotation[1] * rotation[1] + rotation[2] * rotation[2]))) * 180 / M_PI;

    if (xAngle < -DetectionAngle || xAngle > DetectionAngle
        || yAngle < -DetectionAngle || yAngle > DetectionAngle
        || zAngle < -DetectionAngle || zAngle > DetectionAngle)
    {
        return @" 识别失败，需要人物正脸完整出镜哦~  ";
    }

    // 3、保证人脸在中心区域
    CGPoint faceCenter = [self getFaceCenterInFrameSize:frameSize];

    if (faceCenter.x < 0.5 - CenterScale / 2.0 || faceCenter.x > 0.5 + CenterScale / 2.0
        || faceCenter.y < 0.4 - CenterScale / 2.0 || faceCenter.y > 0.4 + CenterScale / 2.0)
    {
        return @" 请将人脸对准虚线框  ";
    }

    // 4、夸张表情
    float expression[46];
    [FURenderer getFaceInfo:0 name:@"expression" pret:expression number:46];
    for (int i = 0; i < 46; i ++)
    {
        if (expression[i] > 0.5)
        {
            return @" 请保持面部无夸张表情  ";
        }
    }

    // 5、光照均匀
    // 6、光照充足
    if (lightingValue < -1.0) {
        return @" 光线不充足  ";
    }
    
    return @" 完美  ";
}

/**
 获取人脸矩形框
 
 @return 人脸矩形框
 */
- (CGRect)getFaceRect
{
    float faceRect[4];
    int ret = [FURenderer getFaceInfo:0 name:@"face_rect" pret:faceRect number:4];
    if (!ret)
    {
        return CGRectZero;
    }
    // 计算出中心点的坐标值
    CGFloat centerX = (faceRect[0] + faceRect[2]) * 0.5;
    CGFloat centerY = (faceRect[1] + faceRect[3]) * 0.5;
    
    // 将坐标系转换成以左上角为原点的坐标系
    centerX = frameSize.width - centerX;
    centerY = frameSize.height - centerY;
    
    CGRect rect = CGRectZero;
    if (frameSize.width < frameSize.height)
    {
        CGFloat w = frameSize.width;
        rect.size = CGSizeMake(w, w);
        rect.origin = CGPointMake(0, centerY - w/2.0);
    }
    else
    {
        CGFloat w = frameSize.height;
        rect.size = CGSizeMake(w, w);
        rect.origin = CGPointMake(centerX - w / 2.0, 0);
    }
    
    CGPoint origin = rect.origin;
    if (origin.x < 0)
    {
        origin.x = 0;
    }
    if (origin.y < 0)
    {
        origin.y = 0;
    }
    rect.origin = origin;
    
    return rect;
}

/**获取图像中人脸中心点*/
- (CGPoint)getFaceCenterInFrameSize:(CGSize)frameSize
{
    static CGPoint preCenter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        preCenter = CGPointMake(0.49, 0.5);
    });
    
    // 获取人脸矩形框，坐标系原点为图像右下角，float数组为矩形框右下角及左上角两个点的x,y坐标（前两位为右下角的x,y信息，后两位为左上角的x,y信息）
    float faceRect[4];
    int ret = [FURenderer getFaceInfo:0 name:@"face_rect" pret:faceRect number:4];
//    [FURenderer faceCaptureGetResultFaceBbox:self.faceCapture faceN:0 buffer:faceRect length:4];
    
    if (ret == 0)
    {
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


#pragma mark ----- AR
/**
 进入 AR滤镜 模式
 -- 会切换 controller 所在句柄
 */
- (void)enterARMode
{
    if (self.currentAvatars.count != 0)
    {
        FUAvatar *avatar = self.currentAvatars.firstObject;
        int handle = [avatar getControllerHandle];
        arItems[0] = handle;
    }
}

/**
 设置最多识别人脸的个数
 
 @param num 最多识别人脸个数
 */
- (void)setMaxFaceNum:(int)num
{
    [FURenderer setMaxFaces:num];
}

/**
 切换 AR滤镜
 
 @param filePath AR滤镜 路径
 */
- (void)reloadARFilterWithPath:(NSString *)filePath
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    
    if (arItems[1] != 0) {
        [FURenderer destroyItem:arItems[1]];
        arItems[1] = 0;
    }
    
    if (filePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        dispatch_semaphore_signal(self.signal);
        return;
    }
    
    arItems[1] = [FURenderer itemWithContentsOfFile:filePath];
    
    dispatch_semaphore_signal(self.signal);
}


/**
 在正常渲染avatar的模式下，切换AR滤镜
 
 @param filePath  滤镜 路径
 */
- (void)reloadFilterWithPath:(NSString *)filePath
{
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER);
    
    if (mItems[3] != 0)
    {
        [FURenderer destroyItem:mItems[3]];
        mItems[3] = 0;
    }
    
    if (filePath == nil || ![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        dispatch_semaphore_signal(self.signal);
        return;
    }
    
    mItems[3] = [FURenderer itemWithContentsOfFile:filePath];
    
    dispatch_semaphore_signal(self.signal);
}

#pragma mark ------ SET/GET
/// 设置形象风格
/// @param avatarStyle 形象风格
-(void)setAvatarStyle:(FUAvatarStyle)avatarStyle
{
    _avatarStyle = avatarStyle;
    [self loadSubData];
}

/*
 背景道具是否存在
 
 @return 是否存在
 */
- (BOOL)isBackgroundItemExist
{
    return q_controller_bg_ptr > 0;
}

-(NSString *)appVersion
{
    NSString* versionStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return [NSString stringWithFormat:@"DigiMe Art v%@",versionStr];
}

-(NSString *)sdkVersion
{
    NSString *version = [[fuPTAClient shareInstance] getVersion];
    return [NSString stringWithFormat:@"SDK v%@", version];
}

/// 设置instanceId
/// @param _id instanceId
-(void)setInstanceId:(int)_id{
  fuItemSetParamd([FUManager shareInstance].defalutQController , "current_instance_id",_id);
}
// 背景专用 instanceId
static int FUBackground_InstanceId = 0;
/// 设置背景的instanceId，用于多人模式下
-(void)setBackgroundInstanceId
{
   [self setInstanceId:FUBackground_InstanceId];
}

#pragma mark - 动画
static int ranNum = 0;
///  设置一个等待执行的特殊动画
- (void)setNextSpecialAnimation
{
	//随机从两个动画里抽取一个
	//int ranNum = arc4random()%3;
	if (ranNum == 0)
	{
		self.nextSpecialAni = @"ani_danshoubixin_mid.bundle";
	}
	else if (ranNum == 1)
	{
		self.nextSpecialAni = @"ani_hi_mid.bundle";
	}
	else
	{
		self.nextSpecialAni = @"ani_rock_mid.bundle";
	}
	ranNum++;
	if (ranNum > 2) {
		ranNum = 0;
	}
}

/// 清除正在等待执行的特殊动画
- (void)removeNextSpecialAnimation
{
    self.nextSpecialAni = nil;
}

/// 播放在等待中的特殊动画
- (void)playNextSpecialAnimation
{
    FUAvatar *avatar = self.currentAvatars.firstObject;
    NSString *animationPath = [[NSBundle mainBundle] pathForResource:self.nextSpecialAni ofType:nil];

    [avatar reloadAnimationWithPath:animationPath];
    [avatar playOnceAnimation];
    [[FUManager shareInstance] removeNextSpecialAnimation];
}

/// 立即播放一个特殊动画
- (void)playSpecialAnimation
{
    [[FUManager shareInstance] setNextSpecialAnimation];
    [[FUManager shareInstance] playNextSpecialAnimation];
    [FUManager shareInstance].isPlayingSpecialAni = YES;
}


#pragma mark ----- 编辑
- (void)configEditInfo
{
    self.selectedEditType = FUEditTypeFace;
    self.subTypeSelectedDict = [[NSMutableDictionary alloc]init];
    for (NSString *type in self.typeInfoDict.allKeys)
    {
        [self.subTypeSelectedDict setValue:@(0) forKey:type];
    }
    self.isGlassesColor = NO;
}

- (NSArray *)getCurrentTypeArray
{
    FUEditTypeModel *model = self.typeInfoDict[FUEditTypeKey(self.selectedEditType)];
    NSArray *array = model.subTypeArray;
    return array;
}

- (NSString *)getSubTypeNameWithIndex:(NSInteger)index
{
    NSArray *array = [self getCurrentTypeArray];
    NSString *name = [array[index] valueForKey:@"name"];
    
    return name;
}

- (NSString *)getSubTypeKeyWithIndex:(NSInteger)index
{
    NSArray *array = [self getCurrentTypeArray];
    NSString *name = [array[index] valueForKey:@"type"];
    
    return name;
}

/// 从编辑大类里面获取子类的类型名称
/// @param index 子类在大类中的位置
/// @param array 大类数组
- (NSString *)getSubTypeKeyWithIndex:(NSInteger)index currentTypeArr:(NSArray *)array
{
    NSString *key = [array[index] valueForKey:@"type"];
    return key;
}


- (void)setSubTypeSelectedIndex:(NSInteger)index
{
   [self setSubTypeSelectedIndex:index withEditType:self.selectedEditType];
}
- (void)setSubTypeSelectedIndex:(NSInteger)index withEditType:(FUEditType)type
{
    [self.subTypeSelectedDict setValue:@(index) forKey:FUEditTypeKey(type)];
}
- (NSInteger)getSubTypeSelectedIndex
{
    return [[self.subTypeSelectedDict objectForKey:FUEditTypeKey(self.selectedEditType)] integerValue];
}
/// 美妆类型，当前选中的美妆
- (FUMakeupItemModel*)getMakeupCurrentSelectedModel
{
    if(!self.currentSelectedMakeupType) return nil;
    NSInteger index = [[self.selectedItemIndexDict objectForKey:self.currentSelectedMakeupType] integerValue];
    return [self getItemArrayOfSelectedSubType][index];
}

/// 获取当前类别的道具数组
- (NSArray *)getItemArrayOfSelectedSubType
{
	if (self.selectedEditType == FUEditTypeMakeup) {
		NSArray *array = [FUManager shareInstance].itemsDict[FUEditTypeKey(self.selectedEditType)];
		return array;
	}
	NSString *type = [self getSubTypeKeyWithIndex:[self getSubTypeSelectedIndex]];
	NSArray *array = [FUManager shareInstance].itemsDict[type];
	return array;
}
/// 获取美妆选中的道具编号  多选
- (NSArray<NSNumber*>*)getSelectedItemIndexOfMakeup
{
	NSMutableArray<NSNumber*>* tmpSeletedArray = [NSMutableArray array];
	if (!self.selectedItemIndexDict)
	{
		[self getSelectedItemIndexDictWithAvatar:self.currentAvatars.lastObject];
	}
	
	for (NSString * type in self.makeupTypeArray) {
		NSInteger index = [[self.selectedItemIndexDict objectForKey:type] integerValue];
		[tmpSeletedArray addObject:@(index)];
	}
	return tmpSeletedArray;
}
/// makeup 类型存在有效的选项
-(BOOL)makeupHasValiedSeletedItem{
	NSArray<NSNumber*>* seletedArray = [self getSelectedItemIndexOfMakeup];
	for (NSNumber*n in seletedArray) {
		if ([n intValue] > 0) {
			return YES;
		}
	}
	return NO;
}

/// 获取配饰选中的道具编号  多选
- (NSArray<NSNumber*>*)getSelectedItemIndexOfDecoration
{
	NSMutableArray<NSNumber*>* tmpSeletedArray = [NSMutableArray array];
	if (!self.selectedItemIndexDict)
	{
		[self getSelectedItemIndexDictWithAvatar:self.currentAvatars.lastObject];
	}
	
	for (NSString * type in self.decorationTypeArray) {
		NSInteger index = [[self.selectedItemIndexDict objectForKey:type] integerValue];
		[tmpSeletedArray addObject:@(index)];
	}
	return tmpSeletedArray;
}
/// 配饰 类型存在有效的选项
-(BOOL)decorationHasValiedSeletedItem{
	NSArray<NSNumber*>* seletedArray = [self getSelectedItemIndexOfDecoration];
	for (NSNumber*n in seletedArray) {
		if ([n intValue] > 0) {
			return YES;
		}
	}
	return NO;
}

/// 获取当前类别选中的道具编号
- (NSInteger)getSelectedItemIndexOfSelectedSubType
{
    NSString *type = [self getSubTypeKeyWithIndex:[self getSubTypeSelectedIndex]];
    
    if (!self.selectedItemIndexDict)
    {
        [self getSelectedItemIndexDictWithAvatar:self.currentAvatars.lastObject];
    }
    
    NSInteger index = [[self.selectedItemIndexDict objectForKey:type] integerValue];
    
    return index;
}


/// 获取道具选中字典
/// @param avatar 形象模型
- (NSMutableDictionary *)getSelectedItemIndexDictWithAvatar:(FUAvatar *)avatar
{
    NSMutableDictionary *selectedItemIndexDict = [[NSMutableDictionary alloc]init];
    
    [self.itemTypeArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        FUItemModel *model = [[FUItemModel alloc]init];

		model = [avatar valueForKey:obj];
	
        
        NSArray *modelArray = self.itemsDict[obj];
        
        NSInteger index = [modelArray containsObject:model]?[modelArray indexOfObject:model]:0;
        
        [selectedItemIndexDict setObject:@(index) forKey:obj];
    }];
    [self.makeupTypeArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        FUMakeupItemModel *model = [[FUMakeupItemModel alloc]init];

		model = [avatar valueForKey:obj];
        
        
        NSArray *modelArray = self.itemsDict[FUEditTypeKey(FUEditTypeMakeup)];
        
        NSInteger index = [modelArray containsObject:model]?[modelArray indexOfObject:model]:0;
        
        [selectedItemIndexDict setObject:@(index) forKey:obj];
    }];
    
    [self.decorationTypeArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        FUDecorationItemModel *model = [[FUDecorationItemModel alloc]init];
		model = [avatar valueForKey:obj];
        NSArray *modelArray = self.itemsDict[FUDecorationsString];
        NSInteger index = [modelArray containsObject:model]?[modelArray indexOfObject:model]:0;
        [selectedItemIndexDict setObject:@(index) forKey:obj];
    }];
    
    return selectedItemIndexDict;
}

/// 从编辑大类数组里面获取图片名称
/// @param index 子类在编辑大类中的序号
/// @param array 大类数组
- (NSString *)getSubTypeImageNameWithIndex:(NSInteger)index  currentTypeArr:(NSArray *)array
{
    NSString *type = [self getSubTypeKeyWithIndex:index currentTypeArr:array];
    NSString *imageName = [NSString stringWithFormat:@"icon_%@_%@",FUEditTypeKey(self.selectedEditType),type];
    return imageName;
}



/// 获取当前类别的捏脸model
- (FUItemModel *)getNieLianModelOfSelectedType
{
    NSArray *array = [self getItemArrayOfSelectedSubType];
    
    FUItemModel *model = array[0];
    
    return model;
}

/// 获取当前选中的道具类别
- (NSString *)getSelectedType
{
    NSString *type = [self getSubTypeKeyWithIndex:[self getSubTypeSelectedIndex]];
    
    return type;
}

#pragma mark - Resolution

/// 设置输出精度与相机输入一致，目前相机设置为720*1280
- (void)setOutputResolutionAdjustCamera
{
    [[FURenderer shareRenderer] setOutputResolution:720 h:1280];
}
/// 根据屏幕尺寸设置输出精度
- (void)setOutputResolutionAdjustScreen
{
    
//    [[FUManager shareInstance]setOutputResolutionAdjustCamera];
    int width = (int)CVPixelBufferGetBytesPerRow(renderTarget)/4;
    int height = (int)CVPixelBufferGetHeight(renderTarget);

    [[FURenderer shareRenderer]setOutputResolution:width h:height];
}

/// 设置指定输出尺寸
/// @param width 指定图像宽
/// @param height 指定图像高
- (void)setOutputResolutionWithWidth:(CGFloat)width height:(CGFloat)height
{
    self.outPutSize = CGSizeMake(width, height);
    [[FURenderer shareRenderer]setOutputResolution:width h:height];
//    // 如果存在老的 bodyTrackBuffer ，则进行释放
    if (bodyTrackBuffer) CVPixelBufferRelease(bodyTrackBuffer);
	bodyTrackBuffer = [self createEmptyPixelBuffer:CGSizeMake(self.outPutSize.width, self.outPutSize.height)];
}

@end
