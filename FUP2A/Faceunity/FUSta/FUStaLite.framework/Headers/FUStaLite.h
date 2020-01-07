//
//  FUStaLite.h
//  FUSta
//
//  Created by ly-Mac on 2019/3/15.
//  Copyright © 2019 faceunity. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    FUTTSTypePhone,
    FUTTSTypeCharacter,
} FUTTSType;

@interface FUStaLite : NSObject

/**
 获取口型系数序列两帧之间的时间间隔。
 */
@property (nonatomic, assign, readonly) float timeStride;

/**
 获取表情系数中bs的个数。
 */
@property (nonatomic, assign, readonly) int bsCount;

/**
 设置口型系数偏移时间，正数为提前，负数为滞后，单位秒。
 */
@property (nonatomic, assign) float expOffsetTime;

/**
 类方法快速获取stalite实例

 @param ttaData tta数据包，即：data_tta.bin
 @param authData 鉴权数据包
 @return stalite实例
 */
+ (FUStaLite *)staLiteWithTtaData:(NSData *)ttaData authData:(NSData *)authData;

/**
 类方法快速获取stalite实例
 
 @param ttaData tta数据包，即：data_tta.bin
 @param authData 鉴权数据包
 @return stalite实例
 */
- (FUStaLite *)initWithTtaData:(NSData *)ttaData authData:(NSData *)authData;

/**
 根据时间戳查询表情系数序列数据
 *@param ttsData 时间戳文本，支持音素与文字两种格式的时间戳。
 *@param ttsType 时间戳类型:FUTTSTypePhone(0):音素，FUTTSTypeCharacter(1):文字。
 *@return 表情系数序列数据
 * */
-(NSData *)queryExpressionWith:(NSString*)ttsData ttsType:(FUTTSType)ttsType;

//debug
- (int)queryPhone:(NSString *)phone out_Phone:(float *)outPhone;
@end

NS_ASSUME_NONNULL_END
