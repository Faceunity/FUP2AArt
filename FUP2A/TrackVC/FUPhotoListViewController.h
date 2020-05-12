//
//  FUPhotoListViewController.h
//  FUP2A
//
//  Created by Chen on 2020/4/8.
//  Copyright © 2020 L. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol FUPhotoListViewControllerDelegate <NSObject>
// 取消选择视频
- (void)cancelSelectVideo;
// 已经选择的视频资源
- (void)selectedVideo:(PHAsset*)videoAsset;
@end

@interface FUPhotoListViewController : UIViewController
// 选取视频资源的代理
@property (nonatomic, weak) id<FUPhotoListViewControllerDelegate> assetDelegate;
@end

@interface FUPhotoCollectionCell : UICollectionViewCell

@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UILabel *lblDuration;
@end
NS_ASSUME_NONNULL_END
