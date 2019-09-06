//
//  FUEditViewController.m
//  FUP2A
//
//  Created by L on 2018/8/22.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUEditViewController.h"


@interface FUEditViewController ()
<
FUCameraDelegate,
FUFigureViewDelegate
>
{
	BOOL transforming ;
	__block FUFigureShapeType shapeType ;
	
	FUMeshPoint *currentMeshPoint ;
	UIButton *_figureViewUndoBtn;
	UIButton *_figureViewRedoBtn;
}
@property (nonatomic, strong) FUCamera *camera ;
@property (weak, nonatomic) IBOutlet FUOpenGLView *renderView;

@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong)NSString * willLoadHairName;     // 当hair.bundle 没有本地化完成时，先保存，当本地化完成后再加载
@property (nonatomic, strong) FUFigureView *figureView ;

@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImage;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;   // eg: 模型保存中

@property (weak, nonatomic) IBOutlet UILabel *pointLabel;
@property (nonatomic, strong) NSTimer *labelTimer ;

@property (nonatomic, strong) FUAvatar *currentAvatar ;

@property (nonatomic, strong) NSMutableArray *currentMeshPoints ;
@property (weak, nonatomic) IBOutlet UIImageView *tipImage;
@property (nonatomic, strong) dispatch_semaphore_t meshSigin ;

@property (weak, nonatomic) IBOutlet UIButton *faceBtn;
@property (weak, nonatomic) IBOutlet UIView *doAndUndoView;
@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@property (weak, nonatomic) IBOutlet UIButton *redoBtn;

@end

@implementation FUEditViewController

- (BOOL)prefersStatusBarHidden{
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	appManager.editVC = self;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(HairsWriteToLocalSuccessNotMethod) name:HairsWriteToLocalSuccessNot object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUNielianEditManagerStackNotEmptyNotMethod) name:FUNielianEditManagerStackNotEmptyNot object:nil];
	
	self.currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
	[self.currentAvatar enterFacepupMode];
	
	self.currentMeshPoints = [NSMutableArray arrayWithCapacity:1];
	
	transforming = NO ;
	shapeType = FUFigureShapeTypeNone ;
	
	currentMeshPoint = nil ;
	
	[[FUShapeParamsMode shareInstance] resetDefaultParamsWithAvatar:self.currentAvatar];
	
	self.meshSigin = dispatch_semaphore_create(1) ;
	[self.currentAvatar recordOriginalColors];
	
	self.doAndUndoView.layer.shadowColor = [UIColor colorWithRed:35/255.0 green:53/255.0 blue:95/255.0 alpha:0.15].CGColor;
	//[UIColor colorWithRed:35/255.0 green:53/255.0 blue:95/255.0 alpha:0.15].CGColor;
	self.doAndUndoView.layer.shadowOffset = CGSizeMake(0,1);
	self.doAndUndoView.layer.shadowOpacity = 1;
	self.doAndUndoView.layer.shadowRadius = 6;
	
}
-(void)FUNielianEditManagerStackNotEmptyNotMethod{
	if (![FUNielianEditManager sharedInstance].undoStack.isEmpty) {
		self.undoBtn.enabled = YES;
	}
	if (![FUNielianEditManager sharedInstance].redoStack.isEmpty) {
		self.redoBtn.enabled = YES;
	}
}

-(void)HairsWriteToLocalSuccessNotMethod{
	[self figureViewDidChangeHair:self.willLoadHairName];
	[self stopLoadingHairAnimation];
}
-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[FUAvatarEditManager sharedInstance] clear];
    [[FUNielianEditManager sharedInstance] clear];
	[FUAvatarEditManager sharedInstance].enterEditVC = YES;
	[self.camera startCapture];
	
	[self.currentAvatar resetScaleToFace];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"FUFigureView"]){
		UIViewController *vc = segue.destinationViewController ;
		self.figureView = (FUFigureView *)vc.view ;
		
		[self figureViewLoadData];
		
		self.figureView.delegate = self ;
	}
}

- (void)figureViewLoadData {
	
	self.figureView.avatarStyle = [FUManager shareInstance].avatarStyle ;
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	BOOL isMale = avatar.gender == FUGenderMale ;
	self.figureView.avatarIsMale = isMale ;
	
	// decorations
	switch ([FUManager shareInstance].avatarStyle) {
		case FUAvatarStyleNormal:{
			
			self.figureView.hairArray = isMale ? [FUManager shareInstance].maleHairs : [FUManager shareInstance].femaleHairs ;
			self.figureView.beardArray = isMale ? [FUManager shareInstance].maleBeards : @[] ;
			self.figureView.eyeBrowArray = isMale ? [FUManager shareInstance].maleEyeBrows : [FUManager shareInstance].femaleEyeBrows ;
			self.figureView.eyeLashArray = isMale ? @[] : [FUManager shareInstance].femaleEyeLashs ;
			self.figureView.glassesArray = isMale ? [FUManager shareInstance].maleGlasses : [FUManager shareInstance].femaleGlasses ;
			self.figureView.hatArray = isMale ? [FUManager shareInstance].maleHats : [FUManager shareInstance].femaleHats ;
			self.figureView.clothesArray = isMale ? [FUManager shareInstance].maleClothes : [FUManager shareInstance].femaleClothes ;
			self.figureView.faceArray = @[@"捏脸", @"face_1", @"face_2", @"face_3", @"face_4"] ;
			self.figureView.eyeArray = @[@"捏脸", @"eye_1", @"eye_2", @"eye_3", @"eye_4"] ;
			self.figureView.mouthArray = @[@"捏脸", @"mouth_1", @"mouth_2", @"mouth_3", @"mouth_4"] ;
			self.figureView.noseArray = @[@"捏脸", @"nose_1", @"nose_2", @"nose_3", @"nose_4"] ;
		}
			break;
		case FUAvatarStyleQ:{
			self.figureView.hairArray = [FUManager shareInstance].qHairs ;
			self.figureView.beardArray = [FUManager shareInstance].qBeard ;
			self.figureView.eyeBrowArray = [FUManager shareInstance].qEyeBrow ;
			self.figureView.eyeLashArray = [FUManager shareInstance].qEyeLash ;
			self.figureView.glassesArray = [FUManager shareInstance].qGlasses ;
			self.figureView.hatArray = [FUManager shareInstance].qHats ;
			self.figureView.clothesArray = [FUManager shareInstance].qClothes ;
			
			self.figureView.faceArray = @[@"捏脸", @"face_1", @"face_2", @"face_3", @"face_4"] ;
			self.figureView.eyeArray = @[@"捏脸", @"eye_1", @"eye_2", @"eye_3", @"eye_4"] ;
			self.figureView.mouthArray = @[@"捏脸", @"mouth_1", @"mouth_2", @"mouth_3", @"mouth_4"] ;
			self.figureView.noseArray = @[@"捏脸", @"nose_1", @"nose_2", @"nose_3", @"nose_4"] ;
			
			self.figureView.shoesArray = [FUManager shareInstance].qShoes ;
		}
			break ;
	}
	
	self.figureView.hair = avatar.hair ;
	self.figureView.beard = avatar.beard ;
	self.figureView.eyeBrow = avatar.eyeBrow ;
	self.figureView.eyeLash = avatar.eyeLash ;
	self.figureView.glasses = avatar.glasses ;
	self.figureView.hat = avatar.hat ;
	self.figureView.clothes = avatar.clothes ;
	self.figureView.face = avatar.face ;
	self.figureView.eyes = avatar.eyes ;
	self.figureView.mouth = avatar.mouth ;
	self.figureView.nose = avatar.nose ;
	self.figureView.shoes = avatar.shoes ;
	
	self.figureView.skinColorArray = [FUManager shareInstance].skinColorArray;
	self.figureView.skinProgress = avatar.skinColorProgress;
	
	self.figureView.irisColorArray = [FUManager shareInstance].irisColorArray;
	self.figureView.irisLevel = avatar.irisLevel ;
	self.figureView.irisProgress = avatar.irisColorProgress;
	
	self.figureView.lipsColorArray = [FUManager shareInstance].lipColorArray;
	self.figureView.lipLevel = avatar.lipsLevel ;
	self.figureView.lipProgress = avatar.lipColorProgress;
	
	
	
	
	
	self.figureView.hairColorArray = [FUManager shareInstance].hairColorArray;
	self.figureView.hairColor = avatar.hairColor ? avatar.hairColor : [FUManager shareInstance].hairColorArray[0] ;
	
	self.figureView.beardColorArray = [FUManager shareInstance].beardColorArray;
	self.figureView.beardColor = avatar.beardColor ? avatar.beardColor : [FUManager shareInstance].beardColorArray[0] ;
	
	self.figureView.glassesFrameColorArray = [FUManager shareInstance].glassFrameArray;
	self.figureView.glassesFrameColor = avatar.glassFrameColor ? avatar.glassFrameColor : [FUManager shareInstance].glassFrameArray[0] ;
	
	self.figureView.glassesColorArray = [FUManager shareInstance].glassColorArray;
	self.figureView.glassesColor = avatar.glassColor ? avatar.glassColor : [FUManager shareInstance].glassColorArray[0] ;
	
	self.figureView.glassColorIndex = avatar.glassColorIndex;
	self.figureView.glassFrameColorIndex = avatar.glassFrameColorIndex;
	
	self.figureView.hatColorArray = [FUManager shareInstance].hatColorArray;
	self.figureView.hatColor = avatar.hatColor ? avatar.hatColor : [FUManager shareInstance].hatColorArray[0] ;
	
	[self.figureView setupFigureView];
}



