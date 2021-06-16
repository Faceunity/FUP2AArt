//
//  ViewController.m
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import "ViewController.h"
#import "FUTakePhotoController.h"
#import "FUEditViewController.h"
// views
#import "FUHomeBarView.h"
#import "FUHistoryViewController.h"

@interface ViewController ()<
FUCameraDelegate,
UIGestureRecognizerDelegate,
FUHomeBarViewDelegate,
FUHistoryViewControllerDelegate
>
{
    CGFloat preScale; // 捏合比例
    CGFloat _rotDelta;
    FURenderMode renderMode;
    BOOL loadingBundles;
}

@property (nonatomic, strong) FUCamera *camera;
@property (weak, nonatomic) IBOutlet FUOpenGLView *displayView;
@property (weak, nonatomic) IBOutlet FUOpenGLView *preView;

// views
@property (nonatomic, strong) FUHomeBarView *homeBar;
@property (weak, nonatomic) IBOutlet UIButton *trackBtn;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImage;
@property (weak, nonatomic) IBOutlet UILabel *pointLabel;
@property (nonatomic, strong) NSTimer *labelTimer;
@property (nonatomic, assign) FUVideoRecordState videoRecordState;   // 录制视频的状态
@property (nonatomic, strong) FUAvatar *currentAvatar;

// 版本号  view
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionLabel;

@end

@implementation ViewController
{
    BOOL firstLoad;// 首次进入页面
    CRender * _viewRender;
    CRender * _recordRender;
}
-(instancetype)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
	}
	return self;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _viewRender = [[CRender alloc]init];
    _recordRender = [[CRender alloc]init];
    _rotDelta = 1;
    [self addObserver];
    
    firstLoad = YES;
    
    renderMode = FURenderCommonMode;
    [self.camera startCapture];
    
    [self showAppAndSDKVersion];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[FUManager shareInstance] bindPlaneShadow];
    [[FUManager shareInstance] setOutputResolutionAdjustScreen];
    [[FUManager shareInstance] reloadCamItemWithPath:nil];
    
    if ([FUManager shareInstance].currentAvatars.count == 0)
    {
        [[FUManager shareInstance]reloadAvatarToControllerWithAvatar:self.currentAvatar];
    }
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;

    if (firstLoad)
    {
        firstLoad = NO;
        [avatar resetScaleToSmallBody_UseCam];
    }
    else
    {

        
        
        [self.camera startCapture];
        
        
        if (self.homeBar.showTopView)
        {
            [avatar resetScaleToBody_UseCam];
            [avatar loadIdleModePose];
            
        }
        else
        {
            [avatar resetScaleToSmallBody_UseCam];
            [avatar loadStandbyAnimation];
        }
        if ([FUManager shareInstance].isEnterEditView)
        {
            frameIndex = 0;
            [FUManager shareInstance].isEnterEditView = NO;
          //  [avatar loadAfterEditAnimation];
            //[[FUManager shareInstance] setNextSpecialAnimation];
            [FUManager shareInstance].isPlayingSpecialAni = YES;
        }
        
        [self.homeBar reloadModeData];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	
	if (self.trackBtn.selected)   // 如果当前处于面部追踪状态，则关闭
	[self trackAction:self.trackBtn];
	
    [self.camera stopCapture];
    [FUManager shareInstance].isPlayingSpecialAni = NO;
    [[FUManager shareInstance] removeNextSpecialAnimation];
    [[FUManager shareInstance] reloadCamItemWithPath:nil];
    self.currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
    if (!self.preView.hidden)
    {
        self.appVersionLabel.hidden = NO;
        self.sdkVersionLabel.hidden = NO;
		
		
        self.preView.hidden = YES;
        
        FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
        // 加载默认动画
        [avatar loadStandbyAnimation];
        renderMode = FURenderCommonMode;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
    [avatar openHairAnimation];
    loadingBundles = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:@"FUHomeBar"])
    {
        UIViewController *itemsViewc = segue.destinationViewController;
        self.homeBar = (FUHomeBarView *)itemsViewc.view;
        self.homeBar.delegate = self;
    }
    else if ([identifier isEqualToString:@"PushToTakePicView"])
    {//拍照生成页tou
        [self.camera stopCapture];
    }
    else if ([identifier isEqualToString:@"PushToEditView"])
    {//形象编辑页
        [self.camera stopCapture];
        [FUManager shareInstance].isEnterEditView = YES;
    }
    else if ([identifier isEqualToString:@"PushToTrackVC"])
    {//AR驱动页面
        [self.camera stopCapture];
    }
    else if ([identifier isEqualToString:@"PushToHistoryVC"])
    {//形象管理列表
        FUHistoryViewController *historyView = segue.destinationViewController;
        historyView.mDelegate = self;
    }
}

