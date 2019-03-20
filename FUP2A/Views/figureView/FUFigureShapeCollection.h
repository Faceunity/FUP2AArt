//
//  FUFigureShapeCollection.h
//  FUP2A
//
//  Created by L on 2019/2/27.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUFigureShapeCollectionDelegate <NSObject>
- (void)shapeCollectionDidSelectIndex:(NSInteger)index ;
@end

@interface FUFigureShapeCollection : UICollectionView
@property (nonatomic, assign) id<FUFigureShapeCollectionDelegate>mDelegate ;
@property (nonatomic, assign) NSInteger selectedIndex ;
@end

@interface FUFigureShapeCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
