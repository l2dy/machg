//
//  BackoutSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface BackoutSheetController : BaseSheetWindowController < ControllerForLogTableView >
{

	MacHgDocument*			myDocument;

	// Main window
	IBOutlet NSWindow*		theBackoutSheet;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	backoutSheetTitle;
	IBOutlet NSButton*		okButton;
	
	// Lower TabView Panes
	IBOutlet LogTableTextView*	detailedEntryTextView;
}

@property (readwrite,assign) MacHgDocument*  myDocument;

// Initilization
- (BackoutSheetController*) initBackoutSheetControllerWithDocument:(MacHgDocument*)doc;
- (void)	 openBackoutSheetWithRevision:(NSNumber*)revision;


// Action Methods
- (IBAction) validate:(id)sender;
- (IBAction) openBackoutSheetWithSelectedRevision:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) sheetButtonViewDifferencesForBackoutSheet:(id)sender;


- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


@end

