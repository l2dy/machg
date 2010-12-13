//
//  LogTableView.m
//  MacHg
//
//  Created by Jason Harris on 8/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LogTableView.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "MacHgDocument.h"
#import "RevertSheetController.h"
#import "UpdateSheetController.h"
#import "TaskExecutions.h"
#import "LogGraphCell.h"
#import "LogGraph.h"
#import "SingleTimedQueue.h"


#define MMAX(A,B)	(((A) > (B)) ? (A) : (B))
const NSInteger MaxNumberOfDetailedEntriesToShow = 10;
NSString* kKeyPathTagHighColor				= @"values.LogEntryTableTagHighlightColor";
NSString* kKeyPathParentHighColor			= @"values.LogEntryTableParentHighlightColor";
NSString* kKeyPathBranchHighColor			= @"values.LogEntryTableBranchHighlightColor";
NSString* kKeyPathBookmarkHighColor			= @"values.LogEntryTableBookmarkHighlightColor";
NSString* kKeyPathDisplayChangesetColumn	= @"values.LogEntryTableDisplayChangesetColumn";
NSString* kKeyPathRevisionSortOrder			= @"values.RevisionSortOrder";


@interface LogTableView (PrivateAPI)
- (LowHighPair) logGraphLimits;
- (void)		resortTable;
- (BOOL)		sortRevisionOrder;
- (void)		updateDetailedEntryTextView;
@end


@implementation LogTableView

@synthesize theSearchFilter		= theSearchFilter_;
@synthesize theTableRows		= theTableRows_;
@synthesize numberOfTableRows	= numberOfTableRows_;
@synthesize canSelectIncompleteRevision = canSelectIncompleteRevision_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	if (self)
	{
		theSearchFilter_ = nil;
		theTableRows_ = nil;
		repositoryData_ = nil;
		numberOfTableRows_ = 0;
		canSelectIncompleteRevision_ = NO;
		rootPath_ = nil;
		awake_ = NO;
	}
    
	return self;
}



- (void) awakeFromNib
{
	[self observe:kRepositoryDataIsNew		from:[self myDocument]  byCalling:@selector(repositoryDataIsNew)];
	[self observe:kRepositoryDataDidChange	from:[self myDocument]  byCalling:@selector(resetTable:)];
	[self observe:kLogEntriesDidChange		from:[self myDocument]  byCalling:@selector(logEntriesDidChange:)];
	queueForDetailedEntryDisplay_ = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue() withTimeDelay:0.10 descriptiveName:@"queueForDetailedEntryDisplay"];	// Our display of the detailed entry information will occur after 0.10 seconds

	// Bind the show / hide of the column to the preferences LogEntryTableDisplayChangesetColumn which is bound to a checkbox in the prefs.
	id defaults = [NSUserDefaultsController sharedUserDefaultsController];
	NSDictionary* negateValueTransformer = [NSDictionary dictionaryWithObject:NSNegateBooleanTransformerName forKey:@"NSValueTransformerName"];
	NSTableColumn* col = [self tableColumnWithIdentifier:@"changeset"];
	[col  bind:@"hidden"  toObject:defaults  withKeyPath:kKeyPathDisplayChangesetColumn  options:negateValueTransformer];
	
	// Receive a notification when the tag highlight color changes.
	[defaults  addObserver:self  forKeyPath:kKeyPathTagHighColor		options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathParentHighColor		options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathBranchHighColor		options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathBookmarkHighColor	options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathRevisionSortOrder	options:NSKeyValueObservingOptionNew  context:NULL];

	[self setDataSource:self];
	[self setDelegate:self];		// This table handles its own delegate methods
	awake_ = YES;
	[self resetTable:self];
}

