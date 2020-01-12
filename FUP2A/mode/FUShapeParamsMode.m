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
@property (nonatomic, strong) NSMutableDictionary *defaultValues ;
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
/// 编辑成功的小阶段，进行脸部点位保存
/// @param avatar 记录需要保存点位的avatar
- (void)resetDefaultParamsWithAvatar:(FUAvatar *)avatar {
	_avatar = avatar ;
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	for (NSString *proName in self.propertyNames) {
		double value = [avatar getFacepupModeParamWith:proName];
		[[FUShapeParamsMode shareInstance] setValue:@(value) forKey:proName];
		[dict setObject:@(value) forKey:proName];
	}
	[FUShapeParamsMode shareInstance].defaultValues = dict;
}
/// 每次进入编辑界面，进行脸部点位保存
/// @param avatar 记录需要保存点位的avatar
- (void)resetOrignalParamsWithAvatar:(FUAvatar *)avatar {
	_avatar = avatar ;
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	for (NSString *proName in self.propertyNames) {
		double value = [avatar getFacepupModeParamWith:proName];
		[[FUShapeParamsMode shareInstance] setValue:@(value) forKey:proName];
		[dict setObject:@(value) forKey:proName];
	}
	[FUManager shareInstance].orginalFaceup = dict;
}
// 使用字典记录当前初始脸型等点位
- (void)resetDefaultParamsWithDic:(NSDictionary *)dict {
	[FUShapeParamsMode shareInstance].defaultValues = dict;
}
// 使用当前属性来设置默认值
- (void)resetDefaultParamsWithCurrentValue {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	
	for (NSString *proName in self.propertyNames) {
		id value = [self valueForKey:proName];
		[dict setObject:value forKey:proName];
	}
	[FUShapeParamsMode shareInstance].defaultValues = dict;
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
		double value1 = [[[FUManager shareInstance].orginalFaceup valueForKey:propertyName] doubleValue];
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
- (NSDictionary *)getCurrentHeadParams {
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
		double value = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
		[[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
		[dict setObject:@(value) forKey:key];
	}
	return [dict copy];
}
/**
 获取默认脸型点位
 
 @return
 */
- (NSDictionary *)getDefaultHeadParams {
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
- (NSDictionary *)getCurrentMouthParams {
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
		double value = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
		[[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
		[dict setObject:@(value) forKey:key];
	}
	return [dict copy];
}
/**
 获取默认嘴巴点位
 
 @return
 */
- (NSDictionary *)getDefaultMouthParams {
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
- (NSDictionary *)getCurrentNoseParams {
	NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
	for (NSString *propertyName in self.propertyNames) {
		if ([propertyName hasPrefix:@"nos"]) {
			
			[mouthArray addObject:propertyName];
		}
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	for (NSString *key in mouthArray) {
		double value = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
		[[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
		[dict setObject:@(value) forKey:key];
	}
	return [dict copy];
}
/**
 获取默认鼻子点位
 
 @return
 */
- (NSDictionary *)getDefaultNoseParams {
	NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
	for (NSString *propertyName in self.propertyNames) {
		if ([propertyName hasPrefix:@"nos"]) {
			
			[mouthArray addObject:propertyName];
		}
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	for (NSString *key in mouthArray) {
		double value = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
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
- (NSDictionary *)getCurrentEyesParams {
	NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
	for (NSString *propertyName in self.propertyNames) {
		if ([propertyName hasPrefix:@"Eye_"]) {
			
			[mouthArray addObject:propertyName];
		}
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	for (NSString *key in mouthArray) {
		double value = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
		[[FUShapeParamsMode shareInstance] setValue:@(value) forKey:key] ;
		[dict setObject:@(value) forKey:key];
	}
	return [dict copy];
}

/**
 获取默认眼镜点位
 
 @return
 */
- (NSDictionary *)getDefaultEyesParams {
	NSMutableArray *mouthArray = [NSMutableArray arrayWithCapacity:1];
	for (NSString *propertyName in self.propertyNames) {
		if ([propertyName hasPrefix:@"Eye_"]) {
			
			[mouthArray addObject:propertyName];
		}
	}
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	for (NSString *key in mouthArray) {
		double value = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
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

- (BOOL)shouldDeformHair {
	NSArray *array = @[@"HeadBone_stretch", @"HeadBone_shrink", @"HeadBone_wide", @"HeadBone_narrow", @"Head_wide", @"Head_narrow", @"head_shrink", @"head_stretch"];
	for (NSString *key in array) {
		double value1 = [[[FUShapeParamsMode shareInstance] valueForKey:key] doubleValue];
		double value0 = [[[FUShapeParamsMode shareInstance].defaultValues valueForKey:key] doubleValue];
		if (value0 != value1) {
			return YES ;
		}
	}
	return NO ;
}
@end
