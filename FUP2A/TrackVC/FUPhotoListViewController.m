//
//  FUPhotoListViewController.m
//  FUP2A
//
//  Created by Chen on 2020/4/8.
//  Copyright © 2020 L. All rights reserved.
//
#define FU_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define FU_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define EA_NAVIGATIONBAR_HEIGHT \
^(){\
UINavigationController *nav = (UINavigationController *)[[[UIApplication sharedApplication] windows] objectAtIndex:0].rootViewController;\
return nav.navigationBar.frame.size.height;\
}()

#define EA_STATUSBAR_HEIGHT [UIApplication sharedApplication].windows[0].windowScene.statusBarManager.statusBarFrame.size.height


#define EA_NAVBAR_AND_STATUSBAR_HEIGHT EA_NAVIGATIONBAR_HEIGHT+EA_STATUSBAR_HEIGHT



#import "FUPhotoListViewController.h"
#import "FUOrientationViewController.h"

@interface FUPhotoListViewController ()<UITableViewDelegate,UITableViewDataSource,UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *mutArrayAlbums;  //相簿名称数组
@property (nonatomic, strong) NSMutableDictionary *mutDictPhotos;  //相片或视频数组,以相簿名称为key保存的字典
@property (nonatomic, strong) NSMutableDictionary *mutDictPhotosInfo; //相片或视频信息数组，以相簿名称为key保存的字典

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UIView *albumsNavView;    //顶部相簿按钮
@property (nonatomic, strong) UILabel *navTitle;        //选中相簿名称
@property (nonatomic, strong) UIImageView *imgvwArrow;   //相簿栏展开状态
 
@property (nonatomic, assign) NSInteger iSelectedAlbumsIndex;   //选中的相簿索引
@property (nonatomic, strong) UIImageView *imgvwNoPic;
@property (nonatomic, strong) UILabel *lblNoPic;


@end

@implementation FUPhotoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self getResource];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBarHidden = NO;
    if (self.mutArrayAlbums.count > 0)
    {
        [self.view addSubview:self.collectionView];
        [self.view addSubview:self.tableView];
        self.tableView.hidden = YES;
        [self resetTitle];
    }
    else
    {
        [self.view addSubview:self.imgvwNoPic];
        [self.view addSubview:self.lblNoPic];
    }

    //修改Navigation 的返回按钮，并添加一个相簿列表缩放按钮
    [self.albumsNavView addSubview:self.navTitle];
    [self.albumsNavView addSubview:self.imgvwArrow];
    
    
    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"icon_back_black"] style:UIBarButtonItemStylePlain target:self action:@selector(touchUpInsideBtnBack)];
    btnBack.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = btnBack;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar addSubview:self.albumsNavView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.albumsNavView removeFromSuperview];
}


/// 重设title为选中的相簿名
- (void)resetTitle
{
    if (self.mutArrayAlbums.count == 0)
    {
        return;
    }
    self.navTitle.text =  self.mutArrayAlbums[self.iSelectedAlbumsIndex];
    [self.navTitle sizeToFit];
    self.navTitle.center = CGPointMake(50, EA_NAVIGATIONBAR_HEIGHT/2);
    
    self.imgvwArrow.image = self.tableView.hidden?[UIImage imageNamed:@"icon_triangle_down"]:[UIImage imageNamed:@"icon_triangle_up"];
    [self.imgvwArrow sizeToFit];
    self.imgvwArrow.frame = CGRectMake(CGRectGetMaxX(self.navTitle.frame)+5, 0, CGRectGetWidth(self.imgvwArrow.frame), CGRectGetHeight(self.imgvwArrow.frame));
     self.imgvwArrow.center = CGPointMake(CGRectGetMidX(self.imgvwArrow.frame),  CGRectGetMidY(self.navTitle.frame));
   
}

