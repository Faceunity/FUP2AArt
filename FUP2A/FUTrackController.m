//
//  FUTrackController.m
//  FUP2A
//
//  Created by LEE on 9/25/19.
//  Copyright © 2019 L. All rights reserved.
//
#import "FUKeyBoardInputView.h"
#import "FUTrackController.h"
#import "FUTextTrackView.h"
#import "FUARFilterView.h"
#import "FUTextTrackController.h"
#import "FUARFilterController.h"
#import "FUBodyTrackController.h"
#import "FUPoseTrackView.h"
/**
 FUTrackController  是追踪的VC，由 FUPoseTrackController 和 FUARFilterController 两个VC组成
 */
@interface FUTrackController ()<FUTextTrackViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *textTrackBtn;
@property (weak, nonatomic) IBOutlet UIButton *ARFilterBtn;
@property (weak, nonatomic) IBOutlet UIButton *bodyTrackBtn;

@property (weak, nonatomic) IBOutlet FUTextTrackView *textTrackView;
@property (weak, nonatomic) IBOutlet FUARFilterView *arFilterView;
@property (weak, nonatomic) IBOutlet FUPoseTrackView *bodyTrackView;

@property (weak, nonatomic) IBOutlet UIView *bodyTrackContainerView;
@property (weak, nonatomic) IBOutlet UIView *textTrackContainerView;
@property (weak, nonatomic) IBOutlet UIView *arFilterContainerView;

@property (strong, nonatomic) FUTextTrackController *textTrackVC;
@property (strong, nonatomic) FUARFilterController *arFilterVC;
@property (strong, nonatomic) FUBodyTrackController *bodyTrackVC;

@property (strong, nonatomic) UIViewController *currenTrackVC;    // 当前显示的VC
@property (nonatomic, assign) BOOL isFromBodyTrack;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewConstrainstHeight;
@property (nonatomic, assign) BOOL isHiddenCollectionView;

@end

@implementation FUTrackController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.textTrackView.delegate = self;
	[self trackBtnAction:self.bodyTrackBtn];
    [[FUManager shareInstance] loadDefaultBackGroundToController];

}
-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.view addSubview: self.textTrackView.mInputView];
	self.textTrackView.mInputView.hidden = YES;
}

-(void)hideAllSubViews
{
	self.textTrackView.mInputView.hidden = YES;
	self.textTrackView.hidden = YES;
	self.arFilterView.hidden = YES;
    self.bodyTrackView.hidden = YES;
	
	self.textTrackBtn.selected = NO;
	self.ARFilterBtn.selected = NO;
    self.bodyTrackBtn.selected = NO;
    
    self.bodyTrackBtn.backgroundColor = [UIColor whiteColor];
	self.textTrackBtn.backgroundColor = [UIColor whiteColor];
	self.ARFilterBtn.backgroundColor = [UIColor whiteColor];
	
	
    self.bodyTrackContainerView.hidden = YES;
	self.textTrackContainerView.hidden = YES;
	self.arFilterContainerView.hidden = YES;
	
    if (self.currenTrackVC == self.textTrackVC)
    {
		self.textTrackVC.isShow = NO;
	}
    else if (self.currenTrackVC == self.arFilterVC)
    {
		self.arFilterVC.isShow = NO;
	}
    else if (self.currenTrackVC == self.bodyTrackVC)
    {
        self.bodyTrackVC.isShow = NO;
    }
}
/**
 底部栏选择身体追踪或AR驱动
 
 @param sender
 */
