//
//  LogEntry.m
//  MacHg
//
//  Created by Jason Harris on 7/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LogEntry.h"
#import "RepositoryData.h"
#import "Common.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "LabelData.h"
#import "TextButtonCell.h"
#import "DiffTextButtonCell.h"
#import "LabelTextButtonCell.h"
#import "FSNodeInfo.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Local Statics
// -----------------------------------------------------------------------------------------------------------------------------------------

static NSArray*  namesOfPartsShort  = nil;
static NSArray*  namesOfPartsFull   = nil;
NSString* templateStringShort = nil;
NSString* templateStringFull  = nil;
NSString* const entrySeparator      = @"\n\n‹‡›\n";			// We just need to choose two strings which will never be used inside the *comment* of a commit. (Its not disastrous if
NSString* const entryPartSeparator	= @"\n‹,›\n";			// they are though its just the entry for that will display missing....)





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Local Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

void setupGlobalsForPartsAndTemplate()
{
	// For some crazy reason you need to use {branches} to get the branch in the log command. Why?!? Ie you can test this with
	// 'hg log --template "{branches}\n{branch}" --rev tip'
	// This of course contradicts the output of 'hg branch' and 'hg branches'
	NSArray* templateParts;
	templateParts       = [NSArray arrayWithObjects:@"{rev}",    @"{author|person}", @"{date}", @"{parents}", @"{node|short}", @"{desc|firstline}", nil];
	namesOfPartsShort   = [NSArray arrayWithObjects:@"revision", @"author",          @"date",   @"parents",   @"changeset",    @"shortComment",     nil];
	templateStringShort = [[templateParts componentsJoinedByString:entryPartSeparator] stringByAppendingString:entrySeparator];

	templateParts       = [NSArray arrayWithObjects:@"{rev}",    @"{author|person}", @"{date}", @"{parents}", @"{node|short}",  @"{desc|firstline}", @"{desc}",      nil];
	namesOfPartsFull    = [NSArray arrayWithObjects:@"revision", @"author",          @"date",   @"parents",   @"changeset",     @"shortComment",     @"fullComment", nil];
	templateStringFull  = [[templateParts componentsJoinedByString:entryPartSeparator] stringByAppendingString:entrySeparator];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  LogEntry
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation LogEntry

@synthesize		loadStatus = loadStatus_;
@synthesize		revision = revision_;
@synthesize 	author = author_;
@synthesize 	shortComment = shortComment_;
@synthesize 	fullComment = fullComment_;
@synthesize 	parents = parents_;
@synthesize		changeset = changeset_;
@synthesize		filesAdded = filesAdded_;
@synthesize		filesModified = filesModified_;
@synthesize		filesRemoved = filesRemoved_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initializers
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) initForCollection:(RepositoryData*)collection
{
	self = [super init];
	if (self)
	{
		loadStatus_ = eLogEntryLoadedNone;
		collection_ = collection;
		revision_ = nil;
		author_ = nil;
		date_ = nil;
		shortComment_ = nil;
		fullComment_ = nil;
		parents_ = nil;
		tags_ = nil;
		bookmarks_ = nil;
		branch_ = nil;
		labels_ = nil;
		changeset_ = nil;
		filesAdded_ = nil;
		filesModified_ = nil;
		filesRemoved_ = nil;
	}
    
	return self;
}




- (NSArray*) tags
{
	if (tags_)
		return tags_;
	if (![collection_ revisionToLabels])
		return [[NSArray alloc]init];
	NSArray* labels = [[collection_ revisionToLabels] objectForKey:[self revision]];
	NSArray* tagLabels = [LabelData filterLabels:labels byType:eTagLabel];
	NSArray* sortedTagLabels = [tagLabels sortedArrayUsingDescriptors:[LabelData descriptorsForSortByNameAscending]];
	tags_ = [LabelData extractNameFromLabels:sortedTagLabels];
	return tags_;
}

- (NSArray*) bookmarks
{
	if (bookmarks_)
		return bookmarks_;
	if (![collection_ revisionToLabels])
		return [[NSArray alloc]init];
	NSArray* labels = [[collection_ revisionToLabels] objectForKey:[self revision]];
	NSArray* bookmarkLabels = [LabelData filterLabels:labels byType:eBookmarkLabel];
	NSArray* sortedBookmarkLabels = [bookmarkLabels sortedArrayUsingDescriptors:[LabelData descriptorsForSortByNameAscending]];
	bookmarks_ = [LabelData extractNameFromLabels:sortedBookmarkLabels];
	return bookmarks_;
}

