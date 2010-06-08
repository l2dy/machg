//
//  FSBrowser.m
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "FSBrowser.h"
#import "MacHgDocument.h"
#import "FSNodeInfo.h"
#import "FSBrowserCell.h"
#import "ProcessListController.h"
#import "TaskExecutions.h"
#import "MonitorFSEvents.h"
#import "RepositoryData.h"
#import "ShellHere.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSBrowser
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation FSBrowser

@synthesize areNodesVirtual = areNodesVirtual_;
@synthesize absolutePathOfRepositoryRoot = absolutePathOfRepositoryRoot_;
@synthesize isMainFSBrowser = isMainFSBrowser_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	[self setDelegate:self];
	rootNodeInfo_ = nil;
	isMainFSBrowser_ = NO;
	return self;
}


- (void) awakeFromNib
{
	[self observe:kBrowserDisplayPreferencesChanged from:nil byCalling:@selector(reloadDataSin)];

	[self setDelegate:self];

	// Make the browser user our custom browser cell.
	[self setCellClass: [FSBrowserCell class]];
	    
	// Configure the number of visible columns (default max visible columns is 0 and set in IB, which means an unlimited number of
	// columns. (like the finder)).
	[self setDefaultColumnWidth:sizeOfBrowserColumnsFromDefaults()];
	[self repositoryRootDidChange];
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
// MARK: Path and Selection Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (FSNodeInfo*) rootNodeInfo		{ return rootNodeInfo_; }
- (IBAction) reloadData:(id)sender
{
	[self setRowHeightForFont];
	[self loadColumnZero];
	[parentController updateCurrentPreviewImage];
}
- (void) reloadDataSin
{
	[self setRowHeightForFont];
	BrowserSelectionState* theSavedState = [BrowserSelectionState saveBrowserState:self];
	[self setDefaultColumnWidth:sizeOfBrowserColumnsFromDefaults()];
	[self reloadData:self];
	[theSavedState restoreBrowserSelection];				// restore the selection and the scroll positions of the columns and the horizontal scroll
	[parentController updateCurrentPreviewImage];
}

- (void) setRowHeightForFont
{
	static float storedFontSizeofBrowserItems = 0.0;
	static float rowHeight = 0.0;
	if (storedFontSizeofBrowserItems != fontSizeOfBrowserItemsFromDefaults())
	{
		storedFontSizeofBrowserItems = fontSizeOfBrowserItemsFromDefaults();
		NSFont* textFont = [NSFont fontWithName:@"Verdana" size:storedFontSizeofBrowserItems];
		rowHeight = MAX([textFont boundingRectForFont].size.height + 4.0, 16.0);
	}
	[self setRowHeight:rowHeight];
}


- (BOOL)		nodesAreSelected	{ return [self selectedColumn] >= 0; }
- (BOOL)		nodeIsClicked		{ return [self clickedRow] != -1; }
- (BOOL)		nodesAreChosen		{ return [self nodeIsClicked] || [self nodesAreSelected]; }
- (FSNodeInfo*) chosenNode			{ FSNodeInfo* ans = [self clickedNode]; return ans ? ans : [[self selectedCell] nodeInfo]; }
- (FSNodeInfo*) clickedNode
{
	@try
	{
		return [self nodeIsClicked] ? [self itemAtRow:[self clickedRow] inColumn:[self clickedColumn]] : nil;
	}
	@catch (NSException* ne)
	{
		return nil;
	}
	return nil;
}


- (BOOL) singleItemIsChosenInBrower
{
	if ([self nodeIsClicked] && [[self clickedNode] isDirectory])
		return YES;

	int selectedColumn = [self selectedColumn];
	if (selectedColumn >= 0)
		if ([[self selectedRowIndexesInColumn:selectedColumn] count] == 1)
			if (![[[self selectedCell] nodeInfo] isDirectory])
				return YES;
	return NO;
}

- (BOOL) clickedNodeInSelectedNodes
{
	if (![self nodeIsClicked])
		return NO;
	
	NSArray* indexPaths = [self selectionIndexPaths];
	for (NSIndexPath* indexPath in indexPaths)
		if ([indexPath indexAtPosition:[self clickedColumn]] == [self clickedRow])
			return YES;
	return NO;
}

- (BOOL) clickedNodeCoincidesWithTerminalSelections	{ return ([self nodeIsClicked] && ([self clickedColumn] == [self selectedColumn]) && [self clickedNodeInSelectedNodes]); }


- (HGStatus) statusOfChosenPathsInBrowser
{
	if ([self nodeIsClicked] && ![self clickedNodeInSelectedNodes])
		return [[self clickedNode] hgStatus];
	
	if (![self nodesAreSelected])
		return eHGStatusNoStatus;

	HGStatus combinedStatus = eHGStatusNoStatus;
	NSArray* theSelectedNodes = [self selectedCells];
	for (FSBrowserCell* cell in theSelectedNodes)
		combinedStatus = unionBits(combinedStatus, [[cell nodeInfo] hgStatus]);
	return combinedStatus;
}

- (NSArray*) absolutePathsOfBrowserSelectedFiles
{
	if (![self nodesAreSelected])
		return [NSArray array];
	NSArray* theSelectedNodes = [self selectedCells];
	NSMutableArray* paths = [[NSMutableArray alloc] init];
	for (FSBrowserCell* cell in theSelectedNodes)
		if ([cell nodeInfo])
			[paths addObject:[[cell nodeInfo] absolutePath]];
	return paths;
}

- (NSArray*) absolutePathsOfBrowserChosenFiles
{
	if ([self nodeIsClicked] && ![self clickedNodeInSelectedNodes])
		return [NSArray arrayWithObject:[[self clickedNode] absolutePath]];

	return [self absolutePathsOfBrowserSelectedFiles];
}


- (NSString*) enclosingDirectoryOfBrowserChosenFiles
{
	if (![self nodesAreChosen])
		return nil;

	FSNodeInfo* clickedNode = [self clickedNode];
	if ([self nodeIsClicked])
			return [clickedNode isDirectory] ? [clickedNode absolutePath] : [[clickedNode absolutePath] stringByDeletingLastPathComponent];

	// If we have more than one selected cell then we return the enclosing directory.
	NSArray* theSelectedNodes = [self selectedCells];
	if ([theSelectedNodes count] >1)
		return [[[[theSelectedNodes lastObject] nodeInfo] absolutePath] stringByDeletingLastPathComponent];

	FSNodeInfo* selectedNode = [[theSelectedNodes lastObject] nodeInfo];
	return [selectedNode isDirectory] ? [selectedNode absolutePath] : [[selectedNode absolutePath] stringByDeletingLastPathComponent];
}


- (FSNodeInfo*) parentNodeInfoForColumn:(NSInteger)column
{
	if (column == 0)
        return rootNodeInfo_;
	
	// Find the selected item leading up to this column and grab its FSNodeInfo stored in that cell
	FSBrowserCell* selectedCell = [self selectedCellInColumn:column-1];
	return [selectedCell nodeInfo];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Menu Item Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) browserMenuOpenSelectedFilesInFinder:(id)sender
{
	NSArray* paths = [self absolutePathsOfBrowserChosenFiles];
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
	for (NSString* path in [self absolutePathsOfBrowserChosenFiles])
	{
		NSURL* newURL = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urls addObject:newURL];
	}
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:urls];
}


