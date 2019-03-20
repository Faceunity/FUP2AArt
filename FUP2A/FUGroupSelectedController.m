//
//  FUGroupSelectedController.m
//  FUP2A
//
//  Created by L on 2018/12/19.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUGroupSelectedController.h"
#import "FUOpenGLView.h"
#import "FUCamera.h"
#import "FUAvatar.h"
#import "FUManager.h"
#import "FUP2ADefine.h"
#import "UIColor+FU.h"
#import "FUSceneryModel.h"
#import <SVProgressHUD.h>
#import "FUGroupImageController.h"
#import "CRender.h"
#import <FUP2AHelper/FUP2AHelper.h>

typedef enum : NSUInteger {
    GroupSelectedRunModeCommon          = 0,
    GroupSelectedRunModePhotoTake,
    GroupSelectedRunModeVideoRecord,
} GroupSelectedRunMode;

@interface FUGroupSelectedController ()
<
FUCameraDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate
>

{
    NSInteger modelCount ;
    NSMutableArray *selectedIndex ;
    
    GroupSelectedRunMode renderMode ;
    int animationFrameCount ;
    
    BOOL customRenderBackground ;
    
    __block NSString *gifPath ;
}
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (nonatomic, strong) FUCamera *camera ;
@property (weak, nonatomic) IBOutlet FUOpenGLView *glView;

@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (nonatomic, strong) dispatch_semaphore_t signal ;
@end

@implementation FUGroupSelectedController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addObserver];
    
    selectedIndex = [NSMutableArray arrayWithCapacity:1];
    
    self.signal = dispatch_semaphore_create(1) ;
    
    renderMode = GroupSelectedRunModeCommon ;
    animationFrameCount = 0 ;
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    [[FUManager shareInstance] removeRenderAvatar:avatar];
    
    [self showDefaultTips];
    
    customRenderBackground = NO ;
    
    [self.camera startCapture ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.camera startCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.camera stopCapture];
}

- (void)showDefaultTips {
    NSString *message ;
    switch (self.sceneryModel) {
        case FUSceneryModeSingle:{
            message = self.singleModel.gender == FUGenderMale ? @"请选择一个男模型" : @"请选择一个女模型";
        }
            break;
        case FUSceneryModeMultiple:{
            message = @"请选择一男一女模型" ;
        }
            break ;
        case FUSceneryModeAnimation:{
            message = self.animationModel.gender == FUGenderMale ? @"请选择一个男模型" : @"请选择一个女模型";
        }
            break ;
    }
    self.tipLabel.text = message ;
}

- (IBAction)changeBackgroundImage:(UIButton *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];

    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;

    [self.camera stopCapture];

    if (self.sceneryModel == FUSceneryModeAnimation && [FUManager shareInstance].currentAvatars.count != 0) {
        renderMode = GroupSelectedRunModeCommon;
        [[FUP2AHelper shareInstance] cancleRecord];
        [self setNextBtnEnable:NO];
    }

    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)backAction:(UIButton *)sender {
    
    [self.camera stopCapture];
    
    if ([FUManager shareInstance].currentAvatars.count != 0) {
        NSArray *tmpArr = [[FUManager shareInstance].currentAvatars copy];;
        for (FUAvatar *avatar in tmpArr) {
            [[FUManager shareInstance] removeRenderAvatar:avatar];
        }
    }
    
    [[FUP2AHelper shareInstance] cancleRecord];
    
    if (![[FUManager shareInstance] isBackgroundItemExist]) {
        
        NSString *bgPath = [[NSBundle mainBundle] pathForResource:@"bg.bundle" ofType:nil];
        [[FUManager shareInstance] reloadBackGroundWithFilePath:bgPath];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FUGroupImageController"]) {
        FUGroupImageController *controller = (FUGroupImageController *)segue.destinationViewController ;
        switch (self.sceneryModel) {
            case FUSceneryModeSingle:
            case FUSceneryModeMultiple:{
                controller.image = (UIImage *)sender ;
            }
                break;
            case FUSceneryModeAnimation:{
                controller.gifPath = (NSString *)sender ;
            }
                break ;
        }
        controller.currentAvatar = self.currentAvatar ;
    }
}

- (IBAction)nextAction:(UIButton *)sender {
    switch (self.sceneryModel) {
        case FUSceneryModeSingle:
        case FUSceneryModeMultiple:{
            renderMode = GroupSelectedRunModePhotoTake ;
        }
            break;
        case FUSceneryModeAnimation:{
            
            [self.camera stopCapture];
            
            [self performSegueWithIdentifier:@"FUGroupImageController" sender:gifPath];
        }
            break ;
    }
}

-(void)setSceneryModel:(FUSceneryMode)sceneryModel {
    _sceneryModel = sceneryModel ;
    switch (sceneryModel) {
        case FUSceneryModeSingle:{
            modelCount = 1 ;
        }
            break;
        case FUSceneryModeMultiple:{
            modelCount = 2;
        }
            break ;
        case FUSceneryModeAnimation: {
            modelCount = 1 ;
            break;
        }
    }
}

