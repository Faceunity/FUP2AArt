//
//  FUARFilterController.m
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUARFilterController.h"
@import CoreMotion;
@interface FUARFilterController ()<
FUCameraDelegate,
FUARFilterViewDelegate
>
{
	BOOL frontCamera ;
	BOOL avatarChanged;
}
@property (nonatomic, strong) FUCamera *camera ;
@property (weak, nonatomic) IBOutlet FUOpenGLView *renderView;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (nonatomic, strong) FUAvatar *commonAvatar;    //  记录进入人体追踪之前的avatar，当从追踪界面返回时，继续渲染这个 avatar
@property (nonatomic, strong) FUAvatar *currentAvatar;    // 当前选择的AR追踪 Avatar
@property (nonatomic, assign) int  rotationMode ;
@end

@implementation FUARFilterController

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];

    [self initializeMotionManager];
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
	[self.renderView addGestureRecognizer:tapGesture];
	
	CGAffineTransform trans0 = CGAffineTransformMakeScale(0.68, 0.68) ;
	CGAffineTransform trans1 = CGAffineTransformMakeTranslation(0, -80) ;
	self.photoBtn.transform = CGAffineTransformConcat(trans0, trans1) ;
	self.filterView.delegate = self ;
	// 添加进入和退出后台的监听
	[self addObserver];
}

- (void)initializeMotionManager{
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager .accelerometerUpdateInterval = .2;
    self.motionManager .gyroUpdateInterval = .2;
    __weak FUARFilterController *weakSelf = self;
    [self.motionManager  startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                        withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                            if (!error) {
                                              UIInterfaceOrientation orientation = [weakSelf outputAccelerationData:accelerometerData.acceleration];
                                              [[FUManager shareInstance] setScreenOrientation:orientation];
                                              
                                            }
                                            else{
                                                NSLog(@"%@", error);
                                            }
                                        }];
}

/// 获取当前屏幕方向
/// @param acceleration
- (UIInterfaceOrientation)outputAccelerationData:(CMAcceleration)acceleration{
    UIInterfaceOrientation orientationNew;
    
    if (acceleration.x >= 0.75) {
        orientationNew = UIInterfaceOrientationLandscapeLeft;
        self.rotationMode = 3;
//        NSLog(@"Landscape Left");
        
    }
    else if (acceleration.x <= -0.75) {
        orientationNew = UIInterfaceOrientationLandscapeRight;
        self.rotationMode = 1;
//        NSLog(@"Landscape Right");
    }
    else if (acceleration.y <= -0.75) {
        orientationNew = UIInterfaceOrientationPortrait;
        self.rotationMode = 0;
//        NSLog(@"Portrait");
    }
    else if (acceleration.y >= 0.75) {
        orientationNew = UIInterfaceOrientationPortraitUpsideDown;
        self.rotationMode = 2;
//        NSLog(@"UpsideDown");
    }
    return orientationNew;
}

-(void)setIsShow:(BOOL)isShow
{
	_isShow = isShow;
	if (isShow)
    {
        [[FUManager shareInstance]setOutputResolutionAdjustCamera];
        FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
        self.currentAvatar = avatar ;
        self.commonAvatar = avatar;
		// 1.即将进入AR滤镜，加载处理头发的道具
		[[FUManager shareInstance] bindHairMask];
		// 2.解绑定身体、上衣、裤子、鞋子资源，只保留头部的一些素材
	    [[FUManager shareInstance] reloadRenderAvatarInARModeInSameController:self.currentAvatar];
         [self.filterView selectedModeWith:self.currentAvatar];
	    // 3.设置AR滤镜的controller句柄为arItems[0]
		[[FUManager shareInstance] enterARMode];
		// 4.去除背景道具
		[[FUManager shareInstance] reloadBackGroundAndBindToController:nil];
		// 5.向nama设置enter_ar_mode为1，进入AR滤镜模式
		[self.currentAvatar enterARMode];
		[self.camera startCapture];
        [[FUManager shareInstance]enableFaceCapture:1];
	}
    else
    {
	    // 离开AR滤镜，删除处理头发的道具
	    [[FUManager shareInstance] destoryHairMask];
 		[self.camera stopCapture];
		[self.currentAvatar quitARMode];
		NSString *filterName = @"noitem";
		[self ARFilterViewDidSelectedARFilter:filterName];
	    [self.filterView selectModelType];
        [[FUManager shareInstance]enableFaceCapture:0];
	}
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
}
- (IBAction)onCameraChange:(id)sender {
    
	self.camera.shouldMirror = !self.camera.shouldMirror ;
	[self.camera changeCameraInputDeviceisFront:!self.camera.isFrontCamera];
//	[[FUManager shareInstance] faceCapureReset];
}
- (IBAction)backAction:(id)sender {
	// 离开AR滤镜，删除处理头发的道具
	[[FUManager shareInstance] destoryHairMask];
	[self.camera stopCapture];
	[self.currentAvatar quitARMode];
	[[FUManager shareInstance] reloadAvatarToControllerWithAvatar:self.commonAvatar];
	[self.commonAvatar  loadStandbyAnimation];
    [[FUManager shareInstance]enableFaceCapture:0];
	
	
	[self.navigationController popViewControllerAnimated:NO];
	NSString *filterName = @"noitem";
	[self ARFilterViewDidSelectedARFilter:filterName];
}


