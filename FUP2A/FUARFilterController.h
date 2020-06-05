//
//  FUARFilterController.h
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUARFilterView.h"
@interface FUARFilterController : UIViewController
@property (nonatomic, strong) FUARFilterView *filterView ;
@property (nonatomic, assign) BOOL isShow;
@property (nonatomic, strong) void (^ touchBlock)(BOOL);
-(void)hideOrShowFilterView;
@end
