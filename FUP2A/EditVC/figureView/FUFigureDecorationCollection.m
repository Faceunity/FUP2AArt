//
//  FUFigureDecorationCollection.m
//  FUFigureView
//
//  Created by L on 2019/4/10.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUFigureDecorationCollection.h"

@interface FUFigureDecorationCollection ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) NSMutableDictionary *selectedDic ;
@property (nonatomic, strong) NSArray *arrayDecoration;
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
}

- (void)reloadData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [super reloadData];
        [self scrollCurrentToCenterWithAnimation:NO];
    });
}

- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[FUManager shareInstance] getSelectedItemIndexOfSelectedSubType] inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    self.arrayDecoration = [[FUManager shareInstance]getItemArrayOfSelectedSubType];
	return self.arrayDecoration.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	
	FUFigureDecorationCell *cell = (FUFigureDecorationCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"FUFigureDecorationCell" forIndexPath:indexPath];

    FUItemModel *model = [self.arrayDecoration objectAtIndex:indexPath.row];
    NSString *imagePath;
    
    if (model.path.length > 0)
    {
        imagePath = [model getIconPath];
        UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
        cell.imageView.image = image;
    }
    else
    {
        imagePath = model.icon;
        UIImage * image = [UIImage imageNamed:imagePath];
        cell.imageView.image = image;
    }

    
	NSInteger selectedIndex = [[FUManager shareInstance] getSelectedItemIndexOfSelectedSubType];
	cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
	cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
	
	return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    FUItemModel *model = [[[FUManager shareInstance]getItemArrayOfSelectedSubType] objectAtIndex:indexPath.row];
    
    if (([model.type isEqualToString:TAG_FU_ITEM_CLOTH]||[model.type isEqualToString:TAG_FU_ITEM_UPPER]||[model.type isEqualToString:TAG_FU_ITEM_LOWER])&&indexPath.row == 0)
    {
        return;
    }
    
    [[FUManager shareInstance] bindItemWithModel:model];
    
    if ([self.mDelegate respondsToSelector:@selector(didSelectedItem)])
    {
        [self.mDelegate didSelectedItem];
    }
    
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
