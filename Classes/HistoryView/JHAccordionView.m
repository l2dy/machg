//
//  JHSplitView.m
//  JHSplitView
//
//  Created by Jason Harris on 4/17/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//
//
//
// To use this class:
// 1. in Interface builder construct a NSSplitView and delete all it's pains
// 2. Change the NSSplitView into a JHAccordionView.  (Interface Builder : Menu Tools-> IdentityInspector. In the class identity change it there.)
// 3. Create NSViews for the dividers and set their resizing correctly.
// 4. Create NSViews for the content and set their resizing correctly.
// 5. Hook up the outlets (contentView1, dividerView1, contentView2, dividerView2, etc.. of the JHAccordionView. (If you need more
//     just generalize the code it's quite easy to follow in that part.) 
// 5. Run!
// 6. Change the dividers / content views in Interface builder to something else you like. Add buttons to the divider views, etc.
//
//


#import "JHAccordionView.h"

static inline CGFloat square(CGFloat f) { return f*f; }
static inline CGFloat constrain(CGFloat val, CGFloat min, CGFloat max)	{ if (val < min) return min; if (val > max) return max; return val; }

// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  JHAccordionSubView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation JHAccordionSubView



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) adjustPaneAndDivider
{
	CGFloat selfHeight    = self.bounds.size.height;	
	CGFloat selfWidth     = self.bounds.size.width;	
	CGFloat dividerHeight = divider.bounds.size.height;
	CGFloat paneHeight = selfHeight - dividerHeight;
	[divider setFrame:NSMakeRect(0, paneHeight, selfWidth, dividerHeight)];
	[content    setFrame:NSMakeRect(0, 0, selfWidth, paneHeight)];
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

- (CGFloat) dividerHeight	{ return [divider frame].size.height; }
- (CGFloat) dividerWidth	{ return [divider frame].size.width; }

- (CGFloat) contentHeight	{ return [self height] - [self dividerHeight]; }
- (CGFloat) height			{ return [self frame].size.height; }
- (void)	setOldPaneHeight {oldPaneHeight = MAX([self height], 100); };

- (void)	changeFrameHeightBy:(CGFloat)delta		 { if (delta == 0) return; NSRect frame = [self frame]; frame.size.height += delta; [[self animator] setFrame:frame]; }
- (void)	changeFrameHeightDirectBy:(CGFloat)delta { if (delta == 0) return; NSRect frame = [self frame]; frame.size.height += delta; [self setFrame:frame]; }
- (BOOL)	clickIsInsideDivider:(NSEvent*)theEvent	 { return NSPointInRect([theEvent locationInWindow], [divider convertRect:[divider bounds] toView:nil]); }


static inline CGFloat extraForPane(CGFloat extra, JHAccordionSubView* pane, CGFloat totalContentHeights) { return floor(extra * [pane contentHeight] / totalContentHeights); }

- (void) collapsePaneGivingSpaceToPanes:(NSArray*)panes
{
	oldPaneHeight = [self height];
	CGFloat extra = [self contentHeight];

	CGFloat totalContentHeights = 0;
	for (JHAccordionSubView* pane in panes)
		totalContentHeights += [pane contentHeight];
	
	if (totalContentHeights < 1)
	{
		NSInteger count = [panes count];
		CGFloat extraPerPane = floor(extra/count);
		CGFloat total = 0;
		for (JHAccordionSubView* pane in panes)
		{
			total += extraPerPane;
			[pane changeFrameHeightBy: extraPerPane];
		}
		[[panes objectAtIndex:0] changeFrameHeightBy: (extra - total)]; // Put any left over into expanding the first pane
		[self changeFrameHeightBy: -extra];
		return;
	}

	CGFloat total = 0;
	for (JHAccordionSubView* pane in panes)
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
	for (JHAccordionSubView* pane in panes)
		totalContentHeights += [pane contentHeight];

	CGFloat extra = oldPaneHeight - [self height];
	
	CGFloat totalExtra = 0;
	if (totalContentHeights > 0.5)
		for (JHAccordionSubView* pane in panes)
			totalExtra += extraForPane(extra, pane, totalContentHeights);

	if (totalExtra > totalContentHeights || totalContentHeights < 1)
	{
		[self changeFrameHeightBy: totalContentHeights];
		for (JHAccordionSubView* pane in panes)
			[pane changeFrameHeightBy: -[pane contentHeight]];
	}
	else
	{
		[self changeFrameHeightBy: totalExtra];
		for (JHAccordionSubView* pane in panes)
			[pane changeFrameHeightBy: -extraForPane(extra, pane, totalContentHeights)];
	}
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  JHAccordionView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface JHAccordionView (PrivateAPI)
- (void) doDividerDragLoop:(NSEvent*)theEvent;
@end


@implementation JHAccordionView

- (void) awakeFromNib
{
	CGFloat width = [self frame].size.width;
	
	NSMutableArray* panes = [[NSMutableArray alloc]init];
	
	JHAccordionSubView* pane;
	pane = [[JHAccordionSubView alloc]initWithFrame:NSMakeRect(0, 200, width, 100)];
	[pane setDivider:dividerView1];
	[pane setContent:contentView1];
	[self addSubview:pane];
	[panes addObject:pane];

	if (dividerView2 && contentView2)
	{
		pane = [[JHAccordionSubView alloc]initWithFrame:NSMakeRect(0, 100, width, 100)];
		[pane setDivider:dividerView2];
		[pane setContent:contentView2];
		[self addSubview:pane];
		[panes addObject:pane];
	}
		
	if (dividerView3 && contentView3)
	{
		pane = [[JHAccordionSubView alloc]initWithFrame:NSMakeRect(0, 100, width, 100)];
		[pane setDivider:dividerView3];
		[pane setContent:contentView3];
		[self addSubview:pane];
		[panes addObject:pane];
	}

	if (dividerView4 && contentView4)
	{
		pane = [[JHAccordionSubView alloc]initWithFrame:NSMakeRect(0, 100, width, 100)];
		[pane setDivider:dividerView4];
		[pane setContent:contentView4];
		[self addSubview:pane];
		[panes addObject:pane];
	}
		
	arrayOfAccordianPanes = [NSArray arrayWithArray:panes];

	[self adjustSubviews];
	
	for (JHAccordionSubView* pane in arrayOfAccordianPanes)
		[pane setOldPaneHeight];

	
	dividerDragNumber = -1;

	[self setDelegate:self];
}


- (JHAccordionSubView*) pane:(NSInteger)paneNumber
{
	return [arrayOfAccordianPanes objectAtIndex:paneNumber];
}

- (void) mouseDown:(NSEvent*)theEvent
{
	
	for (JHAccordionSubView* pane in arrayOfAccordianPanes)
	{
		if ([pane clickIsInsideDivider:theEvent])
		{
			// Look for double clicks in the divider's, and if we only have a single click figure out if we are dragging.
			NSInteger index = [arrayOfAccordianPanes indexOfObject:pane];
			if ([theEvent clickCount] > 1)
			{
				NSMutableArray* otherPanes = [arrayOfAccordianPanes mutableCopy];
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
	NSInteger count = [arrayOfAccordianPanes count];
	
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
			JHAccordionSubView* recievingPane = [self pane:i-1];
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
			JHAccordionSubView* recievingPane = [self pane:i];
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
	
	NSInteger count = [arrayOfAccordianPanes count];

	CGFloat dividerHeights[count];	// The array of the heights of the dividers (this is constant)
	CGFloat paneHeights[count];		// The array of the heights of each pane (divider + content)

	// Initilize Divider heights
	for (int i = 0; i<count; i++)
		dividerHeights[i] = [[self pane:i] dividerHeight];

	// Make sure the total height is at least as big as the the divider heights.
	NSRect newFrame = [self frame];
	if (newFrame.size.height < total(dividerHeights, count))
	{
		newFrame.origin.y = 0;
		newFrame.size.height = total(dividerHeights, count);
		[self setFrame:newFrame];
	}

	CGFloat oldTotalHeight = oldSize.height;
	CGFloat newTotalHeight = newFrame.size.height;

	// Initilize Pane heights by inserting / deleting the extra space into the first pane
	for (int i = 0; i<count; i++)
		paneHeights[i] = [[self pane:i] height];
	paneHeights[0] += (newTotalHeight - oldTotalHeight);
	for (int i = 0; i<count; i++)
		paneHeights[i] = constrain(paneHeights[i], dividerHeights[i], CGFLOAT_MAX);
	
	
	// Iterate until we adjust the paneHeights to yeild the new total height
	while (total(paneHeights, count) != newTotalHeight)
	{
		CGFloat totalPaneHeights = total(paneHeights, count);

		if (totalPaneHeights > newTotalHeight)
		{
			for (int i = 0; i<count; i++)
				if (paneHeights[i] > dividerHeights[i])
				{
					paneHeights[i] += newTotalHeight - totalPaneHeights;
					break;
				}
		}
		else if (totalPaneHeights < newTotalHeight)
		{
			BOOL inserted = NO;
			for (int i = 0; i<count; i++)
				if (paneHeights[i] > dividerHeights[i])
				{
					paneHeights[i] += newTotalHeight - totalPaneHeights;
					inserted = YES;
					break;
				}
			if (!inserted)
				paneHeights[1] += newTotalHeight - totalPaneHeights;
		}

		for (int i = 0; i<count; i++)
			paneHeights[i] = constrain(paneHeights[i], dividerHeights[i], CGFLOAT_MAX);
	}
	
	CGFloat width = [self frame].size.width;

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
