//
//  FUFigureBottomCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureBottomCollection.h"

@interface FUFigureBottomCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSInteger selectedIndex ;
}
@property (nonatomic, strong) NSArray *bgSubTypeNameArray;
@property (nonatomic, strong) NSArray *bgSubTypeKeyArray;
@property (nonatomic, assign) NSInteger count;
@end

@implementation FUFigureBottomCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dataSource = self ;
    self.delegate = self ;
    [self registerNib:[UINib nibWithNibName:@"FUFigureBottomCell" bundle:nil] forCellWithReuseIdentifier:@"FUFigureBottomCell"];
}

- (void)reloadData
{
    
   // self.count =  [[FUManager shareInstance] getCurrentTypeArrayCount];
    [super reloadData];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.count;
}


- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureBottomCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureBottomCell" forIndexPath:indexPath];

    return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self reloadData];
    if (indexPath.row == [[FUManager shareInstance] getSubTypeSelectedIndex])
    {
        if ([self.mDelegate respondsToSelector:@selector(bottomCollectionDidSelectedIndex:show:animation:)])
        {
            [self.mDelegate bottomCollectionDidSelectedIndex:indexPath.row show:NO animation:YES];
        }
        return ;
    }
    [[FUManager shareInstance]setSubTypeSelectedIndex:indexPath.row];
    [self reloadCam];
    
    [self reloadData];

    if ([self.mDelegate respondsToSelector:@selector(bottomCollectionDidSelectedIndex:show:animation:)])
    {
        [self.mDelegate bottomCollectionDidSelectedIndex:indexPath.row show:YES animation:YES];
    }
}

- (void)reloadCam
{
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    if ([FUManager shareInstance].selectedEditType == FUEditTypeFace||[FUManager shareInstance].selectedEditType == FUEditTypeMakeup)
    {
        [avatar resetScaleToBody_UseCam];
    }
    else if ([FUManager shareInstance].selectedEditType == FUEditTypeDress)
    {
        NSString *subType = [[FUManager shareInstance]getSubTypeKeyWithIndex:[[FUManager shareInstance]getSubTypeSelectedIndex]];
        if ([subType isEqualToString:TAG_FU_ITEM_HAIRHAT]||[subType isEqualToString:TAG_FU_ITEM_GLASSES])
        {
            [avatar resetScaleToBody_UseCam];
        }
        else
        {
            [avatar resetScaleChange_UseCam];
        }
    }
}



@end

#pragma mark --- cell

@implementation FUFigureBottomCell

@end
