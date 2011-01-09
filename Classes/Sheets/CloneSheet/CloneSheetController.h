//
//  CloneSheetController.h
//  MacHg
//
//  Created by Jason Harris on 1/18/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface CloneSheetController : BaseSheetWindowController
{
	IBOutlet NSWindow*					theWindow;
	IBOutlet NSButton*					okButton;
	IBOutlet NSTextField*				theTitleText;
	IBOutlet NSTextField*				pullSourceLabel;			// The short name of the source repository
	IBOutlet NSTextField*				pullSourceStaticText;		// static text "Source" (used in layout calculations)
	IBOutlet NSImageView*				sourceIconWell;				// Image well showing an icon of the source.
	IBOutlet DisclosureBoxController*	disclosureController;		// The disclosure box for the advanced options
	IBOutlet DisclosureBoxController*	errorDisclosureController;	// The disclosure box for any error messages
	IBOutlet NSTextField*				errorMessageTextField;		// The error message explaining why we cant clone

	IBOutlet OptionController*			revOption;
	IBOutlet OptionController*			sshOption;
	IBOutlet OptionController*			updaterevOption;
	IBOutlet OptionController*			remotecmdOption;
	IBOutlet OptionController*			noupdateOption;
	IBOutlet OptionController*			pullOption;
	IBOutlet OptionController*			uncompressedOption;
	
	MacHgDocument*		myDocument;
	
	NSArray*			cmdOptions;
	NSString*			shortNameFieldValue_;
	NSString*			pathFieldValue_;
	SidebarNode*		sourceNode_;
}
@property (readwrite,assign) NSString*  shortNameFieldValue;
@property (readwrite,assign) NSString*  pathFieldValue;

- (CloneSheetController*) initCloneSheetControllerWithDocument:(MacHgDocument*)doc;

// Actions
- (IBAction) browseToPath: (id)sender;
- (IBAction) validateButtons:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) openCloneSheet:(id)sender;

- (void) openCloneSheetWithSource:(SidebarNode*)source;
- (void) controlTextDidChange:(NSNotification*)aNotification;
- (void) setConnectionFromFieldsForSource:(SidebarNode*)source;
- (void) setFieldsFromConnectionForSource:(SidebarNode*)source;

@end
