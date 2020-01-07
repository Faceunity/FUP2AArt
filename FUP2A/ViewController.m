//
//  ViewController.m
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import "ViewController.h"
#import <SVProgressHUD.h>
#import "FUP2ADefine.h"
#import "FUCamera.h"
#import "FUOpenGLView.h"
#import "FUManager.h"
#import "FUAvatar.h"
#import "FUP2AColor.h"
#import "FUTool.h"
#import "FUTakePhotoController.h"
#import "FUEditViewController.h"
#import "FURequestManager.h"

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
	FURenderMode renderMode ;
	BOOL loadingBundles ;
	// 同步信号量
	dispatch_semaphore_t signal;
}
@property (weak, nonatomic) IBOutlet UIImageView *lanchImage;

@property (nonatomic, strong) FUCamera *camera ;
@property (weak, nonatomic) IBOutlet FUOpenGLView *displayView;
@property (weak, nonatomic) IBOutlet FUOpenGLView *preView;

// views
@property (nonatomic, strong) FUHomeBarView *homeBar ;
@property (weak, nonatomic) IBOutlet UIButton *trackBtn;

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImage;
@property (weak, nonatomic) IBOutlet UILabel *pointLabel;
@property (nonatomic, strong) NSTimer *labelTimer ;
@property (nonatomic, assign) FUVideoRecordState videoRecordState ;   // 录制视频的状态


// 版本号  view
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionLabel;
@end



@implementation ViewController
{
	BOOL firstLoad ;// 首次进入页面
	CRender * _viewRender;
	CRender * _recordRender;
}

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	signal = dispatch_semaphore_create(1);
	_viewRender = [[CRender alloc]init];
	_recordRender = [[CRender alloc]init];
	//[[FURenderer shareRenderer] setInputCameraMatrix:0 flip_y:1 rotate_mode:90];
	[FUP2AHelper shareInstance].saveVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fup2a_video.mp4"];
	[[FUP2AHelper shareInstance] startRecordWithType:FUP2AHelperRecordTypeVoicedVideo];
	_rotDelta = 1;
	[self addObserver];
	
	firstLoad = YES ;
	
	renderMode = FURenderCommonMode ;
	[self.camera startCapture ];
	
	self.appVersionLabel.text = [FUManager shareInstance].appVersion;
	self.sdkVersionLabel.text = [FUManager shareInstance].sdkVersion;
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[FUManager shareInstance] reloadCamItemWithPath:nil];
	NSString *default_bg_Path = [[NSBundle mainBundle] pathForResource:@"default_bg" ofType:@"bundle"];
	[[FUManager shareInstance] reloadBackGroundAndBindToController:default_bg_Path];
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	[avatar loadStandbyAnimation];
	
	if (firstLoad) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			self.lanchImage.hidden = NO ;
			[self.view sendSubviewToBack:self.lanchImage];
		});
		firstLoad = NO ;
        [avatar resetScaleToBody];
		
	}else {
        if (self.homeBar.showTopView)
        {
            [avatar resetScaleToBody];
        }
        else
        {
            [avatar resetScaleToSmallBody];
        }

    
		[self.homeBar reloadModeData];
		[self.camera startCapture ];
	}
}

-(void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.camera stopCapture];
	
	if (!self.preView.hidden) {
		self.trackBtn.selected = NO ;
		self.preView.hidden = YES ;
		
		self.preView.hidden = YES ;
		FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
		// 加载默认动画
		[avatar loadStandbyAnimation];
		
		renderMode = FURenderCommonMode ;
		
		self.appVersionLabel.hidden = NO ;
		self.sdkVersionLabel.hidden = NO ;
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	NSString *identifier = segue.identifier ;
	if ([identifier isEqualToString:@"FUHomeBar"]) {
		
		UIViewController *itemsViewc = segue.destinationViewController;
		self.homeBar = (FUHomeBarView *)itemsViewc.view ;
		self.homeBar.delegate = self ;
	}else if ([identifier isEqualToString:@"PushToTakePicView"]){   // 生成页
		
		[self.camera stopCapture];
	}else if ([identifier isEqualToString:@"PushToEditView"]){      // 形象页
		[self.camera stopCapture];
		
	}else if ([identifier isEqualToString:@"PushToTrackVC"]){        // AR
		[self.camera stopCapture];
	}else if ([identifier isEqualToString:@"PushToHistoryVC"]){        // 历史记录
		FUHistoryViewController *historyView = segue.destinationViewController;
		historyView.mDelegate = self ;
	}
}

- (void)loadDefaultAvatar {
	loadingBundles = YES ;
	FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
	[[FUManager shareInstance] reloadRenderAvatarInSameController:avatar];
	[avatar loadStandbyAnimation];
	
	
	loadingBundles = NO ;
}

