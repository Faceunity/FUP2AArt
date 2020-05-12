//
//  FUFigureDecorationCollection.h
//  FUFigureView
//
//  Created by L on 2019/4/10.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUFigureHorizCollectionDelegate <NSObject>

@optional
- (void)didSelectedItem;
@end

@interface FUFigureDecorationCollection : UICollectionView
@property (nonatomic, weak) id<FUFigureHorizCollectionDelegate> mDelegate;

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation;

@end

@interface FUFigureDecorationCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
