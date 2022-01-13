//
//  FUBodyTrackController.m
//  FUP2A
//
//  Created by Chen on 2020/4/2.
//  Copyright © 2020 L. All rights reserved.
//

#import "FUBodyTrackController.h"
#import "FUSwitch.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/PHCollection.h>
#import "FUPhotoListViewController.h"
#import "FUOrientationViewController.h"
#import "FURotation.h"
#import "FUTrackController.h"
@interface FUBodyTrackController ()<FUCameraDelegate,FUSwitchDelegate,FUPoseTrackViewDelegate,
FUPhotoListViewControllerDelegate
>
{
    BOOL isPreparing ;   // 是不是在准备中，如果在准备中，则停止相机的渲染
    BOOL _isVideoInput;             // 判断当前是否是视频输入
    BOOL _shouldBreakVideoInput;    // 是否打破视频的输入
}
@property (nonatomic, strong) FUCamera *camera;
@property (weak, nonatomic) IBOutlet FUOpenGLView *renderView;
@property (weak, nonatomic) IBOutlet FUOpenGLView *preView;
// preView 的宽
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *preViewW;
// preView 的高
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *preViewH;
// 根据 preViewW、preViewH 获取当前preView是否为竖屏状态
@property (nonatomic, assign,readonly) BOOL isPreViewPortrait;
@property (weak, nonatomic) IBOutlet UIButton *btnSetting;
@property (nonatomic, strong) FUAvatar *currentAvatar;    // 当前选择的AR追踪 Avatar
@property (weak, nonatomic) IBOutlet UILabel *lblBodyMode;
@property (weak, nonatomic) IBOutlet FUSwitch *faceSwitch;
@property (weak, nonatomic) IBOutlet FUSwitch *bodySwitch;
@property (weak, nonatomic) IBOutlet FUSwitch *followSwitch;
@property (nonatomic, assign) FURenderMode renderMode;
@property (weak, nonatomic) IBOutlet UIView *settingView;
@property (nonatomic, strong) FUAvatar *originalAvatar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *settingButtonConstraintBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *preViewConstraintBottom;
@property (nonatomic, assign) BOOL isFirstLoad;
// 视频资源位置
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, strong) AVURLAsset *urlAsset;
@property (nonatomic, strong) AVAssetReaderTrackOutput * mOutput;     // 视频输入源
@property (nonatomic, assign)UIImageOrientation currentLoacalVideoOrientation; // 当前加载的本地视频的方向
@property (nonatomic, strong)  CADisplayLink * displayLink;
@property (nonatomic, strong) AVAssetReader * mReader;
@property (nonatomic, assign) BOOL isInputing;


@property (nonatomic, strong) dispatch_semaphore_t Signal;
@end

@implementation FUBodyTrackController
-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

    }
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        

    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.isFirstLoad = YES;
    // Do any additional setup after loading the view.
    [[FUManager shareInstance] loadPoseTrackAnim];
    self.poseTrackView.delegate = self;
    self.settingView.hidden = YES;
    self.renderMode = FURenderPreviewMode;
    self.Signal = dispatch_semaphore_create(1);
    [self configSwitch];
    [self addObserver];
}

- (void)configSwitch
{
    self.followSwitch.delegate = self;
    
    self.bodySwitch.delegate = self;
    self.bodySwitch.offColor = UIColorFromRGB(0x1890FF);
    self.bodySwitch.onColor = UIColorFromRGB(0x1890FF);
    self.bodySwitch.onTitle = @"全";
    self.bodySwitch.offTitle = @"半";
    self.bodySwitch.on = YES;
    
    self.faceSwitch.on = YES;
    self.faceSwitch.delegate = self;
}

- (void)resetCam
{
    if (self.bodySwitch.on)
    {
        self.poseTrackView.hidden?[self.currentAvatar resetScaleToTrackBodyWithoutToolBar]:[self.currentAvatar resetScaleToTrackBodyWithToolBar];
    }
    else
    {
        [self.currentAvatar resetScaleToHalfBodyWithToolBar];
    }
}