// Avatar 旋转
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event];
	UITouch *touch = [touches anyObject];
	
	CGFloat locationX = [touch locationInView:self.displayView].x;
	CGFloat preLocationX = [touch previousLocationInView:self.displayView].x;
	
	float dx = (locationX - preLocationX) / self.displayView.frame.size.width;
	
	CGFloat locationY = [touch locationInView:self.displayView].y;
	CGFloat preLocationY = [touch previousLocationInView:self.displayView].y;
	
	float dy = (locationY - preLocationY) / self.displayView.frame.size.height ;
	
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	[avatar resetRotDelta:dx];
	_rotDelta += dx ;
	[avatar resetTranslateDelta:-dy];
}
- (IBAction)halfAndFullbody:(UIButton *)sender {
	sender.selected = !sender.selected;
	FUAvatar * currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
	if (sender.selected) {
		[currentAvatar loadHalfAvatar];
	}else{
		// 加载全身
		[currentAvatar loadAvatar];
	}
	// [[FUManager shareInstance] reloadRenderAvatarInSameController:currentAvatar];
}
- (IBAction)hideNeckClick:(UIButton *)sender {
	sender.selected = !sender.selected;
	FUAvatar * currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
	if (sender.selected) {
		// 只加载头
		[currentAvatar loadAvatarWithHeadOnly];
		//去掉脖子
		[currentAvatar removeNeck];
		
	}else{
		// 加载全身
		[currentAvatar loadAvatar];
		//加上脖子
		[currentAvatar reAddNeck];
	}
	
}
- (IBAction)recordClick:(UIButton *)sender {
	sender.selected = !sender.selected;
	if (sender.selected) {
		self.videoRecordState = Recording;
	}else{
		self.videoRecordState = Completed;
	}
	
}

// track face
- (IBAction)trackAction:(UIButton *)sender {
	sender.selected = !sender.selected ;
	self.preView.hidden = !sender.selected ;
	renderMode = sender.selected ? FURenderPreviewMode : FURenderCommonMode ;
	
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	
	if (sender.selected) {
		[avatar loadIdleModePose];
		[avatar enterTrackFaceMode];
		
		
	}else{
		[avatar quitTrackFaceMode];
		[avatar loadStandbyAnimation];
	}
	self.appVersionLabel.hidden = sender.selected ;
	self.sdkVersionLabel.hidden = sender.selected ;
}

#pragma mark ---- loading

-(FUCamera *)camera {
	if (!_camera) {
		_camera = [[FUCamera alloc] init];
		_camera.delegate = self ;
		_camera.shouldMirror = NO ;
		[_camera changeCameraInputDeviceisFront:YES];
	}
	return _camera ;
}

#pragma mark ---- FUCameraDelegate

static int frameIndex = 0 ;
CRender * viewRender;
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	if (loadingBundles) {
		return ;
	}
	
	
	frameIndex ++ ;
	
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;

	CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
	float landmarks[150] ;

	CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:mirrored_pixel RenderMode:renderMode Landmarks:landmarks];
	CGSize size = [UIScreen mainScreen].currentMode.size;
	[self.displayView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:NO];
	switch (self.videoRecordState) {
		case Original:
			
			break;
		case Recording:
		{
			CVPixelBufferRef mirrorYBuffer = [_recordRender cutoutPixelBuffer:buffer WithRect:CGRectMake(0, 0, size.width-200,size.height-200)];
			[[FUP2AHelper shareInstance] recordBufferWithType:FUP2AHelperRecordTypeVoicedVideo buffer:mirrorYBuffer sampleBuffer:sampleBuffer Completion:^(CFAbsoluteTime duration) {
				NSLog(@"当前帧返回时长-------------%f",duration);
			}];
		//	CVPixelBufferRelease(mirrorBuffer);
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
	
	if (renderMode == FURenderPreviewMode) {
		[self.preView displayPixelBuffer:pixelBuffer withLandmarks:landmarks count:150 Mirr:YES];
	}
	CVPixelBufferRelease(mirrored_pixel);
	dispatch_semaphore_signal(signal);
}


- (void)saveRecordedVideo:(NSString *)videoPath {
	[appManager checkSavePhotoAuth:^(PHAuthorizationStatus status) {
		if (status == PHAuthorizationStatusAuthorized) {
			if (videoPath && [[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
				[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
					[PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:videoPath]];
				} completionHandler:^(BOOL success, NSError * _Nullable error) {
					
					if(success && error == nil){
						[SVProgressHUD showSuccessWithStatus:@"视频已保存到相册"];
					}else{
						[SVProgressHUD showErrorWithStatus:@"保存视频失败"];
					}
				}];
			}
		}
		
		else if (status == PHAuthorizationStatusDenied) {
			__weak typeof(self)weakSelf = self ;
			UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:nil message:@"请打开你的权限！" preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[appManager openAppSettingView];
			}];
			
			[alertVC addAction:certain];
			[self presentViewController:alertVC animated:YES completion:nil];
			
		}
	}];
	
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark ---- FUHomeBarViewDelegate

- (void)homeBarViewShouldCreateAvatar {
	[self performSegueWithIdentifier:@"PushToTakePicView" sender:nil];
}

- (void)homeBarViewShouldDeleteAvatar {
   [self performSegueWithIdentifier:@"PushToHistoryVC" sender:nil];
}

