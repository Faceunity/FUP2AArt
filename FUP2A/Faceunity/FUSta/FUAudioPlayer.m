//
//  FUAudioPlayer.m
//  FUP2A
//
//  Created by LEE on 10/11/19.
//  Copyright © 2019 L. All rights reserved.
//


#import "FUAudioPlayer.h"


#import <AVFoundation/AVFoundation.h>

@interface FUAudioPlayer() <AVAudioPlayerDelegate>

@property (nonatomic, strong) void (^ completeBlock)(BOOL finished);

@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation FUAudioPlayer

+ (FUAudioPlayer *)sharedAudioPlayer
{
    static FUAudioPlayer *audioPlayer;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        audioPlayer = [[FUAudioPlayer alloc] init];
    });
    return audioPlayer;
}

- (void)playAudioAtPath:(NSString *)path complete:(void (^)(BOOL finished))complete
{
    if (self.player && self.player.isPlaying) {
        [self stopPlayingAudio];
    }
    self.completeBlock = complete;
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    self.player.volume=10;
   BOOL isPreparePlay = [self.player prepareToPlay];
    [self.player setDelegate:self];
    if (error) {
        if (complete) {
            complete(NO);
        }
        return;
    }
    [self.player play];
}

- (void)playAudioData:(NSData *)audioData complete:(void (^)(BOOL finished))complete
{
    if (self.player && self.player.isPlaying) {
        [self stopPlayingAudio];
    }
    self.completeBlock = complete;
    NSError *error;
    self.player = [[AVAudioPlayer alloc] initWithData:audioData error:&error];
    self.player.volume=10;
   BOOL isPreparePlay = [self.player prepareToPlay];
    [self.player setDelegate:self];
    if (error) {
        if (complete) {
            complete(NO);
        }
        return;
    }
    [self.player play];
}

- (void)stopPlayingAudio
{
    [self.player stop];
    if (self.completeBlock) {
        self.completeBlock(NO);
    }
}

- (BOOL)isPlaying
{
    if (self.player) {
        return self.player.isPlaying;
    }
    return NO;
}

#pragma mark - # Delegate
//MARK: AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (self.completeBlock) {
        self.completeBlock(YES);
        self.completeBlock = nil;
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"音频播放出现错误：%@", error);
    if (self.completeBlock) {
        self.completeBlock(NO);
        self.completeBlock = nil;
    }
}

@end