- (void)PoseTrackViewDidSelectedAvatar:(FUAvatar *)avatar
{

	[[FUManager shareInstance] reloadAvatarToControllerWithAvatar:avatar :NO];

	self.currentAvatar = avatar;
    [self.currentAvatar enableHumanAnimDriver:YES];
	if (!self.bodySwitch.on)
	{
		[self.currentAvatar loadHalfAvatar];
		// 调整半身驱动时，avatar的位置
		if (!self.followSwitch.on)
		[self resetCam];
	}
	else
	{
		// 加载全身
		[self.currentAvatar loadFullAvatar];
		// 调整全身驱动时，avatar的位置
		if (!self.followSwitch.on)
		[self resetCam];
	}
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.camera startCapture];
        
    
    if (!self.isFirstLoad)
    {
        if (!self.bodySwitch.on)
        {
            self.lblBodyMode.text = @"半身驱动";
            [self.currentAvatar loadHalfAvatar];
            // 调整半身驱动时，avatar的位置
            [self resetCam];
        }
        else
        {
            self.lblBodyMode.text = @"全身驱动";
            // 加载全身
            [self.currentAvatar loadFullAvatar];
            // 调整全身驱动时，avatar的位置
            [self resetCam];
        }
    }
}

- (void)PoseTrackViewDidSelectedInput:(NSString *)filterName
{
    if ([filterName isEqualToString:@"live"])
    {
        // 刷新 UI
        [self.poseTrackView freshInputIndex:0];
		// 相机输入则设置控件为竖屏视频
		[self sethPreViewOrientation:YES];
        [self.mReader cancelReading];
        [self destroyDisplayLink];
        _isVideoInput = NO;
        [self.camera startCapture];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:@(self.bodySwitch.on) forKey:@"bodySwitch"];
    [[NSUserDefaults standardUserDefaults] setValue:@(self.faceSwitch.on) forKey:@"faceSwitch"];
    [[NSUserDefaults standardUserDefaults] setValue:@(self.followSwitch.on) forKey:@"followSwitch"];
    
    if ([filterName isEqualToString:@"album"])
    {
        
        self.isFirstLoad = NO;
        FUPhotoListViewController *vc = [[FUPhotoListViewController alloc]init];
        vc.assetDelegate = self;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else
    {
        // 刷新 UI
        [self.poseTrackView freshInputIndex:2];
        _isVideoInput = YES;
        self.isFirstLoad = NO;
        [self.camera stopCapture];
        
        [self.mReader cancelReading];
        [self destroyDisplayLink];
        NSString *path = [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/input_video/%@.mp4",filterName];
        
        AVURLAsset *mAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:NULL];
        self.urlAsset = mAsset;
        self.isInputing = YES;
        self.currentLoacalVideoOrientation = UIImageOrientationUp;
        [self playLocalVideoWithTimer];
        // 预制视频输入则设置控件为横屏视频
        [self sethPreViewOrientation:NO];
        
    }
}


- (void)setRenderMode:(FURenderMode)renderMode
{
    _renderMode = renderMode;
    self.faceSwitch.on = _renderMode == FURenderPreviewMode;

    [[FUManager shareInstance]enableFaceCapture:renderMode ==FURenderPreviewMode];

}

- (void)switchView:(FUSwitch *)switchView isOn:(BOOL)on
{
    if (switchView == self.bodySwitch)
    {
        if (!on)
        {
            self.lblBodyMode.text = @"半身驱动";
            [self.currentAvatar loadHalfAvatar];
            // 调整半身驱动时，avatar的位置
            [self resetCam];
        }
        else
        {
            self.lblBodyMode.text = @"全身驱动";
            // 加载全身
            [self.currentAvatar loadFullAvatar];
            // 调整全身驱动时，avatar的位置
            [self resetCam];
            
        }
    }
    else if (switchView == self.faceSwitch)
    {
        self.renderMode = self.faceSwitch.on?FURenderPreviewMode:FURenderCommonMode;
    }
    else if (switchView == self.followSwitch)
    {
        if (on)
        {
        }
        else
        {
            [self resetCam];
        }
    }
}

-(void)setIsShow:(BOOL)isShow
{
    _isShow = isShow;
    if (isShow)
    {
        isPreparing = NO;
        [[FUManager shareInstance]setOutputResolutionWithWidth:720 height:1280];
        [[FUManager shareInstance] loadDefaultBackGroundToController];
        [self PoseTrackViewDidSelectedInput:@"live"];
        FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
        self.currentAvatar = avatar ;
        self.originalAvatar = avatar;
        // 1.即将进入AR滤镜，加载处理头发的道具
        [[FUManager shareInstance] destoryHairMask];
        // 2.解绑定身体、上衣、裤子、鞋子资源，只保留头部的一些素材
        [[FUManager shareInstance]reloadAvatarToControllerWithAvatar:self.currentAvatar : NO];
        [self.poseTrackView selectedModeWith:self.currentAvatar];
        [[FUManager shareInstance]enableHuman3D:1];
        // 5.向nama设置enter_ar_mode为1，进入AR滤镜模式
      //  [self.currentAvatar closeHairAnimation];
        // 当前avatar 进入AR模式，用于身体追踪和ARFilter
        [self.currentAvatar enableHumanAnimDriver:YES];

        if (self.followSwitch.on)
        {
        }

		[self setRenderMode:self.faceSwitch.on ? FURenderPreviewMode : FURenderCommonMode];

        
        if (!self.bodySwitch.on)
        {
            self.lblBodyMode.text = @"半身驱动";
            [self.currentAvatar loadHalfAvatar];
            // 调整半身驱动时，avatar的位置
            [self resetCam];
        }
        else
        {
            self.lblBodyMode.text = @"全身驱动";
            // 加载全身
            [self.currentAvatar loadFullAvatar];
            // 调整全身驱动时，avatar的位置
            [self resetCam];
        }
        [self.camera startCapture];
    }
    else
    {
        isPreparing = YES;
        [self destroyDisplayLink];
        [self.camera stopCapture];
        [self.currentAvatar quitARMode];
        [[FUManager shareInstance]enableHuman3D:0];
        [[FUManager shareInstance]enableFaceCapture:0];
    }
}
/// 当前 self.preView 是否为横屏
-(BOOL)isPreViewPortrait{
   return self.preViewW.constant < self.preViewH.constant;
}

/// 设置 self.preView控件的方向
/// @param portrait YES为竖屏，NO为横屏
-(void)sethPreViewOrientation:(BOOL)portrait
{
    __weak FUBodyTrackController * weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
	CGFloat tmp = 0;
	if ((portrait && !weakSelf.isPreViewPortrait) || (!portrait && weakSelf.isPreViewPortrait)) {
		tmp = weakSelf.preViewH.constant;
		weakSelf.preViewH.constant = weakSelf.preViewW.constant;
		weakSelf.preViewW.constant = tmp;
	}
	});
}

