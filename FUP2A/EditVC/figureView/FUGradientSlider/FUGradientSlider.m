//
//  FUGradientSlider.h
//  FUP2A
//
//  Created by LEE on 7/8/19.
//  Copyright © 2019 L. All rights reserved.
//


#import "FUGradientSlider.h"

#define defaultThickness 15.0f
#define defaultThumbSize 28.0f

@interface FUGradientSlider ()
{
	CGFloat currentValue, _thumbSize;
	CALayer *_thumbLayer;
	CAShapeLayer *_balloonLayer;
	CAGradientLayer *_trackLayer;
	CALayer *_thumbIconLayer;
	BOOL continuous;
}

@property (nonatomic, strong, readonly) CALayer *thumbLayer;
@property (nonatomic, strong, readonly) CAShapeLayer *balloonLayer;
@property (nonatomic, strong, readonly) CAGradientLayer *trackLayer;
@property (nonatomic, strong) CALayer *minTrackImageLayer;
@property (nonatomic, strong) CALayer *maxTrackImageLayer;
@property (nonatomic, strong, readonly) CALayer *thumbIconLayer;
@property (nonatomic, strong) UIColor *balloonColor;
@property (nonatomic, strong) UILabel *lblValue;

@end

@implementation FUGradientSlider
-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(self)
    {
		[self setDefaultValues];
		[self setup];
		self.value = 0;
		[self setNeedsDisplay];
	}
	return self;
}

-(instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
    {
		[self setDefaultValues];
		[self setup];
	}
	return self;
}

-(void)setDefaultValues
{
	_isRainbow = NO;
//    [self updateTrackColors];
	_minValue = 0.0;
	_maxValue = 1.0;
	
	_thickness = defaultThickness;
	currentValue = 0.0f;
	continuous = YES;
	_thumbSize = defaultThumbSize;
	_thumbBorderWidth = 5.0f;
	_thumbBorderColor = [UIColor whiteColor];
}

-(void)setup
{
	self.layer.delegate = self;
	[self.layer addSublayer:self.trackLayer];
	[self.layer addSublayer:self.thumbLayer];
	//    [self.layer addSublayer:self.balloonLayer];
	//    self.balloonLayer.hidden = YES;
	[self.thumbLayer addSublayer:self.thumbIconLayer];
	
	
}

-(CGSize) intrinsicContentSize
{
	return CGSizeMake(UIViewNoIntrinsicMetric, self.thumbSize);
}


-(UIEdgeInsets) alignmentRectInsets
{
	return UIEdgeInsetsMake(4.0, 2.0, 4.0, 2.0);
}

#pragma mark - layer

-(void)layoutSublayersOfLayer:(CALayer *)layer
{
	
	//[super layoutSublayersOfLayer:layer];
	
	if(layer != self.layer) {
		return;
	}
	
	CGFloat w = self.bounds.size.width;
	CGFloat h = self.bounds.size.height;
	CGFloat left = 2.0;
	
	CALayer *minImgLayer = _minTrackImageLayer;
	
	if(minImgLayer != nil)  {
		minImgLayer.position = CGPointMake(0.0, h/2.0);
		left = minImgLayer.bounds.size.width +13.0;
	}
	
	w -= left;
	
	
	
	CALayer *maxImgLayer = _maxTrackImageLayer;
	
	if(maxImgLayer != nil) {
		maxImgLayer.position = CGPointMake(self.bounds.size.width, h/2.0);
		w -= (maxImgLayer.bounds.size.width +13.0);
	}else{
		w -= 2.0;
	}
	
	
	_trackLayer.bounds = CGRectMake(0, 0, w, _thickness);
	_trackLayer.position = CGPointMake( w/2.0 + left, h/2.0);
	
	
	CGFloat halfSize = _thumbSize/2.0;
	CGFloat layerSize = _thumbSize - 4.0;
	
	UIImage *icon = _thumbIcon;
	
	if(icon) {
		layerSize = fmin(fmax(icon.size.height,icon.size.width),layerSize);
		_thumbIconLayer.cornerRadius = 0.0;
		_thumbIconLayer.backgroundColor = [UIColor whiteColor].CGColor;
	}
	else {
		_thumbIconLayer.cornerRadius = layerSize/2.0;
	}
	
	_thumbIconLayer.position = CGPointMake(halfSize, halfSize);
	_thumbIconLayer.bounds = CGRectMake(0, 0, layerSize, layerSize);
	[self updateThumbPosition:NO];
}

