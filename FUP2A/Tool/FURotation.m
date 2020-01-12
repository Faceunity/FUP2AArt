//
//  FURotation.m
//  FUP2A
//
//  Created by LEE on 9/29/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "FURotation.h"
#import <Accelerate/Accelerate.h>
@implementation FURotation{
	CIContext *coreImageContext;
}

- (instancetype)init{
	if((self = [super init]) != nil){
		
		EAGLContext *glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		GLKView *glView = [[GLKView alloc] initWithFrame:CGRectMake(0.0, 0.0, 360.0, 480.0) context:glContext];
		coreImageContext = [CIContext contextWithEAGLContext:glView.context];
		
	}
	
	return self;
}


#pragma mark - Methods Refactored GPUImage - Devanshu
+(CVPixelBufferRef)pixelBufferOrientation:(CMSampleBufferRef)sampleBuffer withOrientation:(UIInterfaceOrientation)orientation
{
	CVImageBufferRef imageBuffer        = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	size_t bytesPerRow                  = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width                        = CVPixelBufferGetWidth(imageBuffer);
	size_t height                       = CVPixelBufferGetHeight(imageBuffer);
	size_t currSize                     = bytesPerRow * height * sizeof(unsigned char);
	size_t bytesPerRowOut               = 4 * height * sizeof(unsigned char);
	
	void *srcBuff                       = CVPixelBufferGetBaseAddress(imageBuffer);
	
	/* rotationConstant:
	 *  0 -- rotate 0 degrees (simply copy the data from src to dest)
	 *  1 -- rotate 90 degrees counterclockwise
	 *  2 -- rotate 180 degress
	 *  3 -- rotate 270 degrees counterclockwise
	 */
	// 正确处理pixelBuffer的方向
	uint8_t rotationConstant = 0;
	switch (orientation) {
		case UIInterfaceOrientationLandscapeRight:
			break;
		case UIInterfaceOrientationLandscapeLeft:
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			break;
		case UIInterfaceOrientationPortrait:
			rotationConstant            = 3;
			break;
			
		default:
			break;
	}
	
	unsigned char *dstBuff              = (unsigned char *)malloc(currSize);
	
	vImage_Buffer inbuff                = {srcBuff, height, width, bytesPerRow};
	vImage_Buffer outbuff               = {dstBuff, width, height, bytesPerRowOut};
	
	uint8_t bgColor[4]                  = {0, 0, 0, 0};
	
	vImage_Error err                    = vImageRotate90_ARGB8888(&inbuff, &outbuff, rotationConstant, bgColor, 0);
	if (err != kvImageNoError) NSLog(@"%ld", err);
	
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
	CVPixelBufferRef rotatedBuffer      = NULL;
	CVPixelBufferCreateWithBytes(NULL,
								 height,
								 width,
								 kCVPixelFormatType_32BGRA,
								 outbuff.data,
								 bytesPerRowOut,
								 freePixelBufferDataAfterRelease,
								 NULL,
								 NULL,
								 &rotatedBuffer);
	
	return rotatedBuffer;
}
+ (CVPixelBufferRef)correctBufferOrientation:(CMSampleBufferRef)sampleBuffer withRotationConstant:(int)rotationConstant
{
	CVImageBufferRef imageBuffer        = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	size_t bytesPerRow                  = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width                        = CVPixelBufferGetWidth(imageBuffer);
	size_t height                       = CVPixelBufferGetHeight(imageBuffer);
	size_t currSize                     = bytesPerRow * height * sizeof(unsigned char);
	size_t bytesPerRowOut               = 4 * height * sizeof(unsigned char);
	
	void *srcBuff                       = CVPixelBufferGetBaseAddress(imageBuffer);
	
	/* rotationConstant:
	 *  0 -- rotate 0 degrees (simply copy the data from src to dest)
	 *  1 -- rotate 90 degrees counterclockwise
	 *  2 -- rotate 180 degress
	 *  3 -- rotate 270 degrees counterclockwise
	 */
	
	unsigned char *dstBuff              = (unsigned char *)malloc(currSize);
	
	vImage_Buffer inbuff                = {srcBuff, height, width, bytesPerRow};
	vImage_Buffer outbuff               = {dstBuff, width, height, bytesPerRowOut};
	
	uint8_t bgColor[4]                  = {0, 0, 0, 0};
	
	vImage_Error err                    = vImageRotate90_ARGB8888(&inbuff, &outbuff, rotationConstant, bgColor, 0);
	if (err != kvImageNoError) NSLog(@"%ld", err);
	
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
	CVPixelBufferRef rotatedBuffer      = NULL;
	CVPixelBufferCreateWithBytes(NULL,
								 height,
								 width,
								 kCVPixelFormatType_32BGRA,
								 outbuff.data,
								 bytesPerRowOut,
								 freePixelBufferDataAfterRelease,
								 NULL,
								 NULL,
								 &rotatedBuffer);
	
	return rotatedBuffer;
}

