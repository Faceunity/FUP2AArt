//
//  FUStaLiteRequestManager.h
//  FUStaLiteDemo
//
//  Created by Lechech on 2019/10/10.
//  Copyright © 2019 ly-Mac. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FUStaLiteHandler)(NSError* __nullable error,NSData *voiceData,NSData *expressionData,float timeStride);

@interface FUStaLiteRequestManager : NSObject


+ (instancetype)shareManager;

/*
 合成方式A
 
 参数说明:
 
 | 名字         | 类型   | 必须 | 说明
 
 | text        | string | 是   | 上传的文本
 | name        | string | 是   | 发音人姓名，详见发音人列表
 | format      | string | 是   | 返回的音频格式       ['pcm', 'wav', 'mp3', 'opus']
 | volume      | number | 否   | 音量 0 ~ 1  default 0.5
 | speed       | number | 否   | 语速  0.5 ~ 2 default 1
 | sample_rate | number | 否   | 采样率 default 16000
 
 
 
 发音人列表:
 
 Siqi
 Sicheng
 Sijing
 Xiaobei
 Aiqi
 Aijia
 Aicheng
 Aida
 Aiya
 Aixia
 Aimei
 Aiyu
 Aiyue
 Aijing
 Aitong
 Aiwei
 Aibao
 
 
 
 调用示例:
 [[FUStaLiteRequestManager shareManager] process:text
                                      voiceName:@"Sicheng"
                                    voiceFormat:@"mp3"
                                    voiceVolume:@"0.1"
                                     voiceSpeed:@"1.5"
                                voiceSamplerate:nil
                                         result:^(NSError * _Nullable error, NSData * _Nonnull voiceData, NSData * _Nonnull expressionData) {
 
 
                                            NSLog(@"audio:%lu",(unsigned long)voiceData.length);
                                            NSLog(@"expression:%lu",(unsigned long)expressionData.length);
 
 
                                        }];
 
 */
- (void)process:(NSString*)text
       voiceName:(NSString*)name
     voiceFormat:(NSString*)format
     voiceVolume:(NSString* __nullable)volume
      voiceSpeed:(NSString* __nullable)speed
 voiceSamplerate:(NSString* __nullable)samplerate
          result:(FUStaLiteHandler)result;






@end

NS_ASSUME_NONNULL_END
