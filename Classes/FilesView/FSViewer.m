//
//  FSBrowser.m
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "FSViewer.h"
#import "FSViewerBrowser.h"
#import "FSViewerOutline.h"
#import "FSViewerTable.h"
#import "MacHgDocument.h"
#import "FSNodeInfo.h"
#import "FSViewerPaneCell.h"
#import "ProcessListController.h"
#import "TaskExecutions.h"
#import "MonitorFSEvents.h"
#import "RepositoryData.h"
#import "ShellHere.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PathQuickLookPreviewItem
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation PathQuickLookPreviewItem
+ (PathQuickLookPreviewItem*) previewItemForPath:(NSString*)path withRect:(NSRect)rect
{
	PathQuickLookPreviewItem* previewItem = [[PathQuickLookPreviewItem alloc] init];
	previewItem->itemRect_ = rect;
	previewItem->path_ = path;
	return previewItem;
}
- (NSURL*) previewItemURL	{ return [NSURL fileURLWithPath:path_]; }
- (NSRect) frameRectOfPath  { return itemRect_; }
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSBrowser
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation FSViewer

@synthesize areNodesVirtual = areNodesVirtual_;
@synthesize absolutePathOfRepositoryRoot = absolutePathOfRepositoryRoot_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) viewerAutoSaveName { return fstr(@"File:%@:primaryViewer", [[parentController myDocument] documentNameForAutosave]); }

- (id) init
{
	self = [super init];
	rootNodeInfo_ = nil;
	return self;
}


- (void) awakeFromNib
{
	[self observe:kBrowserDisplayPreferencesChanged from:nil byCalling:@selector(reloadDataSin)];
	[parentController awakeFromNib];	// The parents must ensure that the internals of awakeFromNib only ever happen once.
	rootNodeInfo_ = nil;
	FSViewerNum viewerNum = [[NSUserDefaults standardUserDefaults] integerForKey:[self viewerAutoSaveName]];
	if (viewerNum == eFilesNoView)
		viewerNum = DefaultFilesViewFromDefaults() + 1;
	[self setCurrentFSViewerPane:viewerNum];
}

- (void) setupViewerPane:(id)view
{
	[view setParentViewer:self];
	[view setMenu:contextualMenuForFSViewerPane];
	[view setTarget:parentController];
	[view setAction:@selector(browserAction:)];
	[view setDoubleAction:@selector(browserDoubleAction:)];	
}

- (FSViewerBrowser*) theFilesBrowser
{
	dispatch_once(&theFilesBrowserInitilizer_, ^{
		// We can't use [NSBundle loadNibNamed:... owner:self] since that causes the FSViewer::awakeFromNib method to fire which
		// will call this method for a second time and we will lock at this dispatch_once again. Thus do this dance of loading the
		// nib and then hooking it up manually. 
		NSViewController* controller = [[NSViewController alloc] initWithNibName:@"FilesViewBrowser" bundle:nil];
		theFilesBrowser_ = DynamicCast(FSViewerBrowser, [controller view]);
		[self setupViewerPane:theFilesBrowser_];		
	});
	return theFilesBrowser_;
}

- (FSViewerOutline*) theFilesOutline
{
	dispatch_once(&theFilesOutlineInitilizer_, ^{
		// We can't use [NSBundle loadNibNamed:... owner:self] since that causes the FSViewer::awakeFromNib method to fire which
		// will call this method for a second time and we will lock at this dispatch_once again. Thus do this dance of loading the
		// nib and then hooking it up manually. 
		NSViewController* controller = [[NSViewController alloc] initWithNibName:@"FilesViewOutline" bundle:nil];
		theFilesOutline_ = DynamicCast(FSViewerOutline, [controller view]);
		[self setupViewerPane:theFilesOutline_];		
	});
	return theFilesOutline_;
}

