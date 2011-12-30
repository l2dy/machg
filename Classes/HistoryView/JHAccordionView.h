//
//  JHSplitView.h
//  JHSplitView
//
//  Created by Jason Harris on 4/17/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>

@class JHAccordionView;
@class JHAccordionSubView;


@interface JHAccordionSubView : NSView
{
	NSView*		divider;
	NSView*		content;
	CGFloat		oldPaneHeight;
}

// Initilization
- (void) setDivider:(NSView*)view;
- (void) setContent:(NSView*)view;


// Accessors
- (CGFloat) dividerHeight;
- (CGFloat) dividerWidth;
- (CGFloat) contentHeight;
- (CGFloat) height;
- (BOOL)	clickIsInsideDivider:(NSEvent*)theEvent;

- (void) collapsePaneGivingSpaceToPanes:(NSArray*)panes;
- (void) expandPaneTakingSpaceFromPanes:(NSArray*)panes;

@end


@interface JHAccordionView : NSSplitView <NSSplitViewDelegate>
{
	IBOutlet NSView*	dividerView1;
	IBOutlet NSView*	dividerView2;
	IBOutlet NSView*	dividerView3;
	IBOutlet NSView*	dividerView4;
	IBOutlet NSView*	contentView1;
	IBOutlet NSView*	contentView2;
	IBOutlet NSView*	contentView3;
	IBOutlet NSView*	contentView4;

	NSArray*			arrayOfAccordianPanes;		// Array of JHAccordionSubView
	NSInteger			dividerDragNumber;			// Which divider is currently being dragged. -1 is no divider	
}

- (JHAccordionSubView*) pane:(NSInteger)paneNumber;
@end
