//
//  FSViewerTable.m
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import "FSViewerTable.h"
#import "FSNodeInfo.h"

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

- (NSArray*) theLeafNodeList
{
	@synchronized(self)
	{
		if (!theLeafNodeList_)
			[self regenerateTableData];
	}
	return theLeafNodeList_;
}

- (void) regenerateTableData
{
	theLeafNodeList_ = [[parentViewer_ rootNodeInfo] generateFlatLeafNodeList];
}

- (void) reloadData
{
	[self regenerateTableData];
	[super reloadData];
}

- (void) reloadDataSin
{
	[self reloadData];
}

- (void) prepareToOpenFSViewerPane
{
	[self reloadData];
	[[[parentViewer_ myDocument] mainWindow] makeFirstResponder:self];
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Testing of selection and clicks
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)		nodesAreSelected				{ return NO; }
- (BOOL)		nodeIsClicked					{ return NO; }
- (BOOL)		nodesAreChosen					{ return NO; }
- (FSNodeInfo*) clickedNode						{ return nil; }
- (BOOL)		clickedNodeInSelectedNodes		{ return NO; }
- (FSNodeInfo*) chosenNode						{ return nil; }
- (NSArray*)	selectedNodes;					{ return [NSArray array]; }
- (NSArray*)	chosenNodes						{ return [NSArray array]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path and Selection Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)		singleFileIsChosenInBrowser											{ return NO; }
- (BOOL)		singleItemIsChosenInBrowser											{ return NO; }
- (HGStatus)	statusOfChosenPathsInBrowser										{ return eHGStatusClean; }
- (NSArray*)	absolutePathsOfSelectedFilesInBrowser								{ return [NSArray array]; }
- (NSArray*)	absolutePathsOfChosenFilesInBrowser									{ return [NSArray array]; }
- (NSString*)	enclosingDirectoryOfChosenFilesInBrowser							{ return @""; }
- (NSArray*)	filterPaths:(NSArray*)absolutePaths byBitfield:(HGStatus)status		{ return [NSArray array]; }


// Graphic Operations
- (NSRect)		frameinWindowOfRow:(NSInteger)row inColumn:(NSInteger)column		{ return NSMakeRect(0, 0, 20, 20); }

- (BOOL)		clickedNodeCoincidesWithTerminalSelections							{ return NO; }

- (void)		repositoryDataIsNew													{ }
- (NSArray*)	quickLookPreviewItems												{ return [NSArray array]; }

