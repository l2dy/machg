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
	LogRecordLoadStatus  loadStatus_;
	NSString* 	author_;
	NSString* 	fullAuthor_;
	NSDate* 	date_;
	NSString* 	shortComment_;
	NSString* 	fullComment_;
	NSString*	changeset_;
	NSArray*	filesAdded_;
	NSArray*	filesModified_;
	NSArray*	filesRemoved_;
}

@property (readwrite,assign) LogRecordLoadStatus loadStatus;
@property (readwrite,assign) NSString* 	author;
@property (readwrite,assign) NSString* 	fullAuthor;
@property (readwrite,assign) NSString* 	shortComment;
@property (readwrite,assign) NSString* 	fullComment;
@property (readwrite,assign) NSString*	changeset;
@property (readwrite,assign) NSArray*	filesAdded;
@property (readwrite,assign) NSArray*	filesModified;
@property (readwrite,assign) NSArray*	filesRemoved;


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