/// 获取视频资源
- (void)getResource
{
    self.mutArrayAlbums = NSMutableArray.new;
    self.mutDictPhotos = NSMutableDictionary.new;
    self.mutDictPhotosInfo = NSMutableDictionary.new;
    self.iSelectedAlbumsIndex = 0;
    
    PHAssetCollectionSubtype subType = PHAssetCollectionSubtypeSmartAlbumVideos;
    
    //获取用户自建相册
    PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:subType options:nil];
    [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
         //  && collection.assetCollectionSubtype != PHAssetCollectionSubtypeAlbumCloudShared 排除 iCloud 图片
		if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            if (fetchResult.count > 0) {
                
                NSMutableArray *photos = [[NSMutableArray alloc]init];
                NSMutableArray *photosInfo = [[NSMutableArray alloc]init];
                [fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
//                    [photosInfo addObject:asset];
					NSArray *resourceArray = [PHAssetResource assetResourcesForAsset:asset];
					BOOL bIsLocallayAvailable = [[resourceArray.firstObject valueForKey:@"locallyAvailable"] boolValue]; // If this returns NO, then the asset is in iCloud and not saved locally yet
					// 如果不是本地视频，则排除掉
					if (!bIsLocallayAvailable) {
						return;
					}
					//从相册中取出照片
                    PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
                    opt.resizeMode = PHImageRequestOptionsResizeModeExact;//缩率图
                    opt.synchronous = YES;
                    PHImageManager *imageManager = [[PHImageManager alloc] init];
                    [imageManager requestImageForAsset:asset targetSize:CGSizeMake(140, 140) contentMode:PHImageContentModeAspectFill options:opt resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
                        
                        CGImageRef imageC = image.CGImage;
                        image = [UIImage imageWithCGImage:imageC scale:2 orientation:UIImageOrientationUp];
                        
                        if (image)
                        {
                            [photos addObject:image];
                            [photosInfo addObject:asset];
                        }
                    }];
                }];
                
                if (photos.count > 0)
                {
                    [self.mutArrayAlbums insertObject:collection.localizedTitle atIndex:0];
                    [self.mutDictPhotosInfo setValue:photosInfo forKey:collection.localizedTitle];
                    [self.mutDictPhotos setValue:photos forKey:collection.localizedTitle];
                }
                
            }
        }
    }];
    
    //获取系统智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:subType options:nil];
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
       //  && collection.assetCollectionSubtype != PHAssetCollectionSubtypeAlbumCloudShared 排除 iCloud 图片
		if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
            if (fetchResult.count > 0) {
                
                NSMutableArray *photos = [[NSMutableArray alloc]init];
                NSMutableArray *photosInfo = [[NSMutableArray alloc]init];
                [fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
					NSArray *resourceArray = [PHAssetResource assetResourcesForAsset:asset];
					BOOL bIsLocallayAvailable = [[resourceArray.firstObject valueForKey:@"locallyAvailable"] boolValue]; // If this returns NO, then the asset is in iCloud and not saved locally yet
					// 如果不是本地视频，则排除掉
					if (!bIsLocallayAvailable) {
						return;
					}
//                    [photosInfo addObject:asset];
                    //从相册中取出照片
                    PHImageRequestOptions *opt = [[PHImageRequestOptions alloc]init];
                    opt.resizeMode = PHImageRequestOptionsResizeModeExact;//缩率图
                    opt.synchronous = YES;
                    PHImageManager *imageManager = [[PHImageManager alloc] init];
                    [imageManager requestImageForAsset:asset targetSize:CGSizeMake(140, 140) contentMode:PHImageContentModeAspectFill options:opt resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
                        
                        CGImageRef imageC = image.CGImage;
                        image = [UIImage imageWithCGImage:imageC scale:2 orientation:UIImageOrientationUp];
                        
                        if (image)
                        {
                            [photos addObject:image];
                            [photosInfo addObject:asset];
                        }
                    }];
                }];
                if (photos.count > 0)
                {
                    [self.mutDictPhotosInfo setValue:photosInfo forKey:collection.localizedTitle];
                    [self.mutDictPhotos setValue:photos forKey:collection.localizedTitle];
                    [self.mutArrayAlbums insertObject:collection.localizedTitle atIndex:0];
                }
            }
        }
    }];
}

