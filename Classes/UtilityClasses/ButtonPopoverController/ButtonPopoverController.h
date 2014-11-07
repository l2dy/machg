//
//  ButtonPopoverController.h
//  MacHg
//
//  Created by Jason Harris on 2/3/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ButtonPopoverController : NSViewController

@property (nonatomic) IBOutlet NSButton*	popoverTriggerButton;
@property (nonatomic) IBOutlet NSPopover*	popover;

- (IBAction) togglePopover:(id)sender;

@end
