//
//  PullSheetController.h
//  MacHg
//
//  Created by Jason Harris on 15/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "TransmitSheetController.h"

@interface PullSheetController : TransmitSheetController <NSMenuDelegate>
{
	IBOutlet NSButton*			sheetButtonOkForPullSheet;
	IBOutlet NSButton*			sheetButtonCancelForPullSheet;

	// Advanced options
	IBOutlet OptionController*	revOption;
	IBOutlet OptionController*	sshOption;
	IBOutlet OptionController*	remotecmdOption;
	IBOutlet OptionController*	updateOption;
}

- (PullSheetController*) initPullSheetControllerWithDocument:(MacHgDocument*)doc;

// Actions
- (IBAction) validateButtons:(id)sender;

// Sheet button actions
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;


- (void) controlTextDidChange:(NSNotification*)aNotification;
- (void) clearSheetFieldValues;

@end
