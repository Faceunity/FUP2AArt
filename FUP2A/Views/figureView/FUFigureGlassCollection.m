//
//  FUFigureGlassCollection.m
//  EditView
//
//  Created by L on 2018/11/6.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUFigureGlassCollection.h"
#import "FUFigureColor.h"

@interface FUFigureGlassCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation FUFigureGlassCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dataSource = self ;
    self.delegate = self ;
}

- (void)setGlassesArray:(NSArray *)glassesArray {
    _glassesArray = glassesArray ;
    [self reloadData];
}

- (void)setGlassesColorIndex:(NSInteger)glassesColorIndex {
    _glassesColorIndex = glassesColorIndex ;
    [self reloadData];
}

#pragma mark ---- UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.glassesArray.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FUFigureGlassCell *cell = (FUFigureGlassCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureGlassCell" forIndexPath:indexPath];
    FUFigureColor *color = self.glassesArray[indexPath.row] ;
    cell.backgroundColor = color.color ;
    cell.selectedImage.hidden = self.glassesColorIndex != indexPath.row ;
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.glassesColorIndex) {
        return ;
    }
    self.glassesColorIndex = indexPath.row ;
    [self reloadData];
    
    switch (self.type) {
        case FUFigureGlassesCollectionTypeGlass:{
            if ([self.mDelegate respondsToSelector:@selector(didChangeGlassesColor:color:)]) {
                FUFigureColor *color = self.glassesArray[self.glassesColorIndex] ;
                [self.mDelegate didChangeGlassesColor:self.glassesColorIndex color:color];
            }
        }
            break;
        case FUFigureGlassesCollectionTypeFrame:{
            if ([self.mDelegate respondsToSelector:@selector(didChangeGlassesFrameColor:color:)]) {
                FUFigureColor *color = self.glassesArray[self.glassesColorIndex] ;
                [self.mDelegate didChangeGlassesFrameColor:self.glassesColorIndex color:color];
            }
        }
            break ;
        case FUFigureGlassesCollectionTypeBeard: {
            if ([self.mDelegate respondsToSelector:@selector(didChangeBearColor:color:)]) {
                FUFigureColor *color = self.glassesArray[self.glassesColorIndex] ;
                [self.mDelegate didChangeBearColor:self.glassesColorIndex color:color];
            }
        }
            break;
        case FUFigureGlassesCollectionTypeHat:{
            if ([self.mDelegate respondsToSelector:@selector(didChangeHatColor:color:)]) {
                FUFigureColor *color = self.glassesArray[self.glassesColorIndex] ;
                [self.mDelegate didChangeHatColor:self.glassesColorIndex color:color];
            }
        }
            break ;
    }
}

@end





@implementation FUFigureGlassCell
- (instancetype)initWithCoder:(NSCoder *)coder  {
    self = [super initWithCoder:coder];
    if (self) {
        self.layer.masksToBounds = YES ;
        self.layer.cornerRadius = self.bounds.size.width / 2.0 ;
    }
    return self;
}
@end