-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER) ;
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
    
    CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:pixelBuffer RenderMode:FURenderCommonMode Landmarks:nil];
    
    if (customRenderBackground) {
        buffer = [[CRender shareRenderer] mergeBgImageToBuffer:buffer];
    }
    
    [self.glView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:YES];
    
    switch (renderMode) {
        case GroupSelectedRunModeCommon:
            break;
        case GroupSelectedRunModePhotoTake:{
            renderMode = GroupSelectedRunModeCommon ;
            UIImage *image = [[FUP2AHelper shareInstance] createImageWithBuffer:buffer mirr:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.camera stopCapture];
                [self performSegueWithIdentifier:@"FUGroupImageController" sender:image];
            });
        }
            break ;
        case GroupSelectedRunModeVideoRecord:{

            [[FUP2AHelper shareInstance] recordBufferWithType:FUP2AHelperRecordTypeGIF buffer:buffer sampleBuffer:sampleBuffer];

            FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
            int index = [avatar getCurrentAnimationFrameIndex];
            if (index == animationFrameCount - 1) {
                renderMode = GroupSelectedRunModeCommon ;

                __weak typeof(self)weakSelf = self ;
                [[FUP2AHelper shareInstance] stopRecordWithType:FUP2AHelperRecordTypeGIF Completion:^(NSString *retPath) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf setNextBtnEnable:YES];
                        self->gifPath = retPath ;
                    });
                }];
            }
        }
            break ;
    }
    
    dispatch_semaphore_signal(self.signal) ;
}

- (int)shouldAddCurrentAvatar:(FUAvatar *)avatar {
    
    switch (_sceneryModel) {
        case FUSceneryModeSingle:
        case FUSceneryModeAnimation:    {
            
            FUSingleModel *model = self.sceneryModel == FUSceneryModeSingle ? self.singleModel : self.animationModel ;
            if (model.gender != avatar.gender) {
                switch (model.gender) {
                    case FUGenderMale:
                        return 1 ;
                        break;
                    case FUGenderFemale:
                        return 2 ;
                        break ;
                        
                    default:
                        break;
                }
            }
            return 0 ;
        }
            break;
        case FUSceneryModeMultiple:{
            if ([FUManager shareInstance].currentAvatars.count == 1) {
                FUAvatar *currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
                if (avatar.gender == currentAvatar.gender) {
                    return 3 ;
                }
            }
            return 0 ;
        }
            break ;
    }
}

- (NSString *)getErrorMessageWithCode:(int)code {
    NSString *message = nil ;
    switch (code) {
        case 1:{
            message = @"请选择男性模型" ;
        }
            break;
        case 2:{
            message = @"请选择女性模型" ;
        }
            break;
        case 3:{
            message = @"请选择一男一女模型" ;
        }
            break;
        default:
            break;
    }
    return message ;
}

