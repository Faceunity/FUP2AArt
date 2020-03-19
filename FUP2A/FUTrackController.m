//
//  FUTrackController.m
//  FUP2A
//
//  Created by LEE on 9/25/19.
//  Copyright © 2019 L. All rights reserved.
//
/**
 FUTrackController  是追踪的VC，由 FUPoseTrackController 和 FUARFilterController 两个VC组成
 */
@interface FUTrackController ()<FUTextTrackViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *textTrackBtn;
@property (weak, nonatomic) IBOutlet UIButton *ARFilterBtn;

@property (weak, nonatomic) IBOutlet FUTextTrackView *textTrackView;
@property (weak, nonatomic) IBOutlet FUARFilterView *arFilterView;

@property (weak, nonatomic) IBOutlet UIView *poseTrackContainerView;
@property (weak, nonatomic) IBOutlet UIView *textTrackContainerView;
@property (weak, nonatomic) IBOutlet UIView *arFilterContainerView;

@property (strong, nonatomic) FUTextTrackController *textTrackVC;

@property (strong, nonatomic) FUARFilterController *arFilterVC;
@property (strong, nonatomic) UIViewController *currenTrackVC;    // 当前显示的VC
@end

@implementation FUTrackController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.textTrackView.delegate = self;
	[self trackBtnAction:self.ARFilterBtn];

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
	
	self.textTrackBtn.selected = NO;
	self.ARFilterBtn.selected = NO;
	
	self.textTrackBtn.backgroundColor = [UIColor whiteColor];
	
	self.ARFilterBtn.backgroundColor = [UIColor whiteColor];
	
	
	self.poseTrackContainerView.hidden = YES;
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
}
/**
 底部栏选择身体追踪或AR驱动
 
 @param sender
 */
- (IBAction)trackBtnAction:(UIButton *)sender
{
	[self hideAllSubViews];
	sender.selected = YES ;
	sender.backgroundColor = UIColorFromRGB(0x4C96FF);
	
	 if (sender == self.textTrackBtn)
     {
		self.textTrackView.mInputView.hidden = NO;
		self.textTrackContainerView.hidden = NO;
		self.textTrackView.hidden = NO;
		self.textTrackVC.isShow = YES;
		self.currenTrackVC = self.textTrackVC;
        [self.arFilterVC.filterView selectNoFilter];
		
	}
    else if (sender == self.ARFilterBtn)
    {//AR驱动
		self.arFilterContainerView.hidden = NO;
		self.arFilterView.hidden = NO;
		self.arFilterVC.isShow = YES;
		self.currenTrackVC = self.arFilterVC;
	}
	
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	NSString *identifier = segue.identifier ;
    if ([identifier isEqualToString:@"EmbedFUTextTrackVC"]){   // 文字驱动
		FUTextTrackController *vc = segue.destinationViewController;
		__weak typeof(self)weakSelf = self ;
		vc.backBlock = ^{
			[weakSelf trackBtnAction:weakSelf.ARFilterBtn];
			
		};
		vc.textTrackView = self.textTrackView;
		self.textTrackVC = vc;
		
	}else if ([identifier isEqualToString:@"EmbedFUARFilterVC"]){   // AR驱动
		FUARFilterController *vc = segue.destinationViewController;
		vc.filterView = self.arFilterView;
		self.arFilterVC = vc;
		
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
