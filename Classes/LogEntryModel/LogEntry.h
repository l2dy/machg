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
	NSString* 	shortDate_;
	NSString* 	fullDate_;
	NSString* 	shortComment_;
	NSString* 	fullComment_;
	NSString* 	parents_;
	NSArray* 	tags_;
	NSArray* 	bookmarks_;
	NSString* 	branch_;
	NSString* 	labels_;					// This is the combination of tags, branches, and bookmarks
	NSString*	changeset_;
	NSString*	filesAdded_;
	NSString*	filesModified_;
	NSString*	filesRemoved_;
}

@property (readwrite,assign) LogEntryLoadStatus loadStatus;
@property (readwrite,assign) NSString* 	revision;
@property (readwrite,assign) NSString* 	author;
@property (readwrite,assign) NSString* 	shortDate;
@property (readwrite,assign) NSString* 	fullDate;
@property (readwrite,assign) NSString* 	shortComment;
@property (readwrite,assign) NSString* 	fullComment;
@property (readwrite,assign) NSString* 	parents;
@property (readwrite,assign) NSString*	changeset;
@property (readwrite,assign) NSString*	filesAdded;
@property (readwrite,assign) NSString*	filesModified;
@property (readwrite,assign) NSString*	filesRemoved;

- (NSArray*)  tags;
- (NSArray*)  bookmarks;
- (NSString*) branch;
- (NSString*) labels;

- (NSAttributedString*) labelsAndShortComment;

// Creation of LogEntries from results
+ (LogEntry*) fromLogResultLineShort:(NSString*)line  forRepositoryData:(RepositoryData*)collection;
+ (LogEntry*) fromLogResultLineFull: (NSString*)line  forRepositoryData:(RepositoryData*)collection;
+ (LogEntry*) pendingEntryForRevision:(NSString*)revisionStr     forRepositoryData:collection;
+ (LogEntry*) unfinishedEntryForRevision:(NSString*)revisionStr  forRepositoryData:collection;


// Flesh out a LogEntry with results
- (void)	  loadLogResultLineShort:(NSString*)line;
- (void)	  loadLogResultLineFull: (NSString*)line;

// Query the LogEntry
- (NSArray*)  parentsOfEntry;
- (NSArray*)  childrenOfEntry;
- (NSString*) changesetInShortForm;
- (BOOL)	  isFullyLoaded;
- (RepositoryData*) repositoryData;


// Presentation of Entry
- (void)	displayFormattedVerboseEntryIn:(id)container;
- (NSAttributedString*)	formattedBriefEntry;
- (NSString*) fullCommentSynchronous;

@end


// Utilities for attributed strings

NSAttributedString*	categoryAttributedString(NSString* string);
NSAttributedString*	normalAttributedString(NSString* string);
NSAttributedString*	grayedAttributedString(NSString* string);

