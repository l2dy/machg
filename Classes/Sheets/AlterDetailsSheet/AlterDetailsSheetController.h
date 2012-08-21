//
//  AlterDetailsSheetController.h
//  MacHg
//
//  Created by Jason Harris on 18/02/12.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"


@interface AlterDetailsSheetController : BaseSheetWindowController <ControllerForLogTableView>
{
	IBOutlet NSWindow*		theChooseChangesetSheet;
	IBOutlet NSTextField*	chooseChangesetSheetTitle;
	IBOutlet NSTextField*	chooseChangesetMessageTextField;
	IBOutlet NSTextField*	chooseChangesetInformativeMessageTextField;
	IBOutlet LogTableView*	logTableView;
	IBOutlet NSSplitView*	inspectorSplitView;
	IBOutlet NSButton*		chooseChangesetButton;

	IBOutlet NSWindow*		theAlterDetailsSheet;
	IBOutlet NSTextField*	alterDetailsSheetTitle;
	IBOutlet NSTextField*	alterDetailsMessageTextField;
	IBOutlet NSTextField*	alterDetailsInformativeMessageTextField;
	IBOutlet NSTextView*	alterDetailsCommitMessageTextView;
	IBOutlet NSTextField*	alterDetailsCommitterTextField;
	IBOutlet NSDatePicker*	alterDetailsDatePicker;
	IBOutlet NSButton*		alterDetailsButton;

	MacHgDocument*	__strong myDocument;
	LogEntry*		entryToAlter_;
	NSString*		__strong commitMessage_;					// The commit message
	NSString*		__strong committer_;						// The value of the committer option
	NSDate*			__strong commitDate_;					// The value of the date option
}
@property (readwrite,strong) MacHgDocument* myDocument;
@property (readwrite,strong) NSString*		commitMessage;
@property (readwrite,strong) NSString*		committer;
@property (readwrite,strong) NSDate*		commitDate;


- (AlterDetailsSheetController*) initAlterDetailsSheetControllerWithDocument:(MacHgDocument*)doc;


// Actions
- (IBAction) validateChooseChangesetButtons:(id)sender;
- (IBAction) openAlterDetailsChooseChangesetSheet:(id)sender;
- (IBAction) sheetButtonChooseChangesetAlter:(id)sender;
- (IBAction) closeChooseChangesetSheet:(id)sender;

- (IBAction) validateAlterDetailsButtons:(id)sender;
- (IBAction) openAlterDetailsSheet:(id)sender;
- (IBAction) sheetButtonAlterDetailsAlter:(id)sender;
- (IBAction) closeAlterDetailsSheet:(id)sender;

- (IBAction) sheetButtonCancel:(id)sender;


// Delegates
- (void)	 controlTextDidChange:(NSNotification*)aNotification;

// Table delegate methods
- (void)	 logTableViewSelectionDidChange:(LogTableView*)theLogTable;

@end
