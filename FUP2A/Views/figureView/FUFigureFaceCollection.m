//
//  FUFigureFaceCollection.m
//  FUP2A
//
//  Created by L on 2019/1/8.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUFigureFaceCollection.h"
#import "FUManager.h"
#import "FUAvatar.h"
#import "UIColor+FU.h"
#import "FUP2AColor.h"

@interface FUFigureFaceCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *skinColorArray ;
@property (nonatomic, strong) NSArray *faceArray ;
@property (nonatomic, strong) NSArray *eyesArray ;
@property (nonatomic, strong) NSArray *lipsArray ;
@property (nonatomic, strong) NSArray *noseArray ;

@end

@implementation FUFigureFaceCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dataSource = self;
    self.delegate = self ;
    
    self.currentType = 1 ;
    [self loadData];
}

- (void)loadData {
//    FUAvatar *currentAvatar = [FUManager shareInstance].currentAvatars.firstObject ;
    
    self.selectedDic = [NSMutableDictionary dictionaryWithCapacity:1];
    
    self.skinColorArray = [FUManager shareInstance].skinColorArray;
    
    self.faceArray = @[@"figure-shape-脸型长度", @"figure-shape-额头宽窄", @"figure-shape-脸颊宽度", @"figure-shape-下颚宽度", @"figure-shape-下巴高低"];
    self.eyesArray = @[@"figure-shape-眼睛位置", @"figure-shape-眼角高低", @"figure-shape-眼睛高低", @"figure-shape-眼睛宽窄", @"figure-shape-face-color"];
    self.lipsArray = @[@"figure-shape-嘴部位置", @"figure-shape-上唇厚度", @"figure-shape-下唇厚度", @"figure-shape-嘴唇宽度", @"figure-shape-face-color"];
    self.noseArray = @[@"figure-shape-鼻子位置", @"figure-shape-鼻翼宽窄", @"figure-shape-鼻头高低" ];
    [self.selectedDic setObject:@(-1) forKey:@(FUFigureFaceTypeFace)];
    [self.selectedDic setObject:@(-1) forKey:@(FUFigureFaceTypeLips)];
    [self.selectedDic setObject:@(-1) forKey:@(FUFigureFaceTypeNose)];
    [self.selectedDic setObject:@(-1) forKey:@(FUFigureFaceTypeEyes)];
}

-(void)setCurrentType:(FUFigureFaceType)currentType {
    _currentType = currentType ;
    [self reloadData];
}

-(void)setCurrentSkinColor:(FUP2AColor *)currentSkinColor {
    _currentSkinColor = currentSkinColor ;
    if (!self.selectedDic) {
        self.selectedDic = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    NSInteger index = [[FUManager shareInstance].skinColorArray indexOfObject:currentSkinColor];
    [self.selectedDic setObject:@(index) forKey:@(FUFigureFaceTypeSkinColor)];
    [self reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *array = [self currentDataArray];
    switch (_currentType) {
        case FUFigureFaceTypeSkinColor:
            return array.count - 1 ;
            break;
            
        default:
            return array.count ;
            break;
    }
}

- (NSArray *)currentDataArray {
    switch (_currentType) {
        case FUFigureFaceTypeSkinColor:{
            return self.skinColorArray ;
        }
            break;
        case FUFigureFaceTypeFace:{
            return self.faceArray ;
        }
            break ;
        case FUFigureFaceTypeEyes:{
            return self.eyesArray ;
        }
            break ;
        case FUFigureFaceTypeLips:{
            return self.lipsArray ;
        }
            break ;
        case FUFigureFaceTypeNose:{
            return self.noseArray ;
        }
            break ;
    }
    return nil ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureFaceCell *cell = (FUFigureFaceCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureFaceCell" forIndexPath:indexPath];
    
    switch (_currentType) {
        case FUFigureFaceTypeSkinColor:{
            FUP2AColor *color = self.skinColorArray[indexPath.row];
            cell.imageView.image = nil ;
            cell.imageView.backgroundColor = color.color ;
            
            NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
            cell.selectedImage.hidden = selectedIndex != indexPath.row ;
        }
            break;
        case FUFigureFaceTypeNose:
        case FUFigureFaceTypeLips:
        case FUFigureFaceTypeEyes:
        case FUFigureFaceTypeFace:{
            
            NSArray *array = [self currentDataArray];
            cell.selectedImage.hidden = YES ;
            
            NSString *itemName = array[indexPath.row];
            if ([self.selectedDic.allKeys containsObject:@(self.currentType)]) {
                NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
                if (selectedIndex == indexPath.row) {
                    itemName = [itemName stringByAppendingString:@"-active"];
                }
            }
            cell.imageView.image = [UIImage imageNamed:itemName];
        }
            break ;
    }
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
    
    FigureShapeSelectedType shapeType = 10;
    switch (_currentType) {
        case FUFigureFaceTypeSkinColor:{
            
            FUP2AColor *color = [FUManager shareInstance].skinColorArray[indexPath.row];
            self.currentSkinColor = color ;
            
            if ([self.mDelegate respondsToSelector:@selector(faceCollectionDidSelectedSkinIndex:)]) {
                [self.mDelegate faceCollectionDidSelectedSkinIndex:indexPath.row];
            }
            return ;
        }
            break;
        case FUFigureFaceTypeFace:{
            shapeType = 10 + indexPath.row ;
        }
            break ;
        case FUFigureFaceTypeEyes:{
            shapeType = 20 + indexPath.row ;
        }
            break ;
        case FUFigureFaceTypeLips: {
            shapeType = 30 + indexPath.row ;
        }
            break ;
        case FUFigureFaceTypeNose:{
            shapeType = 40 + indexPath.row ;
        }
            break ;
    }
    
    if ([self.mDelegate respondsToSelector:@selector(faceCollectionShapeParamChangedWithType:)]) {
        [self.mDelegate faceCollectionShapeParamChangedWithType:shapeType];
    }
    _selectedType = shapeType ;
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation {
    NSInteger index = 0 ;
    if ([self.selectedDic.allKeys containsObject:@(self.currentType)]) {
        index = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
    }
    if (index == -1) {
        index = 0 ;
    }
    [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animation];
}

@end



@implementation FUFigureFaceCell

@end

