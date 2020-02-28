//
//  FUFigureBottomCollection.h
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUFigureBottomCollectionDelegate <NSObject>

@optional
- (void)bottomCollectionDidSelectedIndex:(NSInteger)index show:(BOOL)show animation:(BOOL)animation;

@end

@interface FUFigureBottomCollection : UICollectionView

@property (nonatomic, assign) id<FUFigureBottomCollectionDelegate>mDelegate;

- (void)hiddenSelectedLine ;

@end







@interface FUFigureBottomCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *label;

@end
