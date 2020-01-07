//
//  FUSceneryModel.h
//  FUP2A
//
//  Created by L on 2018/12/19.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FUP2ADefine.h"


@interface FUSingleModel : NSObject

@property (nonatomic, assign) FUGender gender ;
@property (nonatomic, copy) NSString *camera ;    // 相机 bundle 文件
@property (nonatomic, copy) NSString *imageName ;
@property (nonatomic, copy) NSString * animationName ;
@property (nonatomic,strong)NSArray<NSString *> * otherAnimations;

+ (instancetype)modelWithDict:(NSDictionary *)dict ;
@end


@interface FUMultipleModel : NSObject

@property (nonatomic, copy) NSString *imageName ;
@property (nonatomic, strong) NSArray <FUSingleModel *>*modelArray ;
@property (nonatomic, copy) NSString *camera ;    // 相机 bundle 文件
+ (instancetype)modelWithDict:(NSDictionary *)dict ;
@end
