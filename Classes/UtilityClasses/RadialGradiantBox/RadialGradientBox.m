//
//  RadialGradiantBox.m
//  MacHg
//
//  Created by Jason Harris on 6/1/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "RadialGradientBox.h"
#import <QuartzCore/CIFilter.h>

@interface RadialGradientBox (PrivateAPI)

- (void) recomputeFilters;
@end



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  RadialGradiantBox
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation RadialGradientBox : NSBox





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initilization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	offsetFromCenter_ = NSMakePoint(0.0, 0.0);
	radius_ = @450.0f;
	foregroundFilters_ = nil;
	backgroundFilters_ = nil;
	lastCenterForGradiant_ = nil;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Filters
// -----------------------------------------------------------------------------------------------------------------------------------------

- (CIVector*) recomputePosition
{
	NSRect buttonBoxFrame = [centeringObject bounds];
	NSRect other = [centeringObject convertRect:buttonBoxFrame toView:self];
	CIVector* center = [CIVector vectorWithX:NSMidX(other)+offsetFromCenter_.x Y:NSMidY(other)+offsetFromCenter_.y];
	return center;
}
																				  
- (void) recomputeFilters
{
	CIColor* black   = [CIColor colorWithRed:  0.0/255.0 green:  0.0/255.0 blue:  0.0/255.0 alpha:1.0];
	CIColor* color0  = [CIColor colorWithRed: 77.0/255.0 green: 78.0/255.0 blue: 87.0/255.0 alpha:0.8];
	CIColor* color1  = [CIColor colorWithRed: 39.0/255.0 green: 40.0/255.0 blue: 52.0/255.0 alpha:0.5];
	CIVector* center = [self recomputePosition];
	NSNumber* radius = radius_ ? radius_ : @450.0f;
	
	CIFilter* gradiantFilter = [CIFilter filterWithName:@"CIGaussianGradient"];
	[gradiantFilter setValue:color0 forKey:@"inputColor0"];
	[gradiantFilter setValue:color1 forKey:@"inputColor1"];
	[gradiantFilter setValue:center forKey:@"inputCenter"];
	[gradiantFilter setValue:radius forKey:@"inputRadius"];
	
	CIFilter* constantFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
	[constantFilter setValue:black forKey:@"inputColor"];
	
	foregroundFilters_ = @[gradiantFilter];
	backgroundFilters_ = @[constantFilter];
	
}

- (void) setRadius:(NSNumber*)r					{ radius_ = r;				  foregroundFilters_ = nil; backgroundFilters_ = nil; }
- (void) setOffsetFromCenter:(NSPoint)offset	{ offsetFromCenter_ = offset; foregroundFilters_ = nil; backgroundFilters_ = nil; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Drawing
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) viewWillDraw
{
	CIVector* newPosition = [self recomputePosition];
	if (!foregroundFilters_ || !backgroundFilters_ || !lastCenterForGradiant_ || [lastCenterForGradiant_ isNotEqualTo:newPosition])
		[self recomputeFilters];
	[[self layer] setFilters: foregroundFilters_];
	[[self layer] setBackgroundFilters:backgroundFilters_];
	
    [super viewWillDraw];
} 



@end