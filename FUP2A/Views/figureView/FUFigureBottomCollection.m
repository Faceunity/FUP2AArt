//
//  FUFigureBottomCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureBottomCollection.h"
#import "UIColor+FU.h"

@interface FUFigureBottomCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSInteger selectedIndex ;
}
@property (nonatomic, strong) UIView *line ;

@end

@implementation FUFigureBottomCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dataSource = self ;
    self.delegate = self ;
    
    self.line = [[UIView alloc] init];
    self.line.backgroundColor = [UIColor colorWithHexColorString:@"4C96FF"];
    self.line.layer.masksToBounds = YES ;
    self.line.layer.cornerRadius = 1.0 ;
    self.line.frame = CGRectMake(34.0, self.frame.size.height - 2.0, 34, 2.0) ;
    [self addSubview:self.line];
    
    selectedIndex = 0 ;
}

-(void)setDataArray:(NSArray *)dataArray {
    _dataArray = dataArray ;
    [self reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureBottomCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureBottomCell" forIndexPath:indexPath];
    cell.label.text = self.dataArray[indexPath.row] ;
    cell.label.textColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"] : [UIColor colorWithHexColorString:@"000000"] ;
    return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == selectedIndex) {
        if ([self.mDelegate respondsToSelector:@selector(bottomCollectionDidSelectedIndex:show:animation:)]) {
            [self.mDelegate bottomCollectionDidSelectedIndex:selectedIndex show:NO animation:YES];
            
            [self hiddenSelectedItem];
        }
        
        return ;
    }
    BOOL animation = selectedIndex == -1 ;
    
    selectedIndex = indexPath.row ;
    
    FUFigureBottomCell *cell = (FUFigureBottomCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    self.line.hidden = NO;
    CGFloat centerX = cell.center.x ;
    CGPoint center = self.line.center ;
    center.x = centerX ;
    if (!animation) {
        [UIView animateWithDuration:0.35 animations:^{
            self.line.center = center ;
        }];
    }else {
        self.line.center = center ;
    }
    [collectionView reloadData];
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
    if ([self.mDelegate respondsToSelector:@selector(bottomCollectionDidSelectedIndex:show:animation:)]) {
        [self.mDelegate bottomCollectionDidSelectedIndex:selectedIndex show:YES animation:animation];
    }
}

- (void)hiddenSelectedItem {
    if (selectedIndex != -1) {
        selectedIndex = -1 ;
        self.line.hidden = YES ;
        [self reloadData];
    }
}

@end

#pragma mark --- cell

@implementation FUFigureBottomCell

@end
