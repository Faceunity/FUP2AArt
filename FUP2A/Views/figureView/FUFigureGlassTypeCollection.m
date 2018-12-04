//
//  FUFigureGlassTypeCollection.m
//  EditView
//
//  Created by L on 2018/11/7.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUFigureGlassTypeCollection.h"
#import "FUFigureHairCollection.h"
#import "UIColor+FU.h"

@interface FUFigureGlassTypeCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation FUFigureGlassTypeCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dataSource = self ;
    self.delegate = self ;
}

- (void)setGlassesArray:(NSArray *)glassesArray {
    _glassesArray = glassesArray ;
    [self reloadData];
}

#pragma mark ---- UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.glassesArray.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureHairMainCell *cell = (FUFigureHairMainCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureGlassTypeCollection" forIndexPath:indexPath];
    NSString *imageName = self.glassesArray[indexPath.row] ;
    UIImage *image = [UIImage imageNamed:imageName];
    cell.imageView.image = image ;
    
    cell.layer.borderColor = self.selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor;
    cell.layer.borderWidth = self.selectedIndex == indexPath.row ? 2.0 : 0.0 ;
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.selectedIndex == indexPath.row) {
        return ;
    }
    
    self.selectedIndex = indexPath.row ;
    [collectionView reloadData];
    
    NSString *glassesName = self.glassesArray[indexPath.row] ;
    if ([self.mDelegate respondsToSelector:@selector(didChangeGlasses:)]) {
        [self.mDelegate didChangeGlasses:glassesName];
    }
}


@end
