//
//  FUTakePhotoController.m
//  FUP2A
//
//  Created by L on 2018/6/4.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUTakePhotoController.h"
#import <UIKit/UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "FUPhotoLoadingView.h"


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

@property (nonatomic, assign)  FUCurrentViewType currentType ;
@property (nonatomic, strong)  UIImage *selectedImage ;
@property (nonatomic, strong)  UIImage *iconImage ;
@property (nonatomic, strong) CRender *viewRender;
@end

@implementation FUTakePhotoController

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self addObserver];
    self.viewRender = [[CRender alloc]init];
	if (appManager.isXFamily) {
		self.imageView.image = [UIImage imageNamed:@"camera-mask-iphoneX"];
		self.imageView.backgroundColor = [UIColor clearColor];
	}
	
	self.currentType = FUCurrentViewTypeNone ;
	[self.camera startCapture ];
    [[FUManager shareInstance] enableFaceCapture:1];
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
	self.currentType = FUCurrentViewTypeNone ;
	
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
    
	switch (self.currentType) {
		case FUCurrentViewTypeNone:{
            [[FUManager shareInstance]enableFaceCapture:0];
			[self.navigationController popViewControllerAnimated:YES];
		}
			break;
		default:{
			if (!self.backAlter) {
				self.backAlter = [UIAlertController alertControllerWithTitle:nil message:@"您确认放弃生成吗？" preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
				__weak FUTakePhotoController *weakSelf = self ;
				UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					
					weakSelf.currentType = FUCurrentViewTypeNone ;
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
	
	self.currentType = FUCurrentViewTypePreparingCreat ;
	
	self.selectedImage = image ;
	self.iconImage = image ;
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
	
	__weak typeof(self)weakSelf = self ;
	
	// CVPixelBufferRef buffer =  CMSampleBufferGetImageBuffer(sampleBuffer) ;
	float lightValue = 0;
	CVPixelBufferRef buffer = [[FUManager shareInstance] trackFaceWithBuffer:sampleBuffer CurrentlLightingValue:&lightValue];
	dispatch_async(dispatch_get_main_queue(), ^{
	});
	int h = (int)CVPixelBufferGetHeight(buffer);
	int w = (int)CVPixelBufferGetWidth(buffer);
	if (self.camera.isFrontCamera) {
        CVPixelBufferRef mirrorBuffer = [self.viewRender cutoutPixelBufferInXMirror:buffer WithRect:CGRectMake(0, 0, w, h)];
		[self.displayView displayPixelBuffer:mirrorBuffer withLandmarks:nil count:0 Mirr:NO];
		
	}else{
		[self.displayView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:NO];
		
	}
	frameID ++ ;
	if (frameID % 15 == 0) {
		
		NSString *message  = [[FUManager shareInstance] photoDetectionAction];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			weakSelf.messageLabel.text = message ;
		});
	}
	
	if (takePhoto) {
		takePhoto = NO ;
		
		CGRect faceRect = [[FUManager shareInstance] getFaceRect];

        if (CGSizeEqualToSize(faceRect.size, CGSizeZero)) {
			self.currentType = FUCurrentViewTypeNone ;
			[self downloadErrorWithMessage:@"面部识别失败，请重新尝试。"];
			self.iconImage = nil ;
			self.selectedImage = nil ;
			return ;
		}
		
		CVPixelBufferRef imageBuffer;
		
		
		
		if (self.camera.isFrontCamera) {
			imageBuffer = [self.viewRender cutoutPixelBufferInXMirror:buffer WithRect:faceRect];
			self.iconImage = [self.camera getSquareImageFromBuffer:imageBuffer];
			self.selectedImage = [[FUP2AHelper shareInstance] createImageWithBuffer:buffer mirr:YES];
		}else{
			imageBuffer = [self.viewRender cutoutPixelBuffer:buffer WithRect:faceRect];
			self.iconImage = [self.camera getSquareImageFromBuffer:imageBuffer];
			self.selectedImage = [[FUP2AHelper shareInstance] createImageWithBuffer:buffer mirr:NO];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[weakSelf.camera stopCapture];
			
			weakSelf.currentType = FUCurrentViewTypePreparingCreat ;
			
			weakSelf.photoImageView.image = weakSelf.selectedImage ;
			weakSelf.photoImageView.hidden = NO ;
			weakSelf.imageView.hidden = YES ;
			weakSelf.messageLabel.hidden = YES ;
			weakSelf.photoBtn.hidden = YES ;
			weakSelf.libraryBtn.hidden = YES ;
			weakSelf.switchBtn.hidden = YES ;
			[weakSelf selectedGenderAndLoading];
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

- (void)downloadErrorWithMessage:(NSString *)message {
	__weak typeof(self)weakSelf = self ;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		[SVProgressHUD showInfoWithStatus:message];
		[weakSelf.loadingView stopLoading];
		
		weakSelf.loadingContainer.hidden = YES ;
		weakSelf.photoImageView.hidden = YES ;
		weakSelf.imageView.hidden = NO ;
		weakSelf.messageLabel.hidden = NO ;
		[weakSelf.camera startCapture];
		weakSelf.photoBtn.hidden = NO ;
		weakSelf.libraryBtn.hidden = NO ;
		weakSelf.switchBtn.hidden = NO ;
	}) ;
}

- (void)createAvatarWithGender:(FUGender)gender {
	
	self.currentType = FUCurrentViewTypeCreating ;
	
	NSDictionary *params = @{
		@"gender":@(gender),
		@"is_q": @(1),
	};
	
	NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
	NSString *fileName = [NSString stringWithFormat:@"%.0f", time];
	NSString *filePath = [documentPath stringByAppendingPathComponent:fileName];
	[[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
	CFAbsoluteTime startUpdateTime = CFAbsoluteTimeGetCurrent() ;
	__weak typeof(self)weakSelf = self;
    
    NSData *imageData = UIImageJPEGRepresentation(self.selectedImage, 0.1) ;
    UIImage *updateImage = [UIImage imageWithData:imageData];

	[[FURequestManager sharedInstance] createQAvatarWithImage:updateImage Params:params CompletionWithData:^(BOOL createAvatarSuccess, NSDictionary *resultDic, NSError *error) {
		if (createAvatarSuccess) {   // YES代表生成成功
			
			if (weakSelf.currentType == FUCurrentViewTypeNone) {
				return ;
			}
            
			NSString * headUrlPath  = resultDic[@"data"];
			CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
			NSData * headData = [NSData dataWithContentsOfURL:[NSURL URLWithString:headUrlPath]];
            NSLog(@"------------ avatar download time: %f ms", (CFAbsoluteTimeGetCurrent() - endTime) * 1000.0);
            endTime = CFAbsoluteTimeGetCurrent();
			UIImage *image = weakSelf.iconImage ? weakSelf.iconImage : weakSelf.selectedImage;
			NSData *imageData = UIImagePNGRepresentation(image) ;
			NSString *imagePath = [filePath stringByAppendingPathComponent:@"image.png"] ;
			[imageData writeToFile:imagePath atomically:YES];
			
			//      [data writeToFile:[filePath stringByAppendingPathComponent:FU_SERVER_BUNDLE] atomically:YES];
			
			if (weakSelf.currentType == FUCurrentViewTypeNone)
            {
				[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
				return ;
			}
			
			FUAvatar *avatar = [[FUManager shareInstance] createAvatarWithData:headData avatarName:fileName gender:gender];
			//     [avatar resetScaleToBody];
            NSLog(@"------------ avatar create time: %f ms", (CFAbsoluteTimeGetCurrent() - endTime) * 1000.0);
            NSLog(@"------------ avatar total time: %f ms", (CFAbsoluteTimeGetCurrent() - startUpdateTime) * 1000.0);
			if (avatar)
            {
				if (weakSelf.currentType == FUCurrentViewTypeNone)
                {
					[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
					return ;
				}
				
				[[FUManager shareInstance] reloadAvatarToControllerWithAvatar:avatar];
				[avatar loadStandbyAnimation];
				
				[[FUManager shareInstance].avatarList insertObject:avatar atIndex:DefaultAvatarNum];
//				[avatar setTheDefaultColors];
				// 避免 body 还没有加载完成。闪现上一个模型的画面。
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					
					weakSelf.currentType = FUCurrentViewTypeNone ;
					[weakSelf.loadingView stopLoading];
					weakSelf.loadingContainer.hidden = YES ;
					
					NSLog(@"------------------------------------------------------------------------------ create avatar completed ~");
					[avatar resetScaleToBody];
					
                    [[FUManager shareInstance]enableFaceCapture:0];
					[weakSelf.navigationController popViewControllerAnimated:YES ];
				});
			}else {
				weakSelf.currentType = FUCurrentViewTypeNone ;
				[weakSelf downloadErrorWithMessage:@"本地解析错误"];
				weakSelf.iconImage = nil ;
				weakSelf.selectedImage = nil ;
			}
			
		}else{   // 生成avatar失败，处理失败结果
			
			NSString *message;
			if (error) {   // 如果存在网络请求的系统错误
				if(error.code == FUAppVersionInvalid)
				{
					message = @"testflight 存在新版App，请您更新！";
				}else{
					message = [error localizedDescription];
				}
			}else{   // 这里是nama服务器返回的nama相关错误
				int errorCode = [resultDic[@"data"][@"err_code"] intValue];
				message = [weakSelf getErrorMessageWithIndex:errorCode];
			}
			
			weakSelf.currentType = FUCurrentViewTypeNone ;
			[weakSelf downloadErrorWithMessage:message];
			weakSelf.iconImage = nil ;
			weakSelf.selectedImage = nil ;
		}
	}];
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
		switch (self.currentType) {
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
		switch (self.currentType) {
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
	NSLog(@"errorIndex------%d",errorIndex);
	switch (errorIndex) {
		case 2:
			message = @"未检测到人脸" ;
			break;
		case 5:
			message = @"输入图片不符合要求" ;
			break;
		case 6:
			message = @"非正脸图片" ;
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
-(void)dealloc{
	NSLog(@"FUTakePhotoController---------销毁了");
}

@end