- (IBAction)trackBtnAction:(UIButton *)sender
{
	if (sender == self.textTrackBtn )
	{
		if(self.currenTrackVC == self.textTrackVC){
			
		}else{
			[self hideAllSubViews];
			sender.selected = YES ;
			sender.backgroundColor = UIColorFromRGB(0x4C96FF);
			
			if (self.currenTrackVC == self.arFilterVC)
			{
				[[FUManager shareInstance]loadDefaultBackGroundToController];
			}
			
			self.textTrackView.mInputView.hidden = NO;
			self.textTrackContainerView.hidden = NO;
			self.textTrackView.hidden = self.isHiddenCollectionView;
			self.textTrackVC.isShow = YES;
			self.currenTrackVC = self.textTrackVC;
			[self.arFilterVC.filterView selectNoFilter];
		}
	}
	else if (sender == self.ARFilterBtn)
	{//AR驱动
	     if(self.currenTrackVC == self.arFilterVC)
	     {
	     [(FUARFilterController*)self.currenTrackVC hideOrShowFilterView];
		 }else{
		[self hideAllSubViews];
		sender.selected = YES ;
		sender.backgroundColor = UIColorFromRGB(0x4C96FF);
		
		self.isFromBodyTrack = NO;
		self.arFilterContainerView.hidden = NO;
		self.arFilterView.hidden= self.isHiddenCollectionView;
		self.arFilterVC.isShow = YES;
		self.currenTrackVC = self.arFilterVC;
		}
	}
	else if (sender == self.bodyTrackBtn)
	{//身体驱动
		if (self.currenTrackVC == self.bodyTrackVC)
		{
			[(FUBodyTrackController*)self.currenTrackVC hideOrShowPoseTrackView];
		}else{
			[self hideAllSubViews];
			sender.selected = YES ;
			sender.backgroundColor = UIColorFromRGB(0x4C96FF);
			
			if (self.currenTrackVC == self.arFilterVC)
			{
				[[FUManager shareInstance]loadDefaultBackGroundToController];
			}
			
			self.isFromBodyTrack = YES;
			self.bodyTrackView.hidden = self.isHiddenCollectionView;
			self.bodyTrackContainerView.hidden = NO;
			self.currenTrackVC = self.bodyTrackVC;
			self.bodyTrackVC.isShow = YES;
			[self.arFilterVC.filterView selectNoFilter];
			[self.bodyTrackVC resetBottom];
		}
	}
}


- (void)setIsHiddenCollectionView:(BOOL)isHiddenCollectionView
{
    _isHiddenCollectionView = isHiddenCollectionView;
    if (isHiddenCollectionView)
    {
        self.collectionViewConstrainstHeight.constant = 56;
    }
    else
    {
        self.collectionViewConstrainstHeight.constant = 161;
    }
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	NSString *identifier = segue.identifier ;
    if ([identifier isEqualToString:@"EmbedFUTextTrackVC"]){   // 文字驱动
		FUTextTrackController *vc = segue.destinationViewController;
		__weak typeof(self)weakSelf = self ;
		vc.backBlock = ^{
            if (weakSelf.isFromBodyTrack)
            {
                [weakSelf trackBtnAction:weakSelf.bodyTrackBtn];
            }
            else
            {
                [weakSelf trackBtnAction:weakSelf.ARFilterBtn];
            }
			
		};
        
        
        vc.touchBlock = ^{
            weakSelf.isHiddenCollectionView = !weakSelf.isHiddenCollectionView;
        };
		vc.textTrackView = self.textTrackView;
		self.textTrackVC = vc;
		
	}else if ([identifier isEqualToString:@"EmbedFUARFilterVC"]){   // AR驱动
		FUARFilterController *vc = segue.destinationViewController;
		vc.filterView = self.arFilterView;
        __weak typeof(self)weakSelf = self ;
         
         vc.touchBlock = ^{
             weakSelf.isHiddenCollectionView = !weakSelf.isHiddenCollectionView;
         };
		self.arFilterVC = vc;
		
	}
    else if ([identifier isEqualToString:@"EmbedFUBodyTrackVC"]){   // AR驱动
        FUBodyTrackController *vc = segue.destinationViewController;
        vc.poseTrackView = self.bodyTrackView;
        __weak typeof(self)weakSelf = self ;
        
        vc.touchBlock = ^{
            weakSelf.isHiddenCollectionView = !weakSelf.isHiddenCollectionView;
        };
        self.bodyTrackVC = vc;
        
    }
	
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	UITouch *touch = [touches anyObject];
	NSLog(@"touch-----view--------%@",[touch view]);
}
-(void)dealloc{
	NSLog(@"FUTrackController-----------销毁了");
}
@end
