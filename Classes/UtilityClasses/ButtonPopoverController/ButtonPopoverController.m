//
//  ButtonPopoverController.m
//  MacHg
//
//  Created by Jason Harris on 2/3/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//

#import "ButtonPopoverController.h"


@implementation ButtonPopoverController

@synthesize popoverTriggerButton = popoverTriggerButton_;
@synthesize popover = popover_;

- (void)viewDidDisappear
{
	self.popoverTriggerButton.state = NO;
}

- (IBAction)togglePopover:(id)sender;
{
	if (self.popoverTriggerButton.intValue == 1)
		[self.popover showRelativeToRect:[self.popoverTriggerButton bounds] ofView:self.popoverTriggerButton preferredEdge:NSMaxXEdge];
	else
		[self.popover close];
}

@end
