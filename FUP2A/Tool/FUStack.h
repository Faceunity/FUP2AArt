//
//  FUStack.h
//  FUP2A
//
//  Created by LEE on 8/7/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUStack : NSObject
@property (nonatomic,strong)NSObject * top;
// Stack is empty when top is equal to nil
-(BOOL)isEmpty;
// Function to add an item to stack.  It increases top by 1
-(void)push:(NSObject *)object;
// Function to remove an item from stack.  It decreases top by 1
-(NSObject*)pop;
// Function to return the top from stack without removing it
-(NSObject*)peek;
// 字典模型数组里面是否包含某个键值
-(BOOL)exsit:(NSString *)key;
-(void)clear;
@end



@interface FUUndoStack : FUStack
@end
@interface FURedoStack : FUStack
@end
NS_ASSUME_NONNULL_END