- (void)loadDefaultAvatar
{
    loadingBundles = YES;
    FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
    [[FUManager shareInstance] reloadAvatarToControllerWithAvatar:avatar];
    [avatar loadStandbyAnimation];
    loadingBundles = NO;
}

#pragma mark ------ Event ------
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.homeBar.showTopView)
    {
        return;
    }
    
    if ([FUManager shareInstance].isPlayingSpecialAni == NO)
    {
        [[FUManager shareInstance] playSpecialAnimation];
    }
    else
    {
        [[FUManager shareInstance] setNextSpecialAnimation];
    }
    
}

// Avatar 旋转
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;

    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    
    CGFloat locationX = [touch locationInView:self.displayView].x;
    CGFloat preLocationX = [touch previousLocationInView:self.displayView].x;
    
    float dx = (locationX - preLocationX) / self.displayView.frame.size.width;
    
    [avatar resetRotDelta:dx];
    _rotDelta += dx;
}

- (IBAction)recordClick:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected)
    {
        self.videoRecordState = Recording;
    }
    else
    {
        self.videoRecordState = Completed;
    }
}

// track face
- (IBAction)trackAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    self.preView.hidden = !sender.selected;
    renderMode = sender.selected ? FURenderPreviewMode : FURenderCommonMode;
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    
    if (sender.selected)
    {
        [[FUManager shareInstance]enableFaceCapture:1];
        [avatar loadIdleModePose];
    }
    else
    {
        [[FUManager shareInstance]enableFaceCapture:0];
        [avatar loadStandbyAnimation];
    }
    self.appVersionLabel.hidden = sender.selected;
    self.sdkVersionLabel.hidden = sender.selected;
}

#pragma mark ------ SET/GET ------
- (FUCamera *)camera
{
    if (!_camera)
    {
        _camera = [[FUCamera alloc] init];
        _camera.delegate = self;
        _camera.shouldMirror = NO;
        [_camera changeCameraInputDeviceisFront:YES];
    }
    return _camera;
}

#pragma mark ---- FUCameraDelegate
static int frameIndex = 0;
CRender * viewRender;
- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (loadingBundles)
    {
        return;
    }
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    if (frameIndex == 0)
    {//从其他页面返回，重置动画，避免在页面加载过程耗时导致ok动画不正常
        [avatar restartAnimation];
    }

    //判断是否在执行特殊动画
    if ([FUManager shareInstance].isPlayingSpecialAni == YES&&frameIndex > 1)
    {
        float progress = [avatar getAnimateProgress];
        if (progress > 1)
        {//特殊动画执行完毕后
            if ([FUManager shareInstance].nextSpecialAni != nil)
            {//如果有下一个特殊动画,立即执行
                [[FUManager shareInstance]playNextSpecialAnimation];
            }
            else
            {//如果没有下一个特殊动画，执行默认动画
                [avatar loadStandbyAnimation];
                [FUManager shareInstance].isPlayingSpecialAni = NO;
            }
        }
    }
    
    frameIndex ++;
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
    const int landmarks_cnt = 314;
    float landmarks[landmarks_cnt] ;
    CFAbsoluteTime renderBeforeTime = CFAbsoluteTimeGetCurrent();
    CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:mirrored_pixel RenderMode:renderMode Landmarks:landmarks LandmarksLength:landmarks_cnt];
    CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - renderBeforeTime;
