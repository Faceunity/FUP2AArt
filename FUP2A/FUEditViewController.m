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
#import "FUAvatar.h"
#import <SVProgressHUD.h>
#import "FUTool.h"

#import "FUP2AColor.h"
#import "FUFigureView.h"

@interface FUEditViewController ()<FUCameraDelegate,FUFigureViewDelegate>

@property (nonatomic, strong) FUCamera *camera ;
@property (weak, nonatomic) IBOutlet FUOpenGLView *renderView;

@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;

@property (nonatomic, strong) FUFigureView *figureView ;

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImage;
@property (weak, nonatomic) IBOutlet UILabel *pointLabel;
@property (nonatomic, strong) NSTimer *labelTimer ;

@property (nonatomic, strong) FUAvatar *currentAvatar ;

@end

@implementation FUEditViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
    [self.currentAvatar enterFacepupMode];
    
    [self.figureView setupFigureView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.camera startCapture];
    
    [self.currentAvatar resetScaleToFace];
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
    
    CGFloat locationY = [touch locationInView:self.renderView].y;
    CGFloat preLocationY = [touch previousLocationInView:self.renderView].y;
    
    float dy = (locationY - preLocationY) / self.renderView.frame.size.height ;
    
    [self.currentAvatar resetRotDelta:dx];
    [self.currentAvatar resetTranslateDelta:-dy];
}

-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
    
    CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:pixelBuffer RenderMode:FURenderCommonMode Landmarks:nil];
    
    [self.renderView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:YES];
}

// 返回
- (IBAction)backAction:(UIButton *)sender {

    if ([self isModeChanged]) {
        __weak typeof(self)weaklSelf = self ;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"是否保存当前形象编辑？" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"放弃" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [weaklSelf.camera stopCapture];
            
            if (self.figureView.currentHair != self.currentAvatar.hair) {
                NSString *hairPath = [[self.currentAvatar filePath] stringByAppendingPathComponent:self.currentAvatar.hair];
                if (![hairPath hasSuffix:@"bundle"]) {
                    hairPath = [hairPath stringByAppendingString:@".bundle"];
                }
                [self.currentAvatar reloadHairWithPath:hairPath];
            }
            if (self.figureView.currentCloth != self.currentAvatar.clothes) {
                NSString *clothes = self.currentAvatar.clothes ;
                NSString *clothesPath = [[NSBundle mainBundle] pathForResource:clothes ofType:@"bundle"];
                [self.currentAvatar reloadClothesWithPath:clothesPath];
            }
            if (self.figureView.currentGlasses != self.currentAvatar.glasses) {
                NSString *glassesPath = nil ;
                if (self.currentAvatar.glasses != nil && ![self.currentAvatar.glasses isEqualToString:@"glasses-noitem"]) {
                    NSString *glassName = [self.currentAvatar.glasses stringByAppendingString:@".bundle"];
                    glassesPath = [[NSBundle mainBundle] pathForResource:glassName ofType:nil];
                }
                [self.currentAvatar reloadGlassesWithPath:glassesPath];
            }
            
            if (self.figureView.currentBeard != self.currentAvatar.beard) {
                NSString *beardPath = nil ;
                if (self.currentAvatar.beard != nil && ![self.currentAvatar.beard isEqualToString:@"beard-noitem"]) {
                    NSString *beardName = [self.currentAvatar.beard stringByAppendingString:@".bundle"];
                    beardPath = [[NSBundle mainBundle] pathForResource:beardName ofType:nil];
                }
                [self.currentAvatar reloadBeardWithPath:beardPath];
            }
            
            if (self.figureView.currentHat != self.currentAvatar.hat) {
                NSString *hatPath = nil ;
                if (self.currentAvatar.hat != nil && ![self.currentAvatar.hat isEqualToString:@"hat-noitem"]) {
                    NSString *hatName = [self.currentAvatar.hat stringByAppendingString:@".bundle"];
                    hatPath = [[NSBundle mainBundle] pathForResource:hatName ofType:nil];
                }
                [self.currentAvatar reloadHatWithPath:hatPath];
            }
            
            if (self.figureView.currentEyeLash != self.currentAvatar.eyeLash) {
                NSString *hatPath = nil ;
                if (self.currentAvatar.eyeLash != nil && ![self.currentAvatar.eyeLash isEqualToString:@"eyelash-noitem"]) {
                    NSString *hatName = [self.currentAvatar.eyeLash stringByAppendingString:@".bundle"];
                    hatPath = [[NSBundle mainBundle] pathForResource:hatName ofType:nil];
                }
                [self.currentAvatar reloadEyeLashWithPath:hatPath];
            }
            
            if (self.figureView.currentEyeBrow != self.currentAvatar.eyeBrow) {
                NSString *hatPath = nil ;
                if (self.currentAvatar.eyeBrow != nil && ![self.currentAvatar.eyeBrow isEqualToString:@"eyeBrow-noitem"]) {
                    NSString *hatName = [self.currentAvatar.eyeBrow stringByAppendingString:@".bundle"];
                    hatPath = [[NSBundle mainBundle] pathForResource:hatName ofType:nil];
                }
                [self.currentAvatar reloadEyeBrowWithPath:hatPath];
            }
            
            [self.currentAvatar setAvatarColors];
            
            [self.currentAvatar quitFacepupMode];
            
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
        [self.currentAvatar setAvatarColors];
        [self.currentAvatar quitFacepupMode];
        [self.navigationController popViewControllerAnimated:NO];
    }
}

