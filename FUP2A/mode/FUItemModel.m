//
//  FUItemModel.m
//  FUP2A
//
//  Created by Chen on 2020/1/16.
//  Copyright © 2020 L. All rights reserved.
//

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

- (NSString *)getBundlePath
{
    return [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/%@/%@",self.path,self.bundle];
}

- (NSString *)getIconPath
{
    return [[NSBundle mainBundle].resourcePath stringByAppendingFormat:@"/Resource/%@/%@",self.path,self.icon];
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

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList([self class], &outCount);
        for(i = 0; i < outCount; i++)
        {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName)
            {
                NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
                [self setValue:[coder decodeObjectForKey:propertyName] forKey:propertyName];
            }
        }
        // 复制的对象  重新设置一些属性
        free(properties);
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
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
            [coder encodeObject:value forKey:propertyName];
        }
    }
    // 复制的对象  重新设置一些属性
    free(properties);
}

- (BOOL)isEqualToBGModel:(FUItemModel *)model
{
    if (![self.type isEqualToString:model.type]
        ||![self.path isEqualToString:model.path]
        ||![self.name isEqualToString:model.name]
        ||![self.bundle isEqualToString:model.bundle]
        )
    {
        return NO;
    }
    
    return YES;
}

@end
