//
//  GradientBox.h
//  A version simplifed from BWToolkit since this can't be used so easily in Lion.
//
//  Originally created by Brandon Walkin (www.brandonwalkin.com)
//  Heavily simplifed by Jason Harris (www.jasonfharris.com)
//  All code is provided under the New BSD license.
//
#import "GradientBox.h"

@implementation GradientBox

- (void)bwDrawPixelThickLineOfColor:(NSColor*)color atPosition:(int)posInPixels withInset:(int)insetInPixels inRect:(NSRect)aRect inView:(NSView *)view horizontal:(BOOL)isHorizontal flip:(BOOL)shouldFlip
{
	// Convert the given rectangle from points to pixels
	aRect = [view convertRectToBase:aRect];
	
	// Round up the rect's values to integers
	aRect = NSIntegralRect(aRect);
	
	// Add or subtract 0.5 so the lines are drawn within pixel bounds 
	if (isHorizontal)
	{
		if ([view isFlipped])
			aRect.origin.y -= 0.5;
		else
			aRect.origin.y += 0.5;
	}
	else
	{
		aRect.origin.x += 0.5;
	}
	
	NSSize sizeInPixels = aRect.size;
	
	// Convert the rect back to points for drawing
	aRect = [view convertRectFromBase:aRect];
	
	// Flip the position so it's at the other side of the rect
	if (shouldFlip)
	{
		if (isHorizontal)
			posInPixels = sizeInPixels.height - posInPixels - 1;
		else
			posInPixels = sizeInPixels.width - posInPixels - 1;
	}
	
	float posInPoints = posInPixels / [[NSScreen mainScreen] userSpaceScaleFactor];
	float insetInPoints = insetInPixels / [[NSScreen mainScreen] userSpaceScaleFactor];
	
	// Calculate line start and end points
	float startX, startY, endX, endY;
	
	if (isHorizontal)
	{
		startX = aRect.origin.x + insetInPoints;
		startY = aRect.origin.y + posInPoints;
		endX   = aRect.origin.x + aRect.size.width - insetInPoints;
		endY   = aRect.origin.y + posInPoints;
	}
	else
	{
		startX = aRect.origin.x + posInPoints;
		startY = aRect.origin.y + insetInPoints;
		endX   = aRect.origin.x + posInPoints;
		endY   = aRect.origin.y + aRect.size.height - insetInPoints;
	}
	
	// Draw line
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:0.0f];
	[path moveToPoint:NSMakePoint(startX,startY)];
	[path lineToPoint:NSMakePoint(endX,endY)];
	[color set];
	[path stroke];
}

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
	[gradient drawInRect:self.bounds angle:90];
	[gradient release];
		
	// drawn TopBorder
	// [topBorderColor bwDrawPixelThickLineAtPosition:0 withInset:0 inRect:self.bounds inView:self horizontal:YES flip:NO];
	// [[[NSColor whiteColor] colorWithAlphaComponent:topInsetAlpha] bwDrawPixelThickLineAtPosition:1 withInset:0 inRect:self.bounds inView:self horizontal:YES flip:NO];
		
	// draw BottomBorder
	[self bwDrawPixelThickLineOfColor:bottomBorderColor atPosition:0 withInset:0 inRect:self.bounds inView:self horizontal:YES flip:YES];
	//[[[NSColor whiteColor] colorWithAlphaComponent:bottomInsetAlpha] bwDrawPixelThickLineAtPosition:1 withInset:0 inRect:self.bounds inView:self horizontal:YES flip:YES];		
}

- (BOOL)isFlipped
{
	return YES;
}


@end