// 保存
- (IBAction)downLoadAction:(UIButton *)sender {
    sender.userInteractionEnabled = NO ;
    [self.camera stopCapture];
    [self.currentAvatar setAvatarColors];
    [self startLoadingAnimation];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL deformHead = [self.figureView figureViewIsChange] ;
        
        if (!deformHead && !self.currentAvatar.defaultModel) {
            
            self.currentAvatar.hair = self.figureView.currentHair ;
            self.currentAvatar.clothes = self.figureView.currentCloth ;
            self.currentAvatar.glasses = self.figureView.currentGlasses ;
            self.currentAvatar.beard = self.figureView.currentBeard ;
            self.currentAvatar.hat = self.figureView.currentHat ;
            self.currentAvatar.eyeLash = self.figureView.currentEyeLash ;
            self.currentAvatar.eyeBrow = self.figureView.currentEyeBrow ;
            
            self.currentAvatar.skinColor = self.figureView.skinColor ;
            self.currentAvatar.skinLevel = self.figureView.skinLevel ;
            self.currentAvatar.lipColor = self.figureView.lipColor ;
            self.currentAvatar.irisColor = self.figureView.irisColor ;
            self.currentAvatar.hairColor = self.figureView.hairColor ;
            self.currentAvatar.glassColor = self.figureView.glassesColor ;
            self.currentAvatar.glassFrameColor = self.figureView.glassesFrameColor ;
            self.currentAvatar.beardColor = self.figureView.beardColor ;
            self.currentAvatar.hatColor = self.figureView.hatColor ;
            
            [self.currentAvatar setAvatarColors];
            
            [self.currentAvatar quitFacepupMode];
            
            [self rewriteJsonInfoWithAvatar:self.currentAvatar];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:NO ];
            });
            return ;
        }
        
        float coeffi[38] = {
            self.figureView.cheekNarrow > 0 ? self.figureView.cheekNarrow : 0,
            self.figureView.cheekNarrow > 0 ? 0 : fabs(self.figureView.cheekNarrow),
            self.figureView.headShrink > 0 ? self.figureView.headShrink : 0,
            self.figureView.headShrink > 0 ? 0 : fabs(self.figureView.headShrink),
            0,
            0,
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
            self.figureView.headBoneStretch > 0 ? 0 : fabs(self.figureView.headBoneStretch),
            self.figureView.headBoneStretch > 0 ? self.figureView.headBoneStretch : 0,
        };
        
        FUAvatar *avatar = [[FUManager shareInstance] createPupAvatarWithCoeffi:coeffi DeformHead:deformHead];
        
        if (!avatar) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopLoadingAnimation];
                [SVProgressHUD showErrorWithStatus:@"模型保存失败，请重试"];
                [self.camera startCapture];
                sender.userInteractionEnabled = YES ;
                
            });
        }else {
            
            avatar.hair = self.figureView.currentHair ;
            avatar.clothes = self.figureView.currentCloth ;
            avatar.glasses = self.figureView.currentGlasses ;
            avatar.beard = self.figureView.currentBeard ;
            avatar.hat = self.figureView.currentHat ;
            avatar.eyeLash = self.figureView.currentEyeLash ;
            avatar.eyeBrow = self.figureView.currentEyeBrow ;
            
            avatar.skinColor = self.figureView.skinColor ;
            avatar.skinLevel = self.figureView.skinLevel ;
            avatar.lipColor = self.figureView.lipColor ;
            avatar.irisColor = self.figureView.irisColor ;
            avatar.hairColor = self.figureView.hairColor ;
            NSLog(@"--------------------- hair color r:%.2f - g:%.2f - b:%.2f ", avatar.hairColor.r, avatar.hairColor.g, avatar.hairColor.b);
            avatar.glassColor = self.figureView.glassesColor ;
            avatar.glassFrameColor = self.figureView.glassesFrameColor ;
            avatar.beardColor = self.figureView.beardColor ;
            avatar.hatColor = self.figureView.hatColor ;
            
            
            NSInteger replaceIndex = -1 ;
            for (FUAvatar *ava in [FUManager shareInstance].avatarList) {
                if ([ava.name isEqualToString:avatar.name]) {
                    replaceIndex = [[FUManager shareInstance].avatarList indexOfObject:ava];
                    break ;
                }
            }
            if (replaceIndex == -1) {
                [[FUManager shareInstance].avatarList insertObject:avatar atIndex:DefaultAvatarNum];
            }else {
                [[FUManager shareInstance].avatarList replaceObjectAtIndex: replaceIndex withObject:avatar];
            }
            
            
            [[FUManager shareInstance] reloadRenderAvatar:avatar];
            
            [avatar loadStandbyAnimation];
            
            [avatar setAvatarColors];
            
            [avatar quitFacepupMode];
            
            [self rewriteJsonInfoWithAvatar:avatar];
            
            // 避免 body 还没有加载完成。闪现上一个模型的画面。
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:NO ];
            });
        }
    });
}

