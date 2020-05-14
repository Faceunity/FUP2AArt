//
//  FUP2AColor.m
//  FUP2A
//
//  Created by L on 2018/12/15.
//  Copyright © 2018年 L. All rights reserved.
//
@implementation FUP2AColor

-(UIColor *)color {
    if (!_color) {
        _color = [UIColor colorWithRed:self.r / 255.0  green:self.g / 255.0 blue:self.b / 255.0  alpha:1.0];
    }
    return _color ;
}

/*
 */

- (BOOL)colorIsEqualTo:(FUP2AColor *)color {
    
    if (self.r == color.r && self.g == color.g && self.b == color.b) {
        return YES ;
    }
    
    return NO ;
}

+ (instancetype)colorWithDict:(NSDictionary *)dict {
    
    if (dict == nil) {
        return nil ;
    }
    FUP2AColor *model = [[FUP2AColor alloc] init];
    
    model.r = [dict[@"r"] doubleValue];
    model.g = [dict[@"g"] doubleValue];
    model.b = [dict[@"b"] doubleValue];
    model.intensity = [dict[@"intensity"] doubleValue];
    model.index = [dict[@"index"] integerValue];
    
    return model ;
}
+ (FUP2AColor *)color:(UIColor*)color{
  FUP2AColor *model = [[FUP2AColor alloc] init];
	const CGFloat *colors = CGColorGetComponents( color.CGColor );
    model.r = colors[0] * 255.0;
    model.g = colors[1] * 255.0;
    model.b = colors[2] * 255.0;
    model.intensity = 1.0 ;
    return model ;
}
+ (FUP2AColor *)colorWithR:(double)r g:(double)g b:(double)b {
    FUP2AColor *model = [[FUP2AColor alloc] init];
    
    model.r = r;
    model.g = g;
    model.b = b;
    model.intensity = 1.0 ;
    
    return model ;
}

+ (FUP2AColor *)colorWithR:(double)r g:(double)g b:(double)b intensity:(double)intensity {
    FUP2AColor *model = [[FUP2AColor alloc] init];
    
    model.r = r;
    model.g = g;
    model.b = b;
    model.intensity = intensity ;
    
    return model ;
}
-(NSString *)description{
   return [NSString stringWithFormat:@"{\"r\":%f,\"g\":%f,\"b\":%f,\"intensity\":%f}",self.r,self.g,self.b,self.intensity];
}

@end
