//
//  IncomingSheetController.h
//  MacHg
//
//  Created by Jason Harris on 15/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "TransmitSheetController.h"

@interface IncomingSheetController : TransmitSheetController <NSMenuDelegate>
{
	IBOutlet NSButton*			sheetButtonOkForIncomingSheet;
	IBOutlet NSButton*			sheetButtonCancelForIncomingSheet;

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

- (IncomingSheetController*) initIncomingSheetControllerWithDocument:(MacHgDocument*)doc;

// Actions
- (IBAction) validateButtons:(id)sender;

// Sheet button actions
- (IBAction) sheetButtonOkForIncomingSheet:(id)sender;
- (IBAction) sheetButtonCancelForIncomingSheet:(id)sender;


- (void) controlTextDidChange:(NSNotification*)aNotification;
- (void) clearSheetFieldValues;

@end