- (void)rewriteJsonInfoWithAvatar:(FUAvatar *)avatar {
    NSString *jsonPath = [[AvatarListPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
    NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    if (tmpData != nil) {
        NSMutableDictionary *avatarInfo = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
        
        [avatarInfo setObject:avatar.hair forKey:@"hair"];
        [avatarInfo setObject:avatar.clothes forKey:@"clothes"];
        [avatarInfo setObject:avatar.glasses forKey:@"glasses"];
        [avatarInfo setObject:avatar.beard forKey:@"beard"];
        [avatarInfo setObject:avatar.hat forKey:@"hat"];
        [avatarInfo setObject:avatar.eyeLash forKey:@"eyeLash"];
        [avatarInfo setObject:avatar.eyeBrow forKey:@"eyeBrow"];
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:avatarInfo options:NSJSONWritingPrettyPrinted error:nil];
        [jsonData writeToFile:jsonPath atomically:YES];
    }
}

#pragma mark --- FUEditViewDelegate
- (BOOL)isModeChanged  {
    
    // 装饰
    if (self.figureView.currentHair != self.currentAvatar.hair
        || self.figureView.currentCloth != self.currentAvatar.clothes
        || self.figureView.currentGlasses != self.currentAvatar.glasses
        || self.figureView.currentBeard != self.currentAvatar.beard
        || self.figureView.currentHat != self.currentAvatar.hat
        || self.figureView.currentEyeLash != self.currentAvatar.eyeLash
        || self.figureView.currentEyeBrow != self.currentAvatar.eyeBrow) {
        
        return YES ;
    }
    
    // 捏脸参数
    if ([self.figureView figureViewIsChange]) {
        return YES ;
    }
    
    // 肤色
    if (self.figureView.skinLevel != self.figureView.defaultSkinLevel) {
        return YES ;
    }
    
    if ((self.currentAvatar.hairColor != nil && ![self.figureView.hairColor colorIsEqualTo: self.currentAvatar.hairColor])
//        || (self.currentAvatar.beardColor != nil && ![self.figureView.beardColor colorIsEqualTo: self.currentAvatar.beardColor])
        || (self.currentAvatar.glassColor != nil && ![self.figureView.glassesColor colorIsEqualTo: self.currentAvatar.glassColor])
        || (self.currentAvatar.glassFrameColor != nil && ![self.figureView.glassesFrameColor colorIsEqualTo: self.currentAvatar.glassFrameColor])
        || (self.currentAvatar.hatColor != nil && ![self.figureView.hatColor colorIsEqualTo: self.currentAvatar.hatColor])
        || (self.currentAvatar.irisColor != nil && ![self.figureView.irisColor colorIsEqualTo: self.currentAvatar.irisColor])
        || (self.currentAvatar.lipColor != nil && ![self.figureView.lipColor colorIsEqualTo: self.currentAvatar.lipColor])) {
        
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

// 捏合手势实现
- (void)figureViewDidReceiveZoomAction:(float)ds {
    [self.currentAvatar resetScaleDelta:ds];
}

// 头发
- (void)figureViewDidChangeHair:(NSString *)hairName {
    NSString *filePath = nil ;
    if ([hairName isEqualToString:@"hair-noitem"]) {
        filePath = nil ;
    }else {
        if (self.currentAvatar.name) {
            filePath = [[[self.currentAvatar filePath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];

        }else {
            filePath = [[[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:self.currentAvatar.name] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"] ;
        }
    }
    [self.currentAvatar reloadHairWithPath:filePath];
    self.downloadBtn.enabled = YES ;
}

// 胡子
- (void)figureViewDidChangeBeard:(NSString *)beardName {
    NSString *filePath = nil ;
    if ([beardName isEqualToString:@"beard-noitem"]) {
        filePath = nil ;
    }else {
        filePath = [[NSBundle mainBundle] pathForResource:beardName ofType:@"bundle"];
    }
    [self.currentAvatar reloadBeardWithPath:filePath];
    self.downloadBtn.enabled = YES ;
}

// 眉毛
- (void)figureViewDidChangeEyeBrow:(NSString *)browName {
    NSString *hatPath = nil ;
    if (browName && ![browName isEqualToString:@"eyebrow-noitem"]) {
        hatPath = [[NSBundle mainBundle] pathForResource:browName ofType:@"bundle"];
    }
    [self.currentAvatar reloadEyeBrowWithPath:hatPath];
    self.downloadBtn.enabled = YES ;
}

// 睫毛
- (void)figureViewDidChangeeyeLash:(NSString *)lashName {
    NSString *hatPath = nil ;
    if (lashName && ![lashName isEqualToString:@"eyelash-noitem"]) {
        hatPath = [[NSBundle mainBundle] pathForResource:lashName ofType:@"bundle"];
    }
    [self.currentAvatar reloadEyeLashWithPath:hatPath];
    self.downloadBtn.enabled = YES ;
}

// 帽子
- (void)figureViewDidChangeHat:(NSString *)hatName {
    NSString *hatPath = nil ;
    if (hatName && ![hatName isEqualToString:@"hat-noitem"]) {
        hatPath = [[NSBundle mainBundle] pathForResource:hatName ofType:@"bundle"];
    }
    [self.currentAvatar reloadHatWithPath:hatPath];
    self.downloadBtn.enabled = YES ;
}

// 衣服
- (void)figureViewDidChangeClothes:(NSString *)clothesName {
    NSString *filePath = nil ;
    if (![clothesName isEqualToString:@"noitem"]) {
        filePath = [[NSBundle mainBundle] pathForResource:clothesName ofType:@"bundle"];
    }
    [self.currentAvatar reloadClothesWithPath:filePath];
    self.downloadBtn.enabled = YES ;
}

// 眼镜
- (void)figureViewDidChangeGlasses:(NSString *)glassesName {
    
    NSString *filePath = nil ;
    if (![glassesName isEqualToString:@"glasses-noitem"]) {
        filePath = [[NSBundle mainBundle] pathForResource:glassesName ofType:@"bundle"];
    }
    [self.currentAvatar reloadGlassesWithPath:filePath];
    self.downloadBtn.enabled = YES ;
}

// 发色
- (void)figureViewDidChangeHairColor:(FUP2AColor *)hairColor {
    NSLog(@"--- haircolor - r:%.0f - g:%.0f - b:%.0f ", hairColor.r, hairColor.g, hairColor.b);
    [self.currentAvatar facepupModeSetColor:hairColor key:@"hair_color"];
    self.downloadBtn.enabled = YES ;
}

// 帽色
- (void)figureViewDidChangeHatColor:(FUP2AColor *)hatColor {
    [self.currentAvatar facepupModeSetColor:hatColor key:@"hat_color"];
    self.downloadBtn.enabled = YES ;
}

// 肤色
- (void)figureViewDidChangeSkinColor:(FUP2AColor *)skinColor {
    [self.currentAvatar facepupModeSetColor:skinColor key:@"skin_color"];
    self.downloadBtn.enabled = YES ;
}
// 瞳色
- (void)figureViewDidChangeIrisColor:(FUP2AColor *)irisColor {
    [self.currentAvatar facepupModeSetColor:irisColor key:@"iris_color"];
    self.downloadBtn.enabled = YES ;
}

// 唇色
- (void)figureViewDidChangeLipsColor:(FUP2AColor *)lipsColor {
    [self.currentAvatar facepupModeSetColor:lipsColor key:@"lip_color"];
    self.downloadBtn.enabled = YES ;
}

//  镜框颜色
- (void)figureViewDidChangeGlassesColor:(FUP2AColor *)color {
    [self.currentAvatar facepupModeSetColor:color key:@"glass_color"];
    self.downloadBtn.enabled = YES ;
}

//  镜片颜色
- (void)figureViewDidChangeGlassesFrameColor:(FUP2AColor *)color {
    [self.currentAvatar facepupModeSetColor:color key:@"glass_frame_color"];
    self.downloadBtn.enabled = YES ;
}

// 美型参数改变
- (void)figureViewShapeParamsDidChangedWithKey:(NSString *)key level:(double)level {
    [self.currentAvatar facepupModeSetParam:key level:level];
    self.downloadBtn.enabled = YES ;
}
// 页面类型选择
- (void)figureViewDidSelectedTypeWithIndex:(NSInteger)typeIndex {
    if (typeIndex == 10) {
        [self.currentAvatar resetScaleToSmallBody];
    }else {
        [self.currentAvatar resetScaleToFace];
    }
}
// 隐藏全部子页面
- (void)figureViewDidHiddenAllTypeViews {
    [self.currentAvatar resetScaleToBody];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
