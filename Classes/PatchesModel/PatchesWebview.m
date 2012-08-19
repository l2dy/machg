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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  RegenerationTaskController
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation RegenerationTaskController
@synthesize taskNumber = taskNumber_;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchesWebview
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface PatchesWebview (PrivateAPI)
- (void) redisplayViewForTaskNumber:(NSInteger)taskNumber;
@end

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

- (NSInteger) nextTaskNumber					{ return ++taskNumber_; }
- (NSInteger) currentTaskNumber					{ return   taskNumber_; }
- (void) redisplay								{ [self redisplayViewForTaskNumber:taskNumber_]; }
- (BOOL) taskIsStale:(NSInteger)taskNumber		{ return taskNumber < taskNumber_; }
- (BOOL) taskIsNotStale:(NSInteger)taskNumber	{ return taskNumber >= taskNumber_; }

- (void) redisplayViewForTaskNumber:(NSInteger)taskNumber
{
	if (!backingPatch_)
	{
		dispatch_async(mainQueue(), ^{
			if ([self taskIsNotStale:taskNumber])
				[[self windowScriptObject] callWebScriptMethod:@"showMessage" withArguments:@[fallbackMessage_]];
		});
		return;
	}
					   
	dispatch_async(globalQueue(), ^{
		NSString* htmlizedDiffString = [backingPatch_ patchBodyHTMLized];

		if ([htmlizedDiffString length] > DiffDisplaySizeLimitFromDefaults() * 1000000)
		{
			dispatch_async(mainQueue(), ^{
				if ([self taskIsNotStale:taskNumber])
					[[self windowScriptObject] callWebScriptMethod:@"showMessage" withArguments:@[@"File Differences Size Limit Exceeded…"]];
			});
			return;
		}

		NSString* allowHunkSelection = [[parentController myDocument] inMergeState] ? @"no" : @"yes";
		NSString* showExternalDiff = showExternalDiffButton_ ? @"yes" : @"no";

		NSArray* showDiffArgs = @[htmlizedDiffString, fstr(@"%f",FontSizeOfDifferencesWebviewFromDefaults()), stringOfDifferencesWebviewDiffStyle(), allowHunkSelection, showExternalDiff];
		dispatch_async(mainQueue(), ^{
			if ([self taskIsNotStale:taskNumber])
				[[self windowScriptObject] callWebScriptMethod:@"showDiff" withArguments:showDiffArgs];
		});
	});	
}


- (void) setBackingPatch:(PatchData*)patchData andFallbackMessage:(NSString*)fallbackMessage
{
	dispatch_async(mainQueue(), ^{
		[[self windowScriptObject] setValue:self forKey:@"machgWebviewController"];
		[self setBackingPatch:patchData andFallbackMessage:fallbackMessage withTaskNumber:[self nextTaskNumber]];
	});
}

- (void) setBackingPatch:(PatchData*)patchData andFallbackMessage:(NSString*)fallbackMessage withTaskNumber:(NSInteger)taskNumber
{
	dispatch_async(mainQueue(), ^{
		[[self windowScriptObject] setValue:self forKey:@"machgWebviewController"];
		if ([self taskIsStale:taskNumber])
			return;
		fallbackMessage_ = fallbackMessage;
		backingPatch_ = patchData;
		repositoryRootForPatch_ = [[parentController myDocument] absolutePathOfRepositoryRoot];
		[self redisplayViewForTaskNumber: taskNumber];
	});
}


- (void) putUpGeneratingDifferencesNotice:(RegenerationTaskController*)theRegenerationTaskContoller
{
	if ([self taskIsStale:[theRegenerationTaskContoller taskNumber]])
		return;
	if ([[theRegenerationTaskContoller shellTask] isRunning])
		dispatch_async(mainQueue(), ^{
			WebScriptObject* script = [self windowScriptObject];
			[script callWebScriptMethod:@"showGeneratingMessage" withArguments:@[@"Generating Differences… "]];
		});
}


