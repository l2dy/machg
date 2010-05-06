//
//  RebaseSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"

@interface RebaseSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	IBOutlet NSWindow*		theRebaseSheet;						// Main sheet First
	IBOutlet NSButton*		okButton;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	rebaseSheetTitle;

	IBOutlet NSTextField*	sourceHeaderMessage;
	IBOutlet NSTextField*	destinationHeaderMessage;
	
	IBOutlet NSSplitView*	sourceSV;
	IBOutlet NSSplitView*	destinationSV;
	IBOutlet NSView*		sourceTop;
	IBOutlet NSView*		sourceBottom;
	IBOutlet NSView*		destinationTop;
	IBOutlet NSView*		destinationBottom;
	
	IBOutlet LogTableView*	sourceLogTableView;
	IBOutlet NSTextView*	detailedSourceEntryTextView;
	
	IBOutlet LogTableView*	destinationLogTableView;
	IBOutlet NSTextView*	detailedDestinationEntryTextView;
	
	BOOL					keepOriginalRevisions_;
	BOOL					keepOriginalBranchNames_;

	MacHgDocument*			myDocument;
}

@property (readwrite,assign) MacHgDocument*  myDocument;
@property (readwrite,assign) BOOL		  keepOriginalRevisions;
@property (readwrite,assign) BOOL		  keepOriginalBranchNames;


// Initialization
- (RebaseSheetController*) initRebaseSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods - Log Inspector
- (IBAction) openRebaseSheetWithSelectedRevisions:(id)sender;
- (IBAction) sheetButtonOkForRebaseSheet:(id)sender;
- (IBAction) sheetButtonCancelForRebaseSheet:(id)sender;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


- (NSAttributedString*) formattedSheetMessage;

@end


@interface NoDividerSplitView : NSSplitView
{
}
- (void) drawDividerInRect:(NSRect)aRect;
@end

