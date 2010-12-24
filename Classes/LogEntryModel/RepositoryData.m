//
//  RepositoryData.m
//  MacHg
//
//  Created by Jason Harris on 12/10/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LogEntry.h"
#import "LogRecord.h"
#import "LogGraph.h"
#import "RepositoryData.h"
#import "Common.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "LabelData.h"
#import "FSNodeInfo.h"

@interface RepositoryData (PrivateAPI)
- (void) loadCombinedInformationAndNotify:(BOOL)initilizing;
- (BOOL) imediateLoadIncompleteRevisionInformation;
- (void) setEntry:(LogEntry*)entry;
- (void) resetEntriesAndLogGraph;
@end

@implementation RepositoryData

@synthesize rootPath   = rootPath_;
@synthesize myDocument = myDocument;
@synthesize includeIncompleteRevision = includeIncompleteRevision_;
@synthesize logGraph = logGraph_;
@synthesize oldLogGraph = oldLogGraph_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

// Designated initilizer for RepositoryData
- (id) initWithRootPath:(NSString*)rootPath andDocument:(MacHgDocument*)doc
{
	self = [super init];
	if (self)
	{
		// Main lookup tables
        revisionNumberToLogEntry_    = [[NSMutableDictionary alloc] init];
		oldRevisionNumberToLogEntry_ = [[NSMutableDictionary alloc] init];
		logGraph_    = [[LogGraph alloc] initWithRepositoryData:self];
		oldLogGraph_ = [[LogGraph alloc] initWithRepositoryData:self];
		rootPath_ = rootPath;
		myDocument = doc;
		
		// Parent, tip, labels, and incomplete entry
		parent1Revision_		 = nil;
		parent2Revision_		 = nil;
		parent1Changeset_		 = nil;
		parent2Changeset_		 = nil;
		tipRevision_			 = nil;
		tipChangeset_			 = nil;
		branchName_				 = nil;
		revisionNumberToLabels_  = nil;
		incompleteRevisionEntry_ = nil;

		hasMultipleOpenHeads_    = NO;
		includeIncompleteRevision_ = NO;
		[self loadCombinedInformationAndNotify:YES];
	}
    	
	[self observe:kUnderlyingRepositoryChanged	from:myDocument  byCalling:@selector(underlyingRepositoryDidChange)];
	return self;
}


- (void) underlyingRepositoryDidChange
{
	[self loadCombinedInformationAndNotify:NO];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Found Repository Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSNumber*)	  getHGParent1Revision		{ return parent1Revision_; }
