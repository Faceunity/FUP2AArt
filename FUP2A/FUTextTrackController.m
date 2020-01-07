//
//  ViewController.m
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUTextTrackController.h"
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
#import "FURotation.h"
#import "FUTrackController.h"
#import "Faceunity/FUSta/FUStaLiteRequestManager.h"
#import "Faceunity/FUSta/FUAudioPlayer.h"
#import "Faceunity/FUSta/FUMusicPlayer.h"
@interface FUTextTrackController ()<
FUCameraDelegate,
UIGestureRecognizerDelegate,
FUHomeBarViewDelegate,
FUHistoryViewControllerDelegate,FUTextTrackViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,FUMusicPlayerDelegate
>
{
	CGFloat preScale; // 捏合比例
	FURenderMode renderMode ;
	BOOL loadingBundles ;
	
	
	void * _human3dPtr;
	
}

@property (nonatomic, strong) FUCamera *camera ;       // 相机输入源
@property (weak, nonatomic) IBOutlet FUOpenGLView *displayView;
@property (weak, nonatomic) IBOutlet FUOpenGLView *preView;   // 暂时不需要

// views
@property (weak, nonatomic) IBOutlet UIButton *trackBtn;     // 是否追踪脸部点位

@property (nonatomic, strong) AVAssetReaderTrackOutput * mOutput;     // 视频输入源
@property (nonatomic, strong) AVAssetReader * mReader;
@property (nonatomic, strong) AVURLAsset *mAsset;                     // 视频文件
@property (nonatomic, assign) UIInterfaceOrientation videoOrientation;   // 当前视频方向
@property (nonatomic, strong) FUAvatar *commonAvatar;    //  记录进入人体追踪之前的avatar，当从追踪界面返回时，继续渲染这个 avatar
@property (nonatomic, strong) FUAvatar *currentAvatar;    // 当前选择的人体追踪 Avatar
@property (nonatomic, assign) int staExpressionsFrameNumber;    // 当前语音表情系数的总帧数
@property (nonatomic, assign) float *staTotalExpressions;    // 当前语音表情系数的多个帧组成的口型系数数组
@property (nonatomic, assign) float staTimeStride;    // 语音的帧间隔
@property (nonatomic, assign) FUVideoRecordState videoRecordState ;   // 录制视频的状态
@property (nonatomic, assign) FUStaPlayState staPlayState;   // stal音频的播放状态
@property (nonatomic, assign) NSString * currentToneName;   // 当前音色名称，默认是 "Sicheng"
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *faceTrackBtnBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *preViewBottom;

@end
static int expSize = 57;