- (NSString*) branch
{
	if (branch_)
		return branch_;
	if (![collection_ revisionToLabels])
		return @"";
	NSArray* labels = [[collection_ revisionToLabels] objectForKey:[self revision]];
	NSArray* branchLabels = [LabelData filterLabels:labels byType:eBranchLabel];	
	branch_ = IsNotEmpty(branchLabels) ? [[branchLabels objectAtIndex:0] name] : @"";
	return branch_;
}

- (NSString*) labels
{
	if (labels_)
		return labels_;
	if (![collection_ revisionToLabels])
		return @"";
	NSArray* labels = [[collection_ revisionToLabels] objectForKey:[self revision]];
	NSArray* filteredLabels = [LabelData filterLabels:labels byType:eNotOpenHead];
	NSArray* sortedLabels = [filteredLabels sortedArrayUsingDescriptors:[LabelData descriptorsForSortByTypeAscending]];
	NSArray* names = [LabelData extractNameFromLabels:sortedLabels];
	labels_ = [names componentsJoinedByString:@", "];
	return labels_;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Constructors
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (LogEntry*) fromLogResultLineShort:(NSString*)line  forRepositoryData:(RepositoryData*)collection
{
	LogEntry* entry = [[LogEntry alloc] initForCollection:collection];
	[entry loadLogResultLineShort:line];
	return ([entry loadStatus] != eLogEntryLoadedNone) ? entry : nil;
}

+ (LogEntry*) fromLogResultLineFull:(NSString*)line  forRepositoryData:(RepositoryData*)collection
{
	LogEntry* entry = [[LogEntry alloc] initForCollection:collection];
	[entry loadLogResultLineFull:line];
	return ([entry loadStatus] != eLogEntryLoadedNone) ? entry : nil;
}

+ (LogEntry*) pendingEntryForRevision:(NSString*)revisionStr  forRepositoryData:collection
{
	LogEntry* entry = [[LogEntry alloc] initForCollection:collection];
	[entry setRevision:revisionStr];
	[entry setLoadStatus:eLogEntryLoadedPending];
	return entry;
}

+ (LogEntry*) unfinishedEntryForRevision:(NSString*)revisionStr  forRepositoryData:collection
{
	LogEntry* entry = [[LogEntry alloc] initForCollection:collection];
	[entry setRevision:revisionStr];
	[entry setParents:[collection getHGParents]];
	[entry setShortComment:@"Current version (not yet committed)."];
	[entry setFullComment:@"Current version (not yet committed)."];
	entry->date_ = [NSDate dateWithTimeIntervalSinceNow:0];
	[entry setLoadStatus:eLogEntryLoadedFully];
	[entry setAuthor:@""];
	entry->branch_ = @"";
	entry->tags_ = [[NSArray alloc]init];
	[entry setChangeset:@""];
	[entry setFilesAdded:nil];
	[entry setFilesModified:nil];
	[entry setFilesRemoved:nil];
	return entry;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Flesh Out LogEntry
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) loadLogResultLineShort:(NSString*)line
{
	int itemCount  = [namesOfPartsShort count];
	NSArray* parts = [line componentsSeparatedByString:entryPartSeparator];
	if ([parts count] < itemCount)
		return;
	
	for (int item = 0; item <itemCount; item++)
		[self setValue:[parts objectAtIndex:item] forKey:[namesOfPartsShort objectAtIndex:item]];
	labels_ = nil;
	[self setLoadStatus:eLogEntryLoadedPartially];
}

- (void) loadLogResultLineFull:(NSString*)line
{
	int itemCount  = [namesOfPartsFull count];
	NSArray* parts = [line componentsSeparatedByString:entryPartSeparator];
	if ([parts count] < itemCount)
		return;
	
	for (int item = 0; item <itemCount; item++)
		[self setValue:[parts objectAtIndex:item] forKey:[namesOfPartsFull objectAtIndex:item]];
	labels_ = nil;
	[self setLoadStatus:eLogEntryLoadedFully];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Query the LogEntry
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSArray*)	parentsOfEntry			{ return [collection_ parentsOfRev:stringAsNumber([self revision])]; }
- (NSArray*)	childrenOfEntry			{ return [collection_ childrenOfRev:stringAsNumber([self revision])]; }
- (NSString*)	changesetInShortForm	{ return [changeset_ substringToIndex:MIN(12,[changeset_ length])]; }
- (BOOL)	    isFullyLoaded			{ return loadStatus_ == eLogEntryLoadedFully; }
- (RepositoryData*) repositoryData		{ return collection_; }
- (NSString*)	firstParent
{
	if (IsNotEmpty(parents_))
		return [[self parentsOfEntry] objectAtIndex:0];	
	return intAsString(MAX(0, stringAsInt(revision_) - 1));	
}





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
	
	if ([collection_ incompleteRevisionEntry] == self)
		return @"now";
	
	NSDate* now = [NSDate dateWithTimeIntervalSinceNow:0];
	NSTimeInterval delta = ABS([date_ timeIntervalSinceNow]);
	
	NSString* description;
	BOOL inPast = [date_ isBefore:now];
	NSString* relation = inPast ? @"ago" : @"in the future"; 
	if      (delta >= 2 * kYear)	description = fstr(@"%d years %@",   llround(floor(delta / kYear)),   relation);
	else if (delta >= 2 * kMonth)	description = fstr(@"%d months %@",  llround(floor(delta / kMonth)),  relation);
	else if (delta >= 2 * kWeek)	description = fstr(@"%d weeks %@",   llround(floor(delta / kWeek)),   relation);
	else if (delta >= 2 * kDay)		description = fstr(@"%d days %@",    llround(floor(delta / kDay)),    relation);
	else if (delta >= 2 * kHour)	description = fstr(@"%d hours %@",   llround(floor(delta / kHour)),   relation);
	else if (delta >= 2 * kMinute)	description = fstr(@"%d minutes %@", llround(floor(delta / kMinute)), relation);
	else							description = fstr(@"%d seconds %@", llround(floor(delta / kSecond)), relation);
	return description;
}

