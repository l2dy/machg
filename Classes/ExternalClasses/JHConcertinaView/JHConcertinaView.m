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

static inline CGFloat square(CGFloat f)									{ return f*f; }
static inline CGFloat lowest(CGFloat val)								{ return (val > 0) ? floor(val) : ceil(val); }
static inline CGFloat constrain(CGFloat val, CGFloat min, CGFloat max)	{ if (val < min) return min; if (val > max) return max; return val; }

static inline BOOL IsEmpty(id thing)
{
    return
	thing == nil ||
	([thing respondsToSelector:@selector(length)] && [(NSData*)thing length] == 0) ||
	([thing respondsToSelector:@selector(count)]  && [(NSArray*)thing count] == 0);
}

static inline NSString* fstr(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString* string = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return string;
}

NSView* enclosingViewOfClass(NSView* view, Class class)
{
	NSView* theView = view;
	while(theView)
	{
		if ([theView isKindOfClass:class])
			return theView;
		theView = [theView superview];
	}
	return nil;
}

static NSCursor* cursorForSpaceAboveAndBelow(BOOL spaceAbove, BOOL spaceInAndBelow)
{
	if (spaceAbove && spaceInAndBelow)
		return [NSCursor resizeUpDownCursor];
	if (!spaceAbove && spaceInAndBelow)
		return [NSCursor resizeDownCursor];
	if (spaceAbove && !spaceInAndBelow)
		return [NSCursor resizeUpCursor];	
	return [NSCursor arrowCursor];
}



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

- (BOOL) isOpaque { return YES; }

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

