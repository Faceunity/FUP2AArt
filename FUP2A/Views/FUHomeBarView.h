//
//  FUHomeBarView.h
//  FUP2A
//
//  Created by L on 2018/10/24.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FUAvatar ;
@protocol FUHomeBarViewDelegate <NSObject>

@optional
// 进入删除页
- (void)homeBarViewShouldDeleteAvatar ;
// 进入新增页
- (void)homeBarViewShouldCreateAvatar ;
// 切换模型
- (void)homeBarViewDidSelectedAvatar:(FUAvatar *)avatar ;
// 显示/隐藏 上半部
- (void)homeBarViewShouldShowTopView:(BOOL)show ;
// 形象/AR 点击
- (void)homeBarSelectedActionWithAR:(BOOL)isAR ;
// 合影点击
- (void)homeBarSelectedGroupBtn ;
// 隐藏上半部
- (void)homeBarViewDidHiddenTopView ;
// zoom
- (void)homeBarViewReceiveZoom:(float)zoomScale ;
@end

@interface FUHomeBarView : UIView

@property (nonatomic, assign) id<FUHomeBarViewDelegate>delegate ;

//// 隐藏上半部
//- (void)hidHomeBarTopView ;
// 刷新模型页
- (void)reloadModeData ;
@end


@interface FUHomeBarCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) BOOL showBorder ;
@end