-(void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) ;
	
	CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:pixelBuffer RenderMode:FURenderCommonMode Landmarks:nil];
	
	[self.renderView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:YES];
	
	if (transforming) {
		[self reloadPointCoordinates];
	}
}

// 返回
- (IBAction)backAction:(UIButton *)sender {
	
	if (transforming) {
		transforming = NO ;
		
		[self showFigureView:YES];
		
		[self removeMeshPoints];
		
		[self.currentAvatar resetScaleToFace];
		

		self.faceBtn.hidden = YES ;
		shapeType = FUFigureShapeTypeNone ;
		return ;
	}
	
	if ([self isModeChanged]) {
		__weak typeof(self)weaklSelf = self ;
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"是否保存当前形象编辑？" preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"放弃" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		NSDictionary *dict = nil ;
			switch (shapeType) {
			case FUFigureShapeTypeFaceSide:
			case FUFigureShapeTypeFaceFront: {
				dict = [[FUShapeParamsMode shareInstance] resetHeadParams];
			}
				break;
			case FUFigureShapeTypeLipsSide:
			case FUFigureShapeTypeLipsFront:{
				dict = [[FUShapeParamsMode shareInstance] resetMouthParams];
			}
				break ;
			case FUFigureShapeTypeEyesSide:
			case FUFigureShapeTypeEyesFront:{
				dict = [[FUShapeParamsMode shareInstance] resetEyesParams];
			}
				break ;
			case FUFigureShapeTypeNoseSide:
			case FUFigureShapeTypeNoseFront: {
				dict = [[FUShapeParamsMode shareInstance] resetNoseParams];
			}
				break ;
			default:
				break;
		}
		
		if (dict) {
			
			[weaklSelf resetParamsWithDict:dict];
		}
			[weaklSelf.camera stopCapture];
			[self.currentAvatar backToOriginalColors];
			if (self.figureView.hair != self.currentAvatar.hair) {
				NSString *hairPath = [[self.currentAvatar filePath] stringByAppendingPathComponent:self.currentAvatar.hair];
				if (![hairPath hasSuffix:@"bundle"]) {
					hairPath = [hairPath stringByAppendingString:@".bundle"];
				}
				[self.currentAvatar reloadHairWithPath:hairPath];
			}
			if (self.figureView.clothes != self.currentAvatar.clothes) {
				NSString *clothes = self.currentAvatar.clothes ;
				NSString *clothesPath = [[NSBundle mainBundle] pathForResource:clothes ofType:@"bundle"];
				[self.currentAvatar reloadClothesWithPath:clothesPath];
			}
			if (self.figureView.glasses != self.currentAvatar.glasses) {
				NSString *glassesPath = nil ;
				if (self.currentAvatar.glasses != nil && ![self.currentAvatar.glasses isEqualToString:@"glasses-noitem"]) {
					NSString *glassName = [self.currentAvatar.glasses stringByAppendingString:@".bundle"];
					glassesPath = [[NSBundle mainBundle] pathForResource:glassName ofType:nil];
				}
				[self.currentAvatar reloadGlassesWithPath:glassesPath];
			}
			
			if (self.figureView.beard != self.currentAvatar.beard) {
				NSString *beardPath = nil ;
				if (self.currentAvatar.beard != nil && ![self.currentAvatar.beard isEqualToString:@"beard-noitem"]) {
					NSString *beardName = [self.currentAvatar.beard stringByAppendingString:@".bundle"];
					beardPath = [[NSBundle mainBundle] pathForResource:beardName ofType:nil];
				}
				[self.currentAvatar reloadBeardWithPath:beardPath];
			}
			
			if (self.figureView.hat != self.currentAvatar.hat) {
				NSString *hatPath = nil ;
				if (self.currentAvatar.hat != nil && ![self.currentAvatar.hat isEqualToString:@"hat-noitem"]) {
					NSString *hatName = [self.currentAvatar.hat stringByAppendingString:@".bundle"];
					hatPath = [[NSBundle mainBundle] pathForResource:hatName ofType:nil];
				}
				[self.currentAvatar reloadHatWithPath:hatPath];
			}
			
			if (self.figureView.eyeLash != self.currentAvatar.eyeLash) {
				NSString *hatPath = nil ;
				if (self.currentAvatar.eyeLash != nil && ![self.currentAvatar.eyeLash isEqualToString:@"eyelash-noitem"]) {
					NSString *hatName = [self.currentAvatar.eyeLash stringByAppendingString:@".bundle"];
					hatPath = [[NSBundle mainBundle] pathForResource:hatName ofType:nil];
				}
				[self.currentAvatar reloadEyeLashWithPath:hatPath];
			}
			
			if (self.figureView.eyeBrow != self.currentAvatar.eyeBrow) {
				NSString *hatPath = nil ;
				if (self.currentAvatar.eyeBrow != nil && ![self.currentAvatar.eyeBrow isEqualToString:@"eyeBrow-noitem"]) {
					NSString *hatName = [self.currentAvatar.eyeBrow stringByAppendingString:@".bundle"];
					hatPath = [[NSBundle mainBundle] pathForResource:hatName ofType:nil];
				}
				[self.currentAvatar reloadEyeBrowWithPath:hatPath];
			}
			//	[self.figureView resetUI];
			self.currentAvatar.face = nil ;
			self.currentAvatar.eyes = nil ;
			self.currentAvatar.mouth = nil;
			self.currentAvatar.nose = nil;
			
			[self.currentAvatar setAvatarColors];
			
			[self.currentAvatar quitFacepupMode];
			[self.currentAvatar resetScaleToSmallBody];
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
		[self.currentAvatar resetScaleToSmallBody];
		[self.navigationController popViewControllerAnimated:NO];
	}
}

