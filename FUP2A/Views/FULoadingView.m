//
//  FULoadingView.m
//  FUP2A
//
//  Created by L on 2018/10/25.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FULoadingView.h"

@interface FULoadingView ()


@property (nonatomic, strong) NSTimer *loadingTimer ;
@property (nonatomic, strong) NSString *loadingString;
@end
@implementation FULoadingView
-(void)awakeFromNib{
   [super awakeFromNib];
	self.loadingString = self.loadingLabel.text;
}
// 开始加载
- (void)startLoading {
 
  
    self.loadingImage.hidden = NO ;
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:1];
    for (int i = 1; i < 33; i ++) {
        NSString *imageName = [NSString stringWithFormat:@"loading%d.png", i];
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
        [images addObject:image ];
    }
    self.loadingImage.animationImages = images ;
    self.loadingImage.animationRepeatCount = 0 ;
    self.loadingImage.animationDuration = 2.0 ;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loadingImage startAnimating];
        self.loadingLabel.hidden = NO ;
        self.loadingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateLoadingLabel) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.loadingTimer forMode:NSRunLoopCommonModes];
    });
}

- (void)updateLoadingLabel {
    static int num = 0 ;
    num ++ ;
    if (num == 4) {
        num = 0 ;
    }
    NSString *message = self.loadingString;
    for (int i = 0 ; i < num; i ++) {
        message = [message stringByAppendingString:@"."];
    }
    self.loadingLabel.text = message ;
}



// 停止加载
- (void)stopLoading {
    
    self.loadingLabel.hidden = YES ;
    [self.loadingTimer invalidate];
    self.loadingTimer = nil ;

    
    [self.loadingImage stopAnimating];
    self.loadingImage.hidden = YES ;
}

@end
