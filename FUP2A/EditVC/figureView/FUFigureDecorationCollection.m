//
//  FUFigureDecorationCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/10.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureDecorationCollection.h"
#import "UIColor+FU.h"
#import "FUItemModel.h"

@interface FUFigureDecorationCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *selectedDic ;
@end

@implementation FUFigureDecorationCollection

- (void)awakeFromNib
{
	[super awakeFromNib];
	[self registerNib:[UINib nibWithNibName:@"FUFigureDecorationCell" bundle:nil] forCellWithReuseIdentifier:@"FUFigureDecorationCell"];
	
	self.dataSource = self ;
	self.delegate = self ;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FUAvatarEditedDoNotMethod) name:FUAvatarEditedDoNot object:nil];
}

- (void)FUAvatarEditedDoNotMethod
{
    [self reloadData];
    [self scrollCurrentToCenterWithAnimation:YES];
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[FUManager shareInstance] getSelectedItemIndexOfSelectedType] inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [[FUManager shareInstance]getItemArrayOfSelectedType].count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	
	FUFigureDecorationCell *cell = (FUFigureDecorationCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureDecorationCell" forIndexPath:indexPath];
	NSArray * subViews = cell.subviews;
	for (UIView * subV in subViews) {
		if ([subV isKindOfClass:[UILabel class]] ) {
			[subV removeFromSuperview];
		}
	}

    FUItemModel *model = [[[FUManager shareInstance]getItemArrayOfSelectedType] objectAtIndex:indexPath.row];
    NSString *imagePath;
    
    if (model.path.length > 0)
    {
        imagePath = [NSString stringWithFormat:@"%@/%@",model.path,model.icon];
        UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
        cell.imageView.image = image;
    }
    else
    {
        imagePath = model.icon;
        UIImage * image = [UIImage imageNamed:imagePath];
        cell.imageView.image = image;
    }

    
	NSInteger selectedIndex = [[FUManager shareInstance] getSelectedItemIndexOfSelectedType];
	cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
	cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
	
	return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FUItemModel *model = [[[FUManager shareInstance]getItemArrayOfSelectedType] objectAtIndex:indexPath.row];
    
    [[FUManager shareInstance] bindItemWithModel:model];
    
    [self reloadData];
    [self scrollCurrentToCenterWithAnimation:YES];
}

-(void)dealloc
{
	NSLog(@"FUFigureDecorationCollection销毁了----------");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation FUFigureDecorationCell

- (void)awakeFromNib
{
	[super awakeFromNib];
	self.layer.masksToBounds = YES ;
	self.layer.cornerRadius = 8.0 ;
}

@end
