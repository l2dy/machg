//
//  LogEntry.m
//  MacHg
//
//  Created by Jason Harris on 7/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LogEntry.h"
#import "LogRecord.h"
#import "RepositoryData.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "LabelData.h"
#import "TextButtonCell.h"
#import "DiffTextButtonCell.h"
#import "LabelTextButtonCell.h"
#import "ParentTextButtonCell.h"
#import "FSNodeInfo.h"





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Local Statics
// ------------------------------------------------------------------------------------

static NSArray*  namesOfLogEntryParts = nil;
NSString* templateLogEntryString      = nil;
NSString* const logEntrySeparator     = @"\n";
NSString* const logEntryPartSeparator = @"|";
NSString* const incompleteChangeset = @"IncompleteChangeset";

static int logEntryPartChangeset;
static int logEntryPartParents;
static int logEntryPartRevision;



// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Local Utilities
// ------------------------------------------------------------------------------------

void setupGlobalsForLogEntryPartsAndTemplate()
{
	NSArray* templateParts = @[ @"{rev}",    @"{parents}", @"{node}"];
	namesOfLogEntryParts   = @[ @"revision", @"parents",   @"changeset"];
	templateLogEntryString = [[templateParts componentsJoinedByString:logEntryPartSeparator] stringByAppendingString:logEntrySeparator];

	logEntryPartChangeset  = [namesOfLogEntryParts indexOfObject:@"changeset"];
	logEntryPartParents    = [namesOfLogEntryParts indexOfObject:@"parents"];
	logEntryPartRevision   = [namesOfLogEntryParts indexOfObject:@"revision"];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  LogEntry
// ------------------------------------------------------------------------------------
// MARK: -

@implementation LogEntry

@synthesize		loadStatus = loadStatus_;
@synthesize		revision = revision_;
@synthesize 	parentsArray  = parentsArray_;
@synthesize 	childrenArray = childrenArray_;
@synthesize		changeset = changeset_;
@synthesize		fullRecord = fullRecord_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initializers
// ------------------------------------------------------------------------------------

- (id) initForCollection:(RepositoryData*)collection
{
	self = [super init];
	if (self)
	{
		loadStatus_ = eLogEntryLoadedNone;
		collection_ = collection;
		revision_ = nil;
		parentsArray_ = nil;
		childrenArray_ = nil;
		changeset_ = nil;
		fullRecord_ = nil;
	}
    
	return self;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Derived information
// ------------------------------------------------------------------------------------

- (NSArray*) labels { return collection_.revisionNumberToLabels[self.revision]; }

- (NSArray*) tags
{
	NSArray* labels = self.labels;
	if (IsEmpty(labels))
		return [[NSArray alloc]init];
	return [LabelData filterLabelsAndExtractNames:labels byType:eTagLabel];
}

- (NSArray*) bookmarks
{
	NSArray* labels = self.labels;
	if (IsEmpty(labels))
		return [[NSArray alloc]init];
	return [LabelData filterLabelsAndExtractNames:labels byType:eBookmarkLabel];
}

- (NSString*) branchHead
{
	NSArray* labels = self.labels;
	if (IsEmpty(labels))
		return @"";
	NSArray* branchLabels = [LabelData filterLabels:labels byType:eBranchLabel];
	LabelData* branchHeahLabel = IsNotEmpty(branchLabels) ? branchLabels[0] : nil;
	return IsNotEmpty(branchHeahLabel) ? branchHeahLabel.name : @"";
}

- (BOOL) isClosedBranchHead
{
	NSArray* labels = self.labels;
	if (IsEmpty(labels))
		return NO;
	NSArray* branchLabels = [LabelData filterLabels:labels byType:eClosedBranch];
	return IsNotEmpty(branchLabels);
}

- (NSString*) labelsString
{
	NSArray* labels = self.labels;
	if (IsEmpty(labels))
		return @"";
	NSArray* names = [LabelData filterLabelsAndExtractNames:labels byType:eNotOpenHead];
	return [names componentsJoinedByString:@", "];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Constructors
// ------------------------------------------------------------------------------------

+ (LogEntry*) fromLogEntryResultLine:(NSString*)line  forRepositoryData:(RepositoryData*)collection
{
	LogEntry* entry = [[LogEntry alloc] initForCollection:collection];
	[entry loadLogEntryResultLine:line];
	return (entry.loadStatus != eLogEntryLoadedNone) ? entry : nil;
}

+ (LogEntry*) pendingLogEntryForRevision:(NSNumber*)revision  forRepositoryData:collection
{
	LogEntry* entry = [[LogEntry alloc] initForCollection:collection];
	entry.revision = revision;
	entry.loadStatus = eLogEntryLoading;
	return entry;
}

+ (LogEntry*) unfinishedEntryForRevision:(NSNumber*)revision  forRepositoryData:collection
{
	LogEntry* entry = [[LogEntry alloc] initForCollection:collection];
	entry.revision = revision;
	NSNumber* parent1 = [collection getHGParent1Revision];
	NSNumber* parent2 = [collection getHGParent2Revision];
	if (!parent1)
		parent1 = intAsNumber(numberAsInt(revision) -1);
	NSArray* hgParentsArray = parent2 ? @[parent1,parent2] : @[parent1];
	entry.parentsArray = hgParentsArray;
	entry.loadStatus = eLogEntryLoaded;
	entry.changeset = incompleteChangeset;
	entry.fullRecord = LogRecord.unfinishedRecord;
	return entry;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Flesh Out LogEntry
// ------------------------------------------------------------------------------------

- (void) loadLogEntryResultLine:(NSString*)line
{
	static NSString* revHex = @"(\\d+):([0-9a-fA-F]{12})";

	int itemCount  = namesOfLogEntryParts.count;
	NSArray* parts = [line componentsSeparatedByString:logEntryPartSeparator];
	if (parts.count < itemCount)
		return;
	
	[self setChangeset:parts[logEntryPartChangeset]];
	[self setRevision:stringAsNumber(parts[logEntryPartRevision])];

	NSString* parents = parts[logEntryPartParents];
	if (IsEmpty(parents))
	{
		NSInteger revisionInt = numberAsInt(revision_);
		if (revisionInt > 0)
			parentsArray_ = @[ intAsNumber(revisionInt - 1) ];
		else
			parentsArray_ = nil;
	}
	else
	{
		NSMutableArray* parentRevs       = [[NSMutableArray alloc]init];
		[parents enumerateStringsMatchedByRegex:revHex usingBlock:
		 ^(NSInteger captureCount, NSString* const capturedStrings[captureCount], const NSRange capturedRanges[captureCount], volatile BOOL* const stop) {
			 [parentRevs       addObject:stringAsNumber(capturedStrings[1])];
		 }];
		parentsArray_ = [NSArray arrayWithArray:parentRevs];
	}
	
	self.loadStatus = eLogEntryLoaded;
}

- (void) fullyLoadEntry
{
	if (!changeset_)
		return;
	if (!fullRecord_)
		fullRecord_ = [LogRecord createPendingEntryForChangeset:changeset_];
	[fullRecord_ fillFilesOfLogRecordForRepository:collection_];
	[fullRecord_ fillDetailsOfLogRecordForRepository:collection_];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Modify Children of Entry
// ------------------------------------------------------------------------------------

- (void) addChildRevisionNum:(NSNumber*)childRevNum
{
	if (!childRevNum)
		return;
	if (!childrenArray_)
		childrenArray_ = @[childRevNum];
	else if (![childrenArray_ containsObject:childRevNum])
		childrenArray_ = [childrenArray_ arrayByAddingObject:childRevNum];
}

- (void) removeChildRevisionNum:(NSNumber*)childRevNum
{
	if (childRevNum && [childrenArray_ containsObject:childRevNum])
	{
		NSMutableArray* newChildren = [NSMutableArray arrayWithArray:childrenArray_];
		[newChildren removeObjectIdenticalTo:childRevNum];
		childrenArray_ = newChildren;
	}
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Query the LogEntry
// ------------------------------------------------------------------------------------

- (RepositoryData*) repositoryData		{ return collection_; }
- (NSInteger)	childCount				{ return childrenArray_.count; }
- (NSInteger)	parentCount				{ return parentsArray_.count; }
- (BOOL)		hasMultipleParents		{ return parentsArray_.count > 1; }
- (NSArray*)	parentsOfEntry			{ return parentsArray_; }
- (NSArray*)	childrenOfEntry			{ return childrenArray_; }
- (NSString*)	revisionStr				{ return numberAsString(revision_); }
- (NSInteger)	revisionInt				{ return numberAsInt(revision_); }
- (NSInteger)	ithChildRev:(NSInteger)i			{ return (0 <= i && self.childCount  > i) ? numberAsInt(childrenArray_[i]) : NSNotFound; }
- (NSInteger)	ithParentRev:(NSInteger)i			{ return (0 <= i && self.parentCount > i) ? numberAsInt(parentsArray_[i]) : NSNotFound; }
- (BOOL)	    revIsDirectParent:(NSInteger)rev	{ return rev == numberAsInt(revision_) - 1; }
- (BOOL)	    revIsDirectChild:(NSInteger)rev		{ return rev == numberAsInt(revision_) + 1; }
- (BOOL)		isEqualToEntry:(LogEntry*)entry		{ return [changeset_ isEqualToString:entry.changeset] && [parentsArray_ isEqualToArray:entry.parentsOfEntry]; }
- (NSNumber*)	firstParent				{ return parentsArray_.count > 0 ? parentsArray_[0] : nil; }
- (NSNumber*)	secondParent			{ return parentsArray_.count > 1 ? parentsArray_[1] : nil; }
- (NSNumber*)   minimumParent
{
	switch (parentsArray_.count)
	{
		case 1: return parentsArray_[0];
		case 2: return minimumNumber(parentsArray_[0], parentsArray_[1]);
	}
	return nil;
}






// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Status and Updating
// ------------------------------------------------------------------------------------

- (NSString*)	shortChangeset			{ return [changeset_ substringToIndex:MIN(12,changeset_.length)]; }
- (BOOL)	    isLoading				{ return loadStatus_ == eLogEntryLoading; }
- (BOOL)	    isLoaded				{ return loadStatus_ == eLogEntryLoaded; }
- (BOOL)	    isFullyLoaded			{ return loadStatus_ == eLogEntryLoaded && fullRecord_ && fullRecord_.isFullyLoaded; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Query the LogRecord
// ------------------------------------------------------------------------------------

- (NSString*) author			{ return fullRecord_.author; }
- (NSString*) fullAuthor		{ return fullRecord_.fullAuthor; }
- (NSString*) branch            { return stringIsNonWhiteSpace(fullRecord_.branch) ? fullRecord_.branch : @"default"; }
- (NSString*) shortComment		{ return fullRecord_.shortComment; }
- (NSString*) fullComment		{ return fullRecord_.fullComment; }
- (NSArray*)  filesAdded		{ return fullRecord_.filesAdded; }
- (NSArray*)  filesModified		{ return fullRecord_.filesModified; }
- (NSArray*)  filesRemoved		{ return fullRecord_.filesRemoved; }

- (NSString*) shortDate			{ return fullRecord_.shortDate; }
- (NSString*) fullDate			{ return fullRecord_.fullDate; }
- (NSString*) isoDate			{ return fullRecord_.isoDate; }
- (NSDate*)   rawDate			{ return fullRecord_.rawDate; }




// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Formatted Entries
// ------------------------------------------------------------------------------------


- (NSAttributedString*) formattedVerboseEntry
{
	[self fullyLoadEntry];
	NSMutableAttributedString* verboseEntry = [[NSMutableAttributedString alloc] init];
	if (YES)
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"\nChangeset:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@ : %@\n", revision_, self.shortChangeset))];
	}
	if (IsNotEmpty(self.tags))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Tags:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", [self.tags componentsJoinedByString:@", "]))];
	}
	if (IsNotEmpty(self.bookmarks))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Bookmarks:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", [self.bookmarks componentsJoinedByString:@", "]))];
	}	
	if (stringIsNonWhiteSpace(self.branchHead))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Branch Head:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", self.branchHead))];
	}
	if (IsNotEmpty(self.parentsOfEntry))
	{
		[verboseEntry appendAttributedString: categoryAttributedString( (self.parentsOfEntry.count > 1) ? @"Parents:\t" : @"Parent:\t")];
		for (NSNumber* parent in self.parentsOfEntry)
		{
			if (IsNotEmpty(parent))
			{
				NSTextAttachment* attachment = [ParentTextButtonCell parentButtonAttachmentWithText:numberAsString(parent) andLogEntry:self];
				[verboseEntry appendAttributedString: normalAttributedString(@" ")];
				[verboseEntry appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			}
		}
		[verboseEntry appendAttributedString: normalAttributedString(@"\n")];
	}
//	if (stringIsNonWhiteSpace(children_) && (self.childCount > 1 || ![self revIsDirectChild:[self ithChildRev:0]]))
//	{
//		[verboseEntry appendAttributedString: categoryAttributedString(@"Children:\t")];
//		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", children_))];
//	}
	
	if (!self.isFullyLoaded)
		return verboseEntry;

	if (stringIsNonWhiteSpace(self.fullAuthor))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Author:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", self.fullAuthor))];
	}
	else
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Author:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", nonNil(self.author)))];
	}
	
	// branches is always non-null/non-empty
	[verboseEntry appendAttributedString: categoryAttributedString(@"Branch:\t")];
	[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", self.branch))];

	if (IsNotEmpty(self.rawDate))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Date:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@   ", self.shortDate))];
		[verboseEntry appendAttributedString: grayedAttributedString(fstr(@"(%@)\n", self.fullDate))];
	}

	if (stringIsNonWhiteSpace(self.fullComment))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Description:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", self.fullComment))];
	}
	else if (stringIsNonWhiteSpace(self.shortComment))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Description:\t")];
		[verboseEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", self.shortComment))];
	}
	
	if (IsNotEmpty(self.filesAdded))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Added:\t")];
		for (NSString* file in self.filesAdded)
		{
			NSTextAttachment* attachment = [DiffTextButtonCell diffButtonAttachmentWithLogEntry:self andFile:file andType:eDiffFileAdded];
			[verboseEntry appendAttributedString: normalAttributedString(@" ")];
			[verboseEntry appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[verboseEntry appendAttributedString: normalAttributedString(@"\n")];
		}
	}
	if (IsNotEmpty(self.filesModified))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Modified:\t")];
		for (NSString* file in self.filesModified)
		{
			NSTextAttachment* attachment = [DiffTextButtonCell diffButtonAttachmentWithLogEntry:self andFile:file andType:eDiffFileChanged];
			[verboseEntry appendAttributedString: normalAttributedString(@" ")];
			[verboseEntry appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[verboseEntry appendAttributedString: normalAttributedString(@"\n")];
		}
	}
	if (IsNotEmpty(self.filesRemoved))
	{
		[verboseEntry appendAttributedString: categoryAttributedString(@"Removed:\t")];
		for (NSString* file in self.filesRemoved)
		{
			NSTextAttachment* attachment = [DiffTextButtonCell diffButtonAttachmentWithLogEntry:self andFile:file andType:eDiffFileRemoved];
			[verboseEntry appendAttributedString: normalAttributedString(@" ")];
			[verboseEntry appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
			[verboseEntry appendAttributedString: normalAttributedString(@"\n")];
		}
	}

	return verboseEntry;
}