-(void) updateThumbPosition:(BOOL) animated
{
	CGFloat diff = _maxValue - _minValue;
	CGFloat perc = (currentValue - _minValue) / diff;
	
	CGFloat halfHeight = self.bounds.size.height / 2.0;
	CGFloat trackWidth = _trackLayer.bounds.size.width - _thumbSize;
	CGFloat left = _trackLayer.position.x - trackWidth/2.0;
	
	if (animated)
    {
		[CATransaction begin]; //Move the thumb position without animations
		[CATransaction setValue:@YES forKey: kCATransactionDisableActions];
		_thumbLayer.position = CGPointMake(left + (trackWidth * perc), halfHeight);
		_balloonLayer.position = CGPointMake(left + (trackWidth * perc),_balloonLayer.position.y);
        _lblValue.center = CGPointMake(left + (trackWidth * perc), _balloonLayer.position.y);
        UIColor *newColor = [[[FUManager shareInstance] getSkinColorWithProgress:self.value] valueForKey:@"color"];
		[self setThumbColor:newColor];
		//		[self setBalloonColor:newColor];
		self.balloonLayer.fillColor = newColor.CGColor;
		[CATransaction commit];
	}
    else
    {
		UIColor *newColor = [[[FUManager shareInstance] getSkinColorWithProgress:self.value] valueForKey:@"color"];
		[self setThumbColor:newColor];
		//		[self setBalloonColor:newColor];
		self.balloonLayer.fillColor = newColor.CGColor;
		_thumbLayer.position = CGPointMake(left + (trackWidth * perc), halfHeight);
		_balloonLayer.position = CGPointMake(left + (trackWidth * perc),_balloonLayer.position.y);
        _lblValue.center = CGPointMake(left + (trackWidth * perc), _balloonLayer.position.y);
	}
}

#pragma mark - delegate

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint pt = [touch locationInView:self];
	
	//  self.balloonLayer.hidden = NO;
	[self.layer addSublayer:self.balloonLayer];
    [self addSubview:self.lblValue];
//     [self bringSubviewToFront:self.lblValue];
	CGPoint center = _thumbLayer.position;
	CGFloat diameter = fmax(_thumbSize,44.0);
	CGRect r = CGRectMake(center.x - diameter/2.0, center.y - diameter/2.0, diameter,  diameter);
	if(CGRectContainsPoint(r, pt))
    {
		[self sendActionsForControlEvents:UIControlEventTouchDown];
		return YES;
	}
	return NO;
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	
	CGPoint pt = [touch locationInView:self];
	CGFloat newValue = [self valueForLocation:pt];
	[self setValue:newValue animated:NO];
	if(continuous)
    {
		[self sendActionsForControlEvents:UIControlEventValueChanged];
		if(self.actionBlock)
        {
			self.actionBlock(self,newValue, NO);
		}
	}
    self.lblValue.text = [NSString stringWithFormat:@"%0.0f",round(newValue*100)];
	return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	//   self.balloonLayer.hidden = YES;
	[self.balloonLayer removeFromSuperlayer];
    [self.lblValue removeFromSuperview];
   
	if(touch)
    {
		CGPoint pt = [touch locationInView:self];
		CGFloat newValue = [self valueForLocation:pt];
		[self setValue:newValue animated:NO];
	}
	//  [self layoutSubviews];
	if(self.actionBlock)
    {
		self.actionBlock(self,currentValue, YES);
	}
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    [self.delegate gradientSliderValueChangeFinished:self.value];

}



