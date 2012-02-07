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
#import "HunkExclusions.h"



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HTMLizng Differences
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -


static NSString* encodeForHTML(NSString* line)
{
	NSMutableString* text = [line mutableCopy];
	[text replaceOccurrencesOfString:@"&"  withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@"<"  withString:@"&lt;"  options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@">"  withString:@"&gt;"  options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@">"  withString:@"&gt;"  options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@"'"  withString:@"\x27"  options:NSLiteralSearch range:NSMakeRange(0, text.length)];
	[text replaceOccurrencesOfString:@"\"" withString:@"\x22"  options:NSLiteralSearch range:NSMakeRange(0, text.length)];
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


static void addStringForOperation(NSMutableString* build, NSString* str, Operation operation, NSString* prefix)
{
	NSCharacterSet* newlines = [NSCharacterSet newlineCharacterSet];
	NSString* fromStr = encodeForHTML(str);	// This is an ecoded copy
	
	BOOL encounteredNewLine = IsEmpty(build) || [build endsWithNewLine];
	NSInteger position = 0;
	while (position != [fromStr length])
	{
		if (encounteredNewLine)
			[build appendString:prefix];

		encounteredNewLine = NO;
		NSRange newLineRange = [fromStr rangeOfCharacterFromSet:newlines options:NSLiteralSearch range:NSMakeRange(position, [fromStr length] - position)];
		NSRange contentRange;
		if (newLineRange.location == NSNotFound)
			contentRange = NSMakeRange(position, [fromStr length] - position);
		else if (newLineRange.location == position)
		{
			contentRange = NSMakeRange(position, 1);
			encounteredNewLine = YES;
		}
		else
			contentRange = NSMakeRange(position, newLineRange.location - position);

		NSString* contentString = [fromStr substringWithRange:contentRange];
		
		if (encounteredNewLine)
			[build appendString:contentString];
		else
		{
			switch (operation)
			{
				case DIFF_INSERT:   [build appendFormat:@"<insert>%@</insert>", contentString, nil];	break;
				case DIFF_DELETE:	[build appendFormat:@"<delete>%@</delete>", contentString, nil];	break;
				case DIFF_EQUAL:	[build appendString:contentString];									break;
			}			
		}
		position += contentRange.length;
	}
}

// Given the lines on the left and the lines on the right, create the subline diff and reconstruct the left lines with
// <delete>...</delete>'s and the right lines with <insert>...</insert>'s in them. Also reinclude the prefix "-" and "+"
static NSString* htmlizedDifference(NSMutableArray* leftLines, NSMutableArray* rightLines, BOOL sublineDiffing)
{
	DiffMatchPatch* dmp = [DiffMatchPatch new];
	dmp.Diff_Timeout = 0;				
	NSString* left  = [leftLines  componentsJoinedByString:@""];
	NSString* right = [rightLines componentsJoinedByString:@""];

	NSMutableString* newLeft  = [[NSMutableString alloc]init];
	NSMutableString* newRight = [[NSMutableString alloc]init];

	sublineDiffing = sublineDiffing && ([leftLines count] < 100) && ([rightLines count] < 100);

	if (!sublineDiffing)
	{
		addStringForOperation(newLeft,  left,  DIFF_DELETE, @"-");
		addStringForOperation(newRight, right, DIFF_INSERT, @"+");
	}
	else
	{
		NSMutableArray* diffs = [dmp diff_mainOfOldString:left andNewString:right checkLines:NO];
		[dmp diff_cleanupSemantic:diffs];

		// Reconstruct the left and right hand sides
		for (Diff* aDiff in diffs)
			switch (aDiff.operation)
			{
				case DIFF_INSERT:																		addStringForOperation(newRight, aDiff.text, aDiff.operation, @"+");	break;
				case DIFF_DELETE:	addStringForOperation(newLeft, aDiff.text, aDiff.operation, @"-");																		break;
				case DIFF_EQUAL:	addStringForOperation(newLeft, aDiff.text, aDiff.operation, @"-");	addStringForOperation(newRight, aDiff.text, aDiff.operation, @"+");	break;
			}
	}
	
	[leftLines removeAllObjects];
	[rightLines removeAllObjects];

	return fstr(@"%@%@", newLeft, newRight);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HunkObject
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -


@implementation HunkObject

@synthesize hunkHash;

- (HunkObject*) initHunkObjectWithLines:(NSMutableArray*)lines andParentFilePatch:(FilePatch*)parent
{
	self = [super init];
	if (!self || IsEmpty(lines))
		return nil;

	parentFilePatch = parent;
	hunkHeader = [lines popFirst];
	if (![hunkHeader isMatchedByRegex:@"^@@.*"])
		DebugLog(@"Bad patch header");
	hunkBodyLines = lines;
	
	// Compute hunkHash
	changeLineCount = 0;
	NSMutableString* changeLines = [[NSMutableString alloc]init];
	for (NSString* line in lines)
	{
		unichar firstChar = [line characterAtIndex:0];
		if (firstChar != '+' && firstChar != '-')
			continue;
		[changeLines appendString:line];
		changeLineCount++;
	}
	NSString* saltedString = fstr(@"%@:%@", nonNil([parent filePath]), nonNil([changeLines SHA1HashString]));
	hunkHash = [saltedString SHA1HashString];
	if ([[parent hunkHashesSet] containsObject:hunkHash])
	{
		NSString* furtherSaltedHash = [hunkHash stringByAppendingString:intAsString([[parent hunkHashesSet] count])];
		hunkHash = [furtherSaltedHash SHA1HashString];
	}
	return self;
}

+ (HunkObject*) hunkObjectWithLines:(NSMutableArray*)lines andParentFilePatch:(FilePatch*)parentFilePatch
{
	return [[HunkObject alloc] initHunkObjectWithLines:lines andParentFilePatch:parentFilePatch];
}

- (NSString*)   htmlizedHunk:(BOOL)sublineDiffing
{
	NSMutableString* processedString = [[NSMutableString alloc]init];
	
	// Add the hash to the header
	NSArray* split = splitTermination(hunkHeader);
	if ([split count] > 1)
		[processedString appendString:fstr(@"%@ %@%@", [split firstObject], nonNil(hunkHash), [split lastObject])];
	else
		[processedString appendString:hunkHeader];


	NSMutableArray* leftLines	= [[NSMutableArray alloc]init];
	NSMutableArray* rightLines	= [[NSMutableArray alloc]init];
	for (NSString* line in hunkBodyLines)
	{
		if ([line isMatchedByRegex:@"^\\+.*"])
			[rightLines addObject:[line substringWithRange:NSMakeRange(1,[line length]-1)]];
		else if ([line isMatchedByRegex:@"^-.*"])
			[leftLines addObject:[line substringWithRange:NSMakeRange(1,[line length]-1)]];
		else
		{
			if (IsNotEmpty(leftLines) || IsNotEmpty(rightLines))
				[processedString appendString:htmlizedDifference(leftLines, rightLines, sublineDiffing)];
			[processedString appendString:encodeForHTML(line)];
		}
	}
	if (IsNotEmpty(leftLines) || IsNotEmpty(rightLines))
		[processedString appendString:htmlizedDifference(leftLines, rightLines, sublineDiffing)];
	return processedString;
}

- (NSString*) hunkString
{
	NSMutableString* builtHunkString = [[NSMutableString alloc]initWithString:hunkHeader];
	for (NSString* line in hunkBodyLines)
		[builtHunkString appendString:line];
	return builtHunkString;
}

- (NSInteger) lineChangeCount
{
	return changeLineCount;
}

- (NSString*) description
{
	return fstr(@"######## %@ ########\n%@", hunkHash,[self hunkString]);
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilePatch
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation FilePatch

@synthesize filePath;
@synthesize filePatchHeader;
@synthesize hunks;
@synthesize hunkHashesSet;

- (id) initWithPath:(NSString*)path andHeader:(NSString*)header
{
	self = [super init];
    if (self)
	{
		filePath = path;
		filePatchHeader = header;
		hunks = [[NSMutableArray alloc]init];
		hunkHashesSet = [[NSMutableSet alloc]init];
    }
    return self;
}

+ (FilePatch*) filePatchWithPath:(NSString*)path andHeader:(NSString*)header
{
	return [[FilePatch alloc] initWithPath:path andHeader:header];
}


- (void) addHunkObjectWithLines:(NSMutableArray*)lines
{
	if (IsEmpty(lines))
		return;
	HunkObject* hunk = [HunkObject hunkObjectWithLines:lines andParentFilePatch:self];
	[hunks addObject:hunk];
	[hunkHashesSet addObject:[hunk hunkHash]];
}

- (NSInteger) lineChangeCount
{
	NSInteger lineChangeCount = 0;
	for (HunkObject* hunk in hunks)
		lineChangeCount += [hunk lineChangeCount];
	return lineChangeCount;
}

- (NSString*) filePatchFilteredByExclusions:(NSSet*)excludedHunks
{
	// The normal case when this file patch is not filtered at all
	if (IsEmpty(excludedHunks) || ![excludedHunks intersectsSet:[self hunkHashesSet]])
		return [self filePatchString];
	if ([[self hunkHashesSet] isSubsetOfSet:excludedHunks])
		return nil;

	NSMutableString* filteredFilePatch = [NSMutableString stringWithString:filePatchHeader];
	for (HunkObject* hunk in hunks)
	{
		if (![excludedHunks containsObject:[hunk hunkHash]])
			[filteredFilePatch appendString:[hunk hunkString]];
	}
	return filteredFilePatch;
}


- (NSString*) htmlizedFilePatch:(BOOL)sublineDiffing
{
	NSMutableString* builtPatch = [NSMutableString stringWithString:filePatchHeader];
	sublineDiffing = ([hunks count] < 200) && sublineDiffing;
	for (HunkObject* hunk in hunks)
		[builtPatch appendString:[hunk htmlizedHunk:sublineDiffing]];
	return builtPatch;
}

- (NSString*) filePatchString
{
	NSMutableString* builtPatch = [NSMutableString stringWithString:filePatchHeader];
	for (HunkObject* hunk in hunks)
		[builtPatch appendString:[hunk hunkString]];
	return builtPatch;
}

- (NSString*) description
{
	NSMutableString* desc = [NSMutableString stringWithString:filePatchHeader];
	for (HunkObject* hunk in hunks)
		[desc appendString:[hunk description]];
	return desc;
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

@synthesize patchBody = patchBody_;
@synthesize filePatches = filePatches_;


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (PatchData*) initWithDiffContents:(NSString*)contents
{
	filePatchForFilePathDictionary_ = [[NSMutableDictionary alloc]init];
	filePatches_ = [[NSMutableArray alloc]init];
	patchBody_ = contents;
	[self parseBodyIntoFilePatches];
	return self;
}

+ (PatchData*) patchDataFromDiffContents:(NSString*)diff
{
	return [[PatchData alloc] initWithDiffContents:diff];
}






- (NSString*) description
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

- (void) finishHunkObjectWithLines:(NSMutableArray*)hunkLines
{
	FilePatch* currentFilePatch = [filePatches_ lastObject];
	[currentFilePatch addHunkObjectWithLines:hunkLines];
}

- (void) startNewFilePatchForPath:(NSString*)filePath andHeader:(NSString*)filePatchHeader
{
	FilePatch* newFilePatch = [FilePatch filePatchWithPath:filePath andHeader:filePatchHeader];
	if (!filePath || !newFilePatch)
		return;
	[filePatchForFilePathDictionary_ setObject:newFilePatch forKey:filePath];
	[filePatches_ addObject:newFilePatch];
}

-(void) parseBodyIntoFilePatches
{
	if (!patchBody_)
		return;
	
	NSMutableArray* hunkLines = [[NSMutableArray alloc]init];		// The array of lines which go into the current hunk
	
	NSArray* lines = [patchBody_ stringDividedIntoLines];			// The patchBody broken into it's lines (each line includes the line ending)
	for (NSInteger i = 0; i < [lines count] ; i++)
	{
		NSString* line = [lines objectAtIndex:i];

		// For speed for really long patches, short circut for the really common case of just adding the line to the hunk lines.
		// (This skips the regex testing.) 
		unichar firstChar = [line characterAtIndex:0];
		if (firstChar != 'd' && firstChar != '@')
		{
			[hunkLines addObject:line];
			continue;
		}

		// If we hit the diff header of a new file finish the current hunk and start a new filePatch and newHunk
		NSString* filePath = nil;
		if ([line getCapturesWithRegexAndTrimedComponents:@"^diff(?: --git)?\\s*a/(.*) b/(.*)" firstComponent:&filePath] && i+2< [lines count])
		{
			NSMutableString* filePatchHeader = [NSMutableString stringWithString:line];

			NSInteger j = i+1;
			NSInteger headerLineCount = 0;
			for (;j < [lines count] ; j++)
			{
				NSString* jline = [lines objectAtIndex:j];
				if ([jline isMatchedByRegex:@"^(---)|(\\+\\+\\+)|(rename) "])
					 headerLineCount++;
				else if ([jline isMatchedByRegex:@"(^@@.*)|(^diff .*)"])
					break;
				[filePatchHeader appendString:jline];
			}
			if (headerLineCount < 2)
				DebugLog(@"Bad header parse:\n %@", filePatchHeader);
			if (IsNotEmpty(filePath))
			{
				// We found a valid header, add the current lines as a hunk to the current file patch, then start a new filePatch
				[self finishHunkObjectWithLines:hunkLines];				
				hunkLines = [[NSMutableArray alloc]init];
				[self startNewFilePatchForPath:filePath andHeader:filePatchHeader];
				i = j-1;
				continue;
			}
		}

		// We found a hunk header so finish the current hunk object and start collecting lines for a new hunk
		if ([line isMatchedByRegex:@"^@@.*"])
		{
			[self finishHunkObjectWithLines:hunkLines];
			hunkLines = [[NSMutableArray alloc]init];
		}
		
		[hunkLines addObject:line];
	}

	[self finishHunkObjectWithLines:hunkLines];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (FilePatch*) filePatchForFilePath:(NSString*)filePath		{ return [filePatchForFilePathDictionary_ objectForKey:filePath]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Patch Presentation
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
	
	//ExecutionResult* result = [ShellTask execute:@"/usr/bin/diffstat" withArgs:[NSArray arrayWithObjects:path_, nil] withEnvironment:[TaskExecutions environmentForHg]];
	//if ([result hasNoErrors])
	//{
	//	[colorized appendAttributedString:[NSAttributedString string:@"Patch Statistics\n" withAttributes:diffStatHeader]];
	//	[colorized appendAttributedString:[NSAttributedString string:result.outStr withAttributes:diffStatLine]];
	//}
	
	
	NSArray* lines = [patchBody_ stringDividedIntoLines];			// The patchBody broken into it's lines (each line includes the line ending)	
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


- (NSInteger) lineChangeCount
{
	NSInteger lineChangeCount = 0;
	for (FilePatch* filePatch in filePatches_)
		lineChangeCount += [filePatch lineChangeCount];
	return lineChangeCount;
}


- (NSString*) patchBodyHTMLized
{
	NSMutableString* finalString = [[NSMutableString alloc] init];
	BOOL sublineDiffing = [self lineChangeCount] < 2000;
	for (FilePatch* filePatch in filePatches_)
		if (filePatch)
		{
			NSString* htmlizedFilePatch = [filePatch htmlizedFilePatch:sublineDiffing];
			if (htmlizedFilePatch)
				[finalString appendString:htmlizedFilePatch];
		}
	return finalString;
}

- (NSString*) patchBodyString
{
	NSMutableString* finalString = [[NSMutableString alloc] init];
	for (FilePatch* filePatch in filePatches_)
		if (filePatch)
		{
			NSString* filePatchString = [filePatch filePatchString];
			if (filePatchString)
				[finalString appendString:filePatchString];
		}
	return finalString;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Patch Filtering
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) willFilterPatchFor:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root
{
	NSDictionary* repositoryExclusions = [hunkExclusions repositoryExclusionsForRoot:root];
	for (FilePatch* filePatch in filePatches_)
	{
		NSSet* exclusionsSet = [repositoryExclusions objectForKey:filePatch];
		if (exclusionsSet)
			if ([exclusionsSet intersectsSet:[filePatch hunkHashesSet]])
				return YES;
	}
	return NO;
}

- (NSString*) patchBodyFilteredBy:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root
{
	NSMutableString* finalString = [[NSMutableString alloc] init];
	NSDictionary* repositoryExclusions = [hunkExclusions repositoryExclusionsForRoot:root];
	if (IsEmpty(repositoryExclusions))
		return [self patchBodyString];

	for (FilePatch* filePatch in filePatches_)
		if (filePatch)
		{
			NSString* filteredFilePatch = [filePatch filePatchFilteredByExclusions:[repositoryExclusions objectForKey:[filePatch filePath]]];
			if (filteredFilePatch)
				[finalString appendString:filteredFilePatch];
		}
	return finalString;
}


- (NSString*) tempFileWithPatchBodyFilteredBy:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root
{
	NSString* filteredPatchBody = [self patchBodyFilteredBy:hunkExclusions withRoot:root];
	NSString* tempFilePath = tempFilePathWithTemplate(@"MacHgFilteredPatch.XXXXXXXXXX");
	if (!tempFilePath)
	{
		NSRunAlertPanel(@"Temporary File", @"MacHg could not create a temporary file for the filtered patch. Aborting the operation.", @"OK", nil, nil);
		return nil;
	}
	NSError* err = nil;
	[filteredPatchBody writeToFile:tempFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
	[NSApp presentAnyErrorsAndClear:&err];
	return tempFilePath;	
}


- (NSArray*) pathsAffectedByExclusions:(HunkExclusions*)hunkExclusions withRoot:(NSString*)root
{
	NSMutableArray* paths = [[NSMutableArray alloc]init];
	NSDictionary* repositoryExclusions = [hunkExclusions repositoryExclusionsForRoot:root];
	if (!repositoryExclusions)
		return paths;
	for (FilePatch* filePatch in filePatches_)
		if (filePatch)
		{
			NSSet* exclusionsSet = [repositoryExclusions objectForKey:[filePatch filePath]];
			if ([[filePatch hunkHashesSet] intersectsSet:exclusionsSet])
				[paths addObject:[filePatch filePath]];
		}
	return paths;
	
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

