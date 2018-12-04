//
//  FUFigureView.h
//  EditView
//
//  Created by L on 2018/11/2.
//  Copyright © 2018年 L. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FUFigureColor ;
@protocol FUFigureViewDelegate <NSObject>

@optional
// 美型参数改变
- (void)figureViewResetAllShapeParams;
- (void)figureViewShapeParamsDidChangedWithKey:(NSString *)key level:(double)level ;
// 肤色参数改变
- (void)figureViewSkinColorDidChangedCurrentColor:(FUFigureColor *)curColor nextColor:(FUFigureColor *)nextColor scale:(double)scale ; ;
// 唇色参数改变
- (void)figureViewLipColorDidChanged ;
// 瞳色参数改变
- (void)figureViewIrisColorDidChanged ;
// 发色改变
- (void)figureViewDiaChangeHairColor ;
// 发型改变
- (void)figureViewDiaChangeHair:(NSString *)hairName ;
// 镜片改变
- (void)figureViewDiaChangeGlassesColor ;
// 镜框改变
- (void)figureViewDiaChangeGlassesFrameColor ;
// 眼镜改变
- (void)figureViewDiaChangeGlasses:(NSString *)glassesName ;
// 胡色改变
- (void)figureViewDiaChangeBeardColor ;
// 胡子改变
- (void)figureViewDiaChangeBeard:(NSString *)beardName ;
// 衣服改变
- (void)figureViewDiaChangeCloth:(NSString *)clothName ;
// 帽子改变
- (void)figureViewDiaChangeHat:(NSString *)hatName ;
// 帽子颜色改变
- (void)figureViewDiaChangeHatColor ;
@end


@interface FUFigureView : UIView

@property (nonatomic, assign) id<FUFigureViewDelegate>delegate ;

@property (nonatomic, assign) double skinLevel ;
@property (nonatomic, strong) FUFigureColor *skinColor ;
@property (nonatomic, assign) double lipLevel ;
@property (nonatomic, strong) FUFigureColor *lipColor ;
@property (nonatomic, assign) double irisLevel ;
@property (nonatomic, strong) FUFigureColor *irisColor ;

@property (nonatomic, assign) NSInteger hairColorIndex ;
@property (nonatomic, strong) FUFigureColor *hairColor ;

@property (nonatomic, copy) NSString *currentHair ;

@property (nonatomic, assign) double glassesLevel ;
@property (nonatomic, strong) FUFigureColor *glassesColor ;
@property (nonatomic, assign) double glassesFrameLevel ;
@property (nonatomic, strong) FUFigureColor *glassesFrameColor ;
@property (nonatomic, copy) NSString *currentGlasses ;

@property (nonatomic, assign) double beardLevel ;
@property (nonatomic, strong) FUFigureColor *beardColor ;
@property (nonatomic, strong) FUFigureColor *hatColor ;
@property (nonatomic, copy) NSString *currentBeard ;
@property (nonatomic, copy) NSString *currentCloth ;
@property (nonatomic, copy) NSString *currentHat ;

// face shape value
@property (nonatomic, assign) double headShrink ;
@property (nonatomic, assign) double headBoneStretch  ;
@property (nonatomic, assign) double cheekNarrow ;
@property (nonatomic, assign) double jawboneNarrow ;
@property (nonatomic, assign) double jawLower ;
// eye shape value
@property (nonatomic, assign) double eyeUp ;
@property (nonatomic, assign) double eyeOutterUp  ;
@property (nonatomic, assign) double eyeClose ;
@property (nonatomic, assign) double eyeBothIn ;
// mouth shape value
@property (nonatomic, assign) double mouthUp ;
@property (nonatomic, assign) double upperLipThick  ;
@property (nonatomic, assign) double lowerLipThick ;
@property (nonatomic, assign) double lipCornerIn ;
// nose shape value
@property (nonatomic, assign) double noseUp ;
@property (nonatomic, assign) double nostrilIn  ;
@property (nonatomic, assign) double noseTipUp ;


// data source
@property (nonatomic, strong) NSArray *skinColorArray ;
@property (nonatomic, strong) NSArray *lipColorArray ;
@property (nonatomic, strong) NSArray *irisColorArray ;
@property (nonatomic, strong) NSArray *hairColorArray ;
@property (nonatomic, strong) NSArray *beardColorArray ;
@property (nonatomic, strong) NSArray *glassFrameArray ;
@property (nonatomic, strong) NSArray *glassColorArray ;
// defauly value
@property (nonatomic, assign) int defaultSkinLevel ;
@property (nonatomic, assign) int defaultLipLevel ;
@property (nonatomic, assign) int defaultIrisLevel ;

- (void)setupFigureView ;

- (BOOL)figureViewIsChange ;
@end


#pragma mark ---- middle cell
@interface FUFigureMiddleCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;
@end

#pragma mark ---- bottom cell
@interface FUFigureBottomCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end
