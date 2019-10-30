//
//  FUTakePhotoController.m
//  FUP2A
//
//  Created by L on 2018/6/4.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUTakePhotoController.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "FUAvatar.h"
#import "FUManager.h"
#import "FUCamera.h"
#import "FUOpenGLView.h"
#import "FUTool.h"
#import "FURequestManager.h"
#import "CRender.h"
#import <FUP2AHelper/FUP2AHelper.h>
#import "FURenderer.h"

typedef enum : NSInteger {
	FUCurrentViewTypeNone,
	FUCurrentViewTypePreparingCreat,
	FUCurrentViewTypeCreating,
} FUCurrentViewType;


@interface FUTakePhotoController ()<
FUCameraDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
FULoadingViewDelegate
>
{
	BOOL takePhoto ;
	FUCurrentViewType currentType ;
	UIImage *selectedImage ;
	UIImage *iconImage ;
}
@property (nonatomic, strong) FUCamera *camera ;
@property (weak, nonatomic) IBOutlet FUOpenGLView *displayView ;
@property (weak, nonatomic) IBOutlet UIButton *libraryBtn;
@property (weak, nonatomic) IBOutlet UIButton *photoBtn;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;

@property (weak, nonatomic) IBOutlet UIView *loadingContainer;
@property (nonatomic, strong) FUPhotoLoadingView *loadingView ;

@property (nonatomic, strong) UIAlertController *backAlter ;
@end

@implementation FUTakePhotoController

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self addObserver];
	
	if (appManager.isXFamily) {
		self.imageView.image = [UIImage imageNamed:@"camera-mask-iphoneX"];
		self.imageView.backgroundColor = [UIColor clearColor];
	}
	
	currentType = FUCurrentViewTypeNone ;
	[self.camera startCapture ];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	//    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	//    [avatar destroyAvatar];
	//
	//    UIImage *image = [UIImage imageNamed:@"bgImage.png"];
	//    NSData *imageData = UIImagePNGRepresentation(image);
	//
	//    for(int i = 0 ; i < 3 ; i ++) {
	//        [[FURenderer shareRenderer] renderItems:imageData.bytes inFormat:FU_FORMAT_BGRA_BUFFER outPtr:imageData.bytes outFormat:FU_FORMAT_BGRA_BUFFER width:image.size.width height:image.size.height frameId:i items:nil itemCount:0 flipx:NO];
	//    }
	//
	//    [FURenderer destroyAllItems];
}

-(void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.backAlter dismissViewControllerAnimated:YES completion:nil];
	currentType = FUCurrentViewTypeNone ;
	//
	//    NSString *bgPath = [[NSBundle mainBundle] pathForResource:@"bg" ofType:@"bundle"];
	//    [[FUManager shareInstance] reloadBackGroundWithFilePath:bgPath];
	//    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	//    [[FUManager shareInstance] reloadRenderAvatar:avatar];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"FUPhotoLoadingView"]) {
		UIViewController *vc = segue.destinationViewController ;
		self.loadingView = (FUPhotoLoadingView *)vc.view ;
		self.loadingView.mDelegate = self ;
	}
}

// 返回
- (IBAction)backAction:(UIButton *)sender {
	
	[self.camera stopCapture];
	
	switch (currentType) {
		case FUCurrentViewTypeNone:{
			[self.navigationController popViewControllerAnimated:YES];
		}
			break;
		default:{
			if (!self.backAlter) {
				self.backAlter = [UIAlertController alertControllerWithTitle:nil message:@"您确认放弃生成吗？" preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
				__weak typeof(self)weakSelf = self ;
				UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					
					self->currentType = FUCurrentViewTypeNone ;
					[weakSelf.loadingView stopLoading];
					weakSelf.loadingContainer.hidden = YES ;
					weakSelf.photoImageView.hidden = YES ;
					weakSelf.imageView.hidden = NO ;
					[weakSelf.camera startCapture];
					weakSelf.photoBtn.hidden = NO ;
					weakSelf.libraryBtn.hidden = NO ;
					weakSelf.switchBtn.hidden = NO ;
				}];
				
				[self.backAlter addAction:cancle];
				[self.backAlter addAction:certain];
			}
			
			[self presentViewController:self.backAlter animated:YES completion:nil];
		}
			break ;
	}
}

// 切换
- (IBAction)onCameraChange:(UIButton *)sender {
	
	self.camera.shouldMirror = !self.camera.shouldMirror ;
	[self.camera changeCameraInputDeviceisFront:!self.camera.isFrontCamera];
}

// 相册
- (IBAction)photoLibrary:(UIButton *)sender {
	
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	
	picker.delegate = self;
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.allowsEditing = NO;
	
	[self.camera stopCapture];
	
	[self presentViewController:picker animated:YES completion:nil];
}

