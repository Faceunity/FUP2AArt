//
//  FUTrackShowViewController.m
//  FUP2A
//
//  Created by Chen on 2020/4/8.
//  Copyright © 2020 L. All rights reserved.
//

#import "FUTrackShowViewController.h"

#define FU_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

@interface FUTrackShowViewController ()
{
    void * _human3dPtr;
}
//@property (nonatomic, strong) FUCamera *camera;
@property (strong, nonatomic) FUOpenGLView *renderView;
@property (nonatomic, strong) FUAvatar *currentAvatar;    // 当前选择的AR追踪 Avatar
@property (nonatomic, strong) AVURLAsset *urlAsset;
@property (nonatomic, strong) AVAssetReaderTrackOutput * mOutput;     // 视频输入源
@property (nonatomic, strong)  CADisplayLink * displayLink;
@property (nonatomic, strong) AVAssetReader * mReader;
@property (nonatomic, assign) FURenderMode renderMode;
@end

@implementation FUTrackShowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    NSData *human3dData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"human3d.bundle" ofType:nil]];
    
    frameIndex = 0;
    _human3dPtr = [FURenderer create3DBodyTracker:(void*)human3dData.bytes size:(int)human3dData.length];
    
    self.renderView = [[FUOpenGLView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:self.renderView];
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    self.currentAvatar = avatar;
    [[FUManager shareInstance] reloadAvatarToControllerWithAvatar:self.currentAvatar];
    [[FUManager shareInstance] loadDefaultBackGroundToController];
    // 当前avatar 进入AR模式，用于身体追踪和ARFilter
    BOOL faceSwitch = [[[NSUserDefaults standardUserDefaults]valueForKey:@"faceSwitch"] boolValue];
    BOOL bodySwitch = [[[NSUserDefaults standardUserDefaults]valueForKey:@"bodySwitch"] boolValue];
    BOOL followSwitch = [[[NSUserDefaults standardUserDefaults]valueForKey:@"followSwitch"] boolValue];
    
    [self.currentAvatar closeHairAnimation];
    [self.currentAvatar enterTrackBodyMode];
    self.renderMode = faceSwitch?FURenderPreviewMode:FURenderCommonMode;
    bodySwitch?[self.currentAvatar loadFullAvatar]:[self.currentAvatar loadHalfAvatar];
    bodySwitch?[self.currentAvatar resetScaleToImportTrackBody]:[self.currentAvatar resetScaleToHalfBodyInput];
    followSwitch?[self.currentAvatar enterFollowBodyMode]:@"";
}

- (void)setIsLandscape:(BOOL)isLandscape
{
    _isLandscape = isLandscape;
    if (isLandscape)
    {
        [self forceOrientationLandscape];
        self.renderView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    }
    
    UIButton *btnCancel  = [[UIButton alloc]initWithFrame:CGRectMake(FU_SCREEN_WIDTH - 10 - 34, 20 + (appManager.isXFamily&&!isLandscape?24:0), 34, 34)];
    [btnCancel setImage:[UIImage imageNamed:@"icon_close_white"] forState:UIControlStateNormal];
    [btnCancel addTarget:self action:@selector(touchUpInsideBtnCancel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnCancel];
    
    UIButton *btnBack = [[UIButton alloc]initWithFrame:CGRectMake(10, 20 +(appManager.isXFamily&&!isLandscape?24:0), 34, 34)];
    [btnBack setImage:[UIImage imageNamed:@"AR-back"] forState:UIControlStateNormal];
    [btnBack addTarget:self action:@selector(touchUpInsideBtnBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnBack];

}

//支持旋转
 -(BOOL)shouldAutorotate{
     return YES;
 }

 //支持的方向 因为界面A我们只需要支持竖屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationLandscapeRight;
 }

// 横屏 home键在右边
-(void)forceOrientationLandscape
{
    //强制翻转屏幕，Home键在右边。
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationLandscapeRight) forKey:@"orientation"];
    //刷新
    [UIViewController attemptRotationToDeviceOrientation];
}

// 横屏 home键在右边
-(void)forceOrientationPortrait
{
    
    //强制翻转屏幕，Home键在右边。
    [[UIDevice currentDevice] setValue:@(UIDeviceOrientationPortrait) forKey:@"orientation"];
    //刷新
    [UIViewController attemptRotationToDeviceOrientation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (self.asset)
    {
        [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:nil resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
            
            NSURL *url = (NSURL *)[[(AVURLAsset *)avAsset URL] fileReferenceURL];
            NSLog(@"url = %@", [url absoluteString]);
            NSLog(@"url = %@", [url relativePath]);
            AVURLAsset *mAsset = [[AVURLAsset alloc] initWithURL:url options:NULL];
            self.urlAsset = mAsset;
            [self playLocalVideoWithTimer];
        }];
    }
    else
    {
        NSString *path = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/input_video/%@.mp4",self.strFileName];
        
        AVURLAsset *mAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:NULL];
        self.urlAsset = mAsset;
        [self playLocalVideoWithTimer];
    }
}


