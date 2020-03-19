//
//  FUPlaceholderTextView.h
//  FUStaLiteDemo
//
//  Created by LEE on 4/2/19.
//  Copyright © 2019 ly-Mac. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FUPlaceholderTextView : UITextView
@property(nonatomic,strong)NSString * placeholder;
@property(nonatomic,strong)UIColor * placeholderColor;
-(void)recover;

@end

NS_ASSUME_NONNULL_END