@implementation FUTextTrackController
{
	BOOL firstLoad ;// 首次进入页面
}

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.currentToneName = @"Siqi";
	[FUMusicPlayer sharePlayer].delegate = self;
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	
	self.commonAvatar = avatar;     // 记录进入后，普通模式的avatar，用于退出这个界面时，重新渲染这个avatar
	self.currentAvatar = avatar;   // 记录进入后，当前的avatar
	
	
	//	NSString *bgPath = [[NSBundle mainBundle] pathForResource:@"default_bg" ofType:@"bundle"];
	[self.textTrackView selectedModeWith:self.currentAvatar];     // UI选择当前avatar
	// 添加进入和退出后台的监听
	[self addObserver];
	
	firstLoad = YES ;
	// 普通渲染模式
	renderMode = FURenderCommonMode ;
	self.textTrackView.delegate = self;
	
	
	// 检测相册权限并打开
	[appManager checkSavePhotoAuth:^(PHAuthorizationStatus status) {
		if (status == PHAuthorizationStatusAuthorized) {
		}else if (status == PHAuthorizationStatusDenied) {
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

-(void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	self.textTrackView.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (firstLoad) {
		__weak typeof(self)weakSelf = self;
		firstLoad = NO ;
		
	}else {
		
		
	}
	//	[self.camera startCapture ];
	
}
-(void)setStaPlayState:(FUStaPlayState)staPlayState{
	_staPlayState = staPlayState;
	self.videoRecordState = (FUVideoRecordState)staPlayState;
}
-(void)setIsShow:(BOOL)isShow{
	_isShow = isShow;
	if (isShow) {   // 显示当前界面
		[[FUManager shareInstance] reloadRenderAvatarInSameController:self.currentAvatar];
		NSString *default_bg_Path = [[NSBundle mainBundle] pathForResource:@"default_bg" ofType:@"bundle"];
		[[FUManager shareInstance] reloadBackGroundAndBindToController:default_bg_Path];
		[self.currentAvatar resetScaleToBody];
		[self.currentAvatar removeAnimation];

		
		// 打开 avatar的口型系数驱动功能
		[self.currentAvatar enableBlendshape];
		// 设置口型系数的权重 expression_weight0、expression_weight1
		NSData *jsonData = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"sta_bs_blend_weight" ofType:@"json"] encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
		double expression_weight0Expression[57] = {0};
		double expression_weight1Expression[57] = {0};
		NSArray * expression_weight0Array = jsonDic[@"expression_weight0"];
		NSArray * expression_weight1Array = jsonDic[@"expression_weight1"];
		for (int i = 0; i < expSize; i++) {
			expression_weight0Expression[i] = [expression_weight0Array[i] doubleValue];
			expression_weight1Expression[i] = [expression_weight1Array[i] doubleValue];
		}
		[self.currentAvatar setExpression_wieght0:expression_weight0Expression];
		[self.currentAvatar setExpression_wieght1:expression_weight1Expression];
		[self.currentAvatar loadIdleModePose];
		if(self.trackBtn.isSelected)
		{
			[self.currentAvatar loadIdleModePose];
			[self.currentAvatar enterTrackFaceMode];
		}
		[self.camera startCapture];           // 相机继续捕获
		
		
		
	}else{
		[[FUManager shareInstance] reloadFilterWithPath:nil];
		[[FUMusicPlayer sharePlayer] stop];
		self.staPlayState = Original;
		[self.currentAvatar disableBlendshape];
		[self.camera stopCapture];                             // 相机暂停捕获

		
	}
}

// 返回按钮
- (IBAction)backAction:(id)sender {
	self.staPlayState = Original;
	[[FUMusicPlayer sharePlayer] stop];
	[self.currentAvatar disableBlendshape];
	[self.camera stopCapture];

	__weak typeof(self)weakSelf = self;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[[FUManager shareInstance] reloadFilterWithPath:nil];
		[weakSelf.currentAvatar quitTrackBodyMode];   // 退出身体追踪模式
		[FURenderer destroy3DBodyTracker:_human3dPtr];     // 销毁 _human3dPtr 句柄
		
		[weakSelf.navigationController popViewControllerAnimated:NO];
		[[FUManager shareInstance] reloadRenderAvatarInSameController:weakSelf.commonAvatar];     // 以不销毁controller的方式，重新加载avatar
		[weakSelf.commonAvatar loadStandbyAnimation];
		[weakSelf.commonAvatar resetScaleToSmallBody];
	});
	
}

// track face
- (IBAction)trackAction:(UIButton *)sender {
	sender.selected = !sender.selected ;
	renderMode = sender.selected ? FURenderPreviewMode : FURenderCommonMode ;
	if (sender.selected) {
		//	[self.currentAvatar disableBlendshape];
		[self.currentAvatar loadIdleModePose];
		[self.currentAvatar enterTrackFaceMode];
	}else{
		
		[self.currentAvatar quitTrackFaceMode];
		[self.currentAvatar loadIdleModePose];
		//	[self.currentAvatar enableBlendshape];
	}
}

