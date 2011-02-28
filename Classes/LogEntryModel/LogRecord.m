//
//  LogRecord.m
//  MacHg
//
//  Created by Jason Harris on 11/24/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "LogRecord.h"
#import "LogEntry.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "FSNodeInfo.h"






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Local Statics
// -----------------------------------------------------------------------------------------------------------------------------------------

static NSArray*  namesOfLogRecordDetailsParts = nil;
NSString* templateLogRecordString             = nil;
NSString* const LogRecordSeparator            = @"\n\n‚Äπ‚Ä°‚Ä∫\n";	// We just need to choose two strings which will never be used inside the *comment* of a commit. (It's not disastrous if
NSString* const LogRecordDetailsPartSeparator = @"\n‚Äπ,‚Ä∫\n";		// they are though it's just the entry for that will display missing....)

NSMutableDictionary* changesetHashToLogRecord = nil;				// changset (full) -> LogRecord. The items in this map never get
																	// released. Once we load a LogRecord we have it forever





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Local Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

void setupGlobalsForLogRecordPartsAndTemplate()
{
	NSArray* templateParts         = [NSArray arrayWithObjects: @"{node}",    @"{author|person}", @"{author}",     @"{date}",   @"{branches}", @"{desc|firstline}", @"{desc}",      nil];
	namesOfLogRecordDetailsParts   = [NSArray arrayWithObjects: @"changeset", @"author",          @"fullAuthor"  , @"date",     @"branch",     @"shortComment",     @"fullComment", nil];
	templateLogRecordString = [[templateParts componentsJoinedByString:LogRecordDetailsPartSeparator] stringByAppendingString:LogRecordSeparator];
}



@implementation LogRecord

@synthesize		loadStatus = loadStatus_;
@synthesize 	author = author_;
@synthesize 	fullAuthor = fullAuthor_;
@synthesize     branch = branch_;
@synthesize 	shortComment = shortComment_;
@synthesize 	fullComment = fullComment_;
@synthesize		changeset = changeset_;
@synthesize		filesAdded = filesAdded_;
@synthesize		filesModified = filesModified_;
@synthesize		filesRemoved = filesRemoved_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initializers
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	if (self)
	{
		loadStatus_ = eLogEntryLoadedNone;
		author_ = nil;
		fullAuthor_ = nil;
		branch_ = nil;
		date_ = nil;
		shortComment_ = nil;
		fullComment_ = nil;
		changeset_ = nil;
		filesAdded_ = nil;
		filesModified_ = nil;
		filesRemoved_ = nil;
	}
    
	return self;
}


+ (LogRecord*) createPendingEntryForChangeset:(NSString*)changeset
{
	LogRecord* record = [[LogRecord alloc] init];
	[record setChangeset:changeset];
	[record setLoadStatus:eLogRecordDetailsLoading];
	@synchronized(changesetHashToLogRecord)
	{
		LogRecord* stored = [changesetHashToLogRecord objectForKey:changeset];
		if (stored)
			return stored;
		[changesetHashToLogRecord setObject:record forKey:changeset];
	}
	return record;
}