- (IBAction) browserMenuOpenTerminalHere:(id)sender
{
	NSString* theDir = [self enclosingDirectoryOfBrowserChosenFiles];
	if (!theDir)
		theDir = [self absolutePathOfRepositoryRoot];
	OpenTerminalAt(theDir);
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
// MARK: Browser Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) rootItemForBrowser:(NSBrowser*)browser										{ return rootNodeInfo_; }
- (NSInteger) browser:(NSBrowser*)browser numberOfChildrenOfItem:(FSNodeInfo*)item	{ return [[item sortedChildNodeKeys] count]; }
- (BOOL) browser:(NSBrowser*)browser isLeafItem:(FSNodeInfo*)item					{ return ![item isDirectory]; }
- (id) browser:(NSBrowser*)browser objectValueForItem:(FSNodeInfo*)item				{ return [item lastPathComponent]; }
- (id) browser:(NSBrowser*)browser child:(NSInteger)index ofItem:(FSNodeInfo*)item	{ return [[item childNodes] objectForKey:[[item sortedChildNodeKeys] objectAtIndex:index]]; }


- (void) browser:(NSBrowser*)sender willDisplayCell:(FSBrowserCell*)cell atRow:(NSInteger)row column:(NSInteger)column
{
	// Find our parent FSNodeInfo and access the child at this particular row
	FSNodeInfo* parentNodeInfo = [self parentNodeInfoForColumn:column];
	if (!parentNodeInfo || [[parentNodeInfo sortedChildNodeKeys] count] <= row)
		return;
	NSString* childKey = [[parentNodeInfo sortedChildNodeKeys] objectAtIndex:row];	// This is the string key of the child at the rowth row.
	FSNodeInfo* currentNodeInfo = [[parentNodeInfo childNodes] objectForKey:childKey];
	[cell setParentNodeInfo:parentNodeInfo];
	[cell setNodeInfo:currentNodeInfo];
	[cell loadCellContents];
}


- (NSViewController*) browser:(NSBrowser*) browser previewViewControllerForLeafItem:(id)item
{
	if (!ShowFilePreviewInBrowserFromDefaults())
		return nil;
	if (!browserLeafPreviewController_)
		browserLeafPreviewController_ = [[NSViewController alloc] initWithNibName:@"BrowserPreviewView" bundle:[NSBundle bundleForClass:[self class]]];
	return browserLeafPreviewController_; // NSBrowser will set the representedObject for us
}	





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Refresh / Regenrate Browser
// -----------------------------------------------------------------------------------------------------------------------------------------

// Get any resolve status lines and change the resolved code 'R' to 'S' so that this status letter doesn't conflict with the other
// status letters.
- (NSArray*) resolveStatusLines:(NSArray*)absolutePaths  withRootPath:(NSString*)rootPath
{
	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsResolveStatus = [NSMutableArray arrayWithObjects:@"resolve", @"--list", nil];
	[argsResolveStatus addObjectsFromArray:absolutePaths];

	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsResolveStatus fromRoot:rootPath  logging:eLoggingNone];
	if ([results hasErrors])
	{
		[TaskExecutions logMercurialResult:results];
		return nil;
	}
	NSArray* lines = [results.outStr componentsSeparatedByString:@"\n"];
	NSMutableArray* newLines = [[NSMutableArray alloc] init];
	for (NSString* line in lines)
		if (IsNotEmpty(line))
		{
			if ([line characterAtIndex:0] == 'R')
				[newLines addObject:[NSString stringWithFormat:@"S%@",[line substringFromIndex:1]]];
			else
				[newLines addObject:line];
		}
	return newLines;
}

