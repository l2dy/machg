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
	IBOutlet NSView*			divider;
	IBOutlet NSView*			buttonsContainerInDivider;
	CGFloat						oldPaneHeight;
}
@property (readonly,assign) NSView*	divider;
@property (readonly,assign) NSView* buttonsContainerInDivider;

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
	IBOutlet JHAccordionSubView*	pane1Box;
	IBOutlet JHAccordionSubView*	pane2Box;
	IBOutlet JHAccordionSubView*	pane3Box;
	BOOL draggingDivider0;
	BOOL draggingDivider1;
}

@end
