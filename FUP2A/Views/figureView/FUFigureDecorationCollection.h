//
//  FUFigureDecorationCollection.h
//  FUP2A
//
//  Created by L on 2019/1/8.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUFigureDefine.h"

@protocol FUFigureDecorationCollectionDelegate <NSObject>
- (BOOL)decorationCollectionDidSelectedType:(FUFigureDecorationType)type itemName:(NSString *)itemName ;
@end

@interface FUFigureDecorationCollection : UICollectionView

@property (nonatomic, assign) FUFigureDecorationType currentType ;

@property (nonatomic, assign) id<FUFigureDecorationCollectionDelegate>mDelegate ;

@property (nonatomic, strong) NSString *hair ;
@property (nonatomic, strong) NSString *beard ;
@property (nonatomic, strong) NSString *eyeBrow ;
@property (nonatomic, strong) NSString *eyeLash ;
@property (nonatomic, strong) NSString *hat ;
@property (nonatomic, strong) NSString *clothes ;

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation ;
@end

@interface FUFigureDecorationCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