// 保存
- (IBAction)downLoadAction:(UIButton *)sender {
	if (transforming) {
		transforming = NO ;
		self.faceBtn.hidden = YES ;
		shapeType = FUFigureShapeTypeNone ;
		
		[self showFigureView:YES];
		
		[self removeMeshPoints];
		
		[self.currentAvatar resetScaleToFace];
		
		return ;
	}
	[self refreshCurrentAvatarState];
	sender.userInteractionEnabled = NO ;
	[self.camera stopCapture];
	[self.currentAvatar setAvatarColors];
	[self startLoadingSaveAvartAnimation];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		BOOL deformHead = [[FUShapeParamsMode shareInstance] propertiesIsChanged] ;
		if (!deformHead && !self.currentAvatar.defaultModel) {
			
			
			[self.currentAvatar quitFacepupMode];
			
			[self rewriteJsonInfoWithAvatar:self.currentAvatar];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.currentAvatar resetScaleToSmallBody];
				[self.navigationController popViewControllerAnimated:NO ];
			});
			return ;
		}
		
		NSArray *params = [[FUShapeParamsMode shareInstance] finalShapeParams];
		int count = (int)params.count ;
		float coeffi[count] ;
		for (int i = 0 ; i < count; i ++) {
			coeffi[i] = [params[i] floatValue] ;
		}
		
		FUAvatar *avatar = [[FUManager shareInstance] createPupAvatarWithCoeffi:coeffi DeformHead:deformHead];
		
		if (!avatar) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.currentAvatar backToOriginalColors];
				[self stopLoadingSaveAvartAnimation];
				[SVProgressHUD showErrorWithStatus:@"模型保存失败，请重试"];
				[self.camera startCapture];
				sender.userInteractionEnabled = YES ;
			});
		}else {
			
			
			
			if ([[FUShapeParamsMode shareInstance] shouldDeformHair]) {
				//     if (0) {
				NSData *headData = [NSData dataWithContentsOfFile:[[avatar filePath] stringByAppendingPathComponent:FU_HEAD_BUNDLE]];
				
				NSString *baseHairPath = [[NSBundle mainBundle] pathForResource:avatar.hair ofType:@"bundle"] ;
				NSData *baseHairData = [NSData dataWithContentsOfFile: baseHairPath];
				
				NSData *defaultHairData = [[FUP2AClient shareInstance] deformAvatarHairWithDefaultHairData:baseHairData currentHeadData:headData];
				NSString *defaultHairPath = [[[avatar filePath] stringByAppendingPathComponent:avatar.hair] stringByAppendingString:@".bundle"];
				[defaultHairData writeToFile:defaultHairPath atomically:YES];
				
				// create other hairs
				dispatch_async(dispatch_get_global_queue(0, 0), ^{
					NSArray *hairs ;
					if (avatar.isQType) {
						hairs = [FUManager shareInstance].qHairs ;
					}else {
						hairs = avatar.gender == FUGenderMale ? [FUManager shareInstance].maleHairs : [FUManager shareInstance].femaleHairs ;
					}
					for (NSString *hairName in hairs) {
						if ([hairName isEqualToString:@"hair-noitem"] || [hairName isEqualToString:@"hair_q_noitem"] || [hairName isEqualToString:avatar.hair]) {
							continue ;
						}
						NSString *hairPath = [[NSBundle mainBundle] pathForResource:hairName ofType:@"bundle"];
						NSData *d0 = [NSData dataWithContentsOfFile:hairPath];
						
						NSData *d1 = [[FUP2AClient shareInstance] deformAvatarHairWithDefaultHairData:d0 currentHeadData:headData];
						if (d1 == nil) {
							NSLog(@"---- error path: %@", hairPath);
						}
						NSString *hp = [[[avatar filePath] stringByAppendingPathComponent:hairName] stringByAppendingString:@".bundle"];
						[d1 writeToFile:hp atomically:YES];
					}
				});
			}
			
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
			    [avatar resetScaleToSmallBody];
				[self.navigationController popViewControllerAnimated:NO ];
			});
		}
	});
}
-(void)refreshCurrentAvatarState{
	self.currentAvatar.hair = self.figureView.hair ;
	self.currentAvatar.clothes = self.figureView.clothes ;
	self.currentAvatar.glasses = self.figureView.glasses ;
	self.currentAvatar.beard = self.figureView.beard ;
	self.currentAvatar.hat = self.figureView.hat ;
	self.currentAvatar.shoes = self.figureView.shoes ;
	self.currentAvatar.eyeLash = self.figureView.eyeLash ;
	self.currentAvatar.eyeBrow = self.figureView.eyeBrow ;
	
	self.currentAvatar.skinColorProgress = self.figureView.skinProgress;
	// 获取皮肤颜色
	self.currentAvatar.skinColor = self.figureView.getSkinColor;
	self.currentAvatar.lipsLevel = self.figureView.lipLevel ;
	self.currentAvatar.lipColorProgress = self.figureView.lipProgress;
	
	self.currentAvatar.lipColor = self.figureView.getLipColor;
	self.currentAvatar.irisLevel = self.figureView.irisLevel ;
	self.currentAvatar.irisColorProgress = self.figureView.irisProgress;
	self.currentAvatar.irisColor = self.figureView.getIrisColor;
	self.currentAvatar.hairColor = self.figureView.hairColor ;
	self.currentAvatar.glassColor = self.figureView.glassesColor ;
	self.currentAvatar.glassFrameColor = self.figureView.glassesFrameColor ;
	self.currentAvatar.glassColorIndex = self.figureView.glassColorIndex;
	self.currentAvatar.glassFrameColorIndex = self.figureView.glassFrameColorIndex;
	self.currentAvatar.hatColor = self.figureView.hatColor ;
	
	[self.currentAvatar setAvatarColors];
	
}