/**
 FUCameraDelegate的代理方法，用来输出相机CMSampleBufferRef 对象
 
 @param sampleBuffer sampleBuffer相机输出的buffer
 */
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	dispatch_semaphore_wait(self.Signal, DISPATCH_TIME_FOREVER);
	if (isPreparing) {
        dispatch_semaphore_signal(self.Signal);
        return;
    };
	CVPixelBufferRef pixelBuffer;
	
	pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferRef preview_Buffer = [[FUManager shareInstance]copyPixelBuffer:pixelBuffer];
	const int landmarks_cnt = 314;
	float landmarks[landmarks_cnt] ;
	CVPixelBufferRef buffer;
	if (self.camera.isFrontCamera)
	{
		CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
		[[FUManager shareInstance]renderBodyTrackWithBuffer:mirrored_pixel RenderMode:self.renderMode Landmarks:landmarks LandmarksLength:landmarks_cnt];
		[self.renderView displayPixelBuffer:mirrored_pixel withLandmarks:nil count:0 Mirr:NO];
		CVPixelBufferRelease(mirrored_pixel);
	}else{
		[[FUManager shareInstance]renderBodyTrackWithBuffer:pixelBuffer RenderMode:self.renderMode Landmarks:landmarks LandmarksLength:landmarks_cnt];
		[self.renderView displayPixelBuffer:pixelBuffer withLandmarks:nil count:0 Mirr:NO];
	}
	
	[self.preView displayPixelBuffer:preview_Buffer withLandmarks:landmarks count:landmarks_cnt Mirr:self.camera.isFrontCamera];
	//    CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent()  - renderBeforeTime;
	////    NSLog(@"在身体追踪页耗时----::%f s",interval);
	
	CVPixelBufferRelease(preview_Buffer);
	dispatch_semaphore_signal(self.Signal);
}
-(void)cancelSelectVideo{
}
#pragma mark ==============================  播放 本地 视频  ====================================
-(void)selectedVideo:(PHAsset *)videoAsset{
	self.asset = videoAsset;
	if (self.asset)
	{
		_isVideoInput = YES;
		// 刷新 UI
		[self.poseTrackView freshInputIndex:1];
		// 本地视频加载成功后，关闭之前的输入方式
		[self.camera stopCapture];
		[self.mReader cancelReading];
		[self destroyDisplayLink];
		__weak FUBodyTrackController * weakSelf = self;
		[[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:nil resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
			NSURL *url = (NSURL *)[[(AVURLAsset *)avAsset URL] fileReferenceURL];
			NSLog(@"url = %@", [url absoluteString]);
			NSLog(@"url = %@", [url relativePath]);
            AVURLAsset *mAsset = (AVURLAsset *)avAsset;
			NSArray * tracks = [mAsset tracksWithMediaType:AVMediaTypeVideo];
			weakSelf.urlAsset = mAsset;
			AVAssetTrack *mTrack = [tracks objectAtIndex:0];
			CGSize size = mTrack.naturalSize;
			UIImageOrientation videoAssetOrientation  = UIImageOrientationUp;
			CGAffineTransform firstTransform = [mTrack preferredTransform];
			if(firstTransform.a == 0 && firstTransform.b == 1.0 && firstTransform.c == -1.0 && firstTransform.d == 0)
			{
				videoAssetOrientation= UIImageOrientationRight;
			}
			if(firstTransform.a == 0 && firstTransform.b == -1.0 && firstTransform.c == 1.0 && firstTransform.d == 0)
			{
				videoAssetOrientation =  UIImageOrientationLeft;
			}
			if(firstTransform.a == 1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == 1.0)
			{
				videoAssetOrientation =  UIImageOrientationUp;
			}
			if(firstTransform.a == -1.0 && firstTransform.b == 0 && firstTransform.c == 0 && firstTransform.d == -1.0)
			{
				videoAssetOrientation = UIImageOrientationDown;
			}
			weakSelf.currentLoacalVideoOrientation = videoAssetOrientation;
			
			CGRect videoRect = CGRectMake(0.0, 0.0, size.width, size.height);
			videoRect = CGRectApplyAffineTransform(videoRect,firstTransform);
			if (videoRect.size.height > videoRect.size.width)
			{
				// 竖屏视频
				NSLog(@"Portrait mode");
				[weakSelf sethPreViewOrientation:YES];
			}
			else if (videoRect.size.height < videoRect.size.width)
			{
				// 横屏视频
				NSLog(@"Landscape mode");
				[weakSelf sethPreViewOrientation:NO];
			}
			else
			{
				NSLog(@"Square mode");
			}
			[weakSelf playLocalVideoWithTimer];
		}];
	}
	else
	{
		[self.camera startCapture];
	}
}
static int FrameNum = 0;
-(void)playLocalVideoWithTimer
{
	FrameNum = 0;
	__weak typeof(self)weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		CADisplayLink * displayLink = [CADisplayLink displayLinkWithTarget:weakSelf selector:@selector(displayLinkMethod)];
		// 默认30，后面会根据视频的实际帧率进行调整
		if (@available(iOS 10.0, *)) {
			displayLink.preferredFramesPerSecond = 30;
		} else {
			// Fallback on earlier versions
			displayLink.frameInterval = 1/30.0;
		}
		[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		weakSelf.displayLink = displayLink;
		
		NSError * error;
		AVAssetReader * mReader = [[AVAssetReader alloc] initWithAsset:weakSelf.urlAsset error:&error];
		NSLog(@"加载视频资源出错----------------------%@",error);
		NSArray * tracks = [weakSelf.urlAsset tracksWithMediaType:AVMediaTypeVideo];
		AVAssetTrack *mTrack = [tracks objectAtIndex:0];
		NSDictionary * settingsDic = @{(id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary],(NSString*)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
		
		AVAssetReaderTrackOutput * mOutput = [[AVAssetReaderTrackOutput alloc]
											  initWithTrack:mTrack outputSettings:settingsDic];
		mOutput.alwaysCopiesSampleData = NO;
		weakSelf.mOutput = mOutput;
		[mReader addOutput:weakSelf.mOutput];
		weakSelf.mReader = mReader;
		[mReader startReading];
	});
}

