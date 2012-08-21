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
	NSString* 	__strong author_;
	NSString* 	__strong fullAuthor_;
	NSString*   __strong branch_;
	NSDate* 	date_;
	NSString* 	__strong shortComment_;
	NSString* 	__strong fullComment_;
	NSString*	__strong changeset_;
	NSArray*	__strong filesAdded_;
	NSArray*	__strong filesModified_;
	NSArray*	__strong filesRemoved_;
}

@property (readwrite,assign) LogRecordLoadStatus loadStatus;
@property (readwrite,strong) NSString* 	author;
@property (readwrite,strong) NSString* 	fullAuthor;
@property (readwrite,strong) NSString* 	branch;
@property (readwrite,strong) NSString* 	shortComment;
@property (readwrite,strong) NSString* 	fullComment;
@property (readwrite,strong) NSString*	changeset;
@property (readwrite,strong) NSArray*	filesAdded;
@property (readwrite,strong) NSArray*	filesModified;
@property (readwrite,strong) NSArray*	filesRemoved;


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