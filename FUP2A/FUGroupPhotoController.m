//
//  FUGroupPhotoController.m
//  FUP2A
//
//  Created by L on 2018/12/19.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUGroupPhotoController.h"
#import "FUSceneryModel.h"
#import "FUGroupSelectedController.h"


@interface FUGroupPhotoController ()<UICollectionViewDelegateFlowLayout>
{
    FUSceneryMode currentModeType ;
}
@property (weak, nonatomic) IBOutlet UICollectionView *collection;
@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (weak, nonatomic) IBOutlet UIButton *singleButton;
@property (weak, nonatomic) IBOutlet UIButton *mutiButton;
@property (weak, nonatomic) IBOutlet UIButton *animationButton;
@property (nonatomic, strong) NSArray *singleArray;
@property (nonatomic, strong) NSArray *multipleArray;
@property (nonatomic, strong) NSArray *animationArray;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) FUAvatar *currentAvatar ;

@end

@implementation FUGroupPhotoController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigation];
    [self setupData];
    self.currentAvatar = [FUManager shareInstance].currentAvatars.firstObject;
    
    self.allButton.selected = YES;
}

- (void)setupNavigation {
    self.title = @"合影" ;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setBackgroundImage:[UIImage imageNamed:@"group-back"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.tintColor = [UIColor whiteColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    [button sizeToFit];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)setupData {
    
    NSString *dictPath = [FUManager shareInstance].avatarStyle == FUAvatarStyleNormal ? [[NSBundle mainBundle] pathForResource:@"AvatarAnimations.plist" ofType:nil] : [[NSBundle mainBundle] pathForResource:@"AvatarQAnimations.plist" ofType:nil];
    NSDictionary *dataDict = [NSDictionary dictionaryWithContentsOfFile:dictPath];
    
    NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *sinArr = dataDict[@"单人场景"];
    for (NSDictionary *dict in sinArr) {
        FUSingleModel *model = [FUSingleModel modelWithDict:dict];
        [tmpArray addObject:model];
    }
    self.singleArray = [tmpArray copy];
    
    if ([dataDict.allKeys containsObject:@"多人场景"]) {
     
        NSMutableArray *tmpArray2 = [NSMutableArray arrayWithCapacity:1];
        NSArray *muArr = dataDict[@"多人场景"];
        for (NSDictionary *dict in muArr) {
            FUMultipleModel *model = [FUMultipleModel modelWithDict:dict];
            [tmpArray2 addObject:model];
        }
        self.multipleArray = [tmpArray2 copy];
        
        NSMutableArray *tmpArray3 = [NSMutableArray arrayWithCapacity:1];
        NSArray *aniArr = dataDict[@"动画场景"];
        for (NSDictionary *dict in aniArr) {
            FUSingleModel *model = [FUSingleModel modelWithDict:dict];
            [tmpArray3 addObject:model];
        }
        self.animationArray = [tmpArray3 copy];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[FUManager shareInstance] setOutputResolutionAdjustScreen];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[FUManager shareInstance] reloadCamItemWithPath:nil];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)backAction {
    
    if ([FUManager shareInstance].currentAvatars.count == 0) {
    [self.currentAvatar setCurrentAvatarIndex:0];
        [[FUManager shareInstance] addRenderAvatar:self.currentAvatar];
        [self.currentAvatar loadStandbyAnimation];
    }
    
    [self.navigationController popViewControllerAnimated:YES ];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"FUGroupSelectedController"]) {
        
        FUGroupSelectedController *controller = (FUGroupSelectedController *)segue.destinationViewController ;
        
        FUSceneryMode mode = (FUSceneryMode)[[sender valueForKey:@"mode"] integerValue];
        
        switch (mode) {
            case FUSceneryModeSingle:{
                controller.singleModel = [sender valueForKey:@"model"] ;
            }
                break;
            case FUSceneryModeMultiple: {
                controller.multipleModel = [sender valueForKey:@"model"] ;
            }
                break ;
            case FUSceneryModeAnimation: {
                controller.animationModel = [sender valueForKey:@"model"] ;
            }
                break ;
            default:
                break;
        }
        controller.sceneryModel = mode ;
        controller.currentAvatar = self.currentAvatar ;
    }
}

