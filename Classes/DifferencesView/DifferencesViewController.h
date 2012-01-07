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
#import "FSViewer.h"





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

@interface DifferencesView : NSView < ControllerForLogTableView, ControllerForFSViewer, NSUserInterfaceValidations >
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

	IBOutlet FSViewer*			theFSViewer;

	
	BOOL						showCleanFilesInBrowser_;
	BOOL						showModifiedFilesInBrowser_;
	BOOL						showAddedFilesInBrowser_;
	BOOL						showRemovedFilesInBrowser_;
	BOOL						showMissingFilesInBrowser_;
	BOOL						showUntrackedFilesInBrowser_;
	BOOL						showIgnoredFilesInBrowser_;
	BOOL						showUnresolvedFilesInBrowser_;
	BOOL						showResolvedFilesInBrowser_;
	NSMutableArray*				theTableRows;				// Map of table row -> revision number
	NSString*					repositoryRootPath;			// The root of the repository being browsed
}

@property (readwrite,assign) BOOL showAddedFilesInBrowser;
@property (readwrite,assign) BOOL showIgnoredFilesInBrowser;
@property (readwrite,assign) BOOL showMissingFilesInBrowser;
@property (readwrite,assign) BOOL showModifiedFilesInBrowser;
@property (readwrite,assign) BOOL showRemovedFilesInBrowser;
@property (readwrite,assign) BOOL showUntrackedFilesInBrowser;
@property (readwrite,assign) BOOL showCleanFilesInBrowser;
@property (readwrite,assign) BOOL showUnresolvedFilesInBrowser;
@property (readwrite,assign) BOOL showResolvedFilesInBrowser;
@property (readwrite,assign) MacHgDocument*  myDocument;
@property (readwrite,assign) FSViewer*  theFSViewer;

- (void) unload;



- (IBAction)	validateButtons:(id)sender;
- (void)		prepareToOpenDifferencesView;
- (IBAction)	refreshDifferencesView:(id)sender;
- (void)		didSwitchViewTo:(FSViewerNum)viewNumber;
- (void)		scrollToSelected;
- (IBAction)	redisplayBrowser:(id)sender;
- (void)		updateCurrentPreviewImage;


// Quicklook
- (NSInteger)	numberOfQuickLookPreviewItems;


// Selecting revisions
- (void)		compareLowHighValue:(NSValue*)pairAsValue;
- (void)		compareLow:(NSString*)low toHigh:(NSString*)high;


// Contextual Menu Actions
- (IBAction)	mainMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction)	mainMenuRevealSelectedFilesInFinder:(id)sender;
- (IBAction)	mainMenuOpenTerminalHere:(id)sender;

- (IBAction)    differencesMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction)	differencesMenuAnnotateBaseRevisionOfSelectedFiles:(id)sender;
- (IBAction)	differencesMenuAnnotateCompareRevisionOfSelectedFiles:(id)sender;
- (IBAction)	differencesMenuNoAction:(id)sender;

- (IBAction)	mainMenuDiffSelectedFiles:(id)sender;
- (IBAction)	mainMenuDiffAllFiles:(id)sender;
- (IBAction)	toolbarDiffFiles:(id)sender;


// Validation
- (BOOL)		validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;


// Delegated Actions
- (IBAction)	browserAction:(id)sender;
- (IBAction)	browserDoubleAction:(id)sender;


// Delegate Methods
- (void)		logTableViewSelectionDidChange:(LogTableView*)theLogTable;
- (void)		splitViewDidResizeSubviews:(NSNotification*)aNotification;


@end