// 风格切换
- (void)homeBarViewChangeAvatarStyle {
	
	if ([[FUManager shareInstance] isCreatingAvatar]) {
		[SVProgressHUD showInfoWithStatus:@"正在生成模型，不能切换风格~"];
		return ;
	}
	
	[self startLoadingAnimation];
	[self.camera stopCapture];
	
	__weak typeof(self)weakSelf = self ;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) , ^{
		
		// 销毁道具
		for (FUAvatar *avatar in [FUManager shareInstance].currentAvatars) {
			[avatar destroyAvatar];
		}
		
		// 切换 client 和数据源
		int num = [FUManager shareInstance].avatarStyle;
		num ++ ;
		num = num % 2 ;
		[[FUManager shareInstance] setAvatarStyle:(FUAvatarStyle)num];
		
		[[FUManager shareInstance] loadClientDataWithFirstSetup:NO];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf loadDefaultAvatar];
			[weakSelf.homeBar reloadModeData];
			[weakSelf stopLoadingAnimation];
			[weakSelf.camera startCapture];
			FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
			[avatar resetScaleToBody];
		});
	}) ;
}

- (void)homeBarViewDidSelectedAvatar:(FUAvatar *)avatar {
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	
	[[FUManager shareInstance] reloadRenderAvatarInSameController:avatar];
	
	
	switch (self->renderMode) {
		case FURenderCommonMode:
			if ([avatar.name isEqualToString:@"Star"]) {  // 如果是明星模型
				[avatar load_ani_mg_Animation];
			}else{
				[avatar loadStandbyAnimation];
			}
			break;
		case FURenderPreviewMode:
			[avatar loadIdleModePose];
			[avatar enterTrackFaceMode];
			break ;
	}
	dispatch_semaphore_signal(signal);
}

-(void)homeBarViewShouldShowTopView:(BOOL)show {
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	
	if (show) {
		
		[avatar resetScaleToBody];
		
		[UIView animateWithDuration:0.5 animations:^{
			self.trackBtn.transform = CGAffineTransformMakeTranslation(0, -200) ;
		}];
	}else {
		
		if (!CGAffineTransformEqualToTransform(self.trackBtn.transform, CGAffineTransformIdentity)) {
			
			[avatar resetScaleToSmallBody];
			
			[UIView animateWithDuration:0.5 animations:^{
				self.trackBtn.transform = CGAffineTransformIdentity ;
			}];
		}
	}
}
- (void)homeBarSelectedActionWithAR:(BOOL)isAR {
	FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
	
	if (isAR) {     // AR 滤镜
		
		[avatar quitTrackFaceMode];
		//       [self performSegueWithIdentifier:@"PushToARView" sender:nil];
		[self performSegueWithIdentifier:@"PushToTrackVC" sender:nil];
	}else {         // 形象
		//      [self performSegueWithIdentifier:@"PushToEditView" sender:nil];
		FUAvatar *currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
		if ([currentAvatar.name isEqualToString:@"Star"]) {
			return;
		}
		FUEditViewController * editVC = [[FUEditViewController alloc]init];
		[self.navigationController pushViewController:editVC animated:YES];
	}
}

// 合影
- (void)homeBarSelectedGroupBtn {
	[self performSegueWithIdentifier:@"showGroupPhotoController" sender:nil];
}


// zoom
- (void)homeBarViewReceiveZoom:(float)zoomScale {
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	[avatar resetScaleDelta:zoomScale];
}

#pragma mark ---- FUHistoryViewControllerDelegate
-(void)historyViewDidDeleteCurrentItem {
	[self loadDefaultAvatar];
	[self.homeBar reloadModeData];
}

#pragma mark ---- loading action ~

- (void)startLoadingAnimation {
	self.loadingView.hidden = NO ;
	[self.view bringSubviewToFront:self.loadingView];
	NSMutableArray *images = [NSMutableArray arrayWithCapacity:1];
	for (int i = 1; i < 33; i ++) {
		NSString *imageName = [NSString stringWithFormat:@"loading%d.png", i];
		NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
		UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
		[images addObject:image ];
	}
	self.loadingImage.animationImages = images ;
	self.loadingImage.animationRepeatCount = 0 ;
	self.loadingImage.animationDuration = 2.0 ;
	[self.loadingImage startAnimating];
	
	self.labelTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(labelAnimation) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:self.labelTimer forMode:NSRunLoopCommonModes];
}

- (void)labelAnimation {
	self.pointLabel.hidden = NO ;
	static int count = 1 ;
	count ++ ;
	if (count == 4) {
		count = 1 ;
	}
	NSMutableString *str = [@"" mutableCopy];
	for (int i = 0 ; i < count; i ++) {
		[str appendString:@"."] ;
	}
	self.pointLabel.text = str ;
	
}

- (void)stopLoadingAnimation {
	self.loadingView.hidden = YES ;
	[self.view sendSubviewToBack:self.loadingView];
	[self.labelTimer invalidate];
	self.labelTimer = nil ;
	[self.loadingImage stopAnimating ];
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
@end
