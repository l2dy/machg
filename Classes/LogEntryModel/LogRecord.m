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
#import "RepositoryData.h"






// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Local Statics
// ------------------------------------------------------------------------------------

static NSArray*  namesOfLogRecordDetailsParts = nil;
NSString* templateLogRecordString             = nil;
NSString* const LogRecordSeparator            = @"\n\n‚Äπ‚Ä°‚Ä∫\n";	// We just need to choose two strings which will never be used inside the *comment* of a commit. (It's not disastrous if
NSString* const LogRecordDetailsPartSeparator = @"\n‚Äπ,‚Ä∫\n";		// they are though it's just the entry for that will display missing....)

NSMutableDictionary* changesetHashToLogRecord = nil;				// changset (full) -> LogRecord. The items in this map never get
																	// released. Once we load a LogRecord we have it forever





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Local Utilities
// ------------------------------------------------------------------------------------

void setupGlobalsForLogRecordPartsAndTemplate()
{
	NSArray* templateParts       = @[ @"{node}",    @"{author|person}", @"{author}",     @"{date}",   @"{branches}", @"{desc|firstline}", @"{desc}"];
	namesOfLogRecordDetailsParts = @[ @"changeset", @"author",          @"fullAuthor"  , @"date",     @"branch",     @"shortComment",     @"fullComment"];
	templateLogRecordString		 = [[templateParts componentsJoinedByString:LogRecordDetailsPartSeparator] stringByAppendingString:LogRecordSeparator];
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initializers
// ------------------------------------------------------------------------------------

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
		LogRecord* stored = changesetHashToLogRecord[changeset];
		if (stored)
			return stored;
		changesetHashToLogRecord[changeset] = record;
	}
	return record;
}


