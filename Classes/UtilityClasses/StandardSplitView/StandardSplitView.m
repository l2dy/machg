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
	static NSGradient* gradient = nil;
	if (!fillStartingColor)
	{
		fillStartingColor = [NSColor colorWithDeviceRed:225.0/255.0 green:230.0/255.0 blue:233.0/255.0 alpha:1.0];
		fillEndingColor   = [NSColor colorWithDeviceRed:208.0/255.0 green:219.0/255.0 blue:230.0/255.0 alpha:1.0];
		gradient          = [[NSGradient alloc] initWithStartingColor:fillStartingColor endingColor:fillEndingColor];
	}
	
	[gradient drawInRect:aRect angle:90];	
}


@end
