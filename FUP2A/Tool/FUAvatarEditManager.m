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

-(void)undoStackPop:(PopCompleteBlock)completion
{
    self.undo = YES;
    NSObject *obj = self.undoStack.top;
    [self.redoStack push:[self.undoStack pop]];
    [[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditManagerStackNotEmptyNot object:nil];
    completion(obj,self.undoStack.isEmpty);
}

-(void)redoStackPop:(PopCompleteBlock)completion
{
	self.redo = YES;
	[self.undoStack push:[self.redoStack pop]];
    if (self.redoStack.isEmpty)
    {
        [[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditManagerStackNotEmptyNot object:nil];
    }
	NSObject *obj = self.undoStack.top;
	completion(obj,self.redoStack.isEmpty);
	
}
-(BOOL)undoStackEmpty{
	return self.undoStack.isEmpty;
}
-(BOOL)redoStackEmpty{
	return self.redoStack.isEmpty;
}
-(id)undoStackTop{
	return self.undoStack.top;
}
-(id)redoStackTop{
	return self.redoStack.top;
}
-(void)push:(NSObject *)object
{
	if (self.undoStack.top == nil)
    {
		self.undoStack.top = object;
		self.orignalStateDic = object;
		[[NSNotificationCenter defaultCenter]postNotificationName:FUAvatarEditManagerStackNotEmptyNot object:nil];
	}
	[self.undoStack push:object];
}
// 字典模型数组里面是否包含某个键值
-(BOOL)exsit:(NSString *)key
{
	return [self.undoStack exsit:key] || [self.redoStack exsit:key];
}

-(void)clear
{
	self.hadNotEdit = YES;
	self.enterEditVC = NO;
	self.undo = NO;
	self.redo = NO;
	[self.orignalStateDic removeAllObjects];
	[self.undoStack clear];
	[self.redoStack clear];
}

@end

@implementation FUAvatarChangeModel

- (instancetype)init
{
    if (self = [super init])
    {
        self.oldConfig = [[NSMutableDictionary alloc]init];
        self.currentConfig = [[NSMutableDictionary alloc]init];
    }
    
    return self;
}

@end
