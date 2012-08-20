//
//  FSViewerTable.m
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import "FSViewerTable.h"
#import "FSNodeInfo.h"
#import "FSViewerPaneCell.h"
#import "HunkExclusions.h"
#import "MacHgDocument.h"

@interface FSViewerTable (PrivateAPI)
- (void) regenerateTableData;
@end


@implementation FSViewerTable

@synthesize parentViewer = parentViewer_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	[self setDelegate:self];
	[self setDataSource:self];
	[self setTarget:self];
	[self setAction:@selector(fsviewerAction:)];
	[self setDoubleAction:@selector(fsviewerDoubleAction:)];
}

- (NSArray*) leafNodeForTableRow
{
	@synchronized(self)
	{
		if (!leafNodeForTableRow_)
			[self regenerateTableData];
	}
	return leafNodeForTableRow_;
}

- (void) regenerateTableData
{
	if (IsEmpty([[parentViewer_ rootNodeInfo] childNodes]))
		leafNodeForTableRow_ = @[];
	else
		leafNodeForTableRow_ = [[parentViewer_ rootNodeInfo] generateFlatLeafNodeListWithStatus:eHGStatusAll];
}

- (void) reloadData
{
	[self setRowHeight:[parentViewer_ rowHeightForFont]];
	[self regenerateTableData];
	[super reloadData];
}

- (void) reloadDataSin
{
	[self reloadData];
}

