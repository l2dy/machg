//
//  PatchesWebview.m
//  MacHg
//
//  Created by Jason Harris on 1/29/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//

#import "PatchesWebview.h"
#import "PatchData.h"
#import "HunkExclusions.h"
#import "MacHgDocument.h"


@implementation PatchesWebview

@synthesize showExternalDiffButton = showExternalDiffButton_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initilization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) awakeFromNib
{	
	NSURL* patchDetailURL = [parentController patchDetailURL];
	[[self mainFrame] loadRequest:[NSURLRequest requestWithURL:patchDetailURL]];
	[[self windowScriptObject] setValue:self forKey:@"machgWebviewController"];
	fallbackMessage_ = @"";

	HunkExclusions* exclusions = [parentController hunkExclusions];
	[self observe:kHunkWasExcluded from:exclusions byCalling:@selector(hunkWasExcluded:)];
	[self observe:kHunkWasIncluded from:exclusions byCalling:@selector(hunkWasIncluded:)];
	[self observe:kFileWasExcluded from:exclusions byCalling:@selector(fileWasExcluded:)];
	[self observe:kFileWasIncluded from:exclusions byCalling:@selector(fileWasIncluded:)];
	showExternalDiffButton_ = YES;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Refreshing and Regeneration
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) redisplayViewForTaskNumber:(NSInteger)taskNumber
{
	if (!backingPatch_)
	{
		dispatch_async(mainQueue(), ^{
			if (taskNumber >= taskNumber_)
				[[self windowScriptObject] callWebScriptMethod:@"showMessage" withArguments:[NSArray arrayWithObject:fallbackMessage_]];
		});
		return;
	}
					   
	dispatch_async(globalQueue(), ^{
		NSString* htmlizedDiffString = [backingPatch_ patchBodyHTMLized];

		if ([htmlizedDiffString length] > DiffDisplaySizeLimitFromDefaults() * 1000000)
		{
			dispatch_async(mainQueue(), ^{
				if (taskNumber >= taskNumber_)
					[[self windowScriptObject] callWebScriptMethod:@"showMessage" withArguments:[NSArray arrayWithObject:@"File Differences Size Limit Exceeded…"]];
			});
			return;
		}

		NSString* allowHunkSelection = [[parentController myDocument] inMergeState] ? @"no" : @"yes";
		NSString* showExternalDiff = showExternalDiffButton_ ? @"yes" : @"no";

		NSArray* showDiffArgs = [NSArray arrayWithObjects:htmlizedDiffString, fstr(@"%f",FontSizeOfDifferencesWebviewFromDefaults()), stringOfDifferencesWebviewDiffStyle(), allowHunkSelection, showExternalDiff, nil];
		dispatch_async(mainQueue(), ^{
			if (taskNumber >= taskNumber_)
				[[self windowScriptObject] callWebScriptMethod:@"showDiff" withArguments:showDiffArgs];
		});
	});	
}
- (void) redisplay	{ [self redisplayViewForTaskNumber:taskNumber_]; }

- (NSInteger) nextTaskNumber { return ++taskNumber_; }

- (void) setBackingPatch:(PatchData*)patchData andFallbackMessage:(NSString*)fallbackMessage
{
	[[self windowScriptObject] setValue:self forKey:@"machgWebviewController"];
	[self setBackingPatch:patchData andFallbackMessage:fallbackMessage withTaskNumber:[self nextTaskNumber]];
}

- (void) setBackingPatch:(PatchData*)patchData andFallbackMessage:(NSString*)fallbackMessage withTaskNumber:(NSInteger)taskNumber
{
	[[self windowScriptObject] setValue:self forKey:@"machgWebviewController"];
	if (taskNumber_ > taskNumber)
		return;
	fallbackMessage_ = fallbackMessage;
	backingPatch_ = patchData;
	repositoryRootForPatch_ = [[parentController myDocument] absolutePathOfRepositoryRoot];
	[self redisplayViewForTaskNumber: taskNumber];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) fileDiffsDisplayPreferencesChanged:(id)sender { [self postNotificationWithName:kFileDiffsDisplayPreferencesChanged]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Notifications
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) hunkWasExcluded:(NSNotification*)notification
{
	NSString* hunkHash = [[notification userInfo] objectForKey:kHunkHash];
	[[self windowScriptObject] callWebScriptMethod:@"excludeViewHunkStatus" withArguments:[NSArray arrayWithObject:hunkHash]];
}

