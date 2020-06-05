//
//  FUFigureTopCollection.h
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUFigureTopCollectionDelegate <NSObject>

@optional
- (void)topCollectionDidSelectedIndex:(NSInteger)index show:(BOOL)show changeAnimation:(BOOL)changeAnimation;

@end

@interface FUFigureTopCollection : UICollectionView

@property (nonatomic, assign) id<FUFigureTopCollectionDelegate>mDelegate;

@end


@interface FUFigureTopCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) NSString * imageName;
@property (assign,nonatomic)BOOL selectedCell;
@end