- (void) prepareToOpenFSViewerPane
{
	[self reloadDataSin];
	[[[parentViewer_ myDocument] mainWindow] makeFirstResponder:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Testing of selection and clicks
// -----------------------------------------------------------------------------------------------------------------------------------------

- (FSNodeInfo*) nodeAtIndex:(NSInteger)index
{
	@try
	{
		return [self leafNodeForTableRow][index];
	}
	@catch (NSException* ne)
	{
		return nil;
	}
	return nil;
}

- (NSInteger) indexOfNode:(FSNodeInfo*)node
{
	@try
	{
		return [[self leafNodeForTableRow ] indexOfObject:node];
	}
	@catch (NSException* ne)
	{
		return NSNotFound;
	}
	return NSNotFound;
}


- (BOOL)		nodesAreSelected			{ return IsNotEmpty([self selectedRowIndexes]); }
- (BOOL)		nodeIsClicked				{ return [self clickedRow] != -1; }
- (BOOL)		nodesAreChosen				{ return [self nodeIsClicked] || [self nodesAreSelected]; }
- (FSNodeInfo*) selectedNode				{ return [self nodeAtIndex:[self selectedRow]]; }
- (FSNodeInfo*) clickedNode					{ return [self nodeAtIndex:[self clickedRow]]; }
- (BOOL)		clickedNodeInSelectedNodes	{ return [self nodeIsClicked] ? [[self selectedRowIndexes] containsIndex:[self clickedRow]] : NO; }
- (FSNodeInfo*) chosenNode					{ FSNodeInfo* ans = [self clickedNode]; return ans ? ans : [self selectedNode]; }
- (NSArray*)	selectedNodes				{ return [[self leafNodeForTableRow] objectsAtIndexes:[self selectedRowIndexes]]; }

- (IBAction) fsviewerDoubleAction:(id)sender { [parentViewer_ fsviewerDoubleAction:sender]; }
- (IBAction) fsviewerAction:(id)sender		 { [parentViewer_ fsviewerAction:sender]; }





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
- (void)		repositoryDataIsNew													{ [self myDeselectAll]; }

- (NSRect)	rectInWindowForNode:(FSNodeInfo*)node
{
	NSInteger row = [self indexOfNode:node];
	NSRect itemRect = (row != NSNotFound) ? [self rectOfRow:row] : NSZeroRect;	
	
	// check that the path Rect is visible on screen
	if (NSIntersectsRect([self visibleRect], itemRect))
		return [self convertRectToBase:itemRect];			// convert item rect to screen coordinates
	return NSZeroRect;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Save and Restore Table state
// -----------------------------------------------------------------------------------------------------------------------------------------

// Save and restore browser, outline, or table state
- (FSViewerSelectionState*)	saveViewerSelectionState
{
	FSViewerSelectionState* newSavedState = [[FSViewerSelectionState alloc] init];
	
	NSArray* selectedPaths = [parentViewer_ absolutePathsOfSelectedFilesInBrowser];
	BOOL restoreFirstResponderToViewer = [[[parentViewer_ parentWindow] firstResponder] hasAncestor:self];
	
	NSScrollView* enclosingSV = [self enclosingScrollView];
	NSPoint currentScrollPosition = [[enclosingSV contentView] bounds].origin;
	NSValue* scrollPositionAsValue = [NSValue valueWithPoint:currentScrollPosition];
	
	// Save the selectedPaths
	newSavedState.savedColumnScrollPositions = [NSMutableArray arrayWithObject:scrollPositionAsValue];
	newSavedState.savedSelectedPaths = selectedPaths;
	newSavedState.restoreFirstResponderToViewer = restoreFirstResponderToViewer;
	
	return newSavedState;
}

- (void) restoreViewerSelectionState:(FSViewerSelectionState*)savedState
{
	NSArray* savedSelectedPaths            = [savedState savedSelectedPaths];
	NSValue* savedScrollPositionValue	   = [[savedState savedColumnScrollPositions] firstObject];
	FSNodeInfo* rootNode				   = [parentViewer_ rootNodeInfo];
	
	// restore the selection
	NSMutableIndexSet* rowsToBeSelected = [[NSMutableIndexSet alloc]init];	
	for (NSString* path in savedSelectedPaths)
	{
		FSNodeInfo* item = [rootNode nodeForPathFromRoot:path];
		NSInteger row = item ? [self indexOfNode:item] : NSNotFound;
		if (row != NSNotFound)
			[rowsToBeSelected addIndex:row];
	}
	[self selectRowIndexes:rowsToBeSelected byExtendingSelection:NO];
	
	if (savedScrollPositionValue)
	{
		NSScrollView* enclosingSV = [self enclosingScrollView];
		[[enclosingSV documentView] scrollPoint:[savedScrollPositionValue pointValue]];
	}
	if ([rowsToBeSelected count]>0)
	{
		NSUInteger row = [rowsToBeSelected firstIndex];
		[self scrollRowToVisible:row];
	}
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewerTable Data Source
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [[self leafNodeForTableRow] count];
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)requestedRow
{
	FSNodeInfo* node = [self leafNodeForTableRow][requestedRow];
	if ([[aTableColumn identifier] isEqualToString:@"name"])
		return [node relativePathComponent];
	if ([[aTableColumn identifier] isEqualToString:@"path"])
	{
		NSString* root = [[parentViewer_ rootNodeInfo] absolutePath];
		NSString* pathInRepository = pathDifference(root, [[node absolutePath] stringByDeletingLastPathComponent]);
		return IsNotEmpty(pathInRepository) ? pathInRepository : @" ";
	}
	return nil;
}

- (void) tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	FSNodeInfo* node = [self leafNodeForTableRow][rowIndex];
	NSString* columnIdentifier = [aTableColumn identifier];
	[aCell setNodeInfo:node];
	if ([columnIdentifier isEqualToString:@"exclude"])
	{
		NSString* root = [[parentViewer_ rootNodeInfo] absolutePath];
		HunkExclusions* hunkExclusions = [parentViewer_ hunkExclusions];
		NSString* fileName = pathDifference(root, [node absolutePath]);
		NSSet* exlcusions = [hunkExclusions hunkExclusionSetForRoot:root andFile:fileName];
		NSInteger state;
		if (IsEmpty(exlcusions))
			state = NSOnState;
		else
		{
			NSSet* validHunkHashSet = [hunkExclusions validHunkHashSetForRoot:root andFile:fileName];
			state = [validHunkHashSet isSubsetOfSet:exlcusions] ? NSOffState : NSMixedState;
		}
		[aCell setState:state];
		return;
	}
	[aCell setParentNodeInfo:nil];
	[aCell loadCellContents];
}

- (void) tableView:(NSTableView*)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	FSNodeInfo* node = [self leafNodeForTableRow][rowIndex];
	NSString* columnIdentifier = [aTableColumn identifier];

	if ([columnIdentifier isEqualToString:@"exclude"])
	{
		NSString* root = [[parentViewer_ rootNodeInfo] absolutePath];
		HunkExclusions* hunkExclusions = [parentViewer_ hunkExclusions];
		NSString* fileName = pathDifference(root, [node absolutePath]);
		NSSet* exlcusions = [hunkExclusions hunkExclusionSetForRoot:root andFile:fileName];
		if (IsEmpty(exlcusions))
			[hunkExclusions excludeFile:fileName forRoot:root];
		else 
			[hunkExclusions includeFile:fileName forRoot:root];
	}
}

//- (BOOL)tableView:(NSTableView*)aTableView shouldEditTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
//{
//	NSString* requestedColumn = [aTableColumn identifier];
//	if ([requestedColumn isEqualToString:@"patchName"])
//		return NO;
//	return YES;
//}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Table View Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) tableViewSelectionDidChange:(NSNotification*)notification
{
	[parentViewer_ viewerSelectionDidChange:notification];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Delegates Drag & Drop
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal		{ return NSDragOperationCopy | NSDragOperationLink; }

- (BOOL) tableView:(NSTableView*)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pasteboard
{
	NSMutableArray* paths = [[NSMutableArray alloc] init];
	[rowIndexes enumerateIndexesUsingBlock:^(NSUInteger row, BOOL* stop) {
		FSNodeInfo* node = [self leafNodeForTableRow][row];
		[paths addObject:[node absolutePath]];
	}];
	return [parentViewer_ writePaths:paths toPasteboard:pasteboard];	// The parent handles writing out the pasteboard items
}




@end



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FSViewerTableButtonCell
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation FSViewerTableButtonCell
@synthesize tableColumn = tableColumn_;
@synthesize nodeInfo = nodeInfo_;

//- (void) mouseEntered:(NSEvent*)event
//{
//	[NSAnimationContext beginGrouping];
//	[[NSAnimationContext currentContext] setDuration:1.0];
//	[[buttonMessage animator] setHidden:NO];
//	[NSAnimationContext endGrouping];
//}
//- (void) mouseExited:(NSEvent*)event
//{
//	[NSAnimationContext beginGrouping];
//	[[NSAnimationContext currentContext] setDuration:1.0];
//	[[buttonMessage animator] setHidden:YES];
//	[NSAnimationContext endGrouping];
//}

- (BOOL) showsBorderOnlyWhileMouseInside
{
	return YES;
}

@end;
