//
//  FUPhotoLoadingView.m
//  FUP2A
//
//  Created by LEE on 6/25/19.
//  Copyright © 2019 L. All rights reserved.
//

#import "FUPhotoLoadingView.h"
@interface FUPhotoLoadingView()
{
    FUGender gender ;
}
@property (weak, nonatomic) IBOutlet UIButton *maleBtn;
@property (weak, nonatomic) IBOutlet UIButton *femaleBtn;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;

@end


@implementation FUPhotoLoadingView


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
	
	[super startLoading];
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
	

    self.tipLabel.text = @"请选择性别" ;
    [self.maleBtn setImage:[UIImage imageNamed:@"camera-male"] forState:UIControlStateNormal];
    [self.femaleBtn setImage:[UIImage imageNamed:@"camera-female"] forState:UIControlStateNormal];
	
    self.maleBtn.hidden = NO ;
    self.femaleBtn.hidden = NO ;
	self.tipLabel.text = @"请选择性别" ;
    self.tipLabel.hidden = NO ;
    [super stopLoading];
	
    gender = FUGenderUnKnow ;
}

@end

