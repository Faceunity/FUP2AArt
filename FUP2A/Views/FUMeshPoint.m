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
    point.bounds = CGRectMake(0, 0, 23, 23);
    point.contentMode = UIViewContentModeCenter;
    point.index = [dict[@"index"] integerValue];
    point.direction = (FUMeshPiontDirection)[dict[@"direction"] integerValue];
    
    point.leftKey = dict[@"left"] ;
    point.rightKey = dict[@"right"] ;
    point.upKey = dict[@"up"] ;
    point.downKey = dict[@"down"] ;
    
    point.selected = NO ;
    
    return point ;
}



-(void)setSelected:(BOOL)selected {
    _selected = selected ;
    
    UIImage *image = selected ? [UIImage imageNamed:@"mesh_point_selected"] : [UIImage imageNamed:@"mesh_point"] ;
	
	self.image = image ;
}
-(id)copyWithZone:(NSZone *)zone{
	FUMeshPoint * copyPoint = [[FUMeshPoint alloc]init];
	copyPoint.index = self.index;
	copyPoint.direction = self.direction;
	copyPoint.leftKey = [self.leftKey copy];
	copyPoint.rightKey = [self.rightKey copy];
	copyPoint.upKey = [self.upKey copy];
	copyPoint.downKey = [self.downKey copy];
	copyPoint.selected = self.selected;
	copyPoint.contentMode = UIViewContentModeCenter;
	copyPoint.frame = self.frame;
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:appManager.editVC action:@selector(longPressAction:)];
	longPress.minimumPressDuration = 0.01;
	[copyPoint addGestureRecognizer:longPress];
	copyPoint.userInteractionEnabled = YES ;
	return copyPoint;
}
@end
