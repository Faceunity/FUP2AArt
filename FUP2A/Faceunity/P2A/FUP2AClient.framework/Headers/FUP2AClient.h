//
//  FUP2AClient.h
//  FUP2A
//
//  Created by L on 2018/10/15.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FUP2AClient : NSObject


+(instancetype)shareInstance ;

/**
 *  初始化 FUP2AClient data
    - 需要先初始化 data 才能使用其他接口，全局只需要初始化 data 一次

 @param coreDataPath    p2a_client_core 文件路径
 @param customDataPath  customData 文件路径
 @param package         密钥数组，必须配置好密钥，SDK 才能正常工作
 @param size            密钥数组大小
 */
- (void)setupClientWithCoreDataPath:(NSString *)coreDataPath
                     customDataPath:(NSString *)customDataPath
                        authPackage:(void *)package
                           authSize:(int)size;

/**
 *  切换 FUP2AClient data
 
 @param customDataPath  customData 文件路径
 */
- (void)reSetupCustomData:(NSString *)customDataPath ;

/**
 *  生成 head.bundle
     - 根据服务端传回的数据流生成 Avatar 的头部模型
 
 *  @param data     服务端传回的数据流
 
 *  @return         生成的头部模型数据
 */
- (NSData *)createAvatarHeadWithData:(NSData *)data ;

/**
 *  生成 hair.Bundle
     - 根据服务端传回的数据流和预置的头发模型 生成和此头部模型匹配的头发模型
 
 *  @param serverData   服务端传回的数据流
 *  @param hairData     预置头发模型数据
 
 *  @return            生成的头发模型数据
 */
- (NSData *)createAvatarHairWithServerData:(NSData *)serverData
                           defaultHairData:(NSData *)hairData ;

/**
 *  对已现有头部模型进行编辑
     - 对现有的头部模型进行形变处理，生成一个新的头部模型
 
 *  @param headData         现有的头部模型数据
 *  @param deformParams     形变参数
 *  @param paramsSize       形变参数大小
 
 *  @return                 新的头部模型数据
 */
- (NSData *)deformAvatarHeadWithHeadData:(NSData *)headData
                   deformParams:(float *)deformParams
                              paramsSize:(NSInteger)paramsSize;

/**
 *  对已现有头发模型进行编辑
     - 对现有的头发模型进行精修处理，生成一个当前头部模型匹配的头发模型
 
 *  @param hairData         预置头发模型数据
 *  @param headData         当前的头部模型数据
 
 *  @return                 新的头发模型数据
 */
- (NSData *)deformAvatarHairWithDefaultHairData:(NSData *)hairData
                                currentHeadData:(NSData *)headData ;

/**
 *  从服务端返回的数据流获取返回值为 int 的参数
 
 *  @param  data        服务端返回的数据流
 *  @param key          参数名
 
 *  @return             返回的参数
 */
- (int)getIntParamWithData:(NSData *)data key:(NSString *)key ;

- (float)getFloatParamWithData:(NSData *)data key:(NSString *)key ;

- (NSString *)getStringParamWithData:(NSData *)data key:(NSString *)key ;

- (NSArray *)getParamsArrayWithData:(NSData *)data key:(NSString *)key ;


/**
 *  释放 client 数据
    - 释放 client 全部数据，重新加载 client 之前需要释放数据
 */
- (void)releaseClientData ;

/**
 *  获取 FUClient 版本号
 
 *  @return             client 版本号
 */
- (NSString *)getClientVersion ;

@end
