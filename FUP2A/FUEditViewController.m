//
//  FUEditViewController.m
//  FUP2A
//
//  Created by L on 2018/8/22.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUEditViewController.h"
#import "FUCamera.h"
#import "FUOpenGLView.h"
#import "FUManager.h"
#import <SVProgressHUD.h>
#import "FUTool.h"

#import "FUFigureColor.h"
#import "FUFigureView.h"

@interface FUEditViewController ()<FUCameraDelegate,FUFigureViewDelegate>
{
    CGFloat preScale; // 捏合比例
    
    CVPixelBufferRef renderTarget;
}
@property (nonatomic, strong) FUCamera *camera ;
@property (weak, nonatomic) IBOutlet FUOpenGLView *renderView;

@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;

@property (nonatomic, strong) FUFigureView *figureView ;

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImage;
@property (weak, nonatomic) IBOutlet UILabel *pointLabel;
@property (nonatomic, strong) NSTimer *labelTimer ;
@end

@implementation FUEditViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[FUManager shareInstance] enterFacepupMode];
    
    // 捏合 用于缩放
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomAvatar:)];
    [self.renderView addGestureRecognizer:pinchGesture];
    UIPinchGestureRecognizer *pinchGesture2 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomAvatar:)];
    [self.figureView addGestureRecognizer:pinchGesture2];
    
    [self.figureView setupFigureView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.camera startCapture];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FUFigureView"]){
        UIViewController *vc = segue.destinationViewController ;
        self.figureView = (FUFigureView *)vc.view ;
        self.figureView.delegate = self ;
    }
}

// Avatar 旋转
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    
    CGFloat locationX = [touch locationInView:self.renderView].x;
    CGFloat preLocationX = [touch previousLocationInView:self.renderView].x;
    
    float dx = (locationX - preLocationX) / self.renderView.frame.size.width;
    
    [[FUManager shareInstance] setRotDelta:dx Horizontal:YES];
    
    CGFloat locationY = [touch locationInView:self.renderView].y;
    CGFloat preLocationY = [touch previousLocationInView:self.renderView].y;
    
    float dy = (locationY - preLocationY) / self.renderView.frame.size.height ;
    
    [[FUManager shareInstance] setRotDelta:dy Horizontal:NO];
}

// Avatar 缩放
- (void)zoomAvatar:(UIPinchGestureRecognizer *)gesture {
    float curScale = gesture.scale;
    
    if (curScale < 1.0) {
        curScale = - fabsf(1 / curScale - 1);
    }else   {
        curScale -= 1;
    }
    
    float ds = curScale - preScale;
    preScale = curScale;
    
    [[FUManager shareInstance] setScaleDelta:ds];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        preScale = 0.0;
    }
}

-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
    
    CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:pixelBuffer RenderMode:FURenderCommonMode Landmarks:nil];
    
    [self.renderView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:YES];
    
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    int width = (int)CVPixelBufferGetWidth(buffer) ;
    int height = (int)CVPixelBufferGetHeight(buffer) ;
    int size = (int)CVPixelBufferGetDataSize(buffer) ;
    void *byte = CVPixelBufferGetBaseAddress(buffer) ;
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    if (renderTarget) {
        
        int w = (int)CVPixelBufferGetWidth(renderTarget) ;
        int h = (int)CVPixelBufferGetHeight(renderTarget) ;
        
        if (width == w && height == h) {
            
            CVPixelBufferLockBaseAddress(renderTarget, 0) ;
            
            void *b = CVPixelBufferGetBaseAddress(renderTarget) ;
            
            memcpy(b, byte, size) ;
            
            CVPixelBufferUnlockBaseAddress(renderTarget, 0) ;
        }else {
            CFRelease(renderTarget) ;
            renderTarget = nil ;
            [self creatPixelBufferWithSize:CGSizeMake(width, height)] ;
        }
    }else {
        [self creatPixelBufferWithSize:CGSizeMake(width, height)] ;
    }
}

