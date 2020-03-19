//
//  FUTextTrackView.m
//  FUP2A
//
//  Created by L on 2018/8/10.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUTextTrackView.h"
#import "FUAvatar.h"
#import "FUP2ADefine.h"
#import "FUManager.h"


typedef enum : NSInteger {
	FUTextTrackCollectionTypeModel,
	FUTextTrackCollectionTypeFilter,
	FUTextTrackCollectionTypeTone,
} FUTextTrackCollectionType;

@interface FUTextTrackView ()<UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
	NSInteger modelIndex ;
    NSInteger filterIndex ;
	NSInteger toneIndex ;
}

@property (nonatomic, assign) FUTextTrackCollectionType collectionType ;



@property (weak, nonatomic) IBOutlet UIButton *modelBtn;
@property (weak, nonatomic) IBOutlet UIButton *inputBtn;
@property (weak, nonatomic) IBOutlet UIButton *toneBtn;


@property (weak, nonatomic) IBOutlet UICollectionView *collection;
@property (weak, nonatomic) IBOutlet UIView *textView;

//
@property (nonatomic, strong) NSArray *modelsArray ;
@property (nonatomic, strong) NSArray *filtersArray ;
@property (nonatomic, strong) NSArray *toneArray ;
@property (weak, nonatomic) IBOutlet UIView *line;
@end

@implementation FUTextTrackView