//    NSLog(@"在预览页耗时----::%f s",interval);
    CGSize size = [AppManager getSuitablePixelBufferSizeForCurrentDevice];
    
    [self.displayView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:NO];
    switch (self.videoRecordState)
    {
        case Original:
            
            break;
        case Recording:
        {
            CVPixelBufferRef mirrorYBuffer = [_recordRender cutoutPixelBuffer:buffer WithRect:CGRectMake(0, 0, size.width-200,size.height-200)];
            [[FUP2AHelper shareInstance] recordBufferWithType:FUP2AHelperRecordTypeVoicedVideo buffer:mirrorYBuffer sampleBuffer:sampleBuffer Completion:^(CFAbsoluteTime duration) {
                NSLog(@"当前帧返回时长-------------%f",duration);
            }];
        }
            break;
        case Completed:
        {
            
            [[FUP2AHelper shareInstance] stopRecordWithType:FUP2AHelperRecordTypeVoicedVideo TimeCompletion:^(NSString *retPath,CFAbsoluteTime duration) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"视频位置是------------------------%@",retPath);
                    NSLog(@"录制时长是------------------%f",duration);
                    [self saveRecordedVideo:retPath];
                });
            }];
            
            
            self.videoRecordState = Original;
        }
            break;
            
        default:
            break;
    }
    
    if (renderMode == FURenderPreviewMode)
    {
        [self.preView displayPixelBuffer:pixelBuffer withLandmarks:landmarks count:landmarks_cnt Mirr:YES];
    }
    CVPixelBufferRelease(mirrored_pixel);
}


- (void)saveRecordedVideo:(NSString *)videoPath
{
    [appManager checkSavePhotoAuth:^(PHAuthorizationStatus status){
        if (status == PHAuthorizationStatusAuthorized)
        {
            if (videoPath && [[NSFileManager defaultManager] fileExistsAtPath:videoPath])
            {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:videoPath]];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    
                    if(success && error == nil)
                    {
                        [SVProgressHUD showSuccessWithStatus:@"视频已保存到相册"];
                    }
                    else
                    {
                        [SVProgressHUD showErrorWithStatus:@"保存视频失败"];
                    }
                }];
            }
        }
        
        else if (status == PHAuthorizationStatusDenied)
        {
            UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:nil message:@"请打开你的权限！" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [appManager openAppSettingView];
            }];
            
            [alertVC addAction:certain];
            [self presentViewController:alertVC animated:YES completion:nil];
            
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark ---- FUHomeBarViewDelegate
- (void)homeBarViewShouldCreateAvatar
{
    [self performSegueWithIdentifier:@"PushToTakePicView" sender:nil];
}

- (void)homeBarViewShouldDeleteAvatar
{
    [self performSegueWithIdentifier:@"PushToHistoryVC" sender:nil];
}

// 风格切换
- (void)homeBarViewChangeAvatarStyle
{}

- (void)homeBarViewDidSelectedAvatar:(FUAvatar *)avatar
{
    [[FUManager shareInstance] reloadAvatarToControllerWithAvatar:avatar];
    switch (self->renderMode)
    {
        case FURenderCommonMode:
            if ([avatar.name isEqualToString:@"Star"])
            {  // 如果是明星模型
                [avatar load_ani_mg_Animation];
            }else
            {
                [avatar loadIdleModePose];
            }
            break;
        case FURenderPreviewMode:
            [avatar loadIdleModePose];
            [[FUManager shareInstance]enableFaceCapture:1];
            break;
    }
}