-(void)displayLinkMethod
{
    CMSampleBufferRef sampleBuffer = [self.mOutput copyNextSampleBuffer];

    FrameNum ++;
    if (FrameNum == 10){
        CMTime time  = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        float s = CMTimeGetSeconds(time);
        
        NSLog(@"FUT1---帧率是----::%f----%f",FrameNum / s,s);
        int framePerSecond = FrameNum / s;
        self.displayLink.preferredFramesPerSecond = framePerSecond;
    }

    if (sampleBuffer)
    {
        
        // Do something with sampleBuffer here.
        [self renderVideoSampleBuffer:sampleBuffer];
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
            [self.mReader cancelReading];
            [self destroyDisplayLink];
            [self playLocalVideoWithTimer];
        }
    }
}


static int frameIndex = 0 ;
-(void)renderVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	__weak typeof(self)weakSelf = self;
	frameIndex = frameIndex +1 ;
	__block CVPixelBufferRef pixelBuffer;
	//pixelBuffer =  CMSampleBufferGetImageBuffer(sampleBuffer);
	switch (self.currentLoacalVideoOrientation) {
		case UIImageOrientationUp:
			pixelBuffer = [FURotation correctBufferOrientation:sampleBuffer withRotationConstant:0];
			break;
		case UIImageOrientationDown:
			pixelBuffer = [FURotation correctBufferOrientation:sampleBuffer withRotationConstant:2];
			break;
		case UIImageOrientationLeft:
			pixelBuffer = [FURotation correctBufferOrientation:sampleBuffer withRotationConstant:1];
			break;
		case UIImageOrientationRight:
			pixelBuffer = [FURotation correctBufferOrientation:sampleBuffer withRotationConstant:3];
			break;
			
		default:
			pixelBuffer = [FURotation correctBufferOrientation:sampleBuffer withRotationConstant:0];
			break;
	}
	
	BOOL bodySwitch = [[[NSUserDefaults standardUserDefaults]valueForKey:@"bodySwitch"] boolValue];
	if (!bodySwitch&& frameIndex == 3)
	{
		[self.currentAvatar loadHalfAvatar];
		[self resetCam];
	}
	const int landmarks_cnt = 0;
	float landmarks[landmarks_cnt] ;
	CVPixelBufferRef buffer;
	if (0)
	{
		CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
		buffer = [[FUManager shareInstance]renderBodyTrackAdjustAssginOutputSizeWithBuffer:mirrored_pixel RenderMode:self.renderMode Landmarks:landmarks LandmarksLength:landmarks_cnt];
		CVPixelBufferRelease(mirrored_pixel);
	}else{
		buffer = [[FUManager shareInstance]renderBodyTrackAdjustAssginOutputSizeWithBuffer:pixelBuffer RenderMode:self.renderMode Landmarks:landmarks LandmarksLength:landmarks_cnt];
	}
	[weakSelf.renderView displayPixelBuffer:buffer withLandmarks:nil count:landmarks_cnt Mirr:NO];
	// ShouldSpreadScreen:NO 代表不铺满全屏，根据视频尺寸不同，可能或显示黑边
	[weakSelf.preView displayPixelBuffer:pixelBuffer withLandmarks:landmarks count:landmarks_cnt bufferMirr:NO landmarksMirr:YES ShouldSpreadScreen:NO];
	CVPixelBufferRelease(pixelBuffer);
	//    CVPixelBufferRelease(buffer);
	// 销毁 sampleBuffer
	switch (self.currentLoacalVideoOrientation) {
		case UIImageOrientationUp:
			break;
		case UIImageOrientationDown:
			CFRelease(sampleBuffer);
			break;
		case UIImageOrientationLeft:
			CFRelease(sampleBuffer);
			break;
		case UIImageOrientationRight:
			CFRelease(sampleBuffer);
			break;
			
		default:
			break;
	}
}


