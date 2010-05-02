//
//  CloneSheetController.h
//  MacHg
//
//  Created by Jason Harris on 1/18/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface CloneSheetController : BaseSheetWindowController
{
	IBOutlet NSWindow*					theWindow;
	IBOutlet NSButton*					okButton;
	IBOutlet NSTextField*				theTitleText;
	IBOutlet NSTextField*				pullSourceLabel;		// The short name of the source repository
	IBOutlet NSTextField*				pullSourceStaticText;	// static text "Source" (used in layout calculations)
	IBOutlet NSImageView*				sourceIconWell;			// Image well showing an icon of the source.
	IBOutlet NSBox*						cloneBadPathBox;		// A box containing a message that the destination path already had
																// files at that location.
	IBOutlet DisclosureBoxController*	disclosureController;	// The disclosure box for the advanced options
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
