//
//  ExportPatchesSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface ExportPatchesSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	// Main window
	IBOutlet NSWindow*		theExportPatchesSheet;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	exportSheetTitle;
	IBOutlet NSButton*		okButton;
	
	// Lower TabView Panes
	IBOutlet LogTableTextView*	detailedEntryTextView;	
}

@property (weak,readonly) MacHgDocument*  myDocument;
@property NSString*	patchNameOption;
@property BOOL textOption;
@property BOOL gitOption;
@property BOOL noDatesOption;
@property BOOL reversePatchOption;

- (ExportPatchesSheetController*) initExportPatchesSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods
- (IBAction) openExportPatchesSheetWithSelectedRevisions:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) sheetButtonViewDifferencesForExportPatchesSheet:(id)sender;


// Validation and updating
- (IBAction) validate:(id)sender;
- (void)	 logTableViewSelectionDidChange:(LogTableView*)theLogTable;

@end