#pragma mark - properties

-(CGFloat)value
{
	return currentValue;
}

-(void)setValue:(CGFloat)value
{
	[self setValue:value animated:YES];
}

-(void)setValue:(CGFloat) value animated:(BOOL) animated {
	currentValue = fmax(fmin(value,self.maxValue),self.minValue);
    self.lblValue.text = [NSString stringWithFormat:@"%0.0f",round(currentValue*100)];
	[self updateThumbPosition:YES];
	//  [self layoutSubviews];
}

-(void)setThumbSize:(CGFloat)thumbSize {
	_thumbSize = thumbSize;
	_thumbLayer.cornerRadius = _thumbSize / 2.0;
	_thumbLayer.bounds = CGRectMake(0, 0, _thumbSize, _thumbSize);
	[self invalidateIntrinsicContentSize];
}


-(void)setThickness:(CGFloat)thickness {
	_thickness = thickness;
	_trackLayer.cornerRadius = thickness / 2.0;
	[self.layer setNeedsLayout];
}

-(void)setIsRainbow:(BOOL)isRainbow {
	_isRainbow = isRainbow;
	[self updateTrackColors];
}


-(UIColor *)thumbColor
{
	CGColorRef color = _thumbIconLayer.backgroundColor;
	if(color != nil) {
		return [UIColor colorWithCGColor:color];
	}
	return [UIColor whiteColor];
}

-(void)setThumbColor:(UIColor *)thumbColor {
	_thumbIconLayer.backgroundColor = thumbColor.CGColor;
}
-(void)setBalloonColor:(UIColor *)balloonColor{
	_balloonColor = balloonColor;
	_balloonLayer.backgroundColor = balloonColor.CGColor;
}
-(void)setThumbBorderWidth:(CGFloat)thumbBorderWidth {
	_thumbLayer.borderWidth = thumbBorderWidth;
}

-(void)setThumbBorderColor:(UIColor *)thumbBorderColor {
	_thumbLayer.borderColor = thumbBorderColor.CGColor;
}

-(void)setTrackBorderWidth:(CGFloat)trackBorderWidth {
	_trackLayer.borderWidth = trackBorderWidth;
}

-(void)setTrackBorderColor:(UIColor *)trackBorderColor {
	_trackLayer.borderColor = trackBorderColor.CGColor;
}



