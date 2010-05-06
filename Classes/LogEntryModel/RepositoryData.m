//
//  RepositoryData.m
//  MacHg
//
//  Created by Jason Harris on 12/10/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LogEntry.h"
#import "RepositoryData.h"
#import "Common.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "LabelData.h"
#import "FSNodeInfo.h"

@implementation RepositoryData

@synthesize rootPath   = rootPath_;
@synthesize myDocument = myDocument;
@synthesize parentsCollection = parentsCollection_;
@synthesize childrenCollection = childrenCollection_;
@synthesize includeIncompleteRevision = includeIncompleteRevision_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) initWithRootPath:(NSString*)rootPath andDocument:(MacHgDocument*)doc
{
	self = [super init];
	if (self)
	{
        revisionStringToLogEntry_ = [[NSMutableDictionary alloc] init];
		parentsCollection_  = [[NSMutableDictionary alloc] init];
		childrenCollection_ = [[NSMutableDictionary alloc] init];
		rootPath_ = rootPath;
		myDocument = doc;
		
		// Parent and tip info
		parent_ = nil;
		parents_ = nil;
		parent1Revision_ = nil;
		parent2Revision_ = nil;
		parentsRevisions_ = nil;
		parentChangeset_ = nil;
		parentsChangesets_ = nil;
		tip_ = nil;
		tipRevision_ = nil;
		tipChangeset_ = nil;
		branchName_ = nil;
		heads_ = nil;

		// Tags & Branches
		tagToLabelDictionary_ = nil;
		bookmarkToLabelDictionary_ = nil;
		branchToLabelDictionary_ = nil;
		revisionToLabels_ = nil;
		updatingTags_ = NO;
		updatingBranches_ = NO;
		updatingBookmarks_ = NO;
		updatingOpenHeads_ = NO;
		
		inMergeState_ = nil;
		hasMultipleOpenHeads_ = nil;
		repositoryRevision_ = nil;
		incompleteRevisionEntry_ = [LogEntry unfinishedEntryForRevision:intAsString([self computeNumberOfRealRevisions] + 1) forRepositoryData:self];
		[self setEntry:incompleteRevisionEntry_];
		includeIncompleteRevision_ = NO;
		[self adjustCollectionForIncompleteRevisionAllowingNotification:NO];
	}
    
	return self;
}


