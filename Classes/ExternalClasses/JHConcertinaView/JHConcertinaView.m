//
//  JHConcertinaView.m
//  JHSConcertinaView
//
//  Created by Jason Harris on 4/17/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//
//
//
// To use this class:
// 1. in Interface builder construct a NSSplitView and delete all it's pains
// 2. Change the NSSplitView into a JHConcertinaView.  (Interface Builder : Menu Tools-> IdentityInspector. In the class identity change it there.)
// 3. Create NSViews for the dividers and set their resizing correctly.
// 4. Create NSViews for the content and set their resizing correctly.
// 5. Hook up the outlets (contentView1, dividerView1, contentView2, dividerView2, etc.. of the JHConcertinaView. (If you need more
//     just generalize the code it's quite easy to follow in that part.) 
// 5. Run!
// 6. Change the dividers / content views in Interface builder to something else you like. Add buttons to the divider views, etc.
//
//


#import "JHConcertinaView.h"

static inline CGFloat square(CGFloat f) { return f*f; }
static inline CGFloat constrain(CGFloat val, CGFloat min, CGFloat max)	{ if (val < min) return min; if (val > max) return max; return val; }

// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  JHConcertinaSubView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation JHConcertinaSubView



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (JHConcertinaSubView*) concertinaViewWithFrame:(NSRect)f andDivider:(NSView*)d andContent:(NSView*)c
{
	JHConcertinaSubView* pane = [[JHConcertinaSubView alloc]initWithFrame:f];
	[pane setDivider:d];
	[pane setContent:c];
	return pane;
}

- (void) adjustPaneAndDivider
{
	CGFloat selfHeight    = self.bounds.size.height;	
	CGFloat selfWidth     = self.bounds.size.width;	
	CGFloat dividerHeight = divider.bounds.size.height;
	CGFloat paneHeight = selfHeight - dividerHeight;
	[divider setFrame:NSMakeRect(0, paneHeight, selfWidth, dividerHeight)];
	[content setFrame:NSMakeRect(0, 0, selfWidth, paneHeight)];
}

- (void) setDivider:(NSView*)view
{
	divider = view;
	if (![[self subviews] containsObject:divider])
		[self addSubview:divider];
	[self adjustPaneAndDivider];	
}

