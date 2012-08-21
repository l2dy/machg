//
//  PopupActionButton.m
//  MacHg
//
//  Created by Jason Harris on 8/01/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "PopupActionButton.h"
#import "Common.h"
#import "MacHgDocument.h"

@implementation PopupActionButton





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// ------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	[[self menu] setDelegate:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Handle Clicks
// ------------------------------------------------------------------------------------

- (void) mouseDown:(NSEvent*)theEvent
{	
	NSRect frame = [self frame];
	NSControlSize controlSize = [[self cell] controlSize];
	CGFloat offset = (controlSize == NSRegularControlSize) ? 3 : 4;
	
    NSPoint menuOrigin = [self convertPoint:NSMakePoint(0, frame.size.height + offset) toView:nil];
	NSEvent* event = [NSEvent mouseEventWithType:NSLeftMouseDown location:menuOrigin modifierFlags:NSLeftMouseDownMask timestamp:[theEvent timestamp]
									windowNumber:[theEvent windowNumber] context:[theEvent context] eventNumber:[theEvent eventNumber] clickCount:1 pressure:1.0];
    [NSMenu popUpContextMenu:[self menu] withEvent:event forView:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// ------------------------------------------------------------------------------------





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Menu Delegates
// ------------------------------------------------------------------------------------

- (void) menuWillOpen:(NSMenu*)menu
{
	[self highlight:YES];
	[self needsDisplay];
}
- (void) menuDidClose:(NSMenu*)menu
{
	[self highlight:NO];
	[self needsDisplay];
}



@end
