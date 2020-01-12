//
//  FUFigureColorCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/16.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureColorCollection.h"
#import "FUP2AColor.h"

@interface FUFigureColorCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *selectedDic ;
@end

@implementation FUFigureColorCollection

- (void)awakeFromNib {
	[super awakeFromNib];
		   [self registerNib:[UINib nibWithNibName:@"FUFigureColorCollectionCell" bundle:nil] forCellWithReuseIdentifier:@"FUFigureColorCollectionCell"];

	self.dataSource = self ;
	self.delegate = self ;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];
	
}

-(void)setCurrentType:(FUFigureColorType)currentType {
	_currentType = currentType ;
	[self reloadData];
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation {
	if ([self.selectedDic.allKeys containsObject:@(self.currentType)]) {
		NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue];
		[self scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animation];
	}
}

- (void)loadColorData {
	
	self.selectedDic = [NSMutableDictionary dictionaryWithCapacity:1];
	
	NSMutableArray *dataArray = [NSMutableArray arrayWithCapacity:1];
	NSMutableArray *selectedArray = [NSMutableArray arrayWithCapacity:1];
	
	NSArray *propertiesName = @[@"hairColorArray", @"skinColorArray", @"irisColorArray", @"lipsColorArray", @"beardColorArray", @"hatColorArray", @"glassesColorArray", @"glassesFrameColorArray"];
	for (NSString *name in propertiesName) {
		NSArray *array = [self valueForKey:name];
		if (array) {
			[dataArray addObject:array];
			NSString *propertyName = [name substringToIndex:name.length - 5];
			FUP2AColor *color = (FUP2AColor *)[self valueForKey:propertyName];
			if (!color) {
				color = dataArray[0] ;
			}
			[selectedArray addObject:color];
		}
	}
	
	for (int i = 0 ; i < dataArray.count; i ++) {
		NSArray *array = [dataArray objectAtIndex:i] ;
		NSString *name = [selectedArray objectAtIndex:i];
		
		NSInteger index = 0 ;
		if ([array containsObject:name]) {
			index = [array indexOfObject:name];
		}
		
		[self.selectedDic setObject:@(index) forKey:@(i)];
		
		if (self.currentType == (FUFigureColorType)i) {
			[self reloadData];
		}
	}
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	NSArray *array = [self getCurrentDataArray];
	switch (_currentType) {
		case FUFigureColorTypeSkinColor:
		case FUFigureColorTypeirisColor:
		case FUFigureColorTypeLipsColor:
			return array.count - 1 ;
			break ;
		default:
			return array.count ;
			break ;
	}
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	FUFigureColorCollectionCell *cell = (FUFigureColorCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureColorCollectionCell" forIndexPath:indexPath];
	NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue] ;
	switch (_currentType) {
		case FUFigureColorTypeGlassesColor:
			selectedIndex = self.glassColorIndex;
			break ;
		case FUFigureColorTypeGlassesFrameColor:
			selectedIndex = self.glassFrameColorIndex;
			break;
		default:
			break ;
	}
	FUP2AColor *color = [[self getCurrentDataArray] objectAtIndex:indexPath.row];
	cell.backgroundColor = color.color ;
	
	
	cell.selectedImage.hidden = selectedIndex != indexPath.row ;
	return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue] ;
	
	if (selectedIndex == indexPath.row) {
		return ;
	}
	
	[self.selectedDic setObject:@(indexPath.row) forKey:@(self.currentType)];
	[self reloadData];
	
	NSArray *dataArray = [self getCurrentDataArray];
	FUP2AColor *color = [dataArray objectAtIndex:indexPath.row];
	switch (_currentType) {
		case FUFigureColorTypeGlassesColor:
			self.glassColorIndex = indexPath.row;
			break ;
		case FUFigureColorTypeGlassesFrameColor:
			self.glassFrameColorIndex = indexPath.row;
			break;
		default:
			break ;
	}
	if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
		[self.mDelegate didSelectedColor:color index:indexPath.row tyep:self.currentType];
	}
	
	[self scrollCurrentToCenterWithAnimation:YES];
}

- (NSArray *)getCurrentDataArray {
	
	NSArray *array ;
	switch (_currentType) {
		case FUFigureColorTypeHairColor:
			array = self.hairColorArray  ;
			break;
		case FUFigureColorTypeSkinColor:
			array = self.skinColorArray  ;
			break;
		case FUFigureColorTypeirisColor:
			array = self.irisColorArray  ;
			break;
		case FUFigureColorTypeLipsColor:
			array = self.lipsColorArray  ;
			break;
		case FUFigureColorTypeBeardColor:
			array = self.beardColorArray  ;
			break;
		case FUFigureColorTypeHatColor:
			array = self.hatColorArray  ;
			break;
		case FUFigureColorTypeGlassesColor:
			array = self.glassesColorArray  ;
			break;
		case FUFigureColorTypeGlassesFrameColor:
			array = self.glassesFrameColorArray  ;
			break;
	}
	return array ;
}
// ==============================================根据指定名称滚动到相应图标==================================
-(void)FUAvatarEditedDoNotMethod:(NSNotification *)not{
	FUAvatarEditedDoModel * model = [not object];
	switch (model.type) {
		case HairColor:
		{
			int index = [(NSNumber*)model.obj intValue];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureColorTypeHairColor)];
			FUP2AColor *color = [self.hairColorArray objectAtIndex:index];
			if (color == nil) {
				return;
			}
			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeHairColor];
			}
			if (self.currentType == FUFigureColorTypeHairColor){
				[self reloadData];
			}
		}
			break;
		case IrisLevel:
		{
			int index = [(NSNumber*)model.obj intValue];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureColorTypeirisColor)];
			FUP2AColor *color = [self.irisColorArray objectAtIndex:index];
			if (color == nil) {
				return;
			}
			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeirisColor];
			}
			if (self.currentType == FUFigureColorTypeirisColor){
				[self reloadData];
			}
		}
			break;
		case LipsLevel:
		{
			int index = [(NSNumber*)model.obj intValue];
			[self.selectedDic setObject:@(index) forKey:@(FUFigureColorTypeLipsColor)];
			FUP2AColor *color = [self.lipsColorArray objectAtIndex:index];
			if (color == nil) {
				return;
			}
			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeLipsColor];
			}
			if (self.currentType == FUFigureColorTypeLipsColor){
				[self reloadData];
			}
		}
			break;
		case GlassColorIndex:
		{
			int index = [(NSNumber*)model.obj intValue];
			self.glassColorIndex = index;
			FUP2AColor *color = [self.glassesColorArray objectAtIndex:index];
			if (color == nil) {
				return;
			}
			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeGlassesColor];
			}
			if (self.currentType == FUFigureColorTypeGlassesColor){
				[self reloadData];
			}
		}
			break;
		case GlassFrameColorIndex:
		{
			int index = [(NSNumber*)model.obj intValue];
			 self.glassFrameColorIndex = index;
			FUP2AColor *color = [self.glassesFrameColorArray objectAtIndex:index];
			if (color == nil) {
				return;
			}
			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeGlassesFrameColor];
			}
			if (self.currentType == FUFigureColorTypeGlassesFrameColor){
				[self reloadData];
			}
		}
			break;
			
			
		default:
			break;
	}
}

-(void)dealloc{
	NSLog(@"FUFigureDecorationCollection销毁了----------");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


@implementation FUFigureColorCollectionCell
- (void)awakeFromNib {
	[super awakeFromNib];
	self.layer.masksToBounds = YES ;
	self.layer.cornerRadius = self.frame.size.width / 2.0 ;
}
@end
