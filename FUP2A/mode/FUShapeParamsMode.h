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

+ (instancetype)shareInstance ;

// 重置此模型全部捏脸参数
- (void)resetDefaultParamsWithAvatar:(FUAvatar *)avatar ;
/// 每次进入编辑界面，进行脸部点位保存
/// @param avatar 记录需要保存点位的avatar
- (void)resetOrignalParamsWithAvatar:(FUAvatar *)avatar;
// 使用字典记录当前初始脸型等点位
- (void)resetDefaultParamsWithDic:(NSDictionary *)dict;
// 使用当前属性来设置默认值
- (void)resetDefaultParamsWithCurrentValue;
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
- (NSDictionary *)getDefaultHeadParams;
- (NSDictionary *)resetMouthParams;
- (NSDictionary *)getCurrentMouthParams;
- (NSDictionary *)getDefaultMouthParams;
- (NSDictionary *)resetNoseParams;
- (NSDictionary *)getCurrentNoseParams;
- (NSDictionary *)getDefaultNoseParams;
- (NSDictionary *)resetEyesParams;
- (NSDictionary *)getCurrentEyesParams;
- (NSDictionary *)getDefaultEyesParams;

// 最终捏脸参数列表
- (NSArray *)finalShapeParams ;

- (BOOL)shouldDeformHair ;

 
 @property (nonatomic, assign) double HeadBone_stretch;
 @property (nonatomic, assign) double HeadBone_shrink;
 @property (nonatomic, assign) double HeadBone_wide;
 @property (nonatomic, assign) double HeadBone_narrow;
 @property (nonatomic, assign) double Head_wide;
 @property (nonatomic, assign) double Head_narrow;
 @property (nonatomic, assign) double head_shrink;
 @property (nonatomic, assign) double head_stretch;
 @property (nonatomic, assign) double head_fat;
 @property (nonatomic, assign) double head_thin;
 @property (nonatomic, assign) double cheek_wide;
 @property (nonatomic, assign) double cheekbone_narrow;
 @property (nonatomic, assign) double jawbone_Wide;
 @property (nonatomic, assign) double jawbone_Narrow;
 @property (nonatomic, assign) double jaw_m_wide;
 @property (nonatomic, assign) double jaw_M_narrow;
 @property (nonatomic, assign) double jaw_wide;
 @property (nonatomic, assign) double jaw_narrow;
 @property (nonatomic, assign) double jaw_up;
 @property (nonatomic, assign) double jaw_lower;
 @property (nonatomic, assign) double upperLip_Thick;
 @property (nonatomic, assign) double upperLipSide_Thick;
 @property (nonatomic, assign) double lowerLip_Thick;
 @property (nonatomic, assign) double lowerLipSide_Thin;
 @property (nonatomic, assign) double lowerLipSide_Thick;
 @property (nonatomic, assign) double upperLip_Thin;
 @property (nonatomic, assign) double lowerLip_Thin;
 @property (nonatomic, assign) double mouth_magnify;
 @property (nonatomic, assign) double mouth_shrink;
 @property (nonatomic, assign) double lipCorner_Out;
 @property (nonatomic, assign) double lipCorner_In;
 @property (nonatomic, assign) double lipCorner_up;
 @property (nonatomic, assign) double lipCorner_down;
 @property (nonatomic, assign) double mouth_m_down;
 @property (nonatomic, assign) double mouth_m_up;
 @property (nonatomic, assign) double mouth_Up;
 @property (nonatomic, assign) double mouth_Down;
 @property (nonatomic, assign) double nostril_Out;
 @property (nonatomic, assign) double nostril_In;
 @property (nonatomic, assign) double noseTip_Up;
 @property (nonatomic, assign) double noseTip_Down;
 @property (nonatomic, assign) double nose_Up;
 @property (nonatomic, assign) double nose_tall;
 @property (nonatomic, assign) double nose_low;
 @property (nonatomic, assign) double nose_Down;
 @property (nonatomic, assign) double Eye_wide;
 @property (nonatomic, assign) double Eye_shrink;
 @property (nonatomic, assign) double Eye_up;
 @property (nonatomic, assign) double Eye_down;
 @property (nonatomic, assign) double Eye_in;
 @property (nonatomic, assign) double Eye_out;
 @property (nonatomic, assign) double Eye_close_L;
 @property (nonatomic, assign) double Eye_close_R;
 @property (nonatomic, assign) double Eye_open_L;
 @property (nonatomic, assign) double Eye_open_R;
 @property (nonatomic, assign) double Eye_upper_up_L;
 @property (nonatomic, assign) double Eye_upper_up_R;
 @property (nonatomic, assign) double Eye_upper_down_L;
 @property (nonatomic, assign) double Eye_upper_down_R;
 @property (nonatomic, assign) double Eye_upperBend_in_L;
 @property (nonatomic, assign) double Eye_upperBend_in_R;
 @property (nonatomic, assign) double Eye_upperBend_out_L;
 @property (nonatomic, assign) double Eye_upperBend_out_R;
 @property (nonatomic, assign) double Eye_downer_up_L;
 @property (nonatomic, assign) double Eye_downer_up_R;
 @property (nonatomic, assign) double Eye_downer_dn_L;
 @property (nonatomic, assign) double Eye_downer_dn_R;
 @property (nonatomic, assign) double Eye_downerBend_in_L;
 @property (nonatomic, assign) double Eye_downerBend_in_R;
 @property (nonatomic, assign) double Eye_downerBend_out_L;
 @property (nonatomic, assign) double Eye_downerBend_out_R;
 @property (nonatomic, assign) double Eye_outter_in;
 @property (nonatomic, assign) double Eye_outter_out;
 @property (nonatomic, assign) double Eye_outter_up;
 @property (nonatomic, assign) double Eye_outter_down;
 @property (nonatomic, assign) double Eye_inner_in;
 @property (nonatomic, assign) double Eye_inner_out;
 @property (nonatomic, assign) double Eye_inner_up;
 @property (nonatomic, assign) double Eye_inner_down;
 @property (nonatomic, assign) double jawTip_forward;
 @property (nonatomic, assign) double jawTip_backward;
 @property (nonatomic, assign) double jawBone_m_up;
 @property (nonatomic, assign) double jawBone_m_down;
 @property (nonatomic, assign) double upperLipSide_thin;
 @property (nonatomic, assign) double mouth_side_up;
 @property (nonatomic, assign) double mouth_side_down;
 @property (nonatomic, assign) double mouth_forward;
 @property (nonatomic, assign) double mouth_backward;
 @property (nonatomic, assign) double noseTip_forward;
 @property (nonatomic, assign) double noseTip_backward;
 @property (nonatomic, assign) double noseTip_magnify;
 @property (nonatomic, assign) double noseTip_shrink;
 @property (nonatomic, assign) double nostril_up;
 @property (nonatomic, assign) double nostril_down;
 @property (nonatomic, assign) double noseBone_tall;
 @property (nonatomic, assign) double noseBone_low;
 @property (nonatomic, assign) double nose_wide;
 @property (nonatomic, assign) double nose_shrink;
 @property (nonatomic, assign) double Eye_forward;
 @property (nonatomic, assign) double Eye_backward;




@end
