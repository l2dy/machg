//
//  LogEntry.h
//  MacHg
//
//  Created by Jason Harris on 7/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

extern NSString* templateLogEntryString;
extern NSString* const logEntrySeparator;
extern NSString* const logEntryPartSeparator;
extern NSString* const incompleteChangeset;		// This is the changeset hash we use for the "incomplete revision"
void setupGlobalsForLogEntryPartsAndTemplate();

@interface LogEntry : NSObject
{
	RepositoryData* __weak collection_;
}

@property LogEntryLoadStatus loadStatus;
@property NSNumber*		revision;
@property NSArray*		parentsArray;		// Array of parent   revs as NSNumbers
@property NSArray*		childrenArray;		// Array of children revs as NSNumbers
@property NSString*		changeset;
@property LogRecord*	fullRecord;

- (RepositoryData*) repositoryData;

- (NSArray*)  labels;
- (NSArray*)  tags;
- (NSArray*)  bookmarks;
- (NSString*) branchHead;
- (BOOL)      isClosedBranchHead;
- (NSString*) labelsString;

- (id) labelsAndShortComment;



// Creation of LogEntries from results
+ (LogEntry*) fromLogEntryResultLine:(NSString*)line			 forRepositoryData:(RepositoryData*)collection;
+ (LogEntry*) pendingLogEntryForRevision:(NSNumber*)revisionStr  forRepositoryData:(RepositoryData*)collection;
+ (LogEntry*) unfinishedEntryForRevision:(NSNumber*)revisionStr  forRepositoryData:(RepositoryData*)collection;


// Flesh out a LogEntry with results
- (void)	  loadLogEntryResultLine:(NSString*)line;
- (void)	  fullyLoadEntry;


// Modify children of entry
- (void)	  addChildRevisionNum:(NSNumber*)childRevNum;
- (void)	  removeChildRevisionNum:(NSNumber*)childRevNum;


// Query the LogEntry
- (NSInteger) childCount;
- (NSInteger) parentCount;
- (BOOL)	  hasMultipleParents;
- (NSArray*)  parentsOfEntry;			// Array of parent   revs as NSNumbers
- (NSArray*)  childrenOfEntry;			// Array of children revs as NSNumbers
- (NSString*) revisionStr;
- (NSInteger) revisionInt;
- (NSInteger) ithChildRev:(NSInteger)i;
- (NSInteger) ithParentRev:(NSInteger)i;
- (BOOL)      isEqualToEntry:(LogEntry*)entry;
- (BOOL)	  revIsDirectParent:(NSInteger)rev;
- (BOOL)	  revIsDirectChild:(NSInteger)rev;
- (NSNumber*) firstParent;
- (NSNumber*) secondParent;
- (NSNumber*) minimumParent;


// Status and Updating
- (BOOL)	  isLoading;
- (BOOL)	  isLoaded;
- (BOOL)	  isFullyLoaded;


// Query the LogRecord
- (NSString*) author;
- (NSString*) fullAuthor;
- (NSString*) shortComment;
- (NSString*) fullComment;
- (NSArray*)  filesAdded;
- (NSArray*)  filesModified;
- (NSArray*)  filesRemoved;


// Date handling
- (NSString*) shortDate;
- (NSString*) fullDate;
- (NSString*) isoDate;
- (NSDate*)   rawDate;


// Presentation of Entry
- (NSAttributedString*)	formattedBriefEntry;
- (NSAttributedString*) formattedVerboseEntry;

@end


// Utilities for attributed strings

NSAttributedString*	categoryAttributedString(NSString* string);
NSAttributedString*	normalAttributedString(NSString* string);
NSAttributedString*	grayedAttributedString(NSString* string);

