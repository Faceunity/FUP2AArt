//
//  FUShapeParamsMode.h
//  FUP2A
//
//  Created by L on 2019/3/6.
//  Copyright © 2019年 L. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FUAvatar ;
@interface FUShapeParamsMode : NSObject

+ (instancetype)shareInstance ;

// 重置此模型全部捏脸参数
- (void)resetDefaultParamsWithAvatar:(FUAvatar *)avatar ;
// 记录某个捏脸参数的改变
- (void)recordParam:(NSString *)key value:(double)value ;
// 获取某个已经修改过的捏脸参数
- (double)valueWithKey:(NSString *)key ;
// 参数是否有修改
- (BOOL)propertiesIsChanged ;
// 头/嘴/眼/鼻 参数是否有改变
- (BOOL)headParamsIsChanged ;
- (BOOL)mouthParamsIsChanged ;
- (BOOL)noseParamsIsChanged ;
- (BOOL)eyesParamsIsChanged ;
// 重置 头/嘴/眼/鼻 参数 - 返回重置之后的参数s值
- (NSDictionary *)resetHeadParams;
- (NSDictionary *)getCurrentHeadParams;
- (NSDictionary *)resetMouthParams;
- (NSDictionary *)getCurrentMouthParams;
- (NSDictionary *)resetNoseParams;
- (NSDictionary *)getCurrentNoseParams;
- (NSDictionary *)resetEyesParams;
- (NSDictionary *)getCurrentEyesParams;

// 最终捏脸参数列表
- (NSArray *)finalShapeParams ;

- (BOOL)shouldDeformHair ;

 @property (nonatomic, assign) double HeadBone_stretch ;
 @property (nonatomic, assign) double HeadBone_shrink ;
 @property (nonatomic, assign) double HeadBone_wide ;
 @property (nonatomic, assign) double HeadBone_narrow ;
 @property (nonatomic, assign) double Head_wide ;
 @property (nonatomic, assign) double Head_narrow ;
 @property (nonatomic, assign) double head_shrink ;
 @property (nonatomic, assign) double head_stretch ;
 @property (nonatomic, assign) double head_fat ;
 @property (nonatomic, assign) double head_thin ;
 @property (nonatomic, assign) double cheek_wide ;
 @property (nonatomic, assign) double cheekbone_narrow ;
 @property (nonatomic, assign) double jawbone_Wide ;
 @property (nonatomic, assign) double jawbone_Narrow ;
 @property (nonatomic, assign) double jaw_m_wide ;
 @property (nonatomic, assign) double jaw_M_narrow ;
 @property (nonatomic, assign) double jaw_wide ;
 @property (nonatomic, assign) double jaw_narrow ;
 @property (nonatomic, assign) double jaw_up ;
 @property (nonatomic, assign) double jaw_lower ;

 @property (nonatomic, assign) double upperLip_Thick ;
 @property (nonatomic, assign) double upperLipSide_Thick ;
 @property (nonatomic, assign) double lowerLip_Thick ;
 @property (nonatomic, assign) double lowerLipSide_Thin ;
 @property (nonatomic, assign) double lowerLipSide_Thick ;
 @property (nonatomic, assign) double upperLip_Thin ;
 @property (nonatomic, assign) double lowerLip_Thin ;
 @property (nonatomic, assign) double mouth_magnify ;
 @property (nonatomic, assign) double mouth_shrink ;
 @property (nonatomic, assign) double lipCorner_Out ;
 @property (nonatomic, assign) double lipCorner_In ;
 @property (nonatomic, assign) double lipCorner_up ;
 @property (nonatomic, assign) double lipCorner_down ;
 @property (nonatomic, assign) double mouth_m_down ;
 @property (nonatomic, assign) double mouth_m_up ;
 @property (nonatomic, assign) double mouth_Up ;
 @property (nonatomic, assign) double mouth_Down ;

 @property (nonatomic, assign) double nostril_Out ;
 @property (nonatomic, assign) double nostril_In ;
 @property (nonatomic, assign) double noseTip_Up ;
 @property (nonatomic, assign) double noseTip_Down ;
 @property (nonatomic, assign) double nose_Up ;
 @property (nonatomic, assign) double nose_tall ;
 @property (nonatomic, assign) double nose_low ;
 @property (nonatomic, assign) double nose_Down ;

 @property (nonatomic, assign) double Eye_wide ;
 @property (nonatomic, assign) double Eye_shrink ;
 @property (nonatomic, assign) double Eye_up ;
 @property (nonatomic, assign) double Eye_down ;
 @property (nonatomic, assign) double Eye_in ;
 @property (nonatomic, assign) double Eye_out ;
 @property (nonatomic, assign) double Eye_close ;
 @property (nonatomic, assign) double Eye_open ;
 @property (nonatomic, assign) double Eye_upper_up ;
 @property (nonatomic, assign) double Eye_upper_down ;
 @property (nonatomic, assign) double Eye_upperBend_in ;
 @property (nonatomic, assign) double Eye_upperBend_out ;
 @property (nonatomic, assign) double Eye_downer_up ;
 @property (nonatomic, assign) double Eye_downer_dn ;
 @property (nonatomic, assign) double Eye_downerBend_in ;
 @property (nonatomic, assign) double Eye_downerBend_out ;
 @property (nonatomic, assign) double Eye_outter_in ;
 @property (nonatomic, assign) double Eye_outter_out ;
 @property (nonatomic, assign) double Eye_outter_up ;
 @property (nonatomic, assign) double Eye_outter_down ;
 @property (nonatomic, assign) double Eye_inner_in ;
 @property (nonatomic, assign) double Eye_inner_out ;
 @property (nonatomic, assign) double Eye_inner_up ;
 @property (nonatomic, assign) double Eye_inner_down ;
@end
