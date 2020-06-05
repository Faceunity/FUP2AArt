//
//  FUEditViewController.m
//  FUP2A
//
//  Created by L on 2018/8/22.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUEditViewController.h"
#import "FUFigureViewController.h"
#import "FUNielianEditManager.h"
#import "FUFigureDefine.h"
#import "FUAvatarEditManager.h"
#import "FUFigureView.h"
#import "FUMeshPoint.h"
#import "FUShapeParamsMode.h"

@interface FUEditViewController ()
<
FUCameraDelegate,
FUFigureViewDelegate
>
{
	BOOL transforming;
	BOOL customFaceuped;  // YES为已经完成自定义捏脸，NO，为没有自定义捏脸
	__block FUFigureShapeType shapeType;
	
	FUMeshPoint *currentMeshPoint;
	UIButton *_figureViewUndoBtn;
	UIButton *_figureViewRedoBtn;
}
@property (nonatomic, strong) FUCamera *camera;
@property (weak, nonatomic) IBOutlet FUOpenGLView *renderView;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong)NSString * willLoadHairName;     // 当hair.bundle 没有本地化完成时，先保存，当本地化完成后再加载
@property (nonatomic, strong) FUFigureView *figureView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImage;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;   // eg: 模型保存中
@property (weak, nonatomic) IBOutlet UILabel *pointLabel;
@property (nonatomic, weak) NSTimer *labelTimer;
@property (nonatomic, strong) NSMutableArray *currentMeshPoints;
@property (weak, nonatomic) IBOutlet UIImageView *tipImage;
@property (nonatomic, strong) dispatch_semaphore_t meshSigin;
@property (weak, nonatomic) IBOutlet UIButton *faceBtn;
@property (nonatomic,strong) FUFigureViewController * figureVC;
@property (weak, nonatomic) IBOutlet UIView *doAndUndoView;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@property (weak, nonatomic) IBOutlet UIButton *redoBtn;

@property (nonatomic, strong) FUAvatar *currentAvatar;
@property (nonatomic,assign) int pixelBufferW;
@property (nonatomic,assign) int pixelBufferH;
@property (nonatomic, strong) NSString * currentNielianKind;  // 记录当前捏脸的类型
@property (nonatomic,assign) BOOL isChangeItemAni;  //当前动画是否为切换道具专用动画

@end

@implementation FUEditViewController

- (BOOL)prefersStatusBarHidden
{
	return YES;
}
-(instancetype)initWithCoder:(NSCoder *)coder{
	if (self = [super initWithCoder:coder]) {
		[[FUManager shareInstance]enterEditMode];
	}
	return self;
}
- (void)viewDidLoad
{
	[super viewDidLoad];
    [[FUManager shareInstance]configEditInfo];
	//[self setUPContainerView];
	appManager.editVC = self;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(HairsWriteToLocalSuccessNotMethod) name:HairsWriteToLocalSuccessNot object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditManagerStackNotEmptyMethod) name:FUAvatarEditManagerStackNotEmptyNot object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUNielianEditManagerStackNotEmptyNotMethod) name:FUNielianEditManagerStackNotEmptyNot object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterNieLianNotMethod) name:FUEnterNileLianNot object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(creatingHairBundleNotMethod:) name:FUCreatingHairBundleNot object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(creatingHairHatBundleNotMethod:) name:FUCreatingHairHatBundleNot object:nil];
    
	self.currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
//    [self.currentAvatar closeHairAnimation];
	[self.currentAvatar enterFacepupMode];
	[[FUShapeParamsMode shareInstance]recordOrignalParamsWithAvatar:self.currentAvatar];
	[self.currentAvatar loadIdleModePose];
	self.currentMeshPoints = [NSMutableArray arrayWithCapacity:1];
	
	transforming = NO;
	currentMeshPoint = nil;
    
	self.meshSigin = dispatch_semaphore_create(1);
	
	self.doAndUndoView.layer.shadowColor = [UIColor colorWithRed:35/255.0 green:53/255.0 blue:95/255.0 alpha:0.15].CGColor;
	self.doAndUndoView.layer.shadowOffset = CGSizeMake(0,1);
	self.doAndUndoView.layer.shadowOpacity = 1;
	self.doAndUndoView.layer.shadowRadius = 6;
    self.downloadBtn.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[FUAvatarEditManager sharedInstance] clear];
    [[FUNielianEditManager sharedInstance] clear];
    [FUAvatarEditManager sharedInstance].enterEditVC = YES;
    [self.camera startCapture];
    
    [self.currentAvatar resetScaleToBody_UseCam];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)FUAvatarEditManagerStackNotEmptyMethod
{
    self.downloadBtn.enabled = YES;
}
- (void)FUNielianEditManagerStackNotEmptyNotMethod
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (![FUNielianEditManager sharedInstance].undoStack.isEmpty)
        {
			self.undoBtn.enabled = YES;
		}
		if (![FUNielianEditManager sharedInstance].redoStack.isEmpty)
        {
			self.redoBtn.enabled = YES;
		}
		self.resetBtn.enabled = YES;
	});
}

