//
//  CommitSheetController.h
//  MacHg
//
//  Created by Jason Harris on 30/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "BaseSheetWindowController.h"
@class MacHgDocument;

@interface CommitSheetController : BaseSheetWindowController
{
	IBOutlet NSTextField* commitSheetTitle;
	IBOutlet NSTextView*  commitMessageTextView;
	IBOutlet NSTableView* changedFilesTableView;
	IBOutlet NSTableView* previousCommitMessagesTableView;
	IBOutlet NSTextField* commitSheetBranchString;
	IBOutlet NSWindow*	  theCommitSheet;
	IBOutlet NSButton*	  diffButton;
	IBOutlet NSButton*	  okButton;
	IBOutlet NSButton*	  excludePathsButton;
	IBOutlet NSButton*	  includePathsButton;

	MacHgDocument* myDocument;

	BOOL			committingAllFiles;				// We need to set this up since some commands like merging need to "commit" all
													// files.
	NSArray*		absolutePathsOfFilesToCommit;	// This array is stored here when the sheet is set up. Later when
													// the user hits the commit button it does this commit.
	NSMutableIndexSet* excludedItems;				// This index set stores the rows in the list we will exclude from the final commit.

	NSMutableArray*	changedFilesTableSourceData;	// This array is computed whenever we put up the
													// sheet, but the tableview in the sheet uses this class as a data
													// source so we have to have this as a class member.
	NSArray*		logCommentsTableSourceData;		// This array is computed whenever we put up the
													// sheet, but the tableview in the sheet uses this class as a data
													// source so we have to have this as a class member.
}
@property (readwrite,assign) MacHgDocument*  myDocument;

- (CommitSheetController*) initCommitSheetControllerWithDocument:(MacHgDocument*)doc;


- (BOOL)	 filesToCommitAreSelected;
- (NSArray*) chosenFilesToCommit;


- (IBAction) openCommitSheetWithAllFiles:(id)sender;
- (IBAction) openCommitSheetWithSelectedFiles:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;

- (IBAction) exculdePathsAction:(id)sender;
- (IBAction) includePathsAction:(id)sender;
- (IBAction) commitSheetDiffAction:(id)sender;
- (IBAction) handleChangedFilesTableClick:(id)sender;
- (IBAction) handleChangedFilesTableDoubleClick:(id)sender;

@end
