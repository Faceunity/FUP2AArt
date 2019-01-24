//
//  FUFigureDecorationHorizCollection.h
//  FUP2A
//
//  Created by L on 2019/1/9.
//  Copyright © 2019年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUFigureDecorationHorizCollectionDelegate <NSObject>
- (void)didChangeGlasses:(NSString *)glassesName ;
@end

@interface FUFigureDecorationHorizCollection : UICollectionView

@property (nonatomic, assign) id<FUFigureDecorationHorizCollectionDelegate>mDelegate ;

@property (nonatomic, copy) NSString *glassesName ;

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation ;
@end


@interface FUFigureDecorationHorizCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
