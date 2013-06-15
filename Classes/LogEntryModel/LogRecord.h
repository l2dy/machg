//
//  LogRecord.h
//  MacHg
//
//  Created by Jason Harris on 11/24/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"


extern NSString* templateLogRecordString;
extern NSString* const LogRecordSeparator;
extern NSString* const LogRecordDetailsPartSeparator;
void setupGlobalsForLogRecordPartsAndTemplate();


@interface LogRecord : NSObject
{
	NSDate* 	date_;
}

@property LogRecordLoadStatus loadStatus;
@property NSString* author;
@property NSString* fullAuthor;
@property NSString* branch;
@property NSString* shortComment;
@property NSString* fullComment;
@property NSString*	changeset;
@property NSArray*	filesAdded;
@property NSArray*	filesModified;
@property NSArray*	filesRemoved;


// Create Log Records
+ (LogRecord*) createPendingEntryForChangeset:(NSString*)changeset;
+ (LogRecord*) unfinishedRecord;		// This represents the unfinished record, or the record which is being processed right
										// now, the uncommitted record, etc.

// Flesh out LogRecord with results
+ (void)	   fillDetailsOfLogRecordsFrom:(NSInteger)lowLimit  to:(NSInteger)highLimit  forRepository:(RepositoryData*)repository;
- (void)	   fillDetailsOfLogRecordForRepository:(RepositoryData*)repository;
- (void)	   fillFilesOfLogRecordForRepository:(RepositoryData*)repository;


// Status queries
- (BOOL)	  isLoading;
- (BOOL)	  detailsLoaded;
- (BOOL)	  filesLoaded;
- (BOOL)	  detailsAreLoadingOrLoaded;
- (BOOL)	  filesAreLoadingOrLoaded;
- (BOOL)	  isFullyLoaded;


- (NSString*) shortDate;
- (NSString*) fullDate;
- (NSString*) isoDate;
- (NSDate*)   rawDate;


//+ (LogRecord*) fullyLoadRecordForChangeset:(NSString*)changeset andRepository:(RepositoryData*)repository;

@end