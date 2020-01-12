//
//  FUMeshPoint.h
//  FUP2A
//
//  Created by L on 2019/2/28.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUP2ADefine.h"

@interface FUMeshPoint : UIImageView<NSCopying>

@property (nonatomic, assign) NSInteger index ;
@property (nonatomic, assign) FUMeshPiontDirection direction ;
@property (nonatomic, copy) NSArray *leftKey ;
@property (nonatomic, copy) NSArray *rightKey ;
@property (nonatomic, copy) NSArray *upKey ;
@property (nonatomic, copy) NSArray *downKey ;


@property (nonatomic, assign) BOOL selected ;

+ (instancetype)meshPointWithDicInfo:(NSDictionary *)dict ;

@end
