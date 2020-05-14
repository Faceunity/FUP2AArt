//
//  FUMusicPlayer.m
//  FULive
//
//  Created by 刘洋 on 2017/10/13.
//  Copyright © 2017年 liuyang. All rights reserved.
//

#import "FUMusicPlayer.h"


@interface FUMusicPlayer ()<AVAudioPlayerDelegate>

@end

@implementation FUMusicPlayer
{
	AVAudioPlayer *audioPlayer;
	NSString *musicName;
	NSData *musicData;
}

+ (FUMusicPlayer *)sharePlayer{
	static FUMusicPlayer *_sharePlayer;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharePlayer = [[FUMusicPlayer alloc] init];
		//        _sharePlayer.enable = YES;
	});
	
	return _sharePlayer;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		_enable = YES;
	}
	return self;
}

- (void)setEnable:(BOOL)enable{
	if (_enable == enable) {
		return;
	}
	_enable = enable;
	dispatch_async(dispatch_get_main_queue(), ^{
		if (enable) {
			[self rePlay];
		}else [self pause];
	});
}

- (void)playMusic:(NSString *)music{
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([audioPlayer isPlaying]) {
			[audioPlayer stop];
			audioPlayer = nil;
		}
		
		if (music) {
			NSString *path = [[NSBundle mainBundle] pathForResource:music ofType:nil];
			if (path) {
				NSURL *musicUrl = [NSURL fileURLWithPath:path];
				if (musicUrl) {
					musicName = music;
					
					if (self.enable) {
						audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicUrl error:nil];
						//                        audioPlayer.numberOfLoops = 0;
						audioPlayer.delegate = self;
						
						[audioPlayer play];
					}
				}
			}
		}
	});
}
-(void)playMusicWithUrl:(NSString *)url{
  AVPlayerItem * playItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
  AVPlayer * player = [AVPlayer playerWithPlayerItem:playItem];
  player.volume = 1.0;
  [player play];
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
     if (self.asrMusicData) {
    [self playMusicData:self.asrMusicData];
//	NSLog(@"语音完成后播放");
}
	if ([self.delegate respondsToSelector:@selector(musicPlayerDidFinishPlay)]) {
		[self.delegate musicPlayerDidFinishPlay];
	}
//	NSLog(@"audioPlayerDidFinishPlaying flag : %d",flag);
}

- (BOOL)isPlaying{
	return audioPlayer.isPlaying;
}

- (void)playMusicData:(NSData *)data{
	
//    dispatch_async(dispatch_get_main_queue(), ^{
		if ([audioPlayer isPlaying]) {
			[audioPlayer stop];
			audioPlayer = nil;
		}
		
		if (self.enable && data) {
			musicData = data;
			audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
			audioPlayer.delegate = self;
			
			[audioPlayer play];
		}
		
//    });
}
// 特指播放ars中返回的音乐
- (void)playAsrMusicData:(NSData *)data{
	
	self.asrMusicData = data;
	
		if (![self isPlaying]){
		 //   NSLog(@"直接播放");
			audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
			[audioPlayer play];
		}
	
	
}



- (void)resume{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (![audioPlayer isPlaying]) {
			[audioPlayer play];
		}
	});
}

- (void)rePlay{
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (musicName) {
			[self playMusic:musicName];
		}else if (musicData){
			[self playMusicData:musicData];
		}
	});
}

- (void)pause{
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([audioPlayer isPlaying]) {
			[audioPlayer pause];
		}
			self.asrMusicData = nil;
	});
}

- (void)stop{
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if ([audioPlayer isPlaying]) {
			[audioPlayer stop];
		}
		audioPlayer = nil;
		self.asrMusicData = nil;
	});
}
-(void)clearAsrMusicData{
self.asrMusicData = nil;
}

- (float)playProgress {
	if (audioPlayer.duration > 0) {
		return audioPlayer.currentTime / (audioPlayer.duration);
	}else return 0.0;
}

- (NSTimeInterval)currentTime {
	return audioPlayer.currentTime;
}
- (NSTimeInterval)duration {
	return audioPlayer.duration;
}

@end