#pragma mark ---- <UICollectionViewDataSource, UICollectionViewDelegate>
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    return CGSizeMake((screenSize.width-40)/3, (screenSize.width-40)/3/130.0*160.0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    switch (currentModeType) {
        case FUSceneryModeAll:{
            return self.singleArray.count + self.multipleArray.count + self.animationArray.count;
        }
            break;
        case FUSceneryModeSingle:{
            return self.singleArray.count;
        }
            break;
        case FUSceneryModeMultiple: {
            return self.multipleArray.count;
        }
            break ;
        case FUSceneryModeAnimation: {
            return self.animationArray.count;
        }
            break ;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUGroupPhotoCell *cell = (FUGroupPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUGroupPhotoCell" forIndexPath:indexPath];
    cell.iconView.hidden = YES;
    switch (currentModeType) {
        case FUSceneryModeAll:{
            if (indexPath.row < self.singleArray.count)
            {
                FUSingleModel *model = self.singleArray[indexPath.row] ;
                cell.imageView.image = [UIImage imageNamed:model.imageName] ;
            }
            else if (indexPath.row < self.singleArray.count + self.multipleArray.count)
            {
                FUMultipleModel *model = self.multipleArray[indexPath.row - self.singleArray.count] ;
                cell.imageView.image = [UIImage imageNamed:model.imageName] ;
                
            }else
            {
                FUSingleModel *model = self.animationArray[indexPath.row - self.singleArray.count - self.multipleArray.count] ;
                cell.imageView.image = [UIImage imageNamed:model.imageName] ;
                cell.iconView.hidden = NO;
            }
        }
            break;
        case FUSceneryModeSingle:{
            FUSingleModel *model = self.singleArray[indexPath.row] ;
            cell.imageView.image = [UIImage imageNamed:model.imageName] ;
        }
            break;
        case FUSceneryModeMultiple: {
            FUMultipleModel *model = self.multipleArray[indexPath.row] ;
            cell.imageView.image = [UIImage imageNamed:model.imageName] ;
        }
            break ;
        case FUSceneryModeAnimation: {
            FUSingleModel *model = self.animationArray[indexPath.row] ;
            cell.imageView.image = [UIImage imageNamed:model.imageName] ;
            cell.iconView.hidden = NO;
        }
            break ;
    }
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    id model = nil;
    FUSceneryMode mode = FUSceneryModeSingle;
    
    
    switch (currentModeType) {
        case FUSceneryModeAll:{
            if (indexPath.row < self.singleArray.count)
            {
                model = self.singleArray[indexPath.row] ;
                mode = FUSceneryModeSingle;
            }
            else if (indexPath.row < self.singleArray.count + self.multipleArray.count)
            {
                model = self.multipleArray[indexPath.row - self.singleArray.count] ;
                mode = FUSceneryModeMultiple;
                
            }else
            {
                model = self.animationArray[indexPath.row - self.singleArray.count - self.multipleArray.count] ;
                mode = FUSceneryModeAnimation;
            }
        }
            break;
        case FUSceneryModeSingle:{
            model = self.singleArray[indexPath.row] ;
            mode = FUSceneryModeSingle;
        }
            break;
        case FUSceneryModeMultiple: {
            model = self.multipleArray[indexPath.row] ;
            mode = FUSceneryModeMultiple;
        }
            break ;
        case FUSceneryModeAnimation: {
            model = self.animationArray[indexPath.row] ;
            mode = FUSceneryModeAnimation;
        }
            break ;
    }
    
    NSMutableDictionary *infoDict = [[NSMutableDictionary alloc]init];
    [infoDict setValue:@(mode) forKey:@"mode"];
    [infoDict setValue:model forKey:@"model"];
    
    [self performSegueWithIdentifier:@"FUGroupSelectedController" sender:infoDict];
}

#pragma mark ------ Event ------

- (IBAction)touchUpAllButton:(id)sender
{
    [self resetButtonStateWithSender:sender];
    currentModeType = FUSceneryModeAll;
    [self.collection reloadData];
}

- (IBAction)touchUpSingleButton:(id)sender
{
    [self resetButtonStateWithSender:sender];
    currentModeType = FUSceneryModeSingle;
    [self.collection reloadData];
}

- (IBAction)touchUpMutiButton:(id)sender
{
    [self resetButtonStateWithSender:sender];
    currentModeType = FUSceneryModeMultiple;
    [self.collection reloadData];
}

- (IBAction)touchUpAnimationButton:(id)sender
{
    [self resetButtonStateWithSender:sender];
    currentModeType = FUSceneryModeAnimation;
    [self.collection reloadData];
}

- (void)resetButtonStateWithSender:(id)sender
{
    self.allButton.selected = sender == self.allButton?YES:NO;
    self.singleButton.selected = sender == self.singleButton?YES:NO;
    self.mutiButton.selected = sender == self.mutiButton?YES:NO;
    self.animationButton.selected = sender == self.animationButton?YES:NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)dealloc
{
 NSLog(@"FUGroupPhotoController-------销毁了");
}

@end


@implementation FUGroupPhotoCell

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.imageView.layer.masksToBounds = YES ;
        self.imageView.layer.cornerRadius = 8.0 ;
    }
    return self ;
}

@end
