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
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Refreshing and Regeneration
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) redisplayViewForTaskNumber:(NSInteger)taskNumber
{
	if (!backingPatch_)
		dispatch_async(mainQueue(), ^{
			if (taskNumber >= taskNumber_)
				[[self windowScriptObject] callWebScriptMethod:@"showMessage" withArguments:[NSArray arrayWithObject:fallbackMessage_]];
			return;
		});
					   
	dispatch_async(globalQueue(), ^{
		NSString* allowHunkSelection = [[parentController myDocument] inMergeState] ? @"no" : @"yes";
		NSString* htmlizedDiffString = [backingPatch_ patchBodyHTMLized];
		NSArray* showDiffArgs = [NSArray arrayWithObjects:htmlizedDiffString, fstr(@"%f",FontSizeOfDifferencesWebviewFromDefaults()), stringOfDifferencesWebviewDiffStyle(), allowHunkSelection, nil];
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
		NSSet* exclusionsSet = [[parentController hunkExclusions] exclusionsForRoot:repositoryRootForPatch_ andFile:path];
		for (NSString* hunkHash in exclusionsSet)
		{
			NSArray* excludeViewHunkStatusArgs = [NSArray arrayWithObjects:hunkHash, nil];
			[script callWebScriptMethod:@"excludeViewHunkStatus" withArguments:excludeViewHunkStatusArgs];
		}
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
