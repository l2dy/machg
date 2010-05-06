//
//  PatchesTableView.m
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import "HistoryPaneController.h"
#import "TaskExecutions.h"
#import "RepositoryData.h"
#import "LogTableView.h"
#import "PatchData.h"
#import "PatchesTableView.h"
#import "MacHgDocument.h"
#import "NSString+SymlinksAndAliases.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Forward Declarations
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface PatchesTableView()
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchesTableView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation PatchesTableView





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	if (self)
	{
		patchesTableData_ = nil;
	}
    
	return self;
}


- (void) awakeFromNib
{
//	[self observe:kRepositoryDataIsNew		from:[self myDocument]  byCalling:@selector(repositoryDataIsNew)];
//	[self observe:kRepositoryDataDidChange	from:[self myDocument]  byCalling:@selector(logEntriesDidChange:)];
//	[self observe:kLogEntriesDidChange			from:[self myDocument]  byCalling:@selector(logEntriesDidChange:)];
	
	// Tell the browser to send us messages when it is clicked.
	[self setTarget:self];
	[self setAction:@selector(patchTableSingleClick:)];
	[self setDoubleAction:@selector(patchTableDoubleClick:)];
	[self setDelegate:self];
	[self setDataSource:self];

	// drag and drop support
	[self registerForDraggedTypes:[NSArray arrayWithObjects:kPatchesTablePBoardType, NSFilenamesPboardType, nil]];
}

- (MacHgDocument*)		myDocument			{ return [parentController myDocument]; }

- (void) unload					{ }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quieres
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)	   patchIsSelected	{ return 0 <= [self selectedRow] && [self selectedRow] < [patchesTableData_ count]; }
- (BOOL)	   patchIsClicked	{ return [self clickedRow] != -1; }
- (PatchData*) selectedPatch	{ return [self patchIsSelected] ? [patchesTableData_ objectAtIndex:[self selectedRow]] : nil; }
- (PatchData*) clickedPatch		{ return [self patchIsClicked]  ? [patchesTableData_ objectAtIndex:[self clickedRow]]  : nil; }
- (PatchData*) chosenPatch		{ PatchData* ans = [self clickedPatch]; return ans ? ans : [self selectedPatch]; }
- (NSArray*)   patches			{ return patchesTableData_; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Patches Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) patchTableSingleClick:(id)sender
{
}

- (IBAction) patchTableDoubleClick:(id)sender
{
	[self patchTableSingleClick:sender];
}


- (IBAction) removeSelectedPatches:(id)sender
{
	NSMutableArray* newTableData = [NSMutableArray arrayWithArray:patchesTableData_];
	[newTableData removeObjectsAtIndexes:[self selectedRowIndexes]];
	patchesTableData_ = newTableData;
	[self deselectAll:self];
	[self reloadData];
}


- (void) addPatches:(NSArray*)patches
{
	if (!patchesTableData_)
		patchesTableData_ = patches;
	else
	{
		NSArray* newTableData = [patchesTableData_ arrayByAddingObjectsFromArray:patches];
		patchesTableData_ = newTableData;
	}
	[self reloadData];
}

- (BOOL) removePatchAtIndex:(NSInteger)index
{
	if (index < 0 || index >= [patchesTableData_ count])
		return NO;
	NSMutableArray* newTableData = [NSMutableArray arrayWithArray:patchesTableData_];
	[newTableData removeObjectAtIndex:index];
	patchesTableData_ = newTableData;
	[self deselectAll:self];
	[self reloadData];
	return YES;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Patches Table Data
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) recomputePatchesTableData
{
}

- (NSArray*) patchesTableData
{
	return patchesTableData_;
}

- (NSInteger) tableRowForPatch:(PatchData*)patch
{
	if (!patch)
		return NSNotFound;
	if (IsEmpty(patchesTableData_))
		return NSNotFound;	
	return [patchesTableData_ indexOfObject:patch];
}


