//
//  JHConcertinaView.h
//  JHConcertinaView
//
//  Created by Jason Harris on 4/17/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>

@class JHConcertinaView;
@class JHConcertinaSubView;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  JHConcertinaView and JHConcertinaSubView
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface JHConcertinaSubView : NSView
{
	NSView*		divider;
	NSView*		content;
	CGFloat		oldPaneHeight;	// We record the height of the pane when we collapse it so that if we subsequently expand the pane
								// we know the height to expand it to. 
}

// Initilization
+ (JHConcertinaSubView*) concertinaViewWithFrame:(NSRect)f andDivider:(NSView*)d andContent:(NSView*)c;
- (void) setDivider:(NSView*)view;
- (void) setContent:(NSView*)view;


// Accessors
- (NSView*) divider;
- (NSView*) content;
- (CGFloat) dividerHeight;
- (CGFloat) contentHeight;
- (CGFloat) height;
- (BOOL)	clickIsInsideDivider:(NSEvent*)theEvent;

- (void) collapsePaneGivingSpaceToPanes:(NSArray*)panes;
- (void) expandPaneTakingSpaceFromPanes:(NSArray*)panes;

@end


@interface JHConcertinaView : NSSplitView <NSSplitViewDelegate>
{
	IBOutlet NSView*	dividerView1;
	IBOutlet NSView*	dividerView2;
	IBOutlet NSView*	dividerView3;
	IBOutlet NSView*	dividerView4;
	IBOutlet NSView*	contentView1;
	IBOutlet NSView*	contentView2;
	IBOutlet NSView*	contentView3;
	IBOutlet NSView*	contentView4;

	NSArray*			arrayOfConcertinaPanes;		// Array of JHConcertinaSubView
	NSString*			autosavePoistionName_;
	BOOL				awake_;
}

- (JHConcertinaSubView*) pane:(NSInteger)paneNumber;
- (BOOL) isSubviewCollapsed:(NSView*)subview;
- (BOOL) spaceAbove:(JHConcertinaSubView*)subview;
- (BOOL) spaceInAndBelow:(JHConcertinaSubView*)subview;


// Position Autosaving
- (void) restorePositionsFromDefaults;
- (void) savePositionsToDefaults;
- (NSString*) autosavePositionName;
- (void) setAutosavePositionName:(NSString*)name;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  ShowResizeUpDownCursorView
// -----------------------------------------------------------------------------------------------------------------------------------------

// This is a simple complementary view to the concertina view which will overrride addCursorRect:cursor so that mouse tracking
// within this region shows an upDownResize cursor 
@interface ShowResizeUpDownCursorView : NSView
@end

