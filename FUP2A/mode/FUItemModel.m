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
        self.name = [self.bundle lastPathComponent];
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




@end


@implementation FUMakeupItemModel    // 美妆模型
-(NSString *)title{
	// 小写的文件名
	NSString * lastPathBundleName = [[self.bundle stringByDeletingPathExtension] lowercaseString];
	NSString * tmpTitle;
	if ([lastPathBundleName containsString:@"eyebrow"]) { // 眉毛
		tmpTitle = @"眉毛";
	}else if ([lastPathBundleName containsString:@"eyelash"]) { // 睫毛
		tmpTitle = @"睫毛";
	}else if ([lastPathBundleName containsString:@"eyeliner"]) { // 眼线
		tmpTitle = @"眼线";
	}else if ([lastPathBundleName containsString:@"eyeshadow"]) { // 眼影
		tmpTitle = @"眼影";
	}else if ([lastPathBundleName containsString:@"facemakeup"]) { // 脸装
		tmpTitle = @"脸装";
	}else if ([lastPathBundleName containsString:@"lipgloss"]) { // 口红
		tmpTitle = @"口红";
	}else if ([lastPathBundleName containsString:@"pupil"]) { // 美瞳
		tmpTitle = @"美瞳";
	}
	return tmpTitle;
}

-(NSString *)type{
	// 小写的文件名
	NSString * lastPathBundleName = [[self.bundle stringByDeletingPathExtension] lowercaseString];
	NSString * tmpType;
	if ([lastPathBundleName containsString:@"eyebrow"]) { // 眉毛
		tmpType = TAG_FU_ITEM_EYEBROW;
	}else if ([lastPathBundleName containsString:@"eyelash"]) { // 睫毛
		tmpType = TAG_FU_ITEM_EYELASH;
	}else if ([lastPathBundleName containsString:@"eyeliner"]) { // 眼线
		tmpType = TAG_FU_ITEM_EYELINER;
	}else if ([lastPathBundleName containsString:@"eyeshadow"]) { // 眼影
		tmpType = TAG_FU_ITEM_EYESHADOW;
	}else if ([lastPathBundleName containsString:@"facemakeup"]) { // 脸装
		tmpType = TAG_FU_ITEM_FACEMAKEUP;
	}else if ([lastPathBundleName containsString:@"lipgloss"]) { // 口红
		tmpType = TAG_FU_ITEM_LIPGLOSS;
	}else if ([lastPathBundleName containsString:@"pupil"]) { // 美瞳
		tmpType = TAG_FU_ITEM_PUPIL;
	}
	return tmpType;
}
@end

@implementation FUMakeupNoItemModel    // 美妆模型 空选项
-(instancetype)initWithItemModel:(FUItemModel *)model{
	if (self = [super init]) {
		unsigned int outCount, i;
		objc_property_t *properties = class_copyPropertyList([FUItemModel class], &outCount);
		for(i = 0; i < outCount; i++)
		{
			objc_property_t property = properties[i];
			const char *propName = property_getName(property);
			const char * attributes = property_getAttributes(property);
			NSString * attributeString = [NSString stringWithUTF8String:attributes];
			NSArray * attributesArray = [attributeString componentsSeparatedByString:@","];
			BOOL isReadOnly = NO;
			if ([attributesArray containsObject:@"R"]) {
				isReadOnly = YES;
			}
			if(propName)
			{
				NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
				
				id value = [model valueForKey:propertyName];
				if (isReadOnly) {   // 如果是只读属性，则不进行复制
				}else{
					[self setValue:value forKey:propertyName];
				}
			}
		}
		// 复制的对象  重新设置一些属性
		free(properties);
		// 重新设置bundle的路径
		self.bundle = [self.bundle lastPathComponent];
	}
	return self;
}
@end

@implementation FUDecorationItemModel    // 配饰模型
-(NSString *)title{
	// 小写的文件名
	NSString * lastPathBundleName = [[self.bundle stringByDeletingPathExtension] lowercaseString];
	NSString * tmpTitle;
	if ([lastPathBundleName containsString:@"shou"]) { // 手饰
		tmpTitle = @"手饰";
	}else if ([lastPathBundleName containsString:@"jiao"]) { // 脚饰
		tmpTitle = @"脚饰";
	}else if ([lastPathBundleName containsString:@"xianglian"]) { // 项链
		tmpTitle = @"项链";
	}else if ([lastPathBundleName containsString:@"erhuan"]) { // 耳环
		tmpTitle = @"耳环";
	}else if ([lastPathBundleName containsString:@"toushi"]) { // 头饰
		tmpTitle = @"头饰";
	}
	return tmpTitle;
}

