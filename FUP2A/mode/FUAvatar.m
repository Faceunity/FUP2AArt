//
//  FUAvatar.m
//  FU P2A
//
//  Created by 刘洋 on 2017/3/14.
//  Copyright © 2017年 刘洋. All rights reserved.
//

#import "FUAvatar.h"
#import "FUP2ADefine.h"

@interface FUAvatar ()

@property (nonatomic, copy) NSString *imageName;
@end

@implementation FUAvatar

- (void)setTime:(NSString *)time
{
    _time = time;
    _bundleName = @"head.bundle";
    _imageName = @"image.png";
}

-(NSString *)bundleName {
    if (!_bundleName) {
        _bundleName = @"head.bundle" ;
    }
    return _bundleName ;
}

- (NSString *)bundlePath{
    if (!_bundlePath) {
        return [[self avatarPath] stringByAppendingPathComponent:_bundleName];
    }
    return _bundlePath ;
}

-(NSString *)imageName {
    if (!_imageName) {
        return @"image.png" ;
    }
    return _imageName ;
}

- (NSString *)imagePath
{
    if (!_imagePath) {
        
        return [[self avatarPath] stringByAppendingPathComponent:self.imageName];
    }
    return _imagePath ;
}

- (NSString *)avatarPath
{
    return [documentPath stringByAppendingPathComponent:_time];
}

- (void)encodeWithCoder:(NSCoder *)aCoder   {
    
    [aCoder encodeBool:_isMale forKey:@"isMale"];
    [aCoder encodeObject:_time forKey:@"time"];
    [aCoder encodeObject:_hairArr forKey:@"hairArr"];
    [aCoder encodeObject:_defaultHair forKey:@"defaultHair"];
    [aCoder encodeObject:_defaultClothes forKey:@"defaultClothes"];
    [aCoder encodeObject:_defaultGlasses forKey:@"defaultGlasses"];
    [aCoder encodeObject:_defaultBeard forKey:@"defaultBeard"];
    [aCoder encodeObject:_defaultHat forKey:@"defaultHat"];
    
    [aCoder encodeDouble:_hairLabel forKey:@"hairLabel"];
    [aCoder encodeDouble:_bearLabel forKey:@"bearLabel"];
    [aCoder encodeInt:_matchLabel forKey:@"matchLabel"];
    
    [aCoder encodeObject:_skinColor forKey:@"skinColor"];
    [aCoder encodeDouble:_skinLevel forKey:@"skinLevel"];
    [aCoder encodeObject:_lipColor forKey:@"lipColor"];
    [aCoder encodeObject:_serverSkinColor forKey:@"serverSkinColor"];
    [aCoder encodeObject:_serverLipColor forKey:@"serverLipColor"];
    [aCoder encodeObject:_irisColor forKey:@"irisColor"];
    [aCoder encodeObject:_hairColor forKey:@"hairColor"];
    [aCoder encodeObject:_glassColor forKey:@"glassColor"];
    [aCoder encodeObject:_glassFrameColor forKey:@"glassFrameColor"];
    [aCoder encodeObject:_beardColor forKey:@"beardColor"];
    [aCoder encodeObject:_hatColor forKey:@"hatColor"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.time = [aDecoder decodeObjectForKey:@"time"];
        self.isMale = [aDecoder decodeBoolForKey:@"isMale"];
        self.hairArr = [aDecoder decodeObjectForKey:@"hairArr"];
        self.defaultHair = [aDecoder decodeObjectForKey:@"defaultHair"];
        self.defaultClothes = [aDecoder decodeObjectForKey:@"defaultClothes"];
        self.defaultGlasses = [aDecoder decodeObjectForKey:@"defaultGlasses"];
        self.defaultBeard = [aDecoder decodeObjectForKey:@"defaultBeard"];
        self.defaultHat = [aDecoder decodeObjectForKey:@"defaultHat"];
        
        self.hairLabel = [aDecoder decodeDoubleForKey:@"hairLabel"];
        self.bearLabel = [aDecoder decodeDoubleForKey:@"bearLabel"];
        self.matchLabel = [aDecoder decodeIntForKey:@"matchLabel"];
        
        self.skinColor = [aDecoder decodeObjectForKey:@"skinColor"];
        self.skinLevel = [aDecoder decodeDoubleForKey:@"skinLevel"];
        self.lipColor = [aDecoder decodeObjectForKey:@"lipColor"];
        self.serverSkinColor = [aDecoder decodeObjectForKey:@"serverSkinColor"];
        self.serverLipColor = [aDecoder decodeObjectForKey:@"serverLipColor"];
        self.irisColor = [aDecoder decodeObjectForKey:@"irisColor"];
        self.hairColor = [aDecoder decodeObjectForKey:@"hairColor"];
        self.glassColor = [aDecoder decodeObjectForKey:@"glassColor"];
        self.glassFrameColor = [aDecoder decodeObjectForKey:@"glassFrameColor"];
        self.beardColor = [aDecoder decodeObjectForKey:@"beardColor"];
        self.hatColor = [aDecoder decodeObjectForKey:@"hatColor"];
    }
    return self;
}

@end
