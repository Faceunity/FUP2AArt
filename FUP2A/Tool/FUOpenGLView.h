//
//  FUOpenGLView.h
//  FULiveDemo
//
//  Created by 刘洋 on 2017/8/15.
//  Copyright © 2017年 刘洋. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "AGLKVertexAttribArrayBuffer.h"

@interface FUOpenGLView : UIView

@property (nonatomic,strong) GLKBaseEffect *baseEffect;
@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *vertexBuffer;

//- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// 将buffer显示到屏幕上 默认buffer将会铺满整个屏幕
/// @param pixelBuffer 输入源
/// @param landmarks 脸部点位
/// @param count 脸部点位数量
/// @param mirr 是否镜像
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer withLandmarks:(float *)landmarks count:(int)count Mirr:(BOOL) mirr;
/// 将buffer显示到屏幕上
/// @param pixelBuffer 输入源
/// @param landmarks 脸部点位
/// @param count 脸部点位数量
/// @param spreadScreen 显示的texture是否铺满整个屏幕，YES为是，NO如果buffer不能刚好铺满屏幕，则会显示黑边
/// @param bufferMirr 是否镜像buffer
/// @param landmarksMirr 是否镜像脸部点位
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer withLandmarks:(float *)landmarks count:(int)count bufferMirr:(BOOL)bufferMirr landmarksMirr:(BOOL)landmarksMirr ShouldSpreadScreen:(BOOL)spreadScreen;
// 画横屏
- (void)displayLandscapePixelBuffer:(CVPixelBufferRef)pixelBuffer withLandmarks:(float *)landmarks count:(int)count Mirr:(BOOL) mirr;

- (void)convertMirrorPixelBuffer:(CVPixelBufferRef)pixelBuffer dstPixelBuffer:(CVPixelBufferRef*)dstPixelBuffer;
- (void)convertMirrorPixelBuffer2:(CVPixelBufferRef)pixelBuffer dstPixelBuffer:(CVPixelBufferRef*)dstPixelBuffer;
- (void)playDefaultAvatarInOpengl:(void (^)(void))completeBlock;
- (void)displayLinkTest;
// 画横屏   18 : 16
- (void)display18R16PixelBuffer:(CVPixelBufferRef)pixelBuffer withLandmarks:(float *)landmarks count:(int)count Mirr:(BOOL) mirr;
@end
