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
#import "StandardSplitView.h"

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
}

@property (weak,readonly) MacHgDocument*  myDocument;

@property BOOL	keepOriginalRevisions;
@property BOOL	keepOriginalBranchNames;


// Initialization
- (RebaseSheetController*) initRebaseSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods
- (IBAction) openRebaseSheetWithSelectedRevisions:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;

@end


@interface ClippedStandardSplitView : StandardSplitView <NSSplitViewDelegate>
@end