- (void)setUPContainerView
{
	[self.view addSubview:self.containerView];
	FUFigureViewController * figureVC = [[FUFigureViewController alloc]init];
	self.figureVC = figureVC;
	[self.containerView addSubview:self.figureVC.view];
	[self.figureVC didMoveToParentViewController:self];
	self.figureView = (FUFigureView *)figureVC.view;
    
	self.figureView.delegate = self;
	[self.view insertSubview:self.containerView aboveSubview:self.renderView];
	//	self.containerView.hidden = 1;
    
    [self.figureView setupFigureView];
}

- (void)HairsWriteToLocalSuccessNotMethod
{
	[self stopLoadingHairAnimation];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"FUFigureView"])
    {
		FUFigureViewController *vc = segue.destinationViewController;
		self.figureVC = vc;
		self.figureView = (FUFigureView *)vc.view;
		
		self.figureView.delegate = self;
		[self.figureView setupFigureView];
	}
}

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{

	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	
	CVPixelBufferRef mirrored_pixel = [[FUManager shareInstance] dealTheFrontCameraPixelBuffer:pixelBuffer];
	CGSize size = [UIScreen mainScreen].currentMode.size;
	
	self.pixelBufferW = size.width;
	self.pixelBufferH = size.height;
    CVPixelBufferRef buffer = [[FUManager shareInstance] renderP2AItemWithPixelBuffer:pixelBuffer RenderMode:FURenderCommonMode Landmarks:nil LandmarksLength:0];
    

    [self.renderView displayPixelBuffer:buffer withLandmarks:nil count:0 Mirr:NO];
   
	
	if (transforming)
    {
		[self reloadPointCoordinates];
	}
	CVPixelBufferRelease(mirrored_pixel);
}

// 返回
- (IBAction)backAction:(UIButton *)sender
{
    if (transforming)
    {
        
        transforming = NO;

        [self removeMeshPoints];
        [self showFigureView:YES];

        [self.currentAvatar resetScaleToBody_UseCam];
        [self.currentAvatar loadIdleModePose];
        
        FUItemModel *model = [self.currentAvatar valueForKey:[[FUManager shareInstance] getSelectedType]];
        if (!model.shapeDict)
        {
            [self.currentAvatar configFacepupParamWithDict:[FUShapeParamsMode shareInstance].orginalFaceup];
        }
        else
        {
            [self.currentAvatar configFacepupParamWithDict:model.shapeDict];
        }
        
        self.faceBtn.hidden = YES;
        if([[FUManager shareInstance] hasEditAvatar] || customFaceuped) self.downloadBtn.enabled = YES;
        
        return;
    }
    
    if ([[FUManager shareInstance] hasEditAvatar] || customFaceuped)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"是否保存当前形象编辑？" preferredStyle:UIAlertControllerStyleAlert];
    
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"放弃" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
            [[FUManager shareInstance]reloadItemBeforeEdit];
            
            [self.camera stopCapture];

            [self.currentAvatar quitFacepupMode];
            [self.currentAvatar resetScaleToBody_UseCam];
            [self.navigationController popViewControllerAnimated:NO];
        }];
        
        [alertController addAction:cancel];
        
        UIAlertAction *save = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self downLoadAction:nil];
        }];
        
        [alertController addAction:save];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        [self.camera stopCapture];
        [self.currentAvatar quitFacepupMode];
        [self.currentAvatar resetScaleToBody_UseCam];
        [self.navigationController popViewControllerAnimated:NO];
    }
}

