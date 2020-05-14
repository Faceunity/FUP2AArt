//
//  FUMeshPoint.h
//  FUP2A
//
//  Created by L on 2019/2/28.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FUMeshPoint : UIImageView<NSCopying>

@property (nonatomic, assign) NSInteger index ;
@property (nonatomic, assign) FUMeshPiontDirection direction ;
@property (nonatomic, copy) NSString *leftKey ;
@property (nonatomic, copy) NSString *rightKey ;
@property (nonatomic, copy) NSString *upKey ;
@property (nonatomic, copy) NSString *downKey ;


@property (nonatomic, assign) BOOL selected ;

+ (instancetype)meshPointWithDicInfo:(NSDictionary *)dict ;

@end
