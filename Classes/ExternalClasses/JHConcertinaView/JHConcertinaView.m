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
#import "Common.h"

static inline CGFloat square(CGFloat f)									{ return f*f; }
static inline CGFloat lowest(CGFloat val)								{ return (val > 0) ? floor(val) : ceil(val); }
static inline CGFloat constrain(CGFloat val, CGFloat min, CGFloat max)	{ if (val < min) return min; if (val > max) return max; return val; }

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

NSString* const kConcertinaViewContentDidCollapse   = @"ConcertinaViewContentDidCollapse";
NSString* const kConcertinaViewContentDidUncollapse = @"ConcertinaViewContentDidUncollapse";





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

- (NSView*) divider			  { return divider; }
- (NSView*) content			  { return content; }
- (CGFloat) dividerHeight	  { return divider.frame.size.height; }
- (CGFloat) contentHeight	  { return [self height] - [self dividerHeight]; }
- (CGFloat) height			  { return self.frame.size.height; }
- (CGFloat) oldPaneHeight	  { return oldPaneHeight; }
- (void)	initOldPaneHeight { oldPaneHeight = MAX([self height], 100); }

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

	NSInteger count = [panes count];
	CGFloat extraHeights[count];

	if (totalContentHeights < 1)
		for (NSInteger i = 0 ; i < count; i++)
			extraHeights[i] = floor(extra/count);
	else
		for (NSInteger i = 0 ; i < count; i++)
			extraHeights[i] = extraForPane(extra, panes[i], totalContentHeights);

	CGFloat total = 0;
	for (NSInteger i = 0 ; i < count; i++)
		total += extraHeights[0];
	
	extraHeights[0] += (extra - total); // Put any left over into expanding the first pane
	for (NSInteger i = 0 ; i < count; i++)
		[panes[i] changeFrameHeightBy: extraHeights[0]]; // Put any left over into expanding the first pane
	[self changeFrameHeightBy: -extra];

	return;
}

- (void) expandPaneTo:(CGFloat)height byTakingSpaceFromPanes:(NSArray*)panes
{
	CGFloat totalContentHeights = 0;
	for (JHConcertinaSubView* pane in panes)
		totalContentHeights += [pane contentHeight];

	CGFloat extra = height - [self height];
	
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
- (void) doDragLoopOfDivider:(NSInteger)dividerDragIndex withEvent:(NSEvent*)theEvent;
- (void) recordCollapsedState;
- (void) postDidUncollapse:(NSView*)contentSubview;
- (void) postDidCollapse:(NSView*)contentSubview;
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
		[pane initOldPaneHeight];

	[self recordCollapsedState];

	[self setDelegate:self];
	awake_ = YES;
	[self restorePositionsFromDefaults];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savePositionsToDefaults) name:NSSplitViewDidResizeSubviewsNotification object:self];
}

- (void) recordCollapsedState
{
	NSMutableArray* oldCollapsedState = [[NSMutableArray alloc]init];
	for (JHConcertinaSubView* pane in arrayOfConcertinaPanes)
		[oldCollapsedState addObject:boolAsNumber([pane contentHeight]<=0)];
	oldCollapsedStates_ = [NSArray arrayWithArray:oldCollapsedState];	
}

- (void) updateCollapseState
{
	NSInteger count = [arrayOfConcertinaPanes count];
	BOOL savedCollapseStateExists = [oldCollapsedStates_ count] == count;
	BOOL recordNewCollapseSate = !savedCollapseStateExists;
	if (savedCollapseStateExists)
		for (int i = 0; i<count; i++)
		{
			JHConcertinaSubView* ithPane = [self pane:i];
			BOOL initiallyCollapsed = numberAsBool(oldCollapsedStates_[i]);
			BOOL collapsed = [ithPane contentHeight] <= 0;
			recordNewCollapseSate |= (collapsed != initiallyCollapsed);
			if (collapsed && !initiallyCollapsed)
				[self postDidCollapse:[ithPane content]];
			else if (!collapsed && initiallyCollapsed)
				[self postDidUncollapse:[ithPane content]];
		}
	
	if (recordNewCollapseSate)
		[self recordCollapsedState];
}


- (JHConcertinaSubView*) pane:(NSInteger)paneNumber
{
	return arrayOfConcertinaPanes[paneNumber];
}

