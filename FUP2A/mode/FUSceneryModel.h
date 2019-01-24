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
@property (nonatomic, copy) NSString *imageName ;
@property (nonatomic, copy) NSString *animationName ;

+ (instancetype)modelWithDict:(NSDictionary *)dict ;
@end


@interface FUMultipleModel : NSObject

@property (nonatomic, copy) NSString *imageName ;
@property (nonatomic, strong) NSArray <FUSingleModel *>*modelArray ;

+ (instancetype)modelWithDict:(NSDictionary *)dict ;
@end
