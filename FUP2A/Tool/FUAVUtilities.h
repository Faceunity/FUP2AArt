#import <Foundation/Foundation.h>

@class AVAsset;

@interface FUAVUtilities : NSObject

+ (AVAsset *)assetByReversingAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL;

@end
