//
//  FUGifManager.h
//  FUP2A
//
//  Created by L on 2018/12/24.
//  Copyright © 2018年 L. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FUGifManager : NSObject

+ (void)createGIFFromVideoWithPath:(NSString *)videoPath completion:(void(^)(NSString *gifPath))handle ;
@end
