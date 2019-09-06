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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];
	
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
// ==============================================根据指定名称滚动到相应图标==================================
-(void)FUAvatarEditedDoNotMethod:(NSNotification *)not{
	FUAvatarEditedDoModel * model = [not object];
	switch (model.type) {
		case Hair:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * hairName = model.obj;
			int index = [self.hairArray indexOfObject:hairName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeHair)];
			if (self.currentType == FUFigureDecorationCollectionTypeHair){
				[self reloadData];
			}
			
			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:hairName index:index decorationType:FUFigureDecorationCollectionTypeHair];
			}
		}
			break;
		case Face:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * faceName = model.obj;
			NSLog(@"faceName------%@",faceName);
			if ([faceName isEqual:[NSNull null]]) {
			faceName = @"捏脸";
			}
			int index = [self.faceArray indexOfObject:faceName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeFace)];
			if (self.currentType == FUFigureDecorationCollectionTypeFace){
				[self reloadData];
			}
				if (![faceName isEqual:[NSNull null]]  && ![faceName isEqualToString:@"捏脸"]) {

			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:faceName index:index decorationType:FUFigureDecorationCollectionTypeFace];
			}
			}
		}
			break;
					case Eyes:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * eyesName = model.obj;
			NSLog(@"eyesName------%@",eyesName);
			if ([eyesName isEqual:[NSNull null]]) {
			eyesName = @"捏脸";
			}
			int index = [self.eyesArray indexOfObject:eyesName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeEyes)];
			if (self.currentType == FUFigureDecorationCollectionTypeEyes){
				[self reloadData];
			}
			if (![eyesName isEqual:[NSNull null]] && ![eyesName isEqualToString:@"捏脸"]) {
			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:eyesName index:index decorationType:FUFigureDecorationCollectionTypeEyes];
			}
			}
		}
			break;
								case Mouth:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * mouthName = model.obj;
			NSLog(@"mouthName------%@",mouthName);
			if ([mouthName isEqual:[NSNull null]]) {
			mouthName = @"捏脸";
			}
			int index = [self.mouthArray indexOfObject:mouthName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeMouth)];
			if (self.currentType == FUFigureDecorationCollectionTypeMouth){
				[self reloadData];
			}
			if (![mouthName isEqual:[NSNull null]]  && ![mouthName isEqualToString:@"捏脸"]) {
			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:mouthName index:index decorationType:FUFigureDecorationCollectionTypeMouth];
			}
			}
		}
			break;
			
											case Nose:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * noseName = model.obj;
			NSLog(@"noseName------%@",noseName);
			if ([noseName isEqual:[NSNull null]]) {
			noseName = @"捏脸";
			}
			int index = [self.noseArray indexOfObject:noseName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeNose)];
			if (self.currentType == FUFigureDecorationCollectionTypeNose){
				[self reloadData];
			}
			if (![noseName isEqual:[NSNull null]]  && ![noseName isEqualToString:@"捏脸"]) {
			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:noseName index:index decorationType:FUFigureDecorationCollectionTypeNose];
			}
			}
		}
			break;
			
														case Beard:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * beardName = model.obj;
			NSLog(@"beardName------%@",beardName);
			if ([beardName isEqual:[NSNull null]]) {
			beardName = @"beard0";
			}
			int index = [self.beardArray indexOfObject:beardName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeBeard)];
			if (self.currentType == FUFigureDecorationCollectionTypeBeard){
				[self reloadData];
			}
			if (![beardName isEqual:[NSNull null]]) {
			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:beardName index:index decorationType:FUFigureDecorationCollectionTypeBeard];
			}
			}
		}
			break;
		case Hat:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * hatName = model.obj;
			NSLog(@"hatName------%@",hatName);
			if ([hatName isEqual:[NSNull null]]) {
			hatName = @"hat-noitem";
			}
			int index = [self.hatArray indexOfObject:hatName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeHat)];
			if (self.currentType == FUFigureDecorationCollectionTypeHat){
				[self reloadData];
			}
			if (![hatName isEqual:[NSNull null]]) {
			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:hatName index:index decorationType:FUFigureDecorationCollectionTypeHat];
			}
			}
		}
			break;
					case Clothes:
		{
			//	[self scrollToTheHair:model.obj];
			NSString * clothesName = model.obj;
			NSLog(@"clothesName------%@",clothesName);
			int index = [self.clothesArray indexOfObject:clothesName];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeClothes)];
			if (self.currentType == FUFigureDecorationCollectionTypeClothes){
				[self reloadData];
			}
			if (![clothesName isEqual:[NSNull null]]) {
			if ([self.mDelegate respondsToSelector:@selector(decorationCollectionDidSelectedItem:index:decorationType:)]) {
				[self.mDelegate decorationCollectionDidSelectedItem:clothesName index:index decorationType:FUFigureDecorationCollectionTypeClothes];
			}
			}
		}
			break;

		default:
			break;
	}
}
-(void)scrollToTheHair:(NSString*)hair{
	NSUInteger index = [self.hairArray indexOfObject:hair];
	[self.selectedDic setObject:@(index) forKey:@(FUFigureDecorationCollectionTypeHair)];
	[self reloadData];
}
-(void)dealloc{
	NSLog(@"FUFigureDecorationCollection销毁了----------");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

@implementation FUFigureDecorationCell
- (void)awakeFromNib {
	[super awakeFromNib];
	self.layer.masksToBounds = YES ;
	self.layer.cornerRadius = 8.0 ;
}
@end
