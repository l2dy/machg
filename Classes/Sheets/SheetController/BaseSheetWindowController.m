//
//  MySheetWindowController.m
//  MacHg
//
//  Created by Jason Harris on 3/13/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "BaseSheetWindowController.h"


@implementation BaseSheetWindowController

- (BaseSheetWindowController*) initWithWindowNibName:(NSString*)nibName
{
	[super initWithWindowNibName:nibName];
	[self window]; // force loading of the actual nib (strange that the default initWithWindowNibName) doesn't do this.
	return self;
}


- (void) flagsChanged:(NSEvent*)theEvent
{
	NSUInteger modifiers = [theEvent modifierFlags];
	BOOL isCommandDown  = bitsInCommon(modifiers, NSCommandKeyMask);
	[self postNotificationWithName:isCommandDown ? kCommandKeyIsDown : kCommandKeyIsUp ];
	[[self nextResponder] flagsChanged:theEvent];
}

@end