// 保存
- (IBAction)downLoadAction:(UIButton *)sender
{
    if (transforming)
    {
        transforming = NO;
       
        
        FUItemModel *model = [[FUManager shareInstance]getNieLianModelOfSelectedType];
        
        FUItemModel *newModel = [model copy];
        newModel.shapeDict = [FUShapeParamsMode shareInstance].editingFaceup;
        
        FUItemModel *oldModel = [self.currentAvatar valueForKey:newModel.type];
        if ([oldModel.name isEqualToString:@"捏脸"])
        {
            oldModel = [model copy];
            oldModel.shapeDict = [FUShapeParamsMode shareInstance].orginalFaceup;
          //  model.shapeDict = [FUShapeParamsMode shareInstance].orginalFaceup;
        }
        
        NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
        editDict[@"oldConfig"] = oldModel;
        editDict[@"currentConfig"] = newModel;
        
        [[FUAvatarEditManager sharedInstance]push:editDict];
        
        //设置选中索引
        NSArray *array = [FUManager shareInstance].itemsDict[model.type];
        NSInteger index = [array containsObject:model]?[array indexOfObject:model]:0;

        [[FUManager shareInstance].selectedItemIndexDict setObject:@(index) forKey:model.type];
        
        //修改模型信息的参数
        [self.currentAvatar setValue:model forKey:model.type];
        [[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditedDoNot object:nil];
		[self showFigureView:YES];
       
        [self removeMeshPoints];
        [self.currentAvatar resetScaleToBody_UseCam];
        [self.currentAvatar loadIdleModePose];
        self.faceBtn.hidden = YES;
        customFaceuped = YES;
        return;
    }
    
    [self.camera stopCapture];
    [self startLoadingSaveAvartAnimation];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FUManager shareInstance]saveAvatar];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.currentAvatar resetScaleToBody_UseCam];
            [self stopLoadingSaveAvartAnimation];
            [self.navigationController popViewControllerAnimated:NO];
        });
    });
}

#pragma mark --- FUEditViewDelegate
- (BOOL)isModeChanged
{
	if (![FUAvatarEditManager sharedInstance].undoStack.isEmpty || ![FUAvatarEditManager sharedInstance].redoStack.isEmpty)
    {
		return YES;
	}
//	// 装饰
//	if (self.figureView.hair != self.currentAvatar.hair
//		|| self.figureView.clothes != self.currentAvatar.clothes
//		|| self.figureView.upper != self.currentAvatar.upper
//		|| self.figureView.lower != self.currentAvatar.lower
//		|| self.figureView.decorations != self.currentAvatar.decorations
//		|| self.figureView.glasses != self.currentAvatar.glasses
//		|| self.figureView.beard != self.currentAvatar.beard
//		|| self.figureView.hat != self.currentAvatar.hat
//		|| self.figureView.eyeLash != self.currentAvatar.eyeLash) {
//
//		return YES;
//	}
//
//	if (self.currentAvatar.isQType) {
//		if (self.figureView.shoes != self.currentAvatar.shoes) {
//			return YES;
//		}
//	}else {
//		if (self.figureView.eyeBrow != self.currentAvatar.eyeBrow) {
//			return YES;
//		}
//	}
//
	
//	// 捏脸参数
//	if ([[FUShapeParamsMode shareInstance] propertiesIsChanged]) {
//		return YES;
//	}
//
//	if ((self.currentAvatar.hairColor != nil && ![self.figureView.hairColor colorIsEqualTo: self.currentAvatar.hairColor])
//		|| (self.currentAvatar.glassColor != nil && ![self.figureView.glassesColor colorIsEqualTo: self.currentAvatar.glassColor])
//		|| (self.currentAvatar.glassFrameColor != nil && ![self.figureView.glassesFrameColor colorIsEqualTo: self.currentAvatar.glassFrameColor])
//		|| (self.currentAvatar.hatColor != nil && ![self.figureView.hatColor colorIsEqualTo: self.currentAvatar.hatColor])
//		|| self.currentAvatar.skinLevel != self.figureView.skinLevel
//		|| self.currentAvatar.irisLevel != self.figureView.irisLevel
//		|| self.currentAvatar.lipsLevel != self.figureView.lipLevel) {
//
//		return YES;
//	}
//
	return NO;
}

- (void)creatingHairBundleNotMethod:(NSNotification *)not
{
    BOOL show =  [not.userInfo[@"show"] boolValue];
    if (show)
    {
        [self startLoadingHairAnimation];
    }
    else
    {
        [self stopLoadingHairAnimation];
    }
}
// 加载发帽的动画
- (void)creatingHairHatBundleNotMethod:(NSNotification *)not
{
    BOOL show =  [not.userInfo[@"show"] boolValue];
    if (show)
    {
        [self startLoadingHairHatAnimation];
    }
    else
    {
        [self stopLoadingHairHatAnimation];
    }
}
- (void)startLoadingAnimation
{
	self.loadingView.hidden = NO;
	[self.view bringSubviewToFront:self.loadingView];
	NSMutableArray *images = [NSMutableArray arrayWithCapacity:1];
	for (int i = 1; i < 33; i ++)
    {
		NSString *imageName = [NSString stringWithFormat:@"loading%d.png", i];
		NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
		UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
		[images addObject:image ];
	}
	self.loadingImage.animationImages = images;
	self.loadingImage.animationRepeatCount = 0;
	self.loadingImage.animationDuration = 2.0;
	[self.loadingImage startAnimating];
	__weak typeof(self)weakSelf = self;
	self.labelTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:weakSelf selector:@selector(labelAnimation) userInfo:nil repeats:YES];
}

