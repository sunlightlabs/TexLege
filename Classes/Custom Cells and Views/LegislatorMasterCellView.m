//
//	LegislatorMasterCellView.m
//  Created by Gregory Combs on 8/29/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorMasterCellView.h"
#import "LegislatorObj+RestKit.h"
#import "TexLegeTheme.h"
#import "PartisanIndexStats.h"

const CGFloat kLegislatorMasterCellViewWidth = 234.0f;
const CGFloat kLegislatorMasterCellViewHeight = 73.0f;

@implementation LegislatorMasterCellView

@synthesize title;
@synthesize name;
@synthesize tenure;
@synthesize sliderValue, sliderMin, sliderMax, partisan_index;
@synthesize useDarkBackground;
@synthesize highlighted, questionImage;

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		title = [@"Representative - (D-23)" retain];
		name = [@"Rafael Anchía" retain];
		tenure = [@"4 Years" retain];
		sliderValue = 0.0f, partisan_index = 0.0f;
		sliderMin = -1.5f;
		sliderMax = 1.5f;
		questionImage = nil;
		
		[self setOpaque:YES];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
        [self configure];
	}
	return self;
}

- (void) awakeFromNib {
	[super awakeFromNib];
    [self configure];
}

- (void)configure
{
    sliderValue = 0.0f;
    partisan_index = 0.0f;
	sliderMin = -1.5f;
	sliderMax = 1.5f;
	[self setOpaque:YES];
}
- (void)dealloc
{
	nice_release(questionImage);
	nice_release(title);
	nice_release(name);
	nice_release(tenure);
	[super dealloc];
}

- (void)setSliderValue:(CGFloat)value
{
	sliderValue = value;
		
	if (sliderValue == 0.0f) {	// this gives us the center, in cases of no roll call scores
		sliderValue = (sliderMin + sliderMin)/2;
	}
	
	if (sliderMax > (-sliderMin))
		sliderMin = (-sliderMax);
	else
		sliderMax = (-sliderMin);
		
#define	kStarAtDemoc 0.5f
#define kStarAtRepub 162.0f
#define	kStarAtHalf 81.5f
#define kStarMagnifierBase (kStarAtRepub - kStarAtDemoc)
	
	CGFloat magicNumber = (kStarMagnifierBase / (sliderMax - sliderMin));
	CGFloat offset = kStarAtHalf;
		
	sliderValue = sliderValue * magicNumber + offset;
	
	//[self setNeedsDisplay];
}


- (CGSize)sizeThatFits:(CGSize)size
{
	return CGSizeMake(kLegislatorMasterCellViewWidth, kLegislatorMasterCellViewHeight);
}

- (void)setUseDarkBackground:(BOOL)flag
{
	if (self.highlighted)
		return;
	
	useDarkBackground = flag;
	
	UIColor *labelBGColor = (useDarkBackground) ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	self.backgroundColor = labelBGColor;
	[self setNeedsDisplay];
}

- (BOOL)highlighted{
	return highlighted;
}

- (void)setHighlighted:(BOOL)flag
{
	if (highlighted == flag)
		return;
	highlighted = flag;
	
	[self setNeedsDisplay];
}

- (void)setLegislator:(LegislatorObj *)value
{
    if (!value)
    {
        self.partisan_index = 0;
        self.title = nil;
        self.name = nil;
        self.tenure = nil;
        self.sliderMax = 1;
        self.sliderMin = -1;
        self.sliderValue = 0;
        [self setNeedsDisplay];
        return;
    }
	self.partisan_index = value.latestWnomFloat;
    self.title = [value.legtype_name stringByAppendingFormat:@" - %@", [value districtPartyString]];
	self.name = [value legProperName];
	self.tenure = [value tenureString];
		
	PartisanIndexStats *indexStats = [PartisanIndexStats sharedPartisanIndexStats];
	CGFloat minSlider = [indexStats minPartisanIndexUsingChamber:[value.legtype integerValue]];
	CGFloat maxSlider = [indexStats maxPartisanIndexUsingChamber:[value.legtype integerValue]];
	self.sliderMax = maxSlider;
	self.sliderMin = minSlider;	
	[self setSliderValue:self.partisan_index];
	
	[self setNeedsDisplay];	
}

