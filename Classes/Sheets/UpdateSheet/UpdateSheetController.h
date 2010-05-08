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

	MacHgDocument*			myDocument;

	// Main window
	IBOutlet NSWindow*		theUpdateSheet;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	updateSheetTitle;
	IBOutlet NSButton*		okButton;
	
	// Lower TabView Panes
	IBOutlet NSTextView*	detailedEntryTextView;
	
	BOOL					cleanUpdate_;
}

@property (readwrite,assign) MacHgDocument*  myDocument;
@property BOOL cleanUpdate;

- (UpdateSheetController*) initUpdateSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods
- (IBAction) validate:(id)sender;
- (void)     openUpdateSheetWithRevision:(NSString*)revision;
- (IBAction) openUpdateSheetWithCurrentRevision:(id)sender;
- (IBAction) sheetButtonOkForUpdateSheet:(id)sender;
- (IBAction) sheetButtonCancelForUpdateSheet:(id)sender;
- (IBAction) sheetButtonViewDifferencesForUpdateSheet:(id)sender;


- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


- (NSAttributedString*) formattedSheetMessage;
- (void) openUpdateSheetWithRevision:(NSString*)revision;

@end