- (void)rewriteJsonInfoWithAvatar:(FUAvatar *)avatar {
	NSString *rootPath = CurrentAvatarStylePath ;
	NSString *jsonPath = [[rootPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
	NSData *tmpData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
	if (tmpData != nil) {
		NSMutableDictionary *avatarInfo = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
		
		[avatarInfo setObject:avatar.hair forKey:@"hair"];
		[avatarInfo setObject:avatar.clothes forKey:@"clothes"];
		[avatarInfo setObject:avatar.glasses forKey:@"glasses"];
		[avatarInfo setObject:avatar.beard ? avatar.beard : @"beard-noitem" forKey:@"beard"];
		[avatarInfo setObject:avatar.hat ? avatar.hat : @"hat-noitem" forKey:@"hat"];
		[avatarInfo setObject:avatar.eyeLash ? avatar.eyeLash : @"noitem" forKey:@"eyeLash"];
		[avatarInfo setObject:avatar.eyeBrow ? avatar.eyeBrow : @"noitem" forKey:@"eyeBrow"];
		[avatarInfo setObject:avatar.face ? avatar.face : @"捏脸" forKey:@"face"];
		[avatarInfo setObject:avatar.eyes ? avatar.eyes : @"捏脸" forKey:@"eyes"];
		[avatarInfo setObject:avatar.mouth ? avatar.mouth : @"捏脸" forKey:@"mouth"];
		[avatarInfo setObject:avatar.nose ? avatar.nose : @"捏脸" forKey:@"nose"];
		
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:avatarInfo options:NSJSONWritingPrettyPrinted error:nil];
		[jsonData writeToFile:jsonPath atomically:YES];
	}
}

#pragma mark --- FUEditViewDelegate
- (BOOL)isModeChanged  {
	if (![FUAvatarEditManager sharedInstance].undoStack.isEmpty || ![FUAvatarEditManager sharedInstance].redoStack.isEmpty) {
		return YES;
	}
	// 装饰
	if (self.figureView.hair != self.currentAvatar.hair
		|| self.figureView.clothes != self.currentAvatar.clothes
		|| self.figureView.glasses != self.currentAvatar.glasses
		|| self.figureView.beard != self.currentAvatar.beard
		|| self.figureView.hat != self.currentAvatar.hat
		|| self.figureView.eyeLash != self.currentAvatar.eyeLash) {
		
		return YES ;
	}
	
	if (self.currentAvatar.isQType) {
		if (self.figureView.shoes != self.currentAvatar.shoes) {
			return YES ;
		}
	}else {
		if (self.figureView.eyeBrow != self.currentAvatar.eyeBrow) {
			return YES ;
		}
	}
	
	
	// 捏脸参数
	if ([[FUShapeParamsMode shareInstance] propertiesIsChanged]) {
		return YES ;
	}
	
	if ((self.currentAvatar.hairColor != nil && ![self.figureView.hairColor colorIsEqualTo: self.currentAvatar.hairColor])
		|| (self.currentAvatar.glassColor != nil && ![self.figureView.glassesColor colorIsEqualTo: self.currentAvatar.glassColor])
		|| (self.currentAvatar.glassFrameColor != nil && ![self.figureView.glassesFrameColor colorIsEqualTo: self.currentAvatar.glassFrameColor])
		|| (self.currentAvatar.hatColor != nil && ![self.figureView.hatColor colorIsEqualTo: self.currentAvatar.hatColor])
		|| self.currentAvatar.irisLevel != self.figureView.irisLevel
		|| self.currentAvatar.lipsLevel != self.figureView.lipLevel) {
		
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

// 模型保存动画
- (void)startLoadingSaveAvartAnimation {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.loadingLabel.text = @"模型保存中";
		[self startLoadingAnimation];
	});
}

- (void)stopLoadingSaveAvartAnimation {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self stopLoadingAnimation];
	});
}
// 加载发型动画
- (void)startLoadingHairAnimation {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.loadingLabel.text = @"发型加载中";
		self.view.userInteractionEnabled = false;
		[self startLoadingAnimation];
	});
}
- (void)stopLoadingHairAnimation {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.view.userInteractionEnabled = true;
		[self stopLoadingAnimation];
	});
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
// Avatar 旋转
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event];
	
	if (transforming) {
		return ;
	}
	
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

// 捏合手势实现
- (void)figureViewDidReceiveZoomAction:(float)ds {
	
	if (transforming) {
		return ;
	}
	
	[self.currentAvatar resetScaleDelta:ds];
}
// 页面类型选择
- (void)figureViewDidSelectedTypeWithIndex:(NSInteger)typeIndex {
	
	switch ([FUManager shareInstance].avatarStyle) {
		case FUAvatarStyleNormal:{
			if (typeIndex == 9) {
				[self.currentAvatar resetScaleToSmallBody];
			}else {
				[self.currentAvatar resetScaleToFace] ;
			}
		}
			break;
		case FUAvatarStyleQ:{
			switch (typeIndex) {
					//                case 10:
					//                    [self.currentAvatar resetScaleToSmallBody];
					//                    break;
					//                case 11:
					//                    [self.currentAvatar resetScaleToShowShoes] ;
					//                    break ;
				case 8:
					[self.currentAvatar resetScaleToShowShoes];
					break ;
				default:
					[self.currentAvatar resetScaleToFace] ;
					break;
			}
		}
			break ;
	}
}
// 隐藏全部子页面
- (void)figureViewDidHiddenAllTypeViews {
//	[self.currentAvatar resetScaleToBody];
}

