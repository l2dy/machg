//
//  JHSplitView.m
//  JHSplitView
//
//  Created by Jason Harris on 4/17/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//
//
//
//
// To use this class:
// 1. in Interface builder construct a NSSplitView with 3 panes (Or generalize the methods below too 4, 5 panes etc.)
// 2. Change the NSSplitView into a JHAccordionView.  (Interface Builder : Menu Tools-> IdentityInspector. In the class identity change it there.)
// 3. Change each of the children of the JHAccordionView into a JHAccordionSubView. (Again through the IdentityInspector)
// 4. Hook up the outlets (pane1Box, pane2Box, pane3Box) of the JHAccordionView to point to the JHAccordionSubView's.
// 5. Inside each of the JHAccordionSubView's add a NSView of some divider. Inside that add another view which can contain a group of buttons.
//    This buttonsInDivider group will not act like a thick divider in that you can't drag it and you can't double click it. But you
//    can of course click any button inside it and it will act like a normal button.
// 6. In each of the JHAccordionSubView hook up the divider outlet to this NSView which acts as your thick divider.
// 7. In each of the JHAccordionSubView hook up the buttonsInDivider outlet to this NSView which will contain the buttons in the thick divider.
// 8. Run!
// 9. Change the divider in Interface builder to something else you like. Add buttons to the buttonsInDivider view.
//
// The JHAccordionSubView is the direct child of a JHAccordionView
//
//


#import "JHAccordionView.h"

static inline CGFloat constrain(CGFloat val, CGFloat min, CGFloat max)	{ if (val < min) return min; if (val > max) return max; return val; }

// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  JHAccordionSubView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation JHAccordionSubView

@synthesize divider;
@synthesize buttonsContainerInDivider;

- (CGFloat) dividerHeight	{ return [divider frame].size.height; }
- (CGFloat) dividerWidth	{ return [divider frame].size.width; }

- (CGFloat) contentHeight	{ return [self height] - [self dividerHeight]; }
- (CGFloat) height			{ return [self frame].size.height; }
- (void)	setOldPaneHeight {oldPaneHeight = MAX([self height], 100); };

- (void)	changeFrameHeightBy:(CGFloat)delta		{ if (delta == 0) return; NSRect frame = [self frame]; frame.size.height += delta; [[self animator] setFrame:frame]; }
- (void)	changeFrameHeightDirectBy:(CGFloat)delta{ if (delta == 0) return; NSRect frame = [self frame]; frame.size.height += delta; [self setFrame:frame]; }
- (BOOL)	clickIsInsideDivider:(NSEvent*)theEvent
{
	return
		 NSPointInRect([theEvent locationInWindow], [divider convertRect:[divider bounds] toView:nil]) &&
		!NSPointInRect([theEvent locationInWindow], [buttonsContainerInDivider convertRect:[buttonsContainerInDivider bounds] toView:nil]);
}


- (void) collapsePaneGivingSpaceTo:(JHAccordionSubView*)paneA and:(JHAccordionSubView*)paneB
{
	CGFloat contentA = [paneA contentHeight];					// Available space in other paneA
	CGFloat contentB = [paneB contentHeight];					// Available space in other paneB
	if (contentA == 0 && contentB ==0)
		contentA = 5, contentB = 5;
	double rA = contentA*contentA / (contentA*contentA + contentB*contentB);

	oldPaneHeight = [self height];
	CGFloat extra = [self contentHeight];
	CGFloat extraA = floor(extra*rA);
	[self  changeFrameHeightBy: -extra];
	[paneA changeFrameHeightBy: extraA];
	[paneB changeFrameHeightBy: extra - extraA];
}

