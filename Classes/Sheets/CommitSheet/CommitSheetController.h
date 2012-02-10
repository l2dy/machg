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
#import "FSViewer.h"
@class CommitFilesTableView;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface CommitSheetController : BaseSheetWindowController <ControllerForFSViewer>
{
	IBOutlet FSViewer*	  commitFilesViewer;
	IBOutlet NSTextField* commitSheetTitle;
	IBOutlet NSTextView*  commitMessageTextView;
	IBOutlet NSTableView* previousCommitMessagesTableView;
	IBOutlet NSTextField* commitSheetBranchString;
	
	IBOutlet NSWindow*	  theCommitSheet;
	IBOutlet NSButton*	  diffButton;
	IBOutlet NSButton*	  okButton;
	IBOutlet NSButton*	  amendButton;
	IBOutlet DisclosureBoxController*	disclosureController;	// The disclosure box for the advanced options

	
	MacHgDocument*	myDocument;
	
	BOOL			committingAllFiles;				// We need to set this up since some commands like merging need to "commit" all
													// files.
	NSArray*		absolutePathsOfFilesToCommit;	// This array is stored here when the sheet is set up. Later when
													// the user hits the commit button it does this commit.
	NSMutableIndexSet* excludedItems;				// This index set stores the rows in the list we will exclude from the final commit.

	NSArray*		logCommentsTableSourceData;		// This array is computed whenever we put up the
													// sheet, but the tableview in the sheet uses this class as a data
													// source so we have to have this as a class member.
	
	// Advanaced commit options
	NSString*		committer_;						// The value of the committer option
	BOOL			committerOption_;				// Has the committer option been specified
	NSDate*			date_;							// The value of the date option
	BOOL			dateOption_;					// Has the committer option been specified
	BOOL			amendOption_;					// Has the amend option been specified
	NSString*		cachedCommitMessageForAmend_;	// When the amend option has been activated we need to swap out the current
													// commit message for the last revision's commit message
}
@property (readwrite,assign) MacHgDocument* myDocument;
@property (readwrite,assign) BOOL			committerOption;
@property (readwrite,assign) NSString*		committer;
@property (readwrite,assign) BOOL			dateOption;
@property (readwrite,assign) NSDate*		date;
@property (readwrite,assign) BOOL			amendOption;

- (CommitSheetController*) initCommitSheetControllerWithDocument:(MacHgDocument*)doc;


- (IBAction) openCommitSheetWithAllFiles:(id)sender;
- (IBAction) openCommitSheetWithSelectedFiles:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;

- (IBAction) commitSheetDiffAction:(id)sender;
- (void)	 makeMessageFieldFirstResponder;

@end