- (NSString*) fullDate
{
	if ([collection_ incompleteRevisionEntry] == self)
		return @"now";

	return [date_ descriptionWithLocale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

- (void) setDate:(NSString*)dateString
{
	NSString* base;
	NSString* rest;
	BOOL matched = [dateString getCapturesWithRegexAndTrimedComponents:@"(\\d+)\\s*(.*)" firstComponent:&base secondComponent:&rest];
	if (!matched)
	{
		date_ = [NSDate dateWithTimeIntervalSinceNow:0.0];
		return;
	}
	
	float offset = [rest floatValue];
	float date = [base floatValue];
	if (date != NAN && offset != NAN)
		date_ = [NSDate dateWithTimeIntervalSince1970: date + offset];
	else if (date != NAN)
		date_ = [NSDate dateWithTimeIntervalSince1970: date];
	else
		date_ = [NSDate dateWithTimeIntervalSinceNow:0.0];
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Formatted Entries
// -----------------------------------------------------------------------------------------------------------------------------------------


- (NSAttributedString*) formattedVerboseEntry
{
	NSMutableAttributedString* verboseEntry = [[NSMutableAttributedString alloc] init];
	if (YES)
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"\nChangeset:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@ : %@\n", revision_, [self changesetInShortForm]))];
	}
	if (IsNotEmpty([self tags]))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Tags:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", [[self tags] componentsJoinedByString:@", "]))];
	}
	if (IsNotEmpty([self bookmarks]))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Bookmarks:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", [[self bookmarks] componentsJoinedByString:@", "]))];
	}	
	if (stringIsNonWhiteSpace([self branch]))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Branch:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", [self branch]))];
	}
	if (stringIsNonWhiteSpace(parents_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Parents:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", parents_))];
	}
	if (YES)
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Author:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", author_))];
	}
	if (YES)
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Date:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@   ", [self shortDate]))];
		[verboseEntry appendAttributedString: grayedAttributedString(fstr(@"(%@)\n", [self fullDate]))];
	}

	if (stringIsNonWhiteSpace(fullComment_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Description:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", fullComment_))];
	}
	else if (stringIsNonWhiteSpace(shortComment_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Description:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", shortComment_))];
	}
	
	if (IsNotEmpty(filesAdded_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Added:\t")];
		for (NSString* file in filesAdded_)
		{
			NSTextAttachment* attachment = [DiffTextButtonCell diffButtonAttachmentWithLogEntry:self andFile:file andType:eDiffFileAdded];
			[verboseEntry appendAttributedString: normalAttributedString(@" ")];
			[verboseEntry appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[verboseEntry appendAttributedString: normalAttributedString(@"\n")];
		}
	}
	if (IsNotEmpty(filesModified_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Modified:\t")];
		for (NSString* file in filesModified_)
		{
			NSTextAttachment* attachment = [DiffTextButtonCell diffButtonAttachmentWithLogEntry:self andFile:file andType:eDiffFileChanged];
			[verboseEntry appendAttributedString: normalAttributedString(@" ")];
			[verboseEntry appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[verboseEntry appendAttributedString: normalAttributedString(@"\n")];
		}
	}
	if (IsNotEmpty(filesRemoved_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Removed:\t")];
		for (NSString* file in filesRemoved_)
		{
			NSTextAttachment* attachment = [DiffTextButtonCell diffButtonAttachmentWithLogEntry:self andFile:file andType:eDiffFileRemoved];
			[verboseEntry appendAttributedString: normalAttributedString(@" ")];
			[verboseEntry appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[verboseEntry appendAttributedString: normalAttributedString(@"\n")];
		}
	}
	
	
	return verboseEntry;
}


- (void) fullyLoadEntry
{
	if ([self isFullyLoaded])
		return;

	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", revision_, @"--template", templateStringFull, nil];	// templateStringFull is global set in setupGlobalsForPartsAndTemplate()
	ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:[collection_ rootPath]  logging:eLoggingNone];
	NSArray* lines = [hgLogResults.outStr componentsSeparatedByString:entrySeparator];
	[self loadLogResultLineFull:[lines objectAtIndex:0]];
	

	NSMutableArray* modified = nil;
	NSMutableArray* added    = nil;
	NSMutableArray* removed  = nil;
	NSString* revisionNumbers = fstr(@"%@%:%@", [self firstParent], revision_);

	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", @"--rev", revisionNumbers, @"--added", @"--removed", @"--modified", nil];
	ExecutionResult* hgStatusResults = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:[collection_ rootPath]  logging:eLoggingNone];
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
	filesAdded_	   = [NSArray arrayWithArray:added];
	filesModified_ = [NSArray arrayWithArray:modified];
	filesRemoved_  = [NSArray arrayWithArray:removed];	
}


- (void) loadAndDisplayFormattedVerboseEntryIn:(id)container
{
	if ([self isFullyLoaded])
	{
		if ([container isKindOfClass:[NSTextView class]])
			[[container textStorage] setAttributedString:[self formattedVerboseEntry]];
		return;
	}

	if (loadStatus_ == eLogEntryLoadedPending || loadStatus_ == eLogEntryLoadedPartially)
	{
		dispatch_async(globalQueue(), ^{
			[self fullyLoadEntry];
			if ([container isKindOfClass:[NSTextView class]])
				[[container textStorage] setAttributedString:[self formattedVerboseEntry]];
		});
	}
}


- (NSAttributedString*) formattedBriefEntry
{
	[self fullyLoadEntry];
	NSMutableAttributedString* verboseEntry = [[NSMutableAttributedString alloc] init];
	[verboseEntry appendAttributedString: categoryAttributedString(@"Commit:\t")];
	[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@ ", revision_))];
	[verboseEntry appendAttributedString: grayedAttributedString(fstr(@"(%@)", author_))];
	[verboseEntry appendAttributedString: normalAttributedString(fstr(@", %@\n", [self shortDate]))];
	[verboseEntry appendAttributedString: categoryAttributedString(@"Description:\t")];
	[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", fullComment_))];

	return verboseEntry;
}


- (NSString*) fullCommentSynchronous
{
	if (loadStatus_ == eLogEntryLoadedPending || loadStatus_ == eLogEntryLoadedPartially)
	{
		NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", revision_, @"--template", templateStringFull, nil];	// templateStringFull is global set in setupGlobalsForPartsAndTemplate()
		ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:[collection_ rootPath]  logging:eLoggingNone];
		NSArray* lines = [hgLogResults.outStr componentsSeparatedByString:entrySeparator];
		[self loadLogResultLineFull:[lines objectAtIndex:0]];
	}
	return fullComment_;
}

- (id) labelsAndShortComment
{
	if (IsEmpty(bookmarks_) && IsEmpty(tags_) && IsEmpty(branch_))
		return shortComment_;

	NSMutableAttributedString* str = [[NSMutableAttributedString alloc]init];
	for (NSString* bookmark in bookmarks_)
	{
		LabelData* label = [[collection_ bookmarkToLabelDictionary] objectForKey:bookmark];
		if (label)
		{
			NSTextAttachment* attachment = [LabelTextButtonCell labelButtonAttachmentWithLabel:label andLogEntry:self];
			[str appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[str appendAttributedString: [NSAttributedString string:@" " withAttributes:smallSystemFontAttributes]];
		}
	}
	for (NSString* tag in tags_)
	{
		LabelData* label = [[collection_ tagToLabelDictionary] objectForKey:tag];
		if (label)
		{
			NSTextAttachment* attachment = [LabelTextButtonCell labelButtonAttachmentWithLabel:label andLogEntry:self];
			[str appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[str appendAttributedString: [NSAttributedString string:@" " withAttributes:smallSystemFontAttributes]];
		}
	}
	if (branch_)
	{
		LabelData* label = [[collection_ branchToLabelDictionary] objectForKey:branch_];
		if (label)
		{
			NSTextAttachment* attachment = [LabelTextButtonCell labelButtonAttachmentWithLabel:label andLogEntry:self];
			[str appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[str appendAttributedString: [NSAttributedString string:@" " withAttributes:smallSystemFontAttributes]];
		}
	}
	if (shortComment_)
		[str appendAttributedString:[NSAttributedString string:shortComment_ withAttributes:smallSystemFontAttributes]];
	return str;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Description
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) description
{
	return fstr(@"LogEntry: rev %@, parents %@, comment %@, status %d", revision_, parents_, shortComment_, loadStatus_);
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Generation of Attributed Strings
// -----------------------------------------------------------------------------------------------------------------------------------------

const float theIndent = 100.0;
const float theFirstLineIndent = 15.0;

NSDictionary* categoryFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSTextTab* tabstop = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:theIndent];
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		[paragraphStyle setHeadIndent:theIndent];
		[paragraphStyle setFirstLineHeadIndent:theFirstLineIndent];
		[paragraphStyle setTabStops: [NSArray arrayWithObject:tabstop]];
		
		NSColor* textColor = [NSColor colorWithDeviceRed:(180.0/255.0) green:(180.0/255.0) blue:(180.0/255.0) alpha:1.0];
		
		NSFont* font = [NSFont fontWithName:@"Helvetica-Bold"  size:[NSFont systemFontSize]];
		
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	return theDictionary;
}

NSDictionary* normalFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		[paragraphStyle setHeadIndent:theIndent];
		[paragraphStyle setFirstLineHeadIndent:theIndent];
		NSTextTab* tabstop = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:theIndent];
		[paragraphStyle setTabStops: [NSArray arrayWithObject:tabstop]];	// Add a tab stop.
		
		NSFont* font = [NSFont fontWithName:@"Helvetica"  size:[NSFont systemFontSize]];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	return theDictionary;
}

NSDictionary* grayedFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSTextTab* tabstop = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:theIndent];
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		[paragraphStyle setHeadIndent:theIndent];
		[paragraphStyle setFirstLineHeadIndent:theIndent];
		[paragraphStyle setTabStops: [NSArray arrayWithObject:tabstop]];
		
		NSColor* textColor = [NSColor colorWithDeviceRed:(180.0/255.0) green:(180.0/255.0) blue:(180.0/255.0) alpha:1.0];
		
		NSFont* font = [NSFont fontWithName:@"Helvetica"  size:[NSFont systemFontSize]];
		
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	return theDictionary;
}


NSAttributedString* categoryAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:categoryFontAttributes()]; }
NSAttributedString*   normalAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:normalFontAttributes()]; }
NSAttributedString*   grayedAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:grayedFontAttributes()]; }