-(UIBezierPath*)drawBalloonPath:(CGPoint)center{
	float _radius = 22;
	CGPoint CurveCenterPoint = center;
	UIBezierPath *path = [UIBezierPath bezierPath];
	
	
	
	//Curve1
	CGPoint Curve1BeginPoint = CGPointMake(CurveCenterPoint.x, CurveCenterPoint.y - _radius);
	CGPoint Curve1BeginControlPoint = CGPointMake(CurveCenterPoint.x + _radius / 2.0, CurveCenterPoint.y - _radius);
	CGPoint Curve1EndPoint = CGPointMake(CurveCenterPoint.x + _radius, CurveCenterPoint.y);
	CGPoint Curve1EndControlPoint = CGPointMake(CurveCenterPoint.x + _radius, CurveCenterPoint.y - _radius / 2.0);
	[path moveToPoint:Curve1BeginPoint];
	[path addCurveToPoint:Curve1EndPoint controlPoint1:Curve1BeginControlPoint controlPoint2:Curve1EndControlPoint];
	[path addLineToPoint:center];
	//Curve2
	CGPoint Curve2BeginPoint = Curve1EndPoint;
	CGPoint Curve2BeginControlPoint = CGPointMake(CurveCenterPoint.x + _radius, CurveCenterPoint.y + _radius / 2.0);
	CGPoint Curve2EndPoint = CGPointMake(CurveCenterPoint.x, CurveCenterPoint.y + _radius + 15);
	CGPoint Curve2EndControlPoint = CGPointMake(CurveCenterPoint.x + _radius, CurveCenterPoint.y + _radius);
	[path moveToPoint:Curve2BeginPoint];
	[path addCurveToPoint:Curve2EndPoint controlPoint1:Curve2BeginControlPoint controlPoint2:Curve2EndControlPoint];
	[path addLineToPoint:center];
	//Curve3
	CGPoint Curve3BeginPoint = Curve2EndPoint;
	CGPoint Curve3BeginControlPoint = CGPointMake(CurveCenterPoint.x - _radius, CurveCenterPoint.y + _radius);
	CGPoint Curve3EndPoint = CGPointMake(CurveCenterPoint.x - _radius, CurveCenterPoint.y);
	CGPoint Curve3EndControlPoint = CGPointMake(CurveCenterPoint.x - _radius, CurveCenterPoint.y + _radius / 2.0);
	[path moveToPoint:Curve3BeginPoint];
	[path addCurveToPoint:Curve3EndPoint controlPoint1:Curve3BeginControlPoint controlPoint2:Curve3EndControlPoint];
	[path addLineToPoint:center];
	//Curve4
	CGPoint Curve4BeginPoint = Curve3EndPoint;
	CGPoint Curve4BeginControlPoint = CGPointMake(CurveCenterPoint.x - _radius, CurveCenterPoint.y - _radius / 2.0);
	CGPoint Curve4EndPoint = Curve1BeginPoint;
	CGPoint Curve4EndControlPoint = CGPointMake(CurveCenterPoint.x - _radius / 2.0, CurveCenterPoint.y - _radius);
	[path moveToPoint:Curve4BeginPoint];
	[path addCurveToPoint:Curve4EndPoint controlPoint1:Curve4BeginControlPoint controlPoint2:Curve4EndControlPoint];
	[path addLineToPoint:center];
	
	
	
	path.lineWidth =2;
	//    UIColor *color = [UIColor orangeColor];
	//   [color set];
	//   [path fill];
	return path;
	
	
}

#pragma mark - private

-(CGFloat)valueForLocation:(CGPoint) point
{
	CGFloat left = self.bounds.origin.x;
	CGFloat w = self.bounds.size.width;
	
	CALayer *minImgLayer = _minTrackImageLayer;
	if (minImgLayer) {
		CGFloat amt = minImgLayer.bounds.size.width + 13.0;
		w -= amt;
		left += amt;
	} else {
		w -= 2.0;
		left += 2.0;
	}
	
	CALayer *maxImgLayer = _maxTrackImageLayer;
	if (maxImgLayer) {
		w -= (maxImgLayer.bounds.size.width + 13.0);
	}else{
		w -= 2.0;
	}
	
	CGFloat diff = self.maxValue - self.minValue;
	
	CGFloat perc = fmax(fmin((point.x - left) / w ,1.0), 0.0);
	
	return (perc * diff) + self.minValue;
}

-(void)updateTrackColors {
	if(_isRainbow) {
		
		CGFloat h = 0.0;
		CGFloat s = 0.0;
		CGFloat l = 0.0;
		CGFloat a = 1.0;
		
		
		CGFloat cnt = 10.0f;
		CGFloat step = 1.0f / cnt;
		
		NSMutableArray *colors = [NSMutableArray new];
		NSMutableArray<NSNumber*> *locations = [NSMutableArray new];
		for (CGFloat f = 0.0; f<cnt; f+=step) {
			[locations addObject:@(step*f)];
			[colors addObject:(id)[UIColor colorWithHue:step*f saturation:s brightness:l alpha:a].CGColor];
		}
		if(colors.count > 0) {
			_trackLayer.colors = [colors copy];
		}
		if(locations.count > 0) {
			_trackLayer.locations = [locations copy];
		}
		
	}
	else {
		//    _trackLayer.colors = @[(id)_minColor.CGColor, (id)_maxColor.CGColor];
//		int colorsCount = [FUManager shareInstance].skinColorArray.count;
        NSInteger colorsCount = [[FUManager shareInstance] getColorArrayCountWithType:FUFigureColorTypeSkinColor];
		double step = 1.0/(colorsCount - 1);
		NSMutableArray * colorsArrary = [NSMutableArray array];
		NSMutableArray * locationsArray = [NSMutableArray array];
		for (int i = 0; i < colorsCount; i++) {
			FUP2AColor * avatarColor = [[FUManager shareInstance]getColorWithType:FUFigureColorTypeSkinColor andIndex:i];
			UIColor * color = avatarColor.color;
			[colorsArrary addObject:(id)color.CGColor];
			[locationsArray addObject:@(i * step)];
		}
		_trackLayer.colors = colorsArrary; 
		_trackLayer.locations = locationsArray;
	}
}