// 头发
- (void)figureViewDidChangeHair:(NSString *)hair {
	self.currentAvatar.hair = hair;
	NSString *filePath = nil ;
	if ([hair isEqualToString:@"hair-noitem"] || [hair isEqualToString:@"hair_q_noitem"]) {
		filePath = nil ;
		[self.currentAvatar reloadHairWithPath:filePath];
	}else {
		if (self.currentAvatar.name) {
			filePath = [[[self.currentAvatar filePath] stringByAppendingPathComponent:hair] stringByAppendingString:@".bundle"];
			
		}else {
			filePath = [[[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Resource"] stringByAppendingPathComponent:self.currentAvatar.name] stringByAppendingPathComponent:hair] stringByAppendingString:@".bundle"] ;
		}
		
		BOOL exsit = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
		if (exsit) {
			[self.currentAvatar reloadHairWithPath:filePath];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.downloadBtn.enabled = YES ;
			});
		}else{
			[self startLoadingHairAnimation];
			self.willLoadHairName = hair;
		}
	}
	
	
	
	NSLog(@"[FUAvatarEditManager sharedInstance].undoStack------%@",[FUAvatarEditManager sharedInstance].undoStack);
}
// 脸型
- (void)figureViewDidChangeFace:(NSString *)face index:(NSInteger)index {
	NSLog(@"------ face: %@", face);
	if (index == 0) {
		[self faceShapeActionWithKey:@"面部正面" shapeType:FUFigureShapeTypeFaceFront];
		return ;
	}
	
	NSDictionary *dict = [[FUManager shareInstance].qFaces objectAtIndex:index - 1];
	[self faceShapeWithDict:dict];
	self.currentAvatar.face = face ;
	self.downloadBtn.enabled = YES ;
	
}
// 眼睛
- (void)figureViewDidChangeEyes:(NSString *)eyes index:(NSInteger)index {
	NSLog(@"------ eyes: %@", eyes);
	if (index == 0) {
		[self faceShapeActionWithKey:@"眼睛正面" shapeType:FUFigureShapeTypeEyesFront];
		return ;
	}
	
	NSDictionary *dict = [[FUManager shareInstance].qEyes objectAtIndex:index - 1];
	[self faceShapeWithDict:dict];
	self.currentAvatar.eyes = eyes ;
	self.downloadBtn.enabled = YES ;
	
}
// 嘴型
- (void)figureViewDidChangeMouth:(NSString *)mouth index:(NSInteger)index {
	NSLog(@"------ mouth: %@", mouth);
	if (index == 0) {
		[self faceShapeActionWithKey:@"嘴部正面" shapeType:FUFigureShapeTypeLipsFront];
		return ;
	}
	
	NSDictionary *dict = [[FUManager shareInstance].qMouths objectAtIndex:index - 1];
	[self faceShapeWithDict:dict];
	self.currentAvatar.mouth = mouth ;
	self.downloadBtn.enabled = YES ;
	
}
// 鼻子
- (void)figureViewDidChangeNose:(NSString *)nose index:(NSInteger)index {
	NSLog(@"------ nose: %@", nose);
	if (index == 0) {
		[self faceShapeActionWithKey:@"鼻子正面" shapeType:FUFigureShapeTypeNoseFront];
		return ;
	}
	
	NSDictionary *dict = [[FUManager shareInstance].qNoses objectAtIndex:index - 1];
	[self faceShapeWithDict:dict];
	self.currentAvatar.nose = nose ;
	self.downloadBtn.enabled = YES ;
	
}

- (void)faceShapeActionWithKey:(NSString *)key shapeType:(FUFigureShapeType)type {
	transforming = YES ;
	[self showFigureView:NO];

	[self.currentAvatar resetScaleToShapeFaceFront];
	
	[self removeMeshPoints];
	
	[self showMeshPointWithKey:key];
	shapeType = type ;
	self.faceBtn.selected = NO ;
	self.faceBtn.hidden = NO ;
}

- (void)faceShapeWithDict:(NSDictionary *)dict {
	
	NSArray *keys = dict.allKeys ;
	for (NSString *key in keys) {
		double level = [[dict objectForKey:key] doubleValue] ;
		[self.currentAvatar facepupModeSetParam:key level:level];
		[[FUShapeParamsMode shareInstance] recordParam:key value:level];
	}
}

- (IBAction)changeSideOfShapeAction:(UIButton *)sender {
	if (shapeType == FUFigureShapeTypeNone) {
		return ;
	}
	
	NSString *key ;
	
	if (sender.selected) {
		[self.currentAvatar resetScaleToShapeFaceFront];
		switch (shapeType) {
			case FUFigureShapeTypeFaceSide:
				key = @"面部正面" ;
				break;
			case FUFigureShapeTypeEyesSide:
				key = @"眼睛正面" ;
				break;
			case FUFigureShapeTypeLipsSide:
				key = @"嘴部正面" ;
				break;
			case FUFigureShapeTypeNoseSide:
				key = @"鼻子正面" ;
				break;
				
			default:
				break;
		}
		shapeType -= 1 ;
	}else {
		[self.currentAvatar resetScaleToShapeFaceSide];
		switch (shapeType) {
			case FUFigureShapeTypeFaceFront:
				key = @"面部侧面" ;
				break;
			case FUFigureShapeTypeEyesFront:
				key = @"眼睛侧面" ;
				break;
			case FUFigureShapeTypeLipsFront:
				key = @"嘴部侧面" ;
				break;
			case FUFigureShapeTypeNoseFront:
				key = @"鼻子侧面" ;
				break;
				
			default:
				break;
		}
		shapeType += 1 ;
	}
	
	sender.selected = !sender.selected ;
	
	[self removeMeshPoints];
	
	[self showMeshPointWithKey:key];
}

- (void)showMeshPointWithKey:(NSString *)key {
	
	NSDictionary *meshSource = self.currentAvatar.isQType ? [FUManager shareInstance].qMeshPoints : (self.currentAvatar.gender == FUGenderMale ? [FUManager shareInstance].maleMeshPoints : [FUManager shareInstance].femaleMeshPoints);
	
	NSArray *meshArray = [meshSource objectForKey:key];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		
		dispatch_semaphore_wait(self.meshSigin, DISPATCH_TIME_FOREVER) ;
		
		for (NSDictionary *dict in meshArray) {
			
			FUMeshPoint *point = [FUMeshPoint meshPointWithDicInfo:dict];
			
			CGPoint center = [self.currentAvatar getMeshPointOfIndex:point.index];
			point.center = center;
			NSLog(@"center------%d---%f------%f",point.index,center.x,center.y);
			
			[self.containerView addSubview:point];
			
			UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
			longPress.minimumPressDuration = 0.01;
			[point addGestureRecognizer:longPress];
			point.userInteractionEnabled = YES ;
			
			[self.currentMeshPoints addObject:point];
		}
		if ([FUNielianEditManager sharedInstance].hadNotEdit) {
			NSMutableDictionary * facePointDic = [NSMutableDictionary dictionary];
			NSDictionary *faceParamDict = [[FUShapeParamsMode shareInstance] getCurrentHeadParams];
			facePointDic[@"faceParam"] = faceParamDict;
			facePointDic[@"point"] = [self.currentMeshPoints copy];
			[FUNielianEditManager sharedInstance].orignalStateDic = facePointDic;
			[FUNielianEditManager sharedInstance].hadNotEdit = NO;
		}
		
		dispatch_semaphore_signal(self.meshSigin) ;
	});
}

