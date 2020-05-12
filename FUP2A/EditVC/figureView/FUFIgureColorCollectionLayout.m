//
//  FUFIgureColorCollectionLayout.m
//  FUP2A
//
//  Created by Chen on 2020/4/17.
//  Copyright © 2020 L. All rights reserved.
//

#import "FUFIgureColorCollectionLayout.h"

@interface FUFIgureColorCollectionLayout ()
@end

@implementation FUFIgureColorCollectionLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect{
        NSInteger colCount = [self.collectionView numberOfItemsInSection:0];
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    
    if (array.count > colCount)
    {
        array = [array subarrayWithRange:NSMakeRange(0, colCount)];
    }
    
    return array;
}

@end
