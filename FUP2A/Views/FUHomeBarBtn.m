//
//  FUHomeBarBtn.m
//  FUP2A
//
//  Created by L on 2018/10/24.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FUHomeBarBtn.h"

@implementation FUHomeBarBtn

-(void)awakeFromNib {
    [super awakeFromNib];
    
    CGSize imageSize = self.imageView.frame.size ;
    CGSize titleSize = self.titleLabel.frame.size ;
    
    self.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, -imageSize.height - 5, 0) ;
    self.imageEdgeInsets = UIEdgeInsetsMake(-titleSize.height - 5, 0, 0, -titleSize.width) ;
}

@end
