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
- (void) loadLabelsInformation;
- (void) loadBranchNameInformation;
- (void) loadTipInformation;
- (void) loadParentsOfCurrentRevisionInformation;
- (void) loadIncompleteRevisionInformation;
- (void) imediateSynchronizeTipInformation;
- (void) relayoutEntriesAbove:(NSNumber*)low;
- (void) setEntry:(LogEntry*)entry;
- (void) removeEntry:(LogEntry*)entry;
- (NSArray*) allEntriesFromLow:(NSInteger)low toHigh:(NSInteger)high;
@end

@implementation RepositoryData

@synthesize rootPath   = rootPath_;
@synthesize myDocument = myDocument;
@synthesize includeIncompleteRevision = includeIncompleteRevision_;
@synthesize logGraph = logGraph_;





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
        revisionNumberToLogEntry_ = [[NSMutableDictionary alloc] init];
		rootPath_ = rootPath;
		myDocument = doc;
		
		// Parent and tip info
		parent1Revision_		 = nil;
		parent2Revision_		 = nil;
		parent1Changeset_		 = nil;
		parent2Changeset_		 = nil;
		tipRevision_			 = nil;
		tipChangeset_			 = nil;
		branchName_				 = nil;
		revisionNumberToLabels_  = nil;

		// Tags & Branches
		labelsInfoLoadStatus_	 = eInformationStatusNotLoaded;
		branchNameLoadStatus_	 = eInformationStatusNotLoaded;
		tipLoadStatus_			 = eInformationStatusNotLoaded;
		parentsInfoLoadStatus_	 = eInformationStatusNotLoaded;
		incompleteRevLoadStatus_ = eInformationStatusNotLoaded;

		hasMultipleOpenHeads_    = NO;
		includeIncompleteRevision_ = NO;
		[self adjustCollectionForIncompleteRevisionAllowingNotification:NO];
		logGraph_ = [[LogGraph alloc] initWithRepositoryData:self];
	}
    
	[self observe:kUnderlyingRepositoryChanged	from:myDocument  byCalling:@selector(underlyingRepositoryDidChange)];
	return self;
}







// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Status adjusters
// -----------------------------------------------------------------------------------------------------------------------------------------

static void makeStatusStale(InformationLoadStatus* loadStatus)
{
	if (*loadStatus == eInformationStatusLoading)
		*loadStatus = eInformationStatusLoadingButAlreadyStale;
	else if (*loadStatus == eInformationStatusLoaded)
		*loadStatus = eInformationStatusStale;
}


// Given a load status like eInformationStatusLoading after we complete the load this status must be changed to
// eInformationStatusLoaded, etc.
static void adjustStatusForCompletedInformationLoad(InformationLoadStatus* loadStatus)
{	
	if (*loadStatus == eInformationStatusLoadingButAlreadyStale)
		*loadStatus = eInformationStatusStale;
	else if (*loadStatus ==  eInformationStatusLoading)
		*loadStatus = eInformationStatusLoaded;
	else
	{
		DebugLog(@"load status desyncronized had %d when expecting %d.", *loadStatus, eInformationStatusLoading);
		*loadStatus = eInformationStatusLoaded;
	}
}


- (BOOL) adjustStatusForSynchronizeInformation:(InformationLoadStatus*)loadStatus
{
	if (bitsInCommon(*loadStatus,  eInformationStatusLoadedOrLoading))
		return NO;
	@synchronized(self)
	{
		if (bitsInCommon(*loadStatus,  eInformationStatusLoadedOrLoading))
			return NO;
		*loadStatus = eInformationStatusLoading;
	}
	return YES;
}


- (void) underlyingRepositoryDidChange
{
	@synchronized(self)
	{
		makeStatusStale(&tipLoadStatus_);
		[self imediateSynchronizeTipInformation];

		makeStatusStale(&labelsInfoLoadStatus_);
		makeStatusStale(&branchNameLoadStatus_);
		makeStatusStale(&parentsInfoLoadStatus_);
		makeStatusStale(&incompleteRevLoadStatus_);
		for (LogEntry* entry in [revisionNumberToLogEntry_ allValues])
			[entry makeStatusStale];
	}
	[myDocument postNotificationWithName:kLogEntriesDidChange];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Synchronizers
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) synchronizeLabelsInformation
{
	if ([self adjustStatusForSynchronizeInformation:&labelsInfoLoadStatus_])
		dispatch_async(globalQueue(), ^{
			[self loadLabelsInformation];
		});
}

