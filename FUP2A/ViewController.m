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


// 版本号  view
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *sdkVersionLabel;
@end



@implementation ViewController
{
    BOOL firstLoad ;// 首次进入页面
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;

    if (firstLoad) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.lanchImage.hidden = NO ;
            [self.view sendSubviewToBack:self.lanchImage];
        });
        firstLoad = NO ;
        	[avatar resetScaleToBody];

    }else {

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
        
    }else if ([identifier isEqualToString:@"PushToARView"]){        // AR
        [self.camera stopCapture];
    }
}

- (void)loadDefaultAvatar {
    loadingBundles = YES ;
    FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
    [[FUManager shareInstance] reloadRenderAvatar:avatar];
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

// track face
- (IBAction)trackAction:(UIButton *)sender {
    sender.selected = !sender.selected ;
    self.preView.hidden = !sender.selected ;
    renderMode = sender.selected ? FURenderPreviewMode : FURenderCommonMode ;

    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;

    if (sender.selected) {
        [avatar loadTrackFaceModePose];
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
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (loadingBundles) {
        return ;
    }
    
    frameIndex ++ ;
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
    
    float landmarks[150] ;
    CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:pixelBuffer RenderMode:renderMode Landmarks:landmarks];
    
    [self.displayView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:YES];
    
    if (renderMode == FURenderPreviewMode) {
        [self.preView displayPixelBuffer:pixelBuffer withLandmarks:landmarks count:150 Mirr:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark ---- FUHomeBarViewDelegate

- (void)homeBarViewShouldCreateAvatar {
    [self performSegueWithIdentifier:@"PushToTakePicView" sender:nil];
}

- (void)homeBarViewShouldDeleteAvatar {
    [self.camera stopCapture];
    FUHistoryViewController *historyView = [[FUHistoryViewController alloc] initWithNibName:@"FUHistoryViewController" bundle:[NSBundle mainBundle]];
    historyView.mDelegate = self ;
    [self presentViewController:historyView animated:YES completion:nil];
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
    
    self->loadingBundles = YES ;
    
    [[FUManager shareInstance] reloadRenderAvatar:avatar];
    
	//[avatar resetScaleToBody];
       [avatar resetScaleDelta:-1];
       [avatar resetTranslateDelta:0.1];
       [avatar resetRotDelta:_rotDelta];
    switch (self->renderMode) {
        case FURenderCommonMode:
            [avatar loadStandbyAnimation];
            break;
        case FURenderPreviewMode:
            [avatar loadTrackFaceModePose];
            [avatar enterTrackFaceMode];
            break ;
    }
    self->loadingBundles = NO ;
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
    if (isAR) {     // AR 滤镜
        
        FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
        [avatar quitTrackFaceMode];
        [self performSegueWithIdentifier:@"PushToARView" sender:nil];
    }else {         // 形象
        [self performSegueWithIdentifier:@"PushToEditView" sender:nil];
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
