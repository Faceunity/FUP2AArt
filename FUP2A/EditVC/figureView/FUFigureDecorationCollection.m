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
    [self.mDelegate cancelSelectedItem];
}


- (void)scrollCurrentToCenterWithAnimation:(BOOL)animation
{
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[FUManager shareInstance] getSelectedItemIndexOfSelectedSubType] inSection:0];
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
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
	// 如果是 美妆 大类 或者 是 配饰大类  则需要添加角标
	if ([model isKindOfClass:[FUMakeupItemModel class]]) {
		NSString * title = ((FUMakeupItemModel *)model).title;
		if (title) {
			cell.showTagLabel = YES;
			cell.tagLabelText = ((FUMakeupItemModel *)model).title;
		}else{
			cell.showTagLabel = NO;
		}
	}else if([model isKindOfClass:[FUDecorationItemModel class]]) {
		NSString * title = ((FUDecorationItemModel *)model).title;
		if (title) {
			cell.showTagLabel = YES;
			cell.tagLabelText = ((FUDecorationItemModel *)model).title;
		}else{
			cell.showTagLabel = NO;
		}
	}else{
		cell.showTagLabel = NO;
	}
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
	
	if ([model isKindOfClass:[FUMakeupItemModel class]]) {
		if([[FUManager shareInstance]makeupHasValiedSeletedItem]){
			NSArray<NSNumber *> *selectedIndexArray = [[FUManager shareInstance] getSelectedItemIndexOfMakeup];
			if ([selectedIndexArray containsObject:@(indexPath.row)] && indexPath.row>0) {
				cell.layer.borderWidth = 2.0;
				cell.layer.borderColor = [UIColor colorWithHexColorString:@"4C96FF"].CGColor;
				
			}else{
				cell.layer.borderWidth = 0.0;
				cell.layer.borderColor = [UIColor clearColor].CGColor;
			}
			
		}else{
			NSInteger selectedIndex = 0;
			cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
			cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
		}
	}else if ([model isKindOfClass:[FUDecorationItemModel class]]) {
		if([[FUManager shareInstance]decorationHasValiedSeletedItem]){
			NSArray<NSNumber *> *selectedIndexArray = [[FUManager shareInstance] getSelectedItemIndexOfDecoration];
			if ([selectedIndexArray containsObject:@(indexPath.row)] && indexPath.row>0) {
				cell.layer.borderWidth = 2.0;
				cell.layer.borderColor = [UIColor colorWithHexColorString:@"4C96FF"].CGColor;
				
			}else{
				cell.layer.borderWidth = 0.0;
				cell.layer.borderColor = [UIColor clearColor].CGColor;
			}
			
		}else{
			NSInteger selectedIndex = 0;
			cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
			cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
		}
	}
	else{
		NSInteger selectedIndex = [[FUManager shareInstance] getSelectedItemIndexOfSelectedSubType];
		cell.layer.borderWidth = selectedIndex == indexPath.row ? 2.0 : 0.0 ;
		cell.layer.borderColor = selectedIndex == indexPath.row ? [UIColor colorWithHexColorString:@"4C96FF"].CGColor : [UIColor clearColor].CGColor ;
	}
	return cell ;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	FUItemModel *model = [[[FUManager shareInstance]getItemArrayOfSelectedSubType] objectAtIndex:indexPath.row];
	
	if ([model isKindOfClass:[FUMakeupItemModel class]] ) {  // 美妆类型 且包含当前 indexPath.row,为取消操作
		NSArray<NSNumber *> *selectedIndexArray = [[FUManager shareInstance] getSelectedItemIndexOfMakeup];
		if(indexPath.row == 0){   // 美妆的 第 0 个 item，需要记录当前的多选状态
			FUMultipleRecordItemModel * multipleRecordMakeupItemModel = [[FUMultipleRecordItemModel alloc]initWithItemModel:model];
			multipleRecordMakeupItemModel.multipleSelectedArr = [[FUManager shareInstance]getSelectedItemIndexOfMakeup];
			NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
			editDict[@"oldConfig"] = multipleRecordMakeupItemModel;
			editDict[@"currentConfig"] = multipleRecordMakeupItemModel;
			[[FUAvatarEditManager sharedInstance]push:editDict];
			[[FUManager shareInstance] resetMakeupItems];
			if ([self.mDelegate respondsToSelector:@selector(cancelSelectedItem)])
			{
				[self.mDelegate cancelSelectedItem];
			}
		}else if([selectedIndexArray containsObject:@(indexPath.row)]){
		    FUMakeupNoItemModel *noItem = [[FUMakeupNoItemModel alloc]initWithItemModel:model];
		    [self recordModel:noItem];
			[[FUManager shareInstance] removeItemWithModel:nil AndType:model.type];
			
			if ([self.mDelegate respondsToSelector:@selector(cancelSelectedItem)])
			{
				[self.mDelegate cancelSelectedItem];
			}
		}else{
			[[FUManager shareInstance] bindItemWithModel:model];
			if ([self.mDelegate respondsToSelector:@selector(didSelectedItem:)])
			{
				[self.mDelegate didSelectedItem:model];
			}
		}
	}else if ([model isKindOfClass:[FUDecorationItemModel class]] ) {  // 配饰类型 且包含当前 indexPath.row,为取消操作
		NSArray<NSNumber *> *selectedIndexArray = [[FUManager shareInstance] getSelectedItemIndexOfDecoration];
		if(indexPath.row == 0){   // 美妆的 第 0 个 item，需要记录当前的多选状态
			FUMultipleRecordItemModel * multipleRecordMakeupItemModel = [[FUMultipleRecordItemModel alloc]initWithItemModel:model];
			multipleRecordMakeupItemModel.multipleSelectedArr = [[FUManager shareInstance]getSelectedItemIndexOfDecoration];
			NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
			editDict[@"oldConfig"] = multipleRecordMakeupItemModel;
			editDict[@"currentConfig"] = multipleRecordMakeupItemModel;
			[[FUAvatarEditManager sharedInstance]push:editDict];
			// 重置 所有已经选择的配饰
			[[FUManager shareInstance] resetDecorationItems];
			if ([self.mDelegate respondsToSelector:@selector(cancelSelectedItem)])
			{
				[self.mDelegate cancelSelectedItem];
			}
		}else if([selectedIndexArray containsObject:@(indexPath.row)]){
			FUDecorationNoItemModel *noItem = [[FUDecorationNoItemModel alloc]initWithItemModel:model];
		    [self recordModel:noItem];
			[[FUManager shareInstance] removeItemWithModel:nil AndType:model.type];
			
			if ([self.mDelegate respondsToSelector:@selector(cancelSelectedItem)])
			{
				[self.mDelegate cancelSelectedItem];
			}
		}else{
			[[FUManager shareInstance] bindItemWithModel:model];
			if ([self.mDelegate respondsToSelector:@selector(didSelectedItem:)])
			{
				[self.mDelegate didSelectedItem:model];
			}
		}
	}else{
		if (([model.type isEqualToString:TAG_FU_ITEM_CLOTH]||[model.type isEqualToString:TAG_FU_ITEM_UPPER]||[model.type isEqualToString:TAG_FU_ITEM_LOWER])&&indexPath.row == 0)
		{
			return;
		}
		
		[[FUManager shareInstance] bindItemWithModel:model];
		if ([self.mDelegate respondsToSelector:@selector(didSelectedItem:)])
		{
			[self.mDelegate didSelectedItem:model];
		}
		
		
	}
	[self reloadData];
	if ([model isKindOfClass:[FUMakeupItemModel class]]) {
		
	}else if ([model isKindOfClass:[FUDecorationItemModel class]]) {
		
	}
	else{
		[self scrollCurrentToCenterWithAnimation:YES];
	}
}
-(void)recordModel:(FUItemModel*)model{
	NSMutableDictionary *editDict = [[NSMutableDictionary alloc]init];
	FUAvatar *avatar = [FUManager shareInstance].currentAvatars.firstObject;
	FUItemModel *oldModel = [avatar valueForKey:model.type];
	editDict[@"oldConfig"] = oldModel;
	editDict[@"currentConfig"] = model;

	[[FUAvatarEditManager sharedInstance]push:editDict];
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
	self.tagLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
	[self freshLayer];
}
-(void)setShowTagLabel:(BOOL)showTagLabel{
	_showTagLabel = showTagLabel;
	self.tagLabel.hidden = !showTagLabel;
}
-(void)setTagLabelText:(NSString *)tagLabelText{
	_tagLabelText = tagLabelText;
	self.tagLabel.text = tagLabelText;
}
-(void)freshLayer{
	UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.tagLabel.bounds byRoundingCorners: UIRectCornerTopLeft cornerRadii:CGSizeMake(8,8)];
	//创建 layer
	CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
	
	maskLayer.frame = self.tagLabel.bounds;
	//赋值
	maskLayer.path = maskPath.CGPath;
	self.tagLabel.layer.mask = maskLayer;
}

@end
