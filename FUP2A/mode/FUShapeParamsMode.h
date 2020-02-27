//
//  FUShapeParamsMode.h
//  FUP2A
//
//  Created by L on 2019/3/6.
//  Copyright © 2019年 L. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FUAvatar ;
@interface FUShapeParamsMode : NSObject /* ⚠️⚠️ 此类所有属性都是和捏脸点位相关的，禁止增加属性和改变属性相对位置*/

@property (nonatomic, strong) NSMutableDictionary *facepupDict;  //加载捏脸点位
@property (nonatomic, strong) NSArray *faecepupKeyArray;   //捏脸点位key的有序数组
@property(nonatomic,strong) NSMutableDictionary * orginalFaceup;  //最初始的捏脸数据
//@property(nonatomic,strong) NSMutableDictionary * beforeNieLianFaceup;  //进入捏脸模式之前的捏脸数据
@property(nonatomic,strong) NSMutableDictionary * editingFaceup;   //当前的捏脸数据


+ (instancetype)shareInstance ;

/// 获取初始捏脸数据
/// @param avatar 形象
- (void)getOrignalParamsWithAvatar:(FUAvatar *)avatar;

/// 重置捏脸参数，将所有捏脸参数设置为0
/// @param avatar 形象
- (void)resetAllParamsWithAvatar:(FUAvatar *)avatar;

/// 获取最终捏脸参数，针对修改后但是没有生成新head的情况
/// @param avatar 形象
- (NSArray *)getShapeParamsWithAvatar:(FUAvatar *)avatar;

/// 记录参数
/// @param key 参数的key
/// @param value 参数的value
- (void)recordParam:(NSString *)key value:(double)value;

/// 捏脸参数是否发生过改变
- (BOOL)propertiesIsChanged;

/// 进入捏脸模式前记录脸部参数
- (void)recordFacepupBeforeNieLian;

//是否需要重新生成头发
- (BOOL)shouldDeformHair;


- (NSMutableDictionary *)getEditDictWithMeshPoint:(FUMeshPoint *)meshPoint;

- (void)configFacepupParamWithDict:(NSDictionary *)dict;

@end