- (void)touchUpInsideBtnBack
{
    [self.currentAvatar quitTrackBodyMode];
    [self.mReader cancelReading];
    [self destroyDisplayLink];
    [self forceOrientationPortrait];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)touchUpInsideBtnCancel
{
    [self.currentAvatar quitTrackBodyMode];
    [self.mReader cancelReading];
    [self destroyDisplayLink];
    [self forceOrientationPortrait];
    [self popToViewControllerWithString:@"FUTrackController" animated:YES];
}

//回到指定类名的视图控制器
- (void)popToViewControllerWithString:(NSString *)vcString animated:(BOOL)animated
{
    NSArray *arrViewControllers = self.navigationController.viewControllers;
    
    [arrViewControllers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:NSClassFromString(vcString)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popToViewController:(UIViewController *)obj animated:animated];
                *stop = YES;
            });
        }
    }];
}

static int FrameNum = 0;
-(void)displayLinkMethod
{
    __weak typeof(self)weakSelf = self;
    // Copy the next sample buffer from the reader output.
    
    CMSampleBufferRef sampleBuffer = [self.mOutput copyNextSampleBuffer];
//    FrameNum ++;
//    if (FrameNum == 10){
//        CMTime time  = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//        float s = CMTimeGetSeconds(time);
//
//
//        NSLog(@"1---帧率是----::%f----%f",FrameNum / s,s);
//        int framePerSecond = FrameNum / s;
//        self.displayLink.preferredFramesPerSecond = framePerSecond;
//    }
    
    FrameNum ++;
    if (FrameNum == 10){
        CMTime time  = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        float s = CMTimeGetSeconds(time);
        
        
        NSLog(@"1---帧率是----::%f----%f",FrameNum / s,s);
        int framePerSecond = FrameNum / s;
        self.displayLink.preferredFramesPerSecond = framePerSecond;
        
    }

    if (sampleBuffer)
    {
        
        // Do something with sampleBuffer here.
        [weakSelf renderVideoSampleBuffer:sampleBuffer];
//        CFRelease(sampleBuffer);
        sampleBuffer = NULL;
    }
    else
    {
        // Find out why the asset reader output couldn't copy another sample buffer.
        if (self.mReader.status == AVAssetReaderStatusFailed)
        {
            NSError *failureError = self.mReader.error;
            // Handle the error here.
        }
        else if (self.mReader.status == AVAssetReaderStatusCompleted)
        {
            // The asset reader output has read all of its samples.
            [weakSelf.mReader cancelReading];
            [weakSelf destroyDisplayLink];
            [weakSelf playLocalVideoWithTimer];
        }
    }
}

- (void)destroyDisplayLink
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}

static int frameIndex = 0 ;

-(void)renderVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    __weak typeof(self)weakSelf = self;
    frameIndex = frameIndex +1 ;
    CVPixelBufferRef pixelBuffer;

    
    BOOL bodySwitch = [[[NSUserDefaults standardUserDefaults]valueForKey:@"bodySwitch"] boolValue];
    if (!bodySwitch&& frameIndex == 3)
    {
        [self.currentAvatar loadHalfAvatar];
        [self.currentAvatar resetScaleToHalfBodyInput];
    }
    pixelBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer) ;

    CVPixelBufferRef buffer = [[FUManager shareInstance]    renderARFilterItemWithBuffer:pixelBuffer ptr:_human3dPtr RenderMode:self.renderMode landscape:self.isLandscape view0ratio:0.5f resolution:1.0f];

    if (self.isLandscape) {
       // 画出 18 ： 16
        [weakSelf.renderView display18R16PixelBuffer:buffer withLandmarks:nil count:0 Mirr:NO];
    }else{
        [weakSelf.renderView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:NO];
    }
    
    CFRelease(buffer);
}

-(void)playLocalVideoWithTimer
{
    FrameNum = 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CADisplayLink * displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkMethod)];
        // 默认30，后面会根据视频的实际帧率进行调整
        displayLink.preferredFramesPerSecond = 30;
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = displayLink;
        
        NSError * error;
        AVAssetReader * mReader = [[AVAssetReader alloc] initWithAsset:self.urlAsset error:&error];
        NSLog(@"加载视频资源出错----------------------%@",error);
        NSArray * tracks = [self.urlAsset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *mTrack = [tracks objectAtIndex:0];
        
        NSDictionary * settingsDic = @{(id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary],(NSString*)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
        
        AVAssetReaderTrackOutput * mOutput = [[AVAssetReaderTrackOutput alloc]
                                              initWithTrack:mTrack outputSettings:settingsDic];
        mOutput.alwaysCopiesSampleData = NO;
        self.mOutput = mOutput;
        [mReader addOutput:self.mOutput];
        self.mReader = mReader;
        [mReader startReading];
    });
}


@end
