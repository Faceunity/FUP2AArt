//
//  FUFigureGlassCollection.h
//  EditView
//
//  Created by L on 2018/11/6.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum : NSInteger {
    FUFigureGlassesCollectionTypeFrame            = 0,
    FUFigureGlassesCollectionTypeGlass            = 1,
    FUFigureGlassesCollectionTypeBeard            = 2,
    FUFigureGlassesCollectionTypeHat              = 3,
} FUFigureGlassesCollectionType;

@class FUFigureColor ;
@protocol FUFigureGlassCollectionDelegate <NSObject>
@optional
- (void)didChangeGlassesColor:(NSInteger)colorIndex color:(FUFigureColor *)color;
- (void)didChangeGlassesFrameColor:(NSInteger)colorIndex color:(FUFigureColor *)color;
- (void)didChangeBearColor:(NSInteger)colorIndex color:(FUFigureColor *)color;
- (void)didChangeHatColor:(NSInteger)colorIndex color:(FUFigureColor *)color;
@end

@interface FUFigureGlassCollection : UICollectionView

@property (nonatomic, assign) FUFigureGlassesCollectionType type ;

@property (nonatomic, assign) id<FUFigureGlassCollectionDelegate>mDelegate ;

@property (nonatomic, strong) NSArray *glassesArray ;
@property (nonatomic, assign) NSInteger glassesColorIndex ;
@end


@interface FUFigureGlassCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage ;
@end
