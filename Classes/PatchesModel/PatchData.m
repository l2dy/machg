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
		
		lightGreen		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		lightBlue		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		lightRed		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		green			= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		red				= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		linePart		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		hunkPart		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		magenta			= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		headerLine		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		diffStatLine	= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		diffStatHeader	= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		normal			= [NSMutableDictionary dictionaryWithDictionary:theDictionary];

		[lightGreen		setObject:[NSColor color255WithRed:221.0 green:255.0 blue:221.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[lightBlue		setObject:[NSColor color255WithRed:202.0 green:238.0 blue:255.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[lightRed		setObject:[NSColor color255WithRed:255.0 green:221.0 blue:221.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[green			setObject:[NSColor color255WithRed:160.0 green:255.0 blue:160.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[red			setObject:[NSColor color255WithRed:255.0 green:160.0 blue:160.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[linePart		setObject:[NSColor color255WithRed:240.0 green:240.0 blue:240.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[linePart		setObject:[NSColor color255WithRed:128.0 green:128.0 blue:128.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
		[hunkPart		setObject:[NSColor color255WithRed:234.0 green:242.0 blue:245.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[hunkPart		setObject:[NSColor color255WithRed:128.0 green:128.0 blue:128.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
		[headerLine		setObject:[NSColor color255WithRed:230.0 green:230.0 blue:230.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[headerLine		setObject:[NSColor color255WithRed:128.0 green:128.0 blue:128.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
		[diffStatLine	setObject:[NSColor color255WithRed:255.0 green:253.0 blue:217.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[diffStatLine	setObject:[NSColor color255WithRed:128.0 green:128.0 blue:128.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
		[diffStatHeader setObject:[NSColor color255WithRed:255.0 green:253.0 blue:200.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[diffStatHeader setObject:[NSColor color255WithRed:128.0 green:128.0 blue:128.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
		[magenta		setObject:[NSColor color255WithRed:255.0 green:200.0 blue:255.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];
		[normal			setObject:[NSColor color255WithRed:248.0 green:248.0 blue:255.0 alpha:1.0] forKey:NSBackgroundColorAttributeName];

		NSMutableParagraphStyle* hunkParagraphStyle = [paragraphStyle mutableCopy];
		[hunkParagraphStyle setParagraphSpacingBefore:20];
		[hunkPart		setObject:hunkParagraphStyle forKey:NSParagraphStyleAttributeName];
		
		
		NSMutableParagraphStyle* headerParagraphStyle = [paragraphStyle mutableCopy];
		[headerParagraphStyle setParagraphSpacingBefore:30];
		[headerLine		setObject:[NSFont fontWithName:@"Monaco"  size:15] forKey:NSFontAttributeName];
		[headerLine		setObject:headerParagraphStyle forKey:NSParagraphStyleAttributeName];

		[diffStatHeader	setObject:[NSFont fontWithName:@"Monaco"  size:15] forKey:NSFontAttributeName];
	}

	ExecutionResult* result = [TaskExecutions synchronouslyExecute:@"/usr/bin/diffstat" withArgs:[NSArray arrayWithObjects:path_, nil]];
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
		return self;
	}

	patchBody_ = trimString([parts objectAtIndex:2]);
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

