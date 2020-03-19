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

- (void)awakeFromNib
{
	[super awakeFromNib];
    [self registerNib:[UINib nibWithNibName:@"FUFigureColorCollectionCell" bundle:nil] forCellWithReuseIdentifier:@"FUFigureColorCollectionCell"];

	self.dataSource = self ;
	self.delegate = self ;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];
	
}

-(void)setCurrentType:(FUFigureColorType)currentType
{
	_currentType = currentType ;
	[self reloadData];
    
    [self scrollCurrentToCenterWithAnimation:NO];
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[FUManager shareInstance] getSelectedColorIndexWithType:self.currentType] inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = [[FUManager shareInstance]getColorArrayCountWithType:self.currentType];
    
    return count;
//	switch (_currentType)
//    {
//		case FUFigureColorTypeSkinColor:
//		case FUFigureColorTypeirisColor:
//		case FUFigureColorTypeLipsColor:
//			return count - 1 ;
//			break ;
//		default:
//			return count ;
//			break ;
//	}
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	
	FUFigureColorCollectionCell *cell = (FUFigureColorCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureColorCollectionCell" forIndexPath:indexPath];
//	NSInteger selectedIndex = [[self.selectedDic objectForKey:@(self.currentType)] integerValue] ;
//	switch (_currentType) {
//		case FUFigureColorTypeGlassesColor:
//			selectedIndex = self.glassColorIndex;
//			break ;
//		case FUFigureColorTypeGlassesFrameColor:
//			selectedIndex = self.glassFrameColorIndex;
//			break;
//		default:
//			break ;
//	}
	FUP2AColor *color = [[FUManager shareInstance]getColorWithType:self.currentType andIndex:indexPath.row];
	cell.backgroundColor = color.color ;
	
	cell.selectedImage.hidden = [[FUManager shareInstance]getSelectedColorIndexWithType:self.currentType] != indexPath.row ;
	return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FUP2AColor *newColor = [[FUManager shareInstance]getColorWithType:self.currentType andIndex:indexPath.row];
    
    [[FUManager shareInstance]configColorWithColor:newColor ofType:self.currentType];
    
    [self reloadData];
	[self scrollCurrentToCenterWithAnimation:YES];
}

- (void)FUAvatarEditedDoNotMethod:(NSNotification *)not
{
    
    [self reloadData];
    [self scrollCurrentToCenterWithAnimation:YES];
    
}

// ==============================================根据指定名称滚动到相应图标==================================
//- (void)FUAvatarEditedDoNotMethod:(NSNotification *)not{
//	FUAvatarEditedDoModel * model = [not object];
//	switch (model.type) {
//		case HairColor:
//		{
//			int index = [(NSNumber*)model.obj intValue];
//			[self.selectedDic setObject:@(index) forKey:@(FUFigureColorTypeHairColor)];
//			FUP2AColor *color = [self.hairColorArray objectAtIndex:index];
//			if (color == nil) {
//				return;
//			}
//			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
//				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeHairColor];
//			}
//			if (self.currentType == FUFigureColorTypeHairColor){
//				[self reloadData];
//			}
//		}
//			break;
//		case IrisLevel:
//		{
//			int index = [(NSNumber*)model.obj intValue];
//			[self.selectedDic setObject:@(index) forKey:@(FUFigureColorTypeirisColor)];
//			FUP2AColor *color = [self.irisColorArray objectAtIndex:index];
//			if (color == nil) {
//				return;
//			}
//			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
//				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeirisColor];
//			}
//			if (self.currentType == FUFigureColorTypeirisColor){
//				[self reloadData];
//			}
//		}
//			break;
//		case LipsLevel:
//		{
//			int index = [(NSNumber*)model.obj intValue];
//			[self.selectedDic setObject:@(index) forKey:@(FUFigureColorTypeLipsColor)];
//			FUP2AColor *color = [self.lipsColorArray objectAtIndex:index];
//			if (color == nil) {
//				return;
//			}
//			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
//				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeLipsColor];
//			}
//			if (self.currentType == FUFigureColorTypeLipsColor){
//				[self reloadData];
//			}
//		}
//			break;
//		case GlassColorIndex:
//		{
//			int index = [(NSNumber*)model.obj intValue];
//			self.glassColorIndex = index;
//			FUP2AColor *color = [self.glassesColorArray objectAtIndex:index];
//			if (color == nil) {
//				return;
//			}
//			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
//				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeGlassesColor];
//			}
//			if (self.currentType == FUFigureColorTypeGlassesColor){
//				[self reloadData];
//			}
//		}
//			break;
//		case GlassFrameColorIndex:
//		{
//			int index = [(NSNumber*)model.obj intValue];
//			 self.glassFrameColorIndex = index;
//			FUP2AColor *color = [self.glassesFrameColorArray objectAtIndex:index];
//			if (color == nil) {
//				return;
//			}
//			if ([self.mDelegate respondsToSelector:@selector(didSelectedColor:index:tyep:)]) {
//				[self.mDelegate didSelectedColor:color index:index tyep:FUFigureColorTypeGlassesFrameColor];
//			}
//			if (self.currentType == FUFigureColorTypeGlassesFrameColor){
//				[self reloadData];
//			}
//		}
//			break;
//
//
//		default:
//			break;
//	}
//}

- (void)dealloc
{
	NSLog(@"FUFigureDecorationCollection销毁了----------");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


@implementation FUFigureColorCollectionCell

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.layer.masksToBounds = YES ;
	self.layer.cornerRadius = self.frame.size.width / 2.0 ;
}

@end
