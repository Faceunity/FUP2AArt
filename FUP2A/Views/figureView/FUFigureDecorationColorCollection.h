//
//  FUFigureDecorationColorCollection.h
//  FUP2A
//
//  Created by L on 2019/1/8.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUFigureDefine.h"

@class FUP2AColor ;
@protocol FUFigureDecorationColorCollectionDelegate <NSObject>
- (void)decorationColorCollectionDidChangeColor:(FUP2AColor *)color colorType:(FUFigureDecorationType)type ;
@end

@interface FUFigureDecorationColorCollection : UICollectionView

@property (nonatomic, assign) FUFigureDecorationType currentType ;

@property (nonatomic, assign) id<FUFigureDecorationColorCollectionDelegate>mDelegate ;

@property (nonatomic, strong) FUP2AColor *hairColor ;
@property (nonatomic, strong) FUP2AColor *beardColor ;
@property (nonatomic, strong) FUP2AColor *hatColor ;
@property (nonatomic, strong) FUP2AColor *irisColor ;
@property (nonatomic, strong) FUP2AColor *lipsColor ;
@property (nonatomic, strong) FUP2AColor *glassesFrameColor ;
@property (nonatomic, strong) FUP2AColor *glassesColor ;

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation ;
@end

@interface FUFigureDecorationColorCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage ;
@end
