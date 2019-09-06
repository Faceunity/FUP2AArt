//
//  FUAvatarEditedDoModel.h
//  FUP2A
//
//  Created by LEE on 8/8/19.
//  Copyright © 2019 L. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, FUAvatarEditedDoModelType){
    Hair                     = 0,
    HairColor,
	SkinColorProgress,
    Face,
    Eyes,
    IrisLevel,
    Mouth,
    LipsLevel,
    Nose,
    Beard,
    Glasses,
    GlassColorIndex,
    GlassFrameColorIndex,
	Hat,
    EyeBrow,
    EyeLash,

    Clothes,
    Shoes
} ;
@interface FUAvatarEditedDoModel : NSObject
@property (nonatomic,strong)NSObject * obj;
@property (nonatomic,assign)FUAvatarEditedDoModelType type;
@end

NS_ASSUME_NONNULL_END
