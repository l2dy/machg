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
	IBOutlet NSButton*	  removePathsButton;

	MacHgDocument* myDocument;

	BOOL			committingAllFiles;				// We need to set this up since some commands like merging need to "commit" all
													// files.
	NSMutableArray*	exculdedPaths;					// This array is stored here so we can exclude certain files from being
													// committed
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
- (IBAction) commitSheetDiffAction:(id)sender;
- (IBAction) handleChangedFilesTableClick:(id)sender;
- (IBAction) handleChangedFilesTableDoubleClick:(id)sender;

@end
