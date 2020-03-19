//
//  CRender.m
//  FULive
//
//  Created by L on 2018/3/28.
//  Copyright © 2018年 liuyang. All rights reserved.
//

#import "CRender.h"
#import "FUManager.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <Accelerate/Accelerate.h>

#define STRINGIZE(x)    #x
#define STRINGIZE2(x)    STRINGIZE(x)
#define SHADER_STRINGaaa(text) @ STRINGIZE2(text)

NSString *const kFShaderStringaaa = SHADER_STRINGaaa
(
 uniform sampler2D inputImageTexture;
 
 varying highp vec2 textureCoordinate;
 
 void main()
{
	gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
}
 );

NSString *const kVShaderStringaaa = SHADER_STRINGaaa
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
	gl_Position = position;
	textureCoordinate = inputTextureCoordinate.xy;
}
 );

enum
{
	rgbPositionAttribute,
	rgbTextureCoordinateAttribute
};

static CRender *_shareRenderer = nil;

@implementation CRender
{
	EAGLContext *_context;
	GLuint program;
	GLuint rgbToYuvProgram;
	CVOpenGLESTextureRef _texture;
	CVOpenGLESTextureCacheRef _videoTextureCache;
	GLuint _frameBufferHandle;
	CVOpenGLESTextureRef renderTexture;
	
	GLint displayInputTextureUniform;
	
	CVPixelBufferRef renderTarget;
	int frameWidth;
	int frameHeight;
	
	CVPixelBufferRef pixel_buffer;
	
	
	CVPixelBufferRef copyTarget ;
	unsigned char *outImg ;
	int outImgWidth ;
	int outImgHeight ;
	
	GLKTextureInfo *bgTextureInfo;
	CGSize bgTextureSize ;
	
	dispatch_semaphore_t signal ;
}

+ (CRender *)shareRenderer
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_shareRenderer = [[CRender alloc] init];
	});
	return _shareRenderer;
}

- (instancetype)init
{
	if (self = [super init]) {
		
		_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
		
		if (!_context || ![EAGLContext setCurrentContext:_context]) {
			return nil;
		}
		
		[self setupGL];
		
		signal = dispatch_semaphore_create(1) ;
		self.bgImage = [UIImage imageNamed:@"bgImage.png"];
	}
	return self;
}

- (void)setupGL
{
	[EAGLContext setCurrentContext:_context];
	[self loadShadersRGB];
	
	if (!_videoTextureCache) {
		CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
		if (err != noErr) {
			NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
			return;
		}
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	}
}

- (void)setupBufferWithSize:(CGSize)size    {
	
	glEnableVertexAttribArray(rgbPositionAttribute);
	glVertexAttribPointer(rgbPositionAttribute, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
	
	glEnableVertexAttribArray(rgbTextureCoordinateAttribute);
	glVertexAttribPointer(rgbTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
	
	if (!_frameBufferHandle) {
		glGenFramebuffers(1, &_frameBufferHandle);
		glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
	}
	
	CFDictionaryRef empty; // empty value for attr value.
	CFMutableDictionaryRef attrs;
	empty = CFDictionaryCreate(kCFAllocatorDefault, // our empty IOSurface properties dictionary
							   NULL,
							   NULL,
							   0,
							   &kCFTypeDictionaryKeyCallBacks,
							   &kCFTypeDictionaryValueCallBacks);
	attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
									  1,
									  &kCFTypeDictionaryKeyCallBacks,
									  &kCFTypeDictionaryValueCallBacks);
	
	CFDictionarySetValue(attrs,
						 kCVPixelBufferIOSurfacePropertiesKey,
						 empty);
	if (renderTarget) {
		CVPixelBufferRelease(renderTarget);
	}
	CVReturn theError = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
	
	if (theError)
	{
		NSLog(@"FBO size");
	}
	
	CFRelease(attrs);
	CFRelease(empty);
	CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
												  _videoTextureCache, renderTarget,
												  NULL, // texture attributes
												  GL_TEXTURE_2D,
												  GL_RGBA, // opengl format
												  size.width,
												  size.height,
												  GL_BGRA, // native iOS format
												  GL_UNSIGNED_BYTE,
												  0,
												  &renderTexture);
	glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	//    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 720, 1280, 0, GL_BGRA, GL_UNSIGNED_BYTE, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
	glBindTexture(GL_TEXTURE_2D, 0);
	
}

