//
//  FSViewerBrowser.m
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import "FSViewerBrowser.h"
#import "FSNodeInfo.h"
#import "FSViewerPaneCell.h"
#import "MacHgDocument.h"
#import "Sidebar.h"


@implementation FSViewerBrowser

@synthesize parentViewer = parentViewer_;

// ------------------------------------------------------------------------------------
// MARK: -
// MARK: initialization
// ------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	self.delegate = self;
	self.target = self;
	[self setAction:@selector(fsviewerAction:)];
	[self setDoubleAction:@selector(fsviewerDoubleAction:)];	
	
	// Make the browser user our custom browser cell.
	[self setCellClass: [FSViewerPaneIconedCell class]];
}

- (FSNodeInfo*) rootNodeInfo		{ return parentViewer_.rootNodeInfo; }

- (void) reloadData
{
	self.rowHeight = parentViewer_.rowHeightForFont;
	[self loadColumnZero];
	[parentViewer_ updateCurrentPreviewImage];
}

- (void) reloadDataSin
{
	FSViewerSelectionState* theSavedState = self.saveViewerSelectionState;
	self.defaultColumnWidth = sizeOfBrowserColumnsFromDefaults();
	[self reloadData];
	[self restoreViewerSelectionState:theSavedState];				// restore the selection and the scroll positions of the columns and the horizontal scroll
	[parentViewer_ updateCurrentPreviewImage];
}

- (void) repositoryDataIsNew
{
	MacHgDocument* myDocument = parentViewer_.myDocument;
	if (myDocument.sidebar.localRepoIsSelected)
	{
		NSString* fileName = myDocument.documentNameForAutosave;
		NSString* repositoryName = myDocument.selectedRepositoryShortName;
		NSString* columnAutoSaveName = fstr(@"File:%@:Repository:%@", fileName ? fileName : @"Untitled", repositoryName ? repositoryName : @"Unnamed");
		self.columnsAutosaveName = columnAutoSaveName;
	}
}

