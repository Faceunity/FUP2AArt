//
//  FUFigureGlassTypeCollection.h
//  EditView
//
//  Created by L on 2018/11/7.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FUFigureGlassTypeCollectionDelegate <NSObject>
@optional
- (void)didChangeGlasses:(NSString *)glassesName;
@end

@interface FUFigureGlassTypeCollection : UICollectionView

@property (nonatomic, assign) id<FUFigureGlassTypeCollectionDelegate>mDelegate ;
@property (nonatomic, strong) NSArray *glassesArray ;
@property (nonatomic, assign) NSInteger selectedIndex ;
@end
