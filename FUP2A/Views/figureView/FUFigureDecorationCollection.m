//
//  FUFigureDecorationCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/10.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureDecorationCollection.h"
#import "UIColor+FU.h"

@interface FUFigureDecorationCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *selectedDic ;
@end

@implementation FUFigureDecorationCollection

- (void)awakeFromNib {
	[super awakeFromNib];
	
	self.dataSource = self ;
	self.delegate = self ;
}

-(void)setCurrentType:(FUFigureDecorationCollectionType)currentType {
	_currentType = currentType ;
	[self reloadData];
	
	[self scrollCurrentToCenterWithAnimation:NO];
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation {
	if ([self.selectedDic.allKeys containsObject:@(self.currentType)]) {
		NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
		if (selectedIndex >= 0) {
			[self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animation];
		}
	}
}

- (void)loadDecorationData {
	
	self.selectedDic = [NSMutableDictionary dictionaryWithCapacity:1];
	
	NSMutableArray *dataArray = [NSMutableArray arrayWithCapacity:1];
	NSMutableArray *selectedArray = [NSMutableArray arrayWithCapacity:1];
	
	NSArray *propertiesName = @[@"hairArray", @"faceArray", @"eyesArray", @"mouthArray", @"noseArray", @"beardArray", @"eyeBrowArray", @"eyeLashArray", @"hatArray", @"clothesArray", @"shoesArray"];
	for (NSString *name  in propertiesName) {
		NSArray *array = [self valueForKey:name];
		if (array) {
			[dataArray addObject:array];
			NSString *propertyName = [name substringToIndex:name.length - 5];
			NSString *item = [self valueForKey:propertyName];
			if (!item) {
				item = array[0] ;
			}
			[selectedArray addObject:item];
		}
	}
	
	for (int i = 0 ; i < dataArray.count; i ++) {
		NSArray *array = [dataArray objectAtIndex:i] ;
		NSString *name = [selectedArray objectAtIndex:i];
		
		NSInteger index = -1 ;
		if ([array containsObject:name]) {
			index = [array indexOfObject:name];
		}
		
		[self.selectedDic setObject:@(index) forKey:@(i)];
		
		if (self.currentType == (FUFigureDecorationCollectionType)i) {
			[self reloadData];
		}
	}
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return [self getCurrentDataArray].count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	FUFigureDecorationCell *cell = (FUFigureDecorationCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureDecorationCell" forIndexPath:indexPath];
	NSArray * subViews = cell.subviews;
	for (UIView * subV in subViews) {
		if ([subV isKindOfClass:[UILabel class]] ) {
			[subV removeFromSuperview];
		}
	}
	NSArray *dataArray = [self getCurrentDataArray];
	NSString *name = dataArray[indexPath.row] ;
	UIImage * image = [UIImage imageNamed:name];
	cell.imageView.image = image;
	
	NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue] ;
	cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
	cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
	
	return cell ;
}

-(void)recoverCollectionViewUI{
  [self setValue:nil forKey:@"face"];
  [self setValue:nil forKey:@"eyes"];
  [self setValue:nil forKey:@"mouth"];
  [self setValue:nil forKey:@"nose"];

}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue] ;
	
	if (selectedIndex == indexPath.row
		&& indexPath.row != 0
		&& (self.currentType == 0 || self.currentType > 4)) {
		
		return ;
	}
	
	[self.selectedDic setObject:@(indexPath.row) forKey:@(self.currentType)];
	[self reloadData];
	
	NSString *itemName = [[self getCurrentDataArray] objectAtIndex:indexPath.row];
	if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
		[self.mDelegate decorationCollectionDidSelectedItem:itemName index:indexPath.row decorationType:self.currentType];
	}
	
	[self scrollCurrentToCenterWithAnimation:YES];
}

- (NSArray *)getCurrentDataArray {
	
	NSArray *array ;
	switch (_currentType) {
		case FUFigureDecorationCollectionTypeHair:
			array = self.hairArray  ;
			break;
		case FUFigureDecorationCollectionTypeFace:
			array = self.faceArray  ;
			break;
		case FUFigureDecorationCollectionTypeEyes:
			array = self.eyesArray  ;
			break;
		case FUFigureDecorationCollectionTypeMouth:
			array = self.mouthArray  ;
			break;
		case FUFigureDecorationCollectionTypeNose:
			array = self.noseArray  ;
			break;
		case FUFigureDecorationCollectionTypeBeard:
			array = self.beardArray  ;
			break;
		case FUFigureDecorationCollectionTypeEyeBrow:
			array = self.eyeBrowArray  ;
			break;
		case FUFigureDecorationCollectionTypeEyeLash:
			array = self.eyeLashArray  ;
			break;
		case FUFigureDecorationCollectionTypeHat:
			array = self.hatArray  ;
			break;
		case FUFigureDecorationCollectionTypeClothes:
			array = self.clothesArray  ;
			break;
		case FUFigureDecorationCollectionTypeShoes:
			array = self.shoesArray  ;
			break;
	}
	return array ;
}


@end

@implementation FUFigureDecorationCell
- (void)awakeFromNib {
	[super awakeFromNib];
	self.layer.masksToBounds = YES ;
	self.layer.cornerRadius = 8.0 ;
}
@end
