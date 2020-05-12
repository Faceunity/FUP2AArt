//
//  FUFigureHorizCollection.h
//  FUFigureView
//
//  Created by L on 2019/4/17.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUFigureCollectionDelegate <NSObject>

@optional
- (void)didChangeGlassesWithHiddenColorViews:(BOOL)hidden;
@end

@interface FUFigureHorizCollection : UICollectionView

@property (nonatomic, copy) NSString *glasses ;
@property (nonatomic, strong) NSArray *glassesArray ;

@property (nonatomic, assign) id<FUFigureCollectionDelegate>mDelegate ;

- (void)loadCollectionData ;
- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation;
@end


@interface FUFigureHorizCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
