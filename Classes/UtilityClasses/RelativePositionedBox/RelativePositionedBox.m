//
//  LocatedBox.m
//  MacHg
//
//  Created by Jason Harris on 6/1/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "RelativePositionedBox.h"


@implementation RelativePositionedBox


- (void) viewWillDraw
{
	static CGFloat relativeXPosition = 0.35;
	static CGFloat relativeYPosition = 0.7;

	NSRect f = self.frame;
	NSRect bounds = super.superview.bounds;
	f.origin.x = round((bounds.size.width  - f.size.width ) * relativeXPosition);
	f.origin.y = round((bounds.size.height - f.size.height) * relativeYPosition);
	if (f.origin.x < 0)
		f.origin.x = 0;
	if (f.origin.y > f.size.height)
		f.origin.y = f.size.height;
	self.frame = f;
	[super viewWillDraw];
}

@end
