//
//  TSBadgeCell.m
//  Tahsis
//
//  Original version created by Matteo Bertozzi on 3/8/09.
//  Copyright 2009 Matteo Bertozzi. All rights reserved.
//  Extensive modifications made by Jason Harris 29/11/09.
//  Copyright 2009 Jason Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//
//  Actually it needs to be modified some more. It uses method names which are the same as variable, eg drawBadge and it could just
//  do with a tidy up, but it works so leave it.
//

#import "SidebarCell.h"

@interface SidebarCell (Private)
- (CGFloat) drawBadge:(NSRect)cellFrame;
@end

@implementation SidebarCell

#define TSBADGECELL_BUFFER_LEFT_SMALL		2
#define TSBADGECELL_BUFFER_LEFT				4
#define TSBADGECELL_BUFFER_SIDE				3
#define TSBADGECELL_BUFFER_TOP				3
#define TSBADGECELL_PADDING					6

#define TSBADGECELL_CIRCLE_BUFFER_RIGHT		5

#define TSBADGECELL_RADIUS_X				7
#define TSBADGECELL_RADIUS_Y				8

#define TSBADGECELL_TEXT_HEIGHT				14
#define TSBADGECELL_TEXT_MINI				8
#define TSBADGECELL_TEXT_SMALL				20

#define TSBADGECELL_ICON_SIZE				16
#define TSBADGECELL_ICON_HEIGHT_OFFSET		2

@synthesize badgeString = badgeString_;
@synthesize hasBadge	= hasBadge_;
@synthesize icon = icon_;


