//
//  FUShapeParamsMode.m
//  FUP2A
//
//  Created by L on 2019/3/6.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUShapeParamsMode.h"
#import "FUAvatar.h"
#import <objc/runtime.h>

@interface FUShapeParamsMode ()
@property (nonatomic, strong) NSArray *propertyNames ;
@property (nonatomic, strong) FUAvatar *avatar ;
@property (nonatomic, strong) NSDictionary *defaultValues ;
@end

@implementation FUShapeParamsMode

static FUShapeParamsMode *model = nil ;
+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model = [[FUShapeParamsMode alloc] init] ;
    });
    return model ;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        unsigned int count ;
        objc_property_t *properties = class_copyPropertyList([FUShapeParamsMode class], &count) ;
        
        NSMutableArray *mutableNameArray = [NSMutableArray arrayWithCapacity:1];
        for (int i = 0 ; i < count; i ++) {
            const char *name = property_getName(properties[i]) ;
            NSString *proName = [NSString stringWithFormat:@"%s", name];
            if (![proName isEqualToString:@"propertyNames"] && ![proName isEqualToString:@"avatar"] && ![proName isEqualToString:@"defaultValues"]) {
                [mutableNameArray addObject:proName];
            }
        }
        free(properties) ;
        
        self.propertyNames = [mutableNameArray copy];
    }
    return self ;
}

- (void)resetDefaultParamsWithAvatar:(FUAvatar *)avatar {
    _avatar = avatar ;
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *proName in self.propertyNames) {
        double value = [avatar getFacepupModeParamWith:proName];
        [[FUShapeParamsMode shareInstance] setValue:@(value) forKey:proName];
        [dict setObject:@(value) forKey:proName];
    }
    [FUShapeParamsMode shareInstance].defaultValues = [dict copy];
}

- (void)recordParam:(NSString *)key value:(double)value {
    if ([[FUShapeParamsMode shareInstance].propertyNames containsObject:key]) {
        [[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
    }
}

- (double)valueWithKey:(NSString *)key {
    if ([self.propertyNames containsObject:key]) {
        return [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue] ;
    }
    return 0.0 ;
}

- (BOOL)propertiesIsChanged {
    for (NSString *propertyName in self.propertyNames) {
        double value0 = [[[FUShapeParamsMode shareInstance] valueForKey:propertyName] doubleValue];
        double value1 = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:propertyName] doubleValue];
        if (value0 != value1) {
            return YES ;
        }
    }
    return NO ;
}

- (BOOL)headParamsIsChanged {
    NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        if ([propertyName hasPrefix:@"Head"]
            || [propertyName hasPrefix:@"head"]
            || [propertyName hasPrefix:@"cheek"]
            || [propertyName hasPrefix:@"jaw"]) {
            
            [mouthArray addObject:propertyName];
        }
    }
    
    for (NSString *key in mouthArray) {
        double value1 = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
        double value0 = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
        if (value0 != value1) {
            return YES ;
        }
    }
    return NO ;
}
- (BOOL)mouthParamsIsChanged {
    NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        if ([propertyName hasPrefix:@"upperLip"]
            || [propertyName hasPrefix:@"lowerLip"]
            || [propertyName hasPrefix:@"mouth"]
            || [propertyName hasPrefix:@"lipCorner"]) {
            
            [mouthArray addObject:propertyName];
        }
    }
    
    for (NSString *key in mouthArray) {
        double value1 = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
        double value0 = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
        if (value0 != value1) {
            return YES ;
        }
    }
    return NO ;
}
- (BOOL)noseParamsIsChanged {
    NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        if ([propertyName hasPrefix:@"nos"]) {
            
            [mouthArray addObject:propertyName];
        }
    }
    
    for (NSString *key in mouthArray) {
        double value1 = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
        double value0 = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
        if (value0 != value1) {
            return YES ;
        }
    }
    return NO ;
}
- (BOOL)eyesParamsIsChanged {
    NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        if ([propertyName hasPrefix:@"Eye_"]) {
            
            [mouthArray addObject:propertyName];
        }
    }
    
    for (NSString *key in mouthArray) {
        double value1 = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
        double value0 = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
        if (value0 != value1) {
            return YES ;
        }
    }
    return NO ;
}

- (NSDictionary *)resetHeadParams {
    NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        if ([propertyName hasPrefix:@"Head"]
            || [propertyName hasPrefix:@"head"]
            || [propertyName hasPrefix:@"cheek"]
            || [propertyName hasPrefix:@"jaw"]) {
            
            [mouthArray addObject:propertyName];
        }
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *key in mouthArray) {
        double value = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
        [[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
        [dict setObject:@(value) forKey:key];
    }
    return [dict copy];
}
- (NSDictionary *)resetMouthParams {
    NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        if ([propertyName hasPrefix:@"upperLip"]
            || [propertyName hasPrefix:@"lowerLip"]
            || [propertyName hasPrefix:@"mouth"]
            || [propertyName hasPrefix:@"lipCorner"]) {
            
            [mouthArray addObject:propertyName];
        }
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *key in mouthArray) {
        double value = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
        [[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
        [dict setObject:@(value) forKey:key];
    }
    return [dict copy];
}
- (NSDictionary *)resetNoseParams {
    NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        if ([propertyName hasPrefix:@"nos"]) {
            
            [mouthArray addObject:propertyName];
        }
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *key in mouthArray) {
        double value = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
        [[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
        [dict setObject:@(value) forKey:key];
    }
    return [dict copy];
}
- (NSDictionary *)resetEyesParams {
    NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        if ([propertyName hasPrefix:@"Eye_"]) {
            
            [mouthArray addObject:propertyName];
        }
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *key in mouthArray) {
        double value = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
        [[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
        [dict setObject:@(value) forKey:key];
    }
    return [dict copy];
}

//- (void)setAllPropertiesToDefault {
//    [self resetDefaultParamsWithAvatar:self.avatar];
//}

- (NSArray *)finalShapeParams {
    
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:1];
    for (NSString *propertyName in self.propertyNames) {
        id value = [[FUShapeParamsMode shareInstance] valueForKey:propertyName];
        [params addObject:value];
    }
    return [params copy];
}

@end