- (void) unload
{
	[self stopObserving];
	theTableRows_ = nil;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Notifications
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) repositoryDataIsNew
{
	repositoryData_ = [[self myDocument] repositoryData];
	[self resetTable:self];
	NSString* newRepositoryRootPath = [repositoryData_ rootPath];
	if ([newRepositoryRootPath isNotEqualToString:rootPath_])
		[self scrollToCurrentRevision:self];
	rootPath_ = newRepositoryRootPath;	
}

- (void) logEntriesDidChange:(NSNotification*)notification
{
	[self refreshTable:self];
	[self updateDetailedEntryTextView];
}


- (void) observeValueForKeyPath:(NSString*)keyPath  ofObject:(id)object  change:(NSDictionary*)change  context:(void*)context
{
    if ([keyPath isEqualToString:kKeyPathTagHighColor] || [keyPath isEqualToString:kKeyPathParentHighColor] || [keyPath isEqualToString:kKeyPathBranchHighColor] || [keyPath isEqualToString:kKeyPathBookmarkHighColor])
		[self refreshTable:self];
	if ([keyPath isEqualToString:kKeyPathRevisionSortOrder])
		[self resortTable];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Internal Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

- (MacHgDocument*)		myDocument			{ return [parentController myDocument]; }
- (RepositoryData*)	repositoryData
{
	if (repositoryData_)
		return repositoryData_;
	repositoryData_ = [[parentController myDocument] repositoryData];
	return repositoryData_;
}



- (NSString*) revisionForTableRow:(NSInteger)rowNum
{
	@synchronized(self)
	{
		if (rowNum < 0 || rowNum >= [theTableRows_ count])
			return nil;
		return [theTableRows_ objectAtIndex:rowNum];
	}
	return nil;
}


- (LogEntry*) entryForTableRow:(NSInteger)rowNum
{
	NSString* revisionString = [self revisionForTableRow:rowNum];
	if (!revisionString)
		return nil;
	return [[self repositoryData] entryForRevision:stringAsNumber(revisionString)];
}

- (NSInteger) tableRowForIntegerRevision:(NSInteger)revInt  { return (revInt != NSNotFound) ? [self tableRowForRevision:intAsNumber(revInt)] : NSNotFound; }
- (NSInteger) tableRowForRevision:(NSNumber*)revision
{
	if (!revision)
		return NSNotFound;
	if (IsEmpty(theTableRows_))
		return NSNotFound;

	NSString* revisionStr = numberAsString(revision);
	if (IsEmpty(theSearchFilter_))
	{
		int tableRowCount = [theTableRows_ count];
		// We call this often and so we do an optimization where we look at the two most likely places first
		int revInt = numberAsInt(revision);
		if (tableRowCount <= revInt || [[theTableRows_ objectAtIndex:revInt] isEqualToString:revisionStr])
			return revInt;

		int oppInt = [theTableRows_ count] - revInt - 1;
		if (oppInt < 0 || [[theTableRows_ objectAtIndex:oppInt] isEqualToString:revisionStr])
			return oppInt;
	}

	return [theTableRows_ indexOfObject:revisionStr];
}


static inline BOOL between (int a, int b, int i) { return (a <= i && i <= b) || (a >= i && i >= b); }


// Return the closest table row to the given revision. It uses a bisection algorithm O(ln n) to zero in on the correct revision.
- (NSInteger) closestTableRowForRevision:(NSNumber*)revision
{
	if (!revision)
		return NSNotFound;
	if (IsEmpty(theTableRows_))
		return NSNotFound;

	int rval = numberAsInt(revision);
	int a = 0;
	int b = [theTableRows_ count] - 1;
	int aval = stringAsInt([theTableRows_ objectAtIndex:a]);
	int bval = stringAsInt([theTableRows_ objectAtIndex:b]);
	
	while (YES)
	{
		if (aval >= rval && bval >= rval)
			return aval < bval ? a : b;
		if (aval <= rval && bval <= rval)
			return aval > bval ? a : b;
		if (abs(a-b) <= 1)
			return (abs(aval - rval) <= abs(bval - rval)) ? a : b;

		int c = floor((a+b)/2);
		int cval = stringAsInt([theTableRows_ objectAtIndex:c]);

		if (between (aval, cval, rval))
		{
			b = c;
			bval = cval;
		}
		else if (between (bval, cval, rval))
		{
			a = c;
			aval = cval;
		}
		else
			return c;	// This shouldn't happen but in case things are screwy make sure we can break out of the loop.
	}
}


- (BOOL)	  includeIncompleteRevision	{ return [[self repositoryData] includeIncompleteRevision]; }
- (NSNumber*) incompleteRevision		{ return [[self repositoryData] incompleteRevision]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Test Selection
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)		noRevisionSelected			{ return [[self selectedRowIndexes] count] == 0; }
- (BOOL)		singleRevisionSelected		{ return [[self selectedRowIndexes] count] == 1; }
- (BOOL)		multipleRevisionsSelected	{ return [[self selectedRowIndexes] count] > 1; }





// -----------------------------------------------------------------------------------------------------------------------------------------
//   Chosen / Selected item(s)   -----------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (LogEntry*) chosenEntry		{ return [self entryForTableRow:[self chosenRow]]; }
- (LogEntry*) selectedEntry		{ return [self entryForTableRow:[self selectedRow]]; }
- (NSNumber*) chosenRevision	{ return [[self chosenEntry] revision]; }
- (NSNumber*) selectedRevision	{ return [[self selectedEntry] revision]; }

- (NSArray*) chosenEntries
{
	if (![self rowWasClicked] || [[self selectedRowIndexes] containsIndex:[self clickedRow]])
		return [self selectedEntries];
	return [NSArray arrayWithObject:[self chosenEntry]];
}
- (NSArray*) selectedEntries
{
	NSIndexSet* rows = [self selectedRowIndexes];
	NSMutableArray* entries = [[NSMutableArray alloc]init];
	for (NSInteger row = [rows firstIndex]; row != NSNotFound; row = [rows indexGreaterThanIndex: row])
		[entries addObject:[self entryForTableRow:row]];
	return entries;
}
- (NSArray*) chosenRevisions
{
	if (![self rowWasClicked] || [[self selectedRowIndexes] containsIndex:[self clickedRow]])
		return [self selectedRevisions];
	return [NSArray arrayWithObject:[self chosenRevision]];
}
- (NSArray*) selectedRevisions
{
	NSIndexSet* rows = [self selectedRowIndexes];
	NSMutableArray* revisions = [[NSMutableArray alloc]init];
	for (NSInteger row = [rows firstIndex]; row != NSNotFound; row = [rows indexGreaterThanIndex: row])
		[revisions addObjectIfNonNil:[[self entryForTableRow:row] revision]];
	return revisions;
}

- (LowHighPair) lowestToHighestSelectedRevisions
{
	NSIndexSet* rows = [self selectedRowIndexes];
	if (!rows || IsEmpty(rows))
		return MakeLowHighPair(NSNotFound, NSNotFound);
	
	NSInteger firstRev = stringAsInt([self revisionForTableRow:[rows firstIndex]]);
	NSInteger lastRev  = stringAsInt([self revisionForTableRow:[rows lastIndex]]);
	return MakeLowHighPair(MIN(firstRev, lastRev), MAX(firstRev, lastRev));
}

- (LowHighPair) parentToHighestSelectedRevisions
{
	NSIndexSet* rows = [self selectedRowIndexes];
	if (!rows || IsEmpty(rows))
		return MakeLowHighPair(NSNotFound, NSNotFound);
	
	NSString* firstRev    = [self revisionForTableRow:[rows firstIndex]];
	NSString* lastRev     = [self revisionForTableRow:[rows lastIndex]];
	NSInteger firstRevInt = stringAsInt(firstRev);
	NSInteger lastRevInt  = stringAsInt(lastRev);
	NSInteger lowRevInt   = MIN(firstRevInt, lastRevInt);
	NSInteger highRevInt  = MAX(firstRevInt, lastRevInt);
	NSString* lowRev      = (lowRevInt == firstRevInt) ? firstRev : lastRev;

	LogEntry* lowRevEntry = [[self repositoryData] entryForRevision:stringAsNumber(lowRev)];
	NSArray* parents = [lowRevEntry parentsOfEntry];
	NSInteger parentRevInt;
	if ([parents count] == 0)
		parentRevInt = MAX(0, lowRevInt - 1);	// Step back one to see the differences from the previous version to this version.
	else
		parentRevInt = numberAsInt([parents objectAtIndex:0]);
	return MakeLowHighPair(parentRevInt, highRevInt);	
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Scrolling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) scrollToRevision:(NSNumber*)revision	{ [self selectAndScrollToRevision:revision]; }
- (IBAction) scrollToBeginning:(id)sender		{ [self scrollToRevision:intAsNumber(0)]; }
- (IBAction) scrollToCurrentRevision:(id)sender	{ [self scrollToRevision:[[self repositoryData] getHGParent1Revision]]; }
- (IBAction) scrollToEnd:(id)sender				{ [self scrollToRevision:[[self repositoryData] getHGTipRevision]]; }
- (IBAction) scrollToSelected:(id)sender
{
	NSIndexSet* rows = [self selectedRowIndexes];
	dispatch_async(mainQueue(), ^{
		[self  scrollToRangeOfRowsLow:[rows firstIndex] high:[rows lastIndex]];
	});
}

- (void) selectAndScrollToRevision:(NSNumber*)revision
{
	NSInteger newRowToSelect = [self closestTableRowForRevision:revision];
	if (newRowToSelect != NSNotFound)
	{
		NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:newRowToSelect];
		[self selectAndScrollToIndexSet:indexSet];
	}
}

