//
//  DisclosureBoxController.m
//  MacHg
//
//  Created by Jason Harris on 22/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "DisclosureBoxController.h"


@implementation DisclosureBoxController

- (void) awakeFromNib
{
	[self disclosureTrianglePressed:disclosureButton];
}

- (IBAction) disclosureTrianglePressed:(id)sender
{
	[self syncronizeDisclosureBoxToButtonStateWithAnimation:YES];
}

- (IBAction) ensureDisclosureBoxIsOpen:(id)sender
{
	[disclosureButton setState:NSOnState];
	[self syncronizeDisclosureBoxToButtonStateWithAnimation:NO];
}


- (IBAction) ensureDisclosureBoxIsClosed:(id)sender
{
	[disclosureButton setState:NSOffState];
	[self syncronizeDisclosureBoxToButtonStateWithAnimation:NO];
}


- (void) setToOpenState:(BOOL)state
{
	if (state == YES)
		[self ensureDisclosureBoxIsOpen:self];
	else if (state == NO)
		[self ensureDisclosureBoxIsClosed:self];
}

- (void) syncronizeDisclosureBoxToButtonStateWithAnimation:(BOOL)animate
{
	NSRect windowFrame = [parentWindow frame];
	CGFloat sizeChange = [disclosureBox frame].size.height + 5;		// The extra +5 accounts for the space between the box and its neighboring views

	if ([disclosureButton state] == NSOnState && [disclosureBox isHidden] == YES)
	{
		windowFrame.size.height += sizeChange;			// Make the window bigger.
		windowFrame.origin.y    -= sizeChange;			// Move the origin.
		if (!animate)
			[disclosureBox setHidden:NO];
		else
		{
			NSTimeInterval t = [parentWindow animationResizeTime:windowFrame];
			[disclosureBox performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:NO] afterDelay:t];
		}
		[parentWindow setFrame:windowFrame display:YES animate:animate];
		return;
	}
	
	if ([disclosureButton state] == NSOffState && [disclosureBox isHidden] == NO)
	{
		windowFrame.size.height -= sizeChange;			// Make the window smaller.
		windowFrame.origin.y    += sizeChange;			// Move the origin.
		[disclosureBox setHidden:YES];
		[parentWindow setFrame:windowFrame display:YES animate:animate];
	}
}




@end