- (FSViewerTable*) theFilesTable
{
	dispatch_once(&theFilesTableInitilizer_, ^{
		// We can't use [NSBundle loadNibNamed:... owner:self] since that causes the FSViewer::awakeFromNib method to fire which
		// will call this method for a second time and we will lock at this dispatch_once again. Thus do this dance of loading the
		// nib and then hooking it up manually. 
		NSViewController* controller = [[NSViewController alloc] initWithNibName:@"FilesViewTable" bundle:nil];
		theFilesTable_ = DynamicCast(FSViewerTable, [controller view]);
		[self setupViewerPane:theFilesTable_];
	});
	return theFilesTable_;
}


- (void) unload
{
	[self stopObserving];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Chained methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (MacHgDocument*)	myDocument		{ return [parentController myDocument]; }
- (NSWindow*)		parentWindow	{ return [[parentController myDocument] mainWindow]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Pane switching
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSView*) primaryViewOfFSViewerPane:(FSViewerNum)styleNum
{
	switch (styleNum)
	{
		case eFilesBrowser:		return [[self theFilesBrowser] enclosingBoxView];
		case eFilesOutline:		return [[self theFilesOutline] enclosingScrollView];
		case eFilesTable:		return [[self theFilesTable] enclosingBoxView];
		default:				return nil;
	}
}

- (NSView<FSViewerProtocol>*) viewerPane:(FSViewerNum)styleNum
{
	switch (styleNum)
	{
		case eFilesBrowser:		return [self theFilesBrowser];
		case eFilesOutline:		return [self theFilesOutline];
		case eFilesTable:		return [self theFilesTable];
		default:				return nil;
	}
}

- (NSView<FSViewerProtocol>*) currentViewerPane			{ return [self viewerPane:currentFSViewerPane_]; }
- (BOOL)	 showingFilesBrowser						{ return currentFSViewerPane_ == eFilesBrowser; }
- (BOOL)	 showingFilesOutline						{ return currentFSViewerPane_ == eFilesOutline; }
- (BOOL)	 showingFilesTable							{ return currentFSViewerPane_ == eFilesTable; }
- (IBAction) actionSwitchToFilesBrowser:(id)sender		{ [self setCurrentFSViewerPane:eFilesBrowser]; }
- (IBAction) actionSwitchToFilesOutline:(id)sender		{ [self setCurrentFSViewerPane:eFilesOutline]; }
- (IBAction) actionSwitchToFilesTable:(id)sender		{ [self setCurrentFSViewerPane:eFilesTable]; }
- (FSViewerNum)	currentFSViewerPaneNum					{ return currentFSViewerPane_; }

- (void) setCurrentFSViewerPane:(FSViewerNum)styleNum
{
	NSView* view = [self primaryViewOfFSViewerPane:styleNum];
	[[self viewerPane:styleNum] prepareToOpenFSViewerPane];
	[self setContentView:view];
	currentFSViewerPane_ = styleNum;
	[parentController didSwitchViewTo:styleNum];
}

- (void) prepareToOpenFSViewerPane
{
	[[self currentViewerPane] prepareToOpenFSViewerPane];	
}
	





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path and Selection Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (FSNodeInfo*) rootNodeInfo			{ return rootNodeInfo_; }
- (void) reloadData						{ [[self currentViewerPane] reloadData]; }
- (void) reloadDataSin					{ [[self currentViewerPane] reloadDataSin]; }


- (BOOL)		nodesAreSelected		{ return [[self currentViewerPane] nodesAreSelected]; }
- (BOOL)		nodeIsClicked			{ return [[self currentViewerPane] nodeIsClicked]; }
- (BOOL)		nodesAreChosen			{ return [[self currentViewerPane] nodesAreChosen]; }
- (FSNodeInfo*) chosenNode				{ return [[self currentViewerPane] chosenNode]; }
- (FSNodeInfo*) clickedNode				{ return [[self currentViewerPane] clickedNode]; }
- (NSArray*) selectedNodes				{ return [[self currentViewerPane] selectedNodes]; }
- (BOOL) singleFileIsChosenInFiles		{ return [[self currentViewerPane] singleFileIsChosenInFiles]; }
- (BOOL) singleItemIsChosenInFiles		{ return [[self currentViewerPane] singleItemIsChosenInFiles]; }
- (BOOL) clickedNodeInSelectedNodes		{ return [[self currentViewerPane] clickedNodeInSelectedNodes]; }

- (BOOL) clickedNodeCoincidesWithTerminalSelections		{ return [[self currentViewerPane] clickedNodeCoincidesWithTerminalSelections]; }



- (NSArray*) chosenNodes
{
	if ([self nodeIsClicked] && ![self clickedNodeInSelectedNodes])
		return [NSArray arrayWithObject:[self clickedNode]];	
	return [self selectedNodes];
}


- (NSArray*) absolutePathsOfSelectedFilesInBrowser
{
	NSArray* theSelectedNodes = [self selectedNodes];
	if (IsEmpty(theSelectedNodes))
		return [NSArray array];
	NSMutableArray* paths = [[NSMutableArray alloc] init];
	for (FSNodeInfo* node in theSelectedNodes)
		[paths addObjectIfNonNil:[node absolutePath]];
	return paths;
}


- (NSArray*) absolutePathsOfChosenFiles
{
	if ([self nodeIsClicked] && ![self clickedNodeInSelectedNodes])
		return [NSArray arrayWithObject:[[self clickedNode] absolutePath]];
	return [self absolutePathsOfSelectedFilesInBrowser];
}


- (NSString*) enclosingDirectoryOfChosenFiles
{
	if (![self nodesAreChosen])
		return nil;
	
	FSNodeInfo* clickedNode = [self clickedNode];
	if ([self nodeIsClicked])
		return [clickedNode isDirectory] ? [clickedNode absolutePath] : [[clickedNode absolutePath] stringByDeletingLastPathComponent];
	
	// If we have more than one selected cell then we return the enclosing directory.
	NSArray* theSelectedNodes = [self selectedNodes];
	if ([theSelectedNodes count] >1)
		return [[[theSelectedNodes lastObject] absolutePath] stringByDeletingLastPathComponent];
	
	FSNodeInfo* selectedNode = [theSelectedNodes lastObject];
	return [selectedNode isDirectory] ? [selectedNode absolutePath] : [[selectedNode absolutePath] stringByDeletingLastPathComponent];
}

// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Status Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) statusOfChosenPathsInFilesContain:(HGStatus)status		{ return bitsInCommon(status, [self statusOfChosenPathsInFiles]); }
- (BOOL) repositoryHasFilesWhichContainStatus:(HGStatus)status	{ return bitsInCommon(status, [[self rootNodeInfo] hgStatus]); }


- (HGStatus) statusOfChosenPathsInFiles
{
	if ([self nodeIsClicked] && ![self clickedNodeInSelectedNodes])
		return [[self clickedNode] hgStatus];
	
	if (![self nodesAreSelected])
		return eHGStatusNoStatus;
	
	HGStatus combinedStatus = eHGStatusNoStatus;
	NSArray* theSelectedNodes = [self selectedNodes];
	for (FSNodeInfo* node in theSelectedNodes)
		combinedStatus = unionBits(combinedStatus, [node hgStatus]);
	return combinedStatus;
}


- (NSArray*) filterPaths:(NSArray*)absolutePaths byBitfield:(HGStatus)status
{
	FSNodeInfo* theRoot = [self rootNodeInfo];
	NSMutableArray* remainingPaths = [[NSMutableArray alloc] init];
	for (NSString* path in absolutePaths)
	{
		FSNodeInfo* node = [theRoot nodeForPathFromRoot:path];
		BOOL includePath = bitsInCommon([node hgStatus], status);
		if (includePath)
			[remainingPaths addObject:path];
	}
	return remainingPaths;
}

- (NSRect)	rectInWindowForNode:(FSNodeInfo*)node	{ return [[self currentViewerPane] rectInWindowForNode:node]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quicklook Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSRect)	screenRectForNode:(FSNodeInfo*)node		{ NSRect rect = [self rectInWindowForNode:node]; rect.origin = [[self window] convertBaseToScreen:rect.origin]; return rect; }

- (NSInteger) numberOfQuickLookPreviewItems			{ return [[self absolutePathsOfSelectedFilesInBrowser] count]; }

- (NSArray*) quickLookPreviewItems
{
	if (![self nodesAreSelected])
		return [NSArray array];
	
	NSMutableArray* quickLookPreviewItems = [[NSMutableArray alloc] init];
	NSArray* nodes = [self selectedNodes];
	for (FSNodeInfo* node in nodes)
	{
		NSString* path = [node absolutePath];
		if (!path)
			continue;
		NSRect screenRect = [self screenRectForNode:node];
		[quickLookPreviewItems addObject:[PathQuickLookPreviewItem previewItemForPath:path withRect:screenRect]];
	}
	return quickLookPreviewItems;
}






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Menu Item Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) browserMenuOpenSelectedFilesInFinder:(id)sender
{
	NSArray* paths = [self absolutePathsOfChosenFiles];
	for (NSString* path in paths)
		[[NSWorkspace sharedWorkspace] openFile:path];
}


