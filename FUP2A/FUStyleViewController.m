//
//  FUStyleViewController.m
//  FUP2A
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUStyleViewController.h"
#import <Photos/Photos.h>
#import <SVProgressHUD.h>
#import "FUManager.h"
#import "FUAvatar.h"

@interface FUStyleViewController ()

@end

@implementation FUStyleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)qstyleSelected:(UIButton *)sender {
    
    [SVProgressHUD show];
    
    __weak typeof(self)weakSelf = self ;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf loadDefaultDataWithStyle:FUAvatarStyleQ];
    });
}

- (IBAction)basicStyleSelected:(UIButton *)sender {
    
    [SVProgressHUD show];
    
    __weak typeof(self)weakSelf = self ;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf loadDefaultDataWithStyle:FUAvatarStyleNormal];
    });
}

- (void)loadDefaultDataWithStyle:(FUAvatarStyle)style {
    
    [[FUManager shareInstance] setAvatarStyle:style];
    
    [[FUManager shareInstance] loadClientDataWithFirstSetup:YES];
    
    __weak typeof(self)weakSelf = self ;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [weakSelf loadDefaultAvatar];
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self performSegueWithIdentifier:@"showMainViewController" sender:nil];
        });
    });
}

- (void)loadDefaultAvatar {
    FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
    [[FUManager shareInstance] reloadRenderAvatar:avatar];
    [avatar loadStandbyAnimation];
}

- (void)getAuthorityOfPhotoLibrary {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
