//
//  RenameFileSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"


@interface RenameFileSheetController : BaseSheetWindowController
{
	IBOutlet NSWindow*	  theRenameFileSheet;
	IBOutlet NSTextField* renameSheetTitle;
	IBOutlet NSTextField* mainMessageTextField;
	IBOutlet NSTextField* theCurrentNameField;
	IBOutlet NSTextField* theNewNameField;
	IBOutlet NSButton*	  theAlreadyMovedButton;
	IBOutlet NSButton*	  theRenameButton;
	IBOutlet NSTextField* errorMessageTextField;
	IBOutlet DisclosureBoxController*	errorDisclosureController;	// The disclosure box for any error messages
}

@property (weak,readonly) MacHgDocument*  myDocument;
@property NSString*	  theCurrentNameFieldValue;
@property NSString*	  theNewNameFieldValue;
@property NSNumber*	  theAlreadyMovedButtonValue;


- (RenameFileSheetController*) initRenameFileSheetControllerWithDocument:(MacHgDocument*)doc;


// Actions
- (IBAction) validateButtons:(id)sender;
- (IBAction) sheetButtonRename:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) openRenameFileSheet:(id)sender;
- (IBAction) browseToPath:(id)sender;


// Delegates
- (void) controlTextDidChange:(NSNotification*)aNotification;

@end
