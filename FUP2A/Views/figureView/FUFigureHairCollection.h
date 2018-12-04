//
//  FUFigureHairCollection.h
//  EditView
//
//  Created by L on 2018/11/6.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FUFigureColor ;
@protocol FUFigureHairColorCollectionDelegate <NSObject>
@optional
- (void)didChangeHairColor:(NSInteger)colorIndex color:(FUFigureColor *)color;
@end

@interface FUFigureHairColorCollection : UICollectionView

@property (nonatomic, assign) id<FUFigureHairColorCollectionDelegate>mDelegate ;
@property (nonatomic, strong) NSArray *hairColorArray ;
@property (nonatomic, assign) NSInteger colorIndex ;
@end

@interface FUFigureHairColorCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;
@end



#import <UIKit/UIKit.h>
typedef enum : NSInteger {
    FUFigureHairMainCollectionTypeHair             = 0,
    FUFigureHairMainCollectionTypeBerad            = 1,
    FUFigureHairMainCollectionTypeCloth            = 2,
    FUFigureHairMainCollectionTypeHat              = 3,
} FUFigureHairMainCollectionType;

@protocol FUFigureHairMainCollectionDelegate <NSObject>
@optional
- (BOOL)didChangeHair:(NSString *)hairName;
- (void)didChangeBeard:(NSString *)beardName;
- (void)didChangeCloth:(NSString *)clothName;
- (BOOL)didChangeHat:(NSString *)hatName;
@end
@interface FUFigureHairMainCollection : UICollectionView

@property (nonatomic, assign) FUFigureHairMainCollectionType type ; ;
@property (nonatomic, assign) id<FUFigureHairMainCollectionDelegate>mDelegate ;
@property (nonatomic, strong) NSArray *hairArray ;
@property (nonatomic, copy) NSString *currentHair ;
@end

@interface FUFigureHairMainCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
