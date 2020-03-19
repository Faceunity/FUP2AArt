//
//  FURotation.h
//  FUP2A
//
//  Created by LEE on 9/29/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FURotation : NSObject
+(CVPixelBufferRef)pixelBufferOrientation:(CMSampleBufferRef)sampleBuffer withOrientation:(UIInterfaceOrientation)orientation;
+ (CVPixelBufferRef)correctBufferOrientation:(CMSampleBufferRef)sampleBuffer withRotationConstant:(int)rotationConstant;

+(CVPixelBufferRef)correctBufferOrientation:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
