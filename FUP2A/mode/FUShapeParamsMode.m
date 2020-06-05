//
//  FUShapeParamsMode.m
//  FUP2A
//
//  Created by L on 2019/3/6.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUShapeParamsMode.h"

@interface FUShapeParamsMode ()
@end

@implementation FUShapeParamsMode

static FUShapeParamsMode *model = nil ;
+ (instancetype)shareInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		model = [[FUShapeParamsMode alloc] init] ;
	});
	return model ;
}

-(instancetype)init
{
	self = [super init];
	if (self) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"facepup.json" ofType:nil];
        NSData *tmpData = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        if (tmpData != nil)
        {
            self.facepupDict = [NSJSONSerialization JSONObjectWithData:tmpData options:NSJSONReadingMutableContainers error:nil];
        }
        
        [self setFaecepupKeyArray];
	}
	return self ;
}

- (void)setFaecepupKeyArray
{
   self.faecepupKeyArray = [self.facepupDict keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSNumber *tNumber1 = (NSNumber *)obj1;
        NSNumber *tNumber2 = (NSNumber *)obj2;
        // 因为满足sortedArrayUsingComparator方法的默认排序顺序，则不需要交换
        if ([tNumber1 integerValue] < [tNumber2 integerValue])
        {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
}

/// 每次进入编辑界面，进行脸部点位保存
/// @param avatar 记录需要保存点位的avatar
- (void)recordOrignalParamsWithAvatar:(FUAvatar *)avatar {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (NSString *proName in self.faecepupKeyArray) {
        double value = [avatar getFacepupModeParamWith:proName];
        [dict setObject:@(value) forKey:proName];
    }
     self.orginalFaceupBeforEnterEditVC = dict;
}
- (void)getOrignalParamsWithAvatar:(FUAvatar *)avatar
{
    NSArray *params = [avatar getFacepupModeParamsWithLength:(int)self.faecepupKeyArray.count];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (int i = 0; i < params.count; i++)
    {
        NSString *key = self.faecepupKeyArray[i];
        
        [dict setValue:params[i] forKey:key];
    }
    self.orginalFaceup = [dict mutableCopy];
	self.editingFaceup = [dict mutableCopy];
}
/// 获取当前的捏脸点位
/// @param avatar 模型
- (void)getCurrentParamsWithAvatar:(FUAvatar *)avatar
{
    NSArray *params = [avatar getFacepupModeParamsWithLength:(int)self.faecepupKeyArray.count];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    for (int i = 0; i < params.count; i++)
    {
        NSString *key = self.faecepupKeyArray[i];
        
        [dict setValue:params[i] forKey:key];
    }
    self.editingFaceup = [dict mutableCopy];
}

- (void)resetAllParamsWithAvatar:(FUAvatar *)avatar
{
    for (NSString *proName in self.facepupDict.allKeys)
    {
        double value = [self.orginalFaceup[proName] doubleValue];
        
        [avatar facepupModeSetParam:proName level:value];
    }
}

- (NSArray *)getShapeParamsWithAvatar:(FUAvatar *)avatar
{
    NSArray *params = [avatar getFacepupModeParamsWithLength:(int)self.faecepupKeyArray.count];

    return [params copy];
}

- (void)recordParam:(NSString *)key value:(double)value
{
    if ([self.editingFaceup.allKeys containsObject:key])
    {
        [self.editingFaceup setValue:@(value) forKey:key];
    }
}

- (NSMutableDictionary *)getEditDictWithMeshPoint:(FUMeshPoint *)meshPoint
{
    NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
    
    NSMutableDictionary *orignalDict = [[NSMutableDictionary alloc]init];
    NSMutableDictionary *currentDict = [[NSMutableDictionary alloc]init];
    
    if (meshPoint.leftKey.length>0&&meshPoint.leftKey != NULL)
    {
        orignalDict[meshPoint.leftKey] = self.orginalFaceup[meshPoint.leftKey];
        currentDict[meshPoint.leftKey] = self.editingFaceup[meshPoint.leftKey];
    }
    
    if (meshPoint.rightKey.length>0&&meshPoint.rightKey != NULL)
    {
        orignalDict[meshPoint.rightKey] = self.orginalFaceup[meshPoint.rightKey];
        currentDict[meshPoint.rightKey] = self.editingFaceup[meshPoint.rightKey];
    }
    
    if (meshPoint.upKey.length>0&&meshPoint.upKey != NULL)
    {
        orignalDict[meshPoint.upKey] = self.orginalFaceup[meshPoint.upKey];
        currentDict[meshPoint.upKey] = self.editingFaceup[meshPoint.upKey];
    }
    
    if (meshPoint.downKey.length>0&&meshPoint.downKey != NULL)
    {
        orignalDict[meshPoint.downKey] = self.orginalFaceup[meshPoint.downKey];
        currentDict[meshPoint.downKey] = self.editingFaceup[meshPoint.downKey];
    }
    
    [editDict setObject:orignalDict forKey:@"oldConfig"];
    [editDict setObject:currentDict forKey:@"currentConfig"];
    
    return editDict;
}

- (BOOL)propertiesIsChanged
{
    for (NSString *propertyName in self.facepupDict.allKeys)
    {
        double value0 = [[self.orginalFaceup valueForKey:propertyName] doubleValue];
        double value1 = [[self.editingFaceup valueForKey:propertyName] doubleValue];
        if (value0 != value1)
        {
            return YES ;
        }
    }
    return NO ;
}

//- (void)recordFacepupBeforeNieLian
//{
//    self.beforeNieLianFaceup = [self.editingFaceup mutableCopy];
//}

- (BOOL)shouldDeformHair
{
    // 改变脸型，就需要重新deform 头发、发帽
    NSArray *array =
    @[@"HeadBone_stretch",
    @"HeadBone_shrink",
    @"HeadBone_wide",
    @"HeadBone_narrow",
    @"Head_wide",
    @"Head_narrow",
    @"head_shrink",
    @"head_stretch",
    
	@"head_fat",
	@"head_thin",
	@"cheek_wide",
	@"cheekbone_narrow",
	@"jawbone_Wide",
	@"jawbone_Narrow",
	@"jaw_m_wide",
	@"jaw_M_narrow",
	@"jaw_wide",
	@"jaw_narrow",
	@"jaw_up",
	@"jaw_lower",
	@"jawTip_forward",
	@"jawTip_backward",
	@"jawBone_m_up",
	@"jawBone_m_down"
    ];
    NSLog(@"self.orginalFaceup--::%@---::%@",self.orginalFaceupBeforEnterEditVC,self.editingFaceup);
    for (NSString *propertyName in array)
    {
        if ([self.orginalFaceupBeforEnterEditVC.allKeys containsObject:propertyName])
        {
            double value0 = [[self.orginalFaceupBeforEnterEditVC valueForKey:propertyName] doubleValue];
            double value1 = [[self.editingFaceup valueForKey:propertyName] doubleValue];
            if (value0 != value1)
            {
                return YES ;
            }
        }
    }
    
    return NO;
}

- (void)configFacepupParamWithDict:(NSDictionary *)dict
{
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        [self recordParam:key value:[obj doubleValue]];
        [avatar facepupModeSetParam:key level:[obj doubleValue]];
    }];
}

@end