#pragma mark ----- CollectionView Delegate ------
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
    
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    NSString *albumName = [self.mutArrayAlbums objectAtIndex:self.iSelectedAlbumsIndex];
    NSMutableArray *photos = self.mutDictPhotos[albumName];
    
    return photos.count;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FUPhotoCollectionCell *cell = (FUPhotoCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"DiscoverRechangeCenterCell" forIndexPath:indexPath];
    
    cell.contentView.backgroundColor = [UIColor redColor];
    
    NSString *albumName = [self.mutArrayAlbums objectAtIndex:self.iSelectedAlbumsIndex];
    NSMutableArray *photos = self.mutDictPhotos[albumName];
    NSMutableArray *photosInfo = self.mutDictPhotosInfo[albumName];
    
    cell.imageView.image = photos[indexPath.row];
    PHAsset *asset = photosInfo[indexPath.row];
    if (asset.mediaType == PHAssetMediaTypeVideo)
    {
        cell.lblDuration.hidden = NO;
        cell.lblDuration.text =[self transferFormatWithDuration:asset.duration];
    }
    else
    {
        cell.lblDuration.hidden = YES;
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *albumName = [self.mutArrayAlbums objectAtIndex:self.iSelectedAlbumsIndex];
    NSMutableArray *photosInfo = self.mutDictPhotosInfo[albumName];
    
    PHAsset *asset = photosInfo[indexPath.row];
    
    if (asset.duration < 2)
    {
        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
        [SVProgressHUD setMinimumSize:CGSizeZero];
        [SVProgressHUD showImage:nil status:@"视频时长要在2s以上哦"];

        
        return;
    }
    else if (asset.duration >60)
    {
        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
        [SVProgressHUD setMinimumSize:CGSizeZero];
        [SVProgressHUD showImage:nil status:@"视频时长不能超过1分钟哦"];
        
        return;
    }
    self.navigationController.navigationBarHidden = YES;
    [self.assetDelegate selectedVideo:asset];
    [self.navigationController popViewControllerAnimated:YES];
}


- (NSString *)transferFormatWithDuration:(NSTimeInterval)duration
{
    NSInteger minutes = floor(duration/60);
    NSInteger seconds = round(duration - minutes * 60);
    
    return [NSString stringWithFormat:@"%zi:%@%zi",minutes,seconds<10?@"0":@"",seconds];
}

#pragma mark ----- UITableView Delegate ------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.mutArrayAlbums.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 98;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CommonCell"];
    NSString *albumName = [self.mutArrayAlbums objectAtIndex:indexPath.row];
    NSMutableArray *photos = self.mutDictPhotos[albumName];
    cell.imageView.image =  [photos objectAtIndex:0];
    cell.textLabel.text = [NSString stringWithFormat:@"%@(%zi)",albumName,photos.count];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.iSelectedAlbumsIndex = indexPath.row;
    [self tapAlbumNavView];
    [self.collectionView  reloadData];
}

#pragma mark ----- Event ------
- (void)tapAlbumNavView
{
    if (self.tableView.hidden == YES)
    {
        self.tableView.hidden = NO;
        [self resetTitle];
        [UIView animateWithDuration:0.5f animations:^{
            self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
        }];
    }
    else
    {
        
        [UIView animateWithDuration:0.5f animations:^{
            self.tableView.frame = CGRectMake(0, 0 - self.tableView.frame.size.height, self.tableView.frame.size.width, self.tableView.frame.size.height);
        } completion:^(BOOL finished) {
            self.tableView.hidden = YES;
            [self resetTitle];
        }];
    }
}