- (void) markPathsDirty:(RepositoryPaths*)dirtyPaths;
{
	dispatch_async([[self myDocument] refreshBrowserSerialQueue], ^{
		NSArray* absoluteDirtyPaths = [dirtyPaths absolutePaths];
		
		DispatchGroup group = dispatch_group_create();
		__block BrowserSelectionState* theSavedState = nil;
		__block FSNodeInfo* newRootNode = nil;

		// mark the dirty paths and all children as dirty
		dispatch_group_async(group, globalQueue(), ^{
			newRootNode = [rootNodeInfo_ shallowTreeCopyMarkingPathsDirty:absoluteDirtyPaths];	});

		dispatch_group_async(group, globalQueue(), ^{
			theSavedState = [BrowserSelectionState saveBrowserState:self];  });
		
		dispatchGroupWaitAndFinish(group);

		dispatch_async(mainQueue(), ^{
			rootNodeInfo_ = newRootNode;
			[self reloadData:self];
			[theSavedState restoreBrowserSelection];				// restore the selection and the scroll positions of the columns and the horizontal scroll
		});
	});
}



- (void) refreshBrowserPaths:(RepositoryPaths*)changes resumeEventsWhenFinished:(BOOL)resume
{
	NSString* rootPath = [changes rootPath];
	NSArray* absoluteChangedPaths = pruneDisallowedPaths([changes absolutePaths]);
	if (IsEmpty(absoluteChangedPaths) || !pathIsExistentDirectory(rootPath))
		return;

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
					newResolveStatusLines = [self resolveStatusLines:absoluteChangedPaths withRootPath:rootPath];
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
			if (resume && isMainFSBrowser_)
				[[self myDocument] resumeEvents];
			return;
		}

		if ([newStatusLines count] > 0)
			newRootNode = [newRootNode fleshOutTreeWithStatusLines:newStatusLines withParentBrowser:self];
		if ([newResolveStatusLines count] > 0)
			newRootNode = [newRootNode fleshOutTreeWithStatusLines:newResolveStatusLines withParentBrowser:self];

		dispatch_group_async(group, mainQueue(), ^{
			// In the mean time, only if our results are still relevant (ie the root has not changed) then switch to the new root
			if ([rootPath isEqualTo:[[self myDocument] absolutePathOfRepositoryRoot]])
			{			
				BrowserSelectionState* theSavedState = [BrowserSelectionState saveBrowserState:self];
				rootNodeInfo_ = newRootNode;
				[self reloadData:self];
				[theSavedState restoreBrowserSelection];		// restore the selection and the scroll positions of the columns and the horizontal scroll
				if (isMainFSBrowser_)
					[[[self myDocument] repositoryData] adjustCollectionForIncompleteRevisionAllowingNotification:YES];
			}

			[theProcessListController removeProcessIndicator:processNum];
		});

		dispatchGroupWaitTime(group, 5.0);	// Wait for the main queue to finish. Thus any refreshes have to wait for the new
											// tree... Maybe we could queue this so that the updating of the tree doesn't need to
											// wait for the display of the tree.
		dispatchGroupFinish(group);
		if (resume && isMainFSBrowser_)
			[[self myDocument] resumeEvents];
	});
}

