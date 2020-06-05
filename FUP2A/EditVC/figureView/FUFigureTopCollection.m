//
//  FUFigureTopCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureTopCollection.h"

@interface FUFigureTopCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSInteger selectedIndex ;
}
@property (nonatomic, strong) NSArray *bgSubTypeNameArray;
@property (nonatomic, strong) NSArray *bgSubTypeKeyArray;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) NSArray * currentTypeArray;
@property (nonatomic, strong) FUFigureTopCell *oldSelectedCell;
@end

@implementation FUFigureTopCollection

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dataSource = self ;
    self.delegate = self ;
    [self registerNib:[UINib nibWithNibName:@"FUFigureTopCell" bundle:nil] forCellWithReuseIdentifier:@"FUFigureTopCell"];
}

- (void)reloadData
{
    
    self.currentTypeArray =  [[FUManager shareInstance] getCurrentTypeArray];
    [super reloadData];
    [self fixLayoutCrash];
}
/// 修复在 iphonex ，collection 不显示的情况下进行刷新，carsh的问题
-(void)fixLayoutCrash{
	UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
	UICollectionViewFlowLayout *oldLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
	layout.estimatedItemSize = oldLayout.estimatedItemSize;
	layout.footerReferenceSize = oldLayout.footerReferenceSize;
	layout.headerReferenceSize = oldLayout.headerReferenceSize;
	layout.itemSize = oldLayout.itemSize;
	layout.minimumInteritemSpacing = oldLayout.minimumInteritemSpacing;
	layout.minimumLineSpacing = oldLayout.minimumLineSpacing;
	layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	layout.sectionFootersPinToVisibleBounds = oldLayout.sectionFootersPinToVisibleBounds;
	layout.sectionHeadersPinToVisibleBounds = oldLayout.sectionHeadersPinToVisibleBounds;
	layout.sectionInset = oldLayout.sectionInset;
	[self.collectionViewLayout invalidateLayout];
	self.collectionViewLayout = layout;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.currentTypeArray.count;
}


- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	FUFigureTopCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureTopCell" forIndexPath:indexPath];
	cell.imageName = [[FUManager shareInstance]getSubTypeImageNameWithIndex:indexPath.row currentTypeArr:self.currentTypeArray];
	if (indexPath.row == [[FUManager shareInstance]getSubTypeSelectedIndex]) {
		cell.selectedCell = YES;
		self.oldSelectedCell = cell;
	}else{
	
		cell.selectedCell = NO;
	}
	return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == [[FUManager shareInstance] getSubTypeSelectedIndex])
	{
		if ([self.mDelegate respondsToSelector:@selector(topCollectionDidSelectedIndex:show:changeAnimation:)])
		{
			[self.mDelegate topCollectionDidSelectedIndex:indexPath.row show:NO changeAnimation:YES];
		}
		return ;
	}
    
	[[FUManager shareInstance]setSubTypeSelectedIndex:indexPath.row];
	FUFigureTopCell *cell = [self cellForItemAtIndexPath:indexPath];
	cell.selectedCell = YES;
    self.oldSelectedCell.selectedCell = NO;
    self.oldSelectedCell = cell;
	[self reloadCam];
	if ([self.mDelegate respondsToSelector:@selector(topCollectionDidSelectedIndex:show:changeAnimation:)])
	{
		[self.mDelegate topCollectionDidSelectedIndex:indexPath.row show:YES changeAnimation:YES];
	}

}

- (void)reloadCam
{
    FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
    if ([FUManager shareInstance].selectedEditType == FUEditTypeFace||[FUManager shareInstance].selectedEditType == FUEditTypeMakeup)
    {
        [avatar resetScaleToBody_UseCam];
    }
    else if ([FUManager shareInstance].selectedEditType == FUEditTypeDress)
    {
        NSString *subType = [[FUManager shareInstance]getSubTypeKeyWithIndex:[[FUManager shareInstance]getSubTypeSelectedIndex]];
        if ([subType isEqualToString:TAG_FU_ITEM_HAIRHAT]||[subType isEqualToString:TAG_FU_ITEM_GLASSES])
        {
            [avatar resetScaleToBody_UseCam];
        }
        else
        {
            [avatar resetScaleChange_UseCam];
        }
    }
}



@end

#pragma mark --- cell

@implementation FUFigureTopCell
-(void)setImageName:(NSString *)imageName{
    _imageName = imageName;
    self.imageView.image = [UIImage imageNamed:imageName];
}

-(void)setSelectedCell:(BOOL)selectedCell{
	_selectedCell = selectedCell;
	if (selectedCell) {
		self.imageView.image = [UIImage imageNamed:[self.imageName stringByAppendingString:@"_selected"]];
	}else{
		self.imageView.image = [UIImage imageNamed:self.imageName];
	}
}
@end

