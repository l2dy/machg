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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitFSViewer
// ------------------------------------------------------------------------------------

@interface CommitFSViewer : FSViewer
@end




// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitSheetController
// ------------------------------------------------------------------------------------

@interface CommitSheetController : BaseSheetWindowController <ControllerForFSViewer>
{
	IBOutlet CommitFSViewer* commitFilesViewer;
	IBOutlet NSTextField* commitSheetTitle;
	IBOutlet NSTextView*  commitMessageTextView;
	IBOutlet NSTableView* previousCommitMessagesTableView;
	IBOutlet NSTextField* commitSheetBranchString;
	
	IBOutlet NSWindow*	  theCommitSheet;
	IBOutlet NSButton*	  diffButton;
	IBOutlet NSButton*	  okButton;
	IBOutlet NSButton*	  amendButton;
	IBOutlet NSButton*	  commitSubstateButton;
	IBOutlet DisclosureBoxController*	disclosureController;	// The disclosure box for the advanced options


	BOOL			committingAllFiles;				// We need to set this up since some commands like merging need to "commit" all
													// files.
	NSArray*		logCommentsTableSourceData;		// This array is computed whenever we put up the
													// sheet, but the tableview in the sheet uses this class as a data
													// source so we have to have this as a class member.
	BOOL			amendIsPossible_;				// Is the amend operation even possible. This is determined at sheet opening time.
	
	// Advanaced commit options
	NSString*		cachedCommitMessageForAmend_;	// When the amend option has been activated we need to swap out the current
													// commit message for the last revision's commit message
	BOOL			hasHgSub_;						// Does this repository have a .hgsub file
}
@property (weak,readonly) MacHgDocument* myDocument;
@property NSString*	committer;						// The value of the committer option
@property BOOL		committerOption;				// Has the committer option been specified
@property BOOL		dateOption;						// Has the committer option been specified
@property NSDate*	date;							// The value of the date option
@property BOOL		amendOption;					// Has the amend option been specified
@property BOOL		commitSubstateOption;			// Has the commit substate option been specified
@property NSArray*	absolutePathsOfFilesToCommit;

- (CommitSheetController*) initCommitSheetControllerWithDocument:(MacHgDocument*)doc;


- (IBAction) openCommitSheetWithAllFiles:(id)sender;
- (IBAction) openCommitSheetWithSelectedFiles:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;

- (IBAction) commitSheetDiffAction:(id)sender;
- (void)	 makeMessageFieldFirstResponder;

@end