- (void) prepareToOpenFSViewerPane
{
	[self reloadDataSin];
	[[parentViewer_.myDocument mainWindow] makeFirstResponder:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Notifications
// ------------------------------------------------------------------------------------

- (void) postBrowserViewSelectionDidChangeNotification
{
	NSNotification* note = [NSNotification notificationWithName:@"BrowserViewSelectionDidChangeNotification" object:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:parentViewer_ selector:@selector(viewerSelectionDidChange:) object:note];	// Cancel any other requests to show the object
	[parentViewer_ performSelector:@selector(viewerSelectionDidChange:) withObject:note afterDelay:(NSTimeInterval)0.1];
}

- (void) testForSeletionChanged
{
	if ([self.selectionIndexPath compare:lastSelectedIndexPath_] != NSOrderedSame)
		[self postBrowserViewSelectionDidChangeNotification];
	lastSelectedIndexPath_ = self.selectionIndexPath;	
}



// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Path and Selection Operations
// ------------------------------------------------------------------------------------

- (BOOL)		nodesAreSelected	{ return self.selectedColumn >= 0; }
- (BOOL)		nodeIsClicked		{ return self.clickedRow != -1; }
- (BOOL)		nodesAreChosen		{ return self.nodeIsClicked || self.nodesAreSelected; }
- (FSNodeInfo*) chosenNode			{ FSNodeInfo* ans = self.clickedNode; return ans ? ans : [self.selectedCell nodeInfo]; }
- (FSNodeInfo*) clickedNode
{
	@try
	{
		return self.nodeIsClicked ? [self itemAtRow:self.clickedRow inColumn:self.clickedColumn] : nil;
	}
	@catch (NSException* ne)
	{
		return nil;
	}
	return nil;
}

- (NSArray*) selectedNodes
{
	if (!self.nodesAreSelected)
		return @[];
	NSArray* theSelectedCells = self.selectedCells;
	NSMutableArray* nodes = [[NSMutableArray alloc] init];
	for (FSViewerPaneCell* cell in theSelectedCells)
		[nodes addObjectIfNonNil:cell.nodeInfo];
	return nodes;
}


- (BOOL) singleFileIsChosenInFiles
{
	if (self.nodeIsClicked && self.clickedNode.isFile)
		return YES;
	
	int selectedColumn = self.selectedColumn;
	if (selectedColumn >= 0)
		if ([[self selectedRowIndexesInColumn:selectedColumn] count] == 1)
			if ([[self.selectedCell nodeInfo] isFile])
				return YES;
	return NO;
}


- (BOOL) singleItemIsChosenInFiles
{
	if (self.nodeIsClicked && self.clickedNode.isDirectory)
		return YES;
	
	int selectedColumn = self.selectedColumn;
	if (selectedColumn >= 0)
		if ([[self selectedRowIndexesInColumn:selectedColumn] count] == 1)
			return YES;
	return NO;
}

- (BOOL) clickedNodeInSelectedNodes
{
	if (!self.nodeIsClicked)
		return NO;
	if (self.clickedColumn != self.selectedColumn)
		return NO;
	
	NSArray* indexPaths = self.selectionIndexPaths;
	for (NSIndexPath* indexPath in indexPaths)
		if ([indexPath indexAtPosition:self.clickedColumn] == self.clickedRow)
			return YES;
	return NO;
}


- (BOOL) clickedNodeCoincidesWithTerminalSelections	{ return (self.nodeIsClicked && (self.clickedColumn == self.selectedColumn) && self.clickedNodeInSelectedNodes); }


- (FSNodeInfo*) parentNodeInfoForColumn:(NSInteger)column
{
	if (column == 0)
        return self.rootNodeInfo;
	
	// Find the selected item leading up to this column and grab its FSNodeInfo stored in that cell
	FSViewerPaneCell* selectedCell = [self selectedCellInColumn:column-1];
	return selectedCell.nodeInfo;
}


- (IBAction) fsviewerDoubleAction:(id)sender
{
	[self testForSeletionChanged];
	[parentViewer_ fsviewerDoubleAction:sender];
}
- (IBAction) fsviewerAction:(id)sender
{
	[self testForSeletionChanged];
	[parentViewer_ fsviewerAction:sender];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Graphic Operations
// ------------------------------------------------------------------------------------

- (NSRect) frameInWindowOfRow:(NSInteger)row inColumn:(NSInteger)column
{
	NSRect itemRect = [self frameOfRow:row inColumn:column];

	// check that the item Rect is visible
	if (NSIntersectsRect(self.visibleRect, itemRect))
		return [self convertRect:itemRect toView:self.window.contentView];
	return NSZeroRect;
}

- (NSRect)	rectInWindowForNode:(FSNodeInfo*)node
{
	NSInteger col;
	NSInteger row;
	BOOL found = [self.rootNodeInfo getRow:&row andColumn:&col forNode:node];
	return found ? [self frameInWindowOfRow:row inColumn:col] : NSZeroRect;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Browser Delegate Methods
// ------------------------------------------------------------------------------------

- (id) rootItemForBrowser:(NSBrowser*)browser										{ return self.rootNodeInfo; }
- (NSInteger) browser:(NSBrowser*)browser numberOfChildrenOfItem:(FSNodeInfo*)item	{ return item.childNodeCount; }
- (BOOL) browser:(NSBrowser*)browser isLeafItem:(FSNodeInfo*)item					{ return !item.isDirectory; }
- (id) browser:(NSBrowser*)browser objectValueForItem:(FSNodeInfo*)item				{ return item.lastPathComponent; }
- (id) browser:(NSBrowser*)browser child:(NSInteger)index ofItem:(FSNodeInfo*)item	{ return [item childNodeAtIndex:index]; }


- (void) browser:(NSBrowser*)sender willDisplayCell:(FSViewerPaneCell*)cell atRow:(NSInteger)row column:(NSInteger)column
{
	// Find our parent FSNodeInfo and access the child at this particular row
	FSNodeInfo* parentNodeInfo = [self parentNodeInfoForColumn:column];
	if (!parentNodeInfo || parentNodeInfo.sortedChildNodeKeys.count <= row)
		return;
	FSNodeInfo* currentNodeInfo = [parentNodeInfo childNodeAtIndex:row];
	cell.parentNodeInfo = parentNodeInfo;
	cell.nodeInfo = currentNodeInfo;
	cell.stringValue = currentNodeInfo.lastPathComponent;
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


// We overide this here to emulate browserViewSelectionDidChange which doesn't exist. We fire the notification with a tiny delay
// to ensure that the browser has actually changed to the new selection. 
- (NSIndexSet*) browser:(NSBrowser*)browser selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes inColumn:(NSInteger)column
{
	[self postBrowserViewSelectionDidChangeNotification];
	return proposedSelectionIndexes;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Delegates Drag & Drop
// ------------------------------------------------------------------------------------

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal																				{ return NSDragOperationCopy | NSDragOperationLink; }

- (BOOL)browser:(NSBrowser*)browser canDragRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column withEvent:(NSEvent*)event				{ return YES; }
- (BOOL)browser:(NSBrowser*)browser   writeRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard*)pasteboard
{
	NSMutableArray* paths = [[NSMutableArray alloc] init];
	[rowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL* stop) {
		FSNodeInfo* node = [self itemAtRow:row inColumn:column];
		[paths addObject:node.absolutePath];
	}];
	return [parentViewer_ writePaths:paths toPasteboard:pasteboard];	// The parent handles writing out the pasteboard items
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Save and Restore Browser state
// ------------------------------------------------------------------------------------

- (FSViewerSelectionState*)	saveViewerSelectionState
{
	// Save scroll positions of the columns
	NSArray* selectedPaths = parentViewer_.absolutePathsOfSelectedFilesInBrowser;
	FSViewerSelectionState* newSavedState = [[FSViewerSelectionState alloc] init];
	int numberOfColumns = self.lastColumn;
	[newSavedState setSavedColumnScrollPositions:[[NSMutableArray alloc] init]];
	for (int i = 0; i <= numberOfColumns; i++)
	{
		NSMatrix* matrixForColumn = [self matrixInColumn:i];
		NSScrollView* enclosingSV = matrixForColumn.enclosingScrollView;
		NSPoint currentScrollPosition = enclosingSV.contentView.bounds.origin;
		[newSavedState.savedColumnScrollPositions addObject:[NSValue valueWithPoint:currentScrollPosition]];
	}
	
	// Save the horizontal scroll position
	NSScrollView* horizontalSV = [[[self matrixInColumn:0] enclosingScrollView] enclosingScrollView];
	newSavedState.savedHorizontalScrollPosition = horizontalSV.contentView.bounds.origin;
	
	BOOL restoreFirstResponderToViewer = [parentViewer_.parentWindow.firstResponder hasAncestor:self];
	
	// Save the selectedPaths
	newSavedState.savedSelectedPaths = selectedPaths;
	newSavedState.restoreFirstResponderToViewer = restoreFirstResponderToViewer;
	
	return newSavedState;
}


- (void) restoreViewerSelectionState:(FSViewerSelectionState*)savedState
{
	NSArray* savedSelectedPaths            = savedState.savedSelectedPaths;
	NSArray* savedColumnScrollPositions    = savedState.savedColumnScrollPositions;
	NSPoint  savedHorizontalScrollPosition = savedState.savedHorizontalScrollPosition;
	BOOL     restoreFirstResponderToViewer = savedState.restoreFirstResponderToViewer;

	if (savedSelectedPaths.count <1)
		return;
	
	// Restore the selection
	NSString* rootPath = parentViewer_.absolutePathOfRepositoryRoot;
	NSString* relativeSelectedPath = pathDifference(rootPath, savedSelectedPaths.lastObject);
	
	// Loop through and select the correct row in each column until we get to the last column
	if (restoreFirstResponderToViewer)
		[parentViewer_.parentWindow makeFirstResponder:self];
	NSArray* components = relativeSelectedPath.pathComponents;
	FSNodeInfo* childNode = self.rootNodeInfo;
	FSNodeInfo* node = childNode;
	int col = 0;
	for (NSString* name in components)
	{
		node = childNode;
		childNode = node.childNodes[name];
		if (childNode)
		{
			[self selectRow: [node.sortedChildNodeKeys indexOfObject:name] inColumn:col];
			col++;
		}
		else
			break;
	}
	
	// Note if the last node was a directory (ie the only things selected in the column then with the above
	// code the next column will also be displayed although nothing will be selected in it.) If this is the
	// case then we can't call the method selectRowIndexes because this will blow away the display of this next
	// column. Thus if we have more than one thing selected go ahead and select the multiple items.
	if (savedSelectedPaths.count > 1)
	{
		NSMutableIndexSet* rowIndexes = [[NSMutableIndexSet alloc] init];
		for (NSString* path in savedSelectedPaths)
		{
			NSString* name = path.lastPathComponent;
			NSInteger rowIndex = [node.sortedChildNodeKeys indexOfObject:name];
			if (rowIndex != NSNotFound)
				[rowIndexes addIndex:rowIndex];
		}
		if (IsNotEmpty(rowIndexes))
			[self selectRowIndexes:rowIndexes inColumn:(col-1)];
	}
	if (restoreFirstResponderToViewer)
		[self.window makeFirstResponder:self];
	
	
	// restore column scroll positions
	int i = 0;
	for (NSValue* position in savedColumnScrollPositions)
	{
		NSPoint savedScrollPosition = position.pointValue;
		NSMatrix* matrixForColumn = [self matrixInColumn:i];
		NSScrollView* enclosingSV = matrixForColumn.enclosingScrollView;
		[enclosingSV.documentView scrollPoint:savedScrollPosition];
		i++;
	}
	
	// restore horizontal scroll position
	NSScrollView* horizontalSV = [[[self matrixInColumn:0] enclosingScrollView] enclosingScrollView];
	[horizontalSV.documentView scrollPoint:savedHorizontalScrollPosition];
}


@end
