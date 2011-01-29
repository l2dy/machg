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
// MARK: FSBrowser
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface FSBrowser : NSBrowser <NSBrowserDelegate>
{
	IBOutlet id <ControllerForFSBrowser> parentController;
	
	NSString*			absolutePathOfRepositoryRoot_;
	FSNodeInfo*			rootNodeInfo_;
	BOOL				areNodesVirtual_;				// Is this browser used to display virtual nodes?
	BOOL				isMainFSBrowser_;

	NSViewController*	browserLeafPreviewController_;
}

@property (readwrite,assign) BOOL			areNodesVirtual;
@property (readwrite,assign) BOOL			isMainFSBrowser;
@property (readwrite,assign) NSString*		absolutePathOfRepositoryRoot;


// Initialization
- (void)		unload;
- (IBAction)	reloadData:(id)sender;
- (void)		reloadDataSin;
- (FSNodeInfo*) rootNodeInfo;


// Chained
- (NSWindow*)	parentWindow;
- (MacHgDocument*) myDocument;


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
- (BOOL)		singleFileIsChosenInBrower;
- (BOOL)		singleItemIsChosenInBrower;
- (HGStatus)	statusOfChosenPathsInBrowser;
- (BOOL)		statusOfChosenPathsInBrowserContain:(HGStatus)status;
- (BOOL)		repositoryHasFilesWhichContainStatus:(HGStatus)status;
- (NSArray*)	absolutePathsOfSelectedFilesInBrowser;
- (NSArray*)	absolutePathsOfChosenFilesInBrowser;
- (NSString*)	enclosingDirectoryOfChosenFilesInBrowser;
- (FSNodeInfo*)	parentNodeInfoForColumn:(NSInteger)column;


// Graphic Operations
- (NSRect)		frameinWindowOfRow:(NSInteger)row inColumn:(NSInteger)column;


// Menu Item Actions
- (IBAction)	browserMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction)	browserMenuOpenTerminalHere:(id)sender;
- (IBAction)	browserMenuRevealSelectedFilesInFinder:(id)sender;


// Action Utilities
- (BrowserDoubleClickAction) actionEnumForBrowserDoubleClick;	// Get the keyboard modifier state and return the corresponding action enum for a double click


// Refresh / Regenrate Browser
- (void)		setRowHeightForFont;
- (void)		markPathsDirty:(RepositoryPaths*)dirtyPaths;
- (void)		refreshBrowserPaths:(RepositoryPaths*)changes finishingBlock:(BlockProcess)theBlock;
- (void)		repositoryDataIsNew;								// Reset the repository root and regenerate all the data and reload it.
- (void)		regenerateBrowserDataAndReload;						// Regenerate all the data for the browser and reload the browser.

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: BrowserSelectionState
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface BrowserSelectionState : NSObject
{
	NSMutableArray* savedColumnScrollPositions;
	NSPoint			savedHorizontalScrollPosition;
	NSArray*		savedSelectedPaths;
	BOOL			restoreFirstResponderToBrowser;
	FSBrowser*		theBrowser;
}

@property (readwrite,assign) BOOL				restoreFirstResponderToBrowser;
@property (readwrite,assign) NSMutableArray*	savedColumnScrollPositions;
@property (readwrite,assign) NSPoint			savedHorizontalScrollPosition;
@property (readwrite,assign) NSArray*			savedSelectedPaths;


// Save and restore browser state
+ (BrowserSelectionState*)	saveBrowserState:(FSBrowser*)browser;
- (void)					restoreBrowserSelection;

@end