- (void) synchronizeBranchNameInformation
{
	if ([self adjustStatusForSynchronizeInformation:&branchNameLoadStatus_])	
		dispatch_async(globalQueue(), ^{
			[self loadBranchNameInformation];
		});
}

- (void) synchronizeParentsOfCurrentRevisionInformation
{
	if ([self adjustStatusForSynchronizeInformation:&parentsInfoLoadStatus_])		
		dispatch_async(globalQueue(), ^{
			[self loadParentsOfCurrentRevisionInformation];
		});
}



- (void) imediateSynchronizeTipInformation
{
	@synchronized(self)
	{
		if (bitsInCommon(tipLoadStatus_,  eInformationStatusLoadedOrLoading))
			return;
		tipLoadStatus_ = eInformationStatusLoading;
		[self loadTipInformation];
	}
}

- (void) imediateSynchronizeIncompleteRevisionInformation
{
	if (bitsInCommon(incompleteRevLoadStatus_,  eInformationStatusLoadedOrLoading))
		return;
	@synchronized(self)
	{
		if (bitsInCommon(incompleteRevLoadStatus_,  eInformationStatusLoadedOrLoading))
			return;
		incompleteRevLoadStatus_ = eInformationStatusLoading;
		[self loadIncompleteRevisionInformation];
	}
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Found Repository Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSNumber*)	  getHGParent1Revision		{ [self synchronizeParentsOfCurrentRevisionInformation];	return parent1Revision_; }
- (NSNumber*)	  getHGParent2Revision		{ [self synchronizeParentsOfCurrentRevisionInformation];	return parent2Revision_; }
- (NSString*)	  getHGParent1Changeset		{ [self synchronizeParentsOfCurrentRevisionInformation];	return parent1Changeset_; }
- (NSString*)	  getHGParent2Changeset		{ [self synchronizeParentsOfCurrentRevisionInformation];	return parent2Changeset_; }
- (NSString*)	  getHGBranchName			{ [self synchronizeBranchNameInformation];					return branchName_; }
- (NSDictionary*) revisionNumberToLabels	{ [self synchronizeLabelsInformation];						return revisionNumberToLabels_; }
- (NSNumber*)	  getHGTipRevision			{ [self imediateSynchronizeTipInformation];					return tipRevision_; }
- (NSString*)	  getHGTipChangeset			{ [self imediateSynchronizeTipInformation];					return tipChangeset_; }
- (NSNumber*)	  incompleteRevision		{ [self imediateSynchronizeIncompleteRevisionInformation];	return [incompleteRevisionEntry_ revision]; }
- (LogEntry*)	  incompleteRevisionEntry	{ [self imediateSynchronizeIncompleteRevisionInformation];	return incompleteRevisionEntry_; }





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


