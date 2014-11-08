//
//  StandardSplitView.h
//  MacHg
//
//  Created by Jason Harris on 01/01/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "StandardSplitView.h"
#import "Common.h"

@implementation StandardSplitView

- (CGFloat) dividerThickness { return 3.0; }

- (void) drawDividerInRect:(NSRect)aRect
{
	static NSColor* fillStartingColor = nil;
	static NSColor* fillEndingColor   = nil;
	static NSGradient* horizontalGradient = nil;
	static NSGradient* verticalGradient = nil;
	if (!fillStartingColor)
	{
		fillStartingColor  = [NSColor colorWithDeviceRed:225.0/255.0 green:230.0/255.0 blue:233.0/255.0 alpha:1.0];
		fillEndingColor    = [NSColor colorWithDeviceRed:208.0/255.0 green:219.0/255.0 blue:230.0/255.0 alpha:1.0];
		horizontalGradient = [[NSGradient alloc] initWithStartingColor:fillStartingColor endingColor:fillEndingColor];
		CGFloat locations[3];
		locations[0] = 0.0;
		locations[1] = 0.5;
		locations[2] = 1.0;
		NSArray* colors = @[fillStartingColor, fillEndingColor, fillStartingColor];
		verticalGradient   = [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace deviceRGBColorSpace]];
	}
	if (self.isVertical)
		[verticalGradient drawInRect:aRect angle:0];
	else
		[horizontalGradient drawInRect:aRect angle:90];	
}


@end