- (void) setContent:(NSView*)view
{
	content = view;
	if (![[self subviews] containsObject:content])
		[self addSubview:content];
	[self adjustPaneAndDivider];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (CGFloat) dividerHeight	 { return divider.frame.size.height; }
- (CGFloat) dividerWidth	 { return divider.frame.size.width; }

- (CGFloat) contentHeight	 { return [self height] - [self dividerHeight]; }
- (CGFloat) height			 { return self.frame.size.height; }
- (void)	setOldPaneHeight { oldPaneHeight = MAX([self height], 100); };

- (void)	changeFrameHeightBy:(CGFloat)delta		 { if (delta == 0) return; NSRect frame = [self frame]; frame.size.height += delta; [[self animator] setFrame:frame]; }
- (void)	changeFrameHeightDirectBy:(CGFloat)delta { if (delta == 0) return; NSRect frame = [self frame]; frame.size.height += delta; [self setFrame:frame]; }
- (BOOL)	clickIsInsideDivider:(NSEvent*)theEvent	 { return NSPointInRect([theEvent locationInWindow], [divider convertRect:[divider bounds] toView:nil]); }


static inline CGFloat extraForPane(CGFloat extra, JHConcertinaSubView* pane, CGFloat totalContentHeights) { return floor(extra * [pane contentHeight] / totalContentHeights); }

- (void) collapsePaneGivingSpaceToPanes:(NSArray*)panes
{
	oldPaneHeight = [self height];
	CGFloat extra = [self contentHeight];

	CGFloat totalContentHeights = 0;
	for (JHConcertinaSubView* pane in panes)
		totalContentHeights += [pane contentHeight];
	
	if (totalContentHeights < 1)
	{
		NSInteger count = [panes count];
		CGFloat extraPerPane = floor(extra/count);
		CGFloat total = 0;
		for (JHConcertinaSubView* pane in panes)
		{
			total += extraPerPane;
			[pane changeFrameHeightBy: extraPerPane];
		}
		[[panes objectAtIndex:0] changeFrameHeightBy: (extra - total)]; // Put any left over into expanding the first pane
		[self changeFrameHeightBy: -extra];
		return;
	}

	CGFloat total = 0;
	for (JHConcertinaSubView* pane in panes)
	{
		CGFloat amount = extraForPane(extra, pane, totalContentHeights);
		total += amount;
		[pane changeFrameHeightBy: amount];
	}
	[[panes objectAtIndex:0] changeFrameHeightBy: (extra - total)]; // Put any left over into expanding the first pane
	[self changeFrameHeightBy: -extra];
	return;
}

- (void) expandPaneTakingSpaceFromPanes:(NSArray*)panes
{
	CGFloat totalContentHeights = 0;
	for (JHConcertinaSubView* pane in panes)
		totalContentHeights += [pane contentHeight];

	CGFloat extra = oldPaneHeight - [self height];
	
	CGFloat totalExtra = 0;
	if (totalContentHeights > 0.5)
		for (JHConcertinaSubView* pane in panes)
			totalExtra += extraForPane(extra, pane, totalContentHeights);

	if (totalExtra > totalContentHeights || totalContentHeights < 1)
	{
		[self changeFrameHeightBy: totalContentHeights];
		for (JHConcertinaSubView* pane in panes)
			[pane changeFrameHeightBy: -[pane contentHeight]];
	}
	else
	{
		[self changeFrameHeightBy: totalExtra];
		for (JHConcertinaSubView* pane in panes)
			[pane changeFrameHeightBy: -extraForPane(extra, pane, totalContentHeights)];
	}
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  JHConcertinaView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface JHConcertinaView (PrivateAPI)
- (void) doDividerDragLoop:(NSEvent*)theEvent;
@end


@implementation JHConcertinaView

- (void) awakeFromNib
{	
	NSMutableArray* panes = [[NSMutableArray alloc]init];
	
	JHConcertinaSubView* pane;
	NSRect initialFrame = NSMakeRect(0, 100, self.frame.size.width, 100);
	pane = [JHConcertinaSubView concertinaViewWithFrame:initialFrame andDivider:dividerView1 andContent:contentView1];
	[self addSubview:pane];
	[panes addObject:pane];

	if (dividerView2 && contentView2)
	{
		pane = [JHConcertinaSubView concertinaViewWithFrame:initialFrame andDivider:dividerView2 andContent:contentView2];
		[self addSubview:pane];
		[panes addObject:pane];
	}
		
	if (dividerView3 && contentView3)
	{
		pane = [JHConcertinaSubView concertinaViewWithFrame:initialFrame andDivider:dividerView3 andContent:contentView3];
		[self addSubview:pane];
		[panes addObject:pane];
	}

	if (dividerView4 && contentView4)
	{
		pane = [JHConcertinaSubView concertinaViewWithFrame:initialFrame andDivider:dividerView4 andContent:contentView4];
		[self addSubview:pane];
		[panes addObject:pane];
	}
		
	arrayOfConcertinaPanes = [NSArray arrayWithArray:panes];

	[self adjustSubviews];
	
	for (JHConcertinaSubView* pane in arrayOfConcertinaPanes)
		[pane setOldPaneHeight];

	
	dividerDragNumber = -1;

	[self setDelegate:self];
}


- (JHConcertinaSubView*) pane:(NSInteger)paneNumber
{
	return [arrayOfConcertinaPanes objectAtIndex:paneNumber];
}

- (void) mouseDown:(NSEvent*)theEvent
{	
	for (JHConcertinaSubView* pane in arrayOfConcertinaPanes)
	{
		if (![pane clickIsInsideDivider:theEvent])
			continue;

		// Look for double clicks in the divider's, and if we only have a single click figure out if we are dragging.
		NSInteger index = [arrayOfConcertinaPanes indexOfObject:pane];
		if ([theEvent clickCount] > 1)
		{
			NSMutableArray* otherPanes = [arrayOfConcertinaPanes mutableCopy];
			[otherPanes removeObject:pane];
			if ([pane contentHeight] == 0)
				[pane expandPaneTakingSpaceFromPanes:otherPanes];
			else
				[pane collapsePaneGivingSpaceToPanes:otherPanes];
			[self splitView:self resizeSubviewsWithOldSize:[self frame].size];
			return;
		}
		dividerDragNumber = index;
		break;
	}
	
	// If we are dragging do the drag loop until the mouse is let up.
	if (dividerDragNumber > 0)
	{
		[self doDividerDragLoop:theEvent];
		return;
	}
	
	[super mouseDown:theEvent];
}


// We need to do this tight drag loop by "hand" since NSSplitView does a tight drag loop, ie if you override mouseDragged here it
// will never be called when you are dragging a divider since NSSplitView will be swallowing the events. Thus we do the same
// thing here. This complication is necessary since we want to be able to drag one divider past another and have both dividers
// move. The UI is just better this way. When playing with it before I was frustrated by this lack of movement and this fixes it.
- (void) doDividerDragLoop:(NSEvent*)theEvent
{
	CGFloat mouseAnchor = [theEvent locationInWindow].y;
	NSInteger count = [arrayOfConcertinaPanes count];
	
	if (dividerDragNumber < 0)
		return;

	CGFloat dividerAnchors[count];
	
	for (int i = 0; i<count; i++)
		dividerAnchors[i] = [[self pane:i] frame].origin.y;

	while (true)
	{
		NSEvent* event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([event type] == NSLeftMouseUp)
		{
			dividerDragNumber = -1;
			return;
		}
		if ([event type] != NSLeftMouseDragged)
			continue;
		
		CGFloat newMouse = [event locationInWindow].y;
		CGFloat diffMouse = newMouse - mouseAnchor;

		const NSInteger i = dividerDragNumber;
		CGFloat diffDivider = dividerAnchors[i] - [[self pane:i] frame].origin.y;
		CGFloat diff = (diffMouse - diffDivider);
		if (fabs(diff) < 1)
			continue;
		
		if (diff < 0)
		{
			diff = floor(-diff); // reverse mental map here.

			// Put extra space in the pane before the divider and progressively take space from the following panes 
			JHConcertinaSubView* recievingPane = [self pane:i-1];
			for (int j = i; j<count; j++)
			{
				CGFloat chunk = constrain(diff, 0, [[self pane:j] contentHeight]);
				[recievingPane changeFrameHeightDirectBy:chunk];
				[[self pane:j] changeFrameHeightDirectBy:-chunk];
				diff -= chunk;
				if (diff < 0)
					break;
			}
		}
		else
		{
			diff = floor(diff);

			// Put extra space in the pane following the divider and progressively take space from the previous panes 
			JHConcertinaSubView* recievingPane = [self pane:i];
			for (int j = i-1; j>=0; j--)
			{
				CGFloat chunk = constrain(diff, 0, [[self pane:j] contentHeight]);
				[recievingPane changeFrameHeightDirectBy:chunk];
				[[self pane:j] changeFrameHeightDirectBy:-chunk];
				diff -= chunk;
				if (diff < 0)
					break;
			}
		}
    }
}


- (void) mouseUp:(NSEvent*)theEvent
{
	dividerDragNumber = -1;
	[super mouseUp:theEvent];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  SplitView Collapsing Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)	splitView:(NSSplitView*)splitView  shouldCollapseSubview:(NSView*)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex	{ return NO; }
- (BOOL)	splitView:(NSSplitView*)splitView  canCollapseSubview:(NSView*)subview	{ return NO; }

- (CGFloat)	dividerThickness	{ return 0; }
- (void)	drawDividerInRect:(NSRect)aRect { }


static inline CGFloat total(CGFloat* array, NSInteger count)
{
	CGFloat t = 0;
	for (int i = 0; i<count; i++)
		t += array[i];
	return t;
}

- (void) splitView:(NSSplitView*)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	
	NSInteger count = [arrayOfConcertinaPanes count];

	CGFloat dividerHeights[count];	// The array of the heights of the dividers (this is constant)
	CGFloat paneHeights[count];		// The array of the heights of each pane (divider + content)

	// Initilize Divider heights
	for (int i = 0; i<count; i++)
		dividerHeights[i] = [[self pane:i] dividerHeight];

	// Make sure the total height is at least as big as the the divider heights.
	if (self.frame.size.height < total(dividerHeights, count))
	{
		NSRect newFrame = [self frame];
		newFrame.origin.y = 0;
		newFrame.size.height = total(dividerHeights, count);
		[self setFrame:newFrame];
	}

	CGFloat  oldTotalHeight = oldSize.height;
	CGFloat goalTotalHeight = self.frame.size.height;

	// Initilize Pane heights by inserting / deleting the extra space into the first pane
	for (int i = 0; i<count; i++)
		paneHeights[i] = [[self pane:i] height];
	paneHeights[0] += (goalTotalHeight - oldTotalHeight);
	for (int i = 0; i<count; i++)
		paneHeights[i] = constrain(paneHeights[i], dividerHeights[i], CGFLOAT_MAX);
	
	
	// Iterate until we adjust the paneHeights to yeild the new goal total height
	while (total(paneHeights, count) != goalTotalHeight)
	{
		CGFloat totalPaneHeights = total(paneHeights, count);
		CGFloat diff = goalTotalHeight - totalPaneHeights;

		BOOL adjusted = NO;
		for (int i = 0; i<count; i++)
			if (paneHeights[i] > dividerHeights[i])
			{
				paneHeights[i] += diff;
				adjusted = YES;
				break;
			}

		if (!adjusted && diff > 0)
			paneHeights[1] += diff;

		for (int i = 0; i<count; i++)
			paneHeights[i] = constrain(paneHeights[i], dividerHeights[i], CGFLOAT_MAX);
	}
	
	CGFloat width = [self frame].size.width;

	// resize all of the panes to our newly calculated paneHeights
	CGFloat yOffset = 0;
	for (int i = 0; i<count; i++)
	{
		NSRect paneFrame = NSMakeRect(0, yOffset, width, paneHeights[i]);
		yOffset += paneHeights[i];
		[[self pane:i] setFrame:paneFrame];
		[[self pane:i] needsDisplay];
	}
}

@end
