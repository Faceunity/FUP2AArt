//
//  FUItemModel.m
//  FUP2A
//
//  Created by Chen on 2020/1/16.
//  Copyright © 2020 L. All rights reserved.
//

#import "FUItemModel.h"

@implementation FUItemModel

- (void)setBundle:(NSString *)bundle
{
    _bundle = bundle;
    if (bundle.length > 0)
    {
        self.name = [self.bundle stringByReplacingOccurrencesOfString:@"mid/" withString:@""];
    }
    else
    {
        self.name = @"noitem.bundle";
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    FUItemModel * model = [[FUItemModel alloc]init];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for(i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName)
        {
            NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
            id value = [self valueForKey:propertyName];
            [model setValue:value forKey:propertyName];
        }
    }
    // 复制的对象  重新设置一些属性
    free(properties);
    return model;
}

@end