- (NSView*) divider			 { return divider; }
- (NSView*) content			 { return content; }
- (CGFloat) dividerHeight	 { return divider.frame.size.height; }
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
	awake_ = YES;
	[self restorePositionsFromDefaults];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savePositionsToDefaults) name:NSSplitViewDidResizeSubviewsNotification object:self];
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

	JHConcertinaSubView* draggedSubpane = [self pane:dividerDragNumber];
	NSView* draggedDivider = [draggedSubpane divider];

	CGFloat dividerAnchors[count];
	for (int i = 0; i<count; i++)
		dividerAnchors[i] = [[self pane:i] frame].origin.y;

	while (true)
	{
		NSEvent* event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([event type] == NSLeftMouseUp)
		{
			dividerDragNumber = -1;
			[[self window] invalidateCursorRectsForView:draggedDivider];
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

		BOOL spaceAbove      = [self spaceAbove:draggedSubpane];
		BOOL spaceInAndBelow = [self spaceInAndBelow:draggedSubpane];
		NSCursor* cursor = cursorForSpaceAboveAndBelow(spaceAbove, spaceInAndBelow);
		[cursor set];
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
	CGFloat totalDividerHeights = total(dividerHeights, count); 
	if (self.frame.size.height < totalDividerHeights)
	{
		NSRect newFrame = [self frame];
		newFrame.origin.y = 0;
		newFrame.size.height = totalDividerHeights;
		[self setFrame:newFrame];
	}

	BOOL initiallyCollapsed[count];
	
	// Initilize Pane heights by inserting / deleting the extra space into the first pane
	for (int i = 0; i<count; i++)
	{
		paneHeights[i] = constrain([[self pane:i] height], dividerHeights[i], CGFLOAT_MAX);
		initiallyCollapsed[i] = paneHeights[i] <= dividerHeights[i];
	}
	
	// Iterate until we adjust the paneHeights to yeild the new goal total height
	CGFloat goalTotalHeight = self.frame.size.height;
	while (YES)
	{
		CGFloat totalPaneHeights = total(paneHeights, count);
		CGFloat diff = goalTotalHeight - totalPaneHeights;
		if (diff == 0)
			break;

		CGFloat totalContentHeight = totalPaneHeights - totalDividerHeights;
		BOOL adjusted = NO;
		for (int i = 0; i<count; i++)
			if (paneHeights[i] > dividerHeights[i])
			{
				CGFloat change = lowest(diff * (paneHeights[i] - dividerHeights[i]) / totalContentHeight);
				paneHeights[i] += change;
				adjusted |= (change != 0);
				diff -= change;
			}
		
		if (!adjusted)
			for (int i = 0; i<count; i++)
				if (paneHeights[i] > dividerHeights[i])
				{
					CGFloat available = paneHeights[i] - dividerHeights[i];
					CGFloat change = (diff > 0) ? diff : -MIN(-diff, available);
					paneHeights[i] += change;
					adjusted = YES;
					diff -= change;
					if (diff ==0)
						break;					
				}
		
		for (int i = 0; i<count; i++)
			paneHeights[i] = constrain(paneHeights[i], dividerHeights[i], CGFLOAT_MAX);
		
		if (!adjusted)
			break;
	}
	
	CGFloat width = [self frame].size.width;

	// resize all of the panes to our newly calculated paneHeights
	CGFloat yOffset = 0;
	for (int i = 0; i<count; i++)
	{
		NSRect paneFrame = NSMakeRect(0, yOffset, width, paneHeights[i]);
		yOffset += paneHeights[i];
		JHConcertinaSubView* ithPane = [self pane:i];
		if (!NSEqualRects(ithPane.frame, paneFrame))
		{
			[ithPane setFrame:paneFrame];
			[ithPane setNeedsDisplay:YES];
		}
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  SplitView Overides
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)isSubviewCollapsed:(NSView*)subview
{
	for (JHConcertinaSubView* pane in arrayOfConcertinaPanes)
		if (pane == subview)
			return [pane contentHeight] == 0;
	return NO;
}


// Reports whether the divider in the passed in subpane be dragged further up
- (BOOL) spaceAbove:(JHConcertinaSubView*)subview
{
	for (JHConcertinaSubView* pane in arrayOfConcertinaPanes)
	{
		if (pane == subview)
			return NO;
		if ([pane contentHeight] > 0)
			return YES;
	}
	return NO;
}

// Reports whether the divider in the passed in subpane be dragged further down
- (BOOL) spaceInAndBelow:(JHConcertinaSubView*)subview
{
	BOOL found = NO;
	for (JHConcertinaSubView* pane in arrayOfConcertinaPanes)
	{
		found |= (pane == subview);
		if (!found)
			continue;
		if ([pane contentHeight] > 0)
			return YES;
	}
	return NO;
}


- (BOOL) isOpaque { return YES; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  SplitView Autosaving
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) autosavePositionName					{ return autosavePoistionName_; }
- (void) setAutosavePositionName:(NSString*)name	{ autosavePoistionName_ = name; }

- (void) savePositionsToDefaults
{
	if (!autosavePoistionName_ || !awake_)
		return;
	NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
	NSInteger count = [arrayOfConcertinaPanes count];	
	for (int i = 0; i<count; i++)
		[dict setObject:NSStringFromRect([[self pane:i] frame]) forKey:fstr(@"pane%d",i)];
	[[NSUserDefaults standardUserDefaults] setObject:dict forKey:autosavePoistionName_];	
}

- (void) restorePositionsFromDefaults
{
	if (!awake_)
		return;
	NSDictionary* dict = autosavePoistionName_ ? [[NSUserDefaults standardUserDefaults] dictionaryForKey:autosavePoistionName_] : nil;
	if (!dict)
		return;

	NSInteger count = [arrayOfConcertinaPanes count];
	for (int i = 0; i<count; i++)
	{
		NSString* paneFrameString = [dict objectForKey:fstr(@"pane%d",i)];
		if (paneFrameString)
		{
			[[self pane:i] setFrame:NSRectFromString(paneFrameString)];
			[[self pane:i] setNeedsDisplay:YES];
		}
	}
	[self splitView:self resizeSubviewsWithOldSize:self.frame.size];
	[self setNeedsDisplay:YES];
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  SplitView Autosaving
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation ShowResizeUpDownCursorView
- (void)resetCursorRects
{
	JHConcertinaSubView* subView = (JHConcertinaSubView*)enclosingViewOfClass(self, [JHConcertinaSubView class]);
	JHConcertinaView* parentConcertinaView = (JHConcertinaView*)enclosingViewOfClass(self, [JHConcertinaView class]);
	if (!parentConcertinaView)
		[self addCursorRect:[self bounds] cursor:[NSCursor resizeUpDownCursor]];
	BOOL spaceAbove      = [parentConcertinaView spaceAbove:subView];
	BOOL spaceInAndBelow = [parentConcertinaView spaceInAndBelow:subView];
	NSCursor* cursor = cursorForSpaceAboveAndBelow(spaceAbove, spaceInAndBelow);
	[self addCursorRect:[self bounds] cursor:cursor];
}
@end
