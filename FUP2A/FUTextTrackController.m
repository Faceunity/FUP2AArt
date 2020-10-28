//
//  ViewController.m
//  FUP2A
//
//  Created by L on 2018/6/1.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUTextTrackController.h"
#import "FUMusicPlayer.h"
#import "FUTakePhotoController.h"
#import "FUEditViewController.h"

// views
#import "FUHomeBarView.h"
#import "FUHistoryViewController.h"
#import "FURotation.h"
#import "FUTrackController.h"
#import "Faceunity/FUSta/FUStaLiteRequestManager.h"
#import "Faceunity/FUSta/FUAudioPlayer.h"

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
@property (nonatomic, assign) float *staTotalExpressions;    // 当前语音表情系数的多个帧组成的口型系数数组
@property (nonatomic, assign) float staTimeStride;    // 语音的帧间隔
@property (nonatomic, assign) FUVideoRecordState videoRecordState ;   // 录制视频的状态
@property (nonatomic, assign) FUStaPlayState staPlayState;   // stal音频的播放状态
@property (nonatomic, assign) NSString * currentToneName;   // 当前音色名称，默认是 "Sicheng"
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *faceTrackBtnBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *preViewBottom;
@property (nonatomic, strong) FUStaLiteRequestManager *staRequestMgr;
@property (nonatomic, strong)NSArray *prefabricateConfigArr; // 预制的”你好“声音信息，包含音色的中文名
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
	
	self.staRequestMgr = [[FUStaLiteRequestManager alloc]init];
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
    [self loadPrefabricateVoiceData];
}
#define FUChineseName @"chineseName"
-(void)loadPrefabricateVoiceData{
    NSError *error;
    NSData *jsonData = [[NSString stringWithContentsOfFile:FUPrefabricateVoice_config encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *configArr = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    self.prefabricateConfigArr = configArr;
    self.textTrackView.toneArray = [self.prefabricateConfigArr valueForKey:FUChineseName];
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
        [[FUManager shareInstance]setOutputResolutionAdjustScreen];
		[[FUManager shareInstance] reloadAvatarToControllerWithAvatar:self.currentAvatar :NO];
        [self.currentAvatar loadIdleModePose];
		[self.currentAvatar resetScaleToBody];
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
		
		if(self.trackBtn.isSelected)
		{
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
		[[FUManager shareInstance] reloadAvatarToControllerWithAvatar:weakSelf.commonAvatar];     // 以不销毁controller的方式，重新加载avatar
		[weakSelf.commonAvatar loadStandbyAnimation];
		[weakSelf.commonAvatar resetScaleToSmallBody_UseCam];
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
	if ([self.textTrackView hideKeyboard]) {
		if (self.textTrackView.hidden) {
			self.faceTrackBtnBottom.constant = 54;
		}else{
			self.faceTrackBtnBottom.constant = 167;
		}
		self.preViewBottom.constant = 180;
	}else{
		self.textTrackView.hidden = !self.textTrackView.hidden;
		if (self.textTrackView.hidden) {
			self.faceTrackBtnBottom.constant = 54;
		}else{
			self.faceTrackBtnBottom.constant = 167;
		}
	}
	self.touchBlock(self.textTrackView.hidden);
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
		if (self.textTrackView.hidden) {
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
    
    CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
    const int landmarks_cnt = 150;
    float landmarks[landmarks_cnt];
    CFAbsoluteTime renderBeforeTime = CFAbsoluteTimeGetCurrent();
    // 人体追踪的渲染方法
    CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:mirrored_pixel RenderMode:renderMode Landmarks:landmarks LandmarksLength:landmarks_cnt];
    CFAbsoluteTime interval = CFAbsoluteTimeGetCurrent() - renderBeforeTime;
//    NSLog(@"在文字驱动页耗时----::%f s",interval);
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
        }
            break;
        case Completed:
        {
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
	[[FUManager shareInstance] reloadAvatarToControllerWithAvatar:avatar :NO];
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
    __weak typeof(self)weakSelf = self ;
    [self.prefabricateConfigArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *dic = obj;
        if ([dic[FUChineseName] isEqualToString:tone]) {
            weakSelf.currentToneName = dic[@"name"];
            weakSelf.staTimeStride = [dic[@"staTimeStride"] floatValue];
            *stop = YES;
        }
    }];
    if (self.currentToneName == nil) {
        self.currentToneName = @"Siqi";
        self.staTimeStride = 0.007500; 
    }
    [self playPrefabricateVoice];
	
}
-(void)playPrefabricateVoice{
    double exp[57] = {0.0};
    [self.currentAvatar setBlend_expression:exp];
    self.staPlayState = StaOriginal;
    NSError *error;
    NSString *mp3Path = [FUPrefabricateVoice_dir stringByAppendingPathComponent :[NSString stringWithFormat:@"%@.mp3",self.currentToneName]];
    NSData *voiceData = [NSData dataWithContentsOfFile:mp3Path];
    
    NSString *expressionPath = [FUPrefabricateVoice_dir stringByAppendingPathComponent :[NSString stringWithFormat:@"%@.json",self.currentToneName]];
    NSData *jsonData = [[NSString stringWithContentsOfFile:expressionPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *configArr = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    //口型系数
    self.staTotalExpressions = malloc(sizeof(float) * configArr.count );
    for (int i = 0 ; i < configArr.count; i++) {
        NSNumber *n = configArr[i];
        self.staTotalExpressions[i] = [n floatValue];
    }
    
    self.staPlayState = StaPlaying;
    [[FUMusicPlayer sharePlayer] playMusicData:voiceData];
}
#define FUGetAllHelloVoiceData_Debug 0
// 键盘输入文字
- (void)TextTrackViewInput:(NSString *)text{
    __weak typeof(self)weakSelf = self ;
	self.staPlayState = StaOriginal;
#if FUGetAllHelloVoiceData_Debug
    if (0)
#else
    if ([text isEqualToString:@"您好"])
#endif
	{   // 如果输入的文字是“你好”，则加载本地的mp3和口型系数，不再需要网络下载 [text isEqualToString:@"你好"]
        [self playPrefabricateVoice];
    }else{
	[self.staRequestMgr process:text
										  voiceName:self.currentToneName
										voiceFormat:@"mp3"
										voiceVolume:@"0.1"
										 voiceSpeed:@"1"
									voiceSamplerate:nil
											 result:^(NSError * _Nullable error, NSData * _Nonnull voiceData, NSData * _Nonnull expressionData,float timeStride) {
        
        if (error)
        {
            [SVProgressHUD showErrorWithStatus:@"网络访问失败"];
            return ;
        }
        
		
		weakSelf.staTimeStride = timeStride;
		int expressionsTotalSize = (int)expressionData.length;
        NSMutableArray * totalExpressionArray = [NSMutableArray array];
        
		//数组第一个指针，口型系数
		float *expressions = (float *) expressionData.bytes;

		//口型系数
		weakSelf.staTotalExpressions =	malloc(sizeof(float) *expressionsTotalSize );
		memcpy(weakSelf.staTotalExpressions, expressions, expressionsTotalSize);
        for (int i = 0; i < expressionsTotalSize; i++) {
             totalExpressionArray[i] = @(weakSelf.staTotalExpressions[i]);
         }
		weakSelf.staPlayState = StaPlaying;
		[[FUMusicPlayer sharePlayer] playMusicData:voiceData];
#if FUGetAllHelloVoiceData_Debug
        [weakSelf localVoiceData:voiceData expression:totalExpressionArray];
#endif
	}];
    }
}

#if FUGetAllHelloVoiceData_Debug
-(void)getAllVoiceData{
    
}

-(void)localVoiceData:(NSData * _Nonnull)voiceData expression:(NSArray * _Nonnull) expressionArray{
    NSFileManager *df = [NSFileManager defaultManager];
    NSError *error;
    BOOL isDirectory;
    if(![df fileExistsAtPath:StaPath isDirectory:&isDirectory]){
        [df createDirectoryAtPath:StaPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    [voiceData writeToFile:[StaPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3",self.currentToneName]] options:nil error:&error];
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:expressionArray options:NSJSONWritingPrettyPrinted error:&error];
    [jsonData writeToFile:[StaPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json",self.currentToneName]] atomically:YES];

    
    
}
#endif
- (void)selectAction{
	
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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"FUTextTrackController-----销毁了");
}
@end
