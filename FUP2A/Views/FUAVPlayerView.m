//
//  FUAVPlayerView.m
//  FUP2A
//
//  Created by LEE on 6/29/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUAVPlayerView.h"


@implementation FUAVPlayerView
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {

    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
	[(AVPlayerLayer *)[self layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
@end
