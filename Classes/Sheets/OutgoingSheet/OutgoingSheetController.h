//
//  OutgoingSheetController.h
//  MacHg
//
//  Created by Jason Harris on 15/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "TransmitSheetController.h"

@interface OutgoingSheetController : TransmitSheetController <NSMenuDelegate>
{
	IBOutlet NSButton*			sheetButtonOkForOutgoingSheet;
	IBOutlet NSButton*			sheetButtonCancelForOutgoingSheet;

	// Advanced options
	IBOutlet OptionController*	branchOption;
	IBOutlet OptionController*	gitOption;
	IBOutlet OptionController*	graphOption;
	IBOutlet OptionController*	insecureOption;
	IBOutlet OptionController*	limitOption;
	IBOutlet OptionController*	newestfirstOption;
	IBOutlet OptionController*	nomergesOption;
	IBOutlet OptionController*	patchOption;
	IBOutlet OptionController*	remotecmdOption;
	IBOutlet OptionController*	revOption;
	IBOutlet OptionController*	sshOption;
	IBOutlet OptionController*	styleOption;
	IBOutlet OptionController*	templateOption;
}
@property (weak,readonly) MacHgDocument* myDocument;

- (OutgoingSheetController*) initOutgoingSheetControllerWithDocument:(MacHgDocument*)doc;

// Actions
- (IBAction) validateButtons:(id)sender;


// Sheet button actions
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;


- (void) controlTextDidChange:(NSNotification*)aNotification;
- (void) clearSheetFieldValues;

@end