#pragma mark - OpenGLES drawing

- (void)dealloc
{
	[self cleanUpTextures];
	
	if(_videoTextureCache) {
		CFRelease(_videoTextureCache);
	}
}

- (void)cleanUpTextures
{
	if (_texture) {
		CFRelease(_texture);
		_texture = NULL;
	}
	
	// Periodic texture cache flush every frame
	CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShadersRGB
{
	GLuint vertShader, fragShader;
	
	if (!program) {
		program = glCreateProgram();
	}
	
	// Create and compile the vertex shader.
	if (![self compileShader:&vertShader type:GL_VERTEX_SHADER string:kVShaderStringaaa]) {
		NSLog(@"Failed to compile vertex shader");
		return NO;
	}
	
	// Create and compile fragment shader.
	if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER string:kFShaderStringaaa]) {
		NSLog(@"Failed to compile fragment shader");
		return NO;
	}
	
	// Attach vertex shader to program.
	glAttachShader(program, vertShader);
	
	// Attach fragment shader to program.
	glAttachShader(program, fragShader);
	
	// Bind attribute locations. This needs to be done prior to linking.
	glBindAttribLocation(program, rgbPositionAttribute, "position");
	glBindAttribLocation(program, rgbTextureCoordinateAttribute, "inputTextureCoordinate");
	
	// Link the program.
	if (![self linkProgram:program]) {
		NSLog(@"Failed to link program: %d", program);
		
		if (vertShader) {
			glDeleteShader(vertShader);
			vertShader = 0;
		}
		if (fragShader) {
			glDeleteShader(fragShader);
			fragShader = 0;
		}
		if (program) {
			glDeleteProgram(program);
			program = 0;
		}
		
		return NO;
	}
	
	// Get uniform locations.
	displayInputTextureUniform = glGetUniformLocation(program, "inputImageTexture");
	
	// Release vertex and fragment shaders.
	if (vertShader) {
		glDetachShader(program, vertShader);
		glDeleteShader(vertShader);
	}
	if (fragShader) {
		glDetachShader(program, fragShader);
		glDeleteShader(fragShader);
	}
	
	return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(NSString *)shaderString
{
	GLint status;
	const GLchar *source;
	source = (GLchar *)[shaderString UTF8String];
	
	*shader = glCreateShader(type);
	glShaderSource(*shader, 1, &source, NULL);
	glCompileShader(*shader);
	
#if defined(DEBUG)
	GLint logLength;
	glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(*shader, logLength, &logLength, log);
		NSLog(@"Shader compile log:\n%s", log);
		free(log);
	}
#endif
	
	glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
	if (status == 0) {
		glDeleteShader(*shader);
		return NO;
	}
	
	return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
	GLint status;
	glLinkProgram(prog);
	
#if defined(DEBUG)
	GLint logLength;
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s", log);
		free(log);
	}
#endif
	
	glGetProgramiv(prog, GL_LINK_STATUS, &status);
	if (status == 0) {
		return NO;
	}
	
	return YES;
}

- (BOOL) validateProgram:(GLuint)prog
{
	GLint logLength, status;
	
	glValidateProgram(prog);
	glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(prog, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s", log);
		free(log);
	}
	
	glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
	if (status == 0) {
		return NO;
	}
	
	return YES;
}

+ (void) dealFrameTime:(void (^)(void))block
{
	glFinish();
	CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
	
	block();
	
	static int numberOfFramesCaptured = 0;
	static CGFloat totalFrameTimeDuringCapture = 0;
	
	numberOfFramesCaptured++;
	if (numberOfFramesCaptured > 5)
	{
		glFinish();
		CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
		totalFrameTimeDuringCapture += currentFrameTime;
	}
}