// In the future introduce a command "hg debuglabels --branches --tags --bookmarks --heads" which produces a table like:
//
//	T tip                              515:9f3227875212ae24d75b15f6c69977922a436c02
//	B default                          515:9f3227875212ae24d75b15f6c69977922a436c02
//	H                                  515:9f3227875212ae24d75b15f6c69977922a436c02
//	H                                  464:5e825d8db15f6b297e660fe76e0408a926571f27
//	T release0.9.9                     428:1f7d725dd7e5c851a74a3d1942e53dddca67efc4
//	T latestRelease                    428:1f7d725dd7e5c851a74a3d1942e53dddca67efc4
//	H                                  248:e94c038b0d4a36f026032ae60bd4660e434ece4a
//	L myLocalTag                       195:c0e38918cdd30c5170e5a66c5e41e10f2afc4932
//	M myBookmark                       155:53d449e329b2ae010e9afee079c911a3384e97db
//	T release0.9.4                     124:0bbec94296a77885b2007e78638c5296b8f0cc5d
//	T release0.9.3                     101:14c71c57ab6eba2c2bedeb06cf671b6d2d666757
//	T release0.9.2                      69:266d6d82366b0ada26c0d28c393e51e12bf0a47b
//	T release0.9.1                      36:7ed9b844dd67b45ec768599716f9f860320c78be
//	T release0.9.0                       7:72bf6b03f21482be1f3711d2ee0b04996b73fa8e
//
// Where T is Tag, B is branch, M is bookmark, H is open head, L is local tag
// For now do this seperatly.
//
- (void) loadLabelsInformation
{
	NSMutableDictionary* newRevisionToLabels = [[NSMutableDictionary alloc] init];
	
	// Load Bookmarks
	NSMutableArray* bookmarksArgs = [NSMutableArray arrayWithObjects:@"bookmarks", @"--verbose", nil];
	ExecutionResult* bookmarksResults = [TaskExecutions executeMercurialWithArgs:bookmarksArgs fromRoot: rootPath_ logging:eLoggingNone];
	NSString* rawBookmarks = trimString(bookmarksResults.outStr);
	NSArray* bookmarkLines = [rawBookmarks componentsSeparatedByString:@"\n"];
	for (NSString* line in bookmarkLines)
	{
		LabelData* label = [LabelData labelDataFromBookmarkResultLine:line];
		addLabelToDictionary(newRevisionToLabels, label);
	}

	
	// Load Tags
	NSMutableArray* tagsArgs = [NSMutableArray arrayWithObjects:@"tags", @"--verbose", nil];
	ExecutionResult* tagsResults = [TaskExecutions executeMercurialWithArgs:tagsArgs fromRoot: rootPath_ logging:eLoggingNone];
	NSString* rawTags = trimString(tagsResults.outStr);
	NSArray* tagLines = [rawTags componentsSeparatedByString:@"\n"];	
	for (NSString* line in tagLines)
	{
		LabelData* label = [LabelData labelDataFromTagResultLine:line];
		if (label)
		{
			NSNumber* rev = [label revision];
			NSMutableArray* labelArray = [newRevisionToLabels objectForKey:rev];
			if (!labelArray)
			{
				labelArray = [[NSMutableArray alloc]init];
				[newRevisionToLabels setObject:labelArray forKey:rev];
			}
			BOOL isReallyABookmark = NO;
			for (LabelData* l in labelArray)
				if ([l name] == [label name])
					isReallyABookmark = YES;
			if (!isReallyABookmark)
				[labelArray addObject:label];
		}
	}

	
	// Load Heads
	NSMutableArray* argsHeads = [NSMutableArray arrayWithObjects:@"heads", @"--active", @"--template", @"{rev}:{node|short} ", nil];
	ExecutionResult* headsResults = [TaskExecutions executeMercurialWithArgs:argsHeads fromRoot: rootPath_ logging:eLoggingNone];
	NSString* openHeadsStr = trimString(headsResults.outStr);
	
	NSArray* openHeads = [openHeadsStr componentsSeparatedByString:@" "];
	int headCount = 0;
	for (NSString* revChangesetString in openHeads)
	{
		LabelData* label = [LabelData labelDataFromOpenHeadsLine:revChangesetString];
		addLabelToDictionary(newRevisionToLabels, label);
		headCount++;
	}
	
	
	// Load Branches
	NSMutableArray* branchArgs = [NSMutableArray arrayWithObjects:@"branches", nil];
	ExecutionResult* branchResults = [TaskExecutions executeMercurialWithArgs:branchArgs fromRoot: rootPath_ logging:eLoggingNone];
	NSString* rawBranches = trimString(branchResults.outStr);
	NSArray* branchLines = [rawBranches componentsSeparatedByString:@"\n"];	
	for (NSString* line in branchLines)
	{
		LabelData* label = [LabelData labelDataFromBranchResultLine:line];
		addLabelToDictionary(newRevisionToLabels, label);
	}
	
	
	// set result
	dispatch_async(mainQueue(), ^{
		@synchronized(self)
		{
			revisionNumberToLabels_ = newRevisionToLabels;
			hasMultipleOpenHeads_ = headCount > 1;
			adjustStatusForCompletedInformationLoad(&labelsInfoLoadStatus_);
		}
		
		[myDocument postNotificationWithName:kRepositoryDataDidChange userInfo:[NSDictionary dictionaryWithObject:kRepositoryLabelsInfoChanged		forKey:kRepositoryDataChangeType]];
	});
}


- (void) loadBranchNameInformation
{
	NSMutableArray* argsBranch = [NSMutableArray arrayWithObjects:@"branch", nil];
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsBranch fromRoot:rootPath_];
	NSString* newBranchName = trimString(results.outStr);

	dispatch_async(mainQueue(), ^{
		BOOL branchNameChanged = NO;
		@synchronized(self)
		{
			branchNameChanged = (branchName_ != newBranchName);
			branchName_ = newBranchName;
			adjustStatusForCompletedInformationLoad(&branchNameLoadStatus_);
		}
		if (branchNameChanged)
			[myDocument postNotificationWithName:kRepositoryDataDidChange userInfo:[NSDictionary dictionaryWithObject:kRepositoryBranchNameChanged		forKey:kRepositoryDataChangeType]];
	});
}


