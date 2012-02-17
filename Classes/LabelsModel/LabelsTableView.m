//
//  LabelsTableView.m
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import "HistoryViewController.h"
#import "TaskExecutions.h"
#import "RepositoryData.h"
#import "LogTableView.h"
#import "LabelData.h"
#import "LabelsTableView.h"
#import "AddLabelSheetController.h"
#import "MacHgDocument.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Forward Declarations
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface LabelsTableView()
- (void) logEntriesDidChange:(NSNotification*)notification;
- (void) recomputeLabelsTableData;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  LabelsTableView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation LabelsTableView





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	if (self)
	{
		labelsTableData_ = nil;
		labelsTableFilterType_ = eNoLabelType;
		awake_ = NO;
	}
    
	return self;
}


- (void) awakeFromNib
{
	[self observe:kRepositoryDataIsNew		from:[self myDocument]  byCalling:@selector(repositoryDataIsNew)];
	[self observe:kRepositoryDataDidChange	from:[self myDocument]  byCalling:@selector(repositoryDataDidChange:)];
	[self observe:kLogEntriesDidChange		from:[self myDocument]  byCalling:@selector(logEntriesDidChange:)];
	
	// Tell the browser to send us messages when it is clicked.
	[self setTarget:self];
	[self setAction:@selector(labelTableSingleClick:)];
	[self setDoubleAction:@selector(labelTableDoubleClick:)];
	[self setDelegate:self];
	[self setDataSource:self];
	
	// Stop garbage littering on Lion see issue #273
	[DynamicCast(NSClipView, [self superview]) setCopiesOnScroll:NO];
	awake_ = YES;
	[self resetTable:self];
}

- (MacHgDocument*)		myDocument			{ return [parentController myDocument]; }

- (void) unload					{ }






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quieres
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)	  labelIsSelected	{ return 0 <= [self selectedRow] && [self selectedRow] < [labelsTableData_ count]; }
- (BOOL)	  labelIsClicked	{ return [self clickedRow] != -1; }
- (LabelData*) selectedLabel	{ return [self labelIsSelected] ? [labelsTableData_ objectAtIndex:[self selectedRow]] : nil; }
- (LabelData*) clickedLabel		{ return [self labelIsClicked]  ? [labelsTableData_ objectAtIndex:[self clickedRow]]  : nil; }
- (LabelData*) chosenLabel		{ LabelData* ans = [self clickedLabel]; return ans ? ans : [self selectedLabel]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Notification responses
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) repositoryDataIsNew
{
	[self resetTable:self];
	[parentController labelsChanged];
}


- (void) repositoryDataDidChange:(NSNotification*)notification
{
	[self resetTable:self];
	[parentController labelsChanged];
}


- (void) logEntriesDidChange:(NSNotification*)notification
{
	[self refreshTable:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Labels Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) labelTableSingleClick:(id) sender
{
	LabelData* label = [self chosenLabel];
	LogTableView* logTable = [[[self myDocument] theHistoryView] logTableView];
	[logTable scrollToRevision:[label revision]];
}

- (IBAction) labelTableDoubleClick:(id) sender
{
	[self labelTableSingleClick:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Labels Table Data
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setButtonsFromLabelType:(LabelType)labelType
{
	[showTags setState:bitsInCommon(eTagLabel, labelType)];
	[showBookmarks setState:bitsInCommon(eBookmarkLabel, labelType)];
	[showBranches setState:bitsInCommon(eOpenBranchLabel, labelType)];
	[showClosedBranches setState:bitsInCommon(eClosedBranch, labelType)];
	[showOpenHeads setState:bitsInCommon(eOpenHead, labelType)];
}

- (LabelType) labelTypeFilterOfButtons
{
	return
		([showTags state] ? eTagLabel : eNoLabelType) |
		([showBookmarks state] ? eBookmarkLabel : eNoLabelType) |
		([showBranches state] ? eOpenBranchLabel : eNoLabelType) |
		([showClosedBranches state] ? eClosedBranch : eNoLabelType) |
		([showOpenHeads state] ? eOpenHead : eNoLabelType);
}

- (void) recomputeLabelsTableData
{
	@synchronized(self)
	{
		labelsTableFilterType_ = [self labelTypeFilterOfButtons];
		RepositoryData* collection = [[parentController myDocument] repositoryData];
		NSArray* newTableData = [LabelData filterLabelsDictionary:[collection revisionNumberToLabels] byType:labelsTableFilterType_];
		NSArray* descriptors = [self sortDescriptors];
		labelsTableData_ = [LabelData removeDuplicateLabels:newTableData];
		labelsTableData_ = [labelsTableData_ sortedArrayUsingDescriptors:descriptors];
		[parentController labelsChanged];
		dispatch_async(mainQueue(), ^{
			[self reloadData];});
	}
}

- (NSArray*) labelsTableData
{	
	if ([self labelTypeFilterOfButtons] != labelsTableFilterType_)
		[self recomputeLabelsTableData];
	return labelsTableData_;
}

- (NSInteger) tableRowForLabel:(LabelData*)label
{
	if (!label)
		return NSNotFound;
	if (IsEmpty(labelsTableData_))
		return NSNotFound;
	return [labelsTableData_ indexOfObject:label];
}


- (IBAction) resetTable:(id)sender
{
	if (!awake_)
		return;
	[self recomputeLabelsTableData];
}

- (IBAction) refreshTable:(id)sender
{
	if (!awake_)
		return;
	dispatch_async(mainQueue(), ^{
		[self reloadData];});
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Labels Table View Data Source
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [[self labelsTableData] count];
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)requestedRow
{
	if ([self numberOfRowsInTableView:aTableView] <= requestedRow)	return fstr(@"%d",requestedRow);

	LabelData* label = [[self labelsTableData] objectAtIndex:requestedRow];
	NSString* requestedColumn = [aTableColumn identifier];
	return [label valueForKey:requestedColumn];
}

- (void) tableView:(NSTableView*)aTableView sortDescriptorsDidChange:(NSArray*)oldDescriptors
{
	LabelData* selectedLabel = [self selectedLabel];
	NSArray* descriptors = [self sortDescriptors];
	labelsTableData_ = [labelsTableData_ sortedArrayUsingDescriptors:descriptors];
	dispatch_async(mainQueue(), ^{
		[aTableView reloadData];
		if (selectedLabel)
		{
			NSInteger newRow = [self tableRowForLabel:selectedLabel];
			[self scrollToRangeOfRowsLow:newRow high:newRow];
			[self selectRow:newRow];
		}
	});
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Table View Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
{
	LabelData* label = [self chosenLabel];
	if (label)
	{
		LogTableView* logTable = [[[self myDocument] theHistoryView] logTableView];
		[logTable scrollToRevision:[label revision]];
	}
	[parentController labelsChanged];
}




@end