+ (void) dealFrameTimeWithStartTime:(CFAbsoluteTime)startTime
{
	static int numberOfFramesCaptured = 0;
	static CGFloat totalFrameTimeDuringCapture = 0;
	
	numberOfFramesCaptured++;
	if (numberOfFramesCaptured > 5)
	{
		glFinish();
		CFAbsoluteTime currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime);
		totalFrameTimeDuringCapture += currentFrameTime;
		
		CGFloat Average = (totalFrameTimeDuringCapture / (CGFloat)(numberOfFramesCaptured - 5)) * 1000.0;
		
		NSLog(@"Average frame time : %f ms", Average);
		NSLog(@"Current frame time : %f ms", 1000.0 * currentFrameTime);
	}
}
- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer option:(FUCutoutOption)op {
	
	if (pixelBuffer == NULL) return pixelBuffer;
	
	if (!_videoTextureCache) {
		NSLog(@"No video texture cache");
		return pixelBuffer;
	}
	
	if ([EAGLContext currentContext] != _context) {
		[EAGLContext setCurrentContext:_context]; // 非常重要的一行代码
	}
	frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
	frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
	CGRect rect = {0,0,frameWidth,frameHeight};
	if (CGRectEqualToRect(op->rect,CGRectZero) || CGRectEqualToRect(op->rect,CGRectNull));
	else rect = op->rect;
	CGSize size = rect.size ;
	
	int renderframeWidth = (int)CVPixelBufferGetWidth(renderTarget);
	int renderframeHeight = (int)CVPixelBufferGetHeight(renderTarget);
	
	if (size.height != renderframeHeight || size.width != renderframeWidth) {
		
		[self setupBufferWithSize:size];
		//        return nil;
	}
	
	OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
	
	if (type == kCVPixelFormatType_32BGRA) {
		
		[self cleanUpTextures];
		
		CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, frameWidth, frameHeight,GL_BGRA, GL_UNSIGNED_BYTE, 0, &_texture);
		
		if (!_texture || err) {
			NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
			return pixelBuffer;
		}
		
		glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture));
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		GLuint textureHandle = CVOpenGLESTextureGetName(_texture);
		
		glUseProgram(program);
		
		glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
		
		// Set the view port to the entire view.
		glViewport(0, 0, size.width, size.height);
		
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
		
		glActiveTexture(GL_TEXTURE4);
		glBindTexture(GL_TEXTURE_2D, textureHandle);
		glUniform1i(displayInputTextureUniform, 4);
		const int count = 8;
		GLfloat vertices[count] =  {
			-1,-1,
			1, -1,
			-1, 1,
			1,  1,
		};
		FUOrientation orientation = op->orientation;
		if (orientation == FUOrientationOriginal)NSLog(@"orientation == FUOrientationOriginal");
		if (orientation & FUOrientationLeft)NSLog(@"orientation == FUOrientationLeft");
		if (orientation &  FUOrientationUp)NSLog(@"orientation ==  FUOrientationUp");
		if (orientation & FUOrientationRight)NSLog(@"orientation == FUOrientationRight");
		if (orientation &  FUOrientationDown)NSLog(@"orientation ==  FUOrientationDown");
		if (orientation & FUOrientationHorizontallyMirror){
			NSLog(@"orientation == FUOrientationHorizontallyMirror");
			for (int i = 0; i < count; i+=4) {
				CGFloat num0 = vertices[i];
				CGFloat num1 = vertices[i+1];
				vertices[i] = vertices[i+2];
				vertices[i+1] = vertices[i+3];
				vertices[i+2] = num0;
				vertices[i+3] = num1;
			}
		}
		
		if (orientation &   FUOrientationVerticallyMirror){
			NSLog(@"orientation ==  FUOrientationVerticallyMirror");
			for (int i = 0; i < count / 2; i++) {
				CGFloat num0 = vertices[i];
				vertices[i] = vertices[i+4];
				vertices[i+4] = num0;
			}
		}
		
		// 更新顶点数据
		glVertexAttribPointer(rgbPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
		glEnableVertexAttribArray(rgbPositionAttribute);
		
		GLfloat quadTextureData[] =  {
			rect.origin.x / (float)frameWidth,rect.origin.y / (float)frameHeight,                                           // 01
			(rect.origin.x + rect.size.width) / (float)frameWidth,rect.origin.y / (float)frameHeight,                       // 11
			rect.origin.x / (float)frameWidth,(rect.origin.y + rect.size.height)/(float)frameHeight,                        // 00
			(rect.origin.x + rect.size.width) / (float)frameWidth,(rect.origin.y + rect.size.height)/(float)frameHeight,    // 10
		};
		glVertexAttribPointer(rgbTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
		
		glEnableVertexAttribArray(rgbTextureCoordinateAttribute);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glFinish();
		
	}
	
	return renderTarget;
}
- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer WithSize:(CGSize)size {
	CGRect rect = {{0,0},size};
	return [self cutoutPixelBuffer:pixelBuffer WithRect:rect];
}




- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect {
	FUCutoutOption op = malloc(sizeof(*op));
	op->orientation = FUOrientationOriginal;
	op->rect = rect;
	return [self cutoutPixelBuffer:pixelBuffer option:op];
}
// 添加镜像
- (CVPixelBufferRef)cutoutPixelBufferInXMirror:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect {
	FUCutoutOption op = malloc(sizeof(*op));
	op->orientation = FUOrientationHorizontallyMirror;
	op->rect = rect;
	return [self cutoutPixelBuffer:pixelBuffer option:op];
}


// 添加y镜像
- (CVPixelBufferRef)cutoutPixelBufferInYMirror:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect {
	FUCutoutOption op = malloc(sizeof(*op));
	op->orientation = FUOrientationVerticallyMirror;
	op->rect = rect;
	return [self cutoutPixelBuffer:pixelBuffer option:op];
}
// 添加xy镜像
- (CVPixelBufferRef)cutoutPixelBufferInXYMirror:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect {
	FUCutoutOption op = malloc(sizeof(*op));
	op->orientation = FUOrientationHorizontallyMirror | FUOrientationVerticallyMirror;
	op->rect = rect;
	return [self cutoutPixelBuffer:pixelBuffer option:op];
}


/// 使用C语言方法水平翻转pixelBuffer
/// @param pixelBuffer 源pixelBuffer
/// @return CVPixelBufferRef 翻转后的pixelBuffer
- (CVPixelBufferRef)mirrorPixelBufferInXUseC:(CVPixelBufferRef)pixelBuffer {
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER);
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);
	void* pixelBuffer_pod = (void *)CVPixelBufferGetBaseAddress(pixelBuffer);
	int pixelBuffer_stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) ;
	int pixelBuffer_height = (int)CVPixelBufferGetHeight(pixelBuffer) ;
	int pixelBuffer_width = (int)CVPixelBufferGetWidth(pixelBuffer);
	CVPixelBufferRef mirrored_x_pixel = NULL;
	NSDictionary* pixelBufferOptions = @{ (NSString*) kCVPixelBufferPixelFormatTypeKey :
											  @(kCVPixelFormatType_32BGRA),
										  (NSString*) kCVPixelBufferWidthKey : @(pixelBuffer_width),
										  (NSString*) kCVPixelBufferHeightKey : @(pixelBuffer_height),
										  (NSString*) kCVPixelBufferOpenGLESCompatibilityKey : @YES,
										  (NSString*) kCVPixelBufferIOSurfacePropertiesKey : @{}};
	CVPixelBufferCreate(kCFAllocatorDefault,
						pixelBuffer_width, pixelBuffer_height,
						kCVPixelFormatType_32BGRA,
						(__bridge CFDictionaryRef)pixelBufferOptions,
						&mirrored_x_pixel);
	
	CVPixelBufferLockBaseAddress(mirrored_x_pixel, 0);
	void* mirrored_x_pod = (void *)CVPixelBufferGetBaseAddress(mirrored_x_pixel);
	fuRotateImage(pixelBuffer_pod, 0, pixelBuffer_stride / 4, pixelBuffer_height, 0, 1, 0, mirrored_x_pod,NULL);
	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
	CVPixelBufferUnlockBaseAddress(mirrored_x_pixel, 0);
	dispatch_semaphore_signal(signal);
//    CVPixelBufferRelease(pixelBuffer);
	return mirrored_x_pixel;
}

-(void)setBgImage:(UIImage *)bgImage {
	
	// 图片修正
	FUCutoutOption op = malloc(sizeof(*op));
	NSData *fixImageData = UIImageJPEGRepresentation([self fixImageOrientationWithImage:bgImage option:op], 1.0);
	UIImage *fixImage = [UIImage imageWithData:fixImageData];
	
	_bgImage = fixImage ;
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER) ;
	
	if ([EAGLContext currentContext] != _context) {
		[EAGLContext setCurrentContext:_context];
	}
	
	GLKTextureInfo *texture = [GLKTextureLoader textureWithCGImage:fixImage.CGImage options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil] error:nil];
	
	if (bgTextureInfo) {
		GLuint name = bgTextureInfo.name ;
		glDeleteTextures(1, &name) ;
	}
	
	bgTextureInfo = texture;
	
	bgTextureSize = CGSizeMake(CGImageGetWidth(fixImage.CGImage), CGImageGetHeight(fixImage.CGImage)) ;
	
	dispatch_semaphore_signal(signal) ;
}

