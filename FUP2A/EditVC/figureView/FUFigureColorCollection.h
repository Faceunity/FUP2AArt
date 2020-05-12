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

@interface FUFigureColorCollection : UICollectionView

@property (nonatomic, assign) FUFigureColorType currentType ;

@end

@interface FUFigureColorCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;
@end