- (void)showFigureView:(BOOL)show {
	if (show) {
		self.figureView.hidden = NO ;
		self.figureView.transform = CGAffineTransformMakeTranslation(0, self.figureView.frame.size.height) ;
		[UIView animateWithDuration:0.5 animations:^{
			self.figureView.transform = CGAffineTransformIdentity ;
		}];
	}else {
		[UIView animateWithDuration:0.5 animations:^{
			self.figureView.transform = CGAffineTransformMakeTranslation(0, self.figureView.frame.size.height) ;
		}completion:^(BOOL finished) {
			self.figureView.hidden = YES ;
		}];
	}
	self.doAndUndoView.hidden = show;
}

// 胡子
- (void)figureViewDidChangeBeard:(NSString *)beard {
	NSLog(@"---------------- beard: %@ ~", beard);
	
	NSString *filePath = nil ;
	if ([beard isEqualToString:@"beard-noitem"]) {
		filePath = nil ;
	}else {
		filePath = [[NSBundle mainBundle] pathForResource:beard ofType:@"bundle"];
	}
	[self.currentAvatar reloadBeardWithPath:filePath];
	self.currentAvatar.beard = beard;
	self.downloadBtn.enabled = YES ;
	
}
// 眉毛
- (void)figureViewDidChangeEyeBrow:(NSString *)eyeBrow {
	
	NSString *hatPath = nil ;
	if (eyeBrow && ![eyeBrow containsString:@"noitem"]) {
		hatPath = [[NSBundle mainBundle] pathForResource:eyeBrow ofType:@"bundle"];
	}
	[self.currentAvatar reloadEyeBrowWithPath:hatPath];
	self.downloadBtn.enabled = YES ;
	
}
// 睫毛
- (void)figureViewDidChangeeyeLash:(NSString *)eyeLash {
	
	NSString *hatPath = nil ;
	if (eyeLash && ![eyeLash isEqualToString:@"eyelash-noitem"]) {
		hatPath = [[NSBundle mainBundle] pathForResource:eyeLash ofType:@"bundle"];
	}
	[self.currentAvatar reloadEyeLashWithPath:hatPath];
	self.downloadBtn.enabled = YES ;
	
}
// 帽子
- (void)figureViewDidChangeHat:(NSString *)hat {
	NSLog(@"---------------- hat: %@ ~", hat);
	NSString *hatPath = nil ;
	if (hat && ![hat isEqualToString:@"hat-noitem"]) {
		hatPath = [[NSBundle mainBundle] pathForResource:hat ofType:@"bundle"];
	}
	self.currentAvatar.hat = hat;
	[self.currentAvatar reloadHatWithPath:hatPath];
	self.downloadBtn.enabled = YES ;
	
}
// 衣服
- (void)figureViewDidChangeClothes:(NSString *)clothes {
	
	NSString *filePath = nil ;
	if (![clothes isEqualToString:@"noitem"]) {
		filePath = [[NSBundle mainBundle] pathForResource:clothes ofType:@"bundle"];
	}
	self.currentAvatar.clothes = clothes;
	[self.currentAvatar reloadClothesWithPath:filePath];
	self.downloadBtn.enabled = YES ;
	
	if (self.currentAvatar.isQType) {
		NSString *shoesName = [clothes stringByAppendingString:@"_shoes"];
		NSString *shoesPath = [[NSBundle mainBundle] pathForResource:shoesName ofType:@"bundle"];
		[self.currentAvatar reloadShoesWithPath:shoesPath];
	}
	
}
// 鞋子
- (void)figureViewDidChangeShoes:(NSString *)shoes {
	
	NSString *filePath = nil ;
	if (![shoes containsString:@"noitem"]) {
		filePath = [[NSBundle mainBundle] pathForResource:shoes ofType:@"bundle"];
	}
	[self.currentAvatar reloadShoesWithPath:filePath];
	self.downloadBtn.enabled = YES ;
	
}

// 眼镜
- (void)figureViewDidChangeGlasses:(NSString *)glasses {
	
	NSString *filePath = nil ;
	if (![glasses containsString:@"noitem"]) {
		filePath = [[NSBundle mainBundle] pathForResource:glasses ofType:@"bundle"];
	}
	self.currentAvatar.glasses = glasses;
	[self.currentAvatar reloadGlassesWithPath:filePath];
	self.downloadBtn.enabled = YES ;
	
}

// 发色
- (void)figureViewDidChangeHairColor:(FUP2AColor *)hairColor index:(int)index {
	self.currentAvatar.hairColorIndex = index;
	[self.currentAvatar facepupModeSetColor:hairColor key:@"hair_color"];
	self.downloadBtn.enabled = YES ;
	
}
// 肤色
- (void)figureViewDidChangeSkinColor:(FUP2AColor *)skinColor {
	[self.currentAvatar facepupModeSetColor:skinColor key:@"skin_color"];
	self.downloadBtn.enabled = YES ;
	
}
// 瞳色
- (void)figureViewDidChangeIrisColor:(FUP2AColor *)irisColor index:(int)index {
	self.currentAvatar.irisLevel = index;
	[self.currentAvatar facepupModeSetColor:irisColor key:@"iris_color"];
	self.downloadBtn.enabled = YES ;
	
}
// 唇色
- (void)figureViewDidChangeLipsColor:(FUP2AColor *)lipsColor index:(int)index {
self.currentAvatar.lipsLevel = index;
	[self.currentAvatar facepupModeSetColor:lipsColor key:@"lip_color"];
	self.downloadBtn.enabled = YES ;
	
}

// 胡色
- (void)figureViewDidChangeBeardColor:(FUP2AColor *)beardColor {
	
	[self.currentAvatar facepupModeSetColor:beardColor key:@"beard_color"];
	self.downloadBtn.enabled = YES ;
	
}
// 帽色
- (void)figureViewDidChangeHatColor:(FUP2AColor *)hatColor {
	[self.currentAvatar facepupModeSetColor:hatColor key:@"hat_color"];
	self.downloadBtn.enabled = YES ;
	
}
// 镜片色
- (void)figureViewDidChangeGlassesColor:(FUP2AColor *)glassesColor index:(int)index {
	[self.currentAvatar facepupModeSetColor:glassesColor key:@"glass_color"];
	self.currentAvatar.glassColorIndex = index;
	self.downloadBtn.enabled = YES ;
	
}
// 镜框色
- (void)figureViewDidChangeGlassesFrameColor:(FUP2AColor *)glassesFrameColor index:(int)index {
	[self.currentAvatar facepupModeSetColor:glassesFrameColor key:@"glass_frame_color"];
	self.currentAvatar.glassFrameColorIndex = index;
	self.downloadBtn.enabled = YES ;
	
}

