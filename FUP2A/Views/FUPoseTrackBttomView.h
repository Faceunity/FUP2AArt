//
//  FUPoseTrackBttomView.h
//  FUP2A
//
//  Created by LEE on 9/25/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN



@protocol FUPoseTrackBttomViewDelegate <NSObject>

@optional
// 点击模型
- (void)ARFilterViewDidSelectedAvatar:(FUAvatar *)avatar ;
// 点击滤镜
- (void)ARFilterViewDidSelectedARFilter:(NSString *)filterName ;
// 隐藏上半部
- (void)ARFilterViewDidShowTopView:(BOOL)show ;
@end

@interface FUPoseTrackBttomView : UIView

@property (nonatomic, assign) id<FUPoseTrackBttomViewDelegate>delegate ;
- (void)selectedModeWith:(FUAvatar *)avatar ;
- (void)showCollection:(BOOL)show ;
@end

@interface FUPoseTrackBttomCell: UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end


NS_ASSUME_NONNULL_END
