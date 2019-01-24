//
//  FUFigureFaceCollection.h
//  FUP2A
//
//  Created by L on 2019/1/8.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUFigureDefine.h"

@class FUP2AColor ;
@protocol FUFigureFaceCollectionDelegate <NSObject>
- (void)faceCollectionDidSelectedSkinIndex:(NSInteger)skinIndex ;
- (void)faceCollectionShapeParamChangedWithType:(FigureShapeSelectedType)type ;
@end

@interface FUFigureFaceCollection : UICollectionView

@property (nonatomic, assign) id<FUFigureFaceCollectionDelegate>mDelegate ;

@property (nonatomic, assign) FUFigureFaceType currentType ;

@property (nonatomic, strong) FUP2AColor *currentSkinColor ;

@property (nonatomic, strong) NSMutableDictionary *selectedDic ;

@property (nonatomic, assign) FigureShapeSelectedType selectedType ;

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation ;
@end



@interface FUFigureFaceCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;
@end
