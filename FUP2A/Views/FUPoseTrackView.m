//
//  FUPoseTrackView.m
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUPoseTrackView.h"
#import "FUAvatar.h"
#import "FUP2ADefine.h"
#import "FUManager.h"

typedef enum : NSInteger {
    FUPoseTrackCollectionTypeModel,
    FUPoseTrackCollectionTypeInput,
} FUPoseTrackCollectionType;

@interface FUPoseTrackView ()<UICollectionViewDelegate, UICollectionViewDataSource>
{
    NSInteger modelIndex ;
}

@property (nonatomic, assign) FUPoseTrackCollectionType collectionType ;



@property (weak, nonatomic) IBOutlet UIButton *modelBtn;
@property (weak, nonatomic) IBOutlet UIButton *inputBtn;


@property (weak, nonatomic) IBOutlet UICollectionView *collection;
//
@property (nonatomic, strong) NSArray *modelsArray ;
@property (nonatomic, strong) NSArray *inputArray ;
@property (weak, nonatomic) IBOutlet UIView *line;
@end

@implementation FUPoseTrackView

-(void)awakeFromNib {
    [super awakeFromNib];

    self.collection.delegate = self;
    self.collection.dataSource = self ;

    self.collectionType = FUPoseTrackCollectionTypeModel ;
    modelIndex = 0 ;
    self.inputIndex = 1 ;
	
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
    self.inputArray = @[@"album",@"live"];
}

-(void)setCollectionType:(FUPoseTrackCollectionType)collectionType {
    _collectionType = collectionType ;

    [self.collection reloadData];
}


- (IBAction)modelAndInputBtnAction:(UIButton *)sender {
	sender.selected = YES ;
	CGFloat centerX = sender.center.x ;
	CGPoint center = self.line.center ;
	center.x = centerX ;
	self.line.center = center ;
	
	if (sender == self.modelBtn) {
		self.inputBtn.selected = NO;
		self.collectionType = FUPoseTrackCollectionTypeModel;
	}else{
		self.modelBtn.selected = NO;
		self.collectionType = FUPoseTrackCollectionTypeInput;
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
        }];
    }
}
- (void) reloadCollection{
   [self.collection reloadData];
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    switch (_collectionType) {
        case FUPoseTrackCollectionTypeModel:
            return self.modelsArray.count;
            break;
        case FUPoseTrackCollectionTypeInput:
            return self.inputArray.count;
            break ;
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    FUPoseTrackCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUPoseTrackCell" forIndexPath:indexPath];

    switch (_collectionType) {
        case FUPoseTrackCollectionTypeModel:{

                FUAvatar *avatar = self.modelsArray[indexPath.row] ;
                cell.imageView.image = [UIImage imageWithContentsOfFile:avatar.imagePath];

                cell.layer.borderColor = modelIndex == indexPath.row ? [UIColor colorWithRed:54/255.0 green:178/255.0 blue:1.0 alpha:1.0].CGColor : [UIColor clearColor].CGColor;
                cell.layer.borderWidth = modelIndex == indexPath.row ? 2.0 : 0.0 ;
        }
            break;
        case FUPoseTrackCollectionTypeInput:{

            if (indexPath.row == 0) {
                cell.imageView.image =  [UIImage imageNamed:@"icon_album_55"] ;
                cell.layer.borderColor =  [UIColor clearColor].CGColor;
                cell.layer.borderWidth =  0.0 ;
            }else if (indexPath.row == 1) {
                cell.imageView.image =  [UIImage imageNamed:@"icon_live_55"] ;
                cell.layer.borderColor =  [UIColor clearColor].CGColor;
                cell.layer.borderWidth =  0.0 ;
            } else {
            }
			
			cell.layer.borderColor = self.inputIndex == indexPath.row ? [UIColor colorWithRed:54/255.0 green:178/255.0 blue:1.0 alpha:1.0].CGColor : [UIColor clearColor].CGColor;
			cell.layer.borderWidth = self.inputIndex == indexPath.row ? 2.0 : 0.0 ;
        }
            break ;
    }

    return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    switch (_collectionType) {
        case FUPoseTrackCollectionTypeModel:{

            if (modelIndex == indexPath.row) {
                return ;
            }
            modelIndex = indexPath.row ;
            FUAvatar *avatar = self.modelsArray[indexPath.row] ;
            [self.collection reloadData];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(PoseTrackViewDidSelectedAvatar:)]) {
                    [self.delegate PoseTrackViewDidSelectedAvatar:avatar];
                }
            });
        }
            break;
        case FUPoseTrackCollectionTypeInput:{

            [self.collection reloadData];

            NSString *inputName = self.inputArray[indexPath.row] ;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(PoseTrackViewDidSelectedInput:)]) {
                    [self.delegate PoseTrackViewDidSelectedInput:inputName];
                }
            });
        }
            break;
    }
}


@end

@implementation FUPoseTrackCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.masksToBounds = YES ;
    self.layer.cornerRadius = 8.0 ;
}

@end
