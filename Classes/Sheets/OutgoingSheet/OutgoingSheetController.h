//
//  OutgoingSheetController.h
//  MacHg
//
//  Created by Jason Harris on 15/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "TransmitSheetController.h"

@interface OutgoingSheetController : TransmitSheetController <NSMenuDelegate>
{
	IBOutlet NSButton*			sheetButtonOkForOutgoingSheet;
	IBOutlet NSButton*			sheetButtonCancelForOutgoingSheet;

	// Advanced options
	IBOutlet OptionController*	revOption;
	IBOutlet OptionController*	newestfirstOption;
	IBOutlet OptionController*	patchOption;
	IBOutlet OptionController*	gitOption;
	IBOutlet OptionController*	limitOption;
	IBOutlet OptionController*	nomergesOption;
	IBOutlet OptionController*	styleOption;
	IBOutlet OptionController*	templateOption;
	IBOutlet OptionController*	sshOption;
	IBOutlet OptionController*	remotecmdOption;
	IBOutlet OptionController*	graphOption;
}

- (OutgoingSheetController*) initOutgoingSheetControllerWithDocument:(MacHgDocument*)doc;

// Actions
- (IBAction) validateButtons:(id)sender;


// Sheet button actions
- (IBAction) sheetButtonOkForOutgoingSheet:(id)sender;
- (IBAction) sheetButtonCancelForOutgoingSheet:(id)sender;


- (void) controlTextDidChange:(NSNotification*)aNotification;
- (void) clearSheetFieldValues;

@end
