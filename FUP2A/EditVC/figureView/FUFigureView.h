//
//  FUFigureView.h
//  FUFigureView
//
//  Created by L on 2019/4/8.
//  Copyright © 2019 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FUP2AColor ;
@protocol FUFigureViewDelegate <NSObject>

@optional
// 页面类型选择
- (void)figureViewDidSelectedTypeWithIndex:(NSInteger)typeIndex;
// 隐藏全部子页面
- (void)figureViewDidHiddenAllTypeViews;
//// 重置
-(void)reset:(UIButton*)btn;
//// 撤销
-(void)undo:(UIButton*)btn;
// 重做
-(void)redo:(UIButton*)btn;

@end

@interface FUFigureView : UIView

#pragma mark --- data source
@property (nonatomic, assign) id<FUFigureViewDelegate>delegate ;

- (void)setupFigureView ;
//-(void)resetUI;
/**
 当touchMove的时候，判断是否需要隐藏view
 */
-(void)shouldHidePartViews;

- (void)updateSliderWithValue:(double)value;
- (void)reloadTopCollection;
@end
