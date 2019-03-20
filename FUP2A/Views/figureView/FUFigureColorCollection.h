//
//  FUFigureColorCollection.h
//  FUP2A
//
//  Created by L on 2019/2/27.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUFigureDefine.h"

@class FUP2AColor ;
@protocol FUFigureColorCollectionDelegate <NSObject>

- (void)colorCollectionDidSelectedSkinColor:(FUP2AColor *)skinColor ;
- (void)colorCollectionDidSelectedLipsColor:(FUP2AColor *)lipsColor ;
- (void)colorCollectionDidSelectedIrisColor:(FUP2AColor *)irisColor ;
@end

@interface FUFigureColorCollection : UICollectionView

@property (nonatomic, assign) id<FUFigureColorCollectionDelegate>mDelegate ;

@property (nonatomic, assign) FUFigureColorType type ;

@property (nonatomic, strong) FUP2AColor *skinColor ;
@property (nonatomic, strong) NSArray *skinColorArray ;

@property (nonatomic, strong) FUP2AColor *lipsColor ;
@property (nonatomic, strong) NSArray *lipsColorArray ;

@property (nonatomic, strong) FUP2AColor *irisColor ;
@property (nonatomic, strong) NSArray *irisColorArray ;
@end


@interface FUFigureColorCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;
@end
