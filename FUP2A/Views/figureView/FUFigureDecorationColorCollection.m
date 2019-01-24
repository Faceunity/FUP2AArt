//
//  FUFigureDecorationColorCollection.m
//  FUP2A
//
//  Created by L on 2019/1/8.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUFigureDecorationColorCollection.h"
#import "FUManager.h"
#import "FUAvatar.h"
#import "FUP2AColor.h"

@interface FUFigureDecorationColorCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *hairColorArray ;
@property (nonatomic, strong) NSArray *beardColorArray ;
@property (nonatomic, strong) NSArray *hatColorArray ;
@property (nonatomic, strong) NSArray *irisColorArray ;
@property (nonatomic, strong) NSArray *lipsColorArray ;
@property (nonatomic, strong) NSArray *glassesFrameColorArray ;
@property (nonatomic, strong) NSArray *glassesColorArray ;

@property (nonatomic, strong) NSMutableDictionary *selectedDic ;

@end

@implementation FUFigureDecorationColorCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dataSource = self ;
    self.delegate = self ;
    
//    self.currentType = FUFigureDecorationTypeHair ;
    [self loadData];
}

- (void)loadData {
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject ;
    
    self.selectedDic = [NSMutableDictionary dictionaryWithCapacity:1];
    
    // hair color
    self.hairColorArray = [FUManager shareInstance].hairColorArray ;
    if (avatar.hairColor == nil) {
        avatar.hairColor = [FUManager shareInstance].hairColorArray[0];
    }
    self.hairColor = avatar.hairColor ;
    NSInteger hairIndex = [self colorIndexOfColorList:self.hairColorArray color:avatar.hairColor];
    [self.selectedDic setObject:@(hairIndex) forKey:@(FUFigureDecorationTypeHair)];

    // beard color
    self.beardColorArray = [FUManager shareInstance].beardColorArray ;
    if (avatar.beardColor == nil) {
        avatar.beardColor = [FUManager shareInstance].beardColorArray[0];
    }
    self.beardColor = avatar.beardColor ;
    NSInteger beardIndex = [self colorIndexOfColorList:self.beardColorArray color:avatar.beardColor];
    [self.selectedDic setObject:@(beardIndex) forKey:@(FUFigureDecorationTypeBeard)];

    // hat
    self.hatColorArray = [FUManager shareInstance].hatColorArray;
    if (avatar.hatColor == nil) {
        avatar.hatColor = [FUManager shareInstance].hatColorArray[0];
    }
    self.hatColor = avatar.hatColor ;
    NSInteger hatIndex = [self colorIndexOfColorList:self.hatColorArray color:avatar.hatColor];
    [self.selectedDic setObject:@(hatIndex) forKey:@(FUFigureDecorationTypeHat)];
    
    // iris
    self.irisColorArray = [FUManager shareInstance].irisColorArray;
    if (avatar.irisColor == nil) {
        avatar.irisColor = [FUManager shareInstance].irisColorArray[0];
    }
    self.irisColor = avatar.irisColor ;
    NSInteger irisIndex = [self colorIndexOfColorList:self.irisColorArray color:avatar.irisColor];
    [self.selectedDic setObject:@(irisIndex) forKey:@(FUFigureDecorationTypeIris)];
    
    // lips
    self.lipsColorArray = [FUManager shareInstance].lipColorArray;
    if (avatar.lipColor == nil) {
        avatar.lipColor = [FUManager shareInstance].lipColorArray[0];
    }
    self.lipsColor = avatar.lipColor ;
    NSInteger lipIndex = [self colorIndexOfColorList:self.lipsColorArray color:avatar.lipColor];
    [self.selectedDic setObject:@(lipIndex) forKey:@(FUFigureDecorationTypeLips)];
    
    // glasses frame color
    self.glassesFrameColorArray = [FUManager shareInstance].glassFrameArray;
    if (avatar.glassFrameColor == nil) {
        avatar.glassFrameColor = [FUManager shareInstance].glassFrameArray[0];
    }
    self.glassesFrameColor = avatar.glassFrameColor ;
    NSInteger gfIndex = [self colorIndexOfColorList:self.glassesFrameColorArray color:avatar.glassFrameColor];
    [self.selectedDic setObject:@(gfIndex) forKey:@(FUFigureDecorationTypeGlassesFrame)];
    
    // glasses color
    self.glassesColorArray = [FUManager shareInstance].glassColorArray;
    if (avatar.glassColor == nil) {
        avatar.glassColor = [FUManager shareInstance].glassColorArray[0];
    }
    self.glassesColor = avatar.glassColor ;
    NSInteger gIndex = [self colorIndexOfColorList:self.glassesColorArray color:avatar.glassColor];
    [self.selectedDic setObject:@(gIndex) forKey:@(FUFigureDecorationTypeGlasses)];
}

