//
//  FSViewerBrowser.m
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import "FSViewerBrowser.h"
#import "FSNodeInfo.h"
#import "FSBrowserCell.h"
#import "MacHgDocument.h"

@interface FSViewerBrowser (PrivateAPI)
- (void) setRowHeightForFont;
@end


@implementation FSViewerBrowser

@synthesize parentViewer = parentViewer_;

// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	[self setDelegate:self];
	
	// Make the browser user our custom browser cell.
	[self setCellClass: [FSBrowserCell class]];	
}

- (FSNodeInfo*) rootNodeInfo		{ return [parentViewer_ rootNodeInfo]; }

- (void) reloadData
{
	[self setRowHeightForFont];
	[self loadColumnZero];
	[parentViewer_ updateCurrentPreviewImage];
}

- (void) reloadDataSin
{
	[self setRowHeightForFont];
	FSViewerSelectionState* theSavedState = [self saveViewerSelectionState];
	[self setDefaultColumnWidth:sizeOfBrowserColumnsFromDefaults()];
	[self reloadData];
	[self restoreViewerSelectionState:theSavedState];				// restore the selection and the scroll positions of the columns and the horizontal scroll
	[parentViewer_ updateCurrentPreviewImage];
}

- (void) repositoryDataIsNew
{
	MacHgDocument* myDocument = [parentViewer_ myDocument];
	if ([myDocument aRepositoryIsSelected])
	{
		NSString* fileName = [myDocument documentNameForAutosave];
		NSString* repositoryName = [myDocument selectedRepositoryShortName];
		NSString* columnAutoSaveName = fstr(@"File:%@:Repository:%@", fileName ? fileName : @"Untitled", repositoryName ? repositoryName : @"Unnamed");
		[self setColumnsAutosaveName:columnAutoSaveName];
	}
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

- (void) prepareToOpenFSViewerPane
{
	[[[parentViewer_ myDocument] mainWindow] makeFirstResponder:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path and Selection Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

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

- (NSArray*) selectedNodes
{
	if (![self nodesAreSelected])
		return [NSArray array];
	NSArray* theSelectedNodes = [self selectedCells];
	NSMutableArray* nodes = [[NSMutableArray alloc] init];
	for (FSBrowserCell* cell in theSelectedNodes)
		[nodes addObjectIfNonNil:[cell nodeInfo]];
	return nodes;
}

- (NSArray*) chosenNodes
{
	if ([self nodeIsClicked] && ![self clickedNodeInSelectedNodes])
		return [NSArray arrayWithObject:[self clickedNode]];
	
	return [self selectedNodes];
}

- (BOOL) singleFileIsChosenInBrowser
{
	if ([self nodeIsClicked] && [[self clickedNode] isFile])
		return YES;
	
	int selectedColumn = [self selectedColumn];
	if (selectedColumn >= 0)
		if ([[self selectedRowIndexesInColumn:selectedColumn] count] == 1)
			if ([[[self selectedCell] nodeInfo] isFile])
				return YES;
	return NO;
}


- (BOOL) singleItemIsChosenInBrowser
{
	if ([self nodeIsClicked] && [[self clickedNode] isDirectory])
		return YES;
	
	int selectedColumn = [self selectedColumn];
	if (selectedColumn >= 0)
		if ([[self selectedRowIndexesInColumn:selectedColumn] count] == 1)
			return YES;
	return NO;
}

- (BOOL) clickedNodeInSelectedNodes
{
	if (![self nodeIsClicked])
		return NO;
	if ([self clickedColumn] != [self selectedColumn])
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

- (NSArray*) absolutePathsOfSelectedFilesInBrowser
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

- (NSArray*) absolutePathsOfChosenFilesInBrowser
{
	if ([self nodeIsClicked] && ![self clickedNodeInSelectedNodes])
		return [NSArray arrayWithObject:[[self clickedNode] absolutePath]];
	
	return [self absolutePathsOfSelectedFilesInBrowser];
}


- (NSString*) enclosingDirectoryOfChosenFilesInBrowser
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
        return [self rootNodeInfo];
	
	// Find the selected item leading up to this column and grab its FSNodeInfo stored in that cell
	FSBrowserCell* selectedCell = [self selectedCellInColumn:column-1];
	return [selectedCell nodeInfo];
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Graphic Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSRect) frameinWindowOfRow:(NSInteger)row inColumn:(NSInteger)column
{
	NSRect itemRect = [self frameOfRow:row inColumn:column];
	NSRect itemRectInWindow = NSZeroRect;
	
	// check that the path Rect is visible on screen
	if (NSIntersectsRect([self visibleRect], itemRect))
	{
		// convert item rect to screen coordinates
		itemRectInWindow = [self convertRectToBase:itemRect];
		itemRectInWindow.origin = [[self window] convertBaseToScreen:itemRectInWindow.origin];
	}
	return itemRectInWindow;
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
// MARK:  Quicklook Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSArray*) quickLookPreviewItems
{
	if (![self nodesAreSelected])
		return [NSArray array];
	
	NSMutableArray* quickLookPreviewItems = [[NSMutableArray alloc] init];
	NSArray* indexPaths = [self selectionIndexPaths];
	for (NSIndexPath* indexPath in indexPaths)
	{
		NSString* path = [[self itemAtIndexPath:indexPath] absolutePath];
		if (!path)
			continue;
		NSInteger col = [indexPath length] - 1;
		NSInteger row = [indexPath indexAtPosition:col];
		NSRect rect   = [self frameinWindowOfRow:row inColumn:col];
		[quickLookPreviewItems addObject:[PathQuickLookPreviewItem previewItemForPath:path withRect:rect]];
	}
	return quickLookPreviewItems;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Browser Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) rootItemForBrowser:(NSBrowser*)browser										{ return [self rootNodeInfo]; }
- (NSInteger) browser:(NSBrowser*)browser numberOfChildrenOfItem:(FSNodeInfo*)item	{ return [item childNodeCount]; }
- (BOOL) browser:(NSBrowser*)browser isLeafItem:(FSNodeInfo*)item					{ return ![item isDirectory]; }
- (id) browser:(NSBrowser*)browser objectValueForItem:(FSNodeInfo*)item				{ return [item lastPathComponent]; }
- (id) browser:(NSBrowser*)browser child:(NSInteger)index ofItem:(FSNodeInfo*)item	{ return [item childNodeAtIndex:index]; }


- (void) browser:(NSBrowser*)sender willDisplayCell:(FSBrowserCell*)cell atRow:(NSInteger)row column:(NSInteger)column
{
	// Find our parent FSNodeInfo and access the child at this particular row
	FSNodeInfo* parentNodeInfo = [self parentNodeInfoForColumn:column];
	if (!parentNodeInfo || [[parentNodeInfo sortedChildNodeKeys] count] <= row)
		return;
	FSNodeInfo* currentNodeInfo = [parentNodeInfo childNodeAtIndex:row];
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
// MARK:  Delegates Drag & Drop
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal																				{ return NSDragOperationCopy | NSDragOperationLink; }

- (BOOL)browser:(NSBrowser*)browser canDragRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent*)event				{ return YES; }
- (BOOL)browser:(NSBrowser*)browser   writeRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard*)pasteboard
{
	return [parentViewer_ writeRowsWithIndexes:rowIndexes inColumn:column toPasteboard:pasteboard];	// The parent handles writing out the pasteboard items
}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Save and Restore Browser state
// -----------------------------------------------------------------------------------------------------------------------------------------

- (FSViewerSelectionState*)	saveViewerSelectionState
{
	// Save scroll positions of the columns
	NSArray* selectedPaths = [self absolutePathsOfSelectedFilesInBrowser];
	FSViewerSelectionState* newSavedState = [[FSViewerSelectionState alloc] init];
	int numberOfColumns = [self lastColumn];
	newSavedState.savedColumnScrollPositions = [[NSMutableArray alloc] init];
	for (int i = 0; i <= numberOfColumns; i++)
	{
		NSMatrix* matrixForColumn = [self matrixInColumn:i];
		NSScrollView* enclosingSV = [matrixForColumn enclosingScrollView];
		NSPoint currentScrollPosition = [[enclosingSV contentView] bounds].origin;
		[newSavedState.savedColumnScrollPositions addObject:[NSValue valueWithPoint:currentScrollPosition]];
	}
	
	// Save the horizontal scroll position
	NSScrollView* horizontalSV = [[[self matrixInColumn:0] enclosingScrollView] enclosingScrollView];
	newSavedState.savedHorizontalScrollPosition = [[horizontalSV contentView] bounds].origin;
	
	BOOL restoreFirstResponderToViewer = NO;
	for (NSResponder* theResponder = [[parentViewer_ parentWindow] firstResponder]; theResponder; theResponder = [theResponder nextResponder])
		if (theResponder == self)
		{
			restoreFirstResponderToViewer = YES;
			break;
		}
	
	// Save the selectedPaths
	newSavedState.savedSelectedPaths = selectedPaths;
	newSavedState.restoreFirstResponderToViewer = restoreFirstResponderToViewer;
	
	return newSavedState;
}


- (void) restoreViewerSelectionState:(FSViewerSelectionState*)savedState
{
	NSArray* savedSelectedPaths            = [savedState savedSelectedPaths];
	NSArray* savedColumnScrollPositions    = [savedState savedColumnScrollPositions];
	NSPoint  savedHorizontalScrollPosition = [savedState savedHorizontalScrollPosition];
	BOOL     restoreFirstResponderToViewer = [savedState restoreFirstResponderToViewer];

	if ([savedSelectedPaths count] <1)
		return;
	
	// Restore the selection
	NSString* rootPath = [parentViewer_ absolutePathOfRepositoryRoot];
	NSString* relativeSelectedPath = pathDifference(rootPath, [savedSelectedPaths lastObject]);
	
	// Loop through and select the correct row in each column until we get to the last column
	if (restoreFirstResponderToViewer)
		[[parentViewer_ parentWindow] makeFirstResponder:self];
	NSArray* components = [relativeSelectedPath pathComponents];
	FSNodeInfo* childNode = [self rootNodeInfo];
	FSNodeInfo* node = childNode;
	int col = 0;
	for (NSString* name in components)
	{
		node = childNode;
		childNode = [[node childNodes] objectForKey:name];
		if (childNode)
		{
			[self selectRow: [[node sortedChildNodeKeys] indexOfObject:name] inColumn:col];
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
			[self selectRowIndexes:rowIndexes inColumn:(col-1)];
	}
	if (restoreFirstResponderToViewer)
		[[self window] makeFirstResponder:self];
	
	
	// restore column scroll positions
	int i = 0;
	for (NSValue* position in savedColumnScrollPositions)
	{
		NSPoint savedScrollPosition = [position pointValue];
		NSMatrix* matrixForColumn = [self matrixInColumn:i];
		NSScrollView* enclosingSV = [matrixForColumn enclosingScrollView];
		[[enclosingSV documentView] scrollPoint:savedScrollPosition];
		i++;
	}
	
	// restore horizontal scroll position
	NSScrollView* horizontalSV = [[[self matrixInColumn:0] enclosingScrollView] enclosingScrollView];
	[[horizontalSV documentView] scrollPoint:savedHorizontalScrollPosition];
}


@end