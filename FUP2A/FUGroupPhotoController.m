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
#import "FUManager.h"
#import "FUAvatar.h"

@interface FUGroupPhotoController ()
{
    FUSceneryMode currentModeType ;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *singleArray ;
@property (weak, nonatomic) IBOutlet UICollectionView *singleCollection;
@property (weak, nonatomic) IBOutlet UILabel *multipleLabel;
@property (nonatomic, strong) NSArray *multipleArray ;
@property (weak, nonatomic) IBOutlet UICollectionView *multipleCollection;
@property (weak, nonatomic) IBOutlet UILabel *animationLabel;
@property (nonatomic, strong) NSArray *animationArray ;
@property (weak, nonatomic) IBOutlet UICollectionView *animationCollection;

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
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)backAction {
    
    if ([FUManager shareInstance].currentAvatars.count == 0) {
        [[FUManager shareInstance] addRenderAvatar:self.currentAvatar];
        [self.currentAvatar loadStandbyAnimation];
    }
    
    [self.navigationController popViewControllerAnimated:YES ];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FUGroupSelectedController"]) {
        
        FUGroupSelectedController *controller = (FUGroupSelectedController *)segue.destinationViewController ;
        
        switch (currentModeType) {
            case FUSceneryModeSingle:{
                controller.singleModel = sender ;
            }
                break;
            case FUSceneryModeMultiple: {
                controller.multipleModel = sender ;
            }
                break ;
            case FUSceneryModeAnimation: {
                controller.animationModel = sender ;
            }
                break ;
        }
        controller.sceneryModel = currentModeType ;
        controller.currentAvatar = self.currentAvatar ;
    }
}

#pragma mark ---- <UICollectionViewDataSource, UICollectionViewDelegate>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (collectionView == self.singleCollection) {
        return self.singleArray.count ;
    }else if (collectionView == self.multipleCollection){
        return self.multipleArray.count ;
    }else if (collectionView == self.animationCollection) {
        return self.animationArray.count ;
    }
    return 0 ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUGroupPhotoCell *cell = (FUGroupPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUGroupPhotoCell" forIndexPath:indexPath];
    
    if (collectionView == self.singleCollection) {
        
        FUSingleModel *model = self.singleArray[indexPath.row] ;
        cell.imageView.image = [UIImage imageNamed:model.imageName] ;
        
    }else if (collectionView == self.multipleCollection){
        
        FUMultipleModel *model = self.multipleArray[indexPath.row] ;
        cell.imageView.image = [UIImage imageNamed:model.imageName] ;
        
    }else if (collectionView == self.animationCollection) {

        FUSingleModel *model = self.animationArray[indexPath.row] ;
        cell.imageView.image = [UIImage imageNamed:model.imageName] ;
    }
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    id model = nil ;
    if (collectionView == self.singleCollection) {
        
        currentModeType = FUSceneryModeSingle ;
        model = self.singleArray[indexPath.row];
    }else if (collectionView == self.multipleCollection){
        
        currentModeType = FUSceneryModeMultiple ;
        model = self.multipleArray[indexPath.row];
    }else if (collectionView == self.animationCollection) {
        
        currentModeType = FUSceneryModeAnimation ;
        model = self.animationArray[indexPath.row] ;
    }
    
    [self performSegueWithIdentifier:@"FUGroupSelectedController" sender:model];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
