//
//  AttachedWindowController.m
//  MacHg
//
//  Created by Jason Harris on 19/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "AttachedWindowController.h"


@implementation AttachedWindowController





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Attached Window
// ------------------------------------------------------------------------------------

- (void) ensureAttachedWindowIsClosed
{
	if (attachedWindow)
		[self toggleAttachedWindow];
}

- (void) ensureAttachedWindowIsOpen
{
	if (!attachedWindow)
		[self toggleAttachedWindow];
}


- (void) toggleAttachedWindow
{
    if (!attachedWindow)
	{
		// Get the midpoint of the button and find this inside the windows content view. This is where we place the attached window...
        NSPoint buttonPoint = NSMakePoint(NSMidX([locationInParentWindow frame]), NSMidY([locationInParentWindow frame]));
		NSView* theSuperView = [locationInParentWindow superview];
		while (theSuperView && theSuperView != [parentWindow contentView])
		{
			NSRect theFrame = [theSuperView frame];
			buttonPoint.x += theFrame.origin.x;
			buttonPoint.y += theFrame.origin.y;
			theSuperView = [theSuperView superview];
		}
        attachedWindow = [[MAAttachedWindow alloc] initWithView:attachedView  attachedToPoint:buttonPoint  inWindow:parentWindow  onSide:MAPositionRightBottom  atDistance:10];
        [attachedWindow setArrowBaseWidth:15.0];
        [attachedWindow setArrowHeight:25.0];
        [parentWindow addChildWindow:attachedWindow ordered:NSWindowAbove];
    }
	else
	{
        [parentWindow removeChildWindow:attachedWindow];
        [attachedWindow orderOut:self];
        [attachedWindow release];
        attachedWindow = nil;
    }
}


@end
