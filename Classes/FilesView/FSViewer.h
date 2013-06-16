//
//  FSBrowser.h
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import <Quartz/Quartz.h>	// Quartz framework provides the QLPreviewPanel public API
#import "PatchesWebview.h"





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  ControllerForFSViewer
// ------------------------------------------------------------------------------------
// All Controllers which embed a FSBrowser must conform to this protocol
@protocol ControllerForFSViewer <NSObject>
- (NSArray*)		statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath;
- (NSArray*)		resolveStatusLines: (NSArray*)absolutePaths withRootPath:(NSString*)rootPath;
- (BOOL)			writePaths:(NSArray*)paths toPasteboard:(NSPasteboard*)pasteboard;	// dragging support
- (MacHgDocument*)	myDocument;
- (IBAction)		fsviewerDoubleAction:(id)sender;
- (IBAction)		fsviewerAction:(id)sender;
- (void)			setMyDocumentFromParent;
- (void)			didSwitchViewTo:(FSViewerNum)viewNumber;
- (BOOL)			controlsMainFSViewer;
- (BOOL)			autoExpandViewerOutlines;
- (void)			updateCurrentPreviewImage;
- (void)			awakeFromNib;	// This routine needs to be able to be called multiple times on the Controller parent of the
									// FSBrowser, yet interanlly fire only once
- (HunkExclusions*) hunkExclusions;
@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  PathQuickLookPreviewItem
// ------------------------------------------------------------------------------------
@interface PathQuickLookPreviewItem : NSObject <QLPreviewItem>
{
	NSString*    path_;		// absolute path of the item to preview
	NSRect       itemRect_;	// rect in the windows coordinate system
}
+ (PathQuickLookPreviewItem*) previewItemForPath:(NSString*)path withRect:(NSRect)rect;
- (NSRect) frameRectOfPath;
- (NSURL*) previewItemURL;
@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  FSViewerProtocol
// ------------------------------------------------------------------------------------
// The main FSViewer object as well as all the FSViewerPanes must be able to perform the following methods. The main FSViewer just
// forwards these methods onto the current pane. 
@protocol FSViewerProtocol <NSObject>

// Opening
- (void)		prepareToOpenFSViewerPane;

// Testing of selection and clicks
- (BOOL)		nodesAreSelected;
- (BOOL)		nodeIsClicked;
- (BOOL)		nodesAreChosen;
- (FSNodeInfo*) clickedNode;
- (BOOL)		clickedNodeInSelectedNodes;
- (FSNodeInfo*) chosenNode;
- (NSArray*)	selectedNodes;
- (IBAction)	fsviewerDoubleAction:(id)sender;
- (IBAction)	fsviewerAction:(id)sender;


// Path and Selection Operations
- (BOOL)		singleFileIsChosenInFiles;		// Not debugged
- (BOOL)		singleItemIsChosenInFiles;		// Not debugged

- (BOOL)		clickedNodeCoincidesWithTerminalSelections;

- (void)		reloadData;
- (void)		reloadDataSin;
- (void)		repositoryDataIsNew;	// Reset the repository root and regenerate all the data and reload it.
- (NSRect)		rectInWindowForNode:(FSNodeInfo*)node;

// Save and restore browser, outline, or table state
- (FSViewerSelectionState*)	saveViewerSelectionState;
- (void)					restoreViewerSelectionState:(FSViewerSelectionState*)savedState;

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewer
// ------------------------------------------------------------------------------------

@interface FSViewer : NSBox <FSViewerProtocol, ControllerForPatchesWebview>
{
	IBOutlet PatchesWebview*	detailedPatchesWebView;
	IBOutlet NSMenu*			contextualMenuForFSViewerPane;

	FSNodeInfo*			rootNodeInfo_;

 @private
	NSViewController*	theFilesBrowserParent_;
	NSViewController*	theFilesOutlineParent_;
	NSViewController*	theFilesTableParent_;
	FSViewerBrowser*	theFilesBrowser_;
	FSViewerOutline*	theFilesOutline_;
	FSViewerTable*		theFilesTable_;
	FSViewerNum			currentFSViewerPane_;			// The current style of viewing the files, ie browser, outline, or table