- (IBAction) resetTable:(id)sender
{
	[self recomputePatchesTableData];
	dispatch_async(mainQueue(), ^{
		[self reloadData]; });
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Patches Table View Data Source
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [[self patchesTableData] count];
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)requestedRow
{
	PatchData* patch = [[self patchesTableData] objectAtIndex:requestedRow];
	NSString* requestedColumn = [aTableColumn identifier];

	id value = [patch valueForKey:requestedColumn];
	return value;
}

- (void) tableView:(NSTableView*)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	PatchData* clickedPatch = [[self patchesTableData] objectAtIndex:rowIndex];
	NSString* columnIdentifier = [aTableColumn identifier];
	[clickedPatch setValue:anObject forKey:columnIdentifier];

	NSEvent* currentEvent = [NSApp currentEvent];
    unsigned flags = [currentEvent modifierFlags];
	if (flags & NSAlternateKeyMask)
		if ([columnIdentifier isEqualToString:@"forceOption"] || [columnIdentifier isEqualToString:@"exactOption"] || [columnIdentifier isEqualToString:@"commitOption"] || [columnIdentifier isEqualToString:@"importBranchOption"])
			for (PatchData* patch in patchesTableData_)
				[patch setValue:anObject forKey:columnIdentifier];
	[self reloadData];
}

- (void) tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	[aCell setPatchesTableColumn:aTableColumn];
	[aCell setPatch:[patchesTableData_ objectAtIndex:rowIndex]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Table View Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

static NSAttributedString*   normalAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:smallSystemFontAttributes]; }
static NSAttributedString*   grayedAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:smallGraySystemFontAttributes]; }


- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
{
	NSInteger selectedRowCount = [[self selectedRowIndexes] count];
	if (selectedRowCount == 0)
	{
		[[detailedPatchTextView textStorage] setAttributedString:grayedAttributedString(@"No Patch Selected")];		
	}
	else if (selectedRowCount > 1)
	{
		[[detailedPatchTextView textStorage] setAttributedString:grayedAttributedString(@"Multiple Patches Selected")];
	}
	else
	{
		[[detailedPatchTextView textStorage] setAttributedString:[[self selectedPatch] patchBodyColorized]];
	}
}

// Clicking on the checkboxes in the table view shouldn't change the selection.
- (BOOL) selectionShouldChangeInTableView:(NSTableView*)aTableView
{
	NSInteger column = [self clickedColumn];
	if (column < 0)
		return YES;
	NSTableColumn* clickedTableColumn = [[self tableColumns] objectAtIndex:column];
	NSString* columnIdentifier = [clickedTableColumn identifier];
	if ([columnIdentifier isEqualToString:@"forceOption"] || [columnIdentifier isEqualToString:@"exactOption"] || [columnIdentifier isEqualToString:@"commitOption"] || [columnIdentifier isEqualToString:@"importBranchOption"])
		return NO;
	return YES;
}

- (BOOL) tableView:(NSTableView*)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
	return YES;
}

// We want a return in the edited cell of a commitMessage cell to add a newline rather than committing the cell.
- (BOOL) control:(NSControl*)control textView:(NSTextView*)fieldEditor doCommandBySelector:(SEL)commandSelector
{
	if (commandSelector != @selector(insertNewline:))
		return NO;
	
	NSInteger theEditedColumn = [self editedColumn];
	if (theEditedColumn < 0 || theEditedColumn >= [[self tableColumns]count])
		return NO;
	NSTableColumn* editedTableColumn = [[self tableColumns] objectAtIndex:theEditedColumn];
	NSString* columnIdentifier = [editedTableColumn identifier];
	if ([columnIdentifier isNotEqualToString:@"commitMessage"])
		return NO;

	[fieldEditor insertNewlineIgnoringFieldEditor:nil];
	return YES;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Delegates Drag & Drop
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal  { return NSDragOperationMove; }


- (BOOL) tableView:(NSTableView*)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:kPatchesTablePBoardType] owner:self];
    [pboard setData:data forType:kPatchesTablePBoardType];
    return YES;
}

