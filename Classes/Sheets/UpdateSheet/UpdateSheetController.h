//
//  UpdateSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface UpdateSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	// Main window
	IBOutlet NSWindow*		theUpdateSheet;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	updateSheetTitle;
	IBOutlet NSButton*		okButton;
	
	// Lower TabView Panes
	IBOutlet LogTableTextView*	detailedEntryTextView;	
}

@property (weak,readonly) MacHgDocument*  myDocument;
@property BOOL cleanUpdate;

// Initilization
- (UpdateSheetController*) initUpdateSheetControllerWithDocument:(MacHgDocument*)doc;
- (void)	 openUpdateSheetWithRevision:(NSNumber*)revision;


// Action Methods
- (IBAction) validate:(id)sender;
- (IBAction) openUpdateSheetWithCurrentRevision:(id)sender;
- (IBAction) openUpdateSheetWithSelectedRevision:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) sheetButtonViewDifferencesForUpdateSheet:(id)sender;


- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


@end