// 拍摄
- (IBAction)takePic:(UIButton *)sender {
	takePhoto = YES ;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
	// 关闭相册
	[picker dismissViewControllerAnimated:YES completion:nil];
	
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	// 图片转正
	if (image.imageOrientation != UIImageOrientationUp || image.imageOrientation != UIImageOrientationUpMirrored) {
		
		UIGraphicsBeginImageContext(CGSizeMake(image.size.width, image.size.height));
		
		[image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
		
		image = UIGraphicsGetImageFromCurrentImageContext();
		
		UIGraphicsEndImageContext();
	}
	
	currentType = FUCurrentViewTypePreparingCreat ;
	
	selectedImage = image ;
	iconImage = image ;
	self.photoImageView.image = image ;
	self.photoImageView.hidden = NO ;
	self.imageView.hidden = YES ;
	self.messageLabel.hidden = YES ;
	self.photoBtn.hidden = YES ;
	self.libraryBtn.hidden = YES ;
	self.switchBtn.hidden = YES ;
	[self selectedGenderAndLoading];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	// 关闭相册
	[picker dismissViewControllerAnimated:YES completion:nil];
	[self.camera startCapture];
}

#pragma mark ---- loading

-(FUCamera *)camera {
	if (!_camera) {
		_camera = [[FUCamera alloc] init];
		_camera.delegate = self ;
		_camera.shouldMirror = YES ;
		[_camera changeCameraInputDeviceisFront:YES];
	}
	return _camera ;
}

#pragma mark ---- FUCameraDelegate

static int frameID = 0;
-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	
	CVPixelBufferRef buffer = [[FUManager shareInstance] trackFaceWithBuffer:sampleBuffer];
	[self.displayView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:NO];
	
	frameID ++ ;
	if (frameID % 15 == 0) {
		
		NSString *message  = [[FUManager shareInstance] photoDetectionAction];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.messageLabel.text = message ;
		});
	}
	
	if (takePhoto) {
		takePhoto = NO ;
		
		CGRect faceRect = [[FUManager shareInstance] getFaceRect];
		
		if (CGSizeEqualToSize(faceRect.size, CGSizeZero)) {
			self->currentType = FUCurrentViewTypeNone ;
			[self downloadErrorWithMessage:@"面部识别失败，请重新尝试。"];
			self->iconImage = nil ;
			self->selectedImage = nil ;
			
			return ;
		}
		
		CVPixelBufferRef imageBuffer = [[CRender shareRenderer] cutoutPixelBuffer:buffer WithRect:faceRect];
		
		iconImage = [self.camera getSquareImageFromBuffer:imageBuffer];
		
		selectedImage = [[FUP2AHelper shareInstance] createImageWithBuffer:buffer mirr:NO];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[self.camera stopCapture];
			
			self->currentType = FUCurrentViewTypePreparingCreat ;
			
			self.photoImageView.image = self->selectedImage ;
			self.photoImageView.hidden = NO ;
			self.imageView.hidden = YES ;
			self.messageLabel.hidden = YES ;
			self.photoBtn.hidden = YES ;
			self.libraryBtn.hidden = YES ;
			self.switchBtn.hidden = YES ;
			[self selectedGenderAndLoading];
		});
	}
}

#pragma mark ---- selected gender/type

- (void)selectedGenderAndLoading {
	
	[self.camera stopCapture];
	self.loadingContainer.hidden = NO ;
	[self.view bringSubviewToFront:self.backBtn];
}

-(void)shouldCreateAvatarWithGender:(FUGender)gender {
	[self createAvatarWithGender:gender ];
	[self.loadingView startLoading];
}


#pragma mark ---- creat Avatar

