//
//  FUGifManager.m
//  FUP2A
//
//  Created by L on 2018/12/24.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUGifManager.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation FUGifManager

+ (void)createGIFFromVideoWithPath:(NSString *)videoPath completion:(void(^)(NSString *gifPath))handle {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        NSLog(@"video path cannot be nil ~");
        handle(nil) ;
    }
    
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    
    float videoLength = (float)asset.duration.value/asset.duration.timescale;
    // 每秒10帧，时间间隔 0.1s
    float increment = 0.1;
    // 总帧数
    int frameCount = (int)(videoLength * 10.0) ;
    
    NSMutableArray *timePoints = [NSMutableArray arrayWithCapacity:1];
    
    for (int i = 0; i < frameCount; i ++) {
        float seconds = increment * i;
        CMTime time = CMTimeMakeWithSeconds(seconds, 1 * NSEC_PER_SEC);
        [timePoints addObject:[NSValue valueWithCMTime:time]];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSString *gifPath = [self createGIFforTimePoints:timePoints fromURL:videoURL frameCount:frameCount];
        handle(gifPath) ;
    });
}

+ (NSString *)createGIFforTimePoints:(NSArray *)timePoints fromURL:(NSURL *)url frameCount:(int)frameCount {
    
    // options
    NSDictionary *fileOption = @{(NSString *)kCGImagePropertyGIFDictionary:@{(NSString *)kCGImagePropertyGIFLoopCount: @(0)}};
    NSDictionary *frameOption = @{(NSString *)kCGImagePropertyGIFDictionary:
                                      @{(NSString *)kCGImagePropertyGIFDelayTime: @(0.1)},(NSString *)kCGImagePropertyColorModel:(NSString *)kCGImagePropertyColorModelRGB};
    
    NSString *gifPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.gif"];
    NSURL *gifURL = [NSURL fileURLWithPath:gifPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:gifPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:gifPath error:nil];
    }
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)gifURL, kUTTypeGIF , frameCount, NULL);
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)fileOption);
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    
    NSError *error = nil;
    CGImageRef previousImageRefCopy = nil;
    for (NSValue *time in timePoints) {
        // 按照时间点取出视频某帧的图像 image
        CGImageRef imageRef = [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
        // 压缩 image
        imageRef = [self reScaleImageWithImage:imageRef scale:0.25];
        
        if (error) {
            NSLog(@"Error copying image: %@", error);
        }
        if (imageRef) {
            CGImageRelease(previousImageRefCopy);
            previousImageRefCopy = CGImageCreateCopy(imageRef);
        } else if (previousImageRefCopy) {
            imageRef = CGImageCreateCopy(previousImageRefCopy);
        } else {
            NSLog(@"Error copying image and no previous frames to duplicate");
            return nil;
        }
        // 添加到 destination
        CGImageDestinationAddImage(destination, imageRef, (CFDictionaryRef)frameOption);
        CGImageRelease(imageRef);
    }
    CGImageRelease(previousImageRefCopy);
    
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to finalize GIF destination: %@", error);
        if (destination != nil) {
            CFRelease(destination);
        }
        return nil;
    }
    CFRelease(destination);
    
    return gifPath;
}

+ (CGImageRef)reScaleImageWithImage:(CGImageRef)imageRef scale:(float)scale {
    
    CGSize newSize = CGSizeMake(CGImageGetWidth(imageRef) * scale, CGImageGetHeight(imageRef) * scale);
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return nil;
    }
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
    transform = CGAffineTransformRotate(transform, M_PI);
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(context, newRect, imageRef);
    
    CFRelease(imageRef);
    
    imageRef = CGBitmapContextCreateImage(context);
    
    UIGraphicsEndImageContext();
    
    return imageRef;
}

@end
