//
//  AttachedWindowController.h
//  MacHg
//
//  Created by Jason Harris on 19/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MAAttachedWindow.h"

@interface AttachedWindowController : NSObject
{
	IBOutlet NSView*			attachedView;
	IBOutlet NSWindow*			parentWindow;
	IBOutlet NSButton*			locationInParentWindow;

	MAAttachedWindow*			attachedWindow;	// This will contain the view given in the outlet above
}

- (void) ensureAttachedWindowIsClosed;
- (void) ensureAttachedWindowIsOpen;
- (void) toggleAttachedWindow;

@end
