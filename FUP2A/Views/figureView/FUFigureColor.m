//
//  FUFigureColor.m
//  EditView
//
//  Created by L on 2018/11/2.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUFigureColor.h"

@implementation FUFigureColor

+ (instancetype)colorWithDict:(NSDictionary *)dict {
    
    FUFigureColor *model = [[FUFigureColor alloc] init];
    
    model.r = [dict[@"r"] doubleValue];
    model.g = [dict[@"g"] doubleValue];
    model.b = [dict[@"b"] doubleValue];
    model.intensity = [dict[@"intensity"] doubleValue];
    
    model.color = [UIColor colorWithRed:model.r / 255.0  green:model.g / 255.0 blue:model.b / 255.0  alpha:1.0];
    
    return model ;
}

-(UIColor *)color {
    if (!_color) {
        _color = [UIColor colorWithRed:self.r / 255.0  green:self.g / 255.0 blue:self.b / 255.0  alpha:1.0];
    }
    return _color ;
}

+ (FUFigureColor *)colorWithR:(double)r g:(double)g b:(double)b {
    FUFigureColor *model = [[FUFigureColor alloc] init];
    
    model.r = r;
    model.g = g;
    model.b = b;
    model.intensity = 1.0 ;
    
    model.color = [UIColor colorWithRed:r / 255.0  green:g / 255.0 blue:b / 255.0  alpha:1.0];
    return model ;
}
+ (FUFigureColor *)colorWithR:(double)r g:(double)g b:(double)b intensity:(double)intensity {
    FUFigureColor *model = [[FUFigureColor alloc] init];
    
    model.r = r;
    model.g = g;
    model.b = b;
    model.intensity = intensity ;
    
    model.color = [UIColor colorWithRed:r / 255.0  green:g / 255.0 blue:b / 255.0  alpha:1.0];
    return model ;
}

- (void)encodeWithCoder:(NSCoder *)aCoder   {
    
    [aCoder encodeDouble:_r forKey:@"r"];
    [aCoder encodeDouble:_g forKey:@"g"];
    [aCoder encodeDouble:_b forKey:@"b"];
    [aCoder encodeDouble:_intensity forKey:@"intensity"];
    [aCoder encodeInteger:_index forKey:@"index"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.r = [aDecoder decodeDoubleForKey:@"r"];
        self.g = [aDecoder decodeDoubleForKey:@"g"];
        self.b = [aDecoder decodeDoubleForKey:@"b"];
        self.intensity = [aDecoder decodeDoubleForKey:@"intensity"];
        self.index = [aDecoder decodeIntegerForKey:@"index"];
    }
    return self;
}

- (BOOL)colorIsEqualTo:(FUFigureColor *)color {
    
    if (self.r == color.r && self.g == color.g && self.b == color.b) {
        return YES ;
    }
    
    return NO ;
}

@end