- (void) selectAndScrollToRevisions:(NSArray*)revisions
{
	NSMutableIndexSet* indexSet = [[NSMutableIndexSet alloc]init];

	for (NSNumber* rev in revisions)
	{
		NSInteger newRowToSelect = [self closestTableRowForRevision:rev];
		if (newRowToSelect != NSNotFound)
			[indexSet addIndex:newRowToSelect];
	}
	[self selectAndScrollToIndexSet:indexSet];
}

- (void) selectAndScrollToIndexSet:(NSIndexSet*)indexSet
{
	if (IsEmpty(indexSet))
		return;
	dispatch_async(mainQueue(), ^{
		[self  scrollToRangeOfRowsLow:[indexSet firstIndex] high:[indexSet lastIndex]];
		[self selectRowIndexes:indexSet byExtendingSelection:NO];
	});
}

- (void) scrollToRangeOfRevisions:(LowHighPair)limits
{
	NSInteger lowTableRow  = [self tableRowForIntegerRevision:limits.lowRevision];
	NSInteger highTableRow = [self tableRowForIntegerRevision:limits.highRevision];
	[self  scrollToRangeOfRowsLow:lowTableRow high:highTableRow];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
	return numberOfTableRows_;
}


- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)requestedRow
{
	LogEntry* requestedLogEntry = [self entryForTableRow:requestedRow];
	
	NSString* requestedColumn = [aTableColumn identifier];
	if ([requestedColumn isEqualToString:@"graph"])
		return [NSImage imageNamed:@"StatusAdded.png"];
	
	id requestedRowCol = [requestedLogEntry valueForKey:requestedColumn];
	if (requestedRowCol)
		return requestedRowCol;
	
	if ([requestedLogEntry isLoading] || [[requestedLogEntry fullRecord] isLoading])
		return grayedAttributedString(@"Loading");

	return @"missing";
}


