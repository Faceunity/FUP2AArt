//
//  FUARFilterController.m
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUARFilterController.h"
#import "FUOpenGLView.h"
#import "FUCamera.h"
#import "FUManager.h"
#import "FUARFilterView.h"

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

@property (nonatomic, strong) FUARFilterView *filterView ;
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;

@property (nonatomic, strong) FUAvatar *firstAvatar ;
@end

@implementation FUARFilterController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.camera startCapture ];
    [[FUManager shareInstance] setMaxFaceNum:1];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self.renderView addGestureRecognizer:tapGesture];
    
    CGAffineTransform trans0 = CGAffineTransformMakeScale(0.68, 0.68) ;
    CGAffineTransform trans1 = CGAffineTransformMakeTranslation(0, -80) ;
    self.photoBtn.transform = CGAffineTransformConcat(trans0, trans1) ;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    [avatar enterARMode];
    [[FUManager shareInstance] enterARMode];
    
    self.firstAvatar = avatar ;
    
    [self.filterView selectedModeWith:[FUManager shareInstance].currentAvatars.firstObject];
}

- (IBAction)backAction:(id)sender {
    
    [self.camera stopCapture];
    
    [[FUManager shareInstance] reloadRenderAvatar:self.firstAvatar];
    [self.firstAvatar loadStandbyAnimation];
    
    [self.firstAvatar quitARMode];
    [[FUManager shareInstance] setMaxFaceNum:1];
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)onCameraChange:(id)sender {
    self.camera.shouldMirror = !self.camera.shouldMirror ;
    [self.camera changeCameraInputDeviceisFront:!self.camera.isFrontCamera];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FUARFilterView"]) {
        UIViewController *destViewController = segue.destinationViewController ;
        self.filterView = (FUARFilterView *)destViewController.view ;
        self.filterView.delegate = self ;
    }
}

-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
    [[FUManager shareInstance] renderARFilterItemWithBuffer:buffer];
    [self.renderView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:YES];
}

#pragma mark ---- FUARFilterViewDelegate
-(void)ARFilterViewDidSelectedAvatar:(FUAvatar *)avatar {
    avatarChanged = YES;
    [[FUManager shareInstance] reloadRenderAvatarInARMode:avatar];
}

// 点击滤镜
- (void)ARFilterViewDidSelectedARFilter:(NSString *)filterName {
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
    [self.filterView showCollection:NO];
    [self ARFilterViewDidShowTopView:NO];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