#pragma mark ----- 以下 UI
#pragma mark ---- <UICollectionViewDataSource, UICollectionViewDelegate>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [FUManager shareInstance].avatarList.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUGroupSelectedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUGroupSelectedCell" forIndexPath:indexPath];
    
    FUAvatar *avatar = [FUManager shareInstance].avatarList[indexPath.row];
    UIImage *image = [UIImage imageWithContentsOfFile:avatar.imagePath];
    cell.imageView.image = image;
    
    BOOL selected = [selectedIndex containsObject:@(indexPath.row)] ;
    cell.layer.borderWidth = selected ? 2.0 : 0.0;
    cell.layer.borderColor = selected ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor;
    
    switch (self.sceneryModel) {
        case FUSceneryModeSingle:
        case FUSceneryModeAnimation:
        {
            FUSingleModel *model = self.sceneryModel == FUSceneryModeSingle ? self.singleModel : self.animationModel ;
            cell.maskImage.hidden = (model.gender == avatar.gender) && (selectedIndex.count != modelCount || selected) ;
        }
            break;
        case FUSceneryModeMultiple:{
            if (selectedIndex.count == modelCount) {
                cell.maskImage.hidden = selected ;
            }else {
                FUAvatar *a = [FUManager shareInstance].currentAvatars.firstObject;
                cell.maskImage.hidden = !a || selected || a.gender != avatar.gender ;
            }
        }
            break;
    }
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    collectionView.userInteractionEnabled = NO ;
    
    FUAvatar *avatar = [FUManager shareInstance].avatarList[indexPath.row];
    
    if ([selectedIndex containsObject:@(indexPath.row)]) {  // 取消
        [selectedIndex removeObject:@(indexPath.row)];
        [collectionView reloadData];
        
        [[FUManager shareInstance] removeRenderAvatar:avatar];
        
        [self setNextBtnEnable:NO];
        
        renderMode = GroupSelectedRunModeCommon ;
        
        switch (self.sceneryModel) {
            case FUSceneryModeSingle:{
                [self showDefaultTips];
            }
                break ;
            case FUSceneryModeAnimation:{
                
                [self showDefaultTips];
                
                [[FUP2AHelper shareInstance] cancleRecord];
            }
                break;
            case FUSceneryModeMultiple:{
                if (selectedIndex.count == 0) {
                    self.tipLabel.text = @"请选择一男一女模型" ;
                }else {
                    NSString *message = [FUManager shareInstance].currentAvatars.firstObject.gender == FUGenderFemale ? @"请选择一个男模型" : @"请选择一个女模型";
                    self.tipLabel.text = message ;
                }
            }
                break;
        }
        collectionView.userInteractionEnabled = YES ;
        return ;
    }
    
    if (selectedIndex.count == modelCount) {
        collectionView.userInteractionEnabled = YES ;
        return ;
    }
    
    int messageCode = [self shouldAddCurrentAvatar:avatar];
    if (messageCode != 0) {
        collectionView.userInteractionEnabled = YES ;
        return ;
    }
    
    dispatch_semaphore_wait(self.signal, DISPATCH_TIME_FOREVER) ;
    
    self.tipLabel.text = @"生成中...";
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 增加
        [self->selectedIndex addObject:@(indexPath.row)];
        dispatch_async(dispatch_get_main_queue(), ^{
            [collectionView reloadData];
        });
        
        [[FUManager shareInstance] addRenderAvatar:avatar];
        
        [avatar avatarSetParamWithKey:@"target_scale" value:350];
        [avatar avatarSetParamWithKey:@"target_trans" value:65];
        [avatar avatarSetParamWithKey:@"target_angle" value:0];
        [avatar avatarSetParamWithKey:@"reset_all" value:1];
        
        switch (self.sceneryModel) {
            case FUSceneryModeSingle:{
                NSString *animationPath = [[NSBundle mainBundle] pathForResource:self.singleModel.animationName ofType:@"bundle"];
                [avatar reloadAnimationWithPath:animationPath];
                
                if (self->selectedIndex.count == self->modelCount) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setNextBtnEnable:YES];
                    });
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.tipLabel.text = @"完美" ;
                });
            }
                break;
            case FUSceneryModeMultiple:{
                NSString *animation ;
                for (FUSingleModel *model in self.multipleModel.modelArray) {
                    if (model.gender == avatar.gender) {
                        animation = model.animationName ;
                        break ;
                    }
                }
                NSString *animationPath = [[NSBundle mainBundle] pathForResource:animation ofType:@"bundle"];
                [avatar reloadAnimationWithPath:animationPath];
                
                if (self->selectedIndex.count == self->modelCount) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setNextBtnEnable:YES];
                        self.tipLabel.text = @"完美" ;
                    });
                }else {
                    NSString *message = [FUManager shareInstance].currentAvatars.firstObject.gender == FUGenderFemale ? @"请选择一个男模型" : @"请选择一个女模型";
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.tipLabel.text = message ;
                    });
                }
            }
                break ;
            case FUSceneryModeAnimation: {
                NSString *animationPath = [[NSBundle mainBundle] pathForResource:self.animationModel.animationName ofType:@"bundle"];
                [avatar reloadAnimationWithPath:animationPath];
                
                self->animationFrameCount = [avatar getAnimationFrameCount];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.tipLabel.text = @"完美" ;
                });
                
                [[FUP2AHelper shareInstance] startRecordWithType:FUP2AHelperRecordTypeGIF];
                
                self->renderMode = GroupSelectedRunModeVideoRecord ;
            }
                break;
        }
        
        dispatch_semaphore_signal(self.signal) ;
        dispatch_async(dispatch_get_main_queue(), ^{
            collectionView.userInteractionEnabled = YES ;
        });
    });
}

- (void)setNextBtnEnable:(BOOL)enable {
    
    self.nextBtn.enabled = enable ;
    self.nextBtn.selected = enable ;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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


#pragma mark ---- select images
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // 关闭相册
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [self.camera startCapture];
    
    if (image) {
        
        [self exchangeRenderBackgroundWithImage:image];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // 关闭相册
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.camera startCapture];
}

- (void)exchangeRenderBackgroundWithImage:(UIImage *)image {
    
    [[FUManager shareInstance] reloadBackGroundWithFilePath:nil];
    
    [CRender shareRenderer].bgImage = image;
    
    customRenderBackground = YES ;
    
    if (self.sceneryModel == FUSceneryModeAnimation && [FUManager shareInstance].currentAvatars.count != 0) {
        
        FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject ;
        
        [avatar restartAnimation];
        
        renderMode = GroupSelectedRunModeVideoRecord ;
        [[FUP2AHelper shareInstance] startRecordWithType:FUP2AHelperRecordTypeGIF];
    }
}


@end

@implementation FUGroupSelectedCell

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.masksToBounds = YES ;
        self.layer.cornerRadius = 8.0 ;
        self.imageView.layer.masksToBounds = YES ;
        self.imageView.layer.cornerRadius = 8.0 ;
        self.maskImage.layer.masksToBounds = YES ;
        self.maskImage.layer.cornerRadius = 8.0 ;
    }
    return self ;
}

@end

