//
//  FUP2AColor.h
//  FUP2A
//
//  Created by L on 2018/12/15.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FUP2AColor : NSObject

@property (nonatomic, assign) double r ;
@property (nonatomic, assign) double b ;
@property (nonatomic, assign) double g ;
@property (nonatomic, assign) double intensity ;

@property (nonatomic, assign) NSInteger index ;

@property (nonatomic, strong) UIColor *color ;

- (BOOL)colorIsEqualTo:(FUP2AColor *)color ;

+ (instancetype)colorWithDict:(NSDictionary *)dict ;
+ (FUP2AColor *)color:(UIColor*)color ;
+ (FUP2AColor *)colorWithR:(double)r g:(double)g b:(double)b ;
+ (FUP2AColor *)colorWithR:(double)r g:(double)g b:(double)b intensity:(double)intensity;

@end