-(void)awakeFromNib {
	[super awakeFromNib];
	self.mInputView = [[FUKeyBoardInputView alloc]initWithType:Text];
	if (appManager.isXFamily) {
	self.mInputView.frame = CGRectMake(0,HEIGHT - 90 , WIDTH,56);
	}else{
	self.mInputView.frame = CGRectMake(0,HEIGHT - 56 , WIDTH,56);
	}
	[self setTheTalkBar];
	self.collection.delegate = self;
	self.collection.dataSource = self ;
	
	self.collectionType = FUTextTrackCollectionTypeModel ;
	modelIndex = 0 ;
	filterIndex = 0 ;
	self.toneArray = @[@"温柔女声01",@"标准男声02",@"严厉女声03",@"萝莉女声04",@"温柔女声05",@"标准女声06",@"标准男声07",@"标准男声08",@"严厉女声09",@"亲和女声10",@"甜美女声11",@"自然女声12",@"温柔女声13",@"严厉女声14",@"儿童音15",@"萝莉女声16",@"萝莉女声17"];
	[self reloadData];
}
-(void) setTheTalkBar{
	
	__weak typeof(self) weakSelf = self;
	self.mInputView.showOrHideBlock = ^(BOOL isShow,float keyBoardHeight) {
       NSLog(@"键盘弹起，准备输入-----------");
	  [weakSelf.delegate TextTrackViewShowOrHideKeyBoardInput:isShow height:keyBoardHeight];
};
	self.mInputView.exitFromKeyBoardInput = ^{
		NSLog(@"退出键盘输入-----------");
		[weakSelf.delegate TextTrackViewExitFromKeyBoardInput];
	};
	
	[self.mInputView sendText:^(NSString *text) {
		NSLog(@"文字是--------%@",text);
		[weakSelf.delegate TextTrackViewInput:text];
	}];
	
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

-(void)setCollectionType:(FUTextTrackCollectionType)collectionType {
	_collectionType = collectionType ;
	[self.collection reloadData];
}

-(void)resetButtons{
	self.modelBtn.selected = NO;
	self.inputBtn.selected = NO;
	self.toneBtn.selected = NO;
}
- (IBAction)modelAndInputBtnAction:(UIButton *)sender {
	[self resetButtons];
	
	sender.selected = YES ;
	CGFloat centerX = sender.center.x ;
	CGPoint center = self.line.center ;
	center.x = centerX ;
	self.line.center = center ;
   
	if (sender == self.modelBtn) {
		self.collectionType = FUTextTrackCollectionTypeModel;
	}else if (sender == self.inputBtn) {
		self.collectionType = FUTextTrackCollectionTypeFilter;
	}else if (sender == self.toneBtn) {
		self.collectionType = FUTextTrackCollectionTypeTone;
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
// 隐藏键盘
/// return 隐藏之前键盘是否已弹起
-(BOOL)hideKeyboard{
   return [self.mInputView hideKeyboard];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	
	switch (_collectionType) {
		case FUTextTrackCollectionTypeModel:
			return self.modelsArray.count;
			break;
		case FUTextTrackCollectionTypeFilter:
			return self.filtersArray.count + 1;
			break ;
		case FUTextTrackCollectionTypeTone:
			return self.toneArray.count;
			break ;
	}
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	FUTextTrackCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUTextTrackCell" forIndexPath:indexPath];
	cell.imageView.hidden = NO;
	cell.textLabel.hidden = YES;
	switch (_collectionType) {
		case FUTextTrackCollectionTypeModel:{
				FUAvatar *avatar = self.modelsArray[indexPath.row] ;
				cell.imageView.image = [UIImage imageWithContentsOfFile:avatar.imagePath];
				
				cell.layer.borderColor = modelIndex == indexPath.row ? [UIColor colorWithRed:54/255.0 green:178/255.0 blue:1.0 alpha:1.0].CGColor : [UIColor clearColor].CGColor;
				cell.layer.borderWidth = modelIndex == indexPath.row ? 2.0 : 0.0 ;
		}
			break;
		case FUTextTrackCollectionTypeFilter:{

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
		case FUTextTrackCollectionTypeTone:{
			cell.imageView.hidden = YES;
			cell.layer.borderWidth = 0;
			cell.textLabel.text = self.toneArray[indexPath.row];
			cell.textLabel.hidden = NO;
            [cell selectTheTextLabel:toneIndex == indexPath.row];
		}
			break ;
	}
	
	return cell ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (_collectionType) {
		case FUTextTrackCollectionTypeModel:{
			
			if (modelIndex == indexPath.row) {
				return ;
			}
			
			modelIndex = indexPath.row ;
			
			FUAvatar *avatar = self.modelsArray[indexPath.row] ;
			[self.collection reloadData];
			
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				if (self.delegate && [self.delegate respondsToSelector:@selector(TextTrackViewDidSelectedAvatar:)]) {
					[self.delegate TextTrackViewDidSelectedAvatar:avatar];
				}
			});
		}
			break;
		case FUTextTrackCollectionTypeFilter:{
			
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
		case FUTextTrackCollectionTypeTone:{
			
			toneIndex = indexPath.row ;
			[self.collection reloadData];
			
			NSString *tonetName = self.toneArray[indexPath.row] ;
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				if (self.delegate && [self.delegate respondsToSelector:@selector(TextTrackViewDidSelectedTone:)]) {
					[self.delegate TextTrackViewDidSelectedTone:tonetName];
				}
			});
		}
			break;
	}
}
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
	switch (_collectionType) {
		case FUTextTrackCollectionTypeModel:
		case FUTextTrackCollectionTypeFilter:
			return CGSizeMake(55, 55);
			break;
		case FUTextTrackCollectionTypeTone:
			return CGSizeMake(80, 30);
			break;
	}
}
@end

@implementation FUTextTrackCell
-(void) selectTheTextLabel:(BOOL) isSelect{
	if (isSelect) {
		self.textLabel.layer.borderColor = UIColorFromRGB(0x4C96FF).CGColor;
		self.textLabel.layer.cornerRadius = 15;
		self.textLabel.textColor = UIColorFromRGB(0x3E8CFB);
	}else{
		self.textLabel.layer.borderColor = UIColorFromRGB(0xE5E5E5).CGColor;
		self.textLabel.layer.cornerRadius = 15;
		self.textLabel.textColor = UIColorFromRGB(0x5E6167);
	}
	
}
- (void)awakeFromNib {
	[super awakeFromNib];
	self.layer.masksToBounds = YES ;
	self.layer.cornerRadius = 8.0 ;
}

@end
