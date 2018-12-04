//
//  FUFigureShapeCollection.m
//  FUP2A
//
//  Created by L on 2018/11/9.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUFigureShapeCollection.h"
#import "UIColor+FU.h"

@interface FUFigureShapeCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *dataArray ;
@end

@implementation FUFigureShapeCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dataSource = self ;
    self.delegate = self ;
    self.selectedIndex = -1 ;
}


-(void)setType:(FUFigureShapeCollectionType)type {
    _type = type ;
    
    switch (type) {
        case FUFigureShapeCollectionFace:{
//            self.dataArray = @[@"figure-shape-脸型长度", @"figure-shape-额头高低", @"figure-shape-脸颊宽度", @"figure-shape-下颚宽度", @"figure-shape-下巴高低"];
            self.dataArray = @[@"figure-shape-脸型长度", @"figure-shape-脸颊宽度", @"figure-shape-下颚宽度", @"figure-shape-下巴高低"];
        }
            break;
        case FUFigureShapeCollectionEyes:{
            self.dataArray = @[@"figure-shape-眼睛位置", @"figure-shape-眼角高低", @"figure-shape-眼睛高低", @"figure-shape-眼睛宽窄"];
        }
            break;
        case FUFigureShapeCollectionMouth:{
            self.dataArray = @[@"figure-shape-嘴部位置", @"figure-shape-上唇厚度", @"figure-shape-下唇厚度", @"figure-shape-嘴唇宽度"];
        }
            break;
        case FUFigureShapeCollectionNose:{
            self.dataArray = @[@"figure-shape-鼻子位置", @"figure-shape-鼻翼宽窄", @"figure-shape-鼻头高低" ];
        }
            break;
    }
    self.selectedIndex = -1 ;
    
    [self reloadData];
}


#pragma mark -- UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count + 1;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FUFigureShapeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureShapeCell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.imageView.image = [UIImage imageNamed:@"figure-shape-back"];
    }else {
        NSString *imageName = self.dataArray[indexPath.row - 1] ;
        if (self.selectedIndex == indexPath.row) {
            imageName = [imageName stringByAppendingString:@"-active"];
        }
        cell.imageView.image = [UIImage imageNamed:imageName];
    }
    return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        self.selectedIndex  = -1 ;
        if ([self.mDelegate respondsToSelector:@selector(shouldHiddShapeCollection)]) {
            [self.mDelegate shouldHiddShapeCollection];
        }
    }else {
        if (self.selectedIndex == indexPath.row) {
            return ;
        }
        self.selectedIndex = indexPath.row ;
        [collectionView reloadData];
        
        if ([self.mDelegate respondsToSelector:@selector(didSelectedShapeType:)]) {
            FigureShapeSelectedType currentSubType = self.type * 10 + indexPath.row ;
            self.currentSubType = currentSubType ;
            [self.mDelegate didSelectedShapeType:currentSubType];
        }
    }
}



@end



@implementation FUFigureShapeCell
@end
