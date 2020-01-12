//
//  FUGroupImageController.m
//  FUP2A
//
//  Created by L on 2018/12/19.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUGroupImageController.h"


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
	
	FUAvatar *avatar = [FUManager shareInstance].avatarList.firstObject;
	[avatar setCurrentAvatarIndex:0];
	[[FUManager shareInstance]reloadRenderAvatarInSameController:avatar];
	
	if (![[FUManager shareInstance] isBackgroundItemExist]) {
		NSString *bgPath = [[NSBundle mainBundle] pathForResource:@"default_bg.bundle" ofType:nil];
		[[FUManager shareInstance] reloadBackGroundAndBindToController:bgPath];
	}
	UIViewController * lasTwoVC =  self.navigationController.viewControllers[1];
	[self.navigationController popToViewController:lasTwoVC animated:true];
}

- (IBAction)saveImage:(UIButton *)sender {
	if (self.image) {
		NSData* pngdata = UIImagePNGRepresentation (self.image);
		UIImage* img = [UIImage imageWithData:pngdata];
		UIImage* orientationImage = img;
		if (!self.shouldMirrorPohoto) {
			
			orientationImage = [UIImage imageWithCGImage:img.CGImage
															scale:img.scale
													  orientation:UIImageOrientationUpMirrored];
		}
		UIImageWriteToSavedPhotosAlbum(orientationImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
	}
#if 0
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
#else
	if (self.gifPath && [[NSFileManager defaultManager] fileExistsAtPath:self.gifPath]) {
		NSData *data = [NSData dataWithContentsOfFile:self.gifPath];
		
		[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
			[PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:self.gifPath]];
		} completionHandler:^(BOOL success, NSError * _Nullable error) {
			
			if(success && error == nil){
				[SVProgressHUD showSuccessWithStatus:@"动图已保存到相册"];
			}else{
				[SVProgressHUD showErrorWithStatus:@"保存动图失败"];
			}
		}];
	}
#endif
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