- (void) awakeFromNib
{
	[self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	badgeString_ = nil;
	hasBadge_ = NO;
	icon_ = nil;
}

- (void) setIcon:(NSImage*)icon
{
	if (icon_ != icon)
	{
		icon_ = icon;
		[icon_ setFlipped:NO];
		[icon_ setSize:NSMakeSize(TSBADGECELL_ICON_SIZE, TSBADGECELL_ICON_SIZE)];
	}
}


// Kind of ugly but better than before. We should likely use a sort of NSDivideRect sort of thing, with padding to get all three
// rects, the icon, the text, and the badge and then use these uniformly in
- (void) divide:(NSRect)cellFrame intoIconFrame:(NSRect*)iconFrame andTextFrame:(NSRect*)textFrame
{
	bool drawBadge = (hasBadge_ && cellFrame.size.width > TSBADGECELL_TEXT_SMALL * 3);
	CGFloat badgeWidth = (drawBadge ? [self drawBadge:cellFrame] : 0);

	//  NSDivideRect (cellFrame, &iconFrame, &textFrame, TSBADGECELL_ICON_SIZE, NSMinXEdge);
	(*iconFrame) = cellFrame;
	(*iconFrame).origin.y += TSBADGECELL_ICON_HEIGHT_OFFSET;
	(*iconFrame).size.height = TSBADGECELL_ICON_SIZE;
	(*iconFrame).size.width = TSBADGECELL_ICON_SIZE;
		
	// Draw Rect
	(*textFrame) = cellFrame;
	(*textFrame).origin.x += TSBADGECELL_ICON_SIZE + TSBADGECELL_BUFFER_LEFT;
	(*textFrame).size.width -= (badgeWidth + TSBADGECELL_ICON_SIZE + TSBADGECELL_BUFFER_LEFT);
}

- (void) editWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject event:(NSEvent*)theEvent
{
	if (!icon_)
	{
		[super editWithFrame:aRect inView: controlView editor:textObj delegate:anObject event:theEvent];
		return;
	}
	NSRect textFrame, iconFrame;
	[self divide:aRect intoIconFrame:&iconFrame andTextFrame:&textFrame];
    [super editWithFrame:textFrame inView: controlView editor:textObj delegate:anObject event:theEvent];
}

- (void) selectWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	if (!icon_)
	{
		[super selectWithFrame:aRect inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
		return;
	}
    NSRect textFrame, iconFrame;
	[self divide:aRect intoIconFrame:&iconFrame andTextFrame:&textFrame];
    [super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	bool drawBadge = (hasBadge_ && cellFrame.size.width > TSBADGECELL_TEXT_SMALL * 3);
	CGFloat badgeWidth = (drawBadge ? [self drawBadge:cellFrame] : 0);
	
	if (icon_ != nil)
	{
		NSRect iconFrame, textFrame;
		[self divide:cellFrame intoIconFrame:&iconFrame andTextFrame:&textFrame];
		[icon_ drawInRect:iconFrame fromRect:NSZeroRect  operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];	// drawIcon
		[super drawInteriorWithFrame:textFrame inView:controlView];	// drawText
	}
	else
	{
		NSRect labelRect = cellFrame;
		labelRect.size.width -= badgeWidth;
		[super drawInteriorWithFrame:labelRect inView:controlView];
	}
}

- (CGFloat) drawBadge:(NSRect)cellFrame
{
	// Setup Badge String and Size
	NSSize badgeNumSize = [badgeString_ sizeWithAttributes:nil];
	NSFont* badgeFont = [self font];
	
	// Calculate the Badge's coordinate
	CGFloat badgeWidth = badgeNumSize.width + TSBADGECELL_BUFFER_SIDE * 2;
	if (badgeNumSize.width < TSBADGECELL_TEXT_MINI)
		badgeWidth = TSBADGECELL_TEXT_SMALL;
	
	CGFloat badgeY = cellFrame.origin.y + TSBADGECELL_BUFFER_TOP;
	CGFloat badgeX = cellFrame.origin.x + cellFrame.size.width -
	TSBADGECELL_CIRCLE_BUFFER_RIGHT - badgeWidth;
	CGFloat badgeNumX = badgeX + TSBADGECELL_BUFFER_LEFT;
	if (badgeNumSize.width < TSBADGECELL_TEXT_MINI)
		badgeNumX += TSBADGECELL_BUFFER_LEFT_SMALL;
	
	// Draw the badge and number
	NSRect badgeRect = NSMakeRect(badgeX, badgeY, badgeWidth, TSBADGECELL_TEXT_HEIGHT);
	NSBezierPath* badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeRect  xRadius:TSBADGECELL_RADIUS_X  yRadius:TSBADGECELL_RADIUS_Y];
	
	BOOL isWindowFront = [[NSApp mainWindow] isVisible];
	BOOL isViewInFocus = [[[[self controlView] window] firstResponder] isEqual:[self controlView]];
	BOOL isCellHighlighted = [self isHighlighted];
	
	NSDictionary* dict = [[NSMutableDictionary alloc] init];
	[dict setValue:badgeFont forKey:NSFontAttributeName];
	
	if (isWindowFront && isViewInFocus && isCellHighlighted)
	{
		[[NSColor whiteColor] set];
		[dict setValue:[NSColor alternateSelectedControlColor] forKey:NSForegroundColorAttributeName];
	}
	else if (isWindowFront && isViewInFocus && !isCellHighlighted)
	{
		[[NSColor colorWithCalibratedRed:0.53 green:0.60 blue:0.74 alpha:1.0] set];
		[dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	}
	else if (isWindowFront && isCellHighlighted)
	{
		[[NSColor whiteColor] set];
		[dict setValue:[NSColor colorWithCalibratedRed:0.51 green:0.58 blue:0.72 alpha:1.0] forKey:NSForegroundColorAttributeName];
	}
	else if (!isWindowFront && isCellHighlighted)
	{
		[[NSColor whiteColor] set];
		[dict setValue:[NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName];
	}
	else
	{
		[[NSColor disabledControlTextColor] set];
		[dict setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	}
	
	[badgePath fill];
	[badgeString_ drawAtPoint:NSMakePoint(badgeNumX, badgeY) withAttributes:dict];
	
	return badgeWidth + TSBADGECELL_PADDING;
}

@end
