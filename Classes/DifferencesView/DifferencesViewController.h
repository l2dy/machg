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

@class DifferencesSplitView;




// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  DifferencesViewController
// ------------------------------------------------------------------------------------
// MARK: -

@interface DifferencesViewController : NSViewController

@property (weak,readonly) MacHgDocument*	myDocument;
@property IBOutlet DifferencesView*			theDifferencesView;

- (DifferencesViewController*) initDifferencesViewControllerWithDocument:(MacHgDocument*)doc;
@end


// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  DifferencesView
// ------------------------------------------------------------------------------------
// MARK: -

@interface DifferencesView : NSView < ControllerForLogTableView, ControllerForFSViewer, NSUserInterfaceValidations >
{
	IBOutlet DifferencesSplitView*	mainSplitView;

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

	NSMutableArray*				theTableRows;				// Map of table row -> revision number
	NSString*					repositoryRootPath;			// The root of the repository being browsed
}

@property (weak,readonly) MacHgDocument*  myDocument;
@property (assign) IBOutlet DifferencesViewController* parentController;

@property BOOL showAddedFilesInBrowser;
@property BOOL showIgnoredFilesInBrowser;
@property BOOL showMissingFilesInBrowser;
@property BOOL showModifiedFilesInBrowser;
@property BOOL showRemovedFilesInBrowser;
@property BOOL showUntrackedFilesInBrowser;
@property BOOL showCleanFilesInBrowser;
@property BOOL showUnresolvedFilesInBrowser;
@property BOOL showResolvedFilesInBrowser;
@property BOOL autoExpandViewerOutlines;

@property FSViewer*  theFSViewer;


- (void)		restoreDifferencesSplitViewPositions;


// Refreshing
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
- (IBAction)	fsviewerAction:(id)sender;
- (IBAction)	fsviewerDoubleAction:(id)sender;


// Delegate Methods
- (void)		logTableViewSelectionDidChange:(LogTableView*)theLogTable;
- (void)		splitViewDidResizeSubviews:(NSNotification*)aNotification;


@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: DifferencesSplitView
// ------------------------------------------------------------------------------------

@interface DifferencesSplitView : NSSplitView <NSSplitViewDelegate>
{
	IBOutlet NSView*	logTablesGroup;
	IBOutlet NSView*	filesViewerGroup;
}

@end

