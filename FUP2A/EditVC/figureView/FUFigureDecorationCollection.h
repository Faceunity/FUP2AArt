//
//  FUFigureDecorationCollection.h
//  FUFigureView
//
//  Created by L on 2019/4/10.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUFigureDefine.h"

@protocol FUFigureDecorationCollectionDelegate <NSObject>

@optional
- (void)decorationCollectionDidSelectedItem:(NSString *)itemName index:(NSInteger)index decorationType:(FUFigureDecorationCollectionType)type ;
- (void)decorationCollectionDidSelectedUpperItem:(NSString *)upperItemName lowerItem:(NSString *)lowerItemName;
@end

@interface FUFigureDecorationCollection : UICollectionView

@property (nonatomic, assign) FUFigureDecorationCollectionType currentType ;

@property (nonatomic, assign) id<FUFigureDecorationCollectionDelegate>mDelegate ;

@property (nonatomic, copy) NSString *hair ;
@property (nonatomic, strong) NSArray *hairArray ;
// 根据发型名称滚动到指定图标
-(void)scrollToTheHair:(NSString*)hair;

@property (nonatomic, copy) NSString *face ;
@property (nonatomic, strong) NSArray *faceArray ;

@property (nonatomic, copy) NSString *eyes ;
@property (nonatomic, strong) NSArray *eyesArray ;

@property (nonatomic, copy) NSString *mouth;
@property (nonatomic, strong) NSArray *mouthArray ;

@property (nonatomic, copy) NSString *nose ;
@property (nonatomic, strong) NSArray *noseArray ;

@property (nonatomic, copy) NSString *beard ;
@property (nonatomic, strong) NSArray *beardArray ;

@property (nonatomic, copy) NSString *eyeBrow ;
@property (nonatomic, strong) NSArray *eyeBrowArray ;

@property (nonatomic, copy) NSString *eyeLash ;
@property (nonatomic, strong) NSArray *eyeLashArray ;

@property (nonatomic, copy) NSString *hat ;
@property (nonatomic, strong) NSArray *hatArray ;

@property (nonatomic, copy) NSString *clothes ;
@property (nonatomic, strong) NSArray *clothesArray ;


@property (nonatomic, copy) NSString *upper;     // 当前上衣
@property (nonatomic, strong) NSArray *upperArray ;   // 上衣
@property (nonatomic, copy) NSString *lower ;     // 当前裤子
@property (nonatomic, strong) NSArray *lowerArray ;  // 裤子
@property (nonatomic, copy) NSString *shoes;
@property (nonatomic, strong) NSArray *shoesArray ;   // 鞋子
@property (nonatomic, strong) NSString *decorations ;  // 当前配饰
@property (nonatomic, strong) NSArray *decorationsArray ;  // 配饰
-(void)recoverCollectionViewUI;
- (void)loadDecorationData ;

@end

@interface FUFigureDecorationCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
