//
//  MoveLabelSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface MoveLabelSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	MacHgDocument*			myDocument;
	NSArray*				absolutePathsOfFilesToRevert;	// This array is stored here when the sheet is set up. Later when
															// the user hits the revert button it is used to do the revert.
	
	// Main window
	IBOutlet NSWindow*		theMoveLabelSheet;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	labelToMoveTextField;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	moveLabelSheetTitle;
}


@property (readwrite,assign) MacHgDocument*  myDocument;


// Initialization
- (MoveLabelSheetController*) initMoveLabelSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods - Log Inspector
- (IBAction) openMoveLabelSheetWithAllFiles:(id)sender;
- (IBAction) openMoveLabelSheetWithSelectedFiles:(id)sender;
- (IBAction) sheetButtonOkForMoveLabelSheet:(id)sender;
- (IBAction) sheetButtonCancelForMoveLabelSheet:(id)sender;
- (IBAction) sheetButtonViewDifferencesForMoveLabelSheet:(id)sender;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


- (NSAttributedString*) formattedSheetMessage;
- (void) openMoveLabelSheetWithPaths:(NSArray*)paths andRevision:(NSString*)revision;

@end
