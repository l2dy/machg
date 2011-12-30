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

- (void) collapsePaneGivingSpaceTo:(JHAccordionSubView*)paneA and:(JHAccordionSubView*)paneB;
- (void) expandPaneTakingSpaceFrom:(JHAccordionSubView*)paneA and:(JHAccordionSubView*)paneB;

@end


@interface JHAccordionView : NSSplitView <NSSplitViewDelegate>
{
	IBOutlet NSView*	divider1;
	IBOutlet NSView*	divider2;
	IBOutlet NSView*	divider3;
	IBOutlet NSView*	pane1View;
	IBOutlet NSView*	pane2View;
	IBOutlet NSView*	pane3View;

	NSArray*			arrayOfAccordianPanes;		// Array of JHAccordionSubView
	NSInteger			dividerDragNumber;			// Which divider is currently being dragged. -1 is no divider
	
	JHAccordionSubView*	pane1Box;
	JHAccordionSubView*	pane2Box;
	JHAccordionSubView*	pane3Box;	
}

- (JHAccordionSubView*) pane:(NSInteger)paneNumber;
@end