- (void) tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	NSString* requestedColumn = [aTableColumn identifier];
	NSNumber* theRevision = stringAsNumber([self revisionForTableRow:rowIndex]);
	LogEntry* entry = [repositoryData_ entryForRevision:theRevision];
	[aCell setEntry:entry];
	[aCell setLogTableView:DynamicCast(LogTableView,aTableView)];
	[aCell setLogTableColumn:aTableColumn];
	if (numberAsInt(theRevision) == numberOfTableRows_ -1 && [[self repositoryData] includeIncompleteRevision])
	{
		if ([requestedColumn isEqualToString:@"graph"])
			return;

		if ([requestedColumn isEqualToString:@"revision"])
			[aCell setStringValue:@"-"];
		else
		{
			NSColor* grayColor = [NSColor grayColor];
			NSDictionary* newColorAttribute = [NSDictionary dictionaryWithObject:grayColor forKey:NSForegroundColorAttributeName];
			NSMutableAttributedString* str = [[NSMutableAttributedString alloc]init];
			[str initWithAttributedString:[aCell attributedStringValue]];
			[str addAttributes:newColorAttribute range:NSMakeRange(0, [str length])];
			[aCell setAttributedStringValue:str];			
		}
	}
}


- (void) queuedSetDetailedEntryTextView:(NSAttributedString*)fullEntry
{
	dispatch_async(mainQueue(), ^{
		[[detailedEntryTextView textStorage] setAttributedString:fullEntry];
	});
}