- (void)drawRect:(CGRect)dirtyRect
{
	CGRect imageBounds = CGRectMake(0.0f, 0.0f, kLegislatorMasterCellViewWidth, kLegislatorMasterCellViewHeight);
	CGRect bounds = [self bounds];

	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat resolution = 0;
	CGRect drawRect = CGRectZero;

	UIColor *nameColor = nil;
	UIColor *tenureColor = nil;
	UIColor *titleColor = nil;

	// Choose font color based on highlighted state.
	if (self.highlighted) {
		nameColor = tenureColor = titleColor = [TexLegeTheme backgroundLight];
	}
	else {
		nameColor = [TexLegeTheme textDark];
		tenureColor = [TexLegeTheme textLight];
		titleColor = [TexLegeTheme accent];
	}


    CGFloat widthRatio = CGRectGetWidth(bounds) / CGRectGetWidth(imageBounds);
    CGFloat heightRatio = CGRectGetHeight(bounds) / CGRectGetHeight(imageBounds);
	resolution = 0.5f * (widthRatio + heightRatio);

	CGContextSaveGState(context);
    {
        CGContextTranslateCTM(context, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
        CGContextScaleCTM(context, widthRatio, heightRatio);

        // Title

        CGRect titleRect = CGRectMake(8.5f, 0.0f, 240.0f, 18.0f);
        [titleColor set];
        [[self title] drawInRect:[self scaleRect:titleRect forResolution:resolution] withFont:[TexLegeTheme boldTwelve]];

        // Name

        CGRect nameRect = CGRectMake(8.5f, 17.0f, 240.0f, 21.0f);
        [nameColor set];
        [[self name] drawInRect:[self scaleRect:nameRect forResolution:resolution] withFont:[TexLegeTheme boldFifteen]];

        // GradientBar

        CGMutablePathRef path = CGPathCreateMutable();
        CGRect scaleBarRect = CGRectMake(8.5f, 53.0f, 173.0f, 13.0f);
        drawRect = [self scaleRect:scaleBarRect forResolution:resolution];
        scaleBarRect = CGRectInset(scaleBarRect, -2, -2);

        CGPathAddRect(path, NULL, drawRect);

        CGFloat locations[3];
        NSArray *colors = [NSArray arrayWithObjects:(id)[[TexLegeTheme texasBlue] CGColor],
                                                    (id)[[UIColor whiteColor] CGColor],
                                                    (id)[[TexLegeTheme texasRed] CGColor],nil];
        locations[0] = 0.0f;
        locations[1] = 0.499f;
        locations[2] = 1.0f;
        CGGradientRef gradient = CGGradientCreateWithColors(space, (CFArrayRef)colors, locations);
        CGContextAddPath(context, path);
        CGContextSaveGState(context);
        {
            CGContextEOClip(context);
            CGPoint point1 = CGPointMake(29.5f, 59.0f);
            CGPoint point2 = CGPointMake(162.5f, 59.0f);
            CGContextDrawLinearGradient(context, gradient, point1, point2, (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation));
        }
        CGContextRestoreGState(context);
        CGGradientRelease(gradient);

        UIColor *color = nil;
        if (self.highlighted)
            color = [UIColor whiteColor];
        else
            color = [UIColor blackColor];
        [color setStroke];

        CGFloat stroke = 1.0f;
        stroke *= resolution;
        if (stroke < 1.0f) {
            stroke = ceilf(stroke);
        } else {
            stroke = roundf(stroke);
        }
        stroke /= resolution;
        stroke *= 2.0f;
        CGContextSetLineWidth(context, stroke);
        CGContextSaveGState(context);
        {
            CGContextAddPath(context, path);
            CGContextEOClip(context);
            CGContextAddPath(context, path);
            CGContextStrokePath(context);
        }
        CGContextRestoreGState(context);
        CGPathRelease(path);

        // we don't use sliderVal here because it's already been adjusted to compensate for minMax...
        if (self.partisan_index == 0.0f) {
            if (!self.questionImage) {
                self.questionImage = [UIImage imageNamed:@"error"];
            }
            drawRect = CGRectMake(87.f, 47.f, 24.f, 24.f);
            [self.questionImage drawInRect:drawRect blendMode:kCGBlendModeNormal alpha:0.6];
        }
        else {
            // StarGroup

            // Setup for Shadow Effect
            color = [UIColor colorWithWhite:0.0f alpha:0.5f];
            CGContextSaveGState(context);
            {
                // Star
                stroke = 1.0f;
                stroke *= resolution;
                if (stroke < 1.0f) {
                    stroke = ceilf(stroke);
                } else {
                    stroke = roundf(stroke);
                }
                CGFloat starCenter = self.sliderValue;  // lets start at 86.5

                stroke /= resolution;
                CGFloat alignStroke = fmodf(0.5f * stroke * resolution, 1.0f);

                CGFloat yShift = 40.5f;

                path = CGPathCreateMutable();
                CGPoint point = CGPointMake(starCenter+5.157f, 28.0f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathMoveToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+13.5f, 21.71f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+21.843f, 28.0f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+18.732f, 17.713f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+27.0f, 11.313f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+16.734f, 11.245f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+13.5f, 1.0f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+10.266f, 11.245f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+0.0f, 11.313f+yShift);				// top dead center
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+8.268f, 17.713f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                point = CGPointMake(starCenter+5.157f, 28.0f+yShift);
                point = [self scalePoint:point forResolution:resolution alignment:alignStroke];
                CGPathAddLineToPoint(path, NULL, point.x, point.y);
                CGPathCloseSubpath(path);

                color = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f];
                colors = [NSArray arrayWithObjects:(id)[color CGColor], (id)[color CGColor], nil];
                locations[0] = 0.0f;
                locations[1] = 1.0f;
                gradient = CGGradientCreateWithColors(space, (CFArrayRef)colors, locations);
                CGContextAddPath(context, path);
                CGContextSaveGState(context);
                {
                    CGContextEOClip(context);
                    CGPoint point1 = CGPointMake(starCenter+14.0f, 11.5f+yShift);
                    CGPoint point2 = CGPointMake(starCenter+9.5f, 21.5f+yShift);
                    CGContextDrawLinearGradient(context, gradient, point1, point2, (kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation));
                }
                CGContextRestoreGState(context);
                CGGradientRelease(gradient);
                if (self.highlighted)
                    color = [UIColor whiteColor];
                else
                    color = [UIColor blackColor];
                [color setStroke];
                CGContextSetLineWidth(context, stroke);
                CGContextSetLineCap(context, kCGLineCapRound);
                CGContextSetLineJoin(context, kCGLineJoinRound);
                CGContextAddPath(context, path);
                CGContextStrokePath(context);
                CGPathRelease(path);
            }
            CGContextRestoreGState(context);
        }

        // Tenure

        CGRect disclosureRect = CGRectZero;
        CGRect tenureRect = CGRectZero;
        CGRect remainingRect = CGRectZero;
        CGRect otherRect = CGRectZero;

        CGRectDivide(imageBounds, &otherRect, &remainingRect, CGRectGetMaxX(scaleBarRect), CGRectMinXEdge);
        CGRectDivide(remainingRect, &disclosureRect, &tenureRect, 52.f, CGRectMinYEdge);
        tenureRect.size.width -= 2;
        drawRect = [self scaleRect:tenureRect forResolution:resolution];
        
        [tenureColor set];
        [[self tenure] drawInRect:drawRect withFont:[TexLegeTheme boldTen] lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentRight];
        
    }
	CGContextRestoreGState(context);
	CGColorSpaceRelease(space);
}

- (CGRect)scaleRect:(CGRect)rect forResolution:(CGFloat)resolution
{
	rect.origin.x = roundf((resolution * CGRectGetMinX(rect)) / resolution);
	rect.origin.y = roundf((resolution * CGRectGetMinY(rect))/ resolution);
	rect.size.width = roundf((resolution * CGRectGetWidth(rect)) / resolution);
	rect.size.height = roundf((resolution * CGRectGetHeight(rect)) / resolution);
    return rect;
}

- (CGPoint)scalePoint:(CGPoint)point forResolution:(CGFloat)resolution alignment:(CGFloat)alignment
{
    point.x = [self scaleValue:point.x forResolution:resolution alignment:alignment];
    point.y = [self scaleValue:point.y forResolution:resolution alignment:alignment];
    return point;
}

- (CGFloat)scaleValue:(CGFloat)value forResolution:(CGFloat)resolution alignment:(CGFloat)alignment
{
    return (roundf(resolution * value + alignment) - alignment) / resolution;
}

@end
