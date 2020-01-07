//
//  FUHistoryViewController.m
//  FUP2A
//
//  Created by L on 2018/6/20.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUHistoryViewController.h"
#import "FUAvatar.h"
#import "FUP2ADefine.h"
#import "FUManager.h"
#import "FUTool.h"
#import "UIColor+FU.h"

@interface FUHistoryViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSMutableArray<FUAvatar *> *dataSource ;
@property (weak, nonatomic) IBOutlet UICollectionView *collection;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UILabel *noitemLabel;

@property (nonatomic, strong) NSMutableArray<FUAvatar *> *selectedItems ;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deleteBottom;
@end

@implementation FUHistoryViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = [NSMutableArray arrayWithCapacity:1];
    
    NSString *sourcePath = CurrentAvatarStylePath ;
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sourcePath error:nil] ;
    array = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj2 compare:obj1 options:NSNumericSearch] ;
    }];
    for (NSString *jsonName in array) {
        if (![jsonName hasSuffix:@".json"]) {
            continue ;
        }
        NSString *jsonPath = [sourcePath stringByAppendingPathComponent:jsonName];
        NSData *jsonData = [[NSString stringWithContentsOfFile:jsonPath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        
        FUAvatar *avatar = [FUAvatar avatarWithInfoDic:dic];
        [self.dataSource addObject:avatar];
    }
    
    self.noitemLabel.hidden = self.dataSource.count != 0 ;
    
    self.collection.delegate = self ;
    self.collection.dataSource = self ;
    [self.collection registerClass:[FUHistoryCell class] forCellWithReuseIdentifier:@"FUHistoryCell"];
    
    [self.collection reloadData];
    
    self.selectedItems = [NSMutableArray arrayWithCapacity:1];
    
    if ([[FUTool getPlatformType] isEqualToString:@"iPhone X"]) {
        _deleteBottom.constant = 34 ;
        [self.view layoutIfNeeded];
    }
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.collection reloadData];
}

// 关闭
- (IBAction)closeAction:(UIButton *)sender {
	[self.navigationController popViewControllerAnimated:YES];
	
}

// 删除
- (IBAction)deleteAction:(UIButton *)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"确认删除所选模型？" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancle = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [cancle setValue:[UIColor lightGrayColor] forKey:@"titleTextColor"];
    
    
    __weak typeof(self)weaklSelf = self ;
    UIAlertAction *certain = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        FUAvatar *currentAvatar = [FUManager shareInstance].currentAvatars.firstObject ;
        NSString *name = currentAvatar.name;
        
        for (FUAvatar *avatar  in weaklSelf.selectedItems) {
            if ([weaklSelf.dataSource containsObject:avatar]) {
                [weaklSelf.dataSource removeObject:avatar];
                
                // delete file
                NSString *filePath = [documentPath stringByAppendingPathComponent:avatar.name];
                if ([fileManager fileExistsAtPath:filePath]) {
                    [fileManager removeItemAtPath:filePath error:nil];
                }
                // delete avatar info
                NSString *rootPath = CurrentAvatarStylePath ;
                NSString *jsonPath = [[rootPath stringByAppendingPathComponent:avatar.name] stringByAppendingString:@".json"];
                if ([fileManager fileExistsAtPath:jsonPath]) {
                    [fileManager removeItemAtPath:jsonPath error:nil];
                }
                
                if ([name isEqualToString:avatar.name]) {
                    if (self.mDelegate && [self.mDelegate respondsToSelector:@selector(historyViewDidDeleteCurrentItem)]) {
                        [self.mDelegate historyViewDidDeleteCurrentItem];
                    }
                }
            }
            
            for (FUAvatar *a in [FUManager shareInstance].avatarList) {
                if (!a.defaultModel && [avatar.name isEqualToString:a.name]) {
                    [[FUManager shareInstance].avatarList removeObject:a];
                    break ;
                }
            }
        }
        
        [weaklSelf.selectedItems removeAllObjects];
        [weaklSelf.collection reloadData];
        
        weaklSelf.noitemLabel.hidden = weaklSelf.dataSource.count != 0 ;
        [weaklSelf setDeleteBtnTitle];
    }];
    
    [alertController addAction:cancle];
    [alertController addAction:certain];
    
    [self presentViewController:alertController animated:YES completion:^{
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count ;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUHistoryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FUHistoryCell" forIndexPath:indexPath];
    if (indexPath.row < self.dataSource.count) {
        FUAvatar *avatar = self.dataSource[indexPath.row] ;
        cell.imageView.image = [UIImage imageWithContentsOfFile:avatar.imagePath];
        
        if ([self.selectedItems containsObject:avatar]) {
            cell.layer.borderColor = [UIColor colorWithHexColorString:@"4C96FF"].CGColor;
            cell.layer.borderWidth = 2.0 ;
            cell.imageView.layer.borderColor = [UIColor whiteColor].CGColor ;
            cell.imageView.layer.borderWidth = 2.0 ;
        }else {
            cell.layer.borderColor = [UIColor clearColor].CGColor;
            cell.layer.borderWidth = 0.0 ;
            cell.imageView.layer.borderColor = [UIColor clearColor].CGColor ;
            cell.imageView.layer.borderWidth = 0.0 ;
        }
    }
    
    return cell ;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = ([UIScreen mainScreen].bounds.size.width - 80.0) / 4.0 - 1.0;
    return CGSizeMake(width, width) ;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUAvatar *avatar = self.dataSource[indexPath.row] ;
    
    if ([self.selectedItems containsObject:avatar]) {
        [self.selectedItems removeObject:avatar];
    }else {
        [self.selectedItems addObject:avatar];
    }
    
    [self.collection reloadData];
    
    [self setDeleteBtnTitle];
}

- (void)setDeleteBtnTitle {
    
    if (self.selectedItems.count == 0) {
        self.deleteBtn.enabled = NO ;
        self.deleteBtn.titleLabel.text = @"删除" ;
        [self.deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    }else {
        self.deleteBtn.enabled = YES ;
        self.deleteBtn.titleLabel.text = [NSString stringWithFormat:@"删除(%ld)",self.selectedItems.count] ;
        [self.deleteBtn setTitle:[NSString stringWithFormat:@"删除(%ld)",self.selectedItems.count] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end


@implementation FUHistoryCell

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        
        self.layer.masksToBounds = YES ;
        self.layer.cornerRadius = 8.0 ;
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, frame.size.width - 4.0 , frame.size.height - 4.0)];
        self.imageView.layer.masksToBounds = YES ;
        self.imageView.layer.cornerRadius = 8.0 ;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill ;
        self.imageView.clipsToBounds = YES ;
        
        [self addSubview:self.imageView ];
    }
    return self ;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(2, 2, self.bounds.size.width - 4.0 , self.bounds.size.height - 4.0) ;
}

@end