// Save and restore browser, outline, or table state
- (FSViewerSelectionState*)	saveViewerSelectionState								{ return [[FSViewerSelectionState alloc]init]; }
- (void)					restoreViewerSelectionState:(FSViewerSelectionState*)savedState {}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewerTable Data Source
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [[self theLeafNodeList] count];
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)requestedRow
{
	FSNodeInfo* node = [[self theLeafNodeList] objectAtIndex:requestedRow];
	return [node absolutePath];
//	NSString* requestedColumn = [aTableColumn identifier];	
//	id value = [patch valueForKey:requestedColumn];
//	return value;
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
//- (void) tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
//{
//	[aCell setPatchesTableColumn:aTableColumn];
//	[aCell setPatch:[patchesTableData_ objectAtIndex:rowIndex]];
//}
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

//static NSAttributedString*   normalAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:smallSystemFontAttributes]; }
//static NSAttributedString*   grayedAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:smallGraySystemFontAttributes]; }
//
//
//- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
//{
//	WebScriptObject* script = [detailedPatchWebView windowScriptObject];
//	[script setValue:self forKey:@"macHgPatchesTableView"];
//	NSInteger selectedRowCount = [[self selectedRowIndexes] count];
//	if (selectedRowCount == 0)
//	{
//		[script callWebScriptMethod:@"showMessage" withArguments:[NSArray arrayWithObject:@"No Patch Selected"]];
//	}
//	else if (selectedRowCount > 1)
//	{
//		[script callWebScriptMethod:@"showMessage" withArguments:[NSArray arrayWithObject:@"Multiple Patches Selected"]];
//	}
//	else
//	{
//		NSArray* showDiffArgs = [NSArray arrayWithObject:[[self selectedPatch] patchBody]];
//		[script callWebScriptMethod:@"showDiff" withArguments:showDiffArgs];
//	}
//}
//
//// Clicking on the checkboxes in the table view shouldn't change the selection.
//- (BOOL) selectionShouldChangeInTableView:(NSTableView*)aTableView
//{
//	NSInteger column = [self clickedColumn];
//	if (column < 0)
//		return YES;
//	NSTableColumn* clickedTableColumn = [[self tableColumns] objectAtIndex:column];
//	NSString* columnIdentifier = [clickedTableColumn identifier];
//	if ([columnIdentifier isEqualToString:@"forceOption"] || [columnIdentifier isEqualToString:@"exactOption"] || [columnIdentifier isEqualToString:@"commitOption"] || [columnIdentifier isEqualToString:@"importBranchOption"])
//		return NO;
//	return YES;
//}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Delegates Drag & Drop
// -----------------------------------------------------------------------------------------------------------------------------------------

//- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal  { return NSDragOperationMove; }
//
//
//- (BOOL) tableView:(NSTableView*)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
//{
//    // Copy the row numbers to the pasteboard.
//    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
//    [pboard declareTypes:[NSArray arrayWithObject:kPatchesTablePBoardType] owner:self];
//    [pboard setData:data forType:kPatchesTablePBoardType];
//    return YES;
//}
//
//- (NSDragOperation) tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
//{
//    // Add code here to validate the drop
//	NSPasteboard* pboard = [info draggingPasteboard];	// get the pasteboard
//	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kPatchesTablePBoardType]])
//	{
//		if (op == NSTableViewDropAbove)
//			return NSDragOperationMove;
//	}
//	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
//	{
//		NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
//		NSArray* resolvedFilenames = [filenames resolveSymlinksAndAliasesInPaths];
//		for (NSString* file in resolvedFilenames)
//			if (pathIsExistentFile(file))
//				return NSDragOperationCopy;
//	}
//	
//	return NSDragOperationNone;
//}
//
//- (BOOL) tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)dropRow dropOperation:(NSTableViewDropOperation)operation
//{
//    NSPasteboard* pboard = [info draggingPasteboard];
//	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kPatchesTablePBoardType]])
//	{
//		NSData* rowData = [pboard dataForType:kPatchesTablePBoardType];
//		NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
//		NSMutableArray* newTableData = [[NSMutableArray alloc] initWithArray:patchesTableData_];
//		[newTableData removeObjectsAtIndexes:rowIndexes];
//		NSArray* patchesToMove = [patchesTableData_ objectsAtIndexes:rowIndexes];
//		NSInteger rowsRemovedBeforeDropRow = [rowIndexes countOfIndexesInRange:NSMakeRange(0, dropRow)];
//		NSIndexSet* insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dropRow - rowsRemovedBeforeDropRow, [rowIndexes count])];
//		[newTableData insertObjects:patchesToMove atIndexes:insertionIndexes];
//		patchesTableData_ = newTableData;
//		[self reloadData];
//		[self selectRowIndexes:insertionIndexes byExtendingSelection:NO];
//		[parentController patchesDidChange];
//		return YES;
//	}
//	
//	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
//	{
//		NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
//		NSArray* resolvedFilenames = [filenames resolveSymlinksAndAliasesInPaths];
//		NSMutableArray* newPatches = [[NSMutableArray alloc]init];
//		for (NSString* path in resolvedFilenames)
//			if (pathIsExistentFile(path))
//			{
//				PatchData* patch = [PatchData patchDataFromFilePath:path];
//				[newPatches addObject:patch];
//			}
//		NSMutableArray* newTableData = [[NSMutableArray alloc] initWithArray:patchesTableData_];
//		NSIndexSet* insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dropRow, [newPatches count])];
//		[newTableData insertObjects:newPatches atIndexes:insertionIndexes];
//		patchesTableData_ = newTableData;
//		[self reloadData];
//		[self selectRowIndexes:insertionIndexes byExtendingSelection:NO];
//		[parentController patchesDidChange];
//		return YES;
//	}
//	
//	return NO;
//}


@end
