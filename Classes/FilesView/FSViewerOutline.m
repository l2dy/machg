//
//  FSViewerOutline.m
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import "FSViewerOutline.h"
#import "FSNodeInfo.h"
#import "FSViewerPaneCell.h"



@interface FSViewerOutline (PrivateMethods)
- (void) restoreExpandedVisualsFromExpandedState;
@end


@implementation FSViewerOutline

@synthesize parentViewer = parentViewer_;

- (void) awakeFromNib
{
	[self setDelegate:self];
	[self setDataSource:self];
	[self setIndentationPerLevel:20.0];
}

- (void) reloadData
{
	[self setRowHeight:[parentViewer_ rowHeightForFont]];
	[super reloadData];
	if (IsEmpty(expandedNodes_))
		[self restoreExpandedStateFromUserDefaults];
	[self restoreExpandedVisualsFromExpandedState];
}

- (void) reloadDataSin
{
	FSViewerSelectionState* theSavedState = [self saveViewerSelectionState];
	[self reloadData];
	[self restoreViewerSelectionState:theSavedState];
}

- (void) prepareToOpenFSViewerPane
{
	[self reloadDataSin];	// Have the desirable side effect of copying the selection from the current pane to this one.
	[[[parentViewer_ myDocument] mainWindow] makeFirstResponder:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Testing of selection and clicks
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)		nodesAreSelected	{ return [self numberOfSelectedRows] > 0; }
- (BOOL)		nodeIsClicked		{ return [self clickedRow] != -1; }
- (BOOL)		nodesAreChosen		{ return [self nodeIsClicked] || [self nodesAreSelected]; }
- (FSNodeInfo*) selectedNode		{ return [self selectedItem]; }
- (FSNodeInfo*) clickedNode			{ return [self clickedItem]; }
- (FSNodeInfo*) chosenNode			{ return [self chosenItem]; }
- (NSArray*)	selectedNodes		{ return [self selectedItems]; }
- (NSArray*)	chosenNodes			{ return [self chosenItems]; }
- (BOOL) clickedNodeInSelectedNodes	{ return [self clickedRowInSelectedRows]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path and Selection Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) singleFileIsChosenInFiles
{
	if (![[self chosenNode] isFile])
		return NO;
	return ([self numberOfSelectedRows] == 1) || ![self isRowSelected:[self chosenRow]];
}

- (BOOL)		singleItemIsChosenInFiles											{ return ([self numberOfSelectedRows] == 1) || ![self isRowSelected:[self chosenRow]]; }
- (BOOL)		clickedNodeCoincidesWithTerminalSelections							{ return NO; }
- (void)		repositoryDataIsNew													{ expandedNodes_ = nil; }

- (NSRect)	rectInWindowForNode:(FSNodeInfo*)node
{
	NSInteger row = [self rowForItem:node];
	NSRect itemRect = (row>=0) ? [self rectOfRow:row] : NSZeroRect;	
	
	// check that the path Rect is visible on screen
	if (NSIntersectsRect([self visibleRect], itemRect))
		return [self convertRectToBase:itemRect];			// convert item rect to screen coordinates
	return NSZeroRect;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Data Source Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id)        outlineView:(NSOutlineView*)outlineView  child:(NSInteger)index  ofItem:(FSNodeInfo*)item									{ return [(item ? item : [parentViewer_ rootNodeInfo]) childNodeAtIndex:index]; }
- (BOOL)      outlineView:(NSOutlineView*)outlineView  isItemExpandable:(FSNodeInfo*)item												{ return [(item ? item : [parentViewer_ rootNodeInfo]) childNodeCount] > 0; }
- (NSInteger) outlineView:(NSOutlineView*)outlineView  numberOfChildrenOfItem:(FSNodeInfo*)item											{ return [(item ? item : [parentViewer_ rootNodeInfo]) childNodeCount]; }
- (id)        outlineView:(NSOutlineView*)outlineView  objectValueForTableColumn:(NSTableColumn*)tableColumn  byItem:(FSNodeInfo*)item  { return [(item ? item : [parentViewer_ rootNodeInfo]) relativePath]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void)	outlineView:(NSOutlineView*)outlineView  willDisplayCell:(id)aCell  forTableColumn:(NSTableColumn*)tableColumn  item:(id)item
{
	if ([[tableColumn identifier] isEqualToString:@"path"])
	{
		FSNodeInfo* node = DynamicCast(FSNodeInfo, item);
		[aCell setParentNodeInfo:[self parentForItem:node]];
		[aCell setNodeInfo:node];
		[aCell loadCellContents];
	}
}

- (void)outlineViewItemDidCollapse:(NSNotification*)notification
{
	if (!expandedNodes_)
		[self restoreExpandedStateFromUserDefaults];
	FSNodeInfo* node = [[notification userInfo] objectForKey:@"NSObject"];
	if ([expandedNodes_ containsObject:[node absolutePath]])
	{
		[expandedNodes_ removeObject:[node absolutePath]];
		[self saveExpandedStateToUserDefaults];
	}
}

- (void)outlineViewItemDidExpand:(NSNotification*)notification
{
	if (!expandedNodes_)
		[self restoreExpandedStateFromUserDefaults];
	FSNodeInfo* node = [[notification userInfo] objectForKey:@"NSObject"];
	if (![expandedNodes_ containsObject:[node absolutePath]])
	{
		[expandedNodes_ addObject:[node absolutePath]];
		[self saveExpandedStateToUserDefaults];
	}	
}

- (void)outlineViewSelectionDidChange:(NSNotification*)notification
{
	[parentViewer_ viewerSelectionDidChange:notification];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Delegates Drag & Drop
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal						{ return NSDragOperationCopy | NSDragOperationLink; }

- (BOOL) canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint	{ return YES; }
- (BOOL) outlineView:(NSOutlineView*)outlineView  writeItems:(NSArray*)items  toPasteboard:(NSPasteboard*)pasteboard
{
	NSMutableArray* paths = [[NSMutableArray alloc] init];
	for (FSNodeInfo* node in items)
		[paths addObject:[node absolutePath]];
	return [parentViewer_ writePaths:paths toPasteboard:pasteboard];	// The parent handles writing out the pasteboard items
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Save and Restore Outline state
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) saveExpandedStateToUserDefaults
{
	NSString* cacheKeyName = fstr(@"ChacheExpandedFSViewerOutlineNodes§%@", [[parentViewer_ myDocument] absolutePathOfRepositoryRoot]);
	[[NSUserDefaults standardUserDefaults] setObject:[expandedNodes_ allObjects] forKey:cacheKeyName];
}

- (void) restoreExpandedStateFromUserDefaults
{
	NSString* cacheKeyName = fstr(@"ChacheExpandedFSViewerOutlineNodes§%@", [[parentViewer_ myDocument] absolutePathOfRepositoryRoot]);
	NSArray* expandedNodes = [[NSUserDefaults standardUserDefaults] objectForKey:cacheKeyName];
	expandedNodes_ = expandedNodes ? [NSMutableSet setWithArray:expandedNodes] : [[NSMutableSet alloc] init];
}

- (void) restoreExpandedVisualsFromExpandedState
{
	FSNodeInfo* rootNode = [parentViewer_ rootNodeInfo];
	NSArray* sortedExpandedPaths = [[expandedNodes_ allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	for (NSString* path in sortedExpandedPaths)
	{
		FSNodeInfo* node = [rootNode nodeForPathFromRoot:path];
		if (node)
			[self expandItem:node];
	}	
}

- (FSViewerSelectionState*)	saveViewerSelectionState
{
	FSViewerSelectionState* newSavedState = [[FSViewerSelectionState alloc] init];

	NSArray* selectedPaths = [parentViewer_ absolutePathsOfSelectedFilesInBrowser];
	BOOL restoreFirstResponderToViewer = [[[parentViewer_ parentWindow] firstResponder] hasAncestor:self];
	
	// Save the selectedPaths
	newSavedState.savedSelectedPaths = selectedPaths;
	newSavedState.restoreFirstResponderToViewer = restoreFirstResponderToViewer;
	
	return newSavedState;
}

- (void) restoreViewerSelectionState:(FSViewerSelectionState*)savedState
{
	NSArray* savedSelectedPaths            = [savedState savedSelectedPaths];
	BOOL     restoreFirstResponderToViewer = [savedState restoreFirstResponderToViewer];
	FSNodeInfo* rootNode				   = [parentViewer_ rootNodeInfo];

	// restore the selection
	NSMutableIndexSet* rowsToBeSelected = [[NSMutableIndexSet alloc]init];	
	for (NSString* path in savedSelectedPaths)
	{
		FSNodeInfo* item = [rootNode nodeForPathFromRoot:path];
		if (item)
			[rowsToBeSelected addIndex:[self rowForItem:item]];
	}
	[self selectRowIndexes:rowsToBeSelected byExtendingSelection:NO];

	if (restoreFirstResponderToViewer)
		[[self window] makeFirstResponder:self];	
}

@end
