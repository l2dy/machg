//
//  PatchData.m
//  MacHg
//
//  Created by Jason Harris on 4/23/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "PatchData.h"
#import "Common.h"


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
//	color brightblue "^ .*"
//	color brightred "^-.*"
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
	static NSMutableDictionary* brightBlue = nil;
	static NSMutableDictionary* brightRed = nil;
	static NSMutableDictionary* red = nil;
	static NSMutableDictionary* black = nil;
	static NSMutableDictionary* yellow = nil;
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
		
		lightGreen	= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		brightBlue	= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		brightRed	= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		green		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		red			= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		yellow		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		magenta		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];
		black		= [NSMutableDictionary dictionaryWithDictionary:theDictionary];

		[lightGreen	setObject:[NSColor colorWithDeviceRed:(  0.0/255.0) green:(180.0/255.0) blue:(  0.0/255.0) alpha:1.0] forKey:NSForegroundColorAttributeName];
		[brightBlue	setObject:[NSColor colorWithDeviceRed:(  0.0/255.0) green:(  0.0/255.0) blue:(180.0/255.0) alpha:1.0] forKey:NSForegroundColorAttributeName];
		[brightRed	setObject:[NSColor colorWithDeviceRed:(180.0/255.0) green:(  0.0/255.0) blue:(  0.0/255.0) alpha:1.0] forKey:NSForegroundColorAttributeName];
		[green		setObject:[NSColor colorWithDeviceRed:(  0.0/255.0) green:(128.0/255.0) blue:(  0.0/255.0) alpha:1.0] forKey:NSForegroundColorAttributeName];
		[red		setObject:[NSColor colorWithDeviceRed:(180.0/255.0) green:(  0.0/255.0) blue:(  0.0/255.0) alpha:1.0] forKey:NSForegroundColorAttributeName];
		[yellow		setObject:[NSColor colorWithDeviceRed:(128.0/255.0) green:(128.0/255.0) blue:(  0.0/255.0) alpha:1.0] forKey:NSForegroundColorAttributeName];
		[magenta	setObject:[NSColor colorWithDeviceRed:(128.0/255.0) green:(  0.0/255.0) blue:(128.0/255.0) alpha:1.0] forKey:NSForegroundColorAttributeName];
		[black		setObject:[NSColor colorWithDeviceRed:(  0.0/255.0) green:(  0.0/255.0) blue:(  0.0/255.0) alpha:1.0] forKey:NSForegroundColorAttributeName];
	}

	
	NSMutableArray* lines = [[NSMutableArray alloc]init];
	NSInteger start = 0;	
	while (start < [patchBody_ length])
	{
		NSRange nextLine = [patchBody_ lineRangeForRange:NSMakeRange(start, 1)];
		[lines addObject:[patchBody_ substringWithRange:nextLine]];
		start = nextLine.location + nextLine.length;
	}
	
	for (NSString* line in lines)
	{		
			 if ([line isMatchedByRegex:@"^\\+.*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:lightGreen]];
		else if ([line isMatchedByRegex:@"^\\+\\+\\+.*"])	[colorized appendAttributedString:[NSAttributedString string:line withAttributes:green]];
		else if ([line isMatchedByRegex:@"^ .*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:brightBlue]];
		else if ([line isMatchedByRegex:@"^-.*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:brightRed]];
		else if ([line isMatchedByRegex:@"^---.*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:red]];
		else if ([line isMatchedByRegex:@"^@@.*"])			[colorized appendAttributedString:[NSAttributedString string:line withAttributes:yellow]];
		else if ([line isMatchedByRegex:@"^diff.*"])		[colorized appendAttributedString:[NSAttributedString string:line withAttributes:magenta]];
		else												[colorized appendAttributedString:[NSAttributedString string:line withAttributes:black]];
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
	exactOption_ = YES;
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
		date_ = trimString([parts objectAtIndex:1]);		

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