- (NSAttributedString*) formattedBriefEntry
{
	NSMutableAttributedString* briefEntry = [[NSMutableAttributedString alloc] init];
	[briefEntry appendAttributedString: categoryAttributedString(@"Commit:\t")];
	[briefEntry appendAttributedString: normalAttributedString(fstr(@"%@ ", revision_))];
	[briefEntry appendAttributedString: grayedAttributedString(fstr(@"(%@)", self.author))];
	[briefEntry appendAttributedString: normalAttributedString(fstr(@", %@\n", self.shortDate))];
	[briefEntry appendAttributedString: categoryAttributedString(@"Description:\t")];
	[briefEntry appendAttributedString: normalAttributedString(fstr(@"%@\n", self.fullComment))];
	return briefEntry;
}


- (id) labelsAndShortComment
{
	NSArray* labels = self.labels;
	if (IsEmpty(labels))
		return self.shortComment;


	NSMutableAttributedString* str = [[NSMutableAttributedString alloc]init];
	for (LabelData* label in [LabelData filterLabels:labels byType:eBookmarkLabel])
	{
		NSTextAttachment* attachment = [LabelTextButtonCell labelButtonAttachmentWithLabel:label andLogEntry:self];
		[str appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
		[str appendAttributedString: [NSAttributedString string:@" " withAttributes:smallSystemFontAttributes]];
	}
	for (LabelData* label in [LabelData filterLabels:labels byType:eTagLabel])
	{
		NSTextAttachment* attachment = [LabelTextButtonCell labelButtonAttachmentWithLabel:label andLogEntry:self];
		[str appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
		[str appendAttributedString: [NSAttributedString string:@" " withAttributes:smallSystemFontAttributes]];
	}
	for (LabelData* label in [LabelData filterLabels:labels byType:eBranchLabel])
	{
		NSTextAttachment* attachment = [LabelTextButtonCell labelButtonAttachmentWithLabel:label andLogEntry:self];
		[str appendAttributedString: [NSAttributedString attributedStringWithAttachment:attachment]];
		[str appendAttributedString: [NSAttributedString string:@" " withAttributes:smallSystemFontAttributes]];
	}
	if (self.shortComment)
		[str appendAttributedString:[NSAttributedString string:self.shortComment withAttributes:smallSystemFontAttributes]];
	return str;
}



// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Description
// ------------------------------------------------------------------------------------

- (NSString*) description
{
	NSString* revString = revision_ ? fstr(@"%@", revision_) : @"nil";
	NSString* parentsArrayString = parentsArray_ ? fstr(@"%@", parentsArray_) : @"nil";
	NSString* childrenArrayString = childrenArray_ ? fstr(@"%@", childrenArray_) : @"nil";

	NSString* statusString;
	switch (loadStatus_)
	{
		case eLogEntryLoadedNone:				statusString = @"eLogEntryLoadedNone";				break;
		case eLogEntryLoading:					statusString = @"eLogEntryLoading";					break;
		case eLogEntryLoaded:					statusString = @"eLogEntryLoaded";					break;
		default:								statusString = @"error";							break;
	}

	return fstr(@"LogEntry: rev %@, parents %@, children %@, status %@", revString, parentsArrayString, childrenArrayString, statusString);
}

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Generation of Attributed Strings
// ------------------------------------------------------------------------------------

const float theIndent = 100.0;
const float theFirstLineIndent = 15.0;

NSDictionary* categoryFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSTextTab* tabstop = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:theIndent];
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		paragraphStyle.paragraphStyle = NSParagraphStyle.defaultParagraphStyle;
		paragraphStyle.headIndent = theIndent;
		paragraphStyle.firstLineHeadIndent = theFirstLineIndent;
		[paragraphStyle setTabStops: @[tabstop]];
		
		NSColor* textColor = rgbColor255(180.0, 180.0, 180.0);
		
		NSFont* font = [NSFont fontWithName:@"Helvetica-Bold"  size:NSFont.systemFontSize];
		
		theDictionary = @{NSFontAttributeName: font, NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName: paragraphStyle};
	}
	return theDictionary;
}

