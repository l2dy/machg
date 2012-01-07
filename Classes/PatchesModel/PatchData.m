//
//  PatchData.m
//  MacHg
//
//  Created by Jason Harris on 4/23/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "PatchData.h"
#import "Common.h"
#import "TaskExecutions.h"


@implementation FilePatch

- (id) initWithPath:(NSString*)path andHeader:(NSString*)header
{
	self = [super init];
    if (self)
	{
		filePath = path;
		filePatchHeader = header;
		hunks = [[NSMutableArray alloc]init];
		hunkHashes = [[NSMutableSet alloc]init];
    }
    return self;
}

+ (FilePatch*) filePatchWithPath:(NSString*)path andHeader:(NSString*)header
{
	return [[FilePatch alloc] initWithPath:path andHeader:header];
}


- (NSString*) hashHunk:(NSString*)hunk
{
	NSString* saltedString = fstr(@"%@:%@", nonNil(filePath), nonNil([hunk SHA1HashString]));
	return [saltedString SHA1HashString];
}

- (void) finishHunk:(NSMutableArray*)lines
{
	if (IsEmpty(lines))
		return;
	NSString* hunk = [lines componentsJoinedByString:@""];
	[hunks addObject:hunk];
	[hunkHashes addObject:[self hashHunk:hunk]];
	[lines removeAllObjects];
}

- (NSString*) filterFilePatchWithExclusions:(NSSet*)excludedHunks
{
	NSMutableString* filteredFilePatch = [[NSMutableString alloc] init];

	[filteredFilePatch appendString:filePatchHeader];

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

@end


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchRecord
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
#define NSMaxiumRange    ((NSRange){.location= 0UL, .length= NSUIntegerMax})

@implementation PatchData

@synthesize path = path_;
@synthesize nodeID = nodeID_;
@synthesize patchBody = patchBody_;
@synthesize excludedPatchHunksForFilePath = excludedPatchHunksForFilePath_;
@synthesize forceOption = forceOption_;
@synthesize exactOption = exactOption_;
@synthesize dontCommitOption = dontCommitOption_;
@synthesize importBranchOption = importBranchOption_;
@synthesize guessRenames = guessRenames_;
@synthesize authorIsModified = authorIsModified_;
@synthesize dateIsModified = dateIsModified_;
@synthesize commitMessageIsModified = commitMessageIsModified_;
@synthesize parentIsModified = parentIsModified_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

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

	ExecutionResult* result = [ShellTask execute:@"/usr/bin/diffstat" withArgs:[NSArray arrayWithObjects:path_, nil] withEnvironment:[TaskExecutions environmentForHg]];
	if ([result hasNoErrors])
	{
		[colorized appendAttributedString:[NSAttributedString string:@"Patch Statistics\n" withAttributes:diffStatHeader]];
		[colorized appendAttributedString:[NSAttributedString string:result.outStr withAttributes:diffStatLine]];
	}

	
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
	for (FilePatch* fp in filePatches_)
		if (fp)
		{
			NSString* filteredFilePatch = [fp filterFilePatchWithExclusions:[excludedPatchHunksForFilePath_ objectForKey:fp->filePath]];
			if (filteredFilePatch)
				[finalString appendString:filteredFilePatch];
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
			NSMutableString* header = [[NSMutableString alloc]init];
			[header appendString:line];

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

- (PatchData*) initWithFilePath:(NSString*)path contents:(NSString*)contents
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
	excludedPatchHunksForFilePath_ = [[NSMutableDictionary alloc]init];
	filePatchForFilePath_ = [[NSMutableDictionary alloc]init];
	filePatches_ = [[NSMutableArray alloc]init];
	
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
		patchBody_ = contents;
		[self parseBodyIntoFilePatches];
		return self;
	}

	patchBody_ = trimString([parts objectAtIndex:2]);
	NSString* header  = trimString([parts objectAtIndex:1]);
	if (!header)
	{
		[self parseBodyIntoFilePatches];
		return self;
	}

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
	
	[self parseBodyIntoFilePatches];
	return self;
}


+ (PatchData*) patchDataFromFilePath:(NSString*)path
{
	NSString* patchContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	if (!patchContents)
		return nil;

	return [[PatchData alloc] initWithFilePath:path contents:patchContents];

}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quieres
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) patchName							{ return [path_ lastPathComponent]; }
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

@end;

