//
//  FUAvatarEditManager.m
//  FUP2A
//
//  Created by LEE on 8/7/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUAvatarEditManager.h"

@implementation FUAvatarEditManager
static FUAvatarEditManager *sharedInstance;
+ (FUAvatarEditManager *)sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sharedInstance = [[FUAvatarEditManager alloc] init];
		sharedInstance.orignalStateDic = [NSMutableDictionary dictionary];
		sharedInstance.undoStack = [[FUStack alloc]init];
		sharedInstance.redoStack = [[FUStack alloc]init];
		sharedInstance.hadNotEdit = YES;
	});
	return sharedInstance;
}
-(void)undoStackPop:(PopCompleteBlock)completion{
	self.undo = YES;
	if (self.redoStack.isEmpty) {
		[self.redoStack push:[self.undoStack pop]];
		[[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditManagerStackNotEmptyNot object:nil];
	}else{
		[self.redoStack push:[self.undoStack pop]];
	}
	NSDictionary * currentConfig = self.undoStack.top;
	if (self.undoStack.isEmpty) {
		completion(self.orignalStateDic,YES);
	}else{
		completion(currentConfig,NO);
	}
}
-(void)redoStackPop:(PopCompleteBlock)completion{
	self.redo = YES;
	[self.undoStack push:[self.redoStack pop]];
	NSDictionary * currentConfig = self.undoStack.top;
	completion(currentConfig,self.redoStack.isEmpty);
	
}
-(void)push:(NSObject *)object{
	if (self.undoStack.top == nil) {
		self.undoStack.top = object;
		[[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditManagerStackNotEmptyNot object:nil];
	}
    [self.undoStack push:object];
}
// 字典模型数组里面是否包含某个键值
-(BOOL)exsit:(NSString *)key{
  return [self.undoStack exsit:key] || [self.redoStack exsit:key];
}
-(void)clear{
	self.hadNotEdit = YES;
	self.enterEditVC = NO;
	self.undo = NO;
	self.redo = NO;
	[self.orignalStateDic removeAllObjects];
	[self.undoStack clear];
	[self.redoStack clear];
}

@end
