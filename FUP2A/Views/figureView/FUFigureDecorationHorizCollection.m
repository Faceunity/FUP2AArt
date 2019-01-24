//
//  FUFigureDecorationHorizCollection.m
//  FUP2A
//
//  Created by L on 2019/1/9.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUFigureDecorationHorizCollection.h"
#import "FUManager.h"
#import "FUAvatar.h"
#import "UIColor+FU.h"

@interface FUFigureDecorationHorizCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSInteger selectedIndex ;
}
@property (nonatomic, strong) NSArray *glassesArray ;
@end

@implementation FUFigureDecorationHorizCollection
- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dataSource = self ;
    self.delegate = self ;
    [self loadData];
}

- (void)loadData {
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject ;
    BOOL isMale = avatar.gender == FUGenderMale ;
    
    self.glassesArray = isMale ? [FUManager shareInstance].maleGlasses : [FUManager shareInstance].femaleGlasses ;
    
    self.glassesName = avatar.glasses ;
    selectedIndex = 0 ;
    
    [self reloadData];
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation {
    
    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally  animated:animation];
}

-(void)setGlassesName:(NSString *)glassesName {
    _glassesName = glassesName ;
    if ([self.glassesArray containsObject:self.glassesName]) {
        selectedIndex = [self.glassesArray indexOfObject:glassesName];
        [self reloadData];
        [self scrollCurrentToCenterWithAnimation:NO];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.glassesArray.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureDecorationHorizCell *cell = (FUFigureDecorationHorizCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureDecorationHorizCell" forIndexPath:indexPath];
    UIImage *image = [UIImage imageNamed:self.glassesArray[indexPath.row]];
    cell.imageView.image = image ;
    
    cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
    cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == selectedIndex ) {
        return ;
    }
    selectedIndex = indexPath.row ;
    [collectionView reloadData];
    
    [self scrollCurrentToCenterWithAnimation:YES];
    
    if ([self.mDelegate respondsToSelector:@selector(didChangeGlasses:)]) {
        [self.mDelegate didChangeGlasses:self.glassesArray[indexPath.row]];
    }
}

@end


@implementation FUFigureDecorationHorizCell

@end
