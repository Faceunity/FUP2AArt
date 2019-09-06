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

@interface FUStyleViewController ()<FULoadingViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *QStyleButton;
@property (weak, nonatomic) IBOutlet UIButton *NormalStyleButton;
@property (weak, nonatomic) IBOutlet UIView *loadingContainer;
@property (nonatomic, strong) FULoadingView *loadingView ;

@end

@implementation FUStyleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)qstyleSelected:(UIButton *)sender {
    
        self.loadingContainer.hidden = NO;
        [self.loadingView startLoading];
    self.QStyleButton.enabled = false;
    self.NormalStyleButton.enabled = false;
    __weak typeof(self)weakSelf = self ;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf loadDefaultDataWithStyle:FUAvatarStyleQ];
    });
}

- (IBAction)basicStyleSelected:(UIButton *)sender {
    
    [SVProgressHUD show];
	self.QStyleButton.enabled = false;
    self.NormalStyleButton.enabled = false;
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
			weakSelf.QStyleButton.enabled = true;
            weakSelf.NormalStyleButton.enabled = true;
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FUStyleLoadingView"]) {
        UIViewController *vc = segue.destinationViewController ;
        self.loadingView = (FUPhotoLoadingView *)vc.view ;
        self.loadingView.mDelegate = self ;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