- (void)labelAnimation
{
	self.pointLabel.hidden = NO;
	static int count = 1;
	count ++;
	if (count == 4)
    {
		count = 1;
	}
	NSMutableString *str = [@"" mutableCopy];
	for (int i = 0; i < count; i ++)
    {
		[str appendString:@"."];
	}
	self.pointLabel.text = str;
}

- (void)stopLoadingAnimation
{
	self.loadingView.hidden = YES;
	[self.view sendSubviewToBack:self.loadingView];
	[self.labelTimer invalidate];
	self.labelTimer = nil;
	[self.loadingImage stopAnimating ];
}

// 模型保存动画
- (void)startLoadingSaveAvartAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.loadingLabel.text = @"模型保存中";
		[self startLoadingAnimation];
	});
}

- (void)stopLoadingSaveAvartAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self stopLoadingAnimation];
	});
}

// 加载发型动画
- (void)startLoadingHairAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.loadingLabel.text = @"发型加载中";
		self.view.userInteractionEnabled = false;
		[self startLoadingAnimation];
	});
}

- (void)stopLoadingHairAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.view.userInteractionEnabled = true;
		[self stopLoadingAnimation];
	});
}

// 加载发帽动画
- (void)startLoadingHairHatAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.loadingLabel.text = @"发帽加载中";
		self.view.userInteractionEnabled = false;
		[self startLoadingAnimation];
	});
}

- (void)stopLoadingHairHatAnimation
{
	dispatch_async(dispatch_get_main_queue(), ^{
		self.view.userInteractionEnabled = true;
		[self stopLoadingAnimation];
	});
}

- (FUCamera *)camera
{
	if (!_camera)
    {
		_camera = [[FUCamera alloc] init];
		_camera.delegate = self;
		_camera.shouldMirror = NO;
		[_camera changeCameraInputDeviceisFront:YES];
	}
	return _camera;
}

#pragma mark ---- FUFigureViewDelegate
// Avatar 旋转
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
	
	if (transforming)
    {
		return;
	}

	UITouch *touch = [touches anyObject];
	
	CGFloat locationX = [touch locationInView:self.renderView].x;
	CGFloat preLocationX = [touch previousLocationInView:self.renderView].x;
	
	float dx = (locationX - preLocationX) / self.renderView.frame.size.width;
	
	[self.currentAvatar resetRotDelta:dx];
}


// 页面类型选择
- (void)figureViewDidSelectedTypeWithIndex:(NSInteger)typeIndex
{
	switch ([FUManager shareInstance].avatarStyle)
    {
		case FUAvatarStyleNormal:{
			if (typeIndex == 9)
            {
				[self.currentAvatar resetScaleToSmallBody];
			}
            else
            {
				[self.currentAvatar resetScaleToFace];
			}
		}
			break;
		case FUAvatarStyleQ:{
            if (typeIndex <= 14)
            {
                [self.currentAvatar resetScaleToBody_UseCam];
                if (self.isChangeItemAni)
                {
                    self.isChangeItemAni = NO;
                    [self.currentAvatar loadIdleModePose];
                }
                
            }
            else
            {
                [self.currentAvatar resetScaleChange_UseCam];
                if (!self.isChangeItemAni)
                {
                    self.isChangeItemAni = YES;
                    [self.currentAvatar loadChangeItemAnimation];
                }
            }
		}
			break;
	}
}

// 隐藏全部子页面
- (void)figureViewDidHiddenAllTypeViews
{
	[self.currentAvatar resetScaleToSmallBody_UseCam];
}

- (void)enterNieLianNotMethod
{
    [[FUShapeParamsMode shareInstance]getOrignalParamsWithAvatar:self.currentAvatar];
    [self.currentAvatar loadTrackFaceModePose_NoSignal];
    transforming = YES;
    [self showFigureView:NO];
    [self.currentAvatar resetScaleToFace_UseCamNoSignal];

    
    [self showMeshPointWithKey:[FUManager shareInstance].shapeModeKey];
    self.downloadBtn.enabled = NO;
    self.faceBtn.selected = NO;
    self.faceBtn.hidden = NO;
}

- (void)faceShapeWithDict:(NSDictionary *)dict
{
	NSArray *keys = dict.allKeys;
	for (NSString *key in keys)
    {
		double level = [[dict objectForKey:key] doubleValue];
		[self.currentAvatar facepupModeSetParam:key level:level];
		[[FUShapeParamsMode shareInstance] recordParam:key value:level];
	}
}

