
# FUStaLite.framework使用文档:

### 介绍：FUStaLite库可以将因素时间戳生成口型系数，口型系数用于驱动FaceUnity的虚拟形象说话，还原音频口型。


#### 1. 初始化鉴权FUStaLite库，获取stalite实例
```objc
快速获取stalite实例

@param ttaData tta数据包，即：data_tta.bin
@param authData 鉴权数据包
@return stalite实例
+ (FUStaLite *)staLiteWithTtaData:(NSData *)ttaData authData:(NSData *)authData
```

#### 2. 输入时间戳查询表情系数
```objc
/**
根据时间戳查询表情系数序列数据

*@param ttsData 时间戳文本，支持音素与文字两种格式的时间戳。
*@param ttsType 时间戳类型:FUTTSTypePhone(0):音素，FUTTSTypeCharacter(1):文字。
*@return 表情系数序列数据
* */
-(NSData *)queryExpressionWith:(NSString*)ttsData ttsType:(FUTTSType)ttsType

```


### 示例：你可以参考Demo中提供的FUStaLiteRequestManager来生成表情系数，FUStaLiteRequestManager访问了Faceunity的Tts接口， 将其返回的时间戳输入到FUStaLite库生成对应表情系数。FUStaLiteRequestManager调用示例：

```objc
/*
合成方式

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

*/


- (void)process:(NSString*)text
      voiceName:(NSString*)name
    voiceFormat:(NSString*)format
    voiceVolume:(NSString* __nullable)volume
     voiceSpeed:(NSString* __nullable)speed
voiceSamplerate:(NSString* __nullable)samplerate
         result:(FUStaLiteHandler)result;

```
