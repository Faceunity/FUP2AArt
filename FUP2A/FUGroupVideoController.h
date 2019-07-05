//
//  FUGroupVideoController.h
//  FUP2A
//
//  Created by LEE on 6/29/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUGroupVideoController : UIViewController

@property (nonatomic, copy) NSString *videoPath ;

@property (nonatomic, strong) FUAvatar *currentAvatar ;


@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic, weak) IBOutlet FUAVPlayerView *playerView;



@end

NS_ASSUME_NONNULL_END
