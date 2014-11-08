//
//  CommandKeyTextField.m
//  MacHg
//
//  Created by Jason Harris on 3/13/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "CommandKeyTextField.h"
#import "Common.h"

@implementation CommandKeyTextField

- (void) showCommandKeyEquivalent	{ self.hidden = NO; }
- (void) hideCommandKeyEquivalent	{ self.hidden = YES; }

- (void) syncronizeToModifierKeys
{
	CGEventRef event = CGEventCreate(NULL /*default event source*/);
	CGEventFlags modifiers = CGEventGetFlags(event);
	CFRelease(event);

	BOOL isCommandDown  = bitsInCommon(modifiers, kCGEventFlagMaskCommand);
	if (isCommandDown)
		[self showCommandKeyEquivalent];
	else
		[self hideCommandKeyEquivalent];
}

- (void) awakeFromNib
{
	self.hidden = YES;
	[self observe:kCommandKeyIsDown		from:nil  byCalling:@selector(showCommandKeyEquivalent)];
	[self observe:kCommandKeyIsUp		from:nil  byCalling:@selector(hideCommandKeyEquivalent)];
	
	[self showCommandKeyEquivalent];
	[self performSelector:@selector(syncronizeToModifierKeys) withObject:nil afterDelay:(NSTimeInterval)1.5];
}

- (void) dealloc
{
	[self stopObserving];
}

@end
