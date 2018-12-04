//
//  FULoadingView.m
//  FUP2A
//
//  Created by L on 2018/10/25.
//  Copyright © 2018年 L. All rights reserved.
//

#import "FULoadingView.h"

@interface FULoadingView ()
{
    FUGender gender ;
}
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIButton *maleBtn;
@property (weak, nonatomic) IBOutlet UIButton *femaleBtn;
@property (weak, nonatomic) IBOutlet UIImageView *loadingImage;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;

@property (nonatomic, strong) NSTimer *loadingTimer ;
@end

@implementation FULoadingView

-(void)awakeFromNib {
    [super awakeFromNib];
    gender = FUGenderUnKnow ;
}

// 选择性别
- (IBAction)genderSelected:(UIButton *)sender {

    if (gender == FUGenderUnKnow) {

        if (sender == self.maleBtn) {
            gender = FUGenderMale ;
        }else if (sender == self.femaleBtn){
            gender = FUGenderFemale ;
        }

        if (self.mDelegate && [self.mDelegate respondsToSelector:@selector(shouldCreateAvatarWithGender:)]) {
            [self.mDelegate shouldCreateAvatarWithGender:gender];
        }

        return ;
    }
}

// 开始加载
- (void)startLoading {
    self.tipLabel.hidden = YES ;
    self.maleBtn.hidden = YES ;
    self.femaleBtn.hidden = YES ;
    
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
    NSString *message = @"模型生成中";
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
    self.tipLabel.text = @"请选择性别" ;
    [self.maleBtn setImage:[UIImage imageNamed:@"camera-male"] forState:UIControlStateNormal];
    [self.femaleBtn setImage:[UIImage imageNamed:@"camera-female"] forState:UIControlStateNormal];
    
    self.tipLabel.hidden = NO ;
    self.maleBtn.hidden = NO ;
    self.femaleBtn.hidden = NO ;
    
    [self.loadingImage stopAnimating];
    self.loadingImage.hidden = YES ;
    
    gender = FUGenderUnKnow ;
}

@end