// The parent controller determines when we receive this event.
- (void) repositoryRootDidChange
{
	if ([[self myDocument] aRepositoryIsSelected])
	{
		NSString* fileName = [[self myDocument] documentNameForAutosave];
		NSString* repositoryName = [[self myDocument] selectedRepositoryShortName];
		NSString* columnAutoSaveName = [NSString stringWithFormat:@"File:%@:Repository:%@", fileName ? fileName : @"Untitled", repositoryName ? repositoryName : @"Unnamed"];
		[self setColumnsAutosaveName:columnAutoSaveName];
	}
	absolutePathOfRepositoryRoot_ = [[self myDocument] absolutePathOfRepositoryRoot];
	[self regenerateBrowserDataAndReload];
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
	[self refreshBrowserPaths:[RepositoryPaths fromPaths:absoluteChangedPaths withRootPath:rootPath]  resumeEventsWhenFinished:NO];
}


@end






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: BrowserSelectionState
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation BrowserSelectionState

@synthesize savedColumnScrollPositions;
@synthesize savedHorizontalScrollPosition;
@synthesize savedSelectedPaths;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Save and Restore Browser state
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (BrowserSelectionState*)	saveBrowserState:(FSBrowser*)browser
{
	// Save scroll positions of the columns
	NSArray* selectedPaths = [browser absolutePathsOfBrowserSelectedFiles];
	BrowserSelectionState* newSavedState = [[BrowserSelectionState alloc] init];
	newSavedState->theBrowser = browser;
	int numberOfColumns = [browser lastColumn];
	newSavedState.savedColumnScrollPositions = [[NSMutableArray alloc] init];
	for (int i = 0; i <= numberOfColumns; i++)
	{
		NSMatrix* matrixForColumn = [browser matrixInColumn:i];
		NSScrollView* enclosingSV = [matrixForColumn enclosingScrollView];
		NSPoint currentScrollPosition = [[enclosingSV contentView] bounds].origin;
		[newSavedState.savedColumnScrollPositions addObject:[NSValue valueWithPoint:currentScrollPosition]];
	}

	// Save the horizontal scroll position
	NSScrollView* horizontalSV = [[[browser matrixInColumn:0] enclosingScrollView] enclosingScrollView];
	newSavedState.savedHorizontalScrollPosition = [[horizontalSV contentView] bounds].origin;

	// Save the selectedPaths
	newSavedState.savedSelectedPaths = selectedPaths;
	return newSavedState;
}


- (void) restoreBrowserSelection
{
	if ([savedSelectedPaths count] <1)
		return;

	// Restore the selection
	NSString* rootPath = [theBrowser absolutePathOfRepositoryRoot];
	NSString* relativeSelectedPath = pathDifference(rootPath, [savedSelectedPaths lastObject]);

	// Loop through and select the correct row in each column until we get to the last column
	[[theBrowser parentWindow] makeFirstResponder:theBrowser];
	NSArray* components = [relativeSelectedPath pathComponents];
	FSNodeInfo* childNode = [theBrowser rootNodeInfo];
	FSNodeInfo* node = childNode;
	int col = 0;
	for (NSString* name in components)
	{
		node = childNode;
		childNode = [[node childNodes] objectForKey:name];
		if (childNode)
		{
			[theBrowser selectRow: [[node sortedChildNodeKeys] indexOfObject:name] inColumn:col];
			col++;
		}
		else
			break;
	}

	// Note if the last node was a directory (ie the only things selected in the column then with the above
	// code the next column will also be displayed although nothing will be selected in it.) If this is the
	// case then we can't call the method selectRowIndexes because this will blow away the display of this next
	// column. Thus if we have more than one thing selected go ahead and select the multiple items.
	if ([savedSelectedPaths count] > 1)
	{
		NSMutableIndexSet* rowIndexes = [[NSMutableIndexSet alloc] init];
		for (NSString* path in savedSelectedPaths)
		{
			NSString* name = [path lastPathComponent];
			NSInteger rowIndex = [[node sortedChildNodeKeys] indexOfObject:name];
			if (rowIndex != NSNotFound)
				[rowIndexes addIndex:rowIndex];
		}
		if (IsNotEmpty(rowIndexes))
			[theBrowser selectRowIndexes:rowIndexes inColumn:(col-1)];
	}
	[[theBrowser window] makeFirstResponder:theBrowser];


	// restore column scroll positions
	int i = 0;
	for (NSValue* position in savedColumnScrollPositions)
	{
		NSPoint savedScrollPosition = [position pointValue];
		NSMatrix* matrixForColumn = [theBrowser matrixInColumn:i];
		NSScrollView* enclosingSV = [matrixForColumn enclosingScrollView];
		[[enclosingSV documentView] scrollPoint:savedScrollPosition];
		i++;
	}

	// restore horizontal scroll position
	NSScrollView* horizontalSV = [[[theBrowser matrixInColumn:0] enclosingScrollView] enclosingScrollView];
	[[horizontalSV documentView] scrollPoint:savedHorizontalScrollPosition];
}




@end




