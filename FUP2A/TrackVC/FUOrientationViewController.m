//
//  FUOrientationViewController.m
//  FUP2A
//
//  Created by Chen on 2020/4/8.
//  Copyright © 2020 L. All rights reserved.
//

#import "FUOrientationViewController.h"
#import "FUTrackShowViewController.h"

@interface FUOrientationViewController ()

@end

@implementation FUOrientationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
    self.title = @"请选择模板样式";
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat space = (self.view.frame.size.height - 360 - 60)/3.0;
    
    UIButton *buttonL = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-90, space+60, 180, 180)];
    [buttonL setBackgroundImage:[UIImage imageNamed:@"img_landscape"] forState:UIControlStateNormal];
    [buttonL addTarget:self action:@selector(touchUpInsideButtonL) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonL];
    
    
    
    UIButton *buttonP = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-90, space*2+60 + 180, 180, 180)];
    [buttonP setBackgroundImage:[UIImage imageNamed:@"img_portrait"] forState:UIControlStateNormal];
    [buttonP addTarget:self action:@selector(touchUpInsideButtonP) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:buttonP];
    
    
    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"icon_back_black"] style:UIBarButtonItemStylePlain target:self action:@selector(touchUpInsideBtnBack)];
    btnBack.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = btnBack;
}

- (void)touchUpInsideBtnBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (!self.asset)
    {
        self.navigationController.navigationBarHidden = YES;
    }
    
}

- (void)touchUpInsideButtonL
{
    FUTrackShowViewController *vc = FUTrackShowViewController.new;
    vc.asset = self.asset;
    vc.isLandscape = YES;
    vc.strFileName = self.strFileName;
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)touchUpInsideButtonP
{
    FUTrackShowViewController *vc = FUTrackShowViewController.new;
    vc.asset = self.asset;
    vc.isLandscape = NO;
    vc.strFileName = self.strFileName;
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController pushViewController:vc animated:YES];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