NSDictionary* normalFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		paragraphStyle.paragraphStyle = NSParagraphStyle.defaultParagraphStyle;
		paragraphStyle.headIndent = theIndent;
		paragraphStyle.firstLineHeadIndent = theIndent;
		NSTextTab* tabstop = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:theIndent];
		[paragraphStyle setTabStops: @[tabstop]];	// Add a tab stop.
		
		NSFont* font = [NSFont fontWithName:@"Helvetica"  size:NSFont.systemFontSize];
		theDictionary = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle};
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
		paragraphStyle.paragraphStyle = NSParagraphStyle.defaultParagraphStyle;
		paragraphStyle.headIndent = theIndent;
		paragraphStyle.firstLineHeadIndent = theIndent;
		[paragraphStyle setTabStops: @[tabstop]];
		
		NSColor* textColor = rgbColor255(180.0, 180.0, 180.0);
		
		NSFont* font = [NSFont fontWithName:@"Helvetica"  size:NSFont.systemFontSize];
		
		theDictionary = @{NSFontAttributeName: font, NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName: paragraphStyle};
	}
	return theDictionary;
}


NSAttributedString* categoryAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:categoryFontAttributes()]; }
NSAttributedString*   normalAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:normalFontAttributes()]; }
NSAttributedString*   grayedAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:grayedFontAttributes()]; }

