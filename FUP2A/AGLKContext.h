//
//  AGLKContext.h
//  OpenGL ES 02-GLKit
//
//  Created by Dustin on 17/3/16.
//  Copyright © 2017年 PicVision. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface AGLKContext : EAGLContext
{
    GLKVector4 _clearColor;
}

@property (nonatomic,assign)GLKVector4 clearColor;

- (void)clear:(GLbitfield)mask;
@end
