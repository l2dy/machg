//
//  GradientBox.h
//  A version simplifed from BWToolkit since this can't be used so easily in Lion.
//
//  Originally created by Brandon Walkin (www.brandonwalkin.com)
//  Heavily simplifed by Jason Harris (www.jasonfharris.com)
//  All code is provided under the New BSD license.
//
#import "GradientBox.h"
#import "Common.h"

@implementation GradientBox

- (void)drawRect:(NSRect)rect 
{
	static NSColor* fillStartingColor = nil;
	static NSColor* fillEndingColor   = nil;
	static NSColor* bottomBorderColor = nil;
	static NSGradient *gradient = nil;
	if (!fillStartingColor)
	{
		fillStartingColor = [NSColor colorWithDeviceRed:182.0/255.0 green:195.0/255.0 blue:207.0/255.0 alpha:1.0];
		fillEndingColor   = [NSColor colorWithDeviceRed:131.0/255.0 green:145.0/255.0 blue:157.0/255.0 alpha:1.0];
		bottomBorderColor = [NSColor colorWithDeviceRed:109.0/255.0 green:122.0/255.0 blue:133.0/255.0 alpha:1.0];
		gradient          = [[NSGradient alloc] initWithStartingColor:fillStartingColor endingColor:fillEndingColor];
	}

	// draw gradient
	[gradient drawInRect:self.bounds angle:270];
		
	// drawn TopBorder
	// [topBorderColor bwDrawPixelThickLineAtPosition:0 withInset:0 inRect:self.bounds inView:self horizontal:YES flip:NO];
	// [[[NSColor whiteColor] colorWithAlphaComponent:topInsetAlpha] bwDrawPixelThickLineAtPosition:1 withInset:0 inRect:self.bounds inView:self horizontal:YES flip:NO];
		
	// draw BottomBorder
	[bottomBorderColor bwDrawPixelThickLineAtPosition:0 withInset:0 inRect:self.bounds inView:self horizontal:YES flip:NO];
	//[[[NSColor whiteColor] colorWithAlphaComponent:bottomInsetAlpha] bwDrawPixelThickLineAtPosition:1 withInset:0 inRect:self.bounds inView:self horizontal:YES flip:YES];		
}

- (BOOL)isFlipped
{
	return NO;
}


@end
