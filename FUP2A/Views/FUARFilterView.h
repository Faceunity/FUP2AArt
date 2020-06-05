//
//  FUARFilterView.h
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUARFilterViewDelegate <NSObject>

@optional
// 点击模型
- (void)ARFilterViewDidSelectedAvatar:(FUAvatar *)avatar ;
// 点击滤镜
- (void)ARFilterViewDidSelectedARFilter:(NSString *)filterName ;
// 隐藏上半部
- (void)ARFilterViewDidShowTopView:(BOOL)show ;
@end

@interface FUARFilterView : UIView

@property (nonatomic, assign) id<FUARFilterViewDelegate>delegate ;
- (void)selectedModeWith:(FUAvatar *)avatar ;
- (void)showCollection:(BOOL)show ;
- (void)selectNoFilter;
/// 选择模型类型
- (void)selectModelType;
@end

@interface FUARFilterCell: UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