- (void) updateDetailedEntryTextView
{
	if (!detailedEntryTextView)
		return;
	
	if ([self noRevisionSelected])
	{
		[self queuedSetDetailedEntryTextView:grayedAttributedString(@"No Selection")];
		return;
	}
	
	if ([self singleRevisionSelected])
	{
		LogEntry* entry = [self selectedEntry];
		if (!entry)
		{
			[self queuedSetDetailedEntryTextView:grayedAttributedString(@"No Selection")];
			return;
		}
		if (![entry isFullyLoaded])
			[queueForDetailedEntryDisplay_ addBlockOperation:^{[entry fullyLoadEntry];}];

		[self queuedSetDetailedEntryTextView:[entry formattedVerboseEntry]];
		return;
	}
	
	if ([self multipleRevisionsSelected])
	{
		NSIndexSet* rows = [self selectedRowIndexes];

		if ([rows count] <= MaxNumberOfDetailedEntriesToShow)
		{
			NSArray* entries = [self selectedEntries];
			NSMutableAttributedString* combinedString = [[NSMutableAttributedString alloc] init];
			for (LogEntry* entry in entries)
			{
				NSAttributedString* briefEntry = [entry formattedBriefEntry];
				if (briefEntry)
					[combinedString appendAttributedString:briefEntry];
			}
			if (combinedString)
			{
				[self queuedSetDetailedEntryTextView:combinedString];
				return;
			}
		}

		// If we have more than MaxNumberOfDetailedEntriesToShow things selected or something went wrong then we don't try and
		// give the details of each entry.
		LowHighPair lowHigh = [self lowestToHighestSelectedRevisions];
		NSString* descriptiveString = fstr(@"Multiple Selection: %d revisions in range %d to %d", [rows count], lowHigh.lowRevision, lowHigh.highRevision);
		[self queuedSetDetailedEntryTextView:grayedAttributedString(descriptiveString)];
		return;
	}
}	
		
- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
{
	[self updateDetailedEntryTextView];
	if ([parentController respondsToSelector:@selector(logTableViewSelectionDidChange:)])
		[parentController logTableViewSelectionDidChange:self];
}


// if a parent controller want's to control the allowed indexes then let it.
- (NSIndexSet*) tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes
{
	if ([parentController respondsToSelector:@selector(tableView:selectionIndexesForProposedSelection:)])
		return [parentController tableView:tableView selectionIndexesForProposedSelection:proposedSelectionIndexes];
	return proposedSelectionIndexes;
}


