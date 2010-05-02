//
//  PushSheetController.h
//  MacHg
//
//  Created by Jason Harris on 15/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "TransmitSheetController.h"

@interface PushSheetController : TransmitSheetController <NSMenuDelegate>
{
	IBOutlet NSButton*			sheetButtonOkForPushSheet;
	IBOutlet NSButton*			sheetButtonCancelForPushSheet;

	// Advanced options
	IBOutlet OptionController*	revOption;
	IBOutlet OptionController*	sshOption;
	IBOutlet OptionController*	remotecmdOption;
}

- (PushSheetController*) initPushSheetControllerWithDocument:(MacHgDocument*)doc;

// Actions
- (IBAction) validateButtons:(id)sender;


// Sheet button actions
- (IBAction) sheetButtonOkForPushSheet:(id)sender;
- (IBAction) sheetButtonCancelForPushSheet:(id)sender;


- (void) controlTextDidChange:(NSNotification*)aNotification;
- (void) clearSheetFieldValues;

@end
