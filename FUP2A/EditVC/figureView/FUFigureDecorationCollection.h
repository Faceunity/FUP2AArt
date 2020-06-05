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
/// 取消选择美妆类型
/// @param model
- (void)cancelSelectedItem;
- (void)didSelectedItem:(FUItemModel*)model;
@end

@interface FUFigureDecorationCollection : UICollectionView
@property (nonatomic, weak) id<FUFigureHorizCollectionDelegate> mDelegate;

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation;

@end

@interface FUFigureDecorationCell : UICollectionViewCell
@property (assign, nonatomic)BOOL showTagLabel;
@property (strong, nonatomic)NSString *tagLabelText;
// 标签
@property (weak, nonatomic) IBOutlet UILabel *tagLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
