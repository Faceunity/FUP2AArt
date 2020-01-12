//
//  FUMusicPlayer.h
//  FULive
//
//  Created by 刘洋 on 2017/10/13.
//  Copyright © 2017年 liuyang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FUMusicPlayerDelegate <NSObject>

- (void)musicPlayerDidFinishPlay;

@end

@interface FUMusicPlayer : NSObject

@property (nonatomic, weak) id<FUMusicPlayerDelegate> delegate;
@property (nonatomic, assign) int id_p;
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, strong) NSData * asrMusicData;

+ (FUMusicPlayer *)sharePlayer;

- (void)playMusic:(NSString *)music;
- (void)playMusicWithUrl:(NSString *)url;

- (void)playMusicData:(NSData *)data;
- (void)playAsrMusicData:(NSData *)data;
- (void)rePlay;

- (void)stop;

- (void)resume;

- (void)pause;
-(void)clearAsrMusicData;
- (float)playProgress;

- (BOOL)isPlaying;

- (NSTimeInterval)currentTime;
- (NSTimeInterval)duration;

@end