- (NSDragOperation) tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    // Add code here to validate the drop
    NSLog(@"validate Drop");
	NSPasteboard* pboard = [info draggingPasteboard];	// get the pasteboard
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kPatchesTablePBoardType]])
	{
		if (op == NSTableViewDropAbove)
			return NSDragOperationMove;
	}
	else if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
	{
		NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
		NSArray* resolvedFilenames = [filenames resolveSymlinksAndAliasesInPaths];
		for (NSString* file in resolvedFilenames)
			if (pathIsExistentFile(file))
				return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}




- (BOOL) tableView:(NSTableView*)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)dropRow dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kPatchesTablePBoardType]])
	{
		NSData* rowData = [pboard dataForType:kPatchesTablePBoardType];
		NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
		NSMutableArray* newTableData = [[NSMutableArray alloc] initWithArray:patchesTableData_];
		[newTableData removeObjectsAtIndexes:rowIndexes];
		NSArray* patchesToMove = [patchesTableData_ objectsAtIndexes:rowIndexes];
		NSInteger rowsRemovedBeforeDropRow = [rowIndexes countOfIndexesInRange:NSMakeRange(0, dropRow)];
		NSIndexSet* insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dropRow - rowsRemovedBeforeDropRow, [rowIndexes count])]; 
		[newTableData insertObjects:patchesToMove atIndexes:insertionIndexes];
		patchesTableData_ = newTableData;		
		[self reloadData];
		[self selectRowIndexes:insertionIndexes byExtendingSelection:NO];
		[parentController patchesDidChange];
		return YES;
	}
	
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
	{
		NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
		NSArray* resolvedFilenames = [filenames resolveSymlinksAndAliasesInPaths];
		NSMutableArray* newPatches = [[NSMutableArray alloc]init];
		for (NSString* path in resolvedFilenames)
			if (pathIsExistentFile(path))
			{
				PatchData* patch = [PatchData patchDataFromFilePath:path];
				[newPatches addObject:patch];
			}
		NSMutableArray* newTableData = [[NSMutableArray alloc] initWithArray:patchesTableData_];
		NSIndexSet* insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(dropRow, [newPatches count])]; 
		[newTableData insertObjects:newPatches atIndexes:insertionIndexes];
		patchesTableData_ = newTableData;		
		[self reloadData];
		[self selectRowIndexes:insertionIndexes byExtendingSelection:NO];
		[parentController patchesDidChange];
		return YES;
	}
	
	return NO;
}



//- (BOOL)outlineView:(NSOutlineView*)outlineView  acceptDrop:(id<NSDraggingInfo>)info  item:(id)targetItem  childIndex:(NSInteger)index
//{
//	NSPasteboard* pboard = [info draggingPasteboard];	// get the pasteboard
//	
//	Patch* targetParent = targetItem;
//	if (targetParent == nil)
//		targetParent = root_;
//	
//	// We are dragging files in from the finder.
//	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
//	{
//		PatchData* copiedTree = [root_ copyNodeTree];
//		[[self prepareUndoWithTarget:self] setRootAndUpdate:copiedTree];
//		[[self undoManager] setActionName:@"Drag"];
//		
//		NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
//		PatchData* newSelectedNode = nil;
//		for (id file in filenames)
//			if (pathIsDirectory(file) && repositoryExistsAtPath(file))
//			{
//				PatchData* node = [PatchData nodeForLocalURL:file];
//				[targetParent insertChild:node atIndex:index];
//				[[AppController sharedAppController] computeRepositoryIdentityForPath:file];
//				newSelectedNode = node;
//			}
//		
//		for (id file in filenames)
//			if (pathIsDirectory(file) && !repositoryExistsAtPath(file))
//			{
//				NSString* fileName = [[NSFileManager defaultManager] displayNameAtPath:file];
//				[[myDocument theLocalRepositoryRefSheetController] openSheetForNewRepositoryRefNamed:fileName atPath:file addNewRepositoryRefTo:targetParent atIndex:index];
//				return YES;
//			}
//		
//		[self reloadData];
//		if (newSelectedNode)
//			[self selectNode:newSelectedNode];
//		[self outlineViewSelectionDidChange:nil];
//		return YES;
//	}
//	
//	return YES;
//}
//