- (void)createAvatarWithGender:(FUGender)gender {
	
	currentType = FUCurrentViewTypeCreating ;
	
	NSDictionary *params = @{
		@"gender":@(gender),
		@"is_q": @(1),
	};
	
	NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
	NSString *fileName = [NSString stringWithFormat:@"%.0f", time];
	NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
	[[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
	CFAbsoluteTime startUpdateTime = CFAbsoluteTimeGetCurrent() ;
	[[FURequestManager sharedInstance] createQAvatarWithImage:selectedImage Params:params CompletionWithData:^(NSData *data, NSError *error) {
		if (!error && data) {
			
			if (self->currentType == FUCurrentViewTypeNone) {
				return ;
			}
			NSLog(@"------------ server time: %f ms", (CFAbsoluteTimeGetCurrent() - startUpdateTime) * 1000.0);
			UIImage *image = self->iconImage ? self->iconImage : self->selectedImage;
			NSData *imageData = UIImagePNGRepresentation(image) ;
			NSString *imagePath = [filePath stringByAppendingPathComponent:@"image.png"] ;
			[imageData writeToFile:imagePath atomically:YES];
			
			[data writeToFile:[filePath stringByAppendingPathComponent:FU_SERVER_BUNDLE] atomically:YES];
			
			if (self->currentType == FUCurrentViewTypeNone) {
				[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
				return ;
			}
			
			FUAvatar *avatar = [[FUManager shareInstance] createAvatarWithData:data avatarName:fileName gender:gender];
			//     [avatar resetScaleToBody];
			if (avatar) {
				
				if (self->currentType == FUCurrentViewTypeNone) {
					[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
					return ;
				}
				
				[[FUManager shareInstance] reloadRenderAvatar:avatar];
				[avatar loadStandbyAnimation];
				
				[[FUManager shareInstance].avatarList insertObject:avatar atIndex:DefaultAvatarNum];
				
				// 避免 body 还没有加载完成。闪现上一个模型的画面。
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					
					self->currentType = FUCurrentViewTypeNone ;
					[self.loadingView stopLoading];
					self.loadingContainer.hidden = YES ;
					
					NSLog(@"------------------------------------------------------------------------------ create avatar completed ~");
					[avatar resetScaleToBody];
					[avatar setTheDefaultColors];
					
					[self.navigationController popViewControllerAnimated:YES ];
				});
			}else {
				self->currentType = FUCurrentViewTypeNone ;
				[self downloadErrorWithMessage:@"本地解析错误"];
				self->iconImage = nil ;
				self->selectedImage = nil ;
			}
			
		}else{
			
			
			NSDictionary *userInfo = error.userInfo;
			NSHTTPURLResponse *response = userInfo[@"com.alamofire.serialization.response.error.response"];
			NSInteger code = response.statusCode;
			
			NSString *message = @"网络访问错误" ;
			NSString *str0 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			if ([str0 isEqualToString:@"上传的图片未检测到人脸！"]) {
				message = str0;
			}else if (code == 500) {
				NSData *data = userInfo[@"com.alamofire.serialization.response.error.data"];
				
				NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				
				if ([str isEqualToString:@"server busy"]) {
					message = @"服务器被占用" ;
				}else if ([str isEqualToString:@"输入参数错误"]){
					message = @"bad input" ;
				}else {
					int errIndex = [str intValue] ;
					message = [self getErrorMessageWithIndex:errIndex];
				}
			}
			
			
			self->currentType = FUCurrentViewTypeNone ;
			[self downloadErrorWithMessage:message];
			self->iconImage = nil ;
			self->selectedImage = nil ;
		}
	}];
}

- (void)downloadErrorWithMessage:(NSString *)message {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[SVProgressHUD showInfoWithStatus:message];
		[self.loadingView stopLoading];
		
		self.loadingContainer.hidden = YES ;
		self.photoImageView.hidden = YES ;
		self.imageView.hidden = NO ;
		self.messageLabel.hidden = NO ;
		[self.camera startCapture];
		self.photoBtn.hidden = NO ;
		self.libraryBtn.hidden = NO ;
		self.switchBtn.hidden = NO ;
	}) ;
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
		switch (currentType) {
			case FUCurrentViewTypeNone:{
				[self.camera startCapture];
			}
				break;
			case FUCurrentViewTypePreparingCreat:
				break;
			case FUCurrentViewTypeCreating:{
				[self.loadingView startLoading];
			}
				break ;
		}
	}
}

- (void)didBecomeActive {
	
	if (self.navigationController.visibleViewController == self) {
		switch (currentType) {
			case FUCurrentViewTypeNone:{
				[self.camera startCapture];
			}
				break;
			case FUCurrentViewTypePreparingCreat:
				break;
			case FUCurrentViewTypeCreating:{
				[self.loadingView startLoading];
			}
				break ;
		}
	}
}

- (UIImage *)cutImage:(UIImage *)image size:(CGSize)size {
	
	CGRect desRect = CGRectMake((image.size.width - size.width)/2.0, (image.size.height - size.height)/2.0, size.width, size.height) ;
	CGImageRef subImageRef = CGImageCreateWithImageInRect(image.CGImage, desRect);
	CGRect smallRect = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
	UIGraphicsBeginImageContext(smallRect.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextDrawImage(context, smallRect, subImageRef);
	UIImage *image0 = [UIImage imageWithCGImage:subImageRef];
	UIGraphicsEndImageContext();
	CGImageRelease(subImageRef);
	return image0;
}

- (NSString *)getErrorMessageWithIndex:(int)errorIndex {
	NSString *message ;
	switch (errorIndex) {
		case 1:
			message = @"无法加载输入图片" ;
			break;
		case 2:
			message = @"未检测到人脸" ;
			break;
		case 3:
			message = @"检测到多个人脸" ;
			break;
		case 4:
			message = @"检测不到头发" ;
			break;
		case 5:
			message = @"输入图片不符合要求" ;
			break;
		case 6:
			message = @"非正脸图片" ;
			break;
		case 7:
			message = @"非清晰人脸" ;
			break;
		case 8:
			message = @"未找到匹配发型" ;
			break;
		case 9:
			message = @"未知错误" ;
			break;
		case 10:
			message = @"FOV错误" ;
			break;
			
		default:
			message = @"未知错误" ;
			break;
	}
	return message ;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

@end