- (void) expandPaneTakingSpaceFrom:(JHAccordionSubView*)paneA and:(JHAccordionSubView*)paneB
{
	CGFloat contentA = [paneA contentHeight];					// Available space in other paneA
	CGFloat contentB = [paneB contentHeight];					// Available space in other paneB
	if (contentA == 0 && contentB ==0)
		contentA = 5, contentB = 5;
	double rA = contentA*contentA / (contentA*contentA + contentB*contentB);
	double rB = contentB*contentB / (contentA*contentA + contentB*contentB);
	
	CGFloat extra = oldPaneHeight - [self height];
	CGFloat extraA = floor(extra*rA);
	CGFloat extraB = floor(extra*rB);
	if (extraA + extraB > contentA + contentB)
	{
		[self  changeFrameHeightBy: contentA + contentB];
		[paneA changeFrameHeightBy: -contentA];
		[paneB changeFrameHeightBy: -contentB];
	}
	else
	{
		[self  changeFrameHeightBy: extraA+extraB];
		[paneA changeFrameHeightBy: -extraA];
		[paneB changeFrameHeightBy: -extraB];
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
	[pane1Box setOldPaneHeight];
	[pane2Box setOldPaneHeight];
	[pane3Box setOldPaneHeight];
	draggingDivider0 = NO;
	draggingDivider1 = NO;
	[self setDelegate:self];
}


- (void) mouseDown:(NSEvent*)theEvent
{
	
	// Look for double clicks in the divider's, and if we only have a single click figure out if we are dragging.
	if ([pane1Box clickIsInsideDivider:theEvent])
	{
		if ([theEvent clickCount] > 1)
		{
			if ([pane1Box contentHeight] == 0)
				[pane1Box expandPaneTakingSpaceFrom:pane2Box and:pane3Box];
			else
				[pane1Box collapsePaneGivingSpaceTo:pane2Box and:pane3Box];
			[self splitView:self resizeSubviewsWithOldSize:[self frame].size];
			return;
		}
	}

	else if ([pane2Box clickIsInsideDivider:theEvent])
	{
		if ([theEvent clickCount] > 1)
		{
			if ([pane2Box contentHeight] == 0)
				[pane2Box expandPaneTakingSpaceFrom:pane1Box and:pane3Box];
			else
				[pane2Box collapsePaneGivingSpaceTo:pane1Box and:pane3Box];
			[self splitView:self resizeSubviewsWithOldSize:[self frame].size];
			return;
		}
		draggingDivider0 = YES;
	}
	
	else if ([pane3Box clickIsInsideDivider:theEvent])
	{
		if ([theEvent clickCount] > 1)
		{
			if ([pane3Box contentHeight] == 0)
				[pane3Box expandPaneTakingSpaceFrom:pane1Box and:pane2Box];
			else
				[pane3Box collapsePaneGivingSpaceTo:pane1Box and:pane2Box];
			[self splitView:self resizeSubviewsWithOldSize:[self frame].size];
			return;
		}
		draggingDivider1 = YES;
	}

	
	// If we are dragging do the drag loop until the mouse is let up.
	if (draggingDivider0 || draggingDivider1)
	{
		[self doDividerDragLoop:theEvent];
		return;
	}
	
	[super mouseDown:theEvent];	
}


// We need to do this tight drag loop by "hand" since NSSplitView does a tight drag loop, ie if you override mouseDragged here it
// will never be called when you are dragging a divider since NSSplitView will be swallowing the events. Thus we dod the same
// thing here. This complication is necessary since we want to be able to drag one divider past another and have both dividers
// move. The UI is just better this way. When playing with it before I was frustrated by this lack of movement and this fixes it.
- (void) doDividerDragLoop:(NSEvent*)theEvent
{
	CGFloat mouseAnchor = [theEvent locationInWindow].y;
	CGFloat divider0Anchor = [pane2Box frame].origin.y;
	CGFloat divider1Anchor = [pane3Box frame].origin.y;

	while (true)
	{
		NSEvent* event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([event type] == NSLeftMouseUp)
		{
			draggingDivider0 = NO;
			draggingDivider1 = NO;
			return;
		}
		if ([event type] != NSLeftMouseDragged)
			continue;
		
		CGFloat newMouse = [event locationInWindow].y;
		CGFloat diffMouse = newMouse - mouseAnchor;

		if (draggingDivider0)
		{
			CGFloat diff0Divider = divider0Anchor - [pane2Box frame].origin.y;
			CGFloat diff = (diffMouse - diff0Divider);
				
			if (diff < 0)
			{
				diff = -diff; // reverse mental map here.
				
				// Take from second pane and give to first
				CGFloat chunk2 = constrain(diff, 0, [pane2Box contentHeight]);
				[pane1Box changeFrameHeightDirectBy:chunk2];
				[pane2Box changeFrameHeightDirectBy:-chunk2];
				diff -= chunk2;

				// Take remainder from third pane and give to first
				CGFloat chunk3 = constrain(diff, 0, [pane3Box contentHeight]);
				[pane1Box changeFrameHeightDirectBy:chunk3];
				[pane3Box changeFrameHeightDirectBy:-chunk3];
			}
			else
			{
				// Take from first and give to second
				CGFloat chunk3 = constrain(diff, 0, [pane1Box contentHeight]);
				[pane1Box changeFrameHeightDirectBy:-chunk3];
				[pane2Box changeFrameHeightDirectBy:chunk3];
			}
		}
		if (draggingDivider1)
		{
			CGFloat diff1Divider = divider1Anchor - [pane3Box frame].origin.y;
			CGFloat diff = diffMouse - diff1Divider;
			
			if (diff > 0)
			{
				// Take from second pane and give to third
				CGFloat chunk2 = constrain(diff, 0, [pane2Box contentHeight]);
				[pane2Box changeFrameHeightDirectBy:-chunk2];
				[pane3Box changeFrameHeightDirectBy:chunk2];
				diff -= chunk2;
				
				// Take remainder from first pane and give to third
				CGFloat chunk1 = constrain(diff, 0, [pane1Box contentHeight]);
				[pane1Box changeFrameHeightDirectBy:-chunk1];
				[pane3Box changeFrameHeightDirectBy:chunk1];
			}
			else
			{
				// Take from third pane and give to second
				CGFloat chunk3 = constrain(-diff, 0, [pane3Box contentHeight]);
				[pane2Box changeFrameHeightDirectBy:chunk3];
				[pane3Box changeFrameHeightDirectBy:-chunk3];
			}
		}
    }
}


- (void) mouseUp:(NSEvent*)theEvent
{
	draggingDivider0 = NO;
	draggingDivider1 = NO;
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

- (void) splitView:(NSSplitView*)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [self frame];

	CGFloat divider1Height = [pane1Box dividerHeight];
	CGFloat divider2Height = [pane2Box dividerHeight];
	CGFloat divider3Height = [pane3Box dividerHeight];

	// Make sure the total height is at least as big as the the divider heights.
	if (newFrame.size.height < divider1Height + divider2Height + divider3Height)
	{
		newFrame.origin.y = 0;
		newFrame.size.height = divider1Height + divider2Height + divider3Height;
		[self setFrame:newFrame];
	}

	CGFloat oldTotalHeight = oldSize.height;
	CGFloat newTotalHeight = newFrame.size.height;
	
	CGFloat pane1Height = [pane1Box height];
	CGFloat pane2Height = [pane2Box height];
	CGFloat pane3Height = [pane3Box height];
	
	pane1Height = pane1Height + (newTotalHeight - oldTotalHeight);

	pane1Height = constrain(pane1Height, divider1Height, CGFLOAT_MAX);
	pane2Height = constrain(pane2Height, divider2Height, CGFLOAT_MAX);
	pane3Height = constrain(pane3Height, divider3Height, CGFLOAT_MAX);
		
	
	while (pane1Height + pane2Height + pane3Height != newTotalHeight)
	{
		BOOL content1Closed = pane1Height <= divider1Height;
		BOOL content2Closed = pane2Height <= divider2Height;
		BOOL content3Closed = pane3Height <= divider3Height;
		
		if (pane1Height + pane2Height + pane3Height > newTotalHeight)
		{
			if (!content1Closed && pane1Height > divider1Height)
				pane1Height = newTotalHeight - pane2Height - pane3Height;
			else if (!content3Closed && pane3Height > divider3Height)
				pane3Height = newTotalHeight - pane1Height - pane2Height;
			else if (!content2Closed && pane2Height > divider2Height)
				pane2Height = newTotalHeight - pane1Height - pane3Height;
		}
		else if (pane1Height + pane2Height + pane3Height < newTotalHeight)
		{
			if (!content1Closed)
				pane1Height = newTotalHeight - pane2Height - pane3Height;
			else if (!content3Closed)
				pane3Height = newTotalHeight - pane1Height - pane2Height;
			else
				pane2Height = newTotalHeight - pane1Height - pane3Height;
		}

		pane1Height = constrain(pane1Height, divider1Height, content1Closed ? divider1Height : CGFLOAT_MAX);
		pane2Height = constrain(pane2Height, divider2Height, content2Closed ? divider2Height : CGFLOAT_MAX);
		pane3Height = constrain(pane3Height, divider3Height, content3Closed ? divider3Height : CGFLOAT_MAX);
	}
	
	CGFloat width = [self frame].size.width;
	NSRect pane1Frame = NSMakeRect(0, 0, width, pane1Height);
	NSRect pane2Frame = NSMakeRect(0, pane1Frame.origin.y + pane1Height, width, pane2Height);
	NSRect pane3Frame = NSMakeRect(0, pane2Frame.origin.y + pane2Height, width, pane3Height);
	[pane1Box setFrame:pane1Frame];
	[pane2Box setFrame:pane2Frame];
	[pane3Box setFrame:pane3Frame];
	[pane1Box needsDisplay];
	[pane2Box needsDisplay];
	[pane3Box needsDisplay];
}


- (IBAction) doSomething:(id)sender
{
	NSLog(@"Doing something");
}


@end
