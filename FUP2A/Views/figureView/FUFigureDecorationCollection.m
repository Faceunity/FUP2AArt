//
//  FUFigureDecorationCollection.m
//  FUP2A
//
//  Created by L on 2019/1/8.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUFigureDecorationCollection.h"
#import "FUManager.h"
#import "FUAvatar.h"
#import "UIColor+FU.h"


@interface FUFigureDecorationCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *hairArray ;
@property (nonatomic, strong) NSArray *beardArray ;
@property (nonatomic, strong) NSArray *browArray ;
@property (nonatomic, strong) NSArray *lashArray ;
@property (nonatomic, strong) NSArray *hatArray ;
@property (nonatomic, strong) NSArray *clothesArray ;

@property (nonatomic, strong) NSMutableDictionary *selectedDic ;
@end

@implementation FUFigureDecorationCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dataSource = self ;
    self.delegate = self ;
    
    self.currentType = FUFigureDecorationTypeHair ;
    [self loadData];
}

- (void)loadData {
    
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject ;
    BOOL isMale = avatar.gender == FUGenderMale ;
    
    self.selectedDic = [NSMutableDictionary dictionaryWithCapacity:1];
    
    // hair
    self.hairArray = isMale ? [FUManager shareInstance].maleHairs : [FUManager shareInstance].femaleHairs ;
    self.hair = avatar.hair ;
    [self.selectedDic setObject:@([self.hairArray indexOfObject:self.hair]) forKey:@(FUFigureDecorationTypeHair)];
    
    // beard
    self.beardArray = isMale ? [FUManager shareInstance].maleBeards : @[] ;
    self.beard = avatar.beard ;
    [self.selectedDic setObject:@([self.beardArray indexOfObject:self.beard]) forKey:@(FUFigureDecorationTypeBeard)];
    
    // eyebrow
    self.browArray = isMale ? [FUManager shareInstance].maleEyeBrows : [FUManager shareInstance].femaleEyeBrows ;
    self.eyeBrow = avatar.eyeBrow ;
    [self.selectedDic setObject:@([self.browArray indexOfObject:self.eyeBrow]) forKey:@(FUFigureDecorationTypeEyeBrow)];
    
    // eyelash
    self.lashArray = isMale ? @[] : [FUManager shareInstance].femaleEyeLashs ;
    self.eyeLash = avatar.eyeLash ;
    [self.selectedDic setObject:@([self.lashArray indexOfObject:self.eyeLash]) forKey:@(FUFigureDecorationTypeEyeLash)];
    
    // hat
    self.hatArray = isMale ? [FUManager shareInstance].maleHats : [FUManager shareInstance].femaleHats;
    self.hat = avatar.hat ;
    [self.selectedDic setObject:@([self.hatArray indexOfObject:self.hat]) forKey:@(FUFigureDecorationTypeHat)];
    
    // clothes
    self.clothesArray = isMale ? [FUManager shareInstance].maleClothes : [FUManager shareInstance].femaleClothes;
    self.clothes = avatar.clothes ;
    [self.selectedDic setObject:@([self.clothesArray indexOfObject:self.clothes]) forKey:@(FUFigureDecorationTypeClothes)];
}

-(void)setCurrentType:(FUFigureDecorationType)currentType {
    _currentType = currentType ;
    [self reloadData];
    [self scrollCurrentToCenterWithAnimation:NO];
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation {
    if ([self.selectedDic.allKeys containsObject:@(self.currentType)]) {
        NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animation];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self currentDataArray].count ;
}

- (NSArray *)currentDataArray {
    switch (_currentType) {
        case FUFigureDecorationTypeHair:{
            return self.hairArray ;
        }
            break;
        case FUFigureDecorationTypeBeard:{
            return self.beardArray ;
        }
            break ;
        case FUFigureDecorationTypeEyeBrow:{
            return self.browArray ;
        }
            break ;
        case FUFigureDecorationTypeEyeLash:{
            return self.lashArray ;
        }
            break ;
        case FUFigureDecorationTypeHat:{
            return self.hatArray ;
        }
            break ;
        case FUFigureDecorationTypeClothes:{
            return self.clothesArray ;
        }
            break ;
        case FUFigureDecorationTypeIris:    // 此处用不上
        case FUFigureDecorationTypeLips:
        case FUFigureDecorationTypeGlassesFrame:
        case FUFigureDecorationTypeGlasses:
            return nil ;
            break;
    }
    return nil ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureDecorationCell *cell = (FUFigureDecorationCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureDecorationCell" forIndexPath:indexPath];
    NSArray *array = [self currentDataArray];
    UIImage *image = [UIImage imageNamed:array[indexPath.row]];
    cell.imageView.image = image ;
    
    NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
    
    cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
    cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
    if (selectedIndex == indexPath.row) {
        return ;
    }
    
    NSString *itemName = [[self currentDataArray] objectAtIndex:indexPath.row];
    if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedType:itemName:)]) {
        BOOL ret = [self.mDelegate decorationCollectionDidSelectedType:self.currentType itemName:itemName];
        if (!ret) {
            return ;
        }
    }
    
    [self.selectedDic setObject:@(indexPath.row) forKey:@(self.currentType)];
    [collectionView reloadData];
    
    [self scrollCurrentToCenterWithAnimation:YES];
    
    switch (_currentType) {
        case FUFigureDecorationTypeHair:
            self.hair = itemName ;
            break;
        case FUFigureDecorationTypeBeard:
            self.beard = itemName ;
            break ;
        case FUFigureDecorationTypeHat:
            self.hat = itemName ;
            break ;
        case FUFigureDecorationTypeClothes:
            self.clothes = itemName ;
            break ;
        case FUFigureDecorationTypeEyeBrow:
            self.eyeBrow = itemName ;
            break ;
        case FUFigureDecorationTypeEyeLash:
            self.eyeLash = itemName ;
            break ;
        case FUFigureDecorationTypeIris:    // 此处用不上
        case FUFigureDecorationTypeLips:
        case FUFigureDecorationTypeGlassesFrame:
        case FUFigureDecorationTypeGlasses:
            break;
    }
}

@end


@implementation FUFigureDecorationCell

@end