- (void) expandPane:(NSView*)paneChild toHeight:(CGFloat)height
{
	JHConcertinaSubView* pane = (JHConcertinaSubView*)enclosingViewOfClass(paneChild, [JHConcertinaSubView class]);
	NSMutableArray* otherPanes = [arrayOfConcertinaPanes mutableCopy];
	[otherPanes removeObject:pane];
	[pane expandPaneTo:height byTakingSpaceFromPanes:otherPanes];
	[self splitView:self resizeSubviewsWithOldSize:[self frame].size];	
}

- (void) collapsePane:(NSView*)paneChild
{
	JHConcertinaSubView* pane = (JHConcertinaSubView*)enclosingViewOfClass(paneChild, [JHConcertinaSubView class]);
	NSMutableArray* otherPanes = [arrayOfConcertinaPanes mutableCopy];
	[otherPanes removeObject:pane];
	[pane collapsePaneGivingSpaceToPanes:otherPanes];
	[self splitView:self resizeSubviewsWithOldSize:[self frame].size];	
}

- (void) expandPane:(NSView*)paneChild toPecentageHeight:(float)percentage
{
	float desieredFrameHeight = [self frame].size.height*constrain(percentage,0,1);
	[self expandPane:paneChild toHeight:desieredFrameHeight];
}

- (void) mouseDown:(NSEvent*)theEvent
{
	NSInteger dividerDragIndex = NSNotFound;
	for (JHConcertinaSubView* pane in arrayOfConcertinaPanes)
		if ([pane clickIsInsideDivider:theEvent])
		{
			dividerDragIndex = [arrayOfConcertinaPanes indexOfObject:pane];
			break;
		}

	if (dividerDragIndex == NSNotFound)
	{
		[super mouseDown:theEvent];
		return;
	}

	// If the divider was single clicked then drag it otherwise animate a collapse / expand of the divider's content
	if ([theEvent clickCount] <= 1)
		[self doDragLoopOfDivider:dividerDragIndex withEvent:theEvent];
	else
	{
		JHConcertinaSubView* pane = [self pane:dividerDragIndex];
		if ([pane contentHeight] == 0)
			[self expandPane:pane toHeight:[pane oldPaneHeight]];
		else
			[self collapsePane:pane];
	}
}


// We need to do this tight drag loop by "hand" since NSSplitView does a tight drag loop, ie if you override mouseDragged here it
// will never be called when you are dragging a divider since NSSplitView will be swallowing the events. Thus we do the same
// thing here. This complication is necessary since we want to be able to drag one divider past another and have both dividers
// move. The UI is just better this way. When playing with it before I was frustrated by this lack of movement and this fixes it.
- (void) doDragLoopOfDivider:(NSInteger)dividerDragIndex withEvent:(NSEvent*)theEvent
{
	CGFloat mouseAnchor = [theEvent locationInWindow].y;
	NSInteger count = [arrayOfConcertinaPanes count];
	
	if (dividerDragIndex < 0)
		return;

	JHConcertinaSubView* draggedSubpane = [self pane:dividerDragIndex];
	NSView* draggedDivider = [draggedSubpane divider];

	CGFloat dividerAnchors[count];
	for (int i = 0; i<count; i++)
		dividerAnchors[i] = [[self pane:i] frame].origin.y;

	while (true)
	{
		NSEvent* event = [[self window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
		if ([event type] == NSLeftMouseUp)
		{
			[[self window] invalidateCursorRectsForView:draggedDivider];
			return;
		}
		if ([event type] != NSLeftMouseDragged)
			continue;
		
		CGFloat newMouse = [event locationInWindow].y;
		CGFloat diffMouse = newMouse - mouseAnchor;

		const NSInteger i = dividerDragIndex;
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  SplitView Collapsing Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void)	postDidUncollapse:(NSView*)contentSubview	{ [[NSNotificationCenter defaultCenter] postNotificationName:kConcertinaViewContentDidUncollapse object:contentSubview]; }
- (void)	postDidCollapse:(NSView*)contentSubview		{ [[NSNotificationCenter defaultCenter] postNotificationName:kConcertinaViewContentDidCollapse	 object:contentSubview]; }

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
	
	[self updateCollapseState];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  SplitView Overides
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)isSubviewCollapsed:(NSView*)subview
{
	JHConcertinaSubView* concertinaSubView = (JHConcertinaSubView*)enclosingViewOfClass(subview, [JHConcertinaSubView class]);
	for (JHConcertinaSubView* pane in arrayOfConcertinaPanes)
		if (pane == concertinaSubView)
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
		dict[fstr(@"pane%d",i)] = NSStringFromRect([[self pane:i] frame]);
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
		NSString* paneFrameString = dict[fstr(@"pane%d",i)];
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
