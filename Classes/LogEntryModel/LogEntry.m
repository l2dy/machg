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


static NSArray*  namesOfPartsShort  = nil;
static NSArray*  namesOfPartsFull   = nil;
NSString* templateStringShort = nil;
NSString* templateStringFull  = nil;
NSString* const entrySeparator      = @"\n\n‹‡›\n";			// We just need to choose two strings which will never be used inside the *comment* of a commit. (Its not disastrous if
NSString* const entryPartSeparator	= @"\n‹,›\n";			// they are though its just the entry for that will display missing....)

void setupGlobalsForPartsAndTemplate()
{
	// For some crazy reason you need to use {branches} to get the branch in the log command. Why?!? Ie you can test this with
	// 'hg log --template "{branches}\n{branch}" --rev tip'
	// This of course contradicts the output of 'hg branch' and 'hg branches'
	NSArray* templateParts;
	templateParts       = [NSArray arrayWithObjects:@"{rev}",    @"{author|person}", @"{date|age}", @"{parents}", @"{node|short}", @"{desc|firstline}", nil];
	namesOfPartsShort   = [NSArray arrayWithObjects:@"revision", @"author",          @"shortDate",  @"parents",   @"changeset",    @"shortComment",     nil];
	templateStringShort = [[templateParts componentsJoinedByString:entryPartSeparator] stringByAppendingString:entrySeparator];

	templateParts       = [NSArray arrayWithObjects:@"{rev}",    @"{author|person}", @"{date|age}", @"{date|isodate}", @"{parents}", @"{node|short}", @"{file_adds}", @"{file_mods}",   @"{file_dels}",   @"{desc|firstline}", @"{desc}",      nil];
	namesOfPartsFull    = [NSArray arrayWithObjects:@"revision", @"author",          @"shortDate",  @"fullDate",       @"parents",   @"changeset",    @"filesAdded",  @"filesModified", @"filesRemoved",  @"shortComment",     @"fullComment", nil];
	templateStringFull  = [[templateParts componentsJoinedByString:entryPartSeparator] stringByAppendingString:entrySeparator];
}

@implementation LogEntry

@synthesize		loadStatus = loadStatus_;
@synthesize		revision = revision_;
@synthesize 	author = author_;
@synthesize 	shortDate = shortDate_;
@synthesize 	fullDate = fullDate_;
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
		shortDate_ = nil;
		fullDate_ = nil;
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
	[entry setShortDate:@"now"];
	[entry setFullDate:@"now"];
	[entry setLoadStatus:eLogEntryLoadedFully];
	[entry setAuthor:@""];
	entry->branch_ = @"";
	entry->tags_ = [[NSArray alloc]init];
	[entry setChangeset:@""];
	[entry setFilesAdded:@""];
	[entry setFilesModified:@""];
	[entry setFilesRemoved:@""];
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Formatted Entries
// -----------------------------------------------------------------------------------------------------------------------------------------


