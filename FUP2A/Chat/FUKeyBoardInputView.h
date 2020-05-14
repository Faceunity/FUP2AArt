//
//  FUKeyBoardInputView.h
//  FUStaLiteDemo
//
//  Created by LEE on 4/2/19.
//  Copyright © 2019 ly-Mac. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "FUPlaceholderTextView.h"

typedef NS_ENUM(NSInteger,FUInputType) {
    Voice,
    Text,
    Music
};

/**
 底部按钮点击的五种状态
 
 - FUChatBottomTypeDefault: 默认在底部的状态
 - FUChatBottomTypeVoice: 准备发语音的状态
 - FUChatBottomTypeEdit: 准备编辑文本的状态
 - FUChatBottomTypeSymbol: 准备发送表情的状态
 - FUChatBottomTypeAdd: 准备发送其他功能的状态
 */
typedef NS_ENUM(NSInteger,FUChatKeyBoardStatus) {
    FUChatKeyBoardStatusDefault=1,
    FUChatKeyBoardStatusVoice,
    FUChatKeyBoardStatusEdit,
    FUChatKeyBoardStatusSymbol,
    FUChatKeyBoardStatusAdd,
};

/**
 聊天界面底部的输入框视图
 */

#define FUKeyBoardInputViewH      56     //输入部分的高度


@class FUKeyBoardInputView;




@interface FUKeyBoardInputView : UIView<UITextViewDelegate,AVAudioRecorderDelegate>



//键盘或者 表情视图 功能视图的高度
@property(nonatomic,assign)CGFloat changeTime;
@property(nonatomic,assign)CGFloat keyBoardHieght;

//当前的编辑状态（默认 语音 编辑文本 发送表情 其他功能）
@property(nonatomic,assign)FUChatKeyBoardStatus keyBoardStatus;

//顶部线条
@property(nonatomic,strong) UIView   *topLine;


@property(nonatomic,strong) UIButton *mBackBtn;

@property(nonatomic,strong) FUPlaceholderTextView   *mTextView;
@property(nonatomic,strong) NSString     *textString;





@property (nonatomic, copy)void (^showOrHideBlock)(BOOL,float);     // 键盘弹起
@property (nonatomic, copy)void (^textBlock)(NSString*);
@property (nonatomic, copy)void (^exitFromKeyBoardInput)(void);
-(instancetype)initWithType:(FUInputType)type;
-(void)setVoiceTouchBeginAction:(void (^)(void))touchBegin willTouchCancelAction:(void (^)(BOOL))willTouchCancel touchEndAction:(void (^)(void))touchEnd touchCancelAction:(void (^)(void))touchCancel;
-(void)sendText:(void (^)(NSString*))textBlock;
// 隐藏键盘
/// return 隐藏之前键盘是否已弹起
-(BOOL)hideKeyboard;
@end