- (void)destroyDisplayLink
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}



#pragma mark ----- Event ------
- (IBAction)touchUpInsideBtnSetting:(id)sender
{
    self.settingView.hidden = !self.settingView.hidden;
}

- (IBAction)touchUpInsideBtnBack:(id)sender
{
    isPreparing = YES;
    [self.camera stopCapture];
    [self.mReader cancelReading];
    [self destroyDisplayLink];

    [self.currentAvatar enableHumanAnimDriver:NO];
    [self.currentAvatar quitARMode];
    [[FUManager shareInstance]enableFaceCapture:0];
    [[FUManager shareInstance]enableHuman3D:0];
    [[FUManager shareInstance] reloadAvatarToControllerWithAvatar:self.originalAvatar];
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)touchUpInsideBtnCamera:(id)sender
{
	if (_isVideoInput) {   // 视频输入，禁止切换摄像头  //@"当前相机不支持旋转相机"
		[SVProgressHUD showInfoWithStatus:@"当前模式不支持旋转相机"];
	}else{
        [self.camera stopCapture];
		self.camera.shouldMirror = !self.camera.shouldMirror ;
		[self.camera changeCameraInputDeviceisFront:!self.camera.isFrontCamera];
//		[[FUManager shareInstance] faceCapureReset];
        [self.camera startCapture];
	}
}



