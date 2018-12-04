//
//  FUHistoryViewController.h
//  FUP2A
//
//  Created by L on 2018/6/20.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUHistoryViewControllerDelegate <NSObject>

@optional
- (void)historyViewDidDeleteCurrentItem ;
@end


@interface FUHistoryViewController : UIViewController


@property (nonatomic, assign) id<FUHistoryViewControllerDelegate>mDelegate ;
@end

@interface FUHistoryCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView ;
@end
