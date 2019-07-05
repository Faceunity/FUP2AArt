//
//  AGLKContext.m
//  OpenGL ES 02-GLKit
//
//  Created by Dustin on 17/3/16.
//  Copyright © 2017年 PicVision. All rights reserved.
//

#import "AGLKContext.h"

@implementation AGLKContext

//设置当前OpenGL ES的上下文的“清除颜色”(set存方法)
- (void)setClearColor:(GLKVector4)clearColor{
    _clearColor = clearColor;
    
    glClearColor(clearColor.r,
                 clearColor.g,
                 clearColor.b,
                 clearColor.a);
    
}

//获得当前的OpenGL ES的上下文的“清除颜色”（get取方法）
- (GLKVector4)clearColor{
    return _clearColor;
}

//清除颜色缓冲
- (void)clear:(GLbitfield)mask{
    glClear(mask);
}

@end
