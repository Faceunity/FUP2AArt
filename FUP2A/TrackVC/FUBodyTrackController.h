//
//  FUBodyTrackController.h
//  FUP2A
//
//  Created by Chen on 2020/4/2.
//  Copyright © 2020 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUPoseTrackView.h"
NS_ASSUME_NONNULL_BEGIN

@interface FUBodyTrackController : UIViewController
@property (nonatomic, strong)FUPoseTrackView  *poseTrackView ;
@property (nonatomic, assign) BOOL isShow;
@property (nonatomic, strong) void (^ touchBlock)(void);
-(void)hideOrShowPoseTrackView;
- (void)resetBottom;
@end

NS_ASSUME_NONNULL_END