-(UIColor *)valueColor
{
	if(_isRainbow){
		CGFloat diff = _maxValue - _minValue;
		if(diff != 0) {
			return  [UIColor colorWithHue:currentValue/diff saturation:1.0 brightness:1.0 alpha:1.0];
		}
	}
	return [UIColor whiteColor];
}

#pragma mark ------ GET/SET ------
-(CAGradientLayer*)trackLayer
{
    if(!_trackLayer) {
        _trackLayer = [CAGradientLayer new];
        _trackLayer.cornerRadius = defaultThickness / 2.0;
        _trackLayer.startPoint = CGPointMake(0.0, 0.5);
        _trackLayer.endPoint = CGPointMake(1.0, 0.5);
        _trackLayer.locations = @[@0.0,@1.0];
        _trackLayer.colors = @[(id)[UIColor blueColor].CGColor,(id)[UIColor orangeColor].CGColor];
        _trackLayer.borderColor = [UIColor blackColor].CGColor;
    }
    return _trackLayer;
}

-(CALayer*)thumbIconLayer
{
    
    if(!_thumbIconLayer) {
        CGFloat size = defaultThumbSize - 4;
        _thumbIconLayer = [CALayer new];
        _thumbIconLayer.cornerRadius = size/2.0;
        _thumbIconLayer.bounds = CGRectMake(0, 0, size, size);
        _thumbIconLayer.backgroundColor = [UIColor whiteColor].CGColor;
    }
    return _thumbIconLayer;
}

-(CALayer*)thumbLayer
{
    if(!_thumbLayer) {
        _thumbLayer = [CALayer new];
        _thumbLayer.cornerRadius = defaultThumbSize/2.0;
        _thumbLayer.bounds = CGRectMake(0, 0, defaultThumbSize, defaultThumbSize);
        _thumbLayer.backgroundColor = [UIColor whiteColor].CGColor;
        _thumbLayer.borderColor = _thumbBorderColor.CGColor;
        _thumbLayer.borderWidth = _thumbBorderWidth;
    }
    return _thumbLayer;
}

-(CAShapeLayer *)balloonLayer{
    if (!_balloonLayer) {
        _balloonLayer = [CAShapeLayer layer];
        CGFloat balloonLayerX = 0;
        CGFloat balloonLayerY = -50;
        CGFloat balloonLayerW = 44;
        CGFloat balloonLayerH = 52;
        
        CGFloat balloonLayerCenterX = balloonLayerW / 2.0;
        CGFloat balloonLayerCenterY = balloonLayerCenterX;
        
        
        _balloonLayer.frame = CGRectMake(balloonLayerX,balloonLayerY, balloonLayerW, balloonLayerH);
        _balloonLayer.path = [self drawBalloonPath:CGPointMake(balloonLayerCenterX, balloonLayerCenterY)].CGPath;
    }
    return _balloonLayer;
}

- (UILabel *)lblValue
{
    if (!_lblValue)
    {
        _lblValue = ({
            UILabel *object = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 44, 52)];
            object.text = @"1";
            object.font = [UIFont systemFontOfSize:17];
            object.textColor = [UIColor whiteColor];
            object.textAlignment = NSTextAlignmentCenter;
            object;
        });
    }
    return _lblValue;
}

@end
