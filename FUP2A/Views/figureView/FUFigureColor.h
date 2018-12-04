//
//  FUFigureColor.h
//  EditView
//
//  Created by L on 2018/11/2.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FUFigureColor : NSObject

@property (nonatomic, strong) UIColor *color ;

@property (nonatomic, assign) double r ;
@property (nonatomic, assign) double b ;
@property (nonatomic, assign) double g ;
@property (nonatomic, assign) double intensity ;

@property (nonatomic, assign) NSInteger index ;

- (BOOL)colorIsEqualTo:(FUFigureColor *)color ;

+ (instancetype)colorWithDict:(NSDictionary *)dict ;
+ (FUFigureColor *)colorWithR:(double)r g:(double)g b:(double)b ;
+ (FUFigureColor *)colorWithR:(double)r g:(double)g b:(double)b intensity:(double)intensity;
@end
