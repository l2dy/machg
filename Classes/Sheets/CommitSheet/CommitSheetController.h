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
@class CommitFilesTableView;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface CommitSheetController : BaseSheetWindowController
{
	IBOutlet CommitFilesTableView* commitFilesTableView;
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitFileInfo
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface CommitFileInfo : NSObject
{
	HGStatus			hgStatus;			// This is the status of the file about to be committed (modified, added, or removed)
	NSString*			filePath;			// This is the path relative to the repository root
	NSString*			absoluteFilePath;	// This is the path relative to the repository root
	NSImage*			fileImage;			// The icon for the given file
	NSImage*			statusImage;		// The status icon corresponding to this hgStatus
	NSInteger			lineCount;			// This is the number of lines in the file
	NSInteger			additionLineCount;	// This is the number of lines being added in the change
	NSInteger			removalLineCount;	// This is the number of lines being removed in the change
	CommitCheckBoxState	commitState;		// This is the state of the file we are about to commit (all the changes in the file,
											// none of the changes in the file, or some of the changes in the file.) 
	CommitFilesTableView* parent;			// The parent of this CommitFileInfo
}
@property (readwrite,assign) HGStatus				hgStatus;
@property (readwrite,assign) NSString*				filePath;
@property (readwrite,assign) NSString*				absoluteFilePath;
@property (readwrite,assign) NSImage*				fileImage;
@property (readwrite,assign) NSImage*				statusImage;
@property (readwrite,assign) NSInteger				lineCount;
@property (readwrite,assign) NSInteger				additionLineCount;
@property (readwrite,assign) NSInteger				removalLineCount;
@property (readwrite,assign) CommitCheckBoxState	commitState;
@property (readwrite,assign) CommitFilesTableView*	parent;

- (id) initWithStatusLine:(NSString*)statusLine withRoot:(NSString*)rootPath andParent:(CommitFilesTableView*)theParent;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitFilesTableView
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface CommitFilesTableView : NSTableView <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet CommitSheetController*	parentController;	// The parent controller
	
	NSArray*	commitDataArray;						// An array of CommitFileInfo
}
@property (readwrite,assign) NSArray*	commitDataArray;

// Initialization
- (void) resetTableDataWithPaths:(NSArray*)paths;

- (NSArray*) allFilesToCommit;
- (NSArray*) filteredFilesToCommit;
- (NSArray*) chosenFilesToCommit;
- (BOOL)	 rowsAreSelected;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Cells For CommitFilesTableView
// -----------------------------------------------------------------------------------------------------------------------------------------


@interface CommitFilesTableButtonCell : NSButtonCell
{
	CommitFileInfo*	commitFileInfo_;
}
@property (assign,readwrite) CommitFileInfo*	commitFileInfo;
@end

@interface CommitFilesTableImageCell : NSImageCell
{
	CommitFileInfo*	commitFileInfo_;
}
@property (assign,readwrite) CommitFileInfo*	commitFileInfo;
@end

@interface CommitFilesTableTextCell : NSTextFieldCell
{
	CommitFileInfo*	commitFileInfo_;
}
@property (assign,readwrite) CommitFileInfo*	commitFileInfo;
@end
