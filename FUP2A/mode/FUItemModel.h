//
//  FUItemModel.h
//  FUP2A
//
//  Created by Chen on 2020/1/16.
//  Copyright © 2020 L. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUItemModel : NSObject<NSCopying>

@property (nonatomic, strong) NSString *type; //道具类别
@property (nonatomic, strong) NSString *path; //道具目录所在路径
@property (nonatomic, strong) NSString *name; //道具名称
@property (nonatomic, strong) NSString *bundle; //道具bundle的相对路径
@property (nonatomic, strong) NSString *icon;  //道具icon的相对路径
@property (nonatomic, strong) NSArray *label;
@property (nonatomic, strong) NSNumber *gender;
@property (nonatomic, strong) NSNumber *gender_match; //适合性别
@property (nonatomic, strong) NSNumber *body_match_level; //所需身体登记
@property (nonatomic, strong) NSMutableDictionary *shapeDict;  //脸部点位信息
- (NSString *)getBundlePath;
- (NSString *)getIconPath;
@end

// 专用于美妆的类型，因为含有多选
@interface FUMakeupItemModel : FUItemModel   // 美妆模型
@property (nonatomic, strong,readonly) NSString *title;
@end
// 专用于美妆的类型的空选项
@interface FUMakeupNoItemModel : FUMakeupItemModel   // 美妆模型
-(instancetype)initWithItemModel:(FUMakeupItemModel*)model;
@end
// 专用于配饰的类型，因为含有多选
@interface FUDecorationItemModel : FUItemModel   // 配饰
@property (nonatomic, strong,readonly) NSString *title;
@end
@interface FUDecorationNoItemModel : FUItemModel   // 配饰类型的空选项
-(instancetype)initWithItemModel:(FUDecorationItemModel*)model;
@end

typedef enum : NSInteger {
    FUMultipleRecordItemModelTypeMakeup,    // 美妆
    FUMultipleRecordItemModelTypeDecorations,  // 配饰
    FUMultipleRecordItemModelTypeMutualExclusion  // 互斥 ，用于头发、发帽、头饰 之间的撤销回退工作
} FUMultipleRecordItemModelType; // 用于记录多选model 的类型
/// 多选美妆类型的记录，用于撤销回退时
@interface FUMultipleRecordItemModel : FUItemModel
-(instancetype)initWithItemModel:(FUMakeupItemModel*)model;
@property (nonatomic, strong)NSArray*multipleSelectedArr;
@property (nonatomic, assign,readonly) FUMultipleRecordItemModelType recordType;
@end
NS_ASSUME_NONNULL_END