// 撤销
-(void)undo:(UIButton*)btn{
	_figureViewUndoBtn = btn;
	[[FUAvatarEditManager sharedInstance] undoStackPop:^(NSDictionary * config,BOOL isEmpty) {
		[self setTheSpifyConfig:config];
		if (isEmpty) {
			btn.enabled = false;
		}
	}];
	_figureViewRedoBtn.enabled = YES;
}
// 重做
-(void)redo:(UIButton*)btn{
	_figureViewRedoBtn = btn;
	[[FUAvatarEditManager sharedInstance] redoStackPop:^(NSDictionary * config,BOOL isEmpty) {
		[self setTheSpifyConfig:config];
		if (isEmpty) {
			btn.enabled = false;
		}
	}];
	_figureViewUndoBtn.enabled = YES;
}
-(void)setTheSpifyConfig:(NSDictionary *)config{
	NSLog(@"config---------%@",config);
	for (NSString * key in config.allKeys) {
		FUAvatarEditedDoModel * model = [[FUAvatarEditedDoModel alloc]init];
		if ([key isEqualToString:@"hair"]){
			//		[self figureViewDidChangeHair:config[key]];
			
			model.obj = config[key];
			model.type = Hair;
			
		}else if ([key isEqualToString:@"hairColorIndex"]) {
			model.obj = config[key];
			model.type = HairColor;
		}else if ([key isEqualToString:@"skinColorProgress"]) {
			model.obj = config[key];
			model.type = SkinColorProgress;
		}else if ([key isEqualToString:@"face"]) {
			model.obj = config[key];
			if ([model.obj isKindOfClass:[NSDictionary class]]) {
				NSDictionary * faceParamDict = model.obj;
				[self resetParamsWithDict:faceParamDict];
				model.obj = [NSNull null];
			}
		
			model.type = Face;
		}else if ([key isEqualToString:@"eyes"]) {
			model.obj = config[key];
			if ([model.obj isKindOfClass:[NSDictionary class]]) {
				NSDictionary * faceParamDict = model.obj;
				[self resetParamsWithDict:faceParamDict];
				model.obj = [NSNull null];
			}
			model.type = Eyes;
		}else if ([key isEqualToString:@"irisLevel"]) {
			model.obj = config[key];
			model.type = IrisLevel;
		}else if ([key isEqualToString:@"mouth"]) {
		
			model.obj = config[key];
						if ([model.obj isKindOfClass:[NSDictionary class]]) {
				NSDictionary * faceParamDict = model.obj;
				[self resetParamsWithDict:faceParamDict];
				model.obj = [NSNull null];
			}
			model.type = Mouth;
		}else if ([key isEqualToString:@"lipsLevel"]) {
			model.obj = config[key];
			model.type = LipsLevel;
		}else if ([key isEqualToString:@"nose"]) {
			model.obj = config[key];
						if ([model.obj isKindOfClass:[NSDictionary class]]) {
				NSDictionary * faceParamDict = model.obj;
				[self resetParamsWithDict:faceParamDict];
				model.obj = [NSNull null];
			}
			model.type = Nose;
		}else if ([key isEqualToString:@"beard"]) {
			model.obj = config[key];
			model.type = Beard;
		}else if ([key isEqualToString:@"glasses"]) {
			model.obj = config[key];
			model.type = Glasses;
		}
		else if ([key isEqualToString:@"glassColorIndex"]) {
				model.obj = config[key];
			model.type = GlassColorIndex;
		}else if ([key isEqualToString:@"glassFrameColorIndex"]) {
			model.obj = config[key];
			model.type = GlassFrameColorIndex;
		}else if ([key isEqualToString:@"hat"]) {
			model.obj = config[key];
			model.type = Hat;
		}else if ([key isEqualToString:@"clothes"]) {
			model.obj = config[key];
			model.type = Clothes;
		}
		[FUAvatarEditManager sharedInstance].type = model.type;
		[[NSNotificationCenter defaultCenter] postNotificationName:FUAvatarEditedDoNot object:model];
	}
	[FUAvatarEditManager sharedInstance].undo = NO;
	[FUAvatarEditManager sharedInstance].redo = NO;
}
- (void)reloadPointCoordinates {
	
	dispatch_semaphore_wait(self.meshSigin, DISPATCH_TIME_FOREVER) ;
	
	for (FUMeshPoint *point in self.currentMeshPoints) {
		
		CGPoint center = [self.currentAvatar getMeshPointOfIndex:point.index];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			point.center = center;
		});
	}
	
	dispatch_semaphore_signal(self.meshSigin) ;
}

- (void)removeMeshPoints {
	
	dispatch_semaphore_wait(self.meshSigin, DISPATCH_TIME_FOREVER) ;
	
	for (FUMeshPoint *point in self.currentMeshPoints) {
		[point removeFromSuperview];
	}
	[self.currentMeshPoints removeAllObjects];
	[[FUNielianEditManager sharedInstance] clear];
	self.undoBtn.enabled = NO;
	self.redoBtn.enabled = NO;
	dispatch_semaphore_signal(self.meshSigin) ;
}

static double distance = 50.0 ;