// override what we can select to ensure if canSelectIncompleteRevision_ is false then we can't select the incomplete revision.
- (void) selectRowIndexes:(NSIndexSet*)indexes byExtendingSelection:(BOOL)extend
{
	if (!canSelectIncompleteRevision_ && [indexes containsIndex:[self tableRowForRevision:[self incompleteRevision]]])
	{
		NSMutableIndexSet* newIndexes = [[NSMutableIndexSet alloc]init];
		[newIndexes addIndexes:indexes];
		[newIndexes removeIndex:[self tableRowForRevision:[self incompleteRevision]]];
		if ([newIndexes count] == 0)
			return;
		dispatch_async(mainQueue(), ^{
			[super selectRowIndexes:newIndexes byExtendingSelection:extend]; });
		return;
	}
	dispatch_async(mainQueue(), ^{
		[super selectRowIndexes:indexes byExtendingSelection:extend]; });
}

- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn*)tableColumn
{
	if (tableColumn && [[tableColumn identifier] isEqualToString:@"revision"])
	{
		RevisionSortOrderOption newOrder = [self sortRevisionOrder] ? eSortRevisionsDescending : eSortRevisionsAscending; 
		[[NSUserDefaults standardUserDefaults] setInteger:newOrder forKey:MHGRevisionSortOrder];
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Sorting
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) sortRevisionOrder	{ return RevisionSortOrderFromDefaults() == eSortRevisionsAscending; }

- (NSArray*) sortTableRowsAccordingToSortOrder:(NSArray*)newTableRows
{
	ComparitorFunction func = [self sortRevisionOrder] ? sortIntsAscending : sortIntsDescending;
	return [NSMutableArray arrayWithArray:[newTableRows sortedArrayUsingFunction:func context:NULL]];
}

- (void) setSortDescriptorsAccordingToDefaults
{
	NSSortDescriptor* descriptor = [NSSortDescriptor sortDescriptorWithKey:@"revision" ascending:[self sortRevisionOrder] comparator:^(id obj1, id obj2) {
		if ([obj1 integerValue] > [obj2 integerValue])	return (NSComparisonResult)NSOrderedDescending;
		if ([obj1 integerValue] < [obj2 integerValue])	return (NSComparisonResult)NSOrderedAscending;
		return (NSComparisonResult)NSOrderedSame;}];
	[self setSortDescriptors:[NSArray arrayWithObject:descriptor]];
}

- (void) resortTable
{
	NSArray* selectedRevisions = [self selectedRevisions];
	[self setSortDescriptorsAccordingToDefaults];
	theTableRows_ = [self sortTableRowsAccordingToSortOrder:theTableRows_];
	[self selectAndScrollToRevisions:selectedRevisions];
	[self reloadData];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Log Graph Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

// Find the range of visible table rows plus some spillover
- (LowHighPair) logGraphLimits
{
	const int spillOverGraph = 10;
	NSRect clippedView = [[self enclosingScrollView] documentVisibleRect];
	NSRange theRange = [self rowsInRect: clippedView];
	
	// From the table rows find the low and high revisions
	NSString* r1 = [self revisionForTableRow:MAX(theRange.location, 0)];
	NSString* r2 = [self revisionForTableRow:MIN(theRange.location + theRange.length, [theTableRows_ count] -1)];
	int i1 = stringAsInt(r1);
	int i2 = stringAsInt(r2);
	int ilow    = MIN(i1,i2);
	int ihigh   = MAX(i1,i2);
	
	// include the spill over and constrain
	int lowRevision  = MAX(ilow  - spillOverGraph, 0);
	int highRevision = MIN(ihigh + spillOverGraph, [[self repositoryData] computeNumberOfRevisions]);
	return MakeLowHighPair(lowRevision, highRevision);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Backing updating
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) refreshTable:(id)sender
{
	if (!awake_)
		return;
	[self reloadData];
}


- (IBAction) resetTable:(id)sender
{
	if (!awake_)
		return;
	@synchronized(self)
	{
		RepositoryData* repositoryData = [self repositoryData];
		NSNumber* currentRevision     = [repositoryData getHGParent1Revision];
		NSArray* theSelectedRevisions = [self selectedRevisions];
		if (IsEmpty(theSelectedRevisions) && currentRevision)
			theSelectedRevisions = [NSArray arrayWithObject:currentRevision];

		NSMutableArray* newTableRows = [[NSMutableArray alloc] init];

		BOOL filtered = IsNotEmpty(theSearchFilter_);

		if (filtered)
		{
			NSString* rootPath      = [repositoryData rootPath];
			NSString* revLimits     = fstr(@"%d:%d", 0, [repositoryData computeNumberOfRealRevisions]);
			NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log",  @"--rev", revLimits, @"--template", @"{rev}\n", @"--keyword", theSearchFilter_, nil];
			ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:rootPath  logging:eLoggingNone];
			
			NSArray* revisions = [hgLogResults.outStr componentsSeparatedByString:@"\n"];
			for (NSString* revision in revisions)
				if (IsNotEmpty(revision))
					[newTableRows addObject:revision];
		}
		else
		{
			int numberOfRevisions	= [repositoryData computeNumberOfRevisions];
			for (int tableRow = 0; tableRow < numberOfRevisions + 1; tableRow++)  // We go from 0 to numberOfRevisions so need +1 here.
				[newTableRows addObject:intAsString(tableRow)];
		}

		[self setSortDescriptorsAccordingToDefaults];
		theTableRows_ = [self sortTableRowsAccordingToSortOrder:newTableRows];
		[self setNumberOfTableRows:[theTableRows_ count]];

		[self refreshTable:sender];		
		[self selectAndScrollToRevisions:theSelectedRevisions];
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Drawing Overrides
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSColor*) specialBackingColorForRow:(NSInteger)rowIndex
{
	RepositoryData* repositoryData = [self repositoryData];
	LogEntry* entry = [self entryForTableRow:rowIndex];
	
	if (!entry || !repositoryData)
		return nil;

	NSColor* backColor = nil;
	if ([repositoryData revisionIsParent:[entry revision]])
		backColor = LogEntryTableParentHighlightColor();
//	else if (IsNotEmpty([entry branch]))
//		backColor = LogEntryTableBranchHighlightColor();
//	else if (IsNotEmpty([entry bookmarks]))
//		backColor = LogEntryTableBookmarkHighlightColor();
//	else if (IsNotEmpty([entry tags]))
//		backColor = LogEntryTableTagHighlightColor();
	
	// If we have no special backing return nil and let callers call their super class and get normal highlighting.
	if (!backColor)
		return [[self selectedRowIndexes] containsIndex:rowIndex] ? [[NSColor selectedTextBackgroundColor] blendedColorWithFraction:0.3 ofColor:[NSColor blackColor]] : nil;
	
	// If we don't have a selected row then draw then draw the backing like normal.
	if (![[self selectedRowIndexes] containsIndex:rowIndex])
		return backColor;
	
	// Finally if we have a selected row and it's tagged or the current revision then blend the colors to indicate this.
	NSColor* theHighlightColor = [NSColor selectedTextColor];
	return backColor ? [backColor blendedColorWithFraction:0.3 ofColor:theHighlightColor] : theHighlightColor;
}

- (void) drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
	NSColor* backColor = [self specialBackingColorForRow:rowIndex];
	if (backColor)
	{
		NSRect bounds = [self rectOfRow:rowIndex];
		[backColor set];
		[NSBezierPath fillRect:bounds];
	}
	[super drawRow:rowIndex clipRect:clipRect];
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LogTableTextFieldCell
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation LogTableTextFieldCell

@synthesize entry		   = entry_;
@synthesize logTableView   = logTableView_;
@synthesize logTableColumn = logTableColumn_;


- (NSColor*) highlightColorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	LogTableView* theLogTableView = (LogTableView*)controlView;
	int rowIndex = [theLogTableView tableRowForRevision:[entry_ revision]];
	NSColor* backColor =[theLogTableView specialBackingColorForRow:rowIndex];
	return backColor ? backColor : [super highlightColorWithFrame:cellFrame inView:controlView];
}

// Expansion tool tip support
- (NSRect) expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSAttributedString* message = [self attributedStringValue];
	if (IsEmpty(message))
		return NSZeroRect;
	
	if ([[[self logTableColumn] identifier] isEqualToString:@"shortComment"])
	{
		RepositoryData* repositoryData = [[self logTableView] repositoryData];
		LogEntry* logEntry = [repositoryData entryForRevision:[entry_ revision]];
		NSString* fullMessageText = [logEntry fullComment];
		if (IsEmpty(fullMessageText))
			return NSZeroRect;
		NSDictionary* attributes = [message attributesOfWholeString];
		message = [NSAttributedString string:fullMessageText withAttributes:attributes];
	}
	NSSize messageSize = [message size];
	
	// If we don't need the expansionFrame then return the zero rect to signal this.
	if (messageSize.width <= cellFrame.size.width && messageSize.height <= cellFrame.size.height)
		return NSZeroRect;
	
	cellFrame = UnionSize(cellFrame, [message size]);
	
	// We want to make the cell *slightly* larger; it looks better when showing the expansion tool tip.
	cellFrame.size.width += 4.0;
	cellFrame.origin.x   -= 2.0;
    return cellFrame;
}

