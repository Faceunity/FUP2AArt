//
//  FUGroupImageController.h
//  FUP2A
//
//  Created by L on 2018/12/19.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FUAvatar;
@interface FUGroupImageController : UIViewController

@property (nonatomic, strong) UIImage *image ;

@property (nonatomic, copy) NSString *gifPath ;

@property (nonatomic, strong) FUAvatar *currentAvatar ;
@end
