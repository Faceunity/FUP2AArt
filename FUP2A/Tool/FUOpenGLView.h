//
//  FUOpenGLView.h
//  FULiveDemo
//
//  Created by 刘洋 on 2017/8/15.
//  Copyright © 2017年 刘洋. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface FUOpenGLView : UIView

@property (nonatomic,strong) GLKBaseEffect *baseEffect;
@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *vertexBuffer;

//- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer withLandmarks:(float *)landmarks count:(int)count Mirr:(BOOL) mirr;
- (void)convertMirrorPixelBuffer:(CVPixelBufferRef)pixelBuffer dstPixelBuffer:(CVPixelBufferRef*)dstPixelBuffer;
- (void)convertMirrorPixelBuffer2:(CVPixelBufferRef)pixelBuffer dstPixelBuffer:(CVPixelBufferRef*)dstPixelBuffer;
-(void)playDefaultAvatarInOpengl:(void (^)(void))completeBlock;
-(void)displayLinkTest;
@end
