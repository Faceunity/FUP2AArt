//
//  FURequestManager.h
//  FUP2A
//
//  Created by L on 2018/7/30.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FUP2ADefine.h"

@interface FURequestManager : NSObject

+ (FURequestManager *)sharedInstance;

- (void)createQAvatarWithImage:(UIImage *)image Params:(NSDictionary *)params CompletionWithData:(void (^)(NSData *data, NSError *error))handle ;

@end
