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
@end

@implementation FUARFilterController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.camera startCapture ];
    [[FUManager shareInstance] maxFace:1];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapClick:)];
    [self.renderView addGestureRecognizer:tapGesture];
    
    CGAffineTransform trans0 = CGAffineTransformMakeScale(0.68, 0.68) ;
    CGAffineTransform trans1 = CGAffineTransformMakeTranslation(0, -80) ;
    self.photoBtn.transform = CGAffineTransformConcat(trans0, trans1) ;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[FUManager shareInstance] enterARMode];
    
    [self.filterView selectedModeWith:[FUManager shareInstance].currentAvatar];
}

- (IBAction)backAction:(id)sender {
    
    [self.camera stopCapture];
    [[FUManager shareInstance] quitARMode];
    [[FUManager shareInstance] maxFace:1];
    
    if (avatarChanged) {
        [[FUManager shareInstance] loadAvatar:[FUManager shareInstance].currentAvatar];
    }
    
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
    [[FUManager shareInstance] loadARModel:avatar];
}

// 点击滤镜
- (void)ARFilterViewDidSelectedARFilter:(NSString *)filterName {
    [[FUManager shareInstance] loadARFilter:filterName];
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
