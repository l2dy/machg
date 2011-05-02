//
//  StripSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface StripSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	IBOutlet NSWindow*		theStripSheet;						// Main sheet First
	IBOutlet NSButton*		okButton;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	stripSheetTitle;

	MacHgDocument*			myDocument;
	
	BOOL					forceOption_;
}

@property (readwrite,assign) MacHgDocument*  myDocument;
@property BOOL forceOption;


// Initialization
- (StripSheetController*) initStripSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods
- (IBAction) openStripSheetWithSelectedRevisions:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) validateButtons:(id)sender;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


@end
