//
//  CollapseSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface CollapseSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	IBOutlet NSWindow*		theCollapseSheet;				// Main sheet First
	IBOutlet NSWindow*		theCollapseConfirmationSheet;	// Main sheet Second
	IBOutlet NSButton*		okButton;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	collapseSheetTitle;
	IBOutlet NSTextView*	combinedCommitMessage;
	IBOutlet NSTextField*	sheetConfirmationInformativeMessageTextField;
}

@property (weak,readonly) MacHgDocument*  myDocument;



// Initialization
- (CollapseSheetController*) initCollapseSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods
- (IBAction) openCollapseSheetWithSelectedRevisions:(id)sender;
- (IBAction) sheetButtonOkForCollapseSheet:(id)sender;
- (IBAction) sheetButtonCancelForCollapseSheet:(id)sender;

- (IBAction) openCollapseSheetWithCombinedCommitMessage:(id)sender;
- (IBAction) sheetButtonOkForCollapseConfirmationSheet:(id)sender;
- (IBAction) sheetButtonCancelForCollapseConfirmationSheet:(id)sender;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;

@end