	dispatch_once_t		theFilesBrowserInitilizer_;
	dispatch_once_t		theFilesOutlineInitilizer_;
	dispatch_once_t		theFilesTableInitilizer_;	
}

@property (ah_weak) IBOutlet id <ControllerForFSViewer> parentController;
@property BOOL		areNodesVirtual;							// Is this browser used to display virtual nodes?
@property NSString*	absolutePathOfRepositoryRoot;


// Access the FSViewerPanes
- (FSViewerBrowser*)	theFilesBrowser;
- (FSViewerOutline*)	theFilesOutline;
- (FSViewerTable*)		theFilesTable;


// Initialization
- (FSNodeInfo*) rootNodeInfo;


// Chained
- (NSWindow*)	parentWindow;
- (MacHgDocument*) myDocument;


// Pane switching
- (BOOL)		showingFilesBrowser;
- (BOOL)		showingFilesOutline;
- (BOOL)		showingFilesTable;
- (IBAction)	actionSwitchToFilesBrowser:(id)sender;
- (IBAction)	actionSwitchToFilesOutline:(id)sender;
- (IBAction)	actionSwitchToFilesTable:(id)sender;
- (FSViewerNum)	currentFSViewerPane;
- (void)		setCurrentFSViewerPane:(FSViewerNum)styleNum;
- (NSView<FSViewerProtocol>*)	currentViewerPane;


// Common Path and Selection Operations
- (NSArray*)	chosenNodes;
- (NSArray*)	absolutePathsOfSelectedFilesInBrowser;
- (NSArray*)	absolutePathsOfChosenFiles;
- (NSString*)	enclosingDirectoryOfChosenFiles;


// Status Operations
- (HGStatus)	statusOfChosenPathsInFiles;
- (BOOL)		statusOfChosenPathsInFilesContain:(HGStatus)status;
- (BOOL)		repositoryHasFilesWhichContainStatus:(HGStatus)status;
- (NSArray*)	filterPaths:(NSArray*)absolutePaths byBitfield:(HGStatus)status;


// Menu Item Actions
- (IBAction)	forceRefreshFSViewer:(id)sender;
- (IBAction)	viewerMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction)	browserMenuOpenTerminalHere:(id)sender;
- (IBAction)	browserMenuRevealSelectedFilesInFinder:(id)sender;


// Action Utilities
- (BrowserDoubleClickAction) actionEnumForBrowserDoubleClick;	// Get the keyboard modifier state and return the corresponding action enum for a double click


// Quicklook Support
- (NSInteger)	numberOfQuickLookPreviewItems;
- (NSArray*)	quickLookPreviewItems;
- (NSRect)		screenRectForNode:(FSNodeInfo*)node;


// Drag and Drop
- (BOOL)		writePaths:(NSArray*)paths toPasteboard:(NSPasteboard*)pasteboard;	// dragging support


// Refresh / Regenrate Browser
- (float)		rowHeightForFont;
- (void)		markPathsDirty:(RepositoryPaths*)dirtyPaths;
- (void)		refreshBrowserPaths:(RepositoryPaths*)changes finishingBlock:(BlockProcess)theBlock;
- (void)		repositoryDataIsNew;								// Reset the repository root and regenerate all the data and reload it.
- (void)		regenerateBrowserDataAndReload;						// Regenerate all the data for the browser and reload the browser.
- (void)		updateCurrentPreviewImage;
- (void)		viewerSelectionDidChange:(NSNotification*)notification;
- (void)		regenerateDifferencesInWebview;

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewerSelectionState
// ------------------------------------------------------------------------------------

// This is a way to save the state of any FSViewer, be it browser, outline, or table.
@interface FSViewerSelectionState : NSObject

// Information for saving a Browser state
@property NSMutableArray*	savedColumnScrollPositions;
@property NSPoint			savedHorizontalScrollPosition;
@property NSArray*			savedSelectedPaths;
@property BOOL				restoreFirstResponderToViewer;

@end