- (void) hunkWasIncluded:(NSNotification*)notification
{
	NSString* hunkHash = [[notification userInfo] objectForKey:kHunkHash];
	[[self windowScriptObject] callWebScriptMethod:@"inludeViewHunkStatus" withArguments:[NSArray arrayWithObject:hunkHash]];
}

- (void) fileWasExcluded:(NSNotification*)notification
{
	NSString* fileName = [[notification userInfo] objectForKey:kFileName];
	FilePatch* filePatch = [backingPatch_ filePatchForFilePath:fileName];
	if (!filePatch)
		return;
	
	NSSet* hunkExclusionSet = [[parentController hunkExclusions] hunkExclusionSetForRoot:repositoryRootForPatch_ andFile:fileName];
	for (NSString* hunkHash in hunkExclusionSet)
		[[self windowScriptObject] callWebScriptMethod:@"excludeViewHunkStatus" withArguments:[NSArray arrayWithObject:hunkHash]];
}

- (void) fileWasIncluded:(NSNotification*)notification
{
	NSString* fileName = [[notification userInfo] objectForKey:kFileName];
	FilePatch* filePatch = [backingPatch_ filePatchForFilePath:fileName];
	if (!filePatch)
		return;
	
	NSSet* validHunkHashSet = [[parentController hunkExclusions] validHunkHashSetForRoot:repositoryRootForPatch_ andFile:fileName];
	for (NSString* hunkHash in validHunkHashSet)
		[[self windowScriptObject] callWebScriptMethod:@"includeViewHunkStatus" withArguments:[NSArray arrayWithObject:hunkHash]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Javascript webview handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) disableHunk:(NSString*)hunkHash forFile:(NSString*)fileName 
{
	if ([[parentController myDocument] inMergeState])
	{
		PlayBeep();
		NSRunAlertPanel(@"Exclusion Forbidden", @"All files must be committed in their entirty during a merge.", @"OK", nil, nil);
		return;
	}
	[[parentController hunkExclusions] disableHunk:hunkHash forRoot:repositoryRootForPatch_ andFile:trimString(fileName)];
}

- (void) enableHunk:(NSString*)hunkHash forFile:(NSString*)fileName 
{
	[[parentController hunkExclusions] enableHunk:hunkHash forRoot:repositoryRootForPatch_ andFile:trimString(fileName)];
}

- (void) excludeHunksAccordingToModel
{
	if ([[parentController myDocument] inMergeState])
		return;
	WebScriptObject* script = [self windowScriptObject];
	for (FilePatch* filePatch in [backingPatch_ filePatches])
	{
		NSString* path = [filePatch filePath];
		NSSet* hunkExclusionSet = [[parentController hunkExclusions] hunkExclusionSetForRoot:repositoryRootForPatch_ andFile:path];
		for (NSString* hunkHash in hunkExclusionSet)
			[script callWebScriptMethod:@"excludeViewHunkStatus" withArguments:[NSArray arrayWithObject:hunkHash]];
	}
}

- (void) doExternalDiffOfFile:(NSString*)fileName 
{
	NSArray* absolutePathOfFile = [NSArray arrayWithObject:fstr(@"%@/%@", repositoryRootForPatch_, trimString(fileName))];
	[[parentController myDocument] viewDifferencesInCurrentRevisionFor:absolutePathOfFile toRevision:nil];
}


+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    // change the javascript name from 'disableHunk_forFile' to 'disableHunkForFile' etc...
	if (sel == @selector(disableHunk:forFile:))			return @"disableHunkForFileName";
	if (sel == @selector(enableHunk:forFile:))			return @"enableHunkForFileName";
	if (sel == @selector(excludeHunksAccordingToModel))	return @"excludeHunksAccordingToModel";
	if (sel == @selector(doExternalDiffOfFile:))		return @"doExternalDiffOfFile";
	return nil;
}
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	if (sel == @selector(disableHunk:forFile:))			return NO;
	if (sel == @selector(enableHunk:forFile:))			return NO;
	if (sel == @selector(excludeHunksAccordingToModel))	return NO;
	if (sel == @selector(doExternalDiffOfFile:))		return NO;
    return YES;
}
+ (BOOL)isKeyExcludedFromWebScript:(const char *)name { return NO; }


@end