- (IBAction) browserMenuRevealSelectedFilesInFinder:(id)sender
{
	if (![self nodesAreChosen])
	{
		[[NSWorkspace sharedWorkspace] selectFile:[self absolutePathOfRepositoryRoot] inFileViewerRootedAtPath:nil];
		return;
	}

	if ([self clickedNode] && ![self clickedNodeCoincidesWithTerminalSelections])
	{
		[[NSWorkspace sharedWorkspace] selectFile:[[self clickedNode] absolutePath] inFileViewerRootedAtPath:nil];
		return;
	}

	NSMutableArray* urls = [[NSMutableArray alloc] init];
	for (NSString* path in [self absolutePathsOfChosenFiles])
	{
		NSURL* newURL = [NSURL fileURLWithPath:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urls addObject:newURL];
	}
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
}


- (IBAction) browserMenuOpenTerminalHere:(id)sender
{
	NSString* theDir = [self enclosingDirectoryOfChosenFiles];
	if (!theDir)
		theDir = [self absolutePathOfRepositoryRoot];

	DoCommandsInTerminalAt(aliasesForShell(theDir), theDir);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  'Open With...' support
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) browserOpenChosenNodesWithApplication:(id)sender
{
	//- (BOOL)openFile:(NSString *)fullPath withApplication:(NSString *)appName
	NSMenuItem* item = DynamicCast(NSMenuItem, sender);
	if (!item)
		return;

	NSString* applicationPath = [[item representedObject] path];
	NSArray* paths = [self absolutePathsOfChosenFiles];
	for (NSString* path in paths)
		[[NSWorkspace sharedWorkspace] openFile:path withApplication:applicationPath];
}

