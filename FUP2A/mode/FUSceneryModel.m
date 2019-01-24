//
//  FUSceneryModel.m
//  FUP2A
//
//  Created by L on 2018/12/19.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUSceneryModel.h"


@implementation FUSingleModel

+ (instancetype)modelWithDict:(NSDictionary *)dict {
    
    FUSingleModel *model = [[FUSingleModel alloc] init];
    model.gender = [dict[@"gender"] integerValue];
    model.imageName = dict[@"image"] ;
    model.animationName = dict[@"animation"] ;
    
    return model ;
}
@end



@implementation FUMultipleModel

+ (instancetype)modelWithDict:(NSDictionary *)dict {
    
    FUMultipleModel *model = [[FUMultipleModel alloc] init];
    model.imageName = dict[@"image"] ;
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
    NSArray *dataArray = dict[@"items"];
    for (NSDictionary *dict in dataArray) {
        FUSingleModel *m = [FUSingleModel modelWithDict:dict];
        [array addObject:m];
    }
    model.modelArray = [array copy];
    
    return model ;
}

@end
