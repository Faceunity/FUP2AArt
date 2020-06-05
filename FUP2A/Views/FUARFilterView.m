//
//  FUARFilterView.m
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUARFilterView.h"

typedef enum : NSInteger {
    FUARCollectionTypeModel,
    FUARCollectionTypeFilter,
} FUARCollectionType;

@interface FUARFilterView ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    NSInteger modelIndex ;
    NSInteger filterIndex ;
}

@property (nonatomic, assign) FUARCollectionType collectionType ;
@property (weak, nonatomic) IBOutlet UIButton *modelBtn;
@property (weak, nonatomic) IBOutlet UIButton *filterBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *collection;
//
@property (nonatomic, strong) NSArray *modelsArray ;
@property (nonatomic, strong) NSArray *filtersArray ;
@property (weak, nonatomic) IBOutlet UIView *line;
@end

@implementation FUARFilterView

-(void)awakeFromNib {
    [super awakeFromNib];

    self.collection.delegate = self;
    self.collection.dataSource = self ;

    self.collectionType = FUARCollectionTypeModel ;
    modelIndex = 0 ;
    filterIndex = 0 ;
    
//    [self reloadData];
}

- (void)selectedModeWith:(FUAvatar *)avatar {
	
	[self reloadData];
	
	modelIndex = 0 ;
	if ([[FUManager shareInstance].avatarList containsObject:avatar]) {
		modelIndex = [[FUManager shareInstance].avatarList indexOfObject:avatar];
	}
	
	[self.collection reloadData];
	if (self.collectionType == FUARCollectionTypeModel) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self.collection scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self->modelIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
		});
	}
}

- (void)reloadData {

    self.modelsArray = [FUManager shareInstance].avatarList;
    self.filtersArray = @[@"toonfilter"];
}

-(void)setCollectionType:(FUARCollectionType)collectionType {
    _collectionType = collectionType ;

    [self.collection reloadData];
}

- (void)selectNoFilter
{
    if (filterIndex != 0)
    {
        filterIndex = 0 ;
        [self.collection reloadData];
    }
}
/// 选择模型类型
- (void)selectModelType{
   [self topBtnAction:self.modelBtn];
}

- (IBAction)topBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected ;
    
    if (!sender.selected) {
        if ([self.delegate respondsToSelector:@selector(ARFilterViewDidShowTopView:)]) {
            [self.delegate ARFilterViewDidShowTopView:NO];
        }
        return ;
    }
    
    self.modelBtn.selected = sender == self.modelBtn ;
    self.filterBtn.selected = sender == self.filterBtn ;
    
    self.collectionType = self.modelBtn.selected ? FUARCollectionTypeModel : FUARCollectionTypeFilter ;
    
    NSIndexPath *indexPath = self.modelBtn.selected ? [NSIndexPath indexPathForRow:modelIndex inSection:0] : [NSIndexPath indexPathForRow:filterIndex inSection:0] ;
    [self.collection scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    
    
    if (self.collection.hidden) {
        
        CGFloat centerX = sender.center.x ;
        CGPoint center = self.line.center ;
        center.x = centerX ;
        self.line.center = center ;
		if ([self.delegate respondsToSelector:@selector(ARFilterViewDidShowTopView:)]) {
            [self.delegate ARFilterViewDidShowTopView:YES];
        }
    }else {
        CGFloat centerX = sender.center.x ;
        CGPoint center = self.line.center ;
        center.x = centerX ;
        [UIView animateWithDuration:0.35 animations:^{
            self.line.center = center ;
        }];
    }
    [self.collection reloadData];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    switch (_collectionType) {
        case FUARCollectionTypeModel:
            return self.modelsArray.count ;
            break;
        case FUARCollectionTypeFilter:
            return self.filtersArray.count + 1;
            break ;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    FUARFilterCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUARFilterCell" forIndexPath:indexPath];

    switch (_collectionType) {
        case FUARCollectionTypeModel:{
                FUAvatar *avatar = self.modelsArray[indexPath.row] ;
                cell.imageView.image = [UIImage imageWithContentsOfFile:avatar.imagePath];

                cell.layer.borderColor = modelIndex == indexPath.row ? [UIColor colorWithRed:54/255.0 green:178/255.0 blue:1.0 alpha:1.0].CGColor : [UIColor clearColor].CGColor;
			    cell.layer.borderWidth = modelIndex == indexPath.row ? 2.0 : 0.0 ;
		
        }
            break;
        case FUARCollectionTypeFilter:{

            if (indexPath.row == 0) {
                cell.imageView.image = filterIndex == 0 ? [UIImage imageNamed:@"noitem-pressed"] : [UIImage imageNamed:@"noitem"] ;
                cell.layer.borderColor =  [UIColor clearColor].CGColor;
                cell.layer.borderWidth =  0.0 ;
            }else {

                NSString *filter = self.filtersArray[indexPath.row - 1] ;
                cell.imageView.image = [UIImage imageNamed:filter] ;
               
                cell.layer.borderColor = filterIndex == indexPath.row ? [UIColor colorWithRed:54/255.0 green:178/255.0 blue:1.0 alpha:1.0].CGColor : [UIColor clearColor].CGColor;
                cell.layer.borderWidth = filterIndex == indexPath.row ? 2.0 : 0.0 ;
            }
        }
            break ;
    }

    return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    switch (_collectionType) {
        case FUARCollectionTypeModel:{

            if (modelIndex == indexPath.row) {
                return ;
            }
            
            modelIndex = indexPath.row ;
            [self.collection reloadData];
            FUAvatar *avatar = self.modelsArray[indexPath.row] ;
			


            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(ARFilterViewDidSelectedAvatar:)]) {
                    [self.delegate ARFilterViewDidSelectedAvatar:avatar];
                }
            });
            
        }
            break;
        case FUARCollectionTypeFilter:{

            if (filterIndex == indexPath.row) {
                return ;
            }
            filterIndex = indexPath.row ;
            [self.collection reloadData];

            NSString *filterName = indexPath.row == 0 ? @"noitem" : self.filtersArray[indexPath.row - 1] ;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(ARFilterViewDidSelectedARFilter:)]) {
                    [self.delegate ARFilterViewDidSelectedARFilter:filterName];
                }
            });
        }
            break;
    }
}


@end

@implementation FUARFilterCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.masksToBounds = YES ;
    self.layer.cornerRadius = 8.0 ;
}

@end
