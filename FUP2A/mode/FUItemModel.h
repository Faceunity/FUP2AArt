//
//  FUItemModel.h
//  FUP2A
//
//  Created by Chen on 2020/1/16.
//  Copyright © 2020 L. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUItemModel : NSObject<NSCopying,NSCoding>

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
- (BOOL)isEqualToBGModel:(FUItemModel *)model;
@end

NS_ASSUME_NONNULL_END
