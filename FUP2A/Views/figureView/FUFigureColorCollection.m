//
//  FUFigureColorCollection.m
//  FUP2A
//
//  Created by L on 2019/2/27.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUFigureColorCollection.h"
#import "FUP2AColor.h"

@interface FUFigureColorCollection ()<UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation FUFigureColorCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dataSource = self ;
    self.delegate = self ;
}

-(void)setType:(FUFigureColorType)type {
    _type = type ;
    
    [self reloadData];
    
    NSInteger index ;
    switch (type) {
        case FUFigureColorTypeSkinColor:{
            index = [self.skinColorArray indexOfObject:self.skinColor];
        }
            break;
        case FUFigureColorTypeLipsColor:{
            index = [self.lipsColorArray indexOfObject:self.lipsColor];
        }
            break ;
        case FUFigureColorTypeirisColor:{
            index = [self.irisColorArray indexOfObject:self.irisColor];
        }
            break ;
    }
    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

-(void)setSkinColor:(FUP2AColor *)skinColor {
    _skinColor = skinColor ;
    if (self.type == FUFigureColorTypeSkinColor) {
        [self reloadData];
        
        NSInteger index = [self.skinColorArray indexOfObject:skinColor];
        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

-(void)setLipsColor:(FUP2AColor *)lipsColor {
    _lipsColor = lipsColor ;
    if (self.type == FUFigureColorTypeLipsColor) {
        [self reloadData];
        
        NSInteger index = [self.lipsColorArray indexOfObject:lipsColor];
        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

-(void)setIrisColor:(FUP2AColor *)irisColor {
    _irisColor = irisColor ;
    if (self.type == FUFigureColorTypeirisColor) {
        [self reloadData];
        
        NSInteger index = [self.irisColorArray indexOfObject:irisColor];
        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    switch (_type) {
        case FUFigureColorTypeSkinColor:
            return self.skinColorArray.count - 1;
            break;
        case FUFigureColorTypeLipsColor:
            return self.lipsColorArray.count ;
            break ;
        case FUFigureColorTypeirisColor:
            return self.irisColorArray.count ;
            break ;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureColorCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureColorCell" forIndexPath:indexPath];
    
    FUP2AColor *color = nil ;
    BOOL selected = NO ;
    switch (_type) {
        case FUFigureColorTypeSkinColor:{
            color = self.skinColorArray[indexPath.row] ;
            selected = self.skinColor == color ;
        }
            break;
        case FUFigureColorTypeLipsColor:{
            color = self.lipsColorArray[indexPath.row] ;
            selected = self.lipsColor == color ;
        }
            break ;
        case FUFigureColorTypeirisColor:{
            color = self.irisColorArray[indexPath.row] ;
            selected = self.irisColor == color ;
        }
            break ;
    }
    
    cell.imageView.backgroundColor = color.color ;
    cell.selectedImage.hidden = !selected ;
    
    return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (_type) {
        case FUFigureColorTypeSkinColor:{
            _skinColor = self.skinColorArray[indexPath.row] ;
            if ([self.mDelegate respondsToSelector:@selector(colorCollectionDidSelectedSkinColor:)]) {
                [self.mDelegate colorCollectionDidSelectedSkinColor:self.skinColor];
            }
        }
            break;
        case FUFigureColorTypeLipsColor:{
            _lipsColor = self.lipsColorArray[indexPath.row] ;
            if ([self.mDelegate respondsToSelector:@selector(colorCollectionDidSelectedLipsColor:)]) {
                [self.mDelegate colorCollectionDidSelectedLipsColor:self.lipsColor];
            }
        }
            break ;
        case FUFigureColorTypeirisColor:{
            _irisColor = self.irisColorArray[indexPath.row] ;
            if ([self.mDelegate respondsToSelector:@selector(colorCollectionDidSelectedIrisColor:)]) {
                [self.mDelegate colorCollectionDidSelectedIrisColor:self.irisColor];
            }
        }
            break ;
    }
    [self reloadData];
    
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

@end


@implementation FUFigureColorCell

@end