+ (LogRecord*) unfinishedRecord
{
	static LogRecord* unfinishedRecord = nil;	
    exectueOnlyOnce(^{
		unfinishedRecord = [[LogRecord alloc] init];
		[unfinishedRecord setChangeset:incompleteChangeset];
		[unfinishedRecord setShortComment:@" - current modifications - "];
		[unfinishedRecord setFullComment: @" - current modifications - "];
		[unfinishedRecord setAuthor:@" - "];
		[unfinishedRecord setLoadStatus:eLogRecordDetailsAndFilesLoaded];
		changesetHashToLogRecord[incompleteChangeset] = unfinishedRecord;
    });

	return unfinishedRecord;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Status Testing
// ------------------------------------------------------------------------------------

- (BOOL)	    isLoading					{ return bitsInCommon(loadStatus_, eLogRecordDetailsLoading | eLogRecordFilesLoading); }
- (BOOL)	    detailsLoaded				{ return bitsInCommon(loadStatus_, eLogRecordDetailsLoaded); }
- (BOOL)	    filesLoaded					{ return bitsInCommon(loadStatus_, eLogRecordFilesLoaded); }
- (BOOL)		detailsAreLoadingOrLoaded	{ return bitsInCommon(loadStatus_, eLogRecordDetailsLoading | eLogRecordDetailsLoaded); }
- (BOOL)		filesAreLoadingOrLoaded		{ return bitsInCommon(loadStatus_, eLogRecordFilesLoading   | eLogRecordFilesLoaded); }
- (BOOL)	    isFullyLoaded				{ return [self detailsLoaded] && [self filesLoaded] ; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Fill Out Records
// ------------------------------------------------------------------------------------

+ (BOOL) parseAndStoreLogRecordDetailsLine:(NSString*)line
{
	int itemCount  = [namesOfLogRecordDetailsParts count];
	NSArray* parts = [line componentsSeparatedByString:LogRecordDetailsPartSeparator];
	if ([parts count] < itemCount)
		return NO;
	
	NSString* changeset = parts[0];
	
	// If we already have an entry for this changeset we are done.
	LogRecord* stored = [changesetHashToLogRecord synchronizedObjectForKey:changeset];
	if (stored && [stored detailsLoaded])
		return NO;

	LogRecord* record = stored ? stored : [[LogRecord alloc] init];
	@synchronized(record)
	{
		for (int item = 0; item <itemCount; item++)
			[record setValue:parts[item] forKey:namesOfLogRecordDetailsParts[item]];
		
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
	
	dispatch_async(globalQueue(), ^{
		NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", changeset_, @"--template", templateLogRecordString, nil];	// templateLogEntryString is global set in setupGlobalsForLogEntryPartsAndTemplate()
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

	@synchronized(self)
	{		
		if ([self filesAreLoadingOrLoaded])
			return;
		
		LogRecordLoadStatus status = [self loadStatus];
		status = unionBits(status, eLogRecordFilesLoading);
		[self setLoadStatus:status];

		dispatch_async(globalQueue(), ^{
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
		});
	}
	
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Date handling
// ------------------------------------------------------------------------------------

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

	NSTimeInterval delta = ABS([date_ timeIntervalSinceNow]);
	NSDate* now = [NSDate dateWithTimeIntervalSinceNow:0];
	if (DateAndTimeFormatFromDefaults() == eDateRelative)
	{		
		NSString* description;
		BOOL inPast = [date_ isBefore:now];
		NSString* relation = inPast ? @"ago" : @"in the future";
		if      (delta >= 2 * kYear)	description = fstr(@"%ld years %@",   lround(floor(delta / kYear)),   relation);
		else if (delta >= 2 * kMonth)	description = fstr(@"%ld months %@",  lround(floor(delta / kMonth)),  relation);
		else if (delta >= 2 * kWeek)	description = fstr(@"%ld weeks %@",   lround(floor(delta / kWeek)),   relation);
		else if (delta >= 2 * kDay)		description = fstr(@"%ld days %@",    lround(floor(delta / kDay)),    relation);
		else if (delta >= 2 * kHour)	description = fstr(@"%ld hours %@",   lround(floor(delta / kHour)),   relation);
		else if (delta >= 2 * kMinute)	description = fstr(@"%ld minutes %@", lround(floor(delta / kMinute)), relation);
		else							description = fstr(@"%ld seconds %@", lround(floor(delta / kSecond)), relation);
		return description;
	}
	else
	{
		NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents* dateComponents = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date_];
		NSInteger year   = [dateComponents year];
		NSInteger month  = [dateComponents month];
		NSInteger day    = [dateComponents day];
		NSInteger hour   = [dateComponents hour];
		NSInteger minute = [dateComponents minute];
		

		NSString* monthString = nil;
		switch (month)
		{
			case 1:  monthString = @"Jan"; break;
			case 2:  monthString = @"Feb"; break;
			case 3:  monthString = @"Mar"; break;
			case 4:  monthString = @"Apr"; break;
			case 5:  monthString = @"May"; break;
			case 6:  monthString = @"Jun"; break;
			case 7:  monthString = @"Jul"; break;
			case 8:  monthString = @"Aug"; break;
			case 9:  monthString = @"Sep"; break;
			case 10: monthString = @"Oct"; break;
			case 11: monthString = @"Nov"; break;
			case 12: monthString = @"Dec"; break;
			default: monthString = @"-";   break;
		}
		NSDateComponents* nowComponents = [gregorian components:NSYearCalendarUnit fromDate:now];
		if (year < [nowComponents year])
			return fstr(@"%2ld %@ %ld", (long)day, monthString, (long)year);
		return fstr(@"%2ld %@ %02ld:%02ld", (long)day, monthString, (long)hour, (long)minute);		
	}

}

- (NSString*) fullDate
{
	if (self == [LogRecord unfinishedRecord])
		return @"now";

	static NSDateFormatter* fullDateFormatter = nil;
    exectueOnlyOnce( ^{
		fullDateFormatter = [[NSDateFormatter alloc] init];
		[fullDateFormatter setDateStyle:NSDateFormatterLongStyle];
		[fullDateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[fullDateFormatter setDoesRelativeDateFormatting:YES];
    });

	return [fullDateFormatter stringFromDate:date_];
}

- (NSDate*) rawDate { return date_; }

- (NSString*) isoDate { return [date_ isodateDescription]; }

- (void) setDate:(NSString*)dateString
{
	date_ = [NSDate dateWithUTCdatePlusOffset:dateString];
	if (!date_)
		date_ = [NSDate dateWithTimeIntervalSinceNow:0.0];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Description
// ------------------------------------------------------------------------------------

- (NSString*) description { return fstr(@"hash:%@, status %d, author:%@ comment: %@", changeset_ ? changeset_ : @"nil", loadStatus_, author_ ? author_ : @"nil", shortComment_ ? shortComment_ : @"nil"); }


@end
