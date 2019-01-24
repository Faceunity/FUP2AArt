//
//  FUFigureBottomCollection.h
//  FUP2A
//
//  Created by L on 2019/1/7.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUFigureBottomCollectionDelegate <NSObject>

@optional
// 点击 index
- (void)bottomCollectionDidSelectedIndex:(NSInteger)index show:(BOOL)show animation:(BOOL)animation ;
@end

@interface FUFigureBottomCollection : UICollectionView

@property (nonatomic, assign) BOOL isMale ;

@property (nonatomic, assign) id<FUFigureBottomCollectionDelegate>mDelegate ;

- (void)hiddenSelectedItem ;
@end

@interface FUFigureBottomCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *label;

@end
