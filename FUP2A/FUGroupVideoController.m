//
//  FUGroupVideoController.m
//  FUP2A
//
//  Created by LEE on 6/29/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUGroupVideoController.h"

@interface FUGroupVideoController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation FUGroupVideoController
- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self loadAssetFromFile];
    [self addObserver];
}

-(void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillResignActiveNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationWillEnterForegroundNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:UIApplicationDidBecomeActiveNotification];
}
- (void)addObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
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
	
	[[FUManager shareInstance].currentAvatars.firstObject resetScaleToSmallBody];
	UIViewController * lasTwoVC =  self.navigationController.viewControllers[1];
	[self.navigationController popToViewController:lasTwoVC animated:true];

}

- (IBAction)saveImage:(UIButton *)sender {
	[appManager checkSavePhotoAuth:^(PHAuthorizationStatus status) {
		if (status == PHAuthorizationStatusAuthorized) {
			if (self.videoPath && [[NSFileManager defaultManager] fileExistsAtPath:self.videoPath]) {
				[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
					[PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:[NSURL URLWithString:self.videoPath]];
				} completionHandler:^(BOOL success, NSError * _Nullable error) {
					
					if(success && error == nil){
						[SVProgressHUD showSuccessWithStatus:@"视频已保存到相册"];
					}else{
						[SVProgressHUD showErrorWithStatus:@"保存视频失败"];
					}
				}];
			}
		}
		
		else if (status == PHAuthorizationStatusDenied) {
			__weak typeof(self)weakSelf = self ;
			UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:nil message:@"请打开你的权限！" preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[appManager openAppSettingView];
			}];
			
			[alertVC addAction:certain];
			[self presentViewController:alertVC animated:YES completion:nil];
			
		}
	}];
	
}








- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}



#pragma AVPlayer  ===========================================

static const NSString *ItemStatusContext;
- (void)loadAssetFromFile {
	__weak typeof(self)weakSelf = self ;
	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:self.videoPath] options:nil];
	NSString *tracksKey = @"tracks";
	[asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:
	 ^{
		 // The completion block goes here.
		 
		 
		 
		 // Completion handler block.
		 dispatch_async(dispatch_get_main_queue(),
						^{
							NSError *error;
							AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
							
							if (status == AVKeyValueStatusLoaded) {
								weakSelf.playerItem = [AVPlayerItem playerItemWithAsset:asset];
								// ensure that this is done before the playerItem is associated with the player
								[weakSelf.playerItem addObserver:weakSelf forKeyPath:@"status"
														 options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
								[[NSNotificationCenter defaultCenter] addObserver:weakSelf
																		 selector:@selector(playerItemDidReachEnd:)
																			 name:AVPlayerItemDidPlayToEndTimeNotification
																		   object:weakSelf.playerItem];
								weakSelf.player = [AVPlayer playerWithPlayerItem:weakSelf.playerItem];
								[weakSelf.playerView setPlayer:weakSelf.player];
								[weakSelf.player play];
							}
							else {
								// You should deal with the error appropriately.
								NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
							}
						});
		 
		 
	 }];
	
	
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
	
	if (context == &ItemStatusContext) {
		dispatch_async(dispatch_get_main_queue(),
					   ^{
						   
					   });
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object
						   change:change context:context];
	return;
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
	[self.player seekToTime:kCMTimeZero];
	[self.player play];
	
}
- (void)dealloc
{
	[self.playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willResignActive    {
    
    if (self.navigationController.visibleViewController == self) {
         [self replay];
    }
}

- (void)willEnterForeground {
    
    if (self.navigationController.visibleViewController == self) {
         [self replay];
    }
}

- (void)didBecomeActive {
    
    if (self.navigationController.visibleViewController == self) {
        [self replay];
    }
}


- (void)replay
{
    if (@available(iOS 10.0, *)) {
        if (self.player.timeControlStatus != AVPlayerTimeControlStatusPlaying)
        {
            [self.player play];
        }
    } else {
        // Fallback on earlier versions
    }
}

@end