/// 合并背景，并且是否需要外部返回的CVPixelBufferRef
/// @param pixelBuffer 输入的CVPixelBufferRef
/// @param isReleaseBuffer 是否需要外部释放
-(CVPixelBufferRef)mergeBgImageToBuffer:(CVPixelBufferRef)pixelBuffer ReleaseBuffer:(BOOL*)isReleaseBuffer {
  
  if (pixelBuffer == NULL || !_videoTextureCache) {
    *isReleaseBuffer = YES;
    return pixelBuffer ;
  }
  
  dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER) ;
  
  if ([EAGLContext currentContext] != _context) {
    [EAGLContext setCurrentContext:_context];
  }
  
  frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer) ;
  frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer) ;
  
  if (!renderTarget) {
    [self setupBufferWithSize:CGSizeMake(frameWidth, frameHeight)];
    *isReleaseBuffer = NO;
    CVPixelBufferRelease(pixelBuffer);
    dispatch_semaphore_signal(signal) ;
    return nil;
  }
  
  int renderframeWidth = (int)CVPixelBufferGetWidth(renderTarget);
  int renderframeHeight = (int)CVPixelBufferGetHeight(renderTarget);
  
  if (frameHeight != renderframeHeight || frameWidth != renderframeWidth) {
    [self setupBufferWithSize:CGSizeMake(frameWidth, frameHeight)];
    *isReleaseBuffer = NO;
    CVPixelBufferRelease(pixelBuffer);
    dispatch_semaphore_signal(signal) ;
    return nil;
  }
  OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
  
  if (type == kCVPixelFormatType_32BGRA) {
    
    [self cleanUpTextures];
    
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, frameWidth, frameHeight,GL_BGRA, GL_UNSIGNED_BYTE, 0, &_texture);
    
    if (!_texture || err) {
      NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
      *isReleaseBuffer = YES;
      dispatch_semaphore_signal(signal) ;
      return pixelBuffer;
    }
    
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    GLuint textureHandle = CVOpenGLESTextureGetName(_texture);
    
    glUseProgram(program);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    // Set the view port to the entire view.
    glViewport(0, 0, frameWidth, frameHeight);
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    
    GLfloat vertices[] =  {
      -1, -1,
      1, -1,
      -1,  1,
      1,  1,
    };
    
    // 更新顶点数据
    glVertexAttribPointer(rgbPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glEnableVertexAttribArray(rgbPositionAttribute);
    
    //   背景贴图
    float width , height ;
    width = bgTextureInfo.width ;
    height = bgTextureInfo.height ;
    
    float df      = (float)frameWidth / (float)frameHeight;
    float db      = width  / height;
    
    float sw, w, sh, h;
    
    if (df > db) {      // 以宽为主
      
      sw  = 0.0 ;
      w   = 1.0 ;
      h   = bgTextureSize.width / df / bgTextureSize.height ;
      sh  = (1 - h) / 2.0 ;
    }else {             // 以高为主
      
      sh  = 0.0 ;
      h   = 1.0 ;
      w   = bgTextureSize.height * df / bgTextureSize.width;
      sw  = (1 - w) / 2.0 ;
    }
    
    GLfloat bgTextureData[8] = {
      w + sw, h + sh,
      sw, h + sh,
      w + sw,     sh,
      sw,     sh,
    } ;
    
    glVertexAttribPointer(rgbTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, bgTextureData);
    glViewport(0.0, 0.0, frameWidth, frameHeight) ;
    
    glEnableVertexAttribArray(rgbPositionAttribute);
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, bgTextureInfo.name);
    glUniform1i(displayInputTextureUniform, 4);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    GLfloat quadTextureData[] =  {
      0.0f, 0.0f,
      1.0f, 0.0f,
      0.0f, 1.0f,
      1.0f, 1.0f,
    };
    
    glVertexAttribPointer(rgbTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
    glViewport(0 , 0, frameWidth, frameHeight) ;
    glEnableVertexAttribArray(rgbPositionAttribute);
    glEnableVertexAttribArray(rgbTextureCoordinateAttribute);
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, textureHandle);
    glUniform1i(displayInputTextureUniform, 4);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
      
    glFinish();
  }
  *isReleaseBuffer = NO;
  CVPixelBufferRelease(pixelBuffer);
  dispatch_semaphore_signal(signal) ;
  
  
  return renderTarget ;
}



