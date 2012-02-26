//
//  PopupWindowController.m
//  MacHg
//
//  Created by Jason Harris on 2/3/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//

#import "PopupWindowController.h"


@implementation PopupWindowController

@synthesize attachedPosition;


- (IBAction) toggleAttachedPopupWindow:(id)sender
{
	// Attach/detach window
    if (!attachedPopupWindow)
	{
		MAWindowPosition windowPosition = attachedPosition ? [attachedPosition intValue] : MAPositionRightTop;
        NSPoint buttonPoint = NSMakePoint(NSMaxX([displayButton bounds]) - 2.0,
                                          NSMidY([displayButton bounds]) + 3.0);
		NSPoint pointInWindow = [displayButton convertPoint:buttonPoint toView:nil];
        attachedPopupWindow = [[MAAttachedWindow alloc] initWithView:popupContentView 
																	 attachedToPoint:pointInWindow 
																			inWindow:[displayButton window] 
																			  onSide:windowPosition
																		  atDistance:2.0];
        [attachedPopupWindow setBorderColor:[NSColor colorWithDeviceWhite:0.9 alpha:1.0]];
        [attachedPopupWindow setBackgroundColor:[NSColor colorWithDeviceWhite:0.93 alpha:1.0]];
        [attachedPopupWindow setViewMargin:3.0];
        [attachedPopupWindow setBorderWidth:1.0];
        [attachedPopupWindow setCornerRadius:5.0];
        [attachedPopupWindow setHasArrow:YES];
        [attachedPopupWindow setDrawsRoundCornerBesideArrow:YES];
        [attachedPopupWindow setArrowBaseWidth:20];
        [attachedPopupWindow setArrowHeight:10];
		[attachedPopupWindow setDelegate:self];
        [[displayButton window] addChildWindow:attachedPopupWindow ordered:NSWindowAbove];
		[attachedPopupWindow makeKeyWindow];
    }
	else
	{
        [[displayButton window] removeChildWindow:attachedPopupWindow];
        [attachedPopupWindow orderOut:self];
        [attachedPopupWindow release];
        attachedPopupWindow = nil;
    }
}

- (void) windowDidResignKey:(NSNotification*)notification
{
	if ([notification object] == attachedPopupWindow)
	{
		NSEvent* currentEvent = [NSApp currentEvent];
		BOOL doToggle = YES;
		if ([currentEvent type] == NSLeftMouseDown)
		{
			NSPoint eventLocation = [currentEvent locationInWindow];
			NSPoint localPoint = [displayButton convertPoint:eventLocation fromView:nil];
			NSRect buttonRect = [displayButton convertRect:[displayButton bounds] fromView:displayButton];
			if (NSPointInRect(localPoint, buttonRect))
				doToggle = NO;
		}
		
		if (doToggle)
			[self toggleAttachedPopupWindow:nil];
	}
}



@end