// 点击滤镜
- (void)ARFilterViewDidSelectedARFilter:(NSString *)filterName {
	//	[self.currentAvatar enterARMode];
	NSString *filterPath = [[NSBundle mainBundle] pathForResource:filterName ofType:@"bundle"];
	[[FUManager shareInstance] reloadFilterWithPath:filterPath];
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	CGFloat YY = CGRectGetMinY(self.textTrackView.mInputView.frame);
	NSLog(@"YY----------%f",YY);
	if ([self.textTrackView hideKeyboard]) {
		if (self.textTrackView.superview.hidden) {
			self.faceTrackBtnBottom.constant = 54;
		}else{
			self.faceTrackBtnBottom.constant = 167;
		}
		self.preViewBottom.constant = 180;
	}else{
		self.textTrackView.superview.hidden = !self.textTrackView.superview.hidden;
		if (self.textTrackView.superview.hidden) {
			self.faceTrackBtnBottom.constant = 54;
		}else{
			self.faceTrackBtnBottom.constant = 167;
		}
	}
	//self.textTrackView.mInputView.frame
	
}
- (void)TextTrackViewShowOrHideKeyBoardInput:(BOOL)isShow height:(float)h{
	if (isShow) {
		if (appManager.isXFamily) {
			self.faceTrackBtnBottom.constant = h + 30;
			self.preViewBottom.constant = h + 30;
		}else{
			
			
			self.faceTrackBtnBottom.constant = h + 20;
			self.preViewBottom.constant = h + 20;
		}
	}else{
		if (self.textTrackView.superview.hidden) {
			self.faceTrackBtnBottom.constant = 54;
		}else{
			self.faceTrackBtnBottom.constant = 167;
		}
		self.preViewBottom.constant = 180;
	}
	
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

-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	if (loadingBundles) {
		return ;
	}
	
	frameIndex ++ ;
	CVPixelBufferRef pixelBuffer;
	pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
	int h = (int)CVPixelBufferGetHeight(pixelBuffer);
	int w = (int)CVPixelBufferGetWidth(pixelBuffer);
	
	CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
	float landmarks[150];
	// 人体追踪的渲染方法
	CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemInFUStaWithPixelBuffer:mirrored_pixel RenderMode:renderMode Landmarks:landmarks];
	if (self.staPlayState == StaPlaying) {
		static int staFrameIndex = 0;
		float currentTime = [FUMusicPlayer sharePlayer].currentTime;
		float totalTime = [FUMusicPlayer sharePlayer].duration;
		staFrameIndex = staFrameIndex == (int)(currentTime / self.staTimeStride) ? staFrameIndex :  (int)(currentTime /  self.staTimeStride);
		double exp[57] = {0.0};
		float *expression = &self.staTotalExpressions[expSize * staFrameIndex];
		for (int i = 0; i < expSize; i++) {
			exp[i] = (double)expression[i];
		}
		[self.currentAvatar setBlend_expression:exp];
	}else if (self.staPlayState == Original) {
	double exp[57] = {0.0};
	[self.currentAvatar setBlend_expression:exp];
	}
	
	[self.displayView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:NO];
	
	switch (self.videoRecordState) {
		case Original:
			break;
		case Recording:
		{
			
			[[FUP2AHelper shareInstance] recordBufferWithType:FUP2AHelperRecordTypeStaVideo buffer:buffer
												 sampleBuffer:sampleBuffer];
		}
			break;
		case Completed:
		{
			
			[[FUP2AHelper shareInstance] stopRecordWithType:FUP2AHelperRecordTypeStaVideo Completion:^(NSString *retPath) {
				dispatch_async(dispatch_get_main_queue(), ^{
				});
			}];
			
			
			self.staPlayState = Original;
		}
			break;
			
		default:
			break;
	}
	if (renderMode == FURenderPreviewMode) {
		if (self.camera.isFrontCamera){
			[self.preView displayPixelBuffer:pixelBuffer withLandmarks:landmarks count:150 Mirr:YES];
		}else{
			[self.preView displayPixelBuffer:pixelBuffer withLandmarks:landmarks count:150 Mirr:NO];
		}
	}else{
		if (self.camera.isFrontCamera){
			[self.preView displayPixelBuffer:pixelBuffer withLandmarks:nil count:0 Mirr:YES];
		}else{
			[self.preView displayPixelBuffer:pixelBuffer withLandmarks:nil count:0 Mirr:NO];
		}
	}
	CVPixelBufferRelease(mirrored_pixel);
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
// 切换相机
- (IBAction)onCameraChange:(id)sender {
	self.camera.shouldMirror = !self.camera.shouldMirror ;
	[self.camera changeCameraInputDeviceisFront:!self.camera.isFrontCamera];
}
// 重新选择的avatar
-(void)TextTrackViewDidSelectedAvatar:(FUAvatar *)avatar{
	loadingBundles = YES;
	[[FUManager shareInstance] reloadRenderAvatarInSameController:avatar];
	if (avatar == nil) {
		self.currentAvatar = nil;
	}else{
		self.currentAvatar = avatar;
		[self.currentAvatar enterTrackFaceMode];
	}
	loadingBundles = NO;
}
-(void)TextTrackViewDidSelectedInput:(NSString *)filterName{
	if ([filterName isEqualToString:@"tooninput"]) {
		
	}else if ([filterName isEqualToString:@"album"]) {
		[self selectAction];
	}else if ([filterName isEqualToString:@"live"]) {
	}
	
}
// 点击音色
- (void)TextTrackViewDidSelectedTone:(NSString *)tone{
	NSLog(@"音色是--------------%@",tone);
	if ([tone isEqualToString:@"温柔女声01"]) self.currentToneName = @"Siqi";
	else if ([tone isEqualToString:@"标准男声02"]) self.currentToneName = @"Sicheng";
	else if ([tone isEqualToString:@"严厉女声03"]) self.currentToneName = @"Sijing";
	else if ([tone isEqualToString:@"萝莉女声04"]) self.currentToneName = @"Xiaobei";
	else if ([tone isEqualToString:@"温柔女声05"]) self.currentToneName = @"Aiqi";
	else if ([tone isEqualToString:@"标准女声06"]) self.currentToneName = @"Aijia";
	else if ([tone isEqualToString:@"标准男声07"]) self.currentToneName = @"Aicheng";
	else if ([tone isEqualToString:@"标准男声08"]) self.currentToneName = @"Aida";
	else if ([tone isEqualToString:@"严厉女声09"]) self.currentToneName = @"Aiya";
	else if ([tone isEqualToString:@"亲和女声10"]) self.currentToneName = @"Aixia";
	else if ([tone isEqualToString:@"甜美女声11"]) self.currentToneName = @"Aimei";
	else if ([tone isEqualToString:@"自然女声12"]) self.currentToneName = @"Aiyu";
	else if ([tone isEqualToString:@"温柔女声13"]) self.currentToneName = @"Aiyue";
	else if ([tone isEqualToString:@"严厉女声14"]) self.currentToneName = @"Aijing";
	else if ([tone isEqualToString:@"儿童音15"]) self.currentToneName = @"Aitong";
	else if ([tone isEqualToString:@"萝莉女声16"]) self.currentToneName = @"Aiwei";
	else if ([tone isEqualToString:@"萝莉女声17"]) self.currentToneName = @"Aibao";
	else self.currentToneName = @"Siqi";
	
}