-(CVPixelBufferRef)mergeBgImageToBuffer:(CVPixelBufferRef)pixelBuffer {
	
	if (pixelBuffer == NULL || !_videoTextureCache) {
		return pixelBuffer ;
	}
	
	dispatch_semaphore_wait(signal, DISPATCH_TIME_FOREVER) ;
	
	if ([EAGLContext currentContext] != _context) {
		[EAGLContext setCurrentContext:_context];
	}
	
	frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer) ;
	frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer) ;
	
	if (!renderTarget) {
		[self setupBufferWithSize:CGSizeMake(frameWidth, frameHeight)];
		dispatch_semaphore_signal(signal) ;
		return nil;
	}
	
	int renderframeWidth = (int)CVPixelBufferGetWidth(renderTarget);
	int renderframeHeight = (int)CVPixelBufferGetHeight(renderTarget);
	
	if (frameHeight != renderframeHeight || frameWidth != renderframeWidth) {
		[self setupBufferWithSize:CGSizeMake(frameWidth, frameHeight)];
		dispatch_semaphore_signal(signal) ;
		return nil;
	}
	OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
	
	if (type == kCVPixelFormatType_32BGRA) {
		
		[self cleanUpTextures];
		
		CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, frameWidth, frameHeight,GL_BGRA, GL_UNSIGNED_BYTE, 0, &_texture);
		
		if (!_texture || err) {
			NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);
			dispatch_semaphore_signal(signal) ;
			return pixelBuffer;
		}
		
		glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(_texture));
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		GLuint textureHandle = CVOpenGLESTextureGetName(_texture);
		
		glUseProgram(program);
		
		glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
		
		// Set the view port to the entire view.
		glViewport(0, 0, frameWidth, frameHeight);
		
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);
		
		glActiveTexture(GL_TEXTURE4);
		glBindTexture(GL_TEXTURE_2D, textureHandle);
		glUniform1i(displayInputTextureUniform, 4);
		
		
		GLfloat vertices[] =  {
			-1, -1,
			1, -1,
			-1,  1,
			1,  1,
		};
		
		// 更新顶点数据
		glVertexAttribPointer(rgbPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
		glEnableVertexAttribArray(rgbPositionAttribute);
		
		//   贴图
		float width , height ;
		width = bgTextureInfo.width ;
		height = bgTextureInfo.height ;
		
		float df      = (float)frameWidth / (float)frameHeight;
		float db      = width  / height;
		
		float sw, w, sh, h;
		
		if (df > db) {      // 以宽为主
			
			sw  = 0.0 ;
			w   = 1.0 ;
			h   = bgTextureSize.width / df / bgTextureSize.height ;
			sh  = (1 - h) / 2.0 ;
		}else {             // 以高为主
			
			sh  = 0.0 ;
			h   = 1.0 ;
			w   = bgTextureSize.height * df / bgTextureSize.width;
			sw  = (1 - w) / 2.0 ;
		}
		
		GLfloat bgTextureData[8] = {
			w + sw, h + sh,
			sw, h + sh,
			w + sw,     sh,
			sw,     sh,
		} ;
		
		glVertexAttribPointer(rgbTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, bgTextureData);
		glViewport(0.0, 0.0, frameWidth, frameHeight) ;
		
		glEnableVertexAttribArray(rgbPositionAttribute);
		glActiveTexture(GL_TEXTURE4);
		glBindTexture(GL_TEXTURE_2D, bgTextureInfo.name);
		glUniform1i(displayInputTextureUniform, 4);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		GLfloat quadTextureData[] =  {
			0.0f, 0.0f,
			1.0f, 0.0f,
			0.0f, 1.0f,
			1.0f, 1.0f,
		};
		
		glVertexAttribPointer(rgbTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
		glViewport(0 , 0, frameWidth, frameHeight) ;
		glEnableVertexAttribArray(rgbPositionAttribute);
		glEnableVertexAttribArray(rgbTextureCoordinateAttribute);
		glActiveTexture(GL_TEXTURE4);
		glBindTexture(GL_TEXTURE_2D, textureHandle);
		glUniform1i(displayInputTextureUniform, 4);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glFinish();
	}
	dispatch_semaphore_signal(signal) ;
	
	
	return renderTarget ;
}