- (void) adjustCollectionForIncompleteRevisionAllowingNotification:(BOOL)allow
{
	BOOL postNotification = NO;
	@synchronized(self)
	{
		BOOL oldIncludeIncompleteRevision = includeIncompleteRevision_;
		BOOL newIncludeIncompleteRevision = [myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
		if (![rootPath_ isEqualToString:[[myDocument rootNodeInfo] absolutePath]])
			return;
		if (oldIncludeIncompleteRevision != newIncludeIncompleteRevision)
		{
			includeIncompleteRevision_ = newIncludeIncompleteRevision;
			[self fleshOutParentsAndChildren:incompleteRevisionEntry_ addRelationShips:includeIncompleteRevision_];
			postNotification = YES;
		}
	}
	
	if (allow && postNotification)
		dispatch_async(mainQueue(), ^{
			[myDocument postNotificationWithName:kRepositoryDataDidChange]; });
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Parent Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) getHGParent
{
	if (!parent_)
		parent_ = trimString([[self getHGParents] stringByMatching:@"(\\d+:[\\d\\w]+)\\s*" capture:1L]);
	return parent_;
}

- (NSString*) getHGParents
{
	if (parents_)
		return parents_;
	@synchronized(self)
	{
		if (!parents_)
		{
			NSMutableArray* argParents = [NSMutableArray arrayWithObjects:@"parents", @"--template", @"{rev}:{node|short} ", nil];
			ExecutionResult results = [TaskExecutions executeMercurialWithArgs:argParents fromRoot:rootPath_];
			parents_ = trimString(results.outStr);
		}
	}
	return parents_;
}


- (NSString*) getHGParentsChangeset
{
	if (!parentChangeset_)
		parentChangeset_ = trimString([[self getHGParents] stringByMatching:@"\\d+:([\\d\\w]+)\\s*" capture:1L]);
	return parentChangeset_;
}

- (NSString*) getHGParentsChangesets
{
	if (!parentsChangesets_)
	{
		NSString* changeset1 = nil;
		NSString* changeset2 = nil;
		if ([[self getHGParents] getCapturesWithRegexAndComponents:@"\\d+:([\\d\\w]+)\\s*\\d+:([\\d\\w]+)" firstComponent:&changeset1 secondComponent:&changeset2])
			parentsChangesets_ = [NSString stringWithFormat:@"%@ %@", changeset1, changeset2];
		else
			parentsChangesets_ = [self getHGParentsChangeset];
	}
	return parentsChangesets_;
}

- (NSString*) getHGParent1Revision
{
	if (!parent1Revision_)
		parent1Revision_ = trimString([[self getHGParents] stringByMatching:@"(\\d+):[\\d\\w]+\\s*" capture:1L]);
	return parent1Revision_;
}

- (NSString*) getHGParent2Revision
{
	if (!parent2Revision_)
	{
		parent2Revision_ = trimString([[self getHGParents] stringByMatching:@"(\\d+):[\\d\\w]+\\s*(\\d+):[\\d\\w]+" capture:2L]);
		if (!parent2Revision_)
			parent2Revision_ = @"";
	}
	return IsNotEmpty(parent2Revision_) ? parent2Revision_ : nil;
}

- (NSString*) getHGParentsRevisions
{
	if (!parentsRevisions_)
	{
		NSString* revision1 = nil;
		NSString* revision2 = nil;
		if ([[self getHGParents] getCapturesWithRegexAndComponents:@"(\\d+):[\\d\\w]+\\s*(\\d+):[\\d\\w]+" firstComponent:&revision1 secondComponent:&revision2])
			parentsRevisions_ = [NSString stringWithFormat:@"%@ %@", revision1, revision2];
		else
			parentsRevisions_ = [self getHGParent1Revision];
	}
	return parentsRevisions_;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Tip Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) getHGTip
{
	if (tip_)
		return tip_;
	@synchronized(self)
	{
		if (!tip_)
		{
			NSMutableArray* argsTip = [NSMutableArray arrayWithObjects:@"tip", @"--template", @"{rev}:{node|short}", nil];
			ExecutionResult results = [TaskExecutions executeMercurialWithArgs:argsTip fromRoot:rootPath_];
			tip_ = results.outStr;
		}
	}
	return tip_;
}

- (NSString*) getHGTipRevision
{
	if (!tipRevision_)
		tipRevision_ = trimString([[self getHGTip] stringByMatching:@"(\\d+):[\\d\\w]+\\s*" capture:1L]);
	return tipRevision_;
}

- (NSString*) getHGTipChangeset
{
	if (!tipChangeset_)
		tipChangeset_ = trimString([[self getHGTip] stringByMatching:@"\\d+:([\\d\\w]+)\\s*" capture:1L]);
	return tipChangeset_;
}

- (NSString*) getHGBranchName
{
	if (branchName_)
		return branchName_;
	@synchronized(self)
	{
		if (!branchName_)
		{
			NSMutableArray* argsBranch = [NSMutableArray arrayWithObjects:@"branch", nil];
			ExecutionResult results = [TaskExecutions executeMercurialWithArgs:argsBranch fromRoot:rootPath_];
			branchName_ = trimString(results.outStr);
		}
	}
	return branchName_;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Heads Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) getHGHeads
{
	if (heads_)
		return heads_;
	@synchronized(self)
	{
		if (!heads_)
		{
			NSMutableArray* argsHeads = [NSMutableArray arrayWithObjects:@"heads", @"--active", @"--template", @"{rev}:{node|short} ", nil];
			ExecutionResult results = [TaskExecutions executeMercurialWithArgs:argsHeads fromRoot: rootPath_ logging:eLoggingNone];
			heads_ = trimString(results.outStr);
		}
	}
	return heads_;
}

- (NSString*) getHGHeadsChangesets
{
	if (!headsChangesets_)
	{
		NSArray* heads = [[self getHGHeads] componentsSeparatedByString:@" "];
		NSMutableArray* headsChangesets = [[NSMutableArray alloc] init];
		for (NSString* head in heads)
		{
			NSString* changeset = trimString([head stringByMatching:@"(\\d+):[\\d\\w]+\\s*" capture:1L]);
			[headsChangesets addObject:changeset];
		}
		headsChangesets_ = [headsChangesets componentsJoinedByString:@" "];
	}
	return headsChangesets_;
}

- (NSString*) getHGHeadsRevisions
{
	if (!headsRevisions_)
	{
		NSArray* heads = [[self getHGHeads] componentsSeparatedByString:@" "];
		NSMutableArray* headsRevisions = [[NSMutableArray alloc] init];
		for (NSString* head in heads)
		{
			NSString* revisionStr = trimString([head stringByMatching:@"(\\d+):[\\d\\w]+\\s*" capture:1L]);
			[headsRevisions addObject:revisionStr];
		}
		headsRevisions_ = [headsRevisions componentsJoinedByString:@" "];
	}
	return headsRevisions_;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Tag & Branch Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) updateTagParts
{
	if (updatingTags_)
		return;
	updatingTags_ = YES;
	@synchronized(self)
	{
		if (tagToLabelDictionary_)
			return;
		dispatch_async(globalQueue(), ^{
			if (!revisionToLabels_)
				revisionToLabels_ = [[NSMutableDictionary alloc] init];

			NSMutableArray* bookmarksArgs = [NSMutableArray arrayWithObjects:@"bookmarks", @"--verbose", nil];
			ExecutionResult bookmarksResults = [TaskExecutions executeMercurialWithArgs:bookmarksArgs fromRoot: rootPath_ logging:eLoggingNone];
			NSString* rawBookmarks = trimString(bookmarksResults.outStr);
			NSArray* bookmarkLines = [rawBookmarks componentsSeparatedByString:@"\n"];
			
			NSMutableDictionary* bookmarkToLabelDict = [[NSMutableDictionary alloc]init];			
			for (NSString* line in bookmarkLines)
			{
				LabelData* label = [LabelData labelDataFromBookmarkResultLine:line];
				if (label)
				{
					[bookmarkToLabelDict synchronizedSetObject:label forKey:[label name]];
					if (![revisionToLabels_ synchronizedObjectForKey:[label revision]])
						[revisionToLabels_ synchronizedSetObject:[[NSMutableArray alloc]init] forKey:[label revision]];
					[[revisionToLabels_ synchronizedObjectForKey:[label revision]] addObject:label];
				}
			}
			
			bookmarkToLabelDictionary_ = bookmarkToLabelDict;
			
			NSMutableArray* tagsArgs = [NSMutableArray arrayWithObjects:@"tags", @"--verbose", nil];
			ExecutionResult tagsResults = [TaskExecutions executeMercurialWithArgs:tagsArgs fromRoot: rootPath_ logging:eLoggingNone];
			NSString* rawTags = trimString(tagsResults.outStr);
			NSArray* tagLines = [rawTags componentsSeparatedByString:@"\n"];

			NSMutableDictionary* tagToLabelDict = [[NSMutableDictionary alloc]init];			
			for (NSString* line in tagLines)
			{
				LabelData* label = [LabelData labelDataFromTagResultLine:line];
				NSString* revisionFromBookmark = [[bookmarkToLabelDict objectForKey:[label name]] revision];
				BOOL bookmarkForLabelExists = (label && revisionFromBookmark && [[label revision] isEqualToString:revisionFromBookmark]);	// A little tricky
				if (label && !bookmarkForLabelExists)
				{
					[tagToLabelDict synchronizedSetObject:label forKey:[label name]];
					if (![revisionToLabels_ synchronizedObjectForKey:[label revision]])
						[revisionToLabels_ synchronizedSetObject:[[NSMutableArray alloc]init] forKey:[label revision]];
					[[revisionToLabels_ synchronizedObjectForKey:[label revision]] addObject:label];
				}
			}

			tagToLabelDictionary_ = tagToLabelDict;
			[myDocument postNotificationWithName:kLogEntriesDidChange userInfo:[NSDictionary dictionaryWithObject:kLogEntryBookmarksChanged forKey:kLogEntryChangeType]];
			[myDocument postNotificationWithName:kLogEntriesDidChange userInfo:[NSDictionary dictionaryWithObject:kLogEntryTagsChanged		forKey:kLogEntryChangeType]];
		});
	}
}

- (NSDictionary*) tagToLabelDictionary { if (!tagToLabelDictionary_)	[self updateTagParts];  return tagToLabelDictionary_; }

- (void) updateBookmarkParts
{
	if (updatingBookmarks_)
		return;
	updatingBookmarks_ = YES;
	@synchronized(self)
	{
		if (bookmarkToLabelDictionary_)
			return;
		[self updateTagParts];
	}
}

- (NSDictionary*) bookmarkToLabelDictionary { if (!bookmarkToLabelDictionary_)	[self updateBookmarkParts];  return bookmarkToLabelDictionary_; }



- (void) updateBranchParts
{
	if (updatingBranches_)
		return;
	updatingBranches_ = YES;
	@synchronized(self)
	{
		if (branchToLabelDictionary_)
			return;
		dispatch_async(globalQueue(), ^{
			if (!revisionToLabels_)
				revisionToLabels_ = [[NSMutableDictionary alloc] init];
			NSMutableArray* branchArgs = [NSMutableArray arrayWithObjects:@"branches", nil];
			ExecutionResult results = [TaskExecutions executeMercurialWithArgs:branchArgs fromRoot: rootPath_ logging:eLoggingNone];
			NSString* rawBranches = trimString(results.outStr);
			NSArray* branchLines = [rawBranches componentsSeparatedByString:@"\n"];

			NSMutableDictionary* branchToLabelDict = [[NSMutableDictionary alloc]init];
			for (NSString* line in branchLines)
			{
				LabelData* label = [LabelData labelDataFromBranchResultLine:line];
				if (label)
				{
					[branchToLabelDict synchronizedSetObject:label forKey:[label name]];
					if (![revisionToLabels_ synchronizedObjectForKey:[label revision]])
						[revisionToLabels_ synchronizedSetObject:[[NSMutableArray alloc]init] forKey:[label revision]];
					[[revisionToLabels_ synchronizedObjectForKey:[label revision]] addObject:label];
				}
			}

			branchToLabelDictionary_	= branchToLabelDict;

			[myDocument postNotificationWithName:kLogEntriesDidChange userInfo:[NSDictionary dictionaryWithObject:kLogEntryBranchesChanged forKey:kLogEntryChangeType]];
		});
	}	
}

- (NSDictionary*) branchToLabelDictionary { if (!branchToLabelDictionary_) [self updateBranchParts];	 return branchToLabelDictionary_; }



- (void) updateOpenHeadParts
{
	if (updatingOpenHeads_)
		return;
	updatingOpenHeads_ = YES;
	@synchronized(self)
	{
		if (openHeadToLabelDictionary_)
			return;
		dispatch_async(globalQueue(), ^{
			if (!revisionToLabels_)
				revisionToLabels_ = [[NSMutableDictionary alloc] init];
			NSArray* openHeads = [[self getHGHeads] componentsSeparatedByString:@" "];
			
			NSMutableDictionary* openHeadToLabelDict = [[NSMutableDictionary alloc]init];
			for (NSString* revChangesetString in openHeads)
			{
				LabelData* label = [LabelData labelDataFromOpenHeadsLine:revChangesetString];
				if (label)
				{
					[openHeadToLabelDict synchronizedSetObject:label forKey:[label revision]];
					if (![revisionToLabels_ synchronizedObjectForKey:[label revision]])
						[revisionToLabels_ synchronizedSetObject:[[NSMutableArray alloc]init] forKey:[label revision]];
					[[revisionToLabels_ synchronizedObjectForKey:[label revision]] addObject:label];
				}
			}
			
			openHeadToLabelDictionary_	= openHeadToLabelDict;
			
			[myDocument postNotificationWithName:kLogEntriesDidChange userInfo:[NSDictionary dictionaryWithObject:kLogEntryOpenHeadsChanged forKey:kLogEntryChangeType]];
		});
	}	
}

- (NSDictionary*) openHeadToLabelDictionary { if (!openHeadToLabelDictionary_) [self updateOpenHeadParts];	 return openHeadToLabelDictionary_; }


- (BOOL) labelsAreFullyLoaded { return tagToLabelDictionary_ && bookmarkToLabelDictionary_ && branchToLabelDictionary_ && openHeadToLabelDictionary_; }

- (NSDictionary*) revisionToLabels
{
	if (![self labelsAreFullyLoaded])
	{
		[self updateTagParts];
		[self updateBookmarkParts];
		[self updateBranchParts];
		[self updateOpenHeadParts];
		return nil;
	}
	return revisionToLabels_;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Derived Information
// -----------------------------------------------------------------------------------------------------------------------------------------

// Compute are we in a mergeState ie does 'hg parents --template "{rev} "' return "num" or "num num" if the later then we are in a merge state.
- (BOOL) inMergeState
{
	if (!inMergeState_)
	{
		NSString* revs = [self getHGParentsRevisions];
		inMergeState_ = [NSNumber numberWithBool:([[revs componentsSeparatedByString: @" "] count] > 1)];
	}
	return [inMergeState_ boolValue];
}

- (BOOL) hasMultipleOpenHeads
{
	if (!hasMultipleOpenHeads_)
	{
		NSString* heads = [self getHGHeads];
		hasMultipleOpenHeads_ = [NSNumber numberWithBool:([[heads componentsSeparatedByString: @" "] count] > 1)];
	}
	return [hasMultipleOpenHeads_ boolValue];
}

- (BOOL)	  revisionIsParent:(NSString*)rev { return [[self getHGParent2Revision] isEqualToString:rev] || [[self getHGParent1Revision] isEqualToString:rev];}

- (BOOL)      isCurrentRevisionTip			{ return [[self getHGParent1Revision] isEqualToString:[self getHGTipRevision]]; }
- (NSInteger) computeNumberOfRealRevisions	{ return [[self getHGTipRevision] intValue]; }
- (NSInteger) computeNumberOfRevisions		{ return [[self getHGTipRevision] intValue] + (includeIncompleteRevision_ ? 1 : 0); }
- (NSString*) incompleteRevision			{ return [incompleteRevisionEntry_ revision]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Parent / Children handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSMutableArray*) setOfParentsForRev:(NSNumber*)rev
{
	NSMutableArray* setOfParents = [parentsCollection_ valueForNumberKey:rev];
	if (!setOfParents)
	{
		setOfParents = [[NSMutableArray alloc] init];
		[parentsCollection_ setValue:setOfParents forNumberKey:rev];
	}
	return setOfParents;
}


- (NSMutableArray*) setOfChildrenForRev:(NSNumber*)rev
{
	NSMutableArray* setOfChildren = [childrenCollection_ valueForNumberKey:rev];
	if (!setOfChildren)
	{
		setOfChildren = [[NSMutableArray alloc] init];
		[childrenCollection_ setValue:setOfChildren forNumberKey:rev];
	}
	return setOfChildren;
}


// Add a child to the record of the revision
- (void) addChildRev:(NSNumber*)childRev forRev:(NSNumber*)rev
{
	NSMutableArray* setOfChildren = [self setOfChildrenForRev:rev];
	if (![setOfChildren containsObject:childRev])
		[setOfChildren addObject:childRev];
}

// Add a parent to the record of the revision
- (void) addParentRev:(NSNumber*)parentRev forRev:(NSNumber*)rev
{
	NSMutableArray* setOfParents = [self setOfParentsForRev:rev];
	if (![setOfParents containsObject:parentRev])
		[setOfParents addObject:parentRev];
}

// Add a child to the record of the revision
- (void) removeChildRev:(NSNumber*)childRev forRev:(NSNumber*)rev
{
	NSMutableArray* setOfChildren = [self setOfChildrenForRev:rev];
	if ([setOfChildren containsObject:childRev])
		[setOfChildren removeObject:childRev];
}

// Add a parent to the record of the revision
- (void) removeParentRev:(NSNumber*)parentRev forRev:(NSNumber*)rev
{
	NSMutableArray* setOfParents = [self setOfParentsForRev:rev];
	if ([setOfParents containsObject:parentRev])
		[setOfParents removeObject:parentRev];
}



- (void) setRelationshipOfParent:(NSNumber*)parentRev andChild:(NSNumber*)childRev addToRelationships:(BOOL)add
{
	if (add)
	{
		[self addParentRev:parentRev forRev:childRev];
		[self addChildRev:childRev   forRev:parentRev];
	}
	else
	{
		[self removeParentRev:parentRev forRev:childRev];
		[self removeChildRev:childRev   forRev:parentRev];
	}
}


- (void) fleshOutParentsAndChildren:(LogEntry*)entry addRelationShips:(BOOL)add
{
	//DebugLog(@"entry %@", entry);
	NSString* theParentsOfEntry = [entry parents];
	NSInteger revInt = stringAsInt([entry revision]);
	NSNumber* revNum = stringAsNumber([entry revision]);

	// If the parents are empty from the log result that means that its parent is the preceding revision.
	if (IsEmpty(theParentsOfEntry))
	{
		if (revInt >= 1)
		{
			NSNumber* previousRevNum = intAsNumber(revInt-1);
			[self setRelationshipOfParent:previousRevNum andChild:revNum addToRelationships:add];
		}
		return;
	}

	NSString* parent1 = nil;
	NSString* parent2 = nil;
	
	if ([theParentsOfEntry getCapturesWithRegexAndComponents:@"(\\d+):[\\d\\w]+\\s*(\\d+):[\\d\\w]+" firstComponent:&parent1 secondComponent:&parent2])
	{
		[self setRelationshipOfParent:stringAsNumber(parent1) andChild:revNum addToRelationships:add];
		[self setRelationshipOfParent:stringAsNumber(parent2) andChild:revNum addToRelationships:add];
		return;
	}
	
	if ([theParentsOfEntry getCapturesWithRegexAndComponents:@"(\\d+):[\\d\\w]+\\s*" firstComponent:&parent1])
		[self setRelationshipOfParent:stringAsNumber(parent1) andChild:revNum addToRelationships:add];
}


- (NSArray*) parentsOfRev:(NSNumber*)rev  { return [parentsCollection_  valueForNumberKey:rev]; }
- (NSArray*) childrenOfRev:(NSNumber*)rev { return [childrenCollection_ valueForNumberKey:rev]; }


- (void) descendantsOfRev_addDescendants:(NSArray*)children to:(NSMutableSet*)descendants
{
	for (NSNumber* childRevNum in children)
		if (![descendants containsObject:childRevNum])
		{
			[descendants addObject:childRevNum];
			[self descendantsOfRev_addDescendants:[self childrenOfRev:childRevNum] to:descendants];
		}
}

- (NSSet*) descendantsOfRev:(NSNumber*)rev
{
	NSMutableSet* descendants = [[NSMutableSet alloc] init];
	[descendants addObject:rev];
	[self descendantsOfRev_addDescendants:[self childrenOfRev:rev] to:descendants];
	return descendants;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LogEntry backing
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setEntry:(LogEntry*)entry
{
	if (entry)
		[revisionStringToLogEntry_  synchronizedSetObject:entry forKey:[entry revision]];
}

// Fill this documents revisionStringToLogEntry_ with data for the revisions from lowLimit to highLimit
- (void) fillTableFrom:(NSInteger)lowLimit to:(NSInteger)highLimit
{
	// Now we just fetch the entries from the high limit to the low limit.
	NSString* revLimits     = [NSString stringWithFormat:@"%d:%d", lowLimit, highLimit];
	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", revLimits, @"--template", templateStringShort, nil];	// templateStringShort is global set in setupGlobalsForPartsAndTemplate()
	dispatch_async(globalQueue(), ^{
		ExecutionResult hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:rootPath_  logging:eLoggingNone];
		NSArray* lines = [hgLogResults.outStr componentsSeparatedByString:entrySeparator];
		NSMutableArray* entries = [[NSMutableArray alloc] init];
		for (NSString* line in lines)
		{
			LogEntry* entry = [LogEntry fromLogResultLineShort:line  forRepositoryData:self];
			if (entry)
				[entries addObject:entry];
		}
		
		dispatch_async(mainQueue(), ^{
			for (LogEntry* entry in entries)
			{
				[self fleshOutParentsAndChildren:entry addRelationShips:YES];
				[self setEntry:entry];
			}
			[myDocument postNotificationWithName:kLogEntriesDidChange userInfo:[NSDictionary dictionaryWithObject:kLogEntryDetailsChanged forKey:kLogEntryChangeType]];
		});
	});
}

- (BOOL) entryIsLoadedForRevisionNumber:(NSNumber*)rev
{
	LogEntry* entry = [revisionStringToLogEntry_ synchronizedObjectForKey:numberAsString(rev)];
	return entry && ([entry loadStatus] >= eLogEntryLoadedPartially);
}

- (LogEntry*) rawEntryForRevisionString:(NSString*)revisionStr
{
	return [revisionStringToLogEntry_ synchronizedObjectForKey:revisionStr];
}

- (LogEntry*) entryForRevisionString:(NSString*)revisionStr
{
	static int cacheLineCount = 100;
	
	LogEntry* requestedLogEntry = [revisionStringToLogEntry_ synchronizedObjectForKey:revisionStr];
	if (requestedLogEntry)
		return requestedLogEntry;
	
	// We now read in some more lines. We do this since in log files with hundreds of thousands of lines we don't want to read
	// *everything* in at once.
	int requestedRow = [revisionStr intValue];
	
	int lowLimit  = MAX(0, requestedRow - cacheLineCount);
	int highLimitOfNormal = [self computeNumberOfRealRevisions];
	int highLimit = MIN(highLimitOfNormal, requestedRow + cacheLineCount);
	
	// We add pending LogEntries for all of the revisions we are about to read in. This means we don't redundantly try to
	// repeatedly do a fillTableFrom:to:
	int count = requestedRow;
	while (--count >= lowLimit)
	{
		NSString* rev = intAsString(count);
		if ([revisionStringToLogEntry_ synchronizedObjectForKey:rev])
		{
			lowLimit = count;
			break;
		}
		[self setEntry:[LogEntry pendingEntryForRevision:rev forRepositoryData:self]];
	}
		
	count = requestedRow;
	while (++count <= highLimit)
	{
		NSString* rev = intAsString(count);
		if ([revisionStringToLogEntry_ synchronizedObjectForKey:rev])
		{
			highLimit = count;
			break;
		}
		[self setEntry:[LogEntry pendingEntryForRevision:rev forRepositoryData:self]];
	}
		
	[self fillTableFrom:lowLimit to:highLimit];

	LogEntry* newPendingEntry = [LogEntry pendingEntryForRevision:revisionStr forRepositoryData:self];
	[self setEntry:newPendingEntry];
	
	return newPendingEntry;
}


@end
