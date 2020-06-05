//
//  FUPoseTrackBttomView.m
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUPoseTrackBttomView.h"
#import "FUPoseTrackView.h"
#import "FUARFilterView.h"
typedef enum : NSInteger {
    FUARCollectionTypeModel,
    FUARCollectionTypeFilter,
} FUARCollectionType;


@interface FUPoseTrackBttomView ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    NSInteger modelIndex ;
    NSInteger filterIndex ;
}

@property (nonatomic, assign) FUARCollectionType collectionType ;

@property (weak, nonatomic) IBOutlet UIButton *poseTrackBtn;
@property (weak, nonatomic) IBOutlet UIButton *ARFilterBtn;

@property (weak, nonatomic) IBOutlet FUPoseTrackView *poseTrackView;
@property (weak, nonatomic) IBOutlet FUARFilterView *arFilterView;



@property (weak, nonatomic) IBOutlet UICollectionView *collection;
//
@property (nonatomic, strong) NSArray *modelsArray ;
@property (nonatomic, strong) NSArray *filtersArray ;
@property (weak, nonatomic) IBOutlet UIView *line;
@end

@implementation FUPoseTrackBttomView

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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collection scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self->modelIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    });
}


- (void)reloadData {

    self.modelsArray = [FUManager shareInstance].avatarList;
    self.filtersArray = @[@"toonfilter"];
}

-(void)setCollectionType:(FUARCollectionType)collectionType {
    _collectionType = collectionType ;

    [self.collection reloadData];
}

- (IBAction)trackBtnAction:(UIButton *)sender {
	sender.selected = YES ;
	sender.backgroundColor = UIColorFromRGB(0x4C96FF);
	if (sender == self.poseTrackBtn) {
		self.ARFilterBtn.backgroundColor = [UIColor whiteColor];
		self.ARFilterBtn.selected = NO;
		self.poseTrackView.hidden = NO;
		self.arFilterView.hidden = YES;
	}else{
		self.poseTrackBtn.backgroundColor = [UIColor whiteColor];
		self.poseTrackBtn.selected = NO;
		self.poseTrackView.hidden = YES;
		self.arFilterView.hidden = YES;
	}
	
	if (!sender.selected) {
		[self showCollection:NO];
		if ([self.delegate respondsToSelector:@selector(ARFilterViewDidShowTopView:)]) {
			[self.delegate ARFilterViewDidShowTopView:NO];
		}
		return ;
	}
	
	
    self.collectionType = self.poseTrackBtn.selected ? FUARCollectionTypeModel : FUARCollectionTypeFilter ;
	
    NSIndexPath *indexPath = self.poseTrackBtn.selected ? [NSIndexPath indexPathForRow:modelIndex inSection:0] : [NSIndexPath indexPathForRow:filterIndex inSection:0] ;
    [self.collection scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
	
	

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
            self.poseTrackBtn.selected = NO ;
            self.ARFilterBtn.selected = NO ;
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

    FUPoseTrackBttomCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUPoseTrackBttomCell" forIndexPath:indexPath];

    switch (_collectionType) {
        case FUARCollectionTypeModel:{

            if (indexPath.row == 0) {
                cell.imageView.image = modelIndex == 0 ? [UIImage imageNamed:@"noitem-pressed"] : [UIImage imageNamed:@"noitem"] ;
                cell.layer.borderColor =  [UIColor clearColor].CGColor;
                cell.layer.borderWidth =  0.0 ;
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

@implementation FUPoseTrackBttomCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.masksToBounds = YES ;
    self.layer.cornerRadius = 8.0 ;
}

@end