- (NSAttributedString*) composeFormattedVerboseEntry
{
	NSMutableAttributedString* verboseEntry = [[NSMutableAttributedString alloc] init];
	if (YES)
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"\nChangeset:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@ : %@\n", revision_, [self changesetInShortForm]])];
	}
	if (IsNotEmpty([self tags]))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Tags:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", [[self tags] componentsJoinedByString:@", "]])];
	}
	if (IsNotEmpty([self bookmarks]))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Bookmarks:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", [[self bookmarks] componentsJoinedByString:@", "]])];
	}	
	if (stringIsNonWhiteSpace([self branch]))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Branch:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", [self branch]])];
	}
	if (stringIsNonWhiteSpace(parents_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Parents:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", parents_])];
	}
	if (YES)
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Author:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", author_])];
	}
	if (YES)
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Date:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@   ", shortDate_])];
		[verboseEntry appendAttributedString: grayedAttributedString([NSString stringWithFormat:@"(%@)\n", fullDate_])];
	}
	if (stringIsNonWhiteSpace(filesAdded_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Added:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", filesAdded_])];
	}
	if (stringIsNonWhiteSpace(filesModified_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Modified:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", filesModified_])];
	}
	if (stringIsNonWhiteSpace(filesRemoved_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Removed:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", filesRemoved_])];
	}
	
//	// Create a file wrapper with an image.
//	NSString * imgName = @"GoodNetwork.png";
//	NSFileWrapper *fwrap = [[[NSFileWrapper alloc] initRegularFileWithContents:
//							 [[NSImage imageNamed:@"GoodNetwork.png"] TIFFRepresentation]] autorelease];
//	[fwrap setFilename:imgName];
//	[fwrap setPreferredFilename:imgName];
//	
//	// Create an attachment with the file wrapper
//	NSTextAttachment * ta = [[[NSTextAttachment alloc] initWithFileWrapper:fwrap] autorelease];
//	
//	// Append the attachment to the end of the attributed string
//	// (assumes "attrStr" already exists).
//	[verboseEntry appendAttributedString:[NSAttributedString attributedStringWithAttachment:ta]];

	
	// Create a file wrapper with an image.
	NSString * imgName = @"GoodNetwork.png";
	NSFileWrapper *fwrap = [[[NSFileWrapper alloc] initRegularFileWithContents:
							 [[NSImage imageNamed:@"GoodNetwork.png"] TIFFRepresentation]] autorelease];
	[fwrap setFilename:imgName];
	[fwrap setPreferredFilename:imgName];
	
	// Create an attachment with the file wrapper
	NSTextAttachment * ta = [[[NSTextAttachment alloc] initWithFileWrapper:fwrap] autorelease];
	TextButtonCell* tbc = [[TextButtonCell alloc] init];
	[tbc setTitle:@"MyButton"];
	[tbc setBezelStyle:NSRoundRectBezelStyle];
	[ta setAttachmentCell:tbc];
	
	// Append the attachment to the end of the attributed string
	// (assumes "attrStr" already exists).
	[verboseEntry appendAttributedString:[NSAttributedString attributedStringWithAttachment:ta]];

	
	
	
	
	if (stringIsNonWhiteSpace(fullComment_))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Description:\t")];
		[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", fullComment_])];
	}
	
	
	return verboseEntry;
}

- (void) displayFormattedVerboseEntryIn:(id)container
{
	if (loadStatus_ == eLogEntryLoadedFully)
	{
		if ([container isKindOfClass:[NSTextView class]])
			[[container textStorage] setAttributedString:[self composeFormattedVerboseEntry]];
		return;
	}

	if (loadStatus_ == eLogEntryLoadedPending || loadStatus_ == eLogEntryLoadedPartially)
	{
		dispatch_async(globalQueue(), ^{
			NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", revision_, @"--template", templateStringFull, nil];	// templateStringFull is global set in setupGlobalsForPartsAndTemplate()
			ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:[collection_ rootPath]  logging:eLoggingNone];
			
			NSArray* lines = [hgLogResults.outStr componentsSeparatedByString:entrySeparator];
			[self loadLogResultLineFull:[lines objectAtIndex:0]];
			if ([container isKindOfClass:[NSTextView class]])
				[[container textStorage] setAttributedString:[self composeFormattedVerboseEntry]];
		});
	}
}


- (NSAttributedString*) formattedBriefEntry
{
	if (loadStatus_ == eLogEntryLoadedPending || loadStatus_ == eLogEntryLoadedPartially)
	{
		NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--rev", revision_, @"--template", templateStringFull, nil];	// templateStringFull is global set in setupGlobalsForPartsAndTemplate()
		ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:[collection_ rootPath]  logging:eLoggingNone];
		
		NSArray* lines = [hgLogResults.outStr componentsSeparatedByString:entrySeparator];
		[self loadLogResultLineFull:[lines objectAtIndex:0]];
	}
	
	NSMutableAttributedString* verboseEntry = [[NSMutableAttributedString alloc] init];
	[verboseEntry appendAttributedString: categoryAttributedString(@"Commit:\t")];
	[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@ ", revision_])];
	[verboseEntry appendAttributedString: grayedAttributedString([NSString stringWithFormat:@"(%@)", author_])];
	[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@", %@\n", shortDate_])];
	[verboseEntry appendAttributedString: categoryAttributedString(@"Description:\t")];
	[verboseEntry appendAttributedString: normalAttributedString([NSString stringWithFormat:@"%@\n", fullComment_])];

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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Description
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) description
{
	return [NSString stringWithFormat:@"LogEntry: rev %@, parents %@, comment %@, status %d", revision_, parents_, shortComment_, loadStatus_];
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

