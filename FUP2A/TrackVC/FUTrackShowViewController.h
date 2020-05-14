//
//  FUTrackShowViewController.h
//  FUP2A
//
//  Created by Chen on 2020/4/8.
//  Copyright © 2020 L. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUTrackShowViewController : UIViewController
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) BOOL isLandscape;
@property (nonatomic, copy) NSString *strFileName;
@end

NS_ASSUME_NONNULL_END