- (IBAction)changeSideOfShapeAction:(UIButton *)sender
{
    if ([[FUManager shareInstance].shapeModeKey containsString:@"_front"])
    {
        [self.currentAvatar resetScaleToShapeFaceSide];
        [FUManager shareInstance].shapeModeKey = [[FUManager shareInstance].shapeModeKey stringByReplacingOccurrencesOfString:@"_front" withString:@"_side"];
    }
    else  if ([[FUManager shareInstance].shapeModeKey containsString:@"_side"])
    {
        [self.currentAvatar resetScaleToShapeFaceFront];
        [FUManager shareInstance].shapeModeKey = [[FUManager shareInstance].shapeModeKey stringByReplacingOccurrencesOfString:@"_side" withString:@"_front"];
    }
    
    sender.selected = !sender.selected;
    [self removeMeshPoints];
    [self showMeshPointWithKey:[FUManager shareInstance].shapeModeKey];
}

- (void)showMeshPointWithKey:(NSString *)key
{
    
    NSDictionary *meshSource = [FUManager shareInstance].qMeshPoints;
	
	NSArray *meshArray = [meshSource objectForKey:key];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		
		dispatch_semaphore_wait(self.meshSigin, DISPATCH_TIME_FOREVER);
		
		for (NSDictionary *dict in meshArray)
        {
			
			FUMeshPoint *point = [FUMeshPoint meshPointWithDicInfo:dict];
			
			CGPoint center = [self.currentAvatar getMeshPointOfIndex:point.index PixelBufferW:self.pixelBufferW PixelBufferH:self.pixelBufferH];
			point.center = center;
			
			[self.containerView addSubview:point];
			
			UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
			longPress.minimumPressDuration = 0.01;
			[point addGestureRecognizer:longPress];
			point.userInteractionEnabled = YES;
			
			[self.currentMeshPoints addObject:point];
		}
		
		dispatch_semaphore_signal(self.meshSigin);
	});
}

- (void)showFigureView:(BOOL)show
{
	if (show)
    {
		self.figureView.hidden = NO;
		self.figureView.transform = CGAffineTransformMakeTranslation(0, self.figureView.frame.size.height);
		[UIView animateWithDuration:0.2 animations:^{
			self.figureView.transform = CGAffineTransformIdentity;
		}];
		[self.figureView reloadTopCollection];
	}
    else
    {
		[UIView animateWithDuration:0.2 animations:^{
			self.figureView.transform = CGAffineTransformMakeTranslation(0, self.figureView.frame.size.height);
		}completion:^(BOOL finished) {
			self.figureView.hidden = YES;
		}];
	}
	self.doAndUndoView.hidden = show;
}

		 // 撤销
