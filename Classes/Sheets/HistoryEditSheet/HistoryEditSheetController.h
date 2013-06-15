//
//  HistoryEditSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface HistoryEditSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	IBOutlet NSWindow*		theHistoryEditSheet;						// Main sheet First
	IBOutlet NSWindow*		theHistoryEditConfirmationSheet;			// Main sheet Second
	IBOutlet NSButton*		okButton;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	historyEditSheetTitle;
	
	IBOutlet NSTextView*	confirmationSheetMessage;
	IBOutlet NSTextField*	sheetConfirmationInformativeMessageTextField;

}
@property (weak,readonly) MacHgDocument*  myDocument;


// Initialization
- (HistoryEditSheetController*) initHistoryEditSheetControllerWithDocument:(MacHgDocument*)doc;

// Primary Edit History Sheet
- (IBAction) openHistoryEditSheetWithSelectedRevisions:(id)sender;
- (IBAction) sheetButtonOkForHistoryEditSheet:(id)sender;
- (IBAction) sheetButtonCancelForHistoryEditSheet:(id)sender;

// Confirmation Edit History Sheet
- (IBAction) openHistoryEditConfirmationSheet:(id)sender;
- (IBAction) sheetButtonOkForHistoryEditConfirmationSheet:(id)sender;
- (IBAction) sheetButtonCancelForHistoryEditConfirmationSheet:(id)sender;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;

@end
