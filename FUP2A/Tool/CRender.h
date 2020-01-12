//
//  CRender.h
//  FULive
//
//  Created by L on 2018/3/28.
//  Copyright © 2018年 liuyang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
typedef NS_OPTIONS(NSUInteger, FUOrientation) {
    FUOrientationOriginal                 = 0,
    FUOrientationLeft                 = 1 << 0,
    FUOrientationUp                   = 1 << 1,
    FUOrientationRight                = 1 << 2,
    FUOrientationDown                 = 1 << 3,
    FUOrientationHorizontallyMirror   = 1 << 4,
    FUOrientationVerticallyMirror     = 1 << 5
};
typedef struct FUCutoutOption_ *FUCutoutOption;    // 调用cutoutPixelBuffer方法的选项
struct FUCutoutOption_{
   CGRect rect;
   FUOrientation orientation;
};
@interface CRender : NSObject

+ (CRender *)shareRenderer;

/**     按照给定的尺寸 剪裁 pixelBuffer     */
- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer WithSize:(CGSize)size;

- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect;
// 添加x镜像
- (CVPixelBufferRef)cutoutPixelBufferInXMirror:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect;


// 添加y镜像
- (CVPixelBufferRef)cutoutPixelBufferInYMirror:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect;
// 添加xy镜像
- (CVPixelBufferRef)cutoutPixelBufferInXYMirror:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect ;
/// 使用C语言方法水平翻转pixelBuffer
/// @param pixelBuffer 源pixelBuffer
/// @return CVPixelBufferRef 翻转后的pixelBuffer
- (CVPixelBufferRef)mirrorPixelBufferInXUseC:(CVPixelBufferRef)pixelBuffer;
/**   加背景贴图  **/
@property (nonatomic, strong) UIImage *bgImage ;

- (CVPixelBufferRef)mergeBgImageToBuffer:(CVPixelBufferRef)pixelBuffer ;
- (UIImage *)fixImageOrientationWithImage:(UIImage *)image option:(FUCutoutOption)op;
@end
