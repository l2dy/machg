//
//  DifferencesViewController.h
//  MacHg
//
//  Created by Jason Harris on 15/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"
#import "FSBrowser.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  DifferencesViewController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface DifferencesViewController : NSViewController
{
	MacHgDocument*				myDocument;
	IBOutlet DifferencesView*	theDifferencesView;
}
@property (readwrite,assign) MacHgDocument*		myDocument;
@property (readwrite,assign) DifferencesView*	theDifferencesView;

- (DifferencesViewController*) initDifferencesViewControllerWithDocument:(MacHgDocument*)doc;
- (void) unload;
@end


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  DifferencesView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface DifferencesView : NSView < ControllerForLogTableView, ControllerForFSBrowser, NSUserInterfaceValidations >
{
	IBOutlet DifferencesViewController*  parentController;
	MacHgDocument*				myDocument;

	IBOutlet BWSplitView*		mainSplitView;

	IBOutlet NSTextField*		baseHeaderMessage;
	IBOutlet NSTextField*		compareHeaderMessage;

	IBOutlet NSSplitView*		baseSV;
	IBOutlet NSSplitView*		compareSV;
	IBOutlet NSView*			baseTop;
	IBOutlet NSView*			baseBottom;
	IBOutlet NSView*			compareTop;
	IBOutlet NSView*			compareBottom;

	IBOutlet LogTableView*		baseLogTableView;
	IBOutlet NSTextView*		detailedBaseEntryTextView;

	IBOutlet LogTableView*		compareLogTableView;
	IBOutlet NSTextView*		detailedCompareEntryTextView;

	IBOutlet FSBrowser*			theBrowser;

	
	BOOL						showCleanFilesInBrowser_;
	BOOL						showModifiedFilesInBrowser_;
	BOOL						showAddedFilesInBrowser_;
	BOOL						showRemovedFilesInBrowser_;
	BOOL						showMissingFilesInBrowser_;
	BOOL						showUnknownFilesInBrowser_;
	BOOL						showIgnoredFilesInBrowser_;
	BOOL						showUnresolvedFilesInBrowser_;
	BOOL						showResolvedFilesInBrowser_;
	int							numberOfTableRows;
	NSMutableArray*				theTableRows;				// Map of table row -> revision number
	NSString*					repositoryRootPath;			// The root of the repository being browsed
	
}

@property (readwrite,assign) BOOL showAddedFilesInBrowser;
@property (readwrite,assign) BOOL showIgnoredFilesInBrowser;
@property (readwrite,assign) BOOL showMissingFilesInBrowser;
@property (readwrite,assign) BOOL showModifiedFilesInBrowser;
@property (readwrite,assign) BOOL showRemovedFilesInBrowser;
@property (readwrite,assign) BOOL showUnknownFilesInBrowser;
@property (readwrite,assign) BOOL showCleanFilesInBrowser;
@property (readwrite,assign) BOOL showUnresolvedFilesInBrowser;
@property (readwrite,assign) BOOL showResolvedFilesInBrowser;
@property (readwrite,assign) MacHgDocument*  myDocument;
@property (readwrite,assign) FSBrowser*  theBrowser;

- (void) unload;



- (IBAction)	validateButtons:(id)sender;
- (IBAction)	openDifferencesView:(id)sender;
- (IBAction)	refreshDifferencesView:(id)sender;
- (void)		scrollToSelected;
- (IBAction)	redisplayBrowser:(id)sender;
- (void)		updateCurrentPreviewImage;

// Selecting revisions
- (void)		compareLowHighValue:(NSValue*)pairAsValue;
- (void)		compareLow:(NSString*)low toHigh:(NSString*)high;


// Overridden Menu Actions
- (IBAction)	differencesMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction)	differencesMenuRevealSelectedFilesInFinder:(id)sender;
- (IBAction)	differencesMenuOpenTerminalHere:(id)sender;
- (IBAction)	differencesMenuDiffSelectedFiles:(id)sender;
- (IBAction)	differencesMenuDiffAllFiles:(id)sender;
- (IBAction)	differencesMenuAnnotateSelectedFiles:(id)sender;
- (IBAction)	differencesMenuNoAction:(id)sender;

- (IBAction)	mainMenuDiffSelectedFiles:(id)sender;
- (IBAction)	mainMenuDiffAllFiles:(id)sender;
- (IBAction)	toolbarDiffFiles:(id)sender;


// Validation
- (BOOL)		validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;


// Delegated Actions
- (IBAction)	browserSingleClick:(id)sender;
- (IBAction)	browserDoubleClick:(id)sender;


// Delegate Methods
- (void)		logTableViewSelectionDidChange:(LogTableView*)theLogTable;
- (NSArray*)	statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath;
- (void)		splitViewDidResizeSubviews:(NSNotification*)aNotification;


@end
