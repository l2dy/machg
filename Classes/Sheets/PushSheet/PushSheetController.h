//
//  PushSheetController.h
//  MacHg
//
//  Created by Jason Harris on 15/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "TransmitSheetController.h"

@interface PushSheetController : TransmitSheetController <NSMenuDelegate>
{
	IBOutlet NSButton*			sheetButtonOkForPushSheet;
	IBOutlet NSButton*			sheetButtonCancelForPushSheet;

	// Advanced options
	IBOutlet OptionController*	bookmarkOption;
	IBOutlet OptionController*	branchOption;
	IBOutlet OptionController*	insecureOption;
	IBOutlet OptionController*	remotecmdOption;
	IBOutlet OptionController*	revOption;
	IBOutlet OptionController*	sshOption;
}
@property (weak,readonly) MacHgDocument* myDocument;

- (PushSheetController*) initPushSheetControllerWithDocument:(MacHgDocument*)doc;

// Actions
- (IBAction) validateButtons:(id)sender;


// Sheet button actions
- (IBAction) sheetButtonPush:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;


- (void) controlTextDidChange:(NSNotification*)aNotification;
- (void) clearSheetFieldValues;

@end