- (void)creatPixelBufferWithSize:(CGSize)size {
    
    if (!renderTarget) {
        NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
                                                  @(kCVPixelFormatType_32BGRA),
                                              (NSString*) kCVPixelBufferWidthKey : @(size.width),
                                              (NSString*) kCVPixelBufferHeightKey : @(size.height),
                                              (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
                                              (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
        CVPixelBufferCreate(kCFAllocatorDefault,
                            size.width, size.height,
                            kCVPixelFormatType_32BGRA,
                            (__bridge CFDictionaryRef)pixelBufferOptions,
                            &renderTarget);
    }
}

// 返回
- (IBAction)backAction:(UIButton *)sender {

    if ([self isModeChanged]) {
        __weak typeof(self)weaklSelf = self ;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"是否保存当前形象编辑？" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"放弃" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [weaklSelf.camera stopCapture];
            [weaklSelf resetPupParams];
            [[FUManager shareInstance] quitFacepupMode];
            FUAvatar *avatar = [FUManager shareInstance].currentAvatar;
            if (self.figureView.currentHair != avatar.defaultHair) {
                NSString *hairPath;
                if (avatar.time) {
                    hairPath = [[avatar avatarPath] stringByAppendingPathComponent:avatar.defaultHair];
                }else {
                    hairPath = [[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:avatar.bundleName] stringByAppendingPathComponent:avatar.defaultHair];
                }
                if (![hairPath hasSuffix:@"bundle"]) {
                    hairPath = [hairPath stringByAppendingString:@".bundle"];
                }
                [[FUManager shareInstance] loadItemWithtype:FUItemTypeHair filePath:hairPath];
            }
            if (self.figureView.currentCloth != avatar.defaultClothes) {
                NSString *clothes = avatar.defaultClothes ;
                if (clothes == nil || [clothes isEqualToString:@"noitem"]) {
                    clothes = avatar.isMale ? @"male_underware" : @"female_underware" ;
                }
                NSString *clothesPath = [[NSBundle mainBundle] pathForResource:clothes ofType:@"bundle"];
                [[FUManager shareInstance] loadItemWithtype:FUItemTypeClothes filePath:clothesPath];
            }
            if (self.figureView.currentGlasses != avatar.defaultGlasses) {
                NSString *glassesPath = nil ;
                if (avatar.defaultGlasses != nil && ![avatar.defaultGlasses isEqualToString:@"glasses-noitem"]) {
                    glassesPath = [[NSBundle mainBundle] pathForResource:avatar.defaultGlasses ofType:@"bundle"];
                }
                [[FUManager shareInstance] loadItemWithtype:FUItemTypeGlasses filePath:glassesPath];
            }
            
            if (self.figureView.currentBeard != avatar.defaultBeard) {
                NSString *glassesPath = nil ;
                if (avatar.defaultBeard != nil && ![avatar.defaultBeard isEqualToString:@"beard-noitem"]) {
                    glassesPath = [[NSBundle mainBundle] pathForResource:avatar.defaultBeard ofType:@"bundle"];
                }
                [[FUManager shareInstance] loadItemWithtype:FUItemTypeBeard filePath:glassesPath];
            }
            
            if (self.figureView.currentHat != avatar.defaultHat) {
                NSString *hatPath = nil ;
                if (avatar.defaultHat != nil && ![avatar.defaultHat isEqualToString:@"hat-noitem"]) {
                    hatPath = [[NSBundle mainBundle] pathForResource:avatar.defaultHat ofType:@"bundle"];
                }
                [[FUManager shareInstance] loadItemWithtype:FUItemTypeHat filePath:hatPath];
            }
            
            [[FUManager shareInstance] setDefaultColorForAvatar:avatar];
            
            [weaklSelf.navigationController popViewControllerAnimated:NO];
        }];
        [cancle setValue:[UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1.0] forKey:@"titleTextColor"];

        UIAlertAction *certain = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weaklSelf downLoadAction:weaklSelf.downloadBtn];
        }];
        [certain setValue:[UIColor colorWithRed:54/255.0 green:178/255.0 blue:255/255.0 alpha:1.0] forKey:@"titleTextColor"];

        [alertController addAction:cancle];
        [alertController addAction:certain];
        [self presentViewController:alertController animated:YES completion:^{
        }];
    }else {
        [self.camera stopCapture];
//        [self resetPupParams];
        [[FUManager shareInstance] quitFacepupMode];
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (void)resetPupParams {
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatar;
    
    double color[3] ;
    FUFigureColor *c = avatar.skinColor ;
    if (!c) {
        c = self.figureView.skinColorArray[self.figureView.defaultSkinLevel] ;
    }
    color[0] = c.r ;
    color[1] = c.g ;
    color[2] = c.b ;
    [[FUManager shareInstance] facepopSetSkinColor:color];
    
    c = avatar.lipColor ;
    if (!c) {
        c = self.figureView.lipColorArray[self.figureView.defaultLipLevel] ;
    }
    color[0] = c.r ;
    color[1] = c.g ;
    color[2] = c.b ;
    [[FUManager shareInstance] facepopSetLipColor:color];
    
    c = avatar.irisColor ;
    if (!c) {
        c = self.figureView.irisColorArray[0] ;
    }
    color[0] = c.r ;
    color[1] = c.g ;
    color[2] = c.b ;
    [[FUManager shareInstance] facepopSetIrisColor:color];
    
    c = avatar.hairColor ;
    if (!c) {
        c = self.figureView.hairColorArray[0] ;
    }
    color[0] = c.r ;
    color[1] = c.g ;
    color[2] = c.b ;
    [[FUManager shareInstance] facepopSetHairColor:color intensity:c.intensity];
    
    c = avatar.glassFrameColor ;
    if (!c) {
        c = self.figureView.glassFrameArray[0] ;
    }
    color[0] = c.r ;
    color[1] = c.g ;
    color[2] = c.b ;
    [[FUManager shareInstance] facepopSetGlassesFrameColor:color];
    
    c = avatar.glassColor ;
    if (!c) {
        c = self.figureView.glassColorArray[0] ;
    }
    color[0] = c.r ;
    color[1] = c.g ;
    color[2] = c.b ;
    [[FUManager shareInstance] facepopSetGlassesColor:color];
    
    c = avatar.beardColor ;
    if (!c) {
        c = self.figureView.beardColorArray[0] ;
    }
    color[0] = c.r ;
    color[1] = c.g ;
    color[2] = c.b ;
    [[FUManager shareInstance] facepopSetBeardColor:color];
}

// 保存
- (IBAction)downLoadAction:(UIButton *)sender {
    sender.userInteractionEnabled = NO ;
    [self.camera stopCapture];
    [self resetPupParams];
    [self startLoadingAnimation];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL deformHead = [self.figureView figureViewIsChange] ;
        
        if (!deformHead && [FUManager shareInstance].currentAvatar.time != nil) {
            FUAvatar *avatar = [FUManager shareInstance].currentAvatar;
            
            avatar.defaultHair = self.figureView.currentHair ;
            avatar.defaultClothes = self.figureView.currentCloth ;
            avatar.defaultGlasses = self.figureView.currentGlasses ;
            avatar.defaultBeard = self.figureView.currentBeard ;
            avatar.defaultHat = self.figureView.currentHat ;
            
            avatar.skinColor = self.figureView.skinColor ;
            avatar.lipColor = self.figureView.lipColor ;
            avatar.irisColor = self.figureView.irisColor ;
            avatar.hairColor = self.figureView.hairColor ;
            avatar.glassColor = self.figureView.glassesColor ;
            avatar.glassFrameColor = self.figureView.glassesFrameColor ;
            avatar.beardColor = self.figureView.beardColor ;
            avatar.hatColor = self.figureView.hatColor ;
            
            [FUManager shareInstance].currentAvatar = avatar;
      
            [[FUManager shareInstance] setDefaultColorForAvatar:avatar];
            
            [[FUManager shareInstance] quitFacepupMode];
            
            NSMutableArray<FUAvatar *> *history = [NSKeyedUnarchiver unarchiveObjectWithFile:historyPath];

            if (!history) {
                history = [[NSMutableArray alloc] init];
            }
            NSInteger index = -1 ;
            for (FUAvatar *ava in history) {
                if ([avatar.time isEqualToString:ava.time]) {
                    index = [history indexOfObject:ava];
                    break ;
                }
            }
            
            if (index != -1) {
                [history replaceObjectAtIndex:index withObject:avatar];
                [NSKeyedArchiver archiveRootObject:history toFile:historyPath];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:NO ];
            });
            return ;
        }
        
        float coeffi[36] = {
            self.figureView.cheekNarrow > 0 ? self.figureView.cheekNarrow : 0,
            self.figureView.cheekNarrow > 0 ? 0 : fabs(self.figureView.cheekNarrow),
            self.figureView.headShrink > 0 ? self.figureView.headShrink : 0,
            self.figureView.headShrink > 0 ? 0 : fabs(self.figureView.headShrink),
            self.figureView.headBoneStretch > 0 ? 0 : fabs(self.figureView.headBoneStretch),
            self.figureView.headBoneStretch > 0 ? self.figureView.headBoneStretch : 0,
            self.figureView.jawLower > 0 ? self.figureView.jawLower : 0,
            self.figureView.jawLower > 0 ? 0 : fabs(self.figureView.jawLower),
            self.figureView.jawboneNarrow > 0 ? self.figureView.jawboneNarrow : 0,
            self.figureView.jawboneNarrow > 0 ? 0 : fabs(self.figureView.jawboneNarrow),
            self.figureView.lipCornerIn > 0 ? self.figureView.lipCornerIn : 0,
            self.figureView.lipCornerIn > 0 ? 0 : fabs(self.figureView.lipCornerIn),
            self.figureView.lowerLipThick > 0 ? self.figureView.lowerLipThick : 0,
            self.figureView.lowerLipThick > 0 ? 0 : fabs(self.figureView.lowerLipThick),
            0,
            self.figureView.mouthUp > 0 ? 0 : fabs(self.figureView.mouthUp),
            self.figureView.mouthUp > 0 ? self.figureView.mouthUp : 0,
            self.figureView.noseUp > 0 ? 0 : fabs(self.figureView.noseUp),
            self.figureView.noseUp > 0 ? self.figureView.noseUp : 0,
            self.figureView.noseTipUp > 0 ? 0 : fabs(self.figureView.noseTipUp),
            self.figureView.noseTipUp > 0 ? self.figureView.noseTipUp : 0,
            self.figureView.nostrilIn > 0 ? self.figureView.nostrilIn : 0,
            self.figureView.nostrilIn > 0 ? 0 : fabs(self.figureView.nostrilIn),
            self.figureView.upperLipThick > 0 ? self.figureView.upperLipThick : 0,
            self.figureView.upperLipThick > 0 ? 0 : fabs(self.figureView.upperLipThick),
            0,
            self.figureView.eyeBothIn > 0 ? self.figureView.eyeBothIn : 0,
            self.figureView.eyeBothIn > 0 ? 0 : fabs(self.figureView.eyeBothIn),
            self.figureView.eyeClose > 0 ? self.figureView.eyeClose : 0,
            self.figureView.eyeUp > 0 ? 0 : fabs(self.figureView.eyeUp),
            0,
            0,
            self.figureView.eyeClose > 0 ? 0 : fabs(self.figureView.eyeClose),
            self.figureView.eyeOutterUp > 0 ? 0 : fabs(self.figureView.eyeOutterUp),
            self.figureView.eyeOutterUp > 0 ? self.figureView.eyeOutterUp : 0,
            self.figureView.eyeUp > 0 ? self.figureView.eyeUp : 0,
        };
        
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent() ;
        BOOL ret = [[FUManager shareInstance] createPupAvatarWithCoeffi:coeffi colorIndex:0 DeformHead:deformHead] ;
        CFAbsoluteTime create = CFAbsoluteTimeGetCurrent();
        FUAvatar *avatar = [FUManager shareInstance].currentAvatar;
        
        avatar.defaultGlasses = self.figureView.currentGlasses ;
        avatar.defaultHair = self.figureView.currentHair ;
        avatar.defaultClothes = self.figureView.currentCloth ;
        avatar.defaultBeard = self.figureView.currentBeard ;
        avatar.defaultHat = self.figureView.currentHat ;
        
        avatar.skinColor = self.figureView.skinColor ;
        avatar.lipColor = self.figureView.lipColor ;
        avatar.irisColor = self.figureView.irisColor ;
        avatar.hairColor = self.figureView.hairColor ;
        avatar.glassColor = self.figureView.glassesColor ;
        avatar.glassFrameColor = self.figureView.glassesFrameColor ;
        avatar.beardColor = self.figureView.beardColor ;
        avatar.hatColor = self.figureView.hatColor ;
        
        NSMutableArray<FUAvatar *> *history = [[NSKeyedUnarchiver unarchiveObjectWithFile:historyPath] mutableCopy];

        if (!history) {
            history = [[NSMutableArray alloc] init];

        }
        NSInteger replaceIndex = -1 ;
        for (FUAvatar *ava in history) {
            if ([ava.time isEqualToString:avatar.time]) {
                replaceIndex = [history indexOfObject:ava];
                break ;

            }

        }
        if (replaceIndex == -1) {
            [history insertObject:avatar atIndex:0];
            [[FUManager shareInstance].avatars insertObject:avatar atIndex:DefaultAvatarNum];

        }else {
            [history replaceObjectAtIndex:replaceIndex withObject:avatar];
            [[FUManager shareInstance].avatars replaceObjectAtIndex:DefaultAvatarNum + replaceIndex withObject:avatar];

        }
        [NSKeyedArchiver archiveRootObject:history toFile:historyPath];
        CFAbsoluteTime final = CFAbsoluteTimeGetCurrent() ;
        NSLog(@"---- total: %f --- change default: %f", (final - start) * 1000.0, (final - create) * 1000.0);
        [[FUManager shareInstance] loadAvatar:avatar];
        if (ret) {
            [[FUManager shareInstance] quitFacepupMode];
            
            // 避免 body 还没有加载完成。闪现上一个模型的画面。
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:NO ];

            });

        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopLoadingAnimation];
                [SVProgressHUD showErrorWithStatus:@"模型保存失败，请重试"];
                [self.camera startCapture];
                sender.userInteractionEnabled = YES ;

            });

        }
    });
}

