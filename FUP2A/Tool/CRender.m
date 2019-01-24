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
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!_context || ![EAGLContext setCurrentContext:_context]) {
            return nil;
        }
        
        [self setupGL];
        
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

- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer WithSize:(CGSize)size {
    
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
    
    int renderframeWidth = (int)CVPixelBufferGetWidth(renderTarget);
    int renderframeHeight = (int)CVPixelBufferGetHeight(renderTarget);
    
    if (size.height != renderframeHeight || size.width != renderframeWidth) {
        
        [self setupBufferWithSize:size];
        return nil;
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
        
        
        GLfloat vertices[] =  {
            -1,-1,
            1, -1,
            -1, 1,
            1,  1,
        };
        
        // 更新顶点数据
        glVertexAttribPointer(rgbPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glEnableVertexAttribArray(rgbPositionAttribute);
        
        // 更新纹理坐标
        CGFloat sizeDf = size.width / size.height ;
        CGFloat frameDf = (CGFloat)frameWidth / (CGFloat)frameHeight ;
        
        CGFloat dw ;
        CGFloat dh ;
        
        if (sizeDf > frameDf) {
            
            dw = 1;
            dh = frameDf / sizeDf;
        }else {
            
            dw = sizeDf / frameDf;
            dh = 1 ;
        }
        
        GLfloat quadTextureData[] =  {
            (1-dw)/2.0, (1-dh)/2.0,// 00
            dw + (1-dw)/2.0, (1-dh)/2.0,// 10
            (1-dw)/2.0, dh + (1-dh)/2.0,// 01
            dw + (1-dw)/2.0, dh + (1-dh)/2.0,// 11
        };
        
        glVertexAttribPointer(rgbTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData);
        
        glEnableVertexAttribArray(rgbTextureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glFinish();
        
    }
    return renderTarget;
}

- (CVPixelBufferRef)cutoutPixelBuffer:(CVPixelBufferRef)pixelBuffer WithRect:(CGRect)rect {
    
    if (pixelBuffer == NULL) return pixelBuffer;
    
    if (!_videoTextureCache) {
        NSLog(@"No video texture cache");
        return pixelBuffer;
    }
    
    if ([EAGLContext currentContext] != _context) {
        [EAGLContext setCurrentContext:_context]; // 非常重要的一行代码
    }
    
    CGSize size = rect.size ;
    
    frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    
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
        
        
        GLfloat vertices[] =  {
            -1,-1,
            1, -1,
            -1, 1,
            1,  1,
        };
        
        // 更新顶点数据
        glVertexAttribPointer(rgbPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glEnableVertexAttribArray(rgbPositionAttribute);
        
//        // 更新纹理坐标
//        CGFloat sizeDf = size.width / size.height ;
//        CGFloat frameDf = (CGFloat)frameWidth / (CGFloat)frameHeight ;
//
//        CGFloat dw ;
//        CGFloat dh ;
//
//        if (sizeDf > frameDf) {
//
//            dw = 1;
//            dh = frameDf / sizeDf;
//        }else {
//
//            dw = sizeDf / frameDf;
//            dh = 1 ;
//        }
//
//        GLfloat quadTextureData[] =  {
//            (1-dw)/2.0, (1-dh)/2.0,// 00
//            dw + (1-dw)/2.0, (1-dh)/2.0,// 10
//            (1-dw)/2.0, dh + (1-dh)/2.0,// 01
//            dw + (1-dw)/2.0, dh + (1-dh)/2.0,// 11
//        };
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

-(void)setBgImage:(UIImage *)bgImage {
    _bgImage = bgImage ;
    
    bgTextureInfo = [GLKTextureLoader textureWithCGImage:bgImage.CGImage options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil] error:nil];
}

-(CVPixelBufferRef)mergeBgImageToBuffer:(CVPixelBufferRef)pixelBuffer {
    
    if (pixelBuffer == NULL || !_videoTextureCache) {
        return pixelBuffer ;
    }
    
    if ([EAGLContext currentContext] != _context) {
        [EAGLContext setCurrentContext:_context];
    }
    
    frameWidth = (int)CVPixelBufferGetWidth(pixelBuffer) ;
    frameHeight = (int)CVPixelBufferGetHeight(pixelBuffer) ;
    
    int renderframeWidth = (int)CVPixelBufferGetWidth(renderTarget);
    int renderframeHeight = (int)CVPixelBufferGetHeight(renderTarget);
    
    if (frameHeight != renderframeHeight || frameWidth != renderframeWidth) {
        [self setupBufferWithSize:CGSizeMake(frameWidth, frameHeight)];
        return nil;
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
        
        //  贴图
        GLfloat quadTextureData1[] =  {
            1.0f, 1.0f,
            0.0f, 1.0f,
            1.0f, 0.0f,
            0.0f, 0.0f,
        };
        glVertexAttribPointer(rgbTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, quadTextureData1);
        glViewport(0 , 0, frameWidth, frameHeight) ;
        glEnableVertexAttribArray(rgbPositionAttribute);
        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D, bgTextureInfo.name);
        glUniform1i(displayInputTextureUniform, 4);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        
        // 更新纹理数据
        GLfloat quadTextureData[] =  {
            0, 0,
            1, 0,
            0, 1,
            1, 1,
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
    

    return renderTarget ;
}

@end