// copy data
// ensure the width and height of sourceBuffer and destBuffer is equal
- (void)copyBuffer:(CVPixelBufferRef)sourceBuffer toBuffer:(CVPixelBufferRef)destBuffer {
	
	CVPixelBufferLockBaseAddress(destBuffer, 0) ;
	CVPixelBufferLockBaseAddress(sourceBuffer, 0) ;
	
	size_t stride = CVPixelBufferGetBytesPerRow(sourceBuffer) ;
	size_t height = CVPixelBufferGetHeight(sourceBuffer) ;
	
	uint8_t *sourBytes = CVPixelBufferGetBaseAddress(sourceBuffer) ;
	uint8_t *destBytes = CVPixelBufferGetBaseAddress(destBuffer) ;
	
	memcpy(destBytes, sourBytes, stride * height) ;
	
	CVPixelBufferUnlockBaseAddress(sourceBuffer, 0) ;
	CVPixelBufferUnlockBaseAddress(destBuffer, 0) ;
}

- (UIImage *)fixImageOrientationWithImage:(UIImage *)image option:(FUCutoutOption)op {

    CGAffineTransform transform = CGAffineTransformIdentity;
    if (image.imageOrientation == UIImageOrientationUp) return image;

	switch (image.imageOrientation) {
		case UIImageOrientationDown:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
			
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
			transform = CGAffineTransformTranslate(transform, image.size.width, 0);
			transform = CGAffineTransformRotate(transform, M_PI_2);
			break;
			
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, 0, image.size.height);
			transform = CGAffineTransformRotate(transform, -M_PI_2);
			break;
			
		default:
			break;
	}
	
	switch (image.imageOrientation) {
		case UIImageOrientationUpMirrored:
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformTranslate(transform, image.size.width, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
			
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRightMirrored:
			transform = CGAffineTransformTranslate(transform, image.size.height, 0);
			transform = CGAffineTransformScale(transform, -1, 1);
			break;
			
		default:
			break;
	}
	
	CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
											 CGImageGetBitsPerComponent(image.CGImage), 0,
											 CGImageGetColorSpace(image.CGImage),
											 CGImageGetBitmapInfo(image.CGImage));
	
	
	FUOrientation orientation = op->orientation;
	if (orientation == FUOrientationOriginal)NSLog(@"orientation == FUOrientationOriginal");
	if (orientation & FUOrientationLeft)NSLog(@"orientation == FUOrientationLeft");
	if (orientation &  FUOrientationUp)NSLog(@"orientation ==  FUOrientationUp");
	if (orientation & FUOrientationRight)NSLog(@"orientation == FUOrientationRight");
	if (orientation &  FUOrientationDown)NSLog(@"orientation ==  FUOrientationDown");
	if (orientation & FUOrientationHorizontallyMirror){
		NSLog(@"orientation == FUOrientationHorizontallyMirror");
		CGContextTranslateCTM(ctx, image.size.width, 0);
		CGContextScaleCTM(ctx, -1.0, 1.0);
	}
	
	if (orientation &   FUOrientationVerticallyMirror){
		NSLog(@"orientation ==  FUOrientationVerticallyMirror");
		CGContextTranslateCTM(ctx, 0, image.size.height);
		CGContextScaleCTM(ctx, 1.0, -1.0);
	}
	CGContextConcatCTM(ctx, transform);
	switch (image.imageOrientation) {
		case UIImageOrientationLeft:
		case UIImageOrientationLeftMirrored:
		case UIImageOrientationRight:
		case UIImageOrientationRightMirrored:
			CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
			break;
			
		default:
			CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
			break;
	}
	
	CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
	UIImage *img = [UIImage imageWithCGImage:cgimg];
	CGContextRelease(ctx);
	CGImageRelease(cgimg);
	return img;
}
-(UIImage *)fixImageOrientationWithImageWithOutDetect:(UIImage *)image option:(FUCutoutOption)op{
    CGSize size = image.size;
    UIGraphicsBeginImageContext(size);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(bitmap, size.width / 2.0, 0);
    CGContextScaleCTM(bitmap,-1.0,1.0);
    CGContextTranslateCTM(bitmap, -size.width / 2.0, 0);
    [image drawInRect:CGRectMake(0.0, 0.0, size.width, size.height)];
    UIImage * resultImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    return resultImage;
}

- (UIImage *)fixNilOrientionImage:(UIImage *)image{
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    transform = CGAffineTransformTranslate(transform, image.size.width, 0);
    transform = CGAffineTransformScale(transform, -1, 1);
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@end