- (void)homeBarViewShouldShowTopView:(BOOL)show
{
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    
    if (show)
    {
        [avatar resetScaleToBody_UseCam];
        [avatar loadIdleModePose];
        [FUManager shareInstance].isPlayingSpecialAni = NO;
        [UIView animateWithDuration:0.5 animations:^{
            self.trackBtn.transform = CGAffineTransformMakeTranslation(0, -200);
        }];
    }
    else
    {
        if (!CGAffineTransformEqualToTransform(self.trackBtn.transform, CGAffineTransformIdentity))
        {
            [avatar loadStandbyAnimation];
            [avatar resetScaleToSmallBody_UseCam];
            [UIView animateWithDuration:0.5 animations:^{
                self.trackBtn.transform = CGAffineTransformIdentity;
            }];
        }
    }
}

- (void)homeBarSelectedActionWithAR:(BOOL)isAR
{
	FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
	if (isAR)
	{     // AR 滤镜
       // [[FUManager shareInstance]enableFaceCapture:0];
		[self performSegueWithIdentifier:@"PushToTrackVC" sender:nil];
	}
	else
	{         // 形象
		loadingBundles = YES;
		FUAvatar *currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
		if ([currentAvatar.name isEqualToString:@"Star"])
		{
			return;
		}
		[[FUManager shareInstance]enableFaceCapture:0];
		[FUManager shareInstance].isEnterEditView = YES;
		[self performSegueWithIdentifier:@"PushToEditView" sender:nil];
	}
}

// 合影
- (void)homeBarSelectedGroupBtn
{
    [self performSegueWithIdentifier:@"showGroupPhotoController" sender:nil];
}


#pragma mark ---- FUHistoryViewControllerDelegate
- (void)historyViewDidDeleteCurrentItem
{
    [self loadDefaultAvatar];
    [self.homeBar reloadModeData];
}

#pragma mark ---- loading action ~
- (void)startLoadingAnimation
{
    self.loadingView.hidden = NO;
    [self.view bringSubviewToFront:self.loadingView];
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:1];
    for (int i = 1; i < 33; i ++)
    {
        NSString *imageName = [NSString stringWithFormat:@"loading%d.png", i];
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        [images addObject:image];
    }
    self.loadingImage.animationImages = images;
    self.loadingImage.animationRepeatCount = 0;
    self.loadingImage.animationDuration = 2.0;
    [self.loadingImage startAnimating];
    
    self.labelTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(labelAnimation) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.labelTimer forMode:NSRunLoopCommonModes];
}

- (void)labelAnimation
{
    self.pointLabel.hidden = NO;
    static int count = 1;
    count ++;
    if (count == 4)
    {
        count = 1;
    }
    NSMutableString *str = [@"" mutableCopy];
    for (int i = 0; i < count; i ++)
    {
        [str appendString:@"."];
    }
    self.pointLabel.text = str;
    
}

- (void)stopLoadingAnimation
{
    self.loadingView.hidden = YES;
    [self.view sendSubviewToBack:self.loadingView];
    [self.labelTimer invalidate];
    self.labelTimer = nil;
    [self.loadingImage stopAnimating];
}

#pragma mark --- Observer
- (void)addObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)willResignActive
{
    if (self.navigationController.visibleViewController == self)
    {
        [self.camera stopCapture];
    }
}

- (void)willEnterForeground
{
    if (self.navigationController.visibleViewController == self)
    {
        [self.camera startCapture];
    }
}

- (void)didBecomeActive
{
    if (self.navigationController.visibleViewController == self)
    {
        [self.camera startCapture];
    }
}

#pragma mark ------ info ------
- (void)showAppAndSDKVersion
{
    self.appVersionLabel.text = [FUManager shareInstance].appVersion;
    self.sdkVersionLabel.text = [FUManager shareInstance].sdkVersion;
}

@end
