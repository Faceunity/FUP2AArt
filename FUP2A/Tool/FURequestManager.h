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
typedef void(^FURequestResultDicBlock)(BOOL createAvatarSuccess ,NSDictionary *resultDic, NSError *error);   /*createAvatarSuccess 当前avatar有没有生成成功 */
@interface FURequestManager : NSObject

+ (FURequestManager *)sharedInstance;

@property (nonatomic, copy) NSString *servicerString ;

@property (nonatomic, copy) NSString *serverShortString ;

- (void)createQAvatarWithImage:(UIImage *)image Params:(NSDictionary *)params CompletionWithData:(FURequestResultDicBlock)handle ;
@end