- (NSNumber*)	  getHGParent2Revision		{ return parent2Revision_; }
- (NSString*)	  getHGParent1Changeset		{ return parent1Changeset_; }
- (NSString*)	  getHGParent2Changeset		{ return parent2Changeset_; }
- (NSString*)	  getHGBranchName			{ return branchName_; }
- (NSDictionary*) revisionNumberToLabels	{ return revisionNumberToLabels_; }
- (NSNumber*)	  getHGTipRevision			{ return tipRevision_; }
- (NSString*)	  getHGTipChangeset			{ return tipChangeset_; }
- (NSNumber*)	  incompleteRevision		{ return [incompleteRevisionEntry_ revision]; }
- (LogEntry*)	  incompleteRevisionEntry	{ return incompleteRevisionEntry_; }
- (NSNumber*)	  minimumParent				{ return (parent1Revision_ && parent2Revision_) ? intAsNumber(MIN(numberAsInt(parent1Revision_), numberAsInt(parent2Revision_))) : parent1Revision_; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Incomplete Revision Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) shouldChangeIncompleteRevisionInformation
{
	LogEntry* oldIncompleteRevisionEntry = incompleteRevisionEntry_;
	BOOL oldIncludeIncompleteRevision = includeIncompleteRevision_;
	BOOL newIncludeIncompleteRevision = [myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
	BOOL changedVisibility = (oldIncludeIncompleteRevision != newIncludeIncompleteRevision);
	
	if (!oldIncludeIncompleteRevision && !newIncludeIncompleteRevision)
		return NO;
	
	NSNumber* ip1 = [oldIncompleteRevisionEntry  firstParent];
	NSNumber* ip2 = [oldIncompleteRevisionEntry secondParent];
	NSNumber*  p1 = [self getHGParent1Revision];
	NSNumber*  p2 = [self getHGParent2Revision];
	BOOL parents1Differ = (p1 && !ip1) || (!p1 && ip1) || (p1 && ip1 && ![p1 isEqualToNumber:ip1]);
	BOOL parents2Differ = (p2 && !ip2) || (!p2 && ip2) || (p2 && ip2 && ![p2 isEqualToNumber:ip2]);
	BOOL changedParents = (parents1Differ || parents2Differ);
	
	return changedParents || changedVisibility;
}


- (void) adjustCollectionForIncompleteRevision
{
	if (!tipRevision_)
		return;
	@synchronized(self)
	{
		if (![self shouldChangeIncompleteRevisionInformation])
			return;
		[self resetEntriesAndLogGraph];
	}
	dispatch_async(mainQueue(), ^{
		[myDocument postNotificationWithName:kRepositoryDataDidChange];
		[myDocument postNotificationWithName:kLogEntriesDidChange];
	});
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Loading Information
// -----------------------------------------------------------------------------------------------------------------------------------------

static void addLabelToDictionary(NSMutableDictionary* revisionToLabelArray, LabelData* label)
{
	if (!label)
		return;

	NSNumber* rev = [label revision];
	if (!rev)
		return;

	NSMutableArray* labelArray = [revisionToLabelArray objectForKey:rev];
	if (!labelArray)
	{
		labelArray = [[NSMutableArray alloc]init];
		[revisionToLabelArray setObject:labelArray forKey:rev];
	}
	[labelArray addObject:label];
}


static BOOL labelArrayDictionariesAreEqual(NSDictionary* dict1, NSDictionary* dict2)
{
	return YES;
//	for (LabelData* label in [revisionNumberToLabels_ allValues])
//		if (![label isEqualToLabel:[newRevisionToLabels objectForKey:[label revision]]])
//			labelsChanged = YES;
//	for (LabelData* label in [newRevisionToLabels allValues])
//		if (![label isEqualToLabel:[revisionNumberToLabels_ objectForKey:[label revision]]])
//			labelsChanged = YES;	
}

// loadCombinedInformationAndNotify uses the combinedinfo extension (which I wrote) to generate information like the following
// which contains information on the tip, parents, local tags, global tags, bookmarks, active branches, inactive branches, closed
// branches, and open heads.
//
// A sample output of combinedinfo looks like:
//
//tip 23:43c7d1cb21f0b16b8273d2dd0b3f124e79e97c49
//parent1 23:43c7d1cb21f0b16b8273d2dd0b3f124e79e97c49
//globaltag 23:43c7d1cb21f0b16b8273d2dd0b3f124e79e97c49 tip
//bookmark 13:2483796d252574cc0adf8f49bafe30d82a73ac59 bookjas
//localtag 6:6f3d5bcfa00bfdfe06d1cf1f7bb418ae9a005f0c localcat
//activebranch 23:43c7d1cb21f0b16b8273d2dd0b3f124e79e97c49 branchClip
//activebranch 22:0ea9a6ad294b4f6d86ea7ea3c1c47da8ac271d3b default
//openhead 23:43c7d1cb21f0b16b8273d2dd0b3f124e79e97c49
//openhead 22:0ea9a6ad294b4f6d86ea7ea3c1c47da8ac271d3b
//openhead 19:f8283d02f3b5a8260dd8dcfdbb9cbc03b36e6c31
//openhead 13:2483796d252574cc0adf8f49bafe30d82a73ac59
//openhead 12:68dcbb25b2d11e5f6025aec65f29d52c0044185d

//
// Load all of the combined information to do with the repository and post notifications that RepositoryDataDidChange and
// LogEntriesDidChange
//
- (void) loadCombinedInformationAndNotify:(BOOL)initilizing
{
	dispatch_async(globalQueue(), ^{

		NSMutableDictionary* newRevisionToLabels = [[NSMutableDictionary alloc] init];
		
		NSNumber* oldParent1Revision  = parent1Revision_;
		NSString* oldParent1Changeset = parent1Changeset_;
		NSNumber* oldParent2Revision  = parent2Revision_;
		NSString* oldParent2Changeset = parent2Changeset_;
		NSNumber* oldTipRevision      = tipRevision_;
		NSString* oldTipChangeset     = tipChangeset_;
		NSNumber* newParent1Revision  = nil;
		NSString* newParent1Changeset = nil;
		NSNumber* newParent2Revision  = nil;
		NSString* newParent2Changeset = nil;
		NSNumber* newTipRevision      = nil;
		NSString* newTipChangeset     = nil;
		
		
		//
		// Load all of the new full label information
		//
		NSMutableArray* fullLabelArgs = [NSMutableArray arrayWithObjects:@"combinedinfo", nil];
		ExecutionResult* fullLabelResults = [TaskExecutions executeMercurialWithArgs:fullLabelArgs fromRoot: rootPath_ logging:eLoggingNone];
		NSString* rawfullLabel = trimString(fullLabelResults.outStr);
		NSArray* fullLabelLines = [rawfullLabel componentsSeparatedByString:@"\n"];
		NSInteger headCount = 0;
		for (NSString* line in fullLabelLines)
		{
			NSString* labelType = nil;
			NSString* revString = nil;
			NSString* changesetString = nil;			
			NSString* labelName = nil;
			BOOL parsedLine = [line getCapturesWithRegexAndTrimedComponents:@"^(\\w+) (\\d+):([\\d\\w]+)\\s*(.*)"
															 firstComponent:&labelType  secondComponent:&revString  thirdComponent:&changesetString  fourthComponent:&labelName];
			if (!parsedLine)
				continue;
			
			
			if ([labelType isEqualToString:@"tip"])
			{
				newTipRevision  = stringAsNumber(revString);
				newTipChangeset = [NSString stringWithString:changesetString];
				continue;
			}
			
			if ([labelType isEqualToString:@"parent1"])
			{
				newParent1Revision  = stringAsNumber(revString);
				newParent1Changeset = [NSString stringWithString:changesetString];
				continue;
			}
			
			if ([labelType isEqualToString:@"parent2"])
			{
				newParent2Revision  = stringAsNumber(revString);
				newParent2Changeset = [NSString stringWithString:changesetString];
				continue;
			}
			
			if		([labelType isEqualToString:@"bookmark"])		addLabelToDictionary(newRevisionToLabels, [LabelData labelWithName:labelName  andType:eBookmark		  revision:revString  changeset:changesetString]);
			else if ([labelType isEqualToString:@"localtag"])		addLabelToDictionary(newRevisionToLabels, [LabelData labelWithName:labelName  andType:eLocalTag		  revision:revString  changeset:changesetString]);
			else if ([labelType isEqualToString:@"globaltag"])		addLabelToDictionary(newRevisionToLabels, [LabelData labelWithName:labelName  andType:eGlobalTag	  revision:revString  changeset:changesetString]);
			else if ([labelType isEqualToString:@"activebranch"])	addLabelToDictionary(newRevisionToLabels, [LabelData labelWithName:labelName  andType:eActiveBranch	  revision:revString  changeset:changesetString]);
			else if ([labelType isEqualToString:@"closedbranch"])	addLabelToDictionary(newRevisionToLabels, [LabelData labelWithName:labelName  andType:eClosedBranch	  revision:revString  changeset:changesetString]);
			else if ([labelType isEqualToString:@"inactivebranch"])	addLabelToDictionary(newRevisionToLabels, [LabelData labelWithName:labelName  andType:eInactiveBranch revision:revString  changeset:changesetString]);
			else if ([labelType isEqualToString:@"openhead"])	  { addLabelToDictionary(newRevisionToLabels, [LabelData labelWithName:labelName  andType:eOpenHead		  revision:revString  changeset:changesetString]); headCount++; }
		}
		
		
		//
		// compute tipChanged, parentsChanged, labelsChanged
		//
		BOOL tipChanged     = !theSameNumbers(newTipRevision, oldTipRevision) || !theSameStrings(newTipChangeset,oldTipChangeset);
		BOOL parentsChanged = !theSameNumbers(newParent1Revision, oldParent1Revision)  || !theSameNumbers(newParent2Revision, oldParent2Revision) ||
							  !theSameStrings(newParent1Changeset,oldParent1Changeset) || !theSameStrings(newParent2Changeset,oldParent2Changeset);
		BOOL labelsChanged  = labelArrayDictionariesAreEqual(revisionNumberToLabels_, newRevisionToLabels);

		dispatch_async(mainQueue(), ^{
			BOOL incompleteRevisionChanged;
			@synchronized(self)
			{
				parent1Revision_  = newParent1Revision;
				parent1Changeset_ = newParent1Changeset;
				parent2Revision_  = newParent2Revision;
				parent2Changeset_ = newParent2Changeset;
				tipRevision_      = newTipRevision;
				tipChangeset_     = newTipChangeset;
				revisionNumberToLabels_ = newRevisionToLabels;
				hasMultipleOpenHeads_ = headCount > 1;
				
				incompleteRevisionChanged = [self shouldChangeIncompleteRevisionInformation];
				[self resetEntriesAndLogGraph];
			}
			
			DebugLog(@"loadCombinedInformationAndNotify");

			if (initilizing)
				[myDocument postNotificationWithName:kRepositoryDataIsNew];
			else if (tipChanged || parentsChanged || labelsChanged || incompleteRevisionChanged)
				[myDocument postNotificationWithName:kRepositoryDataDidChange];
			[myDocument postNotificationWithName:kLogEntriesDidChange];
		});
	});
}


// This moves all current entry and log graph information into the fall back caches.
- (void) resetEntriesAndLogGraph
{
	[oldRevisionNumberToLogEntry_ addEntriesFromDictionary:revisionNumberToLogEntry_];
	[revisionNumberToLogEntry_ removeAllObjects];
	oldLogGraph_ = logGraph_;
	logGraph_ = [[LogGraph alloc] initWithRepositoryData:self];
	includeIncompleteRevision_ = [myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
	incompleteRevisionEntry_   = includeIncompleteRevision_ ? [LogEntry unfinishedEntryForRevision:intAsNumber([self computeNumberOfRealRevisions] + 1) forRepositoryData:self] : nil;
	if (incompleteRevisionEntry_)
		[self setEntry:incompleteRevisionEntry_];	
}






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Derived Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)	  inMergeState						{ return [self getHGParent2Revision] != nil; }	// If we have a second parent we are merging
- (BOOL)      isCurrentRevisionTip				{ return [[self getHGParent1Revision] isEqualToNumber:[self getHGTipRevision]]; }
- (BOOL)	  revisionIsParent:(NSNumber*)rev	{ return rev && ([[self getHGParent2Revision] isEqualToNumber:rev] || [[self getHGParent1Revision] isEqualToNumber:rev]);}
- (NSInteger) computeNumberOfRealRevisions		{ return [[self getHGTipRevision] intValue]; }
- (NSInteger) computeNumberOfRevisions			{ return [[self getHGTipRevision] intValue] + (includeIncompleteRevision_ ? 1 : 0); }
- (BOOL)	  hasMultipleOpenHeads				{ return hasMultipleOpenHeads_; }


- (BOOL)      isRollbackInformationAvailable
{
	NSString* rollbackFile = fstr(@"%@/.hg/store/undo", rootPath_);	
	BOOL sourceIsDir = NO;
	return [[[NSFileManager alloc] init] fileExistsAtPath:rollbackFile isDirectory:&sourceIsDir];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Parent / Children handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSArray*) parentsOfRevision:(NSNumber*)rev
{
	LogEntry* entry = [self entryForRevision:rev];
	return [entry parentsOfEntry];
}
- (NSArray*) childrenOfRevision:(NSNumber*)rev
{
	LogEntry* entry = [self entryForRevision:rev];
	return [entry childrenOfEntry];
}


- (void) descendantsOfRevisionNumber_addDescendants:(NSArray*)children to:(NSMutableSet*)descendants
{
	for (NSNumber* childRevNum in children)
		if (![descendants containsObject:childRevNum])
		{
			[descendants addObject:childRevNum];
			[self descendantsOfRevisionNumber_addDescendants:[self childrenOfRevision:childRevNum] to:descendants];
		}
}

- (NSSet*) descendantsOfRevisionNumber:(NSNumber*)rev
{
	NSMutableSet* descendants = [[NSMutableSet alloc] init];
	[descendants addObject:rev];
	[self descendantsOfRevisionNumber_addDescendants:[self childrenOfRevision:rev] to:descendants];
	return descendants;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LogEntry backing
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setEntry:(LogEntry*)entry
{
	NSNumber* rev = [entry revision];
	if (!rev)
		return;
	
	@synchronized(revisionNumberToLogEntry_)
	{
		[revisionNumberToLogEntry_  setObject:entry forKey:rev];
		if ([entry parentsArray])
		{
			NSArray* entries = [NSMutableArray arrayWithObject:entry];
			[logGraph_ addEntries:entries];
			[oldLogGraph_ removeEntries:entries];
		}
	}
}
	

// Given a revision ensure that the parents and children are correctly linked in the revisionNumberToLogEntry_ table.
- (void) relinkParentsAndChildrenOf:(NSNumber*)revision
{
	LogEntry* entry = [revisionNumberToLogEntry_ objectForKey:revision];
	for (NSNumber* parentRevision in [entry parentsOfEntry])
	{
		LogEntry* parentEntry = [revisionNumberToLogEntry_ objectForKey:parentRevision];
		[parentEntry addChildRevisionNum:revision];
	}
	NSMutableArray* childrenToRemove = nil;
	for (NSNumber* childRevision in [entry childrenOfEntry])
	{
		LogEntry* childEntry = [revisionNumberToLogEntry_ objectForKey:childRevision];
		if (!childEntry || ![[childEntry parentsOfEntry] containsObject:revision])
		{
			if (!childrenToRemove)
				childrenToRemove = [NSMutableArray arrayWithObject:childRevision];
			else
				[childrenToRemove addObject:childRevision];
		}
	}
	for (NSNumber* childRevision in childrenToRemove)
		[entry removeChildRevisionNum:childRevision];	
}



// Given a set of entries check that we are loading or have the full log recrod for this entry and if not then load the full log
// record for this entry.
- (void) loadLogRecordsOfEntriesIfNecessary:(NSArray*)entries
{
	NSMutableIndexSet* revisionsToLoadLogRecord = [[NSMutableIndexSet alloc] init];

	for (LogEntry* entry in entries)
	{
		NSNumber* revision = [entry revision];
		
		BOOL needToLoadLogRecord = YES;
		NSString* changeset = [entry changeset];
		if (changeset)
		{
			LogRecord* logRecord = [changesetHashToLogRecord objectForKey:changeset];
			if ([logRecord detailsAreLoadingOrLoaded])
				needToLoadLogRecord = NO;
			if (!logRecord)
				logRecord = [LogRecord createPendingEntryForChangeset:changeset];	// Create dummy record where we are parsing
			[entry setFullRecord:logRecord];
		}
		if (needToLoadLogRecord)
			[revisionsToLoadLogRecord addIndex:numberAsInt(revision)];
	}
	if (IsNotEmpty(revisionsToLoadLogRecord))
		[LogRecord  fillDetailsOfLogRecordsFrom:[revisionsToLoadLogRecord firstIndex]  to:[revisionsToLoadLogRecord lastIndex]  forRepository:self];
	
}


// Add the given entries to this repository and post notifications if anything changed
- (void) setEntriesAndNotify:(NSArray*)entries
{
	if (IsEmpty(entries))
		return;
	
	[self loadLogRecordsOfEntriesIfNecessary:entries];

	dispatch_async(mainQueue(), ^{

		@synchronized(revisionNumberToLogEntry_)
		{
			//
			// Determine revisionsToReconnect
			//
			NSMutableSet* revisionsToReconnect = [[NSMutableSet alloc] init];
			for (LogEntry* entry in entries)
			{
				NSNumber* revision = [entry revision];
				
				LogEntry* oldEntry = [oldRevisionNumberToLogEntry_ objectForKey:revision];
				if ([oldEntry childrenArray]) [revisionsToReconnect addObjectsFromArray:[oldEntry childrenArray]];
				if ([oldEntry parentsArray])  [revisionsToReconnect addObjectsFromArray:[oldEntry parentsArray]];
				if ([entry parentsArray])	  [revisionsToReconnect addObjectsFromArray:[entry parentsArray]];
				[revisionsToReconnect addObject:revision];
				[revisionNumberToLogEntry_ setObject:entry forKey:revision];
			}

			
			// Relink all the revisionsToReconnect
			for (NSNumber* revision in revisionsToReconnect)
				[self relinkParentsAndChildrenOf:revision];
			
			
			//
			// Update the graph by adding all the newEntries
			//
			[logGraph_ addEntries:entries];
			[oldLogGraph_ removeEntries:entries];
		}

		[myDocument postNotificationWithName:kLogEntriesDidChange];
	});
}


// Fill this documents revisionNumberToLogEntry_ with data for the revisions from lowLimit to highLimit
- (void) fillTableFrom:(NSInteger)lowLimit to:(NSInteger)highLimit
{
	if (lowLimit < 0 || highLimit < 0)
		return;
	
	// Now we just fetch the entries from the high limit to the low limit.
	NSString* revLimits     = fstr(@"%d:%d", highLimit, lowLimit);
	DebugLog(@"filling revLimits : %@", revLimits);
	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", revLimits, @"--template", templateLogEntryString, nil];	// templateLogEntryString is global set in setupGlobalsForLogEntryPartsAndTemplate()
	dispatch_async(globalQueue(), ^{
		NSInteger minFoundEntry = NSNotFound;
		NSInteger maxFoundEntry = NSNotFound;
		ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:rootPath_  logging:eLoggingNone];
		NSArray* lines = [hgLogResults.outStr componentsSeparatedByString:logEntrySeparator];
		NSMutableArray* entries = [[NSMutableArray alloc] init];
		for (NSString* line in lines)
		{
			LogEntry* entry = [LogEntry fromLogEntryResultLine:line  forRepositoryData:self];
			if (entry)
			{
				minFoundEntry = (minFoundEntry != NSNotFound) ? MIN(minFoundEntry, [entry revisionInt]) : [entry revisionInt];
				maxFoundEntry = (maxFoundEntry != NSNotFound) ? MAX(maxFoundEntry, [entry revisionInt]) : [entry revisionInt];
				[entries addObject:entry];
			}
		}

		// Recover if we didn't get the entries we expected...
		if (minFoundEntry != lowLimit || maxFoundEntry != highLimit)
		{
			DebugLog(@"Loading dropped entries. Asked for %d..%d but recived %d..%d", lowLimit, highLimit, minFoundEntry, maxFoundEntry);
			if (minFoundEntry == NSNotFound || maxFoundEntry == NSNotFound)
			{
				for (NSInteger rev = lowLimit; rev <= highLimit; rev++)
					[revisionNumberToLogEntry_ synchronizedRemoveObjectForKey:intAsNumber(rev)];
				return;
			}
			if (lowLimit < minFoundEntry)
				for (NSInteger rev = lowLimit; rev <= minFoundEntry; rev++)
					[revisionNumberToLogEntry_ synchronizedRemoveObjectForKey:intAsNumber(rev)];
			if (maxFoundEntry < highLimit)
				for (NSInteger rev = maxFoundEntry; rev <= highLimit; rev++)
					[revisionNumberToLogEntry_ synchronizedRemoveObjectForKey:intAsNumber(rev)];
		}
		[self setEntriesAndNotify:entries];
	});
}


- (LogEntry*) entryForRevision:(NSNumber*)revision
{
	static int cacheLineCount = 100;
	
	// If we have the entry use it
	LogEntry* requestedLogEntry = [revisionNumberToLogEntry_ synchronizedObjectForKey:revision];
	if (requestedLogEntry)
		return requestedLogEntry;
	
	// We now read in some more lines. We do this since in log files with hundreds of thousands of lines we don't want to read
	// *everything* in at once.
	int requestedRow = [revision intValue];
	
	int lowLimit  = MAX(0, requestedRow - cacheLineCount);
	int highLimitOfNormal = [self computeNumberOfRealRevisions];
	int highLimit = MIN(highLimitOfNormal, requestedRow + cacheLineCount);
	
	if (requestedRow < lowLimit || requestedRow > highLimit)
		return (requestedLogEntry == incompleteRevisionEntry_) ? [self incompleteRevisionEntry] : nil;
	
	// We add pending LogEntries for all of the revisions we are about to read in. This means we don't redundantly try to
	// repeatedly do a fillTableFrom:to: If an entry is loading or is already fully loaded then we don't need to set it loading
	// again
	int count = requestedRow;
	while (--count >= lowLimit)
	{
		NSNumber* rev = intAsNumber(count);
		LogEntry* entry = [revisionNumberToLogEntry_ synchronizedObjectForKey:rev];
		if (!entry)
			[self setEntry:[LogEntry pendingLogEntryForRevision:rev forRepositoryData:self]];
		else
		{
			lowLimit = count;
			break;
		}
	}
		
	count = requestedRow;
	while (++count <= highLimit)
	{
		NSNumber* rev = intAsNumber(count);
		LogEntry* entry = [revisionNumberToLogEntry_ synchronizedObjectForKey:rev];
		if (!entry)
			[self setEntry:[LogEntry pendingLogEntryForRevision:rev forRepositoryData:self]];
		else
		{
			highLimit = count;
			break;
		}
	}
	
	[self fillTableFrom:lowLimit to:highLimit];		// Asynchronously start the loading of the entries from lowLimit to highLimit

	// Start a new entry which is loading, but if we have an old entry use that in the meantime
	LogEntry* newPendingEntry = [LogEntry pendingLogEntryForRevision:revision forRepositoryData:self];
	[self setEntry:newPendingEntry];
	LogEntry* oldRequestedLogEntry = [oldRevisionNumberToLogEntry_ synchronizedObjectForKey:revision];
	return (oldRequestedLogEntry && [oldRequestedLogEntry isLoaded]) ? oldRequestedLogEntry : newPendingEntry;
}


@end