- (NSInteger)colorIndexOfColorList:(NSArray *)list color:(FUP2AColor *)color {
    NSInteger index = 0 ;
    for (FUP2AColor *c in list) {
        if (c.r == color.r
            && c.g == color.g
            && c.b == color.b) {
            index = [list indexOfObject:c];
            break ;
        }
    }
    return index ;
}

-(void)setCurrentType:(FUFigureDecorationType)currentType {
    _currentType = currentType ;
    [self reloadData];
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation {
    NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animation];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *dataArray = [self currentDataArray];
    
    return dataArray ? dataArray.count : 0 ;
}

- (NSArray *)currentDataArray {
    switch (_currentType) {
        case FUFigureDecorationTypeHair:{
            return self.hairColorArray ;
        }
            break;
        case FUFigureDecorationTypeBeard:{
            return self.beardColorArray ;
        }
            break ;
        case FUFigureDecorationTypeHat:{
            return self.hatColorArray ;
        }
            break ;
        case FUFigureDecorationTypeIris:{
            return self.irisColorArray ;
        }
            break ;
        case FUFigureDecorationTypeLips:{
            return self.lipsColorArray ;
        }
            break ;
        case FUFigureDecorationTypeGlasses:{
            return self.glassesColorArray ;
        }
            break ;
        case FUFigureDecorationTypeGlassesFrame:{
            return self.glassesFrameColorArray ;
        }
            break ;
            
        default:
            return nil;
            break ;
    }
    return nil ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureDecorationColorCell *cell = (FUFigureDecorationColorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureDecorationColorCell" forIndexPath:indexPath];
    NSArray *array = [self currentDataArray];
    
    FUP2AColor *color = array[indexPath.row] ;
    cell.backgroundColor = color.color ;
    
    NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
    
    cell.selectedImage.hidden = indexPath.row != selectedIndex ;
    
    return cell ;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
    if (selectedIndex == indexPath.row) {
        return ;
    }
    [self.selectedDic setObject:@(indexPath.row) forKey:@(self.currentType)];
    [collectionView reloadData];
    
    [self scrollCurrentToCenterWithAnimation:YES];
    
    FUP2AColor *color = [[self currentDataArray] objectAtIndex:indexPath.row];
    if ([self.mDelegate respondsToSelector:@selector(decorationColorCollectionDidChangeColor:colorType:)]) {
        [self.mDelegate decorationColorCollectionDidChangeColor:color colorType:self.currentType];
    }
    
    switch (_currentType) {
        case FUFigureDecorationTypeHair:{
            self.hairColor = color ;
            NSLog(@"--- hair color r:%.2f - g:%.2f - b:%.2f ", color.r, color.g, color.b);
        }
            break;
        case FUFigureDecorationTypeBeard:{
            self.beardColor = color ;
        }
            break ;
        case FUFigureDecorationTypeHat:{
            self.hatColor = color ;
        }
            break ;
        case FUFigureDecorationTypeIris:{
            self.irisColor = color ;
        }
            break ;
        case FUFigureDecorationTypeLips:{
            self.lipsColor = color ;
        }
            break ;
        case FUFigureDecorationTypeGlasses:{
            self.glassesColor = color ;
        }
            break ;
        case FUFigureDecorationTypeGlassesFrame:{
            self.glassesFrameColor = color ;
        }
            break ;
            
        default:
            break ;
    }
}

@end

@implementation FUFigureDecorationColorCell

@end