- (void) drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSAttributedString* message = [self attributedStringValue];
	if (IsEmpty(message))
		return;
	
	if ([[[self logTableColumn] identifier] isEqualToString:@"shortComment"])
	{
		RepositoryData* repositoryData = [[self logTableView] repositoryData];
		LogEntry* logEntry = [repositoryData entryForRevision:[entry_ revision]];
		NSString* fullMessageText = [logEntry fullComment];
		if (IsEmpty(fullMessageText))
			return;
		NSDictionary* attributes = [message attributesOfWholeString];
		message = [NSAttributedString string:fullMessageText withAttributes:attributes];
	}
	
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
// MARK: LogTableTextView
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation LogTableTextView

- (NSString*) getTextWithStringizedAttachments
{
	NSAttributedString* selectedText = [[self textStorage] attributedSubstringFromRange:[self selectedRange]];
	if (![selectedText containsAttachments])
		return [selectedText string];
	
	// embedd known attachments
	NSMutableAttributedString* stringToEncode = [selectedText mutableCopy];

	for (NSRange strRange = NSMakeRange(0, [stringToEncode length]); strRange.length > 0; )
	{
		NSRange effectiveRange;
		id attr = [stringToEncode attribute:NSAttachmentAttributeName atIndex:strRange.length - 1 effectiveRange:&effectiveRange];
		
		//if we find a text attachment, check to see if it's one of ours
		if (attr)
		{
			id attachmentCell = [(NSTextAttachment *)attr attachmentCell];
			if ([attachmentCell isKindOfClass:[NSButtonCell class]])
			{
				[stringToEncode removeAttribute:NSAttachmentAttributeName range:effectiveRange];
				[stringToEncode replaceCharactersInRange:effectiveRange withString:[attachmentCell title]];
			}
		}
		
		strRange.length = effectiveRange.location;
	}
		
	return [stringToEncode string];
}

- (NSArray*) writablePasteboardTypes
{
	return [NSArray arrayWithObject:NSStringPboardType];
}

- (BOOL) writeSelectionToPasteboard:(NSPasteboard*)pboard type:(NSString*)type
{
	if (![type isEqualToString:NSStringPboardType])
		return NO;

    return [pboard setString:[self getTextWithStringizedAttachments] forType:NSStringPboardType];
}

@end

