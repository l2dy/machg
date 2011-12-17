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

@implementation FSViewerOutline

@synthesize parentViewer = parentViewer_;

- (void) awakeFromNib
{
	[self setDelegate:self];
	[self setDataSource:self];
}

- (void) reloadData
{
	[self setRowHeight:[parentViewer_ rowHeightForFont]];
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

- (FSNodeInfo*) nodeAtIndex:(NSInteger)index
{
	@try
	{
		return [self itemAtRow:index];
	}
	@catch (NSException* ne)
	{
		return nil;
	}
	return nil;
}

- (BOOL)		nodesAreSelected	{ return IsNotEmpty([self selectedRowIndexes]); }
- (BOOL)		nodeIsClicked		{ return [self clickedRow] != -1; }
- (BOOL)		nodesAreChosen		{ return [self nodeIsClicked] || [self nodesAreSelected]; }
- (FSNodeInfo*) selectedNode		{ return [self nodeAtIndex:[self selectedRow]]; }
- (FSNodeInfo*) clickedNode			{ return [self nodeAtIndex:[self clickedRow]]; }
- (FSNodeInfo*) chosenNode			{ FSNodeInfo* ans = [self clickedNode]; return ans ? ans : [self selectedNode]; }
- (NSArray*)	selectedNodes		{ return [self selectedItems]; }

- (BOOL) clickedNodeInSelectedNodes
{
	if (![self nodeIsClicked])
		return NO;
	return [[self selectedRowIndexes] containsIndex:[self clickedRow]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path and Selection Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)		singleFileIsChosenInBrowser											{ return NO; }
- (BOOL)		singleItemIsChosenInBrowser											{ return NO; }


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


//- (NSCell*) outlineView:(NSOutlineView*)outlineView  dataCellForTableColumn:(NSTableColumn*)tableColumn item:(id)item	{ return [tableColumn dataCell]; }
//- (BOOL)	outlineView:(NSOutlineView*)outlineView  shouldEditTableColumn:(NSTableColumn*)tableColumn  item:(id)item   { return YES; }
//- (BOOL)	outlineView:(NSOutlineView*)outlineView  shouldSelectItem:(id)item											{ return YES; }
//- (BOOL)	outlineView:(NSOutlineView*)outlineView  isGroupItem:(id)item												{ return ![item isRepositoryRef]; }
//- (void)	outlineView:(NSOutlineView*)outlineView  willDisplayCell:(NSCell*)cell  forTableColumn:(NSTableColumn*)tableColumn  item:(id)item
//{
//	if ([cell isKindOfClass:[SidebarCell class]])
//	{
//		SidebarCell* badgeCell = (SidebarCell*) cell;
//		SidebarNode* node = ExactDynamicCast(SidebarNode,item);
//		SidebarNode* selectedNode = [self selectedNode];
//		NSString* outgoingCount = [outgoingCounts objectForKey:[node path]];
//		NSString* incomingCount = [incomingCounts objectForKey:[node path]];
//		if (node != selectedNode && outgoingCount && incomingCount)
//		{
//			NSString* badgeString = fstr(@"%@↓:%@↑",incomingCount, outgoingCount);
//			[badgeCell setBadgeString:badgeString];
//			[badgeCell setHasBadge:YES];
//		}
//		else if (node != selectedNode && [node isCompatibleTo:selectedNode])
//		{
//			[badgeCell setBadgeString:@" "];
//			[badgeCell setHasBadge:YES];
//		}
//		else
//		{
//			[badgeCell setBadgeString:nil];
//			[badgeCell setHasBadge:NO];
//		}
//		
//		// If the icon disagrees with the repo being present or not then update it.
//		if ([node isLocalRepositoryRef])
//		{
//			BOOL exists = repositoryExistsAtPath([node path]);
//			NSString* name = [[node icon] name];
//			BOOL nameIsMissingRepository = [name isEqualToString:@"MissingRepository"];
//			if ((exists && nameIsMissingRepository) || (!exists && !nameIsMissingRepository))
//				[node refreshNodeIcon];
//		}
//		
//		[badgeCell setIcon:[node icon]];
//		if (![node isSectionNode])
//			[badgeCell setAttributedStringValue:[node attributedStringForNode]];
//	}
//}


@end
