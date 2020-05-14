//
//  FUEditTypeModel.h
//  FUP2A
//
//  Created by Chen on 2020/3/12.
//  Copyright © 2020 L. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUEditTypeModel : NSObject

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray *subTypeArray;

@end

NS_ASSUME_NONNULL_END