- (void) loadTipInformation
{
	NSNumber* oldTipRevision = tipRevision_;

	NSMutableArray* argParents = [NSMutableArray arrayWithObjects:@"tip", @"--template", @"{rev}:{node} ", nil];
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argParents fromRoot:rootPath_];
	NSString* tip = trimString(results.outStr);
	
	NSString* revision1       = nil;
	NSString* changeset1      = nil;
	BOOL foundTip = [tip getCapturesWithRegexAndComponents:@"(\\d+):([\\d\\w]+)\\s*" firstComponent:&revision1 secondComponent:&changeset1];
	
	BOOL tipChanged = NO;
	@synchronized(self)
	{
		if (foundTip)
		{
			NSNumber* newTipRevision = stringAsNumber(revision1);
			NSString* newTipChangeset = changeset1;
			tipChanged = (newTipRevision != tipRevision_ || newTipChangeset != tipChangeset_);
			tipRevision_  = newTipRevision;
			tipChangeset_ = newTipChangeset;
		}
		adjustStatusForCompletedInformationLoad(&tipLoadStatus_);
	}
	
	// If the tip changed, get rid of any excess log entries and post the noticiation kRepositoryDataDidChange
	if (tipChanged)
	{
		if (oldTipRevision && tipRevision_ && [tipRevision_ compare:oldTipRevision] == NSOrderedAscending)
		{
			NSArray* entries = [self allEntriesFromLow:numberAsInt(tipRevision_) + 1 toHigh:numberAsInt(oldTipRevision)];
			for (LogEntry* entry in entries)
				[self removeEntry:entry];
		}
		[myDocument postNotificationWithName:kRepositoryDataDidChange userInfo:[NSDictionary dictionaryWithObject:kRepositoryTipChanged		forKey:kRepositoryDataChangeType]];
	}
}


- (void) loadParentsOfCurrentRevisionInformation
{
	NSMutableArray* argParents = [NSMutableArray arrayWithObjects:@"parents", @"--template", @"{rev}:{node} ", nil];
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argParents fromRoot:rootPath_];
	NSString* parents = trimString(results.outStr);
	
	NSString* revision1 = nil;
	NSString* revision2 = nil;
	NSString* changeset1 = nil;
	NSString* changeset2 = nil;
	BOOL oneParent  = NO;
	BOOL twoParents = [parents getCapturesWithRegexAndComponents:@"(\\d+):([\\d\\w]+)\\s*(\\d+):([\\d\\w]+)" firstComponent:&revision1 secondComponent:&changeset1 thirdComponent:&revision2 fourthComponent:&changeset2];
	if (!twoParents)
		oneParent = [parents getCapturesWithRegexAndComponents:@"(\\d+):([\\d\\w]+)\\s*" firstComponent:&revision1 secondComponent:&changeset1];

	dispatch_async(mainQueue(), ^{
		BOOL parentsOfCurrentRevisionChanged = NO;
		@synchronized(self)
		{
			if (oneParent || twoParents)
			{
				NSNumber* newParent1Revision = revision1 ? stringAsNumber(revision1) : nil;
				NSNumber* newParent2Revision = revision2 ? stringAsNumber(revision2) : nil;
				parentsOfCurrentRevisionChanged = (newParent1Revision != parent1Revision_ || newParent2Revision != parent2Revision_ || changeset1 != parent1Changeset_ || changeset2 != parent2Changeset_);
				parent1Revision_  = newParent1Revision;
				parent1Changeset_ = changeset1;
				parent2Revision_  = newParent2Revision;
				parent2Changeset_ = changeset2;
			}
			
			adjustStatusForCompletedInformationLoad(&parentsInfoLoadStatus_);
		}
		if (parentsOfCurrentRevisionChanged)
			[myDocument postNotificationWithName:kRepositoryDataDidChange userInfo:[NSDictionary dictionaryWithObject:kRepositoryParentsOfCurrentRevChanged		forKey:kRepositoryDataChangeType]];
	});
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Incomplete Revision Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) loadIncompleteRevisionInformation
{
	if (!includeIncompleteRevision_)
	{
		LogEntry* oldIncompleteRevisionEntry = incompleteRevisionEntry_;
		incompleteRevisionEntry_ = nil;
		if (oldIncompleteRevisionEntry)
		{
			[self removeEntry:oldIncompleteRevisionEntry];
			[self relayoutEntriesAbove:[oldIncompleteRevisionEntry minimumParent]];
		}
	}
	else
	{
		incompleteRevisionEntry_ = [LogEntry unfinishedEntryForRevision:intAsNumber([self computeNumberOfRealRevisions] + 1) forRepositoryData:self];
		[self setEntry:incompleteRevisionEntry_];
		LogEntry* newIncompleteRevisionEntry = incompleteRevisionEntry_;
		[self relayoutEntriesAbove:[newIncompleteRevisionEntry minimumParent]];
	}
	adjustStatusForCompletedInformationLoad(&incompleteRevLoadStatus_);
}


