//
//  PatchData.m
//  MacHg
//
//  Created by Jason Harris on 4/23/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import "PatchData.h"
#import "DiffMatchPatch.h"
#import "TaskExecutions.h"



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HTMLizng Differences
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -


static NSString* encodeForHTML(NSString* line)
{
	NSMutableString* text = [line mutableCopy];
	[text replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@"'" withString:@"\x27" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@"\"" withString:@"\x22" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	return text;
}



	
static NSArray* splitTermination(NSString* str)
{
	static NSString* linebreak = nil;
	if (!linebreak)
		linebreak   = [NSString stringWithUTF8String:"(?:\\r\\n|[\\n\\v\\f\\r\302\205\\p{Zl}\\p{Zp}])"];

	NSString* firstChars = [str substringToIndex:[str length] -1];
	NSString* lastChar   = [str substringFromIndex:[str length] -1];
	if (lastChar && [lastChar isMatchedByRegex:linebreak])
		return [NSArray arrayWithObjects:firstChars, lastChar, nil];
	return [NSArray arrayWithObject:str];
}

static NSString* collapseLines(NSArray* originalLines, NSMutableArray* diffLines, NSString* prefix)
{
	NSMutableString* result = [[NSMutableString alloc]init];
	NSString* formatString = [prefix isEqualToString:@"+"] ? @"<insert>%@</insert>" : @"<delete>%@</delete>";
	for (NSString* line in originalLines)
	{
		NSInteger len = [line length];
		NSInteger popped = 0;
		[result appendString:prefix];
		while (popped < len)
		{
			Diff* diff = [diffLines popFirst];
			if (popped + [diff.text length] > len)
			{
				NSString* first = [diff.text substringToIndex:len-popped];
				NSString* rest  = [diff.text substringFromIndex:len-popped];
				Diff* firstDiff = [Diff diffWithOperation:diff.operation andText:first];
				Diff* restDiff  = [Diff diffWithOperation:diff.operation andText:rest];
				[diffLines insertObject:restDiff atIndex:0];
				[diffLines insertObject:firstDiff atIndex:0];
				continue;
			}
			NSString* encoded = encodeForHTML(diff.text);
			if (diff.operation == DIFF_EQUAL)
				[result appendString:encoded];
			else if (popped + [diff.text length] < len)
				[result appendString:fstr(formatString, encoded)];
			else
			{
				NSArray* split = splitTermination(encoded);
				[result appendString:fstr(formatString, [split firstObject])];
				if ([split count] > 1)
					[result appendString:[split lastObject]];
			}
			popped += [diff.text length];
		}
	}
	return result;
}


// Given the lines on the left and the lines on the right, create the subline diff and reconstruct the left lines with
// <delete>...</delete>'s and the right lines with <insert>...</insert>'s in them. Also reinclude the prefix "-" and "+"
static NSString* htmlizedDifference(NSMutableArray* leftLines, NSMutableArray* rightLines)
{
	DiffMatchPatch* dmp = [DiffMatchPatch new];
	dmp.Diff_Timeout = 0;				
	NSString* left  = [leftLines  componentsJoinedByString:@""];
	NSString* right = [rightLines componentsJoinedByString:@""];
	NSMutableArray* newRightLines = [[NSMutableArray alloc]init];
	NSMutableArray* newLeftLines  = [[NSMutableArray alloc]init];
	NSMutableArray* diffs = [dmp diff_mainOfOldString:left andNewString:right checkLines:NO];
	[dmp diff_cleanupSemantic:diffs];

	// Reconstruct all the left hand sides
	for (Diff* aDiff in diffs)
		switch (aDiff.operation)
		{
			case DIFF_INSERT:									[newRightLines addObject:aDiff];	break;
			case DIFF_DELETE:	[newLeftLines addObject:aDiff];										break;
			case DIFF_EQUAL:	[newLeftLines addObject:aDiff]; [newRightLines addObject:aDiff];	break;
		}
	
	NSString* newLeft  = collapseLines(leftLines,  newLeftLines,  @"-");
	NSString* newRight = collapseLines(rightLines, newRightLines, @"+");
	[leftLines removeAllObjects];
	[rightLines removeAllObjects];
	return fstr(@"%@%@", newLeft, newRight);
}


static NSString* htmlize(NSString* hunk, NSString* hash)
{
	NSMutableArray* lines = [[NSMutableArray alloc]init];		// The patchBody broken into it's lines (each line includes the line ending)
	NSInteger start = 0;
	while (start < [hunk length])
	{
		NSRange nextLine = [hunk lineRangeForRange:NSMakeRange(start, 1)];
		[lines addObject:[hunk substringWithRange:nextLine]];
		start = nextLine.location + nextLine.length;
	}
	
	NSMutableString* processedString = [[NSMutableString alloc]init];
	NSMutableArray* leftLines	= [[NSMutableArray alloc]init];
	NSMutableArray* rightLines	= [[NSMutableArray alloc]init];
	for (NSString* line in lines)
	{
		if ([line isMatchedByRegex:@"^\\+.*"])
			[rightLines addObject:[line substringWithRange:NSMakeRange(1,[line length]-1)]];
		else if ([line isMatchedByRegex:@"^-.*"])
			[leftLines addObject:[line substringWithRange:NSMakeRange(1,[line length]-1)]];
		else
		{
			if (IsNotEmpty(leftLines) || IsNotEmpty(rightLines))
				[processedString appendString:htmlizedDifference(leftLines, rightLines)];
			if ([line isMatchedByRegex:@"^@@.*"])
			{
				NSArray* split = splitTermination(line);
				if ([split count] > 1)
					line = fstr(@"%@ %@%@", [split firstObject], hash, [split lastObject]);
			}
			[processedString appendString:encodeForHTML(line)];
		}
	}
	if (IsNotEmpty(leftLines) || IsNotEmpty(rightLines))
		[processedString appendString:htmlizedDifference(leftLines, rightLines)];
	return processedString;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilePatch
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation FilePatch

- (id) initWithPath:(NSString*)path andHeader:(NSString*)header
{
	self = [super init];
    if (self)
	{
		filePath = path;
		filePatchHeader = header;
		hunks = [[NSMutableArray alloc]init];
		hunkHashes = [[NSMutableArray alloc]init];
		hunkHashesSet = [[NSMutableSet alloc]init];
    }
    return self;
}

+ (FilePatch*) filePatchWithPath:(NSString*)path andHeader:(NSString*)header
{
	return [[FilePatch alloc] initWithPath:path andHeader:header];
}


- (NSString*) finishHunk_hashHunk:(NSMutableArray*)lines
{
	NSMutableString* hashLines = [[NSMutableString alloc]init];
	for (NSString* line in lines)
		if ([line isMatchedByRegex:@"^(\\+|-).*"])
			[hashLines appendString:line];	
	NSString* saltedString = fstr(@"%@:%@", nonNil(filePath), nonNil([hashLines SHA1HashString]));
	NSString* hash = [saltedString SHA1HashString];
	if ([hunkHashesSet containsObject:hash])
	{
		NSString* furtherSaltedHash = [hash stringByAppendingString:intAsString([hunks count])];
		hash = [furtherSaltedHash SHA1HashString];
	}
	return hash;
}

- (void) finishHunk:(NSMutableArray*)lines
{
	if (IsEmpty(lines))
		return;

	NSString* hash = [self finishHunk_hashHunk:lines];	
	NSString* hunk = [lines componentsJoinedByString:@""];
	[hunks addObject:hunk];
	[hunkHashes addObject:hash];
	[hunkHashesSet addObject:hash];
	[lines removeAllObjects];
}

- (NSString*) filterFilePatchWithExclusions:(NSSet*)excludedHunks
{
	NSMutableString* filteredFilePatch = [NSMutableString stringWithString:filePatchHeader];

	// The normal case when this file patch is not filtered at all
	if (IsEmpty(excludedHunks))
	{
		for (NSString* hunk in hunks)
			[filteredFilePatch appendString:hunk];		
		return filteredFilePatch;
	}

	// When some (or all) parts of this file patch are excluded
	BOOL containsIncludedHunk = NO;
	NSInteger hunkCounter = 1;
	for (NSString* hunk in hunks)
	{
		if (![excludedHunks containsObject:intAsString(hunkCounter)])
		{
			containsIncludedHunk = YES;
			[filteredFilePatch appendString:hunk];
		}
		hunkCounter++;
	}
	
	return containsIncludedHunk ? filteredFilePatch : nil;
}


- (NSString*) htmlizedFilePatch
{
	NSMutableString* filteredFilePatch = [NSMutableString stringWithString:filePatchHeader];
	for (NSInteger i = 0; i<[hunks count]; i++)
	{
		NSString* hunk = [hunks objectAtIndex:i];
		NSString* hash = [hunkHashes objectAtIndex:i];
		[filteredFilePatch appendString:htmlize(hunk, hash)];
	}
	return filteredFilePatch;
}


- (NSString *)description
{
	NSMutableString* filteredFilePatch = [NSMutableString stringWithString:filePatchHeader];
	
	for (int i = 0; i<[hunks count]; i++)
	{
		[filteredFilePatch appendString:fstr(@"######## %@ ########\n", [hunkHashes objectAtIndex:i])];
		[filteredFilePatch appendString:[hunks objectAtIndex:i]];		
	}
	return filteredFilePatch;
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchData
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface PatchData (PrivateAPI)
-(void) parseBodyIntoFilePatches;
@end

@implementation PatchData

@synthesize excludedPatchHunksForFilePath = excludedPatchHunksForFilePath_;
@synthesize patchBody = patchBody_;
@synthesize filePatches = filePatches_;


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (PatchData*) initWithDiffContents:(NSString*)contents
{
	excludedPatchHunksForFilePath_ = [[NSMutableDictionary alloc]init];
	filePatchForFilePath_ = [[NSMutableDictionary alloc]init];
	filePatches_ = [[NSMutableArray alloc]init];
	patchBody_ = contents;
	[self parseBodyIntoFilePatches];
	return self;
}

+ (PatchData*) patchDataFromDiffContents:(NSString*)diff
{
	return [[PatchData alloc] initWithDiffContents:diff];
}




//	syntax "patch" "\.(patch|diff)$"
//	color brightgreen "^\+.*"
//	color green "^\+\+\+.*"
//	color lightBlue "^ .*"
//	color lightRed "^-.*"
//	color red "^---.*"
//	color brightyellow "^@@.*"
//	color magenta "^diff.*"

- (NSAttributedString*) patchBodyColorized
{
	NSMutableAttributedString* colorized = [[NSMutableAttributedString alloc]init];
	if (!patchBody_)
		return colorized;
	
	static NSMutableDictionary* lightGreen = nil;
	static NSMutableDictionary* green = nil;
	static NSMutableDictionary* lightBlue = nil;
	static NSMutableDictionary* lightRed = nil;
	static NSMutableDictionary* red = nil;
	static NSMutableDictionary* normal = nil;
	static NSMutableDictionary* linePart = nil;
	static NSMutableDictionary* hunkPart = nil;
	static NSMutableDictionary* headerLine = nil;
	static NSMutableDictionary* diffStatLine = nil;
	static NSMutableDictionary* diffStatHeader = nil;
	static NSMutableDictionary* magenta = nil;

	if (!lightGreen)
	{
		
		static NSDictionary* theDictionary = nil;

		NSFont* font = [NSFont fontWithName:@"Monaco"  size:9];
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		float charWidth = [[font screenFontWithRenderingMode:NSFontDefaultRenderingMode] advancementForGlyph:(NSGlyph) ' '].width;
		[paragraphStyle setDefaultTabInterval:(charWidth * 4)];
		[paragraphStyle setTabStops:[NSArray array]];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
		
		lightGreen		= [theDictionary mutableCopy];
		lightBlue		= [theDictionary mutableCopy];
		lightRed		= [theDictionary mutableCopy];
		green			= [theDictionary mutableCopy];
		red				= [theDictionary mutableCopy];
		linePart		= [theDictionary mutableCopy];
		hunkPart		= [theDictionary mutableCopy];
		magenta			= [theDictionary mutableCopy];
		headerLine		= [theDictionary mutableCopy];
		diffStatLine	= [theDictionary mutableCopy];
		diffStatHeader	= [theDictionary mutableCopy];
		normal			= [theDictionary mutableCopy];

		[lightGreen		setObject:rgbColor255(221.0, 255.0, 221.0) forKey:NSBackgroundColorAttributeName];
		[lightBlue		setObject:rgbColor255(202.0, 238.0, 255.0) forKey:NSBackgroundColorAttributeName];
		[lightRed		setObject:rgbColor255(255.0, 221.0, 221.0) forKey:NSBackgroundColorAttributeName];
		[green			setObject:rgbColor255(160.0, 255.0, 160.0) forKey:NSBackgroundColorAttributeName];
		[red			setObject:rgbColor255(255.0, 160.0, 160.0) forKey:NSBackgroundColorAttributeName];
		[linePart		setObject:rgbColor255(240.0, 240.0, 240.0) forKey:NSBackgroundColorAttributeName];
		[linePart		setObject:rgbColor255(128.0, 128.0, 128.0) forKey:NSForegroundColorAttributeName];
		[hunkPart		setObject:rgbColor255(234.0, 242.0, 245.0) forKey:NSBackgroundColorAttributeName];
		[hunkPart		setObject:rgbColor255(128.0, 128.0, 128.0) forKey:NSForegroundColorAttributeName];
		[headerLine		setObject:rgbColor255(230.0, 230.0, 230.0) forKey:NSBackgroundColorAttributeName];
		[headerLine		setObject:rgbColor255(128.0, 128.0, 128.0) forKey:NSForegroundColorAttributeName];
		[diffStatLine	setObject:rgbColor255(255.0, 253.0, 217.0) forKey:NSBackgroundColorAttributeName];
		[diffStatLine	setObject:rgbColor255(128.0, 128.0, 128.0) forKey:NSForegroundColorAttributeName];
		[diffStatHeader setObject:rgbColor255(255.0, 253.0, 200.0) forKey:NSBackgroundColorAttributeName];
		[diffStatHeader setObject:rgbColor255(128.0, 128.0, 128.0) forKey:NSForegroundColorAttributeName];
		[magenta		setObject:rgbColor255(255.0, 200.0, 255.0) forKey:NSBackgroundColorAttributeName];
		[normal			setObject:rgbColor255(248.0, 248.0, 255.0) forKey:NSBackgroundColorAttributeName];

		NSMutableParagraphStyle* hunkParagraphStyle = [paragraphStyle mutableCopy];
		[hunkParagraphStyle setParagraphSpacingBefore:20];
		[hunkPart		setObject:hunkParagraphStyle forKey:NSParagraphStyleAttributeName];
		
		
		NSMutableParagraphStyle* headerParagraphStyle = [paragraphStyle mutableCopy];
		[headerParagraphStyle setParagraphSpacingBefore:30];
		[headerLine		setObject:[NSFont fontWithName:@"Monaco"  size:15] forKey:NSFontAttributeName];
		[headerLine		setObject:headerParagraphStyle forKey:NSParagraphStyleAttributeName];

		[diffStatHeader	setObject:[NSFont fontWithName:@"Monaco"  size:15] forKey:NSFontAttributeName];
	}

	//ExecutionResult* result = [ShellTask execute:@"/usr/bin/diffstat" withArgs:[NSArray arrayWithObjects:path_, nil] withEnvironment:[TaskExecutions environmentForHg]];
	//if ([result hasNoErrors])
	//{
	//	[colorized appendAttributedString:[NSAttributedString string:@"Patch Statistics\n" withAttributes:diffStatHeader]];
	//	[colorized appendAttributedString:[NSAttributedString string:result.outStr withAttributes:diffStatLine]];
	//}

	
	NSMutableArray* lines = [[NSMutableArray alloc]init];
	NSInteger start = 0;
	while (start < [patchBody_ length])
	{
		NSRange nextLine = [patchBody_ lineRangeForRange:NSMakeRange(start, 1)];
		[lines addObject:[patchBody_ substringWithRange:nextLine]];
		start = nextLine.location + nextLine.length;
	}
	
	for (NSInteger i = 0; i < [lines count] ; i++)
	{
		NSString* line = [lines objectAtIndex:i];
		
		// Detect the header of
		// diff ...
		// --- ...
		// +++ b/<fileName>
		if ([line isMatchedByRegex:@"^diff.*"] && i+2< [lines count])
		{
			NSString* minusLine = [lines objectAtIndex:i+1];
			NSString* addLine   = [lines objectAtIndex:i+2];
			NSString* filePath = nil;
			if ([minusLine isMatchedByRegex:@"^---.*"])
				if ([addLine getCapturesWithRegexAndTrimedComponents:@"^\\+\\+\\+\\s*b/(.*)"  firstComponent:&filePath])
					if (IsNotEmpty(filePath))
					{
						// We found a valid header, add to our colorized string and advance through the header
						filePath = fstr(@"%@\n",filePath);	// newline terminate the path
						[colorized appendAttributedString:[NSAttributedString string:filePath withAttributes:headerLine]];
						i += 2;
						continue;
					}
		}
		
		     if ([line isMatchedByRegex:@"^\\+\\+\\+.*"])	[colorized appendAttributedString:[NSAttributedString string:line withAttributes:linePart]];
		else if ([line isMatchedByRegex:@"^\\+.*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:lightGreen]];
		else if ([line isMatchedByRegex:@"^ .*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:normal]];
		else if ([line isMatchedByRegex:@"^---.*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:linePart]];
		else if ([line isMatchedByRegex:@"^-.*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:lightRed]];
		else if ([line isMatchedByRegex:@"^@@.*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:hunkPart]];
		else												[colorized appendAttributedString:[NSAttributedString string:line withAttributes:normal]];
	}
	return colorized;
}


- (NSString*) patchBodyFiltered
{
	NSMutableString* finalString = [[NSMutableString alloc] init];
	for (FilePatch* filePatch in filePatches_)
		if (filePatch)
		{
			NSString* filteredFilePatch = [filePatch filterFilePatchWithExclusions:[excludedPatchHunksForFilePath_ objectForKey:filePatch->filePath]];
			if (filteredFilePatch)
				[finalString appendString:filteredFilePatch];
		}
	return finalString;
}


- (NSString*) patchBodyHTMLized
{
	NSMutableString* finalString = [[NSMutableString alloc] init];
	for (FilePatch* filePatch in filePatches_)
		if (filePatch)
		{
			NSString* htmlizedFilePatch = [filePatch htmlizedFilePatch];
			if (htmlizedFilePatch)
				[finalString appendString:htmlizedFilePatch];
		}
	return finalString;
}


- (NSString *)description
{
	NSMutableString* finalString = [[NSMutableString alloc] init];
	for (FilePatch* filePatch in filePatches_)
		if (filePatch)
		{
			NSString* desc = [filePatch description];
			if (desc)
				[finalString appendString:desc];
		}
	return finalString;
}


-(void) parseBodyIntoFilePatches
{
	if (!patchBody_)
		return;
	
	FilePatch* currentFilePatch = nil;	
	NSMutableArray* hunkLines = [[NSMutableArray alloc]init];	// The array of lines which go into the current hunk
	NSMutableArray* lines = [[NSMutableArray alloc]init];		// The patchBody broken into it's lines (each line includes the line ending)
	NSInteger start = 0;
	while (start < [patchBody_ length])
	{
		NSRange nextLine = [patchBody_ lineRangeForRange:NSMakeRange(start, 1)];
		[lines addObject:[patchBody_ substringWithRange:nextLine]];
		start = nextLine.location + nextLine.length;
	}
	
	for (NSInteger i = 0; i < [lines count] ; i++)
	{
		NSString* line = [lines objectAtIndex:i];
		
		// If we hit the diff header of a new file set the 'currentFile' and copy the header lines over to the result.
		NSString* filePath = nil;
		if ([line getCapturesWithRegexAndTrimedComponents:@"^diff(?: --git)?\\s*a/(.*) b/(.*)" firstComponent:&filePath] && i+2< [lines count])
		{
			NSMutableString* header = [NSMutableString stringWithString:line];

			NSInteger j = i+1;
			NSInteger headerLineCount = 0;
			for (;j < [lines count] ; j++)
			{
				NSString* jline = [lines objectAtIndex:j];
				if ([jline isMatchedByRegex:@"^(---)|(\\+\\+\\+)|(rename) "])
					 headerLineCount++;
				else if ([jline isMatchedByRegex:@"(^@@.*)|(^diff .*)"])
					break;
				[header appendString:jline];
			}
			if (headerLineCount < 2)
				DebugLog(@"Bad header parse:\n %@", header);
			if (IsNotEmpty(filePath))
			{
				// We found a valid header, add to our colorized string and advance through the header
				[currentFilePatch finishHunk:hunkLines];
				currentFilePatch = [FilePatch filePatchWithPath:filePath andHeader:header];
				[filePatchForFilePath_ setObject:currentFilePatch forKey:filePath];
				[filePatches_ addObject:currentFilePatch];
				i = j-1;
				continue;
			}
		}
		
		if ([line isMatchedByRegex:@"^@@.*"])
			[currentFilePatch finishHunk:hunkLines];
		
		[hunkLines addObject:line];
	}

	[currentFilePatch finishHunk:hunkLines];	
}

@end






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchRecord
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
#define NSMaxiumRange    ((NSRange){.location= 0UL, .length= NSUIntegerMax})

@implementation PatchRecord

@synthesize path = path_;
@synthesize nodeID = nodeID_;
@synthesize patchData = patchData_;
@synthesize forceOption = forceOption_;
@synthesize exactOption = exactOption_;
@synthesize dontCommitOption = dontCommitOption_;
@synthesize importBranchOption = importBranchOption_;
@synthesize guessRenames = guessRenames_;
@synthesize authorIsModified = authorIsModified_;
@synthesize dateIsModified = dateIsModified_;
@synthesize commitMessageIsModified = commitMessageIsModified_;
@synthesize parentIsModified = parentIsModified_;



// Parse something like (without the indent):
//	# HG changeset patch
//	# User jfh <jason@unifiedthought.com>
//	# Date 1270819783 -7200
//	# Node ID 74e391de993ba1d1f96bcec3418b9e4d0cab389f
//	# Parent  8a939c287bc9718450dfd65e056ed656687ac91d
//	My comment for this commit message.
//
//  diff ...
//  ...

- (PatchRecord*) initWithFilePath:(NSString*)path contents:(NSString*)contents
{
	path_ = path;
	author_ = @"";
	date_ = @"";
	commitMessage_ = @"";
	parent_ = @"";
	forceOption_ = NO;
	exactOption_ = NO;
	dontCommitOption_ = NO;
	importBranchOption_ = YES;
	guessRenames_ = YES;
	
	static NSString* linebreak = nil;
	static NSString* headerRegEx = nil;
	static NSString* authorRegEx = nil;
	static NSString* dateRegEx = nil;
	static NSString* parentRegEx = nil;
	static NSString* nodeRegEx = nil;
	static NSString* commitMessageRegEx = nil;
	if (!headerRegEx)
	{
		linebreak   = [NSString stringWithUTF8String:"(?:\\r\\n|[\\n\\v\\f\\r\302\205\\p{Zl}\\p{Zp}])"];
		headerRegEx = [NSString stringWithFormat:@"\\A(.*?)(%@%@diff.*)", linebreak, linebreak];
		authorRegEx = @"^# User (.*)$";
		dateRegEx   = @"^# Date (.*)$";
		parentRegEx = @"^# Parent (.*)$";
		nodeRegEx   = @"^# Node ID (.*)$";
		commitMessageRegEx = [NSString stringWithFormat:@"(?:#.*?%@)*(.*)", linebreak];
	}

	NSArray* parts = [contents captureComponentsMatchedByRegex:headerRegEx options:RKLDotAll range:NSMaxiumRange error:NULL];
	if ([parts count] <= 2)
	{
		patchData_ = [PatchData patchDataFromDiffContents:contents];
		return self;
	}

	patchData_ = [PatchData patchDataFromDiffContents:trimString([parts objectAtIndex:2])];
	NSString* header  = trimString([parts objectAtIndex:1]);
	if (!header)
		return self;

	parts = [header captureComponentsMatchedByRegex:authorRegEx options:RKLMultiline range:NSMaxiumRange error:NULL];
	if ([parts count] >= 1)
		author_ = trimString([parts objectAtIndex:1]);

	parts = [header captureComponentsMatchedByRegex:dateRegEx options:RKLMultiline range:NSMaxiumRange error:NULL];
	if ([parts count] >= 1)
	{
		date_ = trimString([parts objectAtIndex:1]);
		if (date_)
		{
			NSDate* parsedDate = [NSDate dateWithUTCdatePlusOffset:date_];
			if (parsedDate)
				date_ = [parsedDate isodateDescription];
		}
	}

	parts = [header captureComponentsMatchedByRegex:parentRegEx options:RKLMultiline range:NSMaxiumRange error:NULL];
	if ([parts count] >= 1)
		parent_ = trimString([parts objectAtIndex:1]);

	parts = [header captureComponentsMatchedByRegex:nodeRegEx options:RKLMultiline range:NSMaxiumRange error:NULL];
	if ([parts count] >= 1)
		nodeID_ = trimString([parts objectAtIndex:1]);

	parts = [header captureComponentsMatchedByRegex:commitMessageRegEx options:(RKLDotAll) range:NSMaxiumRange error:NULL];
	if ([parts count] >= 1)
		commitMessage_ = trimString([parts objectAtIndex:1]);
	
	return self;
}


+ (PatchRecord*) patchRecordFromFilePath:(NSString*)path
{
	NSString* patchRecordContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	if (!patchRecordContents)
		return nil;

	return [[PatchRecord alloc] initWithFilePath:path contents:patchRecordContents];
}






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Queries
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) patchName							{ return [path_ lastPathComponent]; }
- (NSString*) patchBody							{ return [patchData_ patchBody]; }
- (NSString*) author							{ return author_; }
- (NSString*) date								{ return date_; }
- (NSString*) commitMessage						{ return commitMessage_; }
- (NSString*) parent							{ return parent_; }

- (void) setAuthor:(NSString*)author			{ author_ = author; authorIsModified_ = YES; }
- (void) setDate:(NSString*)date				{ date_ = date; dateIsModified_ = YES; }
- (void) setCommitMessage:(NSString*)message	{ commitMessage_ = message; commitMessageIsModified_ = YES; }
- (void) setParent:(NSString*)parent			{ parent_ = parent; parentIsModified_ = YES; }

- (BOOL) commitOption							{ return !dontCommitOption_; };
- (void) setCommitOption:(BOOL)value			{ dontCommitOption_ = !value; }

- (BOOL) isModified								{ return authorIsModified_ || dateIsModified_ || commitMessageIsModified_ || parentIsModified_; }

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Patch Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

NSString* stringOfDifferencesWebviewDiffStyle()
{
	switch (DifferencesWebviewDiffStyleFromDefaults())
	{
		case 	eWebviewDiffStyleUnfied:				return @"WebviewDiffStyleUnfied";
		case	eWebviewDiffStyleSideBySideWrapped:		return @"WebviewDiffStyleSideBySideWrapped";
		case	eWebviewDiffStyleSideBySideTruncated:	return @"WebviewDiffStyleSideBySideTruncated";
	}
	return @"";
}