-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    UITouch *touch = [touches anyObject];
    
    if (!CGRectContainsPoint(self.settingView.frame, [touch locationInView:self.view]))
    {
      [self hideOrShowPoseTrackView];
    }
}
-(void)hideOrShowPoseTrackView{
   self.poseTrackView.hidden = !self.poseTrackView.hidden;
   
   [self resetCam];
   self.touchBlock(self.poseTrackView.hidden);
   [self resetBottom];
}

- (void)resetBottom
{
    if (self.poseTrackView.hidden)
    {
        self.preViewConstraintBottom.constant = -66;
        self.settingButtonConstraintBottom.constant = -56;
    }
    else
    {
        self.preViewConstraintBottom.constant = -171;
        self.settingButtonConstraintBottom.constant = -161;
    }
}

-(FUCamera *)camera {
    if (!_camera) {
        _camera = [[FUCamera alloc] init];
        _camera.delegate = self ;
        _camera.shouldMirror = NO ;
        [_camera changeCameraInputDeviceisFront:YES];
        //        frontCamera = YES ;
    }
    return _camera ;
}
#pragma mark --- Observer

- (void)addObserver{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}


- (void)willResignActive    {
	if ([self.navigationController.visibleViewController isKindOfClass:[FUTrackController class]]) {
		if (_isVideoInput) {
			[self.mReader cancelReading];
			[self destroyDisplayLink];
		}
	}
}

- (void)willEnterForeground {
	

}

- (void)didBecomeActive {
	
	if ([self.navigationController.visibleViewController isKindOfClass:[FUTrackController class]]) {
	// 视频播放进入后台可能会中断，这里重启
		if (_isVideoInput) {
			[self playLocalVideoWithTimer];
		}
	}
}


-(void)dealloc{
    NSLog(@"FUBodyTrackController-----销毁了");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