- (void)reset:(UIButton*)btn{
	[[FUManager shareInstance]reloadItemBeforeEdit];
    [[FUManager shareInstance]getSelectedInfo];
	[[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditedDoNot object:nil];
	[[FUAvatarEditManager sharedInstance]clear];
	self.downloadBtn.enabled = NO;
}


// 撤销
- (void)undo:(UIButton*)btn
{
	_figureViewUndoBtn = btn;
	[[FUAvatarEditManager sharedInstance] undoStackPop:^(NSDictionary * config,BOOL isEmpty) {
		
		id item = config[@"oldConfig"];
		
		if ([item isKindOfClass:[FUItemModel class]])
		{
			FUItemModel * currentModel = config[@"currentConfig"];
			FUItemModel *model = (FUItemModel *)item;
			if ([model isKindOfClass:[FUMultipleRecordItemModel class]]) {   // 如果是美妆类型，且记录了多选状态
				if(((FUMultipleRecordItemModel*)model).recordType == FUMultipleRecordItemModelTypeMakeup){
					[[FUManager shareInstance] reserveMultipleMakeupItemState:model];
				}else if(((FUMultipleRecordItemModel*)model).recordType == FUMultipleRecordItemModelTypeDecorations)
				{
					[[FUManager shareInstance] reserveMultipleDecorationItemState:model];
				}else if(((FUMultipleRecordItemModel*)model).recordType == FUMultipleRecordItemModelTypeMutualExclusion) // 处理 头发、发帽、头饰互斥的逻辑
				{
					[[FUManager shareInstance] dealMutualExclusion:model current:currentModel direction:YES];
				}
			}else{
				if ([model.name containsString:@"noitem"] && ([[FUManager shareInstance].makeupTypeArray containsObject:currentModel.type] || [[FUManager shareInstance].decorationTypeArray containsObject:currentModel.type]))  {  // 如果是美妆，且第一个为noitem
					[[FUManager shareInstance] removeItemWithModel:currentModel AndType:currentModel.type];
					[[FUManager shareInstance].selectedItemIndexDict setObject:@(0) forKey:currentModel.type];
					[FUAvatarEditManager sharedInstance].undo = NO;
					[FUAvatarEditManager sharedInstance].redo = NO;
					
				}else{
					[[FUManager shareInstance]bindItemWithModel:model];
					
				}
			}
			[[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditedDoNot object:nil];
		}
		else if ([item isKindOfClass:[FUP2AColor class]])
		{
			FUP2AColor *color = (FUP2AColor *)item;
			FUFigureColorType colorType = (FUFigureColorType)[config[@"colorType"] integerValue];
			if (colorType == FUFigureColorTypeSkinColor)
			{
				double oldSkinColorProgress = [config[@"oldSkinColorProgress"] doubleValue];
				[[FUManager shareInstance]configSkinColorWithProgress:oldSkinColorProgress isPush:NO];
				self.currentAvatar.skinColorProgress = oldSkinColorProgress;
				[self.figureView updateSliderWithValue:oldSkinColorProgress];
			}
			else
			{
				[[FUManager shareInstance]configColorWithColor:color ofType:colorType];
				[[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditedDoNot object:nil];
			}
		}
		
		if (isEmpty)
		{
			btn.enabled = false;
		}
	}];
	_figureViewRedoBtn.enabled = YES;
}

// 重做
- (void)redo:(UIButton*)btn
{
	_figureViewRedoBtn = btn;
	[[FUAvatarEditManager sharedInstance] redoStackPop:^(NSDictionary * config,BOOL isEmpty) {
		
		id item = config[@"currentConfig"];
		if ([item isKindOfClass:[FUItemModel class]])
		{
			FUItemModel * oldModel = config[@"oldConfig"];
			FUItemModel *model = (FUItemModel *)item;
			if ([oldModel isKindOfClass:[FUMultipleRecordItemModel class]]) {   // 如果是美妆类型，且记录了多选状态
				if(((FUMultipleRecordItemModel*)oldModel).recordType == FUMultipleRecordItemModelTypeMakeup){
					[[FUManager shareInstance] resetMakeupItems];
				}else if(((FUMultipleRecordItemModel*)oldModel).recordType == FUMultipleRecordItemModelTypeDecorations)
				{
					[[FUManager shareInstance] resetDecorationItems];
				}else if(((FUMultipleRecordItemModel*)oldModel).recordType == FUMultipleRecordItemModelTypeMutualExclusion) // 处理 头发、发帽、头饰互斥的逻辑
				{
					[[FUManager shareInstance] dealMutualExclusion:oldModel current:model direction:NO];
				}
				
			}else{
				if ([model.name containsString:@"noitem"] && ([[FUManager shareInstance].makeupTypeArray containsObject:oldModel.type] || [[FUManager shareInstance].decorationTypeArray containsObject:oldModel.type]))  {  // 如果是美妆，且第一个为noitem
					[[FUManager shareInstance] removeItemWithModel:oldModel AndType:oldModel.type];
					[[FUManager shareInstance].selectedItemIndexDict setObject:@(0) forKey:oldModel.type];
					[FUAvatarEditManager sharedInstance].undo = NO;
					[FUAvatarEditManager sharedInstance].redo = NO;
				}else{
					[[FUManager shareInstance]bindItemWithModel:model];
					
				}
			}
			[[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditedDoNot object:nil];
		}
		else if ([item isKindOfClass:[FUP2AColor class]])
		{
			FUP2AColor *color = (FUP2AColor *)item;
			FUFigureColorType colorType = (FUFigureColorType)[config[@"colorType"] integerValue];
			
			if (colorType == FUFigureColorTypeSkinColor)
			{
				double skinColorProgress = [config[@"skinColorProgress"] doubleValue];
				[[FUManager shareInstance]configSkinColorWithProgress:skinColorProgress isPush:NO];
				self.currentAvatar.skinColorProgress = skinColorProgress;
				[self.figureView updateSliderWithValue:skinColorProgress];
			}
			else
			{
				[[FUManager shareInstance]configColorWithColor:color ofType:colorType];
				[[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditedDoNot object:nil];
			}
		}
		
		if (isEmpty)
		{
			btn.enabled = false;
		}
	}];
	_figureViewUndoBtn.enabled = YES;
}

- (void)reloadPointCoordinates
{
	dispatch_semaphore_wait(self.meshSigin, DISPATCH_TIME_FOREVER);

	for (FUMeshPoint *point in self.currentMeshPoints) {

		CGPoint center = [self.currentAvatar getMeshPointOfIndex:point.index PixelBufferW:self.pixelBufferW PixelBufferH:self.pixelBufferH];

		dispatch_async(dispatch_get_main_queue(), ^{
			point.center = center;
		});
	}
	dispatch_semaphore_signal(self.meshSigin);
}

// 删除脸部点位，
- (void)removeMeshPoints
{
	dispatch_semaphore_wait(self.meshSigin, DISPATCH_TIME_FOREVER);
	
	for (FUMeshPoint *point in self.currentMeshPoints) {
		[point removeFromSuperview];
	}
	[self.currentMeshPoints removeAllObjects];
	//	[[FUNielianEditManager sharedInstance] clear];
	//	self.undoBtn.enabled = NO;
	//	self.redoBtn.enabled = NO;
	dispatch_semaphore_signal(self.meshSigin);
}

// 删除脸部点位，但是保留编辑操作
- (void)removeMeshPointsSaveEdit
{
	dispatch_semaphore_wait(self.meshSigin, DISPATCH_TIME_FOREVER);
	
	for (FUMeshPoint *point in self.currentMeshPoints) {
		[point removeFromSuperview];
	}
	[self.currentMeshPoints removeAllObjects];
	dispatch_semaphore_signal(self.meshSigin);
}

static double distance = 50.0;
static double preX = 0.0;
static double preY = 0.0;
- (void)longPressAction:(UILongPressGestureRecognizer *)gester
{
	switch (gester.state) {
		case UIGestureRecognizerStateBegan:{
			currentMeshPoint = (FUMeshPoint *)gester.view;
			currentMeshPoint.selected = YES;
			NSString *imageName;
			switch (currentMeshPoint.direction) {
				case FUMeshPiontDirectionHorizontal:{
					imageName = @"tip_hor";
				}
					break;
				case FUMeshPiontDirectionVertical:{
					imageName = @"tip_ver";
				}
					break;
				case FUMeshPiontDirectionAll:{
					imageName = @"tip_All";
				}
					break;
			}
			self.tipImage.image = [UIImage imageNamed:imageName];
			self.tipImage.hidden = NO;
			
			CGPoint point = [gester locationInView:self.containerView];;
			preX = point.x;
			preY = point.y;
		}
			break;
		case UIGestureRecognizerStateChanged:{
			
			CGPoint currentPoint = [gester locationInView:self.containerView];;
			
			switch (self->currentMeshPoint.direction) {
				case FUMeshPiontDirectionHorizontal:{   // 左右
					
					double dotX = (currentPoint.x - preX)/distance;
					[self setAvatarHorizontalDot:-dotX];
					
					preX = currentPoint.x;
				}
					break;
				case FUMeshPiontDirectionVertical:{     // 上下
					
					double dotY = (currentPoint.y - preY)/distance;
					[self setAvatarVerticalDot:dotY];
					
					preY = currentPoint.y;
				}
					break;
				case FUMeshPiontDirectionAll:{          // 上下左右
					
					double dotX = (currentPoint.x - preX)/distance;
					double dotY = (currentPoint.y - preY)/distance;
					
					[self setAvatarHorizontalDot:-dotX];
					[self setAvatarVerticalDot:dotY];
					
					preX = currentPoint.x;
					preY = currentPoint.y;
				}
					break;
			}
		}
			break;
			
		default:{
			currentMeshPoint.selected = NO;
			self.tipImage.hidden = YES;
			if (self.downloadBtn.selected == NO)
            {
				self.downloadBtn.enabled = YES;
			}
		}
			break;
	}
	if (gester.state == UIGestureRecognizerStateEnded)
    {
		NSLog(@"手势结束了----------");
        
        NSMutableDictionary *editDict = [[FUShapeParamsMode shareInstance]getEditDictWithMeshPoint:currentMeshPoint];
        
		[[FUNielianEditManager sharedInstance] push:editDict];
	}
}
// 重置的点击事件
- (IBAction)resetClick:(UIButton *)sender{
   self.resetBtn.enabled = NO;
   self.redoBtn.enabled = NO;
   self.undoBtn.enabled =  NO;
   FUItemModel *model = [self.currentAvatar valueForKey:[[FUManager shareInstance] getSelectedType]];
   if (!model.shapeDict)
   {
	   [self.currentAvatar configFacepupParamWithDict:[FUShapeParamsMode shareInstance].orginalFaceup];
   }
   else
   {
	   [self.currentAvatar configFacepupParamWithDict:model.shapeDict];
   }
   [[FUNielianEditManager sharedInstance] clear];
}
// 撤销的点击事件
- (IBAction)undoClick:(UIButton *)sender
{
	[[FUNielianEditManager sharedInstance] undoStackPop:^(NSDictionary * config,BOOL isEmpty) {
		[self undoFacePoint:config];
		if (isEmpty) {
			sender.enabled = false;
		}
	}];
	self.redoBtn.enabled = YES;
	self.resetBtn.enabled = YES;
}
// 重做的点击事件
- (IBAction)redoClick:(UIButton *)sender
{
	[[FUNielianEditManager sharedInstance] redoStackPop:^(NSDictionary * config,BOOL isEmpty){
		[self redoFacePoint:config];
		if (isEmpty) {
			sender.enabled = false;
		}
	}];
	self.undoBtn.enabled = YES;
	self.resetBtn.enabled = YES;
}

- (void)undoFacePoint:(NSDictionary *)config
{
    NSMutableDictionary *orignialDict = config[@"oldConfig"];
    
    [[FUShapeParamsMode shareInstance]configFacepupParamWithDict:orignialDict];
}

// 撤销和重做脸部点位
- (void)redoFacePoint:(NSDictionary *)config
{
    NSMutableDictionary *orignialDict = config[@"currentConfig"];
     
    [[FUShapeParamsMode shareInstance]configFacepupParamWithDict:orignialDict];
}

// 左右
- (void)setAvatarHorizontalDot:(double)dot
{
    NSString * leftKey = currentMeshPoint.leftKey;
    NSString * rightKey = currentMeshPoint.rightKey;
    
    double leftValue = [[FUShapeParamsMode shareInstance].editingFaceup[leftKey] doubleValue];
    double rightValue = [[FUShapeParamsMode shareInstance].editingFaceup[rightKey] doubleValue];
    NSString *curKey , *zeroKey;
    double value;
    if (dot > 0)
    {// 右
        if (leftValue - dot > 0)
        {        // leftkey 变小
            curKey = leftKey;
            value = leftValue - dot;
            zeroKey = rightKey;
        }
        else
        {                     // rightkey 变大
            curKey = rightKey;
            value = rightValue + dot;
            zeroKey = leftKey;
        }
        
    }
    else
    {         // 左
        if (rightValue + dot > 0)
        {    // rightkey 变小
            curKey = rightKey;
            value = rightValue + dot;
            zeroKey = leftKey;
        }
        else
        {                     // leftkey 变大
            curKey = leftKey;
            value = leftValue - dot;
            zeroKey = rightKey;
        }
    }
    
    if (value >= 1.0 || value <= 0.0)
    {
        return;
    }
    
    [self.currentAvatar facepupModeSetParam:curKey level:value];
    [self.currentAvatar facepupModeSetParam:zeroKey level:0.0];
    
    [[FUShapeParamsMode shareInstance] recordParam:curKey value:value];
    [[FUShapeParamsMode shareInstance] recordParam:zeroKey value:0];
}

// 上下
- (void)setAvatarVerticalDot:(double)dot
{
    NSString * upKey = currentMeshPoint.upKey;
    NSString * downKey = currentMeshPoint.downKey;
    
    double upValue = [[FUShapeParamsMode shareInstance].editingFaceup[upKey] doubleValue];
    double downValue = [[FUShapeParamsMode shareInstance].editingFaceup[downKey] doubleValue];
    NSString *curKey , *zeroKey;
    double value;
    if (dot > 0)
    {// 下
        if (upValue - dot > 0)
        {        // upkey 变小
            curKey = upKey;
            value = upValue - dot;
            zeroKey = downKey;
        }
        else
        {                     // downkey 变大
            curKey = downKey;
            value = downValue + dot;
            zeroKey = upKey;
        }
    }
    else
    {         // 上
        if (downValue + dot > 0)
        {    // downkey 变小
            curKey = downKey;
            value = downValue + dot;
            zeroKey = upKey;
        }
        else
        {                     // upkey 变大
            curKey = upKey;
            value = upValue - dot;
            zeroKey = downKey;
        }
    }
    
    if (value > 1.0)
    {
        value = 1.0;
    }
    if (value < 0.0)
    {
        value = 0.0;
    }
    
    [self.currentAvatar facepupModeSetParam:curKey level:value];
    [self.currentAvatar facepupModeSetParam:zeroKey level:0.0];
    
    [[FUShapeParamsMode shareInstance] recordParam:curKey value:value];
    [[FUShapeParamsMode shareInstance] recordParam:zeroKey value:0];
}

- (void)resetParamsWithDict:(NSDictionary *)dict
{
	NSArray *keys = dict.allKeys;
	for (NSString *key in keys)
    {
		double value = [[dict objectForKey:key] doubleValue];
		[self.currentAvatar facepupModeSetParam:key level:value];
	}
}

- (void)dealloc
{
	NSLog(@"FUEditViewController销毁了-----");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[FUAvatarEditManager sharedInstance] clear];
	[[FUNielianEditManager sharedInstance] clear];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

@end