@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchesTableCell
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation PatchesTableCell

@synthesize patchesTableColumn = patchesTableColumn_;
@synthesize patch = patch_;

- (NSColor*) cellBackingColor
{
	PatchData* patch = [self patch];
	if (![patch isModified])
		return nil;
	
	NSString* columnIdentifier = [[self patchesTableColumn] identifier];
	if (
		([patch authorIsModified]			&& [columnIdentifier isEqualToString:@"author"]) ||
		([patch dateIsModified]				&& [columnIdentifier isEqualToString:@"date"]) ||
		([patch parentIsModified]			&& [columnIdentifier isEqualToString:@"parent"]) ||
		([patch commitMessageIsModified]	&& [columnIdentifier isEqualToString:@"commitMessage"])
		)
		return [NSColor colorWithCalibratedRed:1.0 green:0.9 blue:0.9 alpha:1.0];
	
	return nil;
}

- (NSColor*) highlightColorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSColor* backingColor = [self cellBackingColor];
	NSColor* highlightColor = [super highlightColorWithFrame:cellFrame inView:controlView];
	if (!backingColor)
		return highlightColor;
	return [highlightColor blendedColorWithFraction:0.5 ofColor:backingColor];
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSColor* backingColor = [self cellBackingColor];
	if (backingColor)
	{
		[backingColor set];
		[NSBezierPath fillRect:cellFrame];
	}
	[super drawWithFrame:cellFrame inView:controlView];
}



@end



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchesTableCommitMessageCell
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation PatchesTableCommitMessageCell

- (void) editWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject event:(NSEvent*)theEvent
{
	aRect = UnionWidthHeight(aRect, 300, 45);
	aRect = UnionSize(aRect, [[self attributedStringValue] size]);
    [super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

// NSTableView may call selectWithFrame: or editWithFrame: depending on how it is invoked. This code should mirror the above
// method. selectWithFrame: differs by starting an editing session and selecting all the text in the cell.
- (void) selectWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	aRect = UnionWidthHeight(aRect, 300, 45);
	aRect = UnionSize(aRect, [[self attributedStringValue] size]);
    [super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

// Expansion tool tip support
- (NSRect) expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView*)view
{
	cellFrame = UnionSize(cellFrame, [[self attributedStringValue] size]);
	
	// We want to make the cell *slightly* larger; it looks better when showing the expansion tool tip.
	cellFrame.size.width += 4.0;
	cellFrame.origin.x   -= 2.0;
    return cellFrame;
}

- (void) drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView*)view
{
    NSAttributedString* message = [self attributedStringValue];
	cellFrame = UnionSize(cellFrame, [message size]);
    if ([message length] > 0)
	{
        cellFrame.origin.x += 2.0;
        cellFrame.size.width -= 2.0;
        [message drawInRect:cellFrame];
    }
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchesTableButtonCell
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation PatchesTableButtonCell
@synthesize patchesTableColumn = patchesTableColumn_;
@synthesize patch = patch_;

- (void) mouseEntered:(NSEvent*)event
{
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:1.0];
	[[buttonMessage animator] setHidden:NO];
	[NSAnimationContext endGrouping];
}
- (void) mouseExited:(NSEvent*)event
{
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:1.0];
	[[buttonMessage animator] setHidden:YES];
	[NSAnimationContext endGrouping];	
}

- (BOOL) showsBorderOnlyWhileMouseInside
{
	return YES;
}

@end;
