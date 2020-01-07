//
//  FUStack.m
//  FUP2A
//
//  Created by LEE on 8/7/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUStack.h"
@interface FUStack()
@property (nonatomic,strong)NSMutableArray * container;

@end
@implementation FUStack
-(instancetype)init{
	if (self = [super init]) {
		self.container = [NSMutableArray array];
	}
	return self;
}
// Stack is empty when top is equal to nil
-(BOOL)isEmpty
{
    return self.top == nil;
}
// Function to add an item to stack.  It increases top by 1
-(void)push:(NSObject *)object{
	self.top = object;
    [self.container addObject:object];
}
// Function to remove an item from stack.  It decreases top by 1
-(NSObject*)pop{
	NSObject * last = [self.container lastObject];
	[self.container removeLastObject];
	self.top = [self.container lastObject];

	return last;
}
// Function to return the top from stack without removing it
-(NSObject*)peek{
	NSObject * last = [self.container lastObject];
	return last;
}
-(void)clear{
   [self.container removeAllObjects];
   self.top = nil;
}
-(BOOL)exsit:(NSString *)key{
	for (NSDictionary * config in self.container) {
		if (config[key] != nil) {
			return YES;
		}
	}
	return NO;
}
//-(NSString *)description{
//	NSMutableString * string = [NSMutableString string];
//	for (NSDictionary * obj in self.container) {
//		for (NSString * key in obj) {
//			id value = obj[key];
//			[string stringByAppendingString:[NSString stringWithFormat:@"%@:%@",key,value]];
//		}
//		[string stringByAppendingString:@"---------------------------------------"];
//	}
//	return string;
//}

@end


@implementation FUUndoStack
- (BOOL)isEmpty{
	return self.container.count >= 1;
}
@end
@implementation FURedoStack

@end