#pragma mark --- FUEditViewDelegate
- (BOOL)isModeChanged  {
    
    if (self.figureView.skinLevel != (float)self.figureView.defaultSkinLevel) {
        return YES ;
    }

    FUAvatar *avatar = [FUManager shareInstance].currentAvatar;
    if (self.figureView.currentHair != avatar.defaultHair
        || self.figureView.currentCloth != avatar.defaultClothes
        || self.figureView.currentGlasses != avatar.defaultGlasses
        || self.figureView.currentBeard != avatar.defaultBeard
        || self.figureView.currentHat != avatar.defaultHat) {
        
        return YES ;
    }
    
    if ([self.figureView figureViewIsChange]) {
        return YES ;
    }

    if (self.figureView.skinLevel != self.figureView.defaultSkinLevel
        || self.figureView.lipLevel != self.figureView.defaultLipLevel ) {
        return YES ;
    }
    
    if ((avatar.hairColor != nil && [self.figureView.hairColor colorIsEqualTo: avatar.hairColor])
        || (avatar.beardColor != nil && [self.figureView.beardColor colorIsEqualTo: avatar.beardColor])
        || (avatar.glassColor != nil && [self.figureView.glassesColor colorIsEqualTo: avatar.glassColor])
        || (avatar.glassFrameColor != nil && [self.figureView.glassesFrameColor colorIsEqualTo: avatar.glassFrameColor])
        || (avatar.hatColor != nil && [self.figureView.hatColor colorIsEqualTo: avatar.hatColor])) {
        return YES ;
    }
    
    return NO ;
}

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

