//
//  FUMeshPoint.m
//  FUP2A
//
//  Created by L on 2019/2/28.
//  Copyright © 2019年 L. All rights reserved.
//

#import "FUMeshPoint.h"

@implementation FUMeshPoint

+ (instancetype)meshPointWithDicInfo:(NSDictionary *)dict {
    
    UIImage *image = [UIImage imageNamed:@"mesh_point"];
    
    FUMeshPoint *point = [[FUMeshPoint alloc] initWithImage:image];
    
    point.index = [dict[@"index"] integerValue];
    point.direction = (FUMeshPiontDirection)[dict[@"direction"] integerValue];
    
    point.leftKey = dict[@"left"] ;
    point.rightKey = dict[@"right"] ;
    point.upKey = dict[@"up"] ;
    point.downKey = dict[@"down"] ;
    
    point.selected = NO ;
    
    return point ;
}


+ (instancetype)meshPointWithIndex:(NSInteger)index {
    
    FUMeshPoint *point = [[FUMeshPoint alloc] initWithFrame:CGRectMake(10, 10, 10, 10)];
    
    point.index = index ;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    label.textColor = [UIColor redColor];
    label.font = [UIFont systemFontOfSize:3.0];
    label.textAlignment = NSTextAlignmentCenter ;
    label.text = [NSString stringWithFormat:@"%ld", point.index] ;
    [point addSubview:label];
    label.center = point.center ;
    
    return point ;
}

-(void)setSelected:(BOOL)selected {
    _selected = selected ;
    
    UIImage *image = selected ? [UIImage imageNamed:@"mesh_point_selected"] : [UIImage imageNamed:@"mesh_point"] ;
    
    self.image = image ;
}

@end
