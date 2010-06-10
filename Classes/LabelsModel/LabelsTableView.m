//
//  LabelsTableView.m
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
		cachedTagToLabelDictionary_ = nil;
		cachedBranchToLabelDictionary_ = nil;
		cachedBookmarkToLabelDictionary_ = nil;
		cachedOpenHeadToLabelDictionary_ = nil;
		labelsTableData_ = nil;
		repositoryData_ = nil;
		oldRepositoryData_ = nil;
	}
    
	return self;
}


- (void) awakeFromNib
{
	[self observe:kRepositoryDataIsNew		from:[self myDocument]  byCalling:@selector(repositoryDataIsNew)];
	[self observe:kRepositoryDataDidChange	from:[self myDocument]  byCalling:@selector(logEntriesDidChange:)];
	[self observe:kLogEntriesDidChange		from:[self myDocument]  byCalling:@selector(logEntriesDidChange:)];
	
	// Tell the browser to send us messages when it is clicked.
	[self setTarget:self];
	[self setAction:@selector(labelTableSingleClick:)];
	[self setDoubleAction:@selector(labelTableDoubleClick:)];
	[self setDelegate:self];
	[self setDataSource:self];
}

- (MacHgDocument*)		myDocument			{ return [parentController myDocument]; }

- (void) unload					{ }


- (RepositoryData*)	repositoryData
{
	if (repositoryData_)
		return repositoryData_;
	repositoryData_ = [[parentController myDocument] repositoryData];
	return repositoryData_;
}





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
	oldRepositoryData_ = repositoryData_;
	repositoryData_ = [[parentController myDocument] repositoryData];
	[self recomputeLabelsTableData];
	dispatch_async(mainQueue(), ^{
		[self reloadData];});
	[parentController labelsChanged];
}


- (void) logEntriesDidChange:(NSNotification*)notification
{
	NSString* changeType = [[notification userInfo] objectForKey:kLogEntryChangeType];
	if ([changeType isEqualTo:kLogEntryTagsChanged] || [changeType isEqualTo:kLogEntryBranchesChanged] || [changeType isEqualTo:kLogEntryBookmarksChanged] || [changeType isEqualTo:kLogEntryOpenHeadsChanged])
		[self recomputeLabelsTableData];
	dispatch_async(mainQueue(), ^{
		[self reloadData];});
	[parentController labelsChanged];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Labels Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) labelTableSingleClick:(id) sender
{
	LabelData* label = [self chosenLabel];
	LogTableView* logTable = [[[self myDocument] theHistoryPaneController] logTableView];
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

- (void) recomputeLabelsTableData
{
	@synchronized(self)
	{
		RepositoryData* collection = (![[self repositoryData] labelsAreFullyLoaded] && [oldRepositoryData_ labelsAreFullyLoaded]) ? oldRepositoryData_ : [self repositoryData];
		
		NSDictionary* liveTagToLabelDictionary		 = [showTags state]		 ? [collection tagToLabelDictionary] : nil;
		NSDictionary* liveBookmarksToLabelDictionary = [showBookmarks state] ? [collection bookmarkToLabelDictionary] : nil;
		NSDictionary* liveBranchToLabelDictionary	 = [showBranches state]	 ? [collection branchToLabelDictionary] : nil;
		NSDictionary* liveOpenHeadToLabelDictionary	 = [showOpenHeads state] ? [collection openHeadToLabelDictionary] : nil;
		cachedTagToLabelDictionary_      = liveTagToLabelDictionary;
		cachedBookmarkToLabelDictionary_ = liveBookmarksToLabelDictionary;
		cachedBranchToLabelDictionary_   = liveBranchToLabelDictionary;
		cachedOpenHeadToLabelDictionary_ = liveOpenHeadToLabelDictionary;
		NSMutableArray* newTableData     = [[NSMutableArray alloc] init];
		if (liveTagToLabelDictionary)		[newTableData addObjectsFromArray:[liveTagToLabelDictionary allValues]];
		if (liveBookmarksToLabelDictionary)	[newTableData addObjectsFromArray:[liveBookmarksToLabelDictionary allValues]];
		if (liveBranchToLabelDictionary)	[newTableData addObjectsFromArray:[liveBranchToLabelDictionary allValues]];
		if (liveOpenHeadToLabelDictionary)	[newTableData addObjectsFromArray:[liveOpenHeadToLabelDictionary allValues]];

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
	RepositoryData* collection = (![[self repositoryData] labelsAreFullyLoaded] && [oldRepositoryData_ labelsAreFullyLoaded]) ? oldRepositoryData_ : [self repositoryData];

	NSDictionary* liveTagToLabelDictionary		 = [showTags state]		 ? [collection tagToLabelDictionary] : nil;
	NSDictionary* liveBookmarksToLabelDictionary = [showBookmarks state] ? [collection bookmarkToLabelDictionary] : nil;
	NSDictionary* liveBranchToLabelDictionary	 = [showBranches state]  ? [collection branchToLabelDictionary] : nil;
	NSDictionary* liveOpenHeadToLabelDictionary	 = [showOpenHeads state] ? [collection openHeadToLabelDictionary] : nil;
	if (liveTagToLabelDictionary       != cachedTagToLabelDictionary_ ||
		liveBookmarksToLabelDictionary != cachedBookmarkToLabelDictionary_ ||
		liveBranchToLabelDictionary    != cachedBranchToLabelDictionary_ ||
		liveOpenHeadToLabelDictionary  != cachedOpenHeadToLabelDictionary_ ||
		labelsTableData_ == nil)
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
	[self recomputeLabelsTableData];
	dispatch_async(mainQueue(), ^{
		[self reloadData]; });
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
	if ([self numberOfRowsInTableView:aTableView] <= requestedRow)	return [NSString stringWithFormat:@"%d",requestedRow];

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
		LogTableView* logTable = [[[self myDocument] theHistoryPaneController] logTableView];
		[logTable scrollToRevision:[label revision]];
	}
	[parentController labelsChanged];
}




@end
