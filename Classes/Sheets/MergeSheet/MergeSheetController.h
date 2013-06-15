//
//  MergeSheetController.h
//  MacHg
//
//  Created by Jason Harris on 15/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"


@interface MergeSheetController : BaseSheetWindowController < ControllerForLogTableView >
{
	IBOutlet NSWindow*		mergeSheetWindow;
	IBOutlet NSButton*		sheetButtonOkForMergeSheet;
	IBOutlet NSButton*		sheetButtonCancelForMergeSheet;

	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	mergeSheetTitle;
}

@property BOOL			forceTheMerge;
@property (weak,readonly) MacHgDocument*	myDocument;



// Initialization
- (MergeSheetController*) initMergeSheetControllerWithDocument:(MacHgDocument*)doc;
- (void)	 openMergeSheetWithRevision:(NSNumber*)revision;


// Validation
- (IBAction) validateButtons:(id)sender;


// Action methods
- (IBAction) openMergeSheet:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) sheetButtonViewDifferencesForMergeSheet:(id)sender;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


@end