+ (CVPixelBufferRef)correctBufferOrientation:(CMSampleBufferRef)sampleBuffer
{
	CVImageBufferRef imageBuffer        = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	size_t bytesPerRow                  = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width                        = CVPixelBufferGetWidth(imageBuffer);
	size_t height                       = CVPixelBufferGetHeight(imageBuffer);
	size_t currSize                     = bytesPerRow * height * sizeof(unsigned char);
	size_t bytesPerRowOut               = 4 * height * sizeof(unsigned char);
	
	void *srcBuff                       = CVPixelBufferGetBaseAddress(imageBuffer);
	
	/* rotationConstant:
	 *  0 -- rotate 0 degrees (simply copy the data from src to dest)
	 *  1 -- rotate 90 degrees counterclockwise
	 *  2 -- rotate 180 degress
	 *  3 -- rotate 270 degrees counterclockwise
	 */
	uint8_t rotationConstant            = 3;
	
	unsigned char *dstBuff              = (unsigned char *)malloc(currSize);
	
	vImage_Buffer inbuff                = {srcBuff, height, width, bytesPerRow};
	vImage_Buffer outbuff               = {dstBuff, width, height, bytesPerRowOut};
	
	uint8_t bgColor[4]                  = {0, 0, 0, 0};
	
	vImage_Error err                    = vImageRotate90_ARGB8888(&inbuff, &outbuff, rotationConstant, bgColor, 0);
	if (err != kvImageNoError) NSLog(@"%ld", err);
	
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
	CVPixelBufferRef rotatedBuffer      = NULL;
	CVPixelBufferCreateWithBytes(NULL,
								 height,
								 width,
								 kCVPixelFormatType_32BGRA,
								 outbuff.data,
								 bytesPerRowOut,
								 freePixelBufferDataAfterRelease,
								 NULL,
								 NULL,
								 &rotatedBuffer);
	
	return rotatedBuffer;
}

void freePixelBufferDataAfterRelease(void *releaseRefCon, const void *baseAddress)
{
	// Free the memory we malloced for the vImage rotation
	free((void *)baseAddress);
}


- (CGImageRef)cgImageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer // Create a CGImageRef from sample buffer data
{
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	return [self cgImageFromImageBuffer:imageBuffer];
}

- (CGImageRef)cgImageFromImageBuffer:(CVImageBufferRef) imageBuffer // Create a CGImageRef from sample buffer data
{
	CVPixelBufferLockBaseAddress(imageBuffer,0);        // Lock the image buffer
	
	uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);   // Get information of the image
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	CGImageRef newImage = CGBitmapContextCreateImage(newContext);
	CGContextRelease(newContext);
	
	CGColorSpaceRelease(colorSpace);
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
	return newImage;
}

- (CMSampleBufferRef)getSampleBufferUsingCIByCGInput:(CGImageRef)imageRef andProvidedSampleBuffer:(CMSampleBufferRef)sampleBuffer{
	CIImage *theCoreImage = [CIImage imageWithCGImage:imageRef];
	
	CVPixelBufferRef pixelBuffer;
	CVPixelBufferCreate(kCFAllocatorSystemDefault, (size_t)theCoreImage.extent.size.width, (size_t)theCoreImage.extent.size.height, kCVPixelFormatType_32BGRA, NULL, &pixelBuffer);
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
	
	[coreImageContext render:theCoreImage toCVPixelBuffer:pixelBuffer];
	
	CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
	CMSampleTimingInfo sampleTime = {
		.duration = CMSampleBufferGetDuration(sampleBuffer),
		.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
		.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
	};
	CMVideoFormatDescriptionRef videoInfo = NULL;
	CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &videoInfo);
	CMSampleBufferRef oBuf;
	CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &sampleTime, &oBuf);
	CVPixelBufferRelease(pixelBuffer);
	CFRelease(videoInfo);
	return oBuf;
}

@end