// 键盘输入文字
- (void)TextTrackViewInput:(NSString *)text{
	NSLog(@"键盘输入文字是-----%@",text);
	self.staPlayState = StaOriginal;
	[[FUStaLiteRequestManager shareManager] process:text
										  voiceName:self.currentToneName
										voiceFormat:@"mp3"
										voiceVolume:@"0.1"
										 voiceSpeed:@"1"
									voiceSamplerate:nil
											 result:^(NSError * _Nullable error, NSData * _Nonnull voiceData, NSData * _Nonnull expressionData,float timeStride) {
		// ⚠️⚠️⚠️⚠️⚠️⚠️ 必须将返回的声音保存到位置
		[FUP2AHelper shareInstance].saveAudioPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"FUStaAudio.mp3"];
		[FUP2AHelper shareInstance].saveVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fup2a_video.mp4"];
		[voiceData writeToFile: [FUP2AHelper shareInstance].saveAudioPath atomically:NO];
		if ([[NSFileManager defaultManager] fileExistsAtPath: [FUP2AHelper shareInstance].saveAudioPath]) {
			NSLog(@"存在FUStaAudioPath---------%@", [FUP2AHelper shareInstance].saveAudioPath);
		}else{
			NSLog(@"不存在FUStaAudioPath---------%@", [FUP2AHelper shareInstance].saveAudioPath);
		}
		[[FUP2AHelper shareInstance] startRecordWithType:FUP2AHelperRecordTypeStaVideo];
		
		self.staTimeStride = timeStride;
		//长度
		int expressionsTotalSize = (int)expressionData.length;
		//数组第一个指针，口型系数
		float *expressions = (float *) expressionData.bytes;
		for (int i = 0; i < expressionsTotalSize; i++) {
			
		}
		//口型系数
		self.staTotalExpressions =	malloc(sizeof(float) *expressionsTotalSize );
		memcpy(self.staTotalExpressions, expressions, expressionsTotalSize);
		self.staExpressionsFrameNumber = expressionsTotalSize /sizeof(float) / expSize;
		self.staPlayState = StaPlaying;
		[[FUMusicPlayer sharePlayer] playMusicData:voiceData];
		
		
		
	}];
}


- (void)selectAction{
	
	NSLog(@"从相册选择");
	UIImagePickerController *picker=[[UIImagePickerController alloc] init];
	
	picker.delegate=self;
	picker.allowsEditing=NO;
	picker.videoMaximumDuration = 1.0;//视频最长长度
	picker.videoQuality = UIImagePickerControllerQualityTypeMedium;//视频质量
	
	//媒体类型：@"public.movie" 为视频  @"public.image" 为图片
	//这里只选择展示视频
	picker.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];
	
	picker.sourceType= UIImagePickerControllerSourceTypeSavedPhotosAlbum;
	__weak typeof(self)weakSelf = self;
	[self presentViewController:picker animated:YES completion:^{
		[weakSelf.camera stopCapture];
	}];
	
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

-(void)TextTrackViewExitFromKeyBoardInput{
	self.backBlock();
	[self.currentAvatar disableBlendshape];
}
#pragma FUMusicPlayerDelegate
- (void)musicPlayerDidFinishPlay{
	// 语音播放结束，录制完成
	self.staPlayState = StaCompleted;
}
-(void)dealloc{
	NSLog(@"FUTextTrackController-----------销毁了");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
