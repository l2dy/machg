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

extern NSString* templateStringShort;
extern NSString* templateStringFull;
extern NSString* const entrySeparator;
extern NSString* const entryPartSeparator;
extern void setupGlobalsForPartsAndTemplate();

@interface LogEntry : NSObject
{
	LogEntryLoadStatus  loadStatus_;
	RepositoryData* collection_;
	NSString* 	revision_;
	NSString* 	author_;
	NSString* 	fullAuthor_;
	NSDate* 	date_;
	NSString* 	shortComment_;
	NSString* 	fullComment_;
	NSString* 	parents_;
	NSArray* 	tags_;
	NSArray* 	bookmarks_;
	NSString* 	branch_;
	NSString* 	labels_;					// This is the combination of tags, branches, and bookmarks
	NSString*	changeset_;
	NSString*	fullChangeset_;
	NSArray*	filesAdded_;
	NSArray*	filesModified_;
	NSArray*	filesRemoved_;
}

@property (readwrite,assign) LogEntryLoadStatus loadStatus;
@property (readwrite,assign) NSString* 	revision;
@property (readwrite,assign) NSString* 	fullAuthor;
@property (readwrite,assign) NSString* 	author;
@property (readwrite,assign) NSString* 	shortComment;
@property (readwrite,assign) NSString* 	fullComment;
@property (readwrite,assign) NSString* 	parents;
@property (readwrite,assign) NSString*	changeset;
@property (readwrite,assign) NSString*	fullChangeset;
@property (readwrite,assign) NSArray*	filesAdded;
@property (readwrite,assign) NSArray*	filesModified;
@property (readwrite,assign) NSArray*	filesRemoved;

- (NSArray*)  tags;
- (NSArray*)  bookmarks;
- (NSString*) branch;
- (NSString*) labels;

- (id) labelsAndShortComment;


// Creation of LogEntries from results
+ (LogEntry*) fromLogResultLineShort:(NSString*)line  forRepositoryData:(RepositoryData*)collection;
+ (LogEntry*) fromLogResultLineFull: (NSString*)line  forRepositoryData:(RepositoryData*)collection;
+ (LogEntry*) pendingEntryForRevision:(NSString*)revisionStr     forRepositoryData:collection;
+ (LogEntry*) unfinishedEntryForRevision:(NSString*)revisionStr  forRepositoryData:collection;


// Flesh out a LogEntry with results
- (void)	  loadLogResultLineShort:(NSString*)line;
- (void)	  loadLogResultLineFull: (NSString*)line;
- (void)	  fullyLoadEntry;


// Query the LogEntry
- (NSArray*)  parentsOfEntry;
- (NSArray*)  childrenOfEntry;
- (NSString*) changesetInShortForm;
- (BOOL)	  isFullyLoaded;
- (RepositoryData*) repositoryData;
- (NSString*) firstParent;


// Date handling
- (NSString*) shortDate;
- (NSString*) fullDate;
- (NSString*) isoDate;
- (void)	  setDate:(NSString*)dateString;


// Presentation of Entry
- (void)	loadAndDisplayFormattedVerboseEntryIn:(id)container;
- (NSAttributedString*)	formattedBriefEntry;
- (NSAttributedString*) formattedVerboseEntry;
- (NSString*) fullCommentSynchronous;

@end


// Utilities for attributed strings

NSAttributedString*	categoryAttributedString(NSString* string);
NSAttributedString*	normalAttributedString(NSString* string);
NSAttributedString*	grayedAttributedString(NSString* string);

