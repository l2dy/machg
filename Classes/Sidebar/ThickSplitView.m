//
//  ThickSplitView.m
//  MacHg
//
//  Created by Jason Harris on 4/19/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ThickSplitView.h"

static inline CGFloat constrain(CGFloat val, CGFloat min, CGFloat max)	{ if (val < min) return min; if (val > max) return max; return val; }

@implementation ThickSplitView

- (void) awakeFromNib
{
	[self setDelegate:self];
}

- (NSRect) splitView:(NSSplitView*)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
{
	proposedEffectiveRect.size.height = 18;
	proposedEffectiveRect.origin.y += 3;
	return proposedEffectiveRect;
}

- (CGFloat) splitView:(NSSplitView*)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
	CGFloat height = [self bounds].size.height;
	if (proposedPosition > height - 50)
		return height - 18;
	return constrain(proposedPosition, height - 250, height - 100);
}

- (void) splitView:(NSSplitView*)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSArray* views		= [self subviews];
	NSView* outline		= [views objectAtIndex:0];
	NSView* info		= [views objectAtIndex:1];
	NSRect outlineFrame = [outline frame];
	outlineFrame.size.height = [self frame].size.height - [info frame].size.height;
	[outline setFrame:outlineFrame];
	[self adjustSubviews];
}


@end
