//
//  FUFigureHorizCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/17.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureHorizCollection.h"
#import "UIColor+FU.h"

@interface FUFigureHorizCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSInteger selectedIndex ;
}

@end

@implementation FUFigureHorizCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.dataSource = self ;
    self.delegate = self ;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];

}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation {
    if (selectedIndex >= 0 && selectedIndex < self.glassesArray.count) {
        [self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animation];
    }
}

- (void)loadCollectionData {
    
    selectedIndex = [self.glassesArray containsObject:self.glasses] ? [self.glassesArray indexOfObject:self.glasses] : 0 ;
    [self reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.glassesArray.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUFigureHorizCollectionCell *cell = (FUFigureHorizCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureHorizCollectionCell" forIndexPath:indexPath];
    UIImage *image = [UIImage imageNamed:self.glassesArray[indexPath.row]];
    cell.imageView.image = image ;
    
    cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
    cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
    
    return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == selectedIndex ) {
        return ;
    }
    selectedIndex = indexPath.row ;
    [collectionView reloadData];
    
    [self scrollCurrentToCenterWithAnimation:YES];
    
    if ([self.mDelegate respondsToSelector:@selector(didChangeGlasses:)]) {
        [self.mDelegate didChangeGlasses:self.glassesArray[indexPath.row]];
    }
}

-(void)FUAvatarEditedDoNotMethod:(NSNotification *)not{
	FUAvatarEditedDoModel * model = [not object];
	switch (model.type) {
		case Glasses:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * glassesName = model.obj;
			NSLog(@"glassesName------%@",glassesName);
			if ([glassesName isEqual:[NSNull null]]) {
				glassesName = @"glasses-noitem";
			}
			int index = [self.glassesArray indexOfObject:glassesName];
			selectedIndex = index;
			[self reloadData];
			[self scrollCurrentToCenterWithAnimation:YES];

			if ([self.mDelegate respondsToSelector:@selector(didChangeGlasses:)]) {
				[self.mDelegate didChangeGlasses:glassesName];
			}
		}
			break;
		default:
			break;
	}
}
@end


@implementation FUFigureHorizCollectionCell
- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.masksToBounds = YES ;
    self.layer.cornerRadius = 8.0 ;
}
@end
