//
//  FUTextTrackView.h
//  FUP2A
//
//  Created by LEE on 10/10/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUKeyBoardInputView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FUTextTrackViewDelegate <NSObject>

@optional
// 点击模型
- (void)TextTrackViewDidSelectedAvatar:(FUAvatar *)avatar ;
// 点击滤镜
- (void)TextTrackViewDidSelectedInput:(NSString *)filterName ;
// 点击音色
- (void)TextTrackViewDidSelectedTone:(NSString *)tone ;
// 隐藏上半部
- (void)TextTrackViewDidShowTopView:(BOOL)show ;
// 键盘输入文字
- (void)TextTrackViewInput:(NSString *)text;
// 弹起键盘
- (void)TextTrackViewShowOrHideKeyBoardInput:(BOOL)isShow height:(float)h;
// 退出键盘输入
- (void)TextTrackViewExitFromKeyBoardInput;
// 点击滤镜
- (void)ARFilterViewDidSelectedARFilter:(NSString *)filterName;
@end

@interface FUTextTrackView : UIView
@property (nonatomic, assign) id<FUTextTrackViewDelegate>delegate ;
@property (nonatomic, strong) NSArray *toneArray ;
@property(nonatomic,strong)FUKeyBoardInputView *mInputView;
- (void)selectedModeWith:(FUAvatar *)avatar ;
- (void)showCollection:(BOOL)show ;
// 隐藏键盘
/// return 隐藏之前键盘是否已弹起
-(BOOL)hideKeyboard;

@end

@interface FUTextTrackCell: UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
-(void) selectTheTextLabel:(BOOL) isSelect;
@end

NS_ASSUME_NONNULL_END
