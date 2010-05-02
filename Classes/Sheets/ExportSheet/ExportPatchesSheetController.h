//
//  ExportPatchesSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface ExportPatchesSheetController : BaseSheetWindowController < ControllerForLogTableView >
{

	MacHgDocument*			myDocument;

	// Main window
	IBOutlet NSWindow*		theExportPatchesSheet;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	exportSheetTitle;
	IBOutlet NSButton*		okButton;
	
	// Lower TabView Panes
	IBOutlet NSTextView*	detailedEntryTextView;
	
	BOOL					textOption_;
	BOOL					gitOption_;
	BOOL					noDatesOption_;
	BOOL					switchParentOption_;
	NSString*				patchNameOption_;
}

@property (readwrite,assign) MacHgDocument*  myDocument;
@property (readwrite,assign) NSString*	patchNameOption;
@property BOOL textOption;
@property BOOL gitOption;
@property BOOL noDatesOption;
@property BOOL switchParentOption;

- (ExportPatchesSheetController*) initExportPatchesSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods - Log Inspector
- (IBAction) openExportPatchesSheetWithSelectedRevisions:(id)sender;
- (IBAction) sheetButtonOkForExportPatchesSheet:(id)sender;
- (IBAction) sheetButtonCancelForExportPatchesSheet:(id)sender;
- (IBAction) sheetButtonViewDifferencesForExportPatchesSheet:(id)sender;


- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


- (NSAttributedString*) formattedSheetMessage;

@end

