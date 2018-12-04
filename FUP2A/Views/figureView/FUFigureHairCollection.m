//
//  FUFigureHairCollection.m
//  EditView
//
//  Created by L on 2018/11/6.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUFigureHairCollection.h"
#import "FUFigureColor.h"
#import "UIColor+FU.h"


@interface FUFigureHairColorCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation FUFigureHairColorCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    self.delegate = self ;
    self.dataSource = self ;
}

-(void)setHairColorArray:(NSArray *)hairColorArray {
    _hairColorArray = hairColorArray ;
    [self reloadData];
}

- (void)setColorIndex:(NSInteger)colorIndex {
    _colorIndex = colorIndex ;
    [self reloadData];
}

#pragma mark ----- UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.hairColorArray.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureHairColorCell *cell = (FUFigureHairColorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureHairColorCell" forIndexPath:indexPath];
    FUFigureColor *color = self.hairColorArray[indexPath.row] ;
    cell.backgroundColor = color.color ;
    cell.selectedImage.hidden = indexPath.row != _colorIndex ;
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _colorIndex) {
        return ;
    }
    _colorIndex = indexPath.row ;
    [collectionView reloadData];
    if ([self.mDelegate respondsToSelector:@selector(didChangeHairColor:color:)]) {
        FUFigureColor *color = self.hairColorArray[_colorIndex] ;
        [self.mDelegate didChangeHairColor:_colorIndex color:color];
    }
}

@end

@implementation FUFigureHairColorCell

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.masksToBounds = YES ;
        self.layer.cornerRadius = self.bounds.size.width / 2.0 ;
    }
    return self ;
}

@end

#pragma mark ----- main collection 

@interface FUFigureHairMainCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSInteger selectedIndex ;
}
@end

@implementation FUFigureHairMainCollection
- (void)awakeFromNib {
    [super awakeFromNib];
    self.delegate = self ;
    self.dataSource = self ;
}

-(void)setHairArray:(NSArray *)hairArray {
    _hairArray = hairArray ;
    
    if ([hairArray containsObject:self.currentHair]) {
        selectedIndex = [hairArray indexOfObject:self.currentHair];
    }
    [self reloadData];
}

-(void)setCurrentHair:(NSString *)currentHair {
    _currentHair = currentHair ;
    
    if ([_hairArray containsObject:self.currentHair]) {
        selectedIndex = [_hairArray indexOfObject:self.currentHair];
    }
    [self reloadData];
}


#pragma mark ----- UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.hairArray.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureHairMainCell *cell = (FUFigureHairMainCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureHairMainCell" forIndexPath:indexPath];
    NSString *imageName = self.hairArray[indexPath.row] ;
    UIImage *image = [UIImage imageNamed:imageName];
    cell.imageView.image = image ;
    
    cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor;
    cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == selectedIndex) {
        return ;
    }
    NSString *hairName = self.hairArray[indexPath.row] ;
    
    switch (self.type) {
        case FUFigureHairMainCollectionTypeHair:{
            if ([self.mDelegate respondsToSelector:@selector(didChangeHair:)]) {
                BOOL ret = [self.mDelegate didChangeHair:hairName];
                if (!ret) {
                    return ;
                }
            }
        }
            break;
        case FUFigureHairMainCollectionTypeBerad:{
            if ([self.mDelegate respondsToSelector:@selector(didChangeBeard:)]) {
                [self.mDelegate didChangeBeard:hairName];
            }
        }
            break ;
        case FUFigureHairMainCollectionTypeCloth: {{
            if ([self.mDelegate respondsToSelector:@selector(didChangeCloth:)]) {
                [self.mDelegate didChangeCloth:hairName];
            }
        }
            break;
        }
        case FUFigureHairMainCollectionTypeHat: {
            if ([self.mDelegate respondsToSelector:@selector(didChangeHat:)]) {
                BOOL ret = [self.mDelegate didChangeHat:hairName];
                if (!ret) {
                    return ;
                }
            }
            break;
        }
    }
    selectedIndex = indexPath.row ;
    [collectionView reloadData];
}

@end


@implementation FUFigureHairMainCell

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.masksToBounds = YES ;
        self.layer.cornerRadius = 8.0 ;
    }
    return self ;
}

@end
