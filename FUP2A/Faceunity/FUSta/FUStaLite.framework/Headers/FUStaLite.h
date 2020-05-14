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

/// 鉴权并设置汉字或英文单词解码数据包
/// @param authData 鉴权数据包
/// @param decoderData 汉字或英文单词解码数据包
+ (BOOL)setupWithAuthData:(NSData *)authData decoderData:(nullable NSData *)decoderData;

/**
 类方法快速获取stalite实例

 @param ttaData tta数据包，即：data_tta.bin
 @return stalite实例
 */
+ (FUStaLite *)staLiteWithTtaData:(nullable NSData *)ttaData;

/**
 类方法快速获取stalite实例
 
 @param ttaData tta数据包，即：data_tta.bin
 @return stalite实例
 */
- (FUStaLite *)initWithTtaData:(nullable NSData *)ttaData;

/// 加载口型系数数据包
/// @param expConfig 口型系数数据包
- (void)setPhonemeExpressionConfig:(NSData *)expConfig;

/**
 根据时间戳查询表情系数序列数据
 *@param ttsData 时间戳文本，支持音素与文字两种格式的时间戳。
 *@param ttsType 时间戳类型:FUTTSTypePhone(0):音素，FUTTSTypeCharacter(1):文字。
 *@param isStreaming 是否是流式处理
 *@return 表情系数序列数据
 * */
- (NSData *)queryExpressionWith:(NSString *)ttsData ttsType:(FUTTSType)ttsType streamType:(int)streamState;

/// 通过时间进度获取表情系数
/// @param expression 表情系数句柄，必须在使用后手动release
/// @param time 时间
- (int)getExpression:(float **)expression withTime:(float)time;
//debug
- (int)queryPhone:(NSString *)phone out_Phone:(float *)outPhone;

@end

NS_ASSUME_NONNULL_END
