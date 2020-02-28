//
//  FUFigureDecorationCollection.h
//  FUFigureView
//
//  Created by L on 2019/4/10.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "FUFigureDefine.h"

@interface FUFigureDecorationCollection : UICollectionView

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation;

@end

@interface FUFigureDecorationCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
