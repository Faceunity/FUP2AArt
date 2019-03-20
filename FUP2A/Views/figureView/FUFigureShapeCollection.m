//
//  FUFigureShapeCollection.m
//  FUP2A
//
//  Created by L on 2019/2/27.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUFigureShapeCollection.h"

@interface FUFigureShapeCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *dataArraty ;
@end

@implementation FUFigureShapeCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    self.delegate = self;
    self.dataSource = self ;
    
    self.dataArraty = @[@"脸", @"眼", @"嘴", @"鼻子"];
    self.selectedIndex = -1 ;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArraty.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureShapeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureShapeCell" forIndexPath:indexPath];
    
    NSString *imageName = self.dataArraty[indexPath.row] ;
    if (indexPath.row == self.selectedIndex) {
        imageName = [imageName stringByAppendingString:@"-active"];
    }
    
    cell.imageView.image = [UIImage imageNamed:imageName];
    
    return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    self.selectedIndex = self.selectedIndex == indexPath.row ? -1 : indexPath.row ;
    
    [collectionView reloadData];
    
    collectionView.userInteractionEnabled = NO ;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        collectionView.userInteractionEnabled = YES ;
    });
    
    if ([self.mDelegate respondsToSelector:@selector(shapeCollectionDidSelectIndex:)]) {
        [self.mDelegate shapeCollectionDidSelectIndex:self.selectedIndex];
    }
}

@end


@implementation FUFigureShapeCell
@end
