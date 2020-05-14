//
//  FUFigureColorCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/16.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureColorCollection.h"
#import "FUFIgureColorCollectionLayout.h"

@interface FUFigureColorCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *selectedDic ;
@property (nonatomic, strong) NSArray *arrayColor;
@end    

@implementation FUFigureColorCollection

- (void)awakeFromNib
{
	[super awakeFromNib];
    [self registerNib:[UINib nibWithNibName:@"FUFigureColorCollectionCell" bundle:nil] forCellWithReuseIdentifier:@"FUFigureColorCollectionCell"];
	self.dataSource = self ;
	self.delegate = self ;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod:) name:FUAvatarEditedDoNot object:nil];
    
    FUFIgureColorCollectionLayout *layout = [[FUFIgureColorCollectionLayout alloc]init];
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

  
    self.collectionViewLayout = layout;
	
}

-(void)setCurrentType:(FUFigureColorType)currentType
{
	_currentType = currentType;
    self.arrayColor = [[FUManager shareInstance]getColorArrayWithType:self.currentType];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
        [self scrollCurrentToCenterWithAnimation:NO];
    });
    
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation
{
    
    NSInteger index = MIN([[FUManager shareInstance] getSelectedColorIndexWithType:self.currentType],  [self numberOfItemsInSection:0]);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.arrayColor.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.arrayColor.count)
    {
        return (FUFigureColorCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureColorCollectionCell" forIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    
	FUFigureColorCollectionCell *cell = (FUFigureColorCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureColorCollectionCell" forIndexPath:indexPath];
	FUP2AColor *color = self.arrayColor[indexPath.row];
	cell.backgroundColor = color.color;
	
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