+ (LogRecord*) unfinishedRecord
{
	static LogRecord* unfinishedRecord = nil;
	if (unfinishedRecord)
		return unfinishedRecord;
	@synchronized(changesetHashToLogRecord)
	{
		if (unfinishedRecord)
			return unfinishedRecord;
		unfinishedRecord = [[LogRecord alloc] init];
		[unfinishedRecord setChangeset:incompleteChangeset];
		[unfinishedRecord setShortComment:@" - current modifications - "];
		[unfinishedRecord setFullComment: @" - current modifications - "];
		[unfinishedRecord setAuthor:@" - "];
		[unfinishedRecord setLoadStatus:eLogRecordDetailsAndFilesLoaded];
		[changesetHashToLogRecord setObject:unfinishedRecord forKey:incompleteChangeset];
	}
	return unfinishedRecord;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Status Testing
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)	    isLoading					{ return bitsInCommon(loadStatus_, eLogRecordDetailsLoading | eLogRecordFilesLoading); }
- (BOOL)	    detailsLoaded				{ return bitsInCommon(loadStatus_, eLogRecordDetailsLoaded); }
- (BOOL)	    filesLoaded					{ return bitsInCommon(loadStatus_, eLogRecordFilesLoaded); }
- (BOOL)		detailsAreLoadingOrLoaded	{ return bitsInCommon(loadStatus_, eLogRecordDetailsLoading | eLogRecordDetailsLoaded); }
- (BOOL)		filesAreLoadingOrLoaded		{ return bitsInCommon(loadStatus_, eLogRecordFilesLoading   | eLogRecordFilesLoaded); }
- (BOOL)	    isFullyLoaded				{ return [self detailsLoaded] && [self filesLoaded] ; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Fill Out Records
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (BOOL) parseAndStoreLogRecordDetailsLine:(NSString*)line
{
	int itemCount  = [namesOfLogRecordDetailsParts count];
	NSArray* parts = [line componentsSeparatedByString:LogRecordDetailsPartSeparator];
	if ([parts count] < itemCount)
		return NO;
	
	NSString* changeset = [parts objectAtIndex:0];
	
	// If we already have an entry for this changeset we are done.
	LogRecord* stored = [changesetHashToLogRecord synchronizedObjectForKey:changeset];
	if (stored && [stored detailsLoaded])
		return NO;

	LogRecord* record = stored ? stored : [[LogRecord alloc] init];
	@synchronized(record)
	{
		for (int item = 0; item <itemCount; item++)
			[record setValue:[parts objectAtIndex:item] forKey:[namesOfLogRecordDetailsParts objectAtIndex:item]];
		
		LogRecordLoadStatus status = [record loadStatus];
		status = unsetBits(status, eLogRecordDetailsLoading);
		status = unionBits(status, eLogRecordDetailsLoaded);
		[record setLoadStatus:status];
		[changesetHashToLogRecord synchronizedSetObject:record forKey:changeset];
	}
	return YES;
}


+ (void) fillDetailsOfLogRecordsFrom:(NSInteger)lowLimit to:(NSInteger)highLimit forRepository:(RepositoryData*)repository
{
	if (lowLimit < 0 || highLimit < 0)
		return;
	// Now we just fetch the entries from the high limit to the low limit.
	NSString* revLimits     = fstr(@"%d:%d", highLimit, lowLimit);
	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", revLimits, @"--template", templateLogRecordString, nil];	// templateLogEntryString is global set in setupGlobalsForLogEntryPartsAndTemplate()
	dispatch_async(globalQueue(), ^{
		ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:[repository rootPath]  logging:eLoggingNone];
		NSArray* lines = [hgLogResults.outStr componentsSeparatedByString:LogRecordSeparator];
		BOOL foundNewRecord = NO;
		for (NSString* line in lines)
			foundNewRecord |= [LogRecord parseAndStoreLogRecordDetailsLine:line];
		
		if (foundNewRecord)
			[[repository myDocument] postNotificationWithName:kLogEntriesDidChange];
	});
}


- (void) fillDetailsOfLogRecordForRepository:(RepositoryData*)repository
{
	if ([self detailsAreLoadingOrLoaded])
		return;
	
	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", changeset_, @"--template", templateLogRecordString, nil];	// templateLogEntryString is global set in setupGlobalsForLogEntryPartsAndTemplate()
	dispatch_async(globalQueue(), ^{
		ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:[repository rootPath]  logging:eLoggingNone];
		NSArray* lines = [hgLogResults.outStr componentsSeparatedByString:LogRecordSeparator];
		BOOL foundNewRecord = NO;
		for (NSString* line in lines)
			foundNewRecord |= [LogRecord parseAndStoreLogRecordDetailsLine:line];
		
		if (foundNewRecord)
			[[repository myDocument] postNotificationWithName:kLogEntriesDidChange];
	});
}


