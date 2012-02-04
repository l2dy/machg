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
		leafNodeForTableRow_ = [NSArray array];
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
		return [[self leafNodeForTableRow] objectAtIndex:index];
	}
	@catch (NSException* ne)
	{
		return nil;
	}
	return nil;
}

- (BOOL)		nodesAreSelected			{ return IsNotEmpty([self selectedRowIndexes]); }
- (BOOL)		nodeIsClicked				{ return [self clickedRow] != -1; }
- (BOOL)		nodesAreChosen				{ return [self nodeIsClicked] || [self nodesAreSelected]; }
- (FSNodeInfo*) selectedNode				{ return [self nodeAtIndex:[self selectedRow]]; }
- (FSNodeInfo*) clickedNode					{ return [self nodeAtIndex:[self clickedRow]]; }
- (BOOL)		clickedNodeInSelectedNodes	{ return [self nodeIsClicked] ? [[self selectedRowIndexes] containsIndex:[self clickedRow]] : NO; }
- (FSNodeInfo*) chosenNode					{ FSNodeInfo* ans = [self clickedNode]; return ans ? ans : [self selectedNode]; }
- (NSArray*)	selectedNodes				{ return [[self leafNodeForTableRow] objectsAtIndexes:[self selectedRowIndexes]]; }





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
	NSInteger row = [[self leafNodeForTableRow ] indexOfObject:node];
	NSRect itemRect = (row != NSNotFound) ? [self rectOfRow:row] : NSZeroRect;	
	
	// check that the path Rect is visible on screen
	if (NSIntersectsRect([self visibleRect], itemRect))
		return [self convertRectToBase:itemRect];			// convert item rect to screen coordinates
	return NSZeroRect;
}

// Save and restore browser, outline, or table state
- (FSViewerSelectionState*)	saveViewerSelectionState								{ return [[FSViewerSelectionState alloc]init]; }
- (void)					restoreViewerSelectionState:(FSViewerSelectionState*)savedState {}





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
	FSNodeInfo* node = [[self leafNodeForTableRow] objectAtIndex:requestedRow];
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
	FSNodeInfo* node = [[self leafNodeForTableRow] objectAtIndex:rowIndex];
	[aCell setParentNodeInfo:nil];
	[aCell setNodeInfo:node];
	[aCell loadCellContents];
}

//- (void) tableView:(NSTableView*)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
//{
//	PatchData* clickedPatch = [[self patchesTableData] objectAtIndex:rowIndex];
//	NSString* columnIdentifier = [aTableColumn identifier];
//	[clickedPatch setValue:anObject forKey:columnIdentifier];
//	
//	NSEvent* currentEvent = [NSApp currentEvent];
//    unsigned flags = [currentEvent modifierFlags];
//	if (flags & NSAlternateKeyMask)
//		if ([columnIdentifier isEqualToString:@"forceOption"] || [columnIdentifier isEqualToString:@"exactOption"] || [columnIdentifier isEqualToString:@"commitOption"] || [columnIdentifier isEqualToString:@"importBranchOption"])
//			for (PatchData* patch in patchesTableData_)
//				[patch setValue:anObject forKey:columnIdentifier];
//	[self reloadData];
//}
//
//
//
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
		FSNodeInfo* node = [[self leafNodeForTableRow] objectAtIndex:row];
		[paths addObject:[node absolutePath]];
	}];
	return [parentViewer_ writePaths:paths toPasteboard:pasteboard];	// The parent handles writing out the pasteboard items
}




@end
