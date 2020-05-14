//
//  FUTextTrackController.h
//  FUP2A
//
//  Created by LEE on 10/10/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUTextTrackView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FUTextTrackController : UIViewController
@property (nonatomic, strong)FUTextTrackView  *textTrackView ;
@property (nonatomic, assign) BOOL isShow;
@property (nonatomic, strong) void (^ backBlock)(void);
@property (nonatomic, strong) void (^ touchBlock)(void);
- (IBAction)backAction:(id)sender;
@end

NS_ASSUME_NONNULL_END
