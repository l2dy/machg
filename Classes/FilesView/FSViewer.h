//
//  FSBrowser.h
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import <Quartz/Quartz.h>	// Quartz framework provides the QLPreviewPanel public API


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  ControllerForFSBrowser
// -----------------------------------------------------------------------------------------------------------------------------------------
// All Controllers which embed a FSBrowser must conform to this protocol
@protocol ControllerForFSBrowser <NSObject>
- (NSArray*)		statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath;
- (NSArray*)		resolveStatusLines: (NSArray*)absolutePaths withRootPath:(NSString*)rootPath;
- (BOOL)			writeRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard*)pasteboard;	// dragging support
- (MacHgDocument*)	myDocument;
- (void)			updateCurrentPreviewImage;
- (void)			awakeFromNib;	// This routine needs to be able to be called multiple times on the Controller parent of the
									// FSBrowser, yet interanlly fire only once
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PathQuickLookPreviewItem
// -----------------------------------------------------------------------------------------------------------------------------------------
@interface PathQuickLookPreviewItem : NSObject <QLPreviewItem>
{
	NSString*    path_;		// absolute path of the item to preview
	NSRect       itemRect_;	// rect in the windows coordinate system
}
+ (PathQuickLookPreviewItem*) previewItemForPath:(NSString*)path withRect:(NSRect)rect;
- (NSRect) frameRectOfPath;
- (NSURL*) previewItemURL;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FSViewerProtocol
// -----------------------------------------------------------------------------------------------------------------------------------------
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
- (NSArray*)	chosenNodes;


// Path and Selection Operations
- (BOOL)		singleFileIsChosenInBrowser;		// Not debugged
- (BOOL)		singleItemIsChosenInBrowser;		// Not debugged
- (HGStatus)	statusOfChosenPathsInBrowser;
- (NSArray*)	absolutePathsOfSelectedFilesInBrowser;
- (NSArray*)	absolutePathsOfChosenFilesInBrowser;
- (NSString*)	enclosingDirectoryOfChosenFilesInBrowser;
- (NSArray*)	filterPaths:(NSArray*)absolutePaths byBitfield:(HGStatus)status;


// Graphic Operations
- (NSRect)		frameinWindowOfRow:(NSInteger)row inColumn:(NSInteger)column;

- (BOOL)		clickedNodeCoincidesWithTerminalSelections;

- (void)		reloadData;
- (void)		reloadDataSin;
- (void)		repositoryDataIsNew;	// Reset the repository root and regenerate all the data and reload it.
- (NSArray*)	quickLookPreviewItems;

// Save and restore browser, outline, or table state
- (FSViewerSelectionState*)	saveViewerSelectionState;
- (void)					restoreViewerSelectionState:(FSViewerSelectionState*)savedState;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewer
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface FSViewer : NSBox <FSViewerProtocol>
{
	IBOutlet id <ControllerForFSBrowser> parentController;
	IBOutlet NSMenu* contextualMenuForFSViewerPane;
	
	NSString*		absolutePathOfRepositoryRoot_;
	FSNodeInfo*		rootNodeInfo_;
	BOOL			areNodesVirtual_;				// Is this browser used to display virtual nodes?
	BOOL			isMainFSBrowser_;

 @private
	FSViewerBrowser*	theFilesBrowser_;
	FSViewerOutline*	theFilesOutline_;
	FSViewerTable*		theFilesTable_;
	FSViewerNum			currentFSViewerPane_;			// The current style of viewing the files, ie browser, outline, or table

	dispatch_once_t		theFilesBrowserInitilizer_;
	dispatch_once_t		theFilesOutlineInitilizer_;
	dispatch_once_t		theFilesTableInitilizer_;	
}

@property (readwrite,assign) BOOL		areNodesVirtual;
@property (readwrite,assign) BOOL		isMainFSBrowser;
@property (readwrite,assign) NSString*	absolutePathOfRepositoryRoot;


// Access the FSViewerPanes
- (FSViewerBrowser*)	theFilesBrowser;
- (FSViewerOutline*)	theFilesOutline;
- (FSViewerTable*)		theFilesTable;


// Initialization
- (void)		unload;
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
- (FSViewerNum)	currentFSViewerPaneNum;
- (void)		setCurrentFSViewerPane:(FSViewerNum)styleNum;
- (NSView<FSViewerProtocol>*)	currentViewerPane;


// Common Path and Selection Operations
- (BOOL)		statusOfChosenPathsInBrowserContain:(HGStatus)status;
- (BOOL)		repositoryHasFilesWhichContainStatus:(HGStatus)status;


// Menu Item Actions
- (IBAction)	browserMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction)	browserMenuOpenTerminalHere:(id)sender;
- (IBAction)	browserMenuRevealSelectedFilesInFinder:(id)sender;


// Action Utilities
- (BrowserDoubleClickAction) actionEnumForBrowserDoubleClick;	// Get the keyboard modifier state and return the corresponding action enum for a double click


// Drag and Drop
- (BOOL)		writeRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard*)pasteboard;


// Refresh / Regenrate Browser
- (void)		markPathsDirty:(RepositoryPaths*)dirtyPaths;
- (void)		refreshBrowserPaths:(RepositoryPaths*)changes finishingBlock:(BlockProcess)theBlock;
- (void)		repositoryDataIsNew;								// Reset the repository root and regenerate all the data and reload it.
- (void)		regenerateBrowserDataAndReload;						// Regenerate all the data for the browser and reload the browser.
- (void)		updateCurrentPreviewImage;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewerSelectionState
// -----------------------------------------------------------------------------------------------------------------------------------------

// This is a way to save the state of any FSViewer, be it browser, outline, or table.
@interface FSViewerSelectionState : NSObject
{
  @public
	// Information for saving a Browser state
	NSMutableArray*		savedColumnScrollPositions;
	NSPoint				savedHorizontalScrollPosition;

	// Information for saving an Outline state
	// XXXX
	// Information for saving a Table state
	// XXXX

	NSArray*			savedSelectedPaths;
	BOOL				restoreFirstResponderToViewer;
}

@property (readwrite,assign) BOOL				restoreFirstResponderToViewer;
@property (readwrite,assign) NSMutableArray*	savedColumnScrollPositions;
@property (readwrite,assign) NSPoint			savedHorizontalScrollPosition;
@property (readwrite,assign) NSArray*			savedSelectedPaths;

@end