- (void) fillFilesOfLogRecordForRepository:(RepositoryData*)repository
{
	if ([self filesAreLoadingOrLoaded])
		return;
	
	// Load the added files, modified files, and removed files
	NSMutableArray* modified = nil;
	NSMutableArray* added    = nil;
	NSMutableArray* removed  = nil;
	
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", @"--change", changeset_, @"--added", @"--removed", @"--modified", nil];
	ExecutionResult* hgStatusResults = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:[repository rootPath]  logging:eLoggingNone];
	NSArray* hgStatusLines = [hgStatusResults.outStr componentsSeparatedByString:@"\n"];
	for (NSString* statusLine in hgStatusLines)
	{
		// If this particular status line is malformed skip this line.
		if ([statusLine length] < 3)
			continue;
		
		NSString* statusLetter   = [statusLine substringToIndex:1];
		HGStatus  theStatus      = [FSNodeInfo statusEnumFromLetter:statusLetter];
		NSString* statusPath     = [statusLine substringFromIndex:2];
		if (theStatus == eHGStatusModified)
		{
			if (!modified) modified = [[NSMutableArray alloc]init];
			[modified addObject:statusPath];
		}
		else if (theStatus == eHGStatusAdded)
		{
			if (!added) added = [[NSMutableArray alloc]init];
			[added addObject:statusPath];
		}
		else if (theStatus == eHGStatusRemoved)
		{
			if (!removed) removed = [[NSMutableArray alloc]init];
			[removed addObject:statusPath];
		}
	}
	
	LogRecordLoadStatus status = [self loadStatus];
	status = unsetBits(status, eLogRecordFilesLoading);
	status = unionBits(status, eLogRecordFilesLoaded);
	@synchronized(self)
	{		
		[self setLoadStatus:status];
		[self setFilesAdded:[NSArray arrayWithArray:added]];
		[self setFilesModified:[NSArray arrayWithArray:modified]];
		[self setFilesRemoved:[NSArray arrayWithArray:removed]];
	}
	[[repository myDocument] postNotificationWithName:kLogEntriesDidChange];
}

//+ (LogRecord*) fullyLoadRecordForChangeset:(NSString*)changeset andRepository:(RepositoryData*)repository
//{
//	// If we already have an entry for this changeset we are done.
//	LogRecord* stored = [changesetHashToLogRecord synchronizedObjectForKey:changeset];
//	LogRecord* record = stored ? stored : [LogRecord createPendingEntryForChangeset:changeset];
//	
//	[record fillFilesOfLogRecordForRepository:repository];
//	[record fillDetailsOfLogRecordForRepository:repository];
//	
//	return record;
//}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Date handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) shortDate
{
	static double kSecond = 1;
	static double kMinute = 60;
	static double kHour   = 3600;
	static double kDay    = 3600 * 24;
	static double kWeek   = 3600 * 24 * 7;
	static double kMonth  = 3600 * 24 * 30;
	static double kYear   = 3600 * 24 * 365;
	
	if (self == [LogRecord unfinishedRecord])
		return @"now";
	
	NSDate* now = [NSDate dateWithTimeIntervalSinceNow:0];
	NSTimeInterval delta = ABS([date_ timeIntervalSinceNow]);
	
	NSString* description;
	BOOL inPast = [date_ isBefore:now];
	NSString* relation = inPast ? @"ago" : @"in the future"; 
	if      (delta >= 2 * kYear)	description = fstr(@"%d years %@",   lround(floor(delta / kYear)),   relation);
	else if (delta >= 2 * kMonth)	description = fstr(@"%d months %@",  lround(floor(delta / kMonth)),  relation);
	else if (delta >= 2 * kWeek)	description = fstr(@"%d weeks %@",   lround(floor(delta / kWeek)),   relation);
	else if (delta >= 2 * kDay)		description = fstr(@"%d days %@",    lround(floor(delta / kDay)),    relation);
	else if (delta >= 2 * kHour)	description = fstr(@"%d hours %@",   lround(floor(delta / kHour)),   relation);
	else if (delta >= 2 * kMinute)	description = fstr(@"%d minutes %@", lround(floor(delta / kMinute)), relation);
	else							description = fstr(@"%d seconds %@", lround(floor(delta / kSecond)), relation);
	return description;
}

- (NSString*) fullDate
{
	if (self == [LogRecord unfinishedRecord])
		return @"now";
	
	static NSDateFormatter* dateFormatter = nil;
	if (!dateFormatter)
		@synchronized(NSApp)
		{
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateStyle:NSDateFormatterLongStyle];
			[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
			[dateFormatter setDoesRelativeDateFormatting:YES];
		}
	
	return [dateFormatter stringFromDate:date_];
}

- (NSDate*) rawDate { return date_; }

- (NSString*) isoDate { return [date_ isodateDescription]; }

- (void) setDate:(NSString*)dateString
{
	date_ = [NSDate dateWithUTCdatePlusOffset:dateString];
	if (!date_)
		date_ = [NSDate dateWithTimeIntervalSinceNow:0.0];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Description
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) description { return fstr(@"hash:%@, status %d, author:%@ comment: %@", changeset_ ? changeset_ : @"nil", loadStatus_, author_ ? author_ : @"nil", shortComment_ ? shortComment_ : @"nil"); }


@end