- (void)touchUpInsideBtnBack
{
    // 取消选择
    [self.assetDelegate cancelSelectVideo];
    [self.albumsNavView removeFromSuperview];
    self.navigationController.navigationBarHidden = YES;
    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark ----- GET/SET ------
- (UITableView *)tableView
{
    if (!_tableView)
    {
        _tableView = ({
            UITableView *object = [[UITableView alloc] initWithFrame:CGRectMake(0, 0 - FU_SCREEN_HEIGHT, FU_SCREEN_WIDTH, FU_SCREEN_HEIGHT) style:UITableViewStylePlain];
            object.delegate = self;
            object.dataSource = self;
            object.tableFooterView = [[UIView alloc]init];
            object.separatorStyle = UITableViewCellSeparatorStyleNone;
            object;
        });
    }
    return _tableView;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView)
    {
        _collectionView = ({
            
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
            CGFloat itemWidth = (FU_SCREEN_WIDTH - 5) / 4.0;
            
            //设置单元格大小
            layout.itemSize = CGSizeMake(itemWidth, itemWidth);
            //最小行间距(默认为10)
            layout.minimumLineSpacing = 1;
            //最小item间距（默认为10）
            layout.minimumInteritemSpacing = 1;
            //设置UICollectionView的滑动方向
            layout.scrollDirection = UICollectionViewScrollDirectionVertical;
            //设置UICollectionView的间距
            layout.sectionInset = UIEdgeInsetsMake(1, 1, 1, 1);
            
            UICollectionView *object = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, FU_SCREEN_WIDTH, FU_SCREEN_HEIGHT) collectionViewLayout:layout];
            
            //遵循CollectionView的代理方法
            object.delegate = self;
            object.dataSource = self;
            
            object.backgroundColor = [UIColor whiteColor];
            //注册cell
            [object registerClass:[FUPhotoCollectionCell class] forCellWithReuseIdentifier:@"DiscoverRechangeCenterCell"];
            object;
        });
    }
    return _collectionView;
}

- (UIView *)albumsNavView
{
    if (!_albumsNavView)
    {
        _albumsNavView = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, EA_NAVIGATIONBAR_HEIGHT)];
            view.center = CGPointMake(FU_SCREEN_WIDTH/2, EA_NAVIGATIONBAR_HEIGHT/2);
            [view addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAlbumNavView)]];
            view;
        });
    }
    return _albumsNavView;
    
}

- (UILabel *)navTitle
{
    if (!_navTitle)
    {
        _navTitle = ({
            UILabel *object = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 0, EA_NAVIGATIONBAR_HEIGHT)];
            object.text = @"视频";
            object.font = [UIFont systemFontOfSize:17];
            object.textColor = [UIColor blackColor];
            [object sizeToFit];
            object.center = CGPointMake(50, EA_NAVIGATIONBAR_HEIGHT/2);
            
            object;
        });
    }
    return _navTitle;
}


- (UIImageView *)imgvwArrow
{
    if (!_imgvwArrow)
    {
        _imgvwArrow = ({
            UIImageView *object = UIImageView.new;
            
            
            object;
        });
    }
    return _imgvwArrow;
}

- (UIImageView *)imgvwNoPic
{
    if (!_imgvwNoPic)
    {
        _imgvwNoPic = ({
            UIImageView *object = UIImageView.new;
            object.image = [UIImage imageNamed:@"img_empty"];
            [object sizeToFit];
            object.center = self.view.center;
            
            object;
        });
    }
    return _imgvwNoPic;
}

- (UILabel *)lblNoPic
{
    if (!_lblNoPic)
    {
        _lblNoPic = ({
            UILabel *object = UILabel.new;
            object.text = @"相册没有视频，先去拍一段吧";
            object.font = [UIFont systemFontOfSize:14];
            object.textColor = [UIColor colorWithHexColorString:@"000000" alpha:0.45];
            [object sizeToFit];
            object.center = CGPointMake(self.view.center.x, self.view.center.y + 100);
            
            
            object;
        });
    }
    return _lblNoPic;
}

@end


@implementation FUPhotoCollectionCell

- (instancetype)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self)
    {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.imageView.backgroundColor = [UIColor redColor];
        [self.contentView addSubview:self.imageView];
        
        
        self.lblDuration = [[UILabel alloc]initWithFrame:CGRectMake(0, frame.size.height - 20, frame.size.width-2, 20)];
        self.lblDuration.font = [UIFont systemFontOfSize:12];
        self.lblDuration.textAlignment = NSTextAlignmentRight;
        self.lblDuration.textColor = [UIColor whiteColor];
        [self.contentView addSubview:self.lblDuration];
        
    }
    
    return self;
}
-(void)dealloc{
    NSLog(@"FUPhotoListViewController----销毁了");
}
@end