- (IBAction) browserOpenChosenNodesWithABrowserToChoose:(id)sender
{
	NSString* applicationPath = getSingleApplicationPathFromOpenPanel([[[self clickedNode] absolutePath] lastPathComponent]);
	NSArray* paths = [self absolutePathsOfChosenFiles];
	for (NSString* path in paths)
		[[NSWorkspace sharedWorkspace] openFile:path withApplication:applicationPath];
}


- (NSMenuItem*) menuItemForOpenWith:(NSURL*)appURL usedDictionary:(NSMutableDictionary*)dict
{
	NSMenuItem* item = [[NSMenuItem alloc]init];
	NSString* appName = [[appURL path] lastPathComponent];
	if ([dict objectForKey:appName])
		return nil;
	[dict setObject:appURL forKey:appName];
	NSString* version = [[[NSBundle bundleWithPath:[appURL path]] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSString* title = [appName stringByDeletingPathExtension];
	[item setTitle:version ? fstr(@"%@ (%@)",title, version) : title];
	[item setRepresentedObject:appURL];
	[item setAction:@selector(browserOpenChosenNodesWithApplication:)];
	[item setKeyEquivalent:@""];
	NSSize imageSize = NSMakeSize(ICON_SIZE, ICON_SIZE);
	NSImage* theFileIcon = [NSWorkspace iconImageOfSize:imageSize forPath:[appURL path]];
	[item setImage:theFileIcon];

	return item;
}

- (void) menuNeedsUpdate:(NSMenu*)theMenu
{
	static NSArray* nsurlSortDescriptors = nil;
	
	if (!nsurlSortDescriptors)
		nsurlSortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"absoluteString" ascending:YES]];

	NSMenuItem* openWithItem = [theMenu itemWithTitle:@"Open With…"];
	if (openWithItem)
		[theMenu removeItem:openWithItem];

	if ([parentController controlsMainFSViewer] && [self singleFileIsChosenInFiles])
	{
		FSNodeInfo* clickedNode = [self clickedNode];
		NSString* path = [clickedNode absolutePath];
		NSURL* pathURL = [NSURL fileURLWithPath:path];
		NSArray* apps = [NSApplication applicationsForURL:pathURL];
		NSArray* appsSorted = [apps sortedArrayUsingDescriptors:nsurlSortDescriptors];
		NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
		NSMenu* subMenu = [[[NSMenu alloc] initWithTitle:@"Open With…"] autorelease];
		NSURL* preferedApp = [NSApplication applicationForURL:pathURL];
		int index = 0;
		
		// Add the prefered application
		if (preferedApp)
		{
			NSMenuItem* newItem = [self menuItemForOpenWith:preferedApp usedDictionary:dict];
			if (newItem)
			{
				[subMenu insertItem:newItem atIndex:index++];
				[subMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];
			}
		}

		// Add each application
		for (NSURL* appUrl in appsSorted)
		{
			NSMenuItem* newItem = [self menuItemForOpenWith:appUrl usedDictionary:dict];
			if (newItem)
				[subMenu insertItem:newItem atIndex:index++];
		}
		
		// Add the Other... item
		[subMenu insertItem:[NSMenuItem separatorItem] atIndex:index++];		
		[subMenu insertItemWithTitle:@"Other…" action:@selector(browserOpenChosenNodesWithABrowserToChoose:) keyEquivalent:@"" atIndex:index++];

		// Create an item for the submenu and add the submenu to the menu.
		NSMenuItem* newOpenWithItem = [[NSMenuItem alloc] init];		
		[newOpenWithItem setTitle:@"Open With…"];
		[newOpenWithItem setSubmenu:subMenu];
		[theMenu insertItem:newOpenWithItem atIndex:1];
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Action Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BrowserDoubleClickAction) actionEnumForBrowserDoubleClick
{
	CGEventRef event = CGEventCreate(NULL /*default event source*/);
	CGEventFlags modifiers = CGEventGetFlags(event);
	CFRelease(event);

	//BOOL isShiftDown    = bitsInCommon(modifiers, kCGEventFlagMaskShift);
	BOOL isCommandDown  = bitsInCommon(modifiers, kCGEventFlagMaskCommand);
	BOOL isCtrlDown     = bitsInCommon(modifiers, kCGEventFlagMaskControl);
	BOOL isOptDown      = bitsInCommon(modifiers, kCGEventFlagMaskAlternate);
	
	// Open the file and display it information by calling the single click routine.
	
	if (      isCommandDown && !isCtrlDown && !isOptDown) return browserBehaviourCommandDoubleClick();
	else if ( isCommandDown && !isCtrlDown &&  isOptDown) return browserBehaviourCommandOptionDoubleClick();
	else if (!isCommandDown && !isCtrlDown &&  isOptDown) return browserBehaviourOptionDoubleClick();
	else if (!isCommandDown && !isCtrlDown && !isOptDown) return browserBehaviourDoubleClick();

	PlayBeep();
	return eBrowserClickActionNoAction;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Drag & Drop
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) writeRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard*)pasteboard
{
	return [parentController writeRowsWithIndexes:rowIndexes inColumn:column toPasteboard:pasteboard];	// The parent handles writing out the pasteboard items
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Refresh / Regenrate Browser
// -----------------------------------------------------------------------------------------------------------------------------------------

- (float) rowHeightForFont
{
	static float storedFontSizeofBrowserItems = 0.0;
	static float rowHeight = 0.0;
	if (storedFontSizeofBrowserItems != fontSizeOfBrowserItemsFromDefaults())
	{
		storedFontSizeofBrowserItems = fontSizeOfBrowserItemsFromDefaults();
		NSFont* textFont = [NSFont fontWithName:@"Verdana" size:storedFontSizeofBrowserItems];
		rowHeight = MAX([textFont boundingRectForFont].size.height + 4.0, 16.0);
	}
	return rowHeight;
}

- (void) markPathsDirty:(RepositoryPaths*)dirtyPaths
{
	dispatch_async([[self myDocument] refreshBrowserSerialQueue], ^{
		NSArray* absoluteDirtyPaths = [dirtyPaths absolutePaths];
		
		DispatchGroup group = dispatch_group_create();
		__block FSViewerSelectionState* theSavedState = nil;
		__block FSNodeInfo* newRootNode = nil;

		// mark the dirty paths and all children as dirty
		dispatch_group_async(group, globalQueue(), ^{
			newRootNode = [rootNodeInfo_ shallowTreeCopyMarkingPathsDirty:absoluteDirtyPaths];	});

		dispatch_group_async(group, globalQueue(), ^{
			theSavedState = [self saveViewerSelectionState];  });
		
		dispatchGroupWaitAndFinish(group);

		dispatch_async(mainQueue(), ^{
			rootNodeInfo_ = newRootNode;
			[self reloadData];
			[self restoreViewerSelectionState:theSavedState ];				// restore the selection and the scroll positions of the columns and the horizontal scroll
		});
	});
}



- (void) refreshBrowserPaths:(RepositoryPaths*)changes finishingBlock:(BlockProcess)theBlock
{
	NSString* rootPath = [changes rootPath];
	NSArray* absoluteChangedPaths = pruneDisallowedPaths([changes absolutePaths]);
	if (IsEmpty(absoluteChangedPaths) || !pathIsExistentDirectory(rootPath))
	{
		if (theBlock)
			theBlock();
		return;
	}

	ProcessListController* theProcessListController = [[self myDocument] theProcessListController];
	NSNumber* processNum = [theProcessListController addProcessIndicator:@"Refresh Browser Data"];

	dispatch_async([[self myDocument] refreshBrowserSerialQueue], ^{

		absolutePathOfRepositoryRoot_ = rootPath;

		// We concurrently get the status lines of the changed paths and at the same time make a shallow copy
		// of the node info tree
		DispatchGroup group = dispatch_group_create();
		__block NSArray* newStatusLines = nil;
		__block NSArray* newResolveStatusLines = nil;
		__block FSNodeInfo* newRootNode = nil;

		dispatch_group_async(group, globalQueue(), ^{
			newStatusLines = [parentController statusLinesForPaths:absoluteChangedPaths withRootPath:rootPath];
		});
		
		dispatch_group_async(group, globalQueue(), ^{
			// If the result is still relevant and If we are in a merge state then we might have resolved and conflicted files and
			// we need to show such status. XXX does the following ever conflict if we are in a merge state and we look at the
			// diff pane?
			if ([rootPath isEqualTo:[[self myDocument] absolutePathOfRepositoryRoot]])
				if ([[self myDocument] inMergeState])
					newResolveStatusLines = [parentController resolveStatusLines:absoluteChangedPaths withRootPath:rootPath];
		});
		
		dispatch_group_async(group, globalQueue(), ^{
			newRootNode = [rootNodeInfo_ shallowTreeCopyRemoving:absoluteChangedPaths];	// copy the tree and prune the changed paths out of the node tree.
			if (!newRootNode)
				newRootNode = [FSNodeInfo newEmptyTreeRootedAt:rootPath];				// regenerate the node tree if we don't have one
		});

		dispatchGroupWait(group);			// Synchronize the created newStatusLines, newResolveStatusLines and the copied
											// newRootNode
		
		// If there was a critical error in the status (signaled by returning a null result then bail...)
		if (!newStatusLines)
		{
			[theProcessListController removeProcessIndicator:processNum];
			dispatchGroupFinish(group);
			if (theBlock)
				theBlock();
			return;
		}

		if ([newStatusLines count] > 0)
			newRootNode = [newRootNode fleshOutTreeWithStatusLines:newStatusLines withParentViewer:self];
		if ([newResolveStatusLines count] > 0)
			newRootNode = [newRootNode fleshOutTreeWithStatusLines:newResolveStatusLines withParentViewer:self];

		dispatch_group_async(group, mainQueue(), ^{
			// In the mean time, only if our results are still relevant (ie the root has not changed) then switch to the new root
			if ([rootPath isEqualTo:[[self myDocument] absolutePathOfRepositoryRoot]])
			{			
				FSViewerSelectionState* theSavedState = [self saveViewerSelectionState];
				rootNodeInfo_ = newRootNode;
				[self reloadData];
				[self restoreViewerSelectionState:theSavedState ];		// restore the selection and the scroll positions of the columns and the horizontal scroll
				if ([parentController controlsMainFSViewer] && ![[self myDocument] underlyingRepositoryChangedEventIsQueued])
					[[[self myDocument] repositoryData] adjustCollectionForIncompleteRevision];
			}

			[theProcessListController removeProcessIndicator:processNum];
		});

		dispatchGroupWaitTime(group, 5.0);	// Wait for the main queue to finish. Thus any refreshes have to wait for the new
											// tree... Maybe we could queue this so that the updating of the tree doesn't need to
											// wait for the display of the tree.
		dispatchGroupFinish(group);
		if (theBlock)
			theBlock();
	});
}

// The parent controller determines when we receive this event.
- (void) repositoryDataIsNew
{
	[[self currentViewerPane] repositoryDataIsNew];
	absolutePathOfRepositoryRoot_ = [[self myDocument] absolutePathOfRepositoryRoot];
	[self regenerateBrowserDataAndReload];
	if (theFilesOutline_)
		[theFilesOutline_ restoreExpandedStateFromUserDefaults];
}

- (void) regenerateBrowserDataAndReload
{
	rootNodeInfo_ = nil;
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	if (!rootPath)
	{
		DebugLog(@"Null Root Path encountered.");
		return;
	}
	NSArray* absoluteChangedPaths = [NSArray arrayWithObject:rootPath];
	[self refreshBrowserPaths:[RepositoryPaths fromPaths:absoluteChangedPaths withRootPath:rootPath]  finishingBlock:nil];
}

- (void) updateCurrentPreviewImage { [parentController updateCurrentPreviewImage]; }


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Save and Restore Viewer Selection state
// -----------------------------------------------------------------------------------------------------------------------------------------

- (FSViewerSelectionState*)	saveViewerSelectionState						{ return [[self currentViewerPane] saveViewerSelectionState]; }
- (void) restoreViewerSelectionState:(FSViewerSelectionState*)savedState	{ [[self currentViewerPane] restoreViewerSelectionState:savedState] ; }

@end






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewerSelectionState
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation FSViewerSelectionState

@synthesize savedColumnScrollPositions;
@synthesize savedHorizontalScrollPosition;
@synthesize savedSelectedPaths;
@synthesize restoreFirstResponderToViewer;

@end