-(NSString *)type{
	// 小写的文件名
	NSString * lastPathBundleName = [[self.bundle stringByDeletingPathExtension] lowercaseString];
	NSString * tmpType = TAG_FU_ITEM_DECORATION_TOUSHI;
	if ([lastPathBundleName containsString:@"shou"]) { // 手饰
		tmpType = TAG_FU_ITEM_DECORATION_SHOU;
	}else if ([lastPathBundleName containsString:@"jiao"]) { // 脚饰
		tmpType = TAG_FU_ITEM_DECORATION_JIAO;
	}else if ([lastPathBundleName containsString:@"xianglian"]) { // 项链
		tmpType = TAG_FU_ITEM_DECORATION_XIANGLIAN;
	}else if ([lastPathBundleName containsString:@"erhuan"]) { // 耳环
		tmpType = TAG_FU_ITEM_DECORATION_ERHUAN;
	}else if ([lastPathBundleName containsString:@"toushi"]) { // 头饰
		tmpType = TAG_FU_ITEM_DECORATION_TOUSHI;
	}
	return tmpType;
}
@end

@implementation FUDecorationNoItemModel    // 配饰模型  空·选项
-(instancetype)initWithItemModel:(FUItemModel *)model{
	if (self = [super init]) {
		unsigned int outCount, i;
		objc_property_t *properties = class_copyPropertyList([FUItemModel class], &outCount);
		for(i = 0; i < outCount; i++)
		{
			objc_property_t property = properties[i];
			const char *propName = property_getName(property);
			const char * attributes = property_getAttributes(property);
			NSString * attributeString = [NSString stringWithUTF8String:attributes];
			NSArray * attributesArray = [attributeString componentsSeparatedByString:@","];
			BOOL isReadOnly = NO;
			if ([attributesArray containsObject:@"R"]) {
				isReadOnly = YES;
			}
			if(propName)
			{
				NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
				
				id value = [model valueForKey:propertyName];
				if (isReadOnly) {   // 如果是只读属性，则不进行复制
				}else{
					[self setValue:value forKey:propertyName];
				}
			}
		}
		// 复制的对象  重新设置一些属性
		free(properties);
		// 重新设置bundle的路径
		self.bundle = [self.bundle lastPathComponent];
	}
	return self;
}
@end
@implementation FUMultipleRecordItemModel    // 美妆模型
-(instancetype)initWithItemModel:(FUItemModel *)model{
	if (self = [super init]) {
		unsigned int outCount, i;
		objc_property_t *properties = class_copyPropertyList([FUItemModel class], &outCount);
		for(i = 0; i < outCount; i++)
		{
			objc_property_t property = properties[i];
			const char *propName = property_getName(property);
			const char * attributes = property_getAttributes(property);
			NSString * attributeString = [NSString stringWithUTF8String:attributes];
			NSArray * attributesArray = [attributeString componentsSeparatedByString:@","];
			BOOL isReadOnly = NO;
			if ([attributesArray containsObject:@"R"]) {
				isReadOnly = YES;
			}
			if(propName)
			{
				NSString *propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
				
				id value = [model valueForKey:propertyName];
				if (isReadOnly) {   // 如果是只读属性，则不进行复制
				}else{
					[self setValue:value forKey:propertyName];
				}
			}
		}
		// 复制的对象  重新设置一些属性
		free(properties);
	}
	return self;
}
-(FUMultipleRecordItemModelType)recordType{
	if ([self.path containsString:@"makeup"]){
		return FUMultipleRecordItemModelTypeMakeup;
	}else if([self.path containsString:@"decoration"])
	{
		return FUMultipleRecordItemModelTypeDecorations;
	}
	for (id obj in self.multipleSelectedArr) {
		if ([obj isKindOfClass:[FUItemModel class]]) {
			// 互斥
			return FUMultipleRecordItemModelTypeMutualExclusion;
		}
	}
	NSAssert(NO, @"获取 recordType 失败");
	return 0;
}
@end
