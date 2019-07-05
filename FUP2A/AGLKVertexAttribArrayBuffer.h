//
//  AGLKVertexAttribArrayBuffer.h
//  OpenGL ES 02-GLKit
//
//  Created by Dustin on 17/3/16.
//  Copyright © 2017年 PicVision. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

@interface AGLKVertexAttribArrayBuffer : NSObject

@property (nonatomic,readonly) GLsizei stride;//顶点数组单个元素缓存字节的数量额
@property (nonatomic,readonly) GLsizeiptr bufferSizeBytes;//指定要复制这个缓存字节的数量
@property (nonatomic,readonly) GLuint glName;//保存了用于盛放本例中用到的顶点数据的缓存的OpenGl ES标识符
- (id)initWithAttribStride:(GLsizei)stride numberOfVertices:(GLsizei)count data:(const GLvoid *)dataPtr usage:(GLenum)usage;

- (void)prepareToDrawWithAttrib:(GLint)index numberOfCoordinates:(GLint)count attribOffset:(GLsizei)offset shouldEnable:(BOOL)shouldEnable;

- (void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count;

@end
