//
//  FUFigureColorCollection.h
//  FUFigureView
//
//  Created by L on 2019/4/16.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUFigureDefine.h"


@class FUP2AColor ;
@protocol FUFigureColorCollectionDelegate <NSObject>
- (void)didSelectedColor:(FUP2AColor *)currentColor index:(NSInteger)index tyep:(FUFigureColorType)type ;
@optional
@end

@interface FUFigureColorCollection : UICollectionView


@property (nonatomic, assign) FUFigureColorType currentType ;
@property (nonatomic, assign) id<FUFigureColorCollectionDelegate>mDelegate ;

// output data
@property (nonatomic, strong) FUP2AColor *hairColor ;
@property (nonatomic, strong) FUP2AColor *skinColor ;
@property (nonatomic, strong) FUP2AColor *irisColor ;
@property (nonatomic, strong) FUP2AColor *lipsColor ;
@property (nonatomic, strong) FUP2AColor *beardColor ;
@property (nonatomic, strong) FUP2AColor *hatColor ;

@property (nonatomic, strong) FUP2AColor *glassesFrameColor ;
@property (nonatomic, strong) FUP2AColor *glassesColor ;

// dataSource

@property (nonatomic, strong) NSArray <FUP2AColor *>*hairColorArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*skinColorArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*irisColorArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*lipsColorArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*beardColorArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*hatColorArray ;

@property (nonatomic, strong) NSArray <FUP2AColor *>*glassesColorArray ;
@property (nonatomic, strong) NSArray <FUP2AColor *>*glassesFrameColorArray ;

- (void)loadColorData ;
@end

@interface FUFigureColorCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;
@end