-(FUCamera *)camera {
    if (!_camera) {
        _camera = [[FUCamera alloc] init];
        _camera.delegate = self ;
        _camera.shouldMirror = NO ;
        [_camera changeCameraInputDeviceisFront:YES];
    }
    return _camera ;
}


#pragma mark ---- FUFigureViewDelegate

- (void)figureViewShapeParamsDidChangedWithKey:(NSString *)key level:(double)level {
    
    [[FUManager shareInstance] facepopSetShapParam:key level:level];
    self.downloadBtn.enabled = YES ;
}


- (void)figureViewSkinColorDidChangedCurrentColor:(FUFigureColor *)curColor nextColor:(FUFigureColor *)nextColor scale:(double)scale {
    double c[3] ;
    c[0] = curColor.r ;
    c[1] = curColor.g ;
    c[2] = curColor.b ;
    if (nextColor) {
        c[0] = (nextColor.r - curColor.r) * scale + curColor.r;
        c[1] = (nextColor.g - curColor.g) * scale + curColor.g;
        c[2] = (nextColor.b - curColor.b) * scale + curColor.b;
    }
    
    [[FUManager shareInstance] facepopSetSkinColor:c];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewLipColorDidChanged {
    FUFigureColor *color = self.figureView.lipColor ;
    double c[3] ;
    c[0] = color.r ;
    c[1] = color.g ;
    c[2] = color.b ;
    [[FUManager shareInstance] facepopSetLipColor:c];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewIrisColorDidChanged {
    FUFigureColor *color = self.figureView.irisColor ;
    double c[3] ;
    c[0] = color.r ;
    c[1] = color.g ;
    c[2] = color.b ;
    [[FUManager shareInstance] facepopSetIrisColor:c];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeHairColor {
    FUFigureColor *color = self.figureView.hairColor ;
    double c[3] ;
    c[0] = color.r ;
    c[1] = color.g ;
    c[2] = color.b ;
    [[FUManager shareInstance] facepopSetHairColor:c intensity:color.intensity];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeHair:(NSString *)hairName {
    
    NSLog(@"--------------- hair name: %@", hairName);
    NSString *filePath = nil ;
    if ([hairName isEqualToString:@"hair-noitem"]) {
        filePath = nil ;
    }else {
        FUAvatar *avatar = [FUManager shareInstance].currentAvatar;
        if (avatar.time) {
            filePath = [[[avatar avatarPath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];

        }else {
            filePath = [[[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:avatar.bundleName] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"] ;
        }
    }
    [[FUManager shareInstance] loadItemWithtype:FUItemTypeHair filePath:filePath];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeGlassesFrameColor {
    FUFigureColor *color = self.figureView.glassesFrameColor ;
    double c[3] ;
    c[0] = color.r ;
    c[1] = color.g ;
    c[2] = color.b ;
    [[FUManager shareInstance] facepopSetGlassesFrameColor:c];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeGlassesColor {
    FUFigureColor *color = self.figureView.glassesColor ;
    double c[3] ;
    c[0] = color.r ;
    c[1] = color.g ;
    c[2] = color.b ;
    [[FUManager shareInstance] facepopSetGlassesColor:c];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeGlasses:(NSString *)glassesName {
    NSString *filePath = nil ;
    if ([glassesName isEqualToString:@"glasses-noitem"]) {
        filePath = nil ;
    }else {
        filePath = [[NSBundle mainBundle] pathForResource:glassesName ofType:@"bundle"];
    }
    [[FUManager shareInstance] loadItemWithtype:FUItemTypeGlasses filePath:filePath];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeBeardColor {
    FUFigureColor *color = self.figureView.beardColor ;
    double c[3] ;
    c[0] = color.r ;
    c[1] = color.g ;
    c[2] = color.b ;
    [[FUManager shareInstance] facepopSetBeardColor:c];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeBeard:(NSString *)beardName {
    NSString *filePath = nil ;
    if ([beardName isEqualToString:@"beard-noitem"]) {
        filePath = nil ;
    }else {
        filePath = [[NSBundle mainBundle] pathForResource:beardName ofType:@"bundle"];
    }
    [[FUManager shareInstance] loadItemWithtype:FUItemTypeBeard filePath:filePath];
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeCloth:(NSString *)clothName {
    NSString *filePath = nil ;
    if ([clothName isEqualToString:@"noitem"]) {
        filePath = [FUManager shareInstance].currentAvatar.isMale ? [[NSBundle mainBundle] pathForResource:@"male_underware" ofType:@"bundle"] :  [[NSBundle mainBundle] pathForResource:@"female_underware" ofType:@"bundle"];
    }else {
        filePath = [[NSBundle mainBundle] pathForResource:clothName ofType:@"bundle"];
    }
    [[FUManager shareInstance] loadItemWithtype:FUItemTypeClothes filePath:filePath];

    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeHat:(NSString *)hatName {
    NSLog(@"--------------- hat name: %@", hatName);
    NSString *hatPath = nil ;
    if (hatName && ![hatName isEqualToString:@"hat-noitem"]) {
        hatPath = [[NSBundle mainBundle] pathForResource:hatName ofType:@"bundle"];
    }
    [[FUManager shareInstance] loadItemWithtype:FUItemTypeHat filePath:hatPath];
    
    self.downloadBtn.enabled = YES ;
}

- (void)figureViewDiaChangeHatColor {
    FUFigureColor *color = self.figureView.hatColor ;
    double c[3] ;
    c[0] = color.r ;
    c[1] = color.g ;
    c[2] = color.b ;
    [[FUManager shareInstance] facepopSetHatColor:c];
    self.downloadBtn.enabled = YES ;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
