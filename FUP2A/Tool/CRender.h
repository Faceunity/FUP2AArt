//
//  CRender.h
//  FULive
//
//  Created by L on 2018/3/28.
//  Copyright © 2018年 liuyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface CRender : NSObject

+ (CRender *)shareRenderer;

/**     按照给定的尺寸 剪裁 pixelBuffer     */
- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer WithSize:(CGSize)size;

- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect;

/**   加背景贴图  **/
@property (nonatomic, strong) UIImage *bgImage ;

- (CVPixelBufferRef)mergeBgImageToBuffer:(CVPixelBufferRef)pixelBuffer ;
@end
