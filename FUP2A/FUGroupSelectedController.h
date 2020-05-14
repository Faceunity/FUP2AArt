//
//  FUGroupSelectedController.h
//  FUP2A
//
//  Created by L on 2018/12/19.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FUSingleModel, FUMultipleModel, FUAvatar;
@interface FUGroupSelectedController : UIViewController

@property (nonatomic, assign) FUSceneryMode sceneryModel ;

@property (nonatomic, strong) FUSingleModel *singleModel ;

@property (nonatomic, strong) FUMultipleModel *multipleModel ;

@property (nonatomic, strong) FUSingleModel *animationModel ;

@property (nonatomic, strong) FUAvatar *currentAvatar ;
@end


@interface FUGroupSelectedCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *maskImage;
@end
