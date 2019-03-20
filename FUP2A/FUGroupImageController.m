//
//  FUGroupImageController.m
//  FUP2A
//
//  Created by L on 2018/12/19.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUGroupImageController.h"
#import <SVProgressHUD.h>
#import "FUManager.h"
#import "FUAvatar.h"
#import <Photos/Photos.h>
#import <SVProgressHUD.h>
#import <UIImage+GIF.h>

@interface FUGroupImageController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation FUGroupImageController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.image) {
        self.imageView.image = self.image ;
    }
    if (self.gifPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:self.gifPath]) {
        NSData *gifData = [NSData dataWithContentsOfFile:self.gifPath];
        self.imageView.image = [UIImage sd_animatedGIFWithData:gifData];
    }
}

- (IBAction)backAction:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backToRoot:(UIButton *)sender {
    
    if ([FUManager shareInstance].currentAvatars.count != 0) {
        NSArray *tmpArr = [[FUManager shareInstance].currentAvatars copy];;
        for (FUAvatar *avatar in tmpArr) {
            [[FUManager shareInstance] removeRenderAvatar:avatar];
        }
    }
    
    [[FUManager shareInstance] addRenderAvatar:self.currentAvatar];
    [self.currentAvatar loadStandbyAnimation];
    
    if (![[FUManager shareInstance] isBackgroundItemExist]) {
        NSString *bgPath = [[NSBundle mainBundle] pathForResource:@"bg.bundle" ofType:nil];
        [[FUManager shareInstance] reloadBackGroundWithFilePath:bgPath];
    }
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)saveImage:(UIButton *)sender {
    if (self.image) {
        UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    }
    if (self.gifPath && [[NSFileManager defaultManager] fileExistsAtPath:self.gifPath]) {
        NSData *data = [NSData dataWithContentsOfFile:self.gifPath];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:data options:nil];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            if(success && error == nil){
                [SVProgressHUD showSuccessWithStatus:@"动图已保存到相册"];
            }else{
                [SVProgressHUD showErrorWithStatus:@"保存动图失败"];
            }
        }];
    }
}

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo  {
    if(error != NULL){
        [SVProgressHUD showErrorWithStatus:@"保存合影失败"];
    }else{
        [SVProgressHUD showSuccessWithStatus:@"合影已保存到相册"];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
