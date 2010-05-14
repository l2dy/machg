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
	LabelData*				labelToMove_;
	
	// Main window
	IBOutlet NSWindow*		theMoveLabelSheet;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSTextField*	labelToMoveTextField;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	moveLabelSheetTitle;
	IBOutlet NSButton*		okButton;
}


@property (readwrite,assign) MacHgDocument*  myDocument;


// Initialization
- (MoveLabelSheetController*) initMoveLabelSheetControllerWithDocument:(MacHgDocument*)doc;


// Action Methods
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (void)	 openMoveLabelSheetForMoveLabel:(LabelData*)label;


// Table delegate methods
- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable;


- (NSAttributedString*) formattedSheetMessage;

@end