- (void) adjustCollectionForIncompleteRevisionAllowingNotification:(BOOL)allow
{
	BOOL postNotification = NO;
	NSNumber* minParent = nil;
	@synchronized(self)
	{
		LogEntry* oldIncompleteRevisionEntry = incompleteRevisionEntry_;
		minParent = [oldIncompleteRevisionEntry minimumParent];		
		
		BOOL oldIncludeIncompleteRevision = includeIncompleteRevision_;
		BOOL newIncludeIncompleteRevision = [myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
		if (![rootPath_ isEqualToString:[[myDocument rootNodeInfo] absolutePath]])
			return;
		
		[self removeEntry:oldIncompleteRevisionEntry];
		makeStatusStale(&incompleteRevLoadStatus_);
		if (oldIncludeIncompleteRevision != newIncludeIncompleteRevision)
		{
			includeIncompleteRevision_ = newIncludeIncompleteRevision;
			postNotification = YES;
		}
	}
	
	// If we had an incomplete revision then relayout entries below the
	if (minParent)
		[self relayoutEntriesAbove:minParent];
	
	if (allow && postNotification)
		dispatch_async(mainQueue(), ^{
			[myDocument postNotificationWithName:kRepositoryDataDidChange]; });
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
	
- (void) removeEntry:(LogEntry*)entry
{
	NSNumber* rev = [entry revision];
	if (!rev)
		return;
	
	@synchronized(revisionNumberToLogEntry_)
	{
		LogEntry* oldEntry = [revisionNumberToLogEntry_ objectForKey:rev];
		if (oldEntry == entry)
		{
			[logGraph_ removeEntries:[NSMutableArray arrayWithObject:oldEntry]];
			[revisionNumberToLogEntry_  removeObjectForKey:rev];
		}
	}
}

- (void) setEntry:(LogEntry*)entry
{
	NSNumber* rev = [entry revision];
	if (!rev)
		return;
	
	@synchronized(revisionNumberToLogEntry_)
	{
		LogEntry* oldEntry = [revisionNumberToLogEntry_ objectForKey:rev];
		if (oldEntry)
			[logGraph_ removeEntries:[NSMutableArray arrayWithObject:oldEntry]];
		[revisionNumberToLogEntry_  setObject:entry forKey:rev];
		[logGraph_ addEntries:[NSMutableArray arrayWithObject:entry]];
	}
}


- (NSArray*) allEntriesFromLow:(NSInteger)low toHigh:(NSInteger)high
{
	NSMutableArray* entries = [[NSMutableArray alloc] init];
	for (NSInteger rev = low; rev <= high ; rev++)
		[entries addObjectIfNonNil:[revisionNumberToLogEntry_ synchronizedObjectForKey:intAsNumber(rev)]];
	return entries;
}


- (void) relayoutEntriesAbove:(NSNumber*)low
{
	if (!low)
		return;
	NSArray* entries = [self allEntriesFromLow:numberAsInt(low) toHigh:[self computeNumberOfRevisions]];
	[logGraph_ removeEntries:entries];
	[logGraph_ addEntries:entries];
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


- (void) setEntriesAndNotify:(NSArray*)entries
{
	NSMutableArray* newEntries = [[NSMutableArray alloc] init];
	NSMutableArray* oldEntries = [[NSMutableArray alloc] init];
	
	NSMutableSet* revisionsToReconnect = [[NSMutableArray alloc] init];


	[self loadLogRecordsOfEntriesIfNecessary:entries];
	
	dispatch_async(mainQueue(), ^{

		BOOL foundNewEntry = NO;
		BOOL foundChangedEntry = NO;

		@synchronized(revisionNumberToLogEntry_)
		{			
			//
			// Determine oldEntries, newEntries, foundChangedEntry and foundNewEntry
			//
			for (LogEntry* entry in entries)
			{
				NSNumber* revision = [entry revision];
				
				LogEntry* oldEntry = [revisionNumberToLogEntry_ objectForKey:revision];
				if (!oldEntry)
					foundNewEntry = YES;
				else if (![oldEntry isEqualToEntry:entry])
					foundChangedEntry = YES;
				else
				{
					[oldEntry setLoadStatus:eLogEntryLoaded];
					continue;
				}
				
				if (oldEntry)
				{
					if ([oldEntry childrenArray])
						[revisionsToReconnect addObjectsFromArray:[oldEntry childrenArray]];
					if ([oldEntry parentsArray])
						[revisionsToReconnect addObjectsFromArray:[oldEntry parentsArray]];
					[oldEntries addObject:oldEntry];
				}
				if ([entry parentsArray])
					[revisionsToReconnect addObjectsFromArray:[entry parentsArray]];
				[revisionsToReconnect addObject:revision];
				[newEntries addObject:entry];
				[revisionNumberToLogEntry_ setObject:entry forKey:revision];
			}
			
			if (!foundChangedEntry && !foundNewEntry)
				return;

			
			// Relink all the revisionsToReconnect
			for (NSNumber* revision in revisionsToReconnect)
				[self relinkParentsAndChildrenOf:revision];
			
			
			//
			// Update the graph by removing all old entries and adding all of the new entries.
			//
			[logGraph_ removeEntries:oldEntries];
			[logGraph_ addEntries:newEntries];
		}

		if (foundChangedEntry || foundNewEntry)
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
	DebugLog(@"revLimits : %@", revLimits);
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
					[[revisionNumberToLogEntry_ synchronizedObjectForKey:intAsNumber(rev)] makeStatusStale];
				return;
			}
			if (lowLimit < minFoundEntry)
				for (NSInteger rev = lowLimit; rev <= minFoundEntry; rev++)
					[[revisionNumberToLogEntry_ synchronizedObjectForKey:intAsNumber(rev)] makeStatusStale];
			if (maxFoundEntry < highLimit)
				for (NSInteger rev = maxFoundEntry; rev <= highLimit; rev++)
					[[revisionNumberToLogEntry_ synchronizedObjectForKey:intAsNumber(rev)] makeStatusStale];
		}
		[self setEntriesAndNotify:entries];
	});
}


- (LogEntry*) entryForRevision:(NSNumber*)revision
{
	static int cacheLineCount = 100;
	
	// If we have the entry use it
	LogEntry* requestedLogEntry = [revisionNumberToLogEntry_ synchronizedObjectForKey:revision];
	if (requestedLogEntry && ([requestedLogEntry isLoaded] || [requestedLogEntry isLoading]))
		return requestedLogEntry;
	
	// We now read in some more lines. We do this since in log files with hundreds of thousands of lines we don't want to read
	// *everything* in at once.
	int requestedRow = [revision intValue];
	
	int lowLimit  = MAX(0, requestedRow - cacheLineCount);
	int highLimitOfNormal = [self computeNumberOfRealRevisions];
	int highLimit = MIN(highLimitOfNormal, requestedRow + cacheLineCount);
	
	if (requestedRow < lowLimit || requestedRow > highLimit)
		return nil;
	
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
		else if ([entry isStale] || [entry isLoadingButAlreadyStale])
			[entry setLoadStatus:eLogEntryLoading];
		else if ([entry isFullyLoaded] || [entry isLoading])
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
		else if ([entry isStale] || [entry isLoadingButAlreadyStale])
			[entry setLoadStatus:eLogEntryLoading];
		else if ([entry isFullyLoaded] || [entry isLoading])
		{
			highLimit = count;
			break;
		}
	}
	
	[self fillTableFrom:lowLimit to:highLimit];		// Asynchronously start the loading of the entries from lowLimit to highLimit

	// If our original entry was stale then we can just mark it as being loaded and return it.
	if (requestedLogEntry)
	{
		[requestedLogEntry setLoadStatus:eLogEntryLoading];
		return requestedLogEntry;
	}

	LogEntry* newPendingEntry = [LogEntry pendingLogEntryForRevision:revision forRepositoryData:self];
	[self setEntry:newPendingEntry];
	return newPendingEntry;
}


@end