- (void) regenerateDifferencesForSelectedPaths:(NSArray*)selectedPaths andRoot:(NSString*)rootPath
{
	RegenerationTaskController* currentRegenerationTaskController = [[RegenerationTaskController alloc]init];
	@synchronized(self)
	{
		[currentRegenerationTaskController setTaskNumber:[self nextTaskNumber]];
		@try { [[currentRegenerationTask_ shellTask] terminate]; }
		@catch (NSException * e) { }
		currentRegenerationTask_ = currentRegenerationTaskController;
	}
	
	// FIXME : If the webscriptObject is now nil then reload the page.
	[self performSelector:@selector(putUpGeneratingDifferencesNotice:) withObject:currentRegenerationTaskController afterDelay:0.5];
	dispatch_async(globalQueue(), ^{
		if ([self taskIsStale:[currentRegenerationTaskController taskNumber]]) return;

		NSMutableArray* argsDiff = [NSMutableArray arrayWithObjects:@"diff", nil];
		[argsDiff addObject:@"--unified" followedBy:fstr(@"%d",NumContextLinesForDifferencesWebviewFromDefaults())];
		[argsDiff addObjectsFromArray:selectedPaths];

		if ([self taskIsStale:[currentRegenerationTaskController taskNumber]]) return;
		
		ExecutionResult* diffResult = [TaskExecutions executeMercurialWithArgs:argsDiff  fromRoot:rootPath logging:eLoggingNone  withDelegate:currentRegenerationTaskController];

		if ([self taskIsStale:[currentRegenerationTaskController taskNumber]]) return;

		PatchData* patchData = IsNotEmpty(diffResult.outStr) ? [PatchData patchDataFromDiffContents:diffResult.outStr] : nil;
		[[parentController hunkExclusions] updateExclusionsForPatchData:patchData andRoot:rootPath within:selectedPaths];
		[self setBackingPatch:patchData andFallbackMessage:@"" withTaskNumber:[currentRegenerationTaskController taskNumber]];
	});	
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
	dispatch_async(mainQueue(), ^{
		NSString* hunkHash = [notification userInfo][kHunkHash];
		[[self windowScriptObject] callWebScriptMethod:@"excludeViewHunkStatus" withArguments:@[hunkHash]];
	});
}

- (void) hunkWasIncluded:(NSNotification*)notification
{
	dispatch_async(mainQueue(), ^{
		NSString* hunkHash = [notification userInfo][kHunkHash];
		[[self windowScriptObject] callWebScriptMethod:@"inludeViewHunkStatus" withArguments:@[hunkHash]];
	});
}

- (void) fileWasExcluded:(NSNotification*)notification
{
	NSString* fileName = [notification userInfo][kFileName];
	FilePatch* filePatch = [backingPatch_ filePatchForFilePath:fileName];
	if (!filePatch)
		return;
	
	dispatch_async(mainQueue(), ^{
		NSSet* hunkExclusionSet = [[parentController hunkExclusions] hunkExclusionSetForRoot:repositoryRootForPatch_ andFile:fileName];
		for (NSString* hunkHash in hunkExclusionSet)
			[[self windowScriptObject] callWebScriptMethod:@"excludeViewHunkStatus" withArguments:@[hunkHash]];
	});
}

- (void) fileWasIncluded:(NSNotification*)notification
{
	NSString* fileName = [notification userInfo][kFileName];
	FilePatch* filePatch = [backingPatch_ filePatchForFilePath:fileName];
	if (!filePatch)
		return;

	dispatch_async(mainQueue(), ^{
		NSSet* validHunkHashSet = [[parentController hunkExclusions] validHunkHashSetForRoot:repositoryRootForPatch_ andFile:fileName];
		for (NSString* hunkHash in validHunkHashSet)
			[[self windowScriptObject] callWebScriptMethod:@"includeViewHunkStatus" withArguments:@[hunkHash]];
	});
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
	dispatch_async(mainQueue(), ^{
		WebScriptObject* script = [self windowScriptObject];
		for (FilePatch* filePatch in [backingPatch_ filePatches])
		{
			NSString* path = [filePatch filePath];
			NSSet* hunkExclusionSet = [[parentController hunkExclusions] hunkExclusionSetForRoot:repositoryRootForPatch_ andFile:path];
			for (NSString* hunkHash in hunkExclusionSet)
				[script callWebScriptMethod:@"excludeViewHunkStatus" withArguments:@[hunkHash]];
		}
	});
}

- (void) doExternalDiffOfFile:(NSString*)fileName 
{
	NSArray* absolutePathOfFile = @[fstr(@"%@/%@", repositoryRootForPatch_, trimString(fileName))];
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
