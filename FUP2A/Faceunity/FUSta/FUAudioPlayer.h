//
//  FUAudioPlayer.h
//  FUP2A
//
//  Created by LEE on 10/11/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUAudioPlayer : NSObject

@property (nonatomic, assign, readonly) BOOL isPlaying;

+ (FUAudioPlayer *)sharedAudioPlayer;

- (void)playAudioAtPath:(NSString *)path complete:(void (^)(BOOL finished))complete;
- (void)playAudioData:(NSData *)audioData complete:(void (^)(BOOL finished))complete;

- (void)stopPlayingAudio;

@end

NS_ASSUME_NONNULL_END
