//
//  FUARFilterView.m
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUARFilterView.h"
#import "FUAvatar.h"
#import "FUP2ADefine.h"
#import "FUManager.h"

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

    modelIndex = 1 ;
    if ([[FUManager shareInstance].avatars containsObject:avatar]) {
        modelIndex = [[FUManager shareInstance].avatars indexOfObject:avatar] + 1 ;
    }
    
    [self.collection reloadData];
    [self.collection scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:modelIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (void)reloadData {

    self.modelsArray = [FUManager shareInstance].avatars;
    self.filtersArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ARFilter.plist" ofType:nil]];
}

-(void)setCollectionType:(FUARCollectionType)collectionType {
    _collectionType = collectionType ;

    [self.collection reloadData];
}

- (IBAction)topBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected ;
    
    if (!sender.selected) {
        [self showCollection:NO];
        if ([self.delegate respondsToSelector:@selector(ARFilterViewDidShowTopView:)]) {
            [self.delegate ARFilterViewDidShowTopView:NO];
        }
        return ;
    }
    
    self.modelBtn.selected = sender == self.modelBtn ;
    self.filterBtn.selected = sender == self.filterBtn ;
    
    self.collectionType = self.modelBtn.selected ? FUARCollectionTypeModel : FUARCollectionTypeFilter ;
    
    if (self.collection.hidden) {
        
        CGFloat centerX = sender.center.x ;
        CGPoint center = self.line.center ;
        center.x = centerX ;
        self.line.center = center ;
        
        [self showCollection:YES];
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
}

- (void)showCollection:(BOOL)show {
    if (show) {
        self.collection.hidden = NO ;
        [UIView animateWithDuration:0.35 animations:^{
            self.collection.transform = CGAffineTransformIdentity ;
        }];
    }else {
        [UIView animateWithDuration:0.35 animations:^{
            self.collection.transform = CGAffineTransformMakeTranslation(0, self.collection.frame.size.height) ;
        }completion:^(BOOL finished) {
            self.collection.hidden = YES ;
            self.line.hidden = YES ;
            self.modelBtn.selected = NO ;
            self.filterBtn.selected = NO ;
        }];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    switch (_collectionType) {
        case FUARCollectionTypeModel:
            return self.modelsArray.count + 1 ;
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

            if (indexPath.row == 0) {
                cell.imageView.image = modelIndex == 0 ? [UIImage imageNamed:@"noitem-pressed"] : [UIImage imageNamed:@"noitem"] ;
                cell.imageView.layer.borderColor =  [UIColor clearColor].CGColor;
                cell.imageView.layer.borderWidth =  0.0 ;
            }else {
                FUAvatar *avatar = self.modelsArray[indexPath.row - 1] ;
                cell.imageView.image = [UIImage imageWithContentsOfFile:avatar.imagePath];

                cell.layer.borderColor = modelIndex == indexPath.row ? [UIColor colorWithRed:54/255.0 green:178/255.0 blue:1.0 alpha:1.0].CGColor : [UIColor clearColor].CGColor;
                cell.layer.borderWidth = modelIndex == indexPath.row ? 2.0 : 0.0 ;
            }
        }
            break;
        case FUARCollectionTypeFilter:{

            if (indexPath.row == 0) {
                cell.imageView.image = filterIndex == 0 ? [UIImage imageNamed:@"noitem-pressed"] : [UIImage imageNamed:@"noitem"] ;
                cell.imageView.layer.borderColor =  [UIColor clearColor].CGColor;
                cell.imageView.layer.borderWidth =  0.0 ;
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

            FUAvatar *avatar = nil ;
            if (indexPath.row != 0) {
                avatar = self.modelsArray[indexPath.row - 1] ;
            }
            [self.collection reloadData];

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