/**
 FUCameraDelegate的代理方法，用来输出相机CMSampleBufferRef 对象
 
 @param sampleBuffer sampleBuffer相机输出的buffer
 */
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
    const int landmarks_cnt = 314;
    float landmarks[landmarks_cnt] ;
    if (self.camera.isFrontCamera)
    {
		CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
		CFAbsoluteTime renderBeforeTime = CFAbsoluteTimeGetCurrent();
		[[FUManager shareInstance] renderARFilterItemWithBuffer:mirrored_pixel rotationMode:self.rotationMode];
		CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - renderBeforeTime;
//		NSLog(@"在AR驱动页耗时----::%f s",interval);
		
		[self.renderView displayPixelBuffer:mirrored_pixel withLandmarks:nil count:0 Mirr:NO];
		CVPixelBufferRelease(mirrored_pixel);
	}
    else
    {
		CFAbsoluteTime renderBeforeTime = CFAbsoluteTimeGetCurrent();
		[[FUManager shareInstance] renderARFilterItemWithBuffer:pixelBuffer rotationMode:self.rotationMode];
		CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - renderBeforeTime;
//		NSLog(@"在AR驱动页耗时----::%f s",interval);
		[self.renderView displayPixelBuffer:pixelBuffer withLandmarks:nil count:0 Mirr:NO];
	}
}

#pragma mark ---- FUARFilterViewDelegate
-(void)ARFilterViewDidSelectedAvatar:(FUAvatar *)avatar
{
	avatarChanged = YES;
//	[self.currentAvatar quitTrackBodyMode];
	[[FUManager shareInstance] reloadRenderAvatarInARModeInSameController:avatar];
	self.currentAvatar = avatar;
}

// 点击滤镜
- (void)ARFilterViewDidSelectedARFilter:(NSString *)filterName
{
	NSString *filterPath = [[NSBundle mainBundle] pathForResource:filterName ofType:@"bundle"];
	[[FUManager shareInstance] reloadARFilterWithPath:filterPath];
}

- (void)ARFilterViewDidShowTopView:(BOOL)show {
	if (show) {
		
		CGAffineTransform trans0 = CGAffineTransformMakeScale(0.68, 0.68) ;
		CGAffineTransform trans1 = CGAffineTransformMakeTranslation(0, -80) ;
		[UIView animateWithDuration:0.35 animations:^{
			self.photoBtn.transform = CGAffineTransformConcat(trans0, trans1) ;
		}];
	}else {
		[UIView animateWithDuration:0.35 animations:^{
			self.photoBtn.transform = CGAffineTransformIdentity;
		}];
	}
}

- (IBAction)takePhoto:(UIButton *)sender {
	[self.camera takePhoto:YES];
}

- (void)tapClick:(UITapGestureRecognizer *)gesture {
	
}

-(FUCamera *)camera {
	if (!_camera) {
		_camera = [[FUCamera alloc] init];
		_camera.delegate = self ;
		_camera.shouldMirror = NO ;
		[_camera changeCameraInputDeviceisFront:YES];
		frontCamera = YES ;
	}
	return _camera ;
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	[self hideOrShowFilterView];
}
-(void)hideOrShowFilterView{
	self.filterView.hidden = !self.filterView.hidden;
	[self ARFilterViewDidShowTopView:!self.filterView.hidden];
	self.touchBlock(self.filterView.hidden);
}


#pragma mark --- Observer

- (void)addObserver{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}


- (void)willResignActive    {
	
	if (self.navigationController.visibleViewController == self) {
		[self.camera stopCapture];

	}
}

- (void)willEnterForeground {
	
	if (self.navigationController.visibleViewController == self) {
		[self.camera startCapture];
	}
}

- (void)didBecomeActive {
	
	if (self.navigationController.visibleViewController == self) {
		[self.camera startCapture];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}
-(void)dealloc{
	NSLog(@"FUARFilterController-----------销毁了");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