static double preX = 0.0 ;
static double preY = 0.0 ;
- (void)longPressAction:(UILongPressGestureRecognizer *)gester {
	
	switch (gester.state) {
		case UIGestureRecognizerStateBegan:{
			currentMeshPoint = (FUMeshPoint *)gester.view ;
			currentMeshPoint.selected = YES ;
			NSString *imageName ;
			switch (currentMeshPoint.direction) {
				case FUMeshPiontDirectionHorizontal:{
					imageName = @"tip_hor" ;
				}
					break;
				case FUMeshPiontDirectionVertical:{
					imageName = @"tip_ver" ;
				}
					break ;
				case FUMeshPiontDirectionAll:{
					imageName = @"tip_All" ;
				}
					break;
			}
			self.tipImage.image = [UIImage imageNamed:imageName];
			self.tipImage.hidden = NO ;
			
			CGPoint point = [gester locationInView:self.containerView]; ;
			preX = point.x ;
			preY = point.y ;
		}
			break;
		case UIGestureRecognizerStateChanged:{
			
			CGPoint currentPoint = [gester locationInView:self.containerView]; ;
			
			switch (self->currentMeshPoint.direction) {
				case FUMeshPiontDirectionHorizontal:{   // 左右
					
					double dotX = (currentPoint.x - preX)/distance;
					[self setAvatarHorizontalDot:dotX];
					
					preX = currentPoint.x ;
				}
					break;
				case FUMeshPiontDirectionVertical:{     // 上下
					
					double dotY = (currentPoint.y - preY)/distance;
					[self setAvatarVerticalDot:dotY];
					
					preY = currentPoint.y ;
				}
					break ;
				case FUMeshPiontDirectionAll:{          // 上下左右
					
					double dotX = (currentPoint.x - preX)/distance;
					double dotY = (currentPoint.y - preY)/distance;
					
					[self setAvatarHorizontalDot:dotX];
					[self setAvatarVerticalDot:dotY];
					
					preX = currentPoint.x ;
					preY = currentPoint.y ;
				}
					break ;
			}
		}
			break ;
			
		default:{
			currentMeshPoint.selected = NO ;
			self.tipImage.hidden = YES ;
			if (self.downloadBtn.selected == NO) {
				self.downloadBtn.enabled = YES ;
			}
		}
			break;
	}
	if (gester.state == UIGestureRecognizerStateEnded) {
		NSLog(@"手势结束了----------");
		NSMutableDictionary * facePointDic = [NSMutableDictionary dictionary];
		NSArray * pointArr = [[NSArray alloc]initWithArray:self.currentMeshPoints copyItems:YES];
		NSDictionary *faceParamDict;
	
		facePointDic[@"point"] = pointArr;

		switch (shapeType) {
			case FUFigureShapeTypeFaceSide:
			case FUFigureShapeTypeFaceFront: {
				faceParamDict = [[FUShapeParamsMode shareInstance] getCurrentHeadParams];
			}
				break;
			case FUFigureShapeTypeLipsSide:
			case FUFigureShapeTypeLipsFront:{
				faceParamDict = [[FUShapeParamsMode shareInstance] getCurrentMouthParams];
			}
				break ;
			case FUFigureShapeTypeEyesSide:
			case FUFigureShapeTypeEyesFront:{
				faceParamDict = [[FUShapeParamsMode shareInstance] getCurrentEyesParams];
			}
				break ;
			case FUFigureShapeTypeNoseSide:
			case FUFigureShapeTypeNoseFront: {
				faceParamDict = [[FUShapeParamsMode shareInstance] getCurrentNoseParams];
			}
				break ;
			default:
				break;
		}
		facePointDic[@"faceParam"] = faceParamDict;
		[[FUNielianEditManager sharedInstance] push:facePointDic];
		
	}
}
- (IBAction)undoClick:(UIButton *)sender {
	[[FUNielianEditManager sharedInstance] undoStackPop:^(NSDictionary * config,BOOL isEmpty) {
		[self undoAndRedoFacePoint:config];
		if (isEmpty) {
			sender.enabled = false;
		}
	}];
	self.redoBtn.enabled = YES;
}
- (IBAction)redoClick:(UIButton *)sender {
	[[FUNielianEditManager sharedInstance] redoStackPop:^(NSDictionary * config,BOOL isEmpty) {
		[self undoAndRedoFacePoint:config];
		if (isEmpty) {
			sender.enabled = false;
		}
	}];
	self.undoBtn.enabled = YES;
}
// 撤销和重做脸部点位
-(void)undoAndRedoFacePoint:(NSDictionary *)config{
	NSDictionary *faceParamDict = config[@"faceParam"];
	NSLog(@"2-------faceParamDict---------%@",faceParamDict);
	[self faceShapeWithDict:faceParamDict];
	[self resetParamsWithDict:faceParamDict];
	for (UIView * subView in self.containerView.subviews) {
		[subView removeFromSuperview];
	}
	NSArray * pointArr = config[@"point"];
	self.currentMeshPoints = [pointArr mutableCopy];
	NSLog(@"self.currentMeshPoints--------%@",self.currentMeshPoints);
	for (UIView * subView in pointArr) {
			[self.containerView addSubview:subView];
		}
}

// 左右
- (void)setAvatarHorizontalDot:(double)dot {
	
	double leftValue = [[FUShapeParamsMode shareInstance] valueWithKey:currentMeshPoint.leftKey];
	double rightValue = [[FUShapeParamsMode shareInstance] valueWithKey:currentMeshPoint.rightKey];
	
	NSString *curKey , *zeroKey ;
	double value ;
	if (dot > 0) {// 右
		
		if (leftValue - dot > 0) {        // leftkey 变小
			curKey = currentMeshPoint.leftKey;
			value = leftValue - dot ;
			zeroKey = currentMeshPoint.rightKey ;
		}else {                     // rightkey 变大
			curKey = currentMeshPoint.rightKey;
			value = rightValue + dot ;
			zeroKey = currentMeshPoint.leftKey ;
		}
		
	}else {         // 左
		
		if (rightValue + dot > 0) {    // rightkey 变小
			curKey = currentMeshPoint.rightKey;
			value = rightValue + dot ;
			zeroKey = currentMeshPoint.leftKey ;
		}else {                     // leftkey 变大
			curKey = currentMeshPoint.leftKey;
			value = leftValue - dot ;
			zeroKey = currentMeshPoint.rightKey ;
		}
	}
	
	if (value >= 1.0 || value <= 0.0) {
		return ;
	}
	
	[self.currentAvatar facepupModeSetParam:curKey level:value];
	[self.currentAvatar facepupModeSetParam:zeroKey level:0.0];
	
	[[FUShapeParamsMode shareInstance] recordParam:curKey value:value];
	[[FUShapeParamsMode shareInstance] recordParam:zeroKey value:0];
}

// 上下
- (void)setAvatarVerticalDot:(double)dot {
	
	double upValue = [[FUShapeParamsMode shareInstance] valueWithKey:currentMeshPoint.upKey];
	double downValue = [[FUShapeParamsMode shareInstance] valueWithKey:currentMeshPoint.downKey];
	
	NSString *curKey , *zeroKey ;
	double value ;
	if (dot > 0) {// 下
		
		if (upValue - dot > 0) {        // upkey 变小
			curKey = currentMeshPoint.upKey;
			value = upValue - dot ;
			zeroKey = currentMeshPoint.downKey ;
		}else {                     // downkey 变大
			curKey = currentMeshPoint.downKey;
			value = downValue + dot ;
			zeroKey = currentMeshPoint.upKey ;
		}
		
	}else {         // 上
		
		if (downValue + dot > 0) {    // downkey 变小
			curKey = currentMeshPoint.downKey;
			value = downValue + dot ;
			zeroKey = currentMeshPoint.upKey ;
		}else {                     // upkey 变大
			curKey = currentMeshPoint.upKey;
			value = upValue - dot ;
			zeroKey = currentMeshPoint.downKey ;
		}
	}
	
	if (value > 1.0) {
		value = 1.0 ;
	}
	if (value < 0.0) {
		value = 0.0 ;
	}
	
	[self.currentAvatar facepupModeSetParam:curKey level:value];
	[self.currentAvatar facepupModeSetParam:zeroKey level:0.0];
	
	[[FUShapeParamsMode shareInstance] recordParam:curKey value:value];
	[[FUShapeParamsMode shareInstance] recordParam:zeroKey value:0];
}


//[weakSelf resetParamsWithDict:dict];
- (void)resetParamsWithDict:(NSDictionary *)dict {
	NSArray *keys = dict.allKeys ;
	for (NSString *key in keys) {
		double value = [[dict objectForKey:key] doubleValue] ;
		[self.currentAvatar facepupModeSetParam:key level:value];
	}
}
-(void)dealloc{
	NSLog(@"FUEditViewController销毁了-----");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[FUAvatarEditManager sharedInstance] clear];
	[[FUNielianEditManager sharedInstance] clear];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

@end
