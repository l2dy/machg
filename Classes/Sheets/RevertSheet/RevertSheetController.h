//
//  RevertSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface RevertSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	MacHgDocument*			myDocument;
	NSArray*				absolutePathsOfFilesToRevert;	// This array is stored here when the sheet is set up. Later when
															// the user hits the revert button it is used to do the revert.

	// Main window
	IBOutlet NSWindow*		theRevertSheet;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextView*	selectedFilesTextView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	revertSheetTitle;
}


@property (readwrite,assign) MacHgDocument*  myDocument;


// Initialization
- (RevertSheetController*) initRevertSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods - Log Inspector
- (IBAction) openRevertSheetWithAllFiles:(id)sender;
- (IBAction) openRevertSheetWithSelectedFiles:(id)sender;
- (IBAction) sheetButtonOkForRevertSheet:(id)sender;
- (IBAction) sheetButtonCancelForRevertSheet:(id)sender;
- (IBAction) sheetButtonViewDifferencesForRevertSheet:(id)sender;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


- (NSAttributedString*) formattedSheetMessage;
- (void) openRevertSheetWithPaths:(NSArray*)paths andRevision:(NSString*)revision;

@end
