//
//  CommonHeader.m
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import "RegexKitLite.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Defaults
// -----------------------------------------------------------------------------------------------------------------------------------------

NSString* const kSidebarPBoardType						= @"SidebarNodePBoardType";
NSString* const kSidebarRootInitializationDummy			= @"SidebarRootInitializationDummy";
NSString* const kPatchesTablePBoardType					= @"PatchesTablePBoardType";

// Notifications
NSString* const kRepositoryRootChanged					= @"RepositoryRootChanged";
NSString* const kRepositoryIdentityChanged				= @"RepositoryIdentityChanged";
NSString* const kSidebarSelectionDidChange				= @"SidebarSelectionDidChange";
NSString* const kBrowserDisplayPreferencesChanged		= @"BrowserDisplayPreferencesChanged";
NSString* const kUnderlyingRepositoryChanged			= @"UnderlyingRepositoryChanged";
NSString* const kCompatibleRepositoryChanged			= @"CompatibleRepositoryChanged";
NSString* const kReceivedCompatibleRepositoryCount		= @"ReceivedCompatibleRepositoryCount";
NSString* const kRepositoryDataDidChange				= @"RepositoryDataDidChange";
NSString* const kRepositoryDataIsNew					= @"RepositoryDataIsNew";
NSString* const kLogEntriesDidChange                    = @"LogEntriesDidChange";
NSString* const kProcessAddedToProcessList				= @"ProcessAddedToProcessList";
NSString* const kProcessRemovedFromProcessList			= @"ProcessRemovedFromProcessList";
NSString* const kCommandKeyIsDown						= @"CommandKeyIsDown"; 
NSString* const kCommandKeyIsUp							= @"CommandKeyIsUp"; 


// Dictionary Keys
NSString* const kLogEntryChangeType						= @"LogEntryChangeType"; 
NSString* const kLogEntryTagsChanged					= @"LogEntryTagsChanged"; 
NSString* const kLogEntryBranchesChanged				= @"LogEntryBranchesChanged"; 
NSString* const kLogEntryBookmarksChanged				= @"LogEntryBookmarksChanged"; 
NSString* const kLogEntryOpenHeadsChanged				= @"LogEntryOpenHeadsChanged"; 
NSString* const kLogEntryDetailsChanged					= @"LogEntryDetailsChanged"; 


/* To regenerate start with a list of names and then search and replace on (\w+) -->
extern NSString* const MHG\1;
BOOL		\1FromDefaults();

NSString* const MHG\1			= @"\1";
BOOL		\1FromDefaults()					{ return boolFromDefaultsForKey(MHG\1); }

*/


// These are the names of the preferences in the plist.
NSString* const MHGAddRemoveSimilarityFactor			= @"AddRemoveSimilarityFactor";
NSString* const MHGAddRemoveUsesSimilarity				= @"AddRemoveUsesSimilarity";
NSString* const MHGAfterMergeDo							= @"AfterMergeDo";
NSString* const MHGAfterMergeSwitchTo					= @"AfterMergeSwitchTo";
NSString* const MHGAllowHistoryEditingOfRepository		= @"AllowHistoryEditingOfRepository";
NSString* const MHGBrowserBehaviourCommandDoubleClick	= @"BrowserBehaviourCommandDoubleClick";
NSString* const MHGBrowserBehaviourCommandOptionDoubleClick	= @"BrowserBehaviourCommandOptionDoubleClick";
NSString* const MHGBrowserBehaviourDoubleClick			= @"BrowserBehaviourDoubleClick";
NSString* const MHGBrowserBehaviourOptionDoubleClick	= @"BrowserBehaviourOptionDoubleClick";
NSString* const MHGDefaultAnnotationOptionChangeset		= @"DefaultAnnotationOptionChangeset";
NSString* const MHGDefaultAnnotationOptionDate			= @"DefaultAnnotationOptionDate";
NSString* const MHGDefaultAnnotationOptionFollow		= @"DefaultAnnotationOptionFollow";
NSString* const MHGDefaultAnnotationOptionLineNumber	= @"DefaultAnnotationOptionLineNumber";
NSString* const MHGDefaultAnnotationOptionNumber		= @"DefaultAnnotationOptionNumber";
NSString* const MHGDefaultAnnotationOptionText			= @"DefaultAnnotationOptionText";
NSString* const MHGDefaultAnnotationOptionUser			= @"DefaultAnnotationOptionUser";
NSString* const MHGDefaultHGIgnoreContents              = @"DefaultHGIgnoreContents";
NSString* const MHGDefaultRevisionSortOrder				= @"DefaultRevisionSortOrder";
NSString* const MHGDefaultWorkspacePath					= @"DefaultWorkspacePath";
NSString* const MHGDisplayFileIconsInBrowser			= @"DisplayFileIconsInBrowser";
NSString* const MHGDisplayResultsOfAddRemoveRenameFiles	= @"DisplayResultsOfAddRemoveRenameFiles";
NSString* const MHGDisplayResultsOfMerging				= @"DisplayResultsOfMerging";
NSString* const MHGDisplayResultsOfPulling				= @"DisplayResultsOfPulling";
NSString* const MHGDisplayResultsOfPushing				= @"DisplayResultsOfPushing";
NSString* const MHGDisplayResultsOfUpdating				= @"DisplayResultsOfUpdating";
NSString* const MHGDisplayWarningForAddRemoveRenameFiles = @"DisplayWarningForAddRemoveRenameFiles";
NSString* const MHGDisplayWarningForBranchNameRemoval	= @"DisplayWarningForBranchNameRemoval";
NSString* const MHGDisplayWarningForFileDeletion		= @"DisplayWarningForFileDeletion";
NSString* const MHGDisplayWarningForMarkingFilesResolved = @"DisplayWarningForMarkingFilesResolved";
NSString* const MHGDisplayWarningForMerging				= @"DisplayWarningForMerging";
NSString* const MHGDisplayWarningForPostMerge			= @"DisplayWarningForPostMerge";
NSString* const MHGDisplayWarningForPulling			    = @"DisplayWarningForPulling";
NSString* const MHGDisplayWarningForPushing			    = @"DisplayWarningForPushing";
NSString* const MHGDisplayWarningForRenamingFiles		= @"DisplayWarningForRenamingFiles";
NSString* const MHGDisplayWarningForRepositoryDeletion	= @"DisplayWarningForRepositoryDeletion";
NSString* const MHGDisplayWarningForRevertingFiles		= @"DisplayWarningForRevertingFiles";
NSString* const MHGDisplayWarningForRollbackFiles		= @"DisplayWarningForRollbackFiles";
NSString* const MHGDisplayWarningForTagRemoval			= @"DisplayWarningForTagRemoval";
NSString* const MHGDisplayWarningForUntrackingFiles		= @"DisplayWarningForUntrackingFiles";
NSString* const MHGDisplayWarningForUpdating			= @"DisplayWarningForUpdating";
NSString* const MHGExecutableLocationHG					= @"ExecutableLocationHG";
NSString* const MHGExecutableLocationOpenDiff			= @"ExecutableLocationOpenDiff";
NSString* const MHGFontSizeOfBrowserItems				= @"FontSizeOfBrowserItems";
NSString* const MHGHandleCommandDefaults				= @"HandleCommandDefaults";
NSString* const MHGHandleGeneratedOrigFiles				= @"HandleGeneratedOrigFiles";
NSString* const MHGLaunchCount							= @"LaunchCount";
NSString* const MHGLogEntryTableBookmarkHighlightColor	= @"LogEntryTableBookmarkHighlightColor";
NSString* const MHGLogEntryTableBranchHighlightColor	= @"LogEntryTableBranchHighlightColor";
NSString* const MHGLogEntryTableDisplayChangesetColumn	= @"LogEntryTableDisplayChangesetColumn";
NSString* const MHGLogEntryTableParentHighlightColor	= @"LogEntryTableParentHighlightColor";
NSString* const MHGLogEntryTableTagHighlightColor		= @"LogEntryTableTagHighlightColor";
NSString* const MHGLoggingLevelForHGCommands			= @"LoggingLevelForHGCommands";
NSString* const MHGMacHgLogFileLocation					= @"MacHgLogFileLocation";
NSString* const MHGOnStartupOpen						= @"OnApplicationStartupOpenWhat";
NSString* const MHGShowAddedFilesInBrowser				= @"ShowAddedFilesInBrowser";
NSString* const MHGShowCleanFilesInBrowser				= @"ShowCleanFilesInBrowser";
NSString* const MHGShowFilePreviewInBrowser				= @"ShowFilePreviewInBrowser";
NSString* const MHGShowIgnoredFilesInBrowser			= @"ShowIgnoredFilesInBrowser";
NSString* const MHGShowMissingFilesInBrowser			= @"ShowMissingFilesInBrowser";
NSString* const MHGShowModifiedFilesInBrowser			= @"ShowModifiedFilesInBrowser";
NSString* const MHGShowRemovedFilesInBrowser			= @"ShowRemovedFilesInBrowser";
NSString* const MHGShowResolvedFilesInBrowser			= @"ShowResolvedFilesInBrowser";
NSString* const MHGShowUnknownFilesInBrowser			= @"ShowUnknownFilesInBrowser";
NSString* const MHGShowUnresolvedFilesInBrowser			= @"ShowUnresolvedFilesInBrowser";
NSString* const MHGSizeOfBrowserColumns					= @"SizeOfBrowserColumns";
NSString* const MHGUseFileMergeForDiff					= @"UseFileMergeForDiff";
NSString* const MHGUseFileMergeForMerge					= @"UseFileMergeForMerge";
NSString* const MHGUseWhichMercurialBinary				= @"UseWhichMercurialBinary";
NSString* const MHGWarnAboutBadMercurialConfiguration   = @"WarnAboutBadMercurialConfiguration";






static inline BOOL		boolFromDefaultsForKey(NSString* key)		{ return [[NSUserDefaults standardUserDefaults] boolForKey:key]; }
static inline int		enumFromDefaultsForKey(NSString* key)		{ return [[NSUserDefaults standardUserDefaults] integerForKey:key]; }
static inline int		integerFromDefaultsForKey(NSString* key)	{ return [[NSUserDefaults standardUserDefaults] integerForKey:key]; }
static inline float		floatFromDefaultsForKey(NSString* key)		{ return [[NSUserDefaults standardUserDefaults] floatForKey:key]; }
static inline NSString* stringFromDefaultsForKey(NSString* key)		{ return [[NSUserDefaults standardUserDefaults] stringForKey:key]; }
static inline NSColor*	colorFromDefaultsForKey(NSString* key)		{ return [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:key]]; }

BOOL		AddRemoveUsesSimilarityFromDefaults()					{ return boolFromDefaultsForKey(MHGAddRemoveUsesSimilarity); }
BOOL		AllowHistoryEditingOfRepositoryFromDefaults()			{ return boolFromDefaultsForKey(MHGAllowHistoryEditingOfRepository); }
BOOL		DefaultAnnotationOptionChangesetFromDefaults()			{ return boolFromDefaultsForKey(MHGDefaultAnnotationOptionChangeset); }
BOOL		DefaultAnnotationOptionDateFromDefaults()				{ return boolFromDefaultsForKey(MHGDefaultAnnotationOptionDate); }
BOOL		DefaultAnnotationOptionFollowFromDefaults()				{ return boolFromDefaultsForKey(MHGDefaultAnnotationOptionFollow); }
BOOL		DefaultAnnotationOptionLineNumberFromDefaults()			{ return boolFromDefaultsForKey(MHGDefaultAnnotationOptionLineNumber); }
BOOL		DefaultAnnotationOptionNumberFromDefaults()				{ return boolFromDefaultsForKey(MHGDefaultAnnotationOptionNumber); }
BOOL		DefaultAnnotationOptionTextFromDefaults()				{ return boolFromDefaultsForKey(MHGDefaultAnnotationOptionText); }
BOOL		DefaultAnnotationOptionUserFromDefaults()				{ return boolFromDefaultsForKey(MHGDefaultAnnotationOptionUser); }
BOOL		DisplayFileIconsInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayFileIconsInBrowser); }
BOOL		DisplayResultsOfAddRemoveRenameFilesFromDefaults()		{ return boolFromDefaultsForKey(MHGDisplayResultsOfAddRemoveRenameFiles); }
BOOL		DisplayResultsOfMergingFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayResultsOfMerging); }
BOOL		DisplayResultsOfPullingFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayResultsOfPulling); }
BOOL		DisplayResultsOfPushingFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayResultsOfPushing); }
BOOL		DisplayResultsOfUpdatingFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayResultsOfUpdating); }
BOOL		DisplayWarningForAddRemoveRenameFilesFromDefaults()		{ return boolFromDefaultsForKey(MHGDisplayWarningForAddRemoveRenameFiles); }
BOOL		DisplayWarningForBranchNameRemovalFromDefaults()		{ return boolFromDefaultsForKey(MHGDisplayWarningForBranchNameRemoval); }
BOOL		DisplayWarningForFileDeletionFromDefaults()				{ return boolFromDefaultsForKey(MHGDisplayWarningForFileDeletion); }
BOOL		DisplayWarningForMarkingFilesResolvedFromDefaults()		{ return boolFromDefaultsForKey(MHGDisplayWarningForMarkingFilesResolved); }
BOOL		DisplayWarningForMergingFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayWarningForMerging); }
BOOL		DisplayWarningForPostMergeFromDefaults()				{ return boolFromDefaultsForKey(MHGDisplayWarningForPostMerge); }
BOOL		DisplayWarningForPullingFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayWarningForPulling); }
BOOL		DisplayWarningForPushingFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayWarningForPushing); }
BOOL		DisplayWarningForRenamingFilesFromDefaults()			{ return boolFromDefaultsForKey(MHGDisplayWarningForRenamingFiles); }
BOOL		DisplayWarningForRepositoryDeletionFromDefaults()		{ return boolFromDefaultsForKey(MHGDisplayWarningForRepositoryDeletion); }
BOOL		DisplayWarningForRevertingFilesFromDefaults()			{ return boolFromDefaultsForKey(MHGDisplayWarningForRevertingFiles); }
BOOL		DisplayWarningForRollbackFilesFromDefaults()			{ return boolFromDefaultsForKey(MHGDisplayWarningForRollbackFiles); }
BOOL		DisplayWarningForTagRemovalFromDefaults()				{ return boolFromDefaultsForKey(MHGDisplayWarningForTagRemoval); }
BOOL		DisplayWarningForUntrackingFilesFromDefaults()			{ return boolFromDefaultsForKey(MHGDisplayWarningForUntrackingFiles); }
BOOL		DisplayWarningForUpdatingFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayWarningForUpdating); }
BOOL		LogEntryTableDisplayChangesetColumnFromDefaults()		{ return boolFromDefaultsForKey(MHGLogEntryTableDisplayChangesetColumn); }
BOOL		ShowAddedFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowAddedFilesInBrowser); }
BOOL		ShowCleanFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowCleanFilesInBrowser); }
BOOL		ShowFilePreviewInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowFilePreviewInBrowser); }
BOOL		ShowIgnoredFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowIgnoredFilesInBrowser); }
BOOL		ShowMissingFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowMissingFilesInBrowser); }
BOOL		ShowModifiedFilesInBrowserFromDefaults()				{ return boolFromDefaultsForKey(MHGShowModifiedFilesInBrowser); }
BOOL		ShowRemovedFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowRemovedFilesInBrowser); }
BOOL		ShowResolvedFilesInBrowserFromDefaults()				{ return boolFromDefaultsForKey(MHGShowResolvedFilesInBrowser); }
BOOL		ShowUnknownFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowUnknownFilesInBrowser); }
BOOL		ShowUnresolvedFilesInBrowserFromDefaults()				{ return boolFromDefaultsForKey(MHGShowUnresolvedFilesInBrowser); }
BOOL		UseFileMergeForDiffFromDefaults()						{ return boolFromDefaultsForKey(MHGUseFileMergeForDiff); }
BOOL		UseFileMergeForMergeFromDefaults()						{ return boolFromDefaultsForKey(MHGUseFileMergeForMerge); }
BOOL		WarnAboutBadMercurialConfigurationFromDefaults()		{ return boolFromDefaultsForKey(MHGWarnAboutBadMercurialConfiguration); }


NSColor*	LogEntryTableParentHighlightColor()						{ return colorFromDefaultsForKey(MHGLogEntryTableParentHighlightColor); }
NSColor*	LogEntryTableTagHighlightColor()						{ return colorFromDefaultsForKey(MHGLogEntryTableTagHighlightColor); }
NSColor*	LogEntryTableBranchHighlightColor()						{ return colorFromDefaultsForKey(MHGLogEntryTableBranchHighlightColor); }
NSColor*	LogEntryTableBookmarkHighlightColor()					{ return colorFromDefaultsForKey(MHGLogEntryTableBookmarkHighlightColor); }


NSString*	AddRemoveSimilarityFactorFromDefaults()					{ return intAsString((int)(round(100 * floatFromDefaultsForKey(MHGAddRemoveSimilarityFactor)))); }
NSString*	DefaultWorkspacePathFromDefaults()						{ return [stringFromDefaultsForKey(MHGDefaultWorkspacePath) stringByStandardizingPath]; }
NSString*	ExecutableLocationHGFromDefaults()						{ return stringFromDefaultsForKey(MHGExecutableLocationHG); }
NSString*	ExecutableLocationOpenDiffFromDefaults()				{ return stringFromDefaultsForKey(MHGExecutableLocationOpenDiff); }
NSString*	MacHgLogFileLocation()									{ return stringFromDefaultsForKey(MHGMacHgLogFileLocation); }
NSString*	DefaultHGIgnoreContentsFromDefaults()					{ return stringFromDefaultsForKey(MHGDefaultHGIgnoreContents); }
float		fontSizeOfBrowserItemsFromDefaults()					{ return floatFromDefaultsForKey(MHGFontSizeOfBrowserItems); }
float		sizeOfBrowserColumnsFromDefaults()						{ return floatFromDefaultsForKey(MHGSizeOfBrowserColumns); }
int			LoggingLevelForHGCommands()								{ return integerFromDefaultsForKey(MHGLoggingLevelForHGCommands); }
int			LaunchCountFromDefaults()								{ return integerFromDefaultsForKey(MHGLaunchCount); }

BrowserDoubleClickAction browserBehaviourCommandDoubleClick()		{ return enumFromDefaultsForKey(MHGBrowserBehaviourCommandDoubleClick); }
BrowserDoubleClickAction browserBehaviourCommandOptionDoubleClick()	{ return enumFromDefaultsForKey(MHGBrowserBehaviourCommandOptionDoubleClick); }
BrowserDoubleClickAction browserBehaviourDoubleClick()				{ return enumFromDefaultsForKey(MHGBrowserBehaviourDoubleClick); }
BrowserDoubleClickAction browserBehaviourOptionDoubleClick()		{ return enumFromDefaultsForKey(MHGBrowserBehaviourOptionDoubleClick); }
AfterMergeDoOption			AfterMergeDoFromDefaults()				{ return enumFromDefaultsForKey(MHGAfterMergeDo); }
AfterMergeSwitchToOption	AfterMergeSwitchToFromDefaults()		{ return enumFromDefaultsForKey(MHGAfterMergeSwitchTo); }
HandleCommandDefaultsOption	HandleCommandDefaultsFromDefaults()		{ return enumFromDefaultsForKey(MHGHandleCommandDefaults); }
HandleOrigFilesOption		HandleGeneratedOrigFilesFromDefaults()	{ return enumFromDefaultsForKey(MHGHandleGeneratedOrigFiles); }
OnStartupOpenWhatOption		OnStartupOpenFromDefaults()				{ return enumFromDefaultsForKey(MHGOnStartupOpen); }
UseWhichMercurialOption		UseWhichMercurialBinaryFromDefaults()	{ return enumFromDefaultsForKey(MHGUseWhichMercurialBinary); }
DefaultRevisionSortOrderOption DefaultRevisionSortOrderFromDefaults()	{ return enumFromDefaultsForKey(MHGDefaultRevisionSortOrder); }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Processes
// -----------------------------------------------------------------------------------------------------------------------------------------

void dispatchWithTimeOut(dispatch_queue_t q, NSTimeInterval t, BlockProcess theBlock)
{
	dispatch_time_t timeOutTime = dispatch_time(DISPATCH_TIME_NOW, t * NSEC_PER_SEC);
	DispatchGroup group = dispatch_group_create();
	dispatch_group_async(group, q, theBlock);
	dispatch_group_wait(group, timeOutTime);
	dispatchGroupFinish(group);
}

void dispatchWithTimeOutBlock(dispatch_queue_t q, NSTimeInterval t, BlockProcess mainBlock, BlockProcess timeoutBlock)
{
	dispatch_time_t timeOutTime = dispatch_time(DISPATCH_TIME_NOW, t * NSEC_PER_SEC);
	DispatchGroup group = dispatch_group_create();
	dispatch_group_async(group, q, mainBlock);
	long result = dispatch_group_wait(group, timeOutTime);
	if (result != 0)
		dispatch_group_async(group, q, timeoutBlock);
	dispatchGroupFinish(group);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Dialogs
// -----------------------------------------------------------------------------------------------------------------------------------------

NSAlert* NewAlertPanel(NSString* title, NSString* message, NSString* defaultButton, NSString* alternateButton, NSString* otherButton)
{
	NSAlert* alert = [NSAlert new];
	[alert setInformativeText:message];
	[alert setMessageText:title];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert addButtonWithTitle:defaultButton];
	if (alternateButton != nil)
		[alert addButtonWithTitle:alternateButton];
	if (otherButton != nil)
		[alert addButtonWithTitle:otherButton];
	return alert;
}

NSInteger RunAlertExtractingSuppressionResult(NSAlert* alert, NSString* keyForBooleanDefault)
{
	int result = [alert runModal];
	if ([[alert suppressionButton] state] == NSOnState)
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:keyForBooleanDefault];
	return result;
}

NSInteger RunCriticalAlertPanelWithSuppression(NSString* title, NSString* message, NSString* defaultButton, NSString* alternateButton, NSString* keyForBooleanDefault)
{
	return RunCriticalAlertPanelOptionsWithSuppression(title, message, defaultButton, alternateButton, nil, keyForBooleanDefault);
}

NSInteger RunCriticalAlertPanelOptionsWithSuppression(NSString* title, NSString* message, NSString* defaultButton, NSString* alternateButton, NSString* otherButton, NSString* keyForBooleanDefault)
{
	NSAlert* alert = NewAlertPanel(title, message, defaultButton, alternateButton, otherButton);
	[alert addSuppressionCheckBox];
	return RunAlertExtractingSuppressionResult(alert, keyForBooleanDefault);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

BOOL pathContainedIn(NSString* base, NSString* path)
{
	return path && base && [path hasPrefix:base];
}

NSString* pathDifference(NSString* base, NSString* path)
{
	int baseLength = [base length];
	int pathLength = [path length];
	if (pathLength <= baseLength)
		return @"";
	if ([[path substringToIndex:baseLength] isNotEqualToString:base])
		return @"";
	return [path substringFromIndex:baseLength+1]; // The +1 gets rid of the /, ie the diff between /foo/bar and
												   // /foo/bar/fish/rover is /fish/rover but we want to return only fish/rover.
}

NSArray* parentPaths(NSArray* filteredPaths, NSString* rootPath)
{
	NSMutableArray* theParentPaths = [[NSMutableArray alloc] init];
	for (NSString* path in filteredPaths)
	{
		NSString* parent = [path stringByDeletingLastPathComponent];
		if ([pathDifference(rootPath, parent) isEqualToString:@""])
			parent = rootPath;
		if (![theParentPaths containsObject:parent])
			[theParentPaths addObject:parent];
	}
	return theParentPaths;
}

void moveFilesToTheTrash(NSArray* absolutePaths)
{
	for (NSString* path in absolutePaths)
	{
		FSRef outRef;
		OSStatus err = FSPathMakeRef((const UInt8*)[path fileSystemRepresentation], &outRef, NULL);
		if (err == noErr)
			dispatch_async(globalQueue(), ^{
				FSMoveObjectToTrashSync (&outRef, NULL, kFSFileOperationSkipSourcePermissionErrors);
			});
	}
}


BOOL pathIsLink(NSString* path)
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
	return fileAttributes ? [[fileAttributes fileType] isEqualToString:NSFileTypeSymbolicLink] : NO;
}


BOOL pathIsExistentDirectory(NSString* path)
{
	BOOL isDir = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
	return (exists && isDir);
}

BOOL pathIsExistentFile(NSString* path)
{
	BOOL isDir = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
	return (exists && !isDir);
}


BOOL pathIsReadable(NSString* path)
{
	return [[NSFileManager defaultManager] isReadableFileAtPath:path];
}


BOOL pathIsVisible(NSString* path)
{
	// Make this as sophisticated for example to hide more files you don't think the user should see!
	NSString* lastPathComponent = [path lastPathComponent];
	return ([lastPathComponent length] ? ([lastPathComponent characterAtIndex:0]!='.') : NO);
}


BOOL repositoryExistsAtPath(NSString* path)
{
	NSString* repositoryDotHGDirPath = [path stringByAppendingPathComponent:@".hg"];
	return pathIsExistentDirectory(repositoryDotHGDirPath);
}

NSArray* pruneDisallowedPaths(NSArray* paths)
{
	NSMutableArray* pruned = [[NSMutableArray alloc]init];
	for (NSString* path in paths)
		if (![[path lastPathComponent] isEqualToString:@".hg"])
			[pruned addObject:path];
	return pruned;
}


// Assumes all paths are directories and there are no duplicates
NSArray* pruneContainedPaths(NSArray* paths)
{
	NSMutableArray* pruned = [[NSMutableArray alloc]init];
	for (NSString* path in paths)
	{
		BOOL includePath = YES;
		for (NSString* compare in paths)
			if ([path hasPrefix:compare] && [path isNotEqualTo:compare])
				includePath = NO;
		if (includePath)
			[pruned addObject:path];
	}
	return pruned;
}


NSString* getSingleDirectoryPathFromOpenPanel()
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	NSInteger result = [panel runModal];
	if (result == NSAlertAlternateReturn)
		return nil;
	NSArray* filenames = [panel filenames];
	id filename = [filenames lastObject];
	return DynamicCast(NSString,filename);
}


NSString* getSingleFilePathFromOpenPanel()
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	NSInteger result = [panel runModal];
	if (result == NSAlertAlternateReturn)
		return nil;
	NSArray* filenames = [panel filenames];
	id filename = [filenames lastObject];
	return DynamicCast(NSString,filename);
}

NSArray* getListOfFilePathsFromOpenPanel(NSString* startingPath)
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setDirectoryURL:[NSURL fileURLWithPath:startingPath]];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:YES];
	NSInteger result = [panel runModal];
	if (result == NSAlertAlternateReturn)
		return nil;
	return [panel filenames];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

NSNumber*		NOasNumber  = nil;
NSNumber*		YESasNumber = nil;
NSNumber*		SlotNumber  = nil;

// Font attributes
NSDictionary*	boldSystemFontAttributes		      = nil;
NSDictionary*	graySystemFontAttributes              = nil;
NSDictionary*	italicSidebarFontAttributes           = nil;
NSDictionary*	italicSystemFontAttributes		      = nil;
NSDictionary*	italicVirginSidebarFontAttributes	  = nil;
NSDictionary*	smallBoldCenteredSystemFontAttributes = nil;
NSDictionary*	smallBoldSystemFontAttributes         = nil;
NSDictionary*	smallCenteredSystemFontAttributes     = nil;
NSDictionary*	smallItalicSystemFontAttributes       = nil;
NSDictionary*	smallSystemFontAttributes             = nil;
NSDictionary*	smallGraySystemFontAttributes         = nil;
NSDictionary*	standardSidebarFontAttributes         = nil;
NSDictionary*	standardVirginSidebarFontAttributes   = nil;
NSDictionary*	systemFontAttributes			      = nil;

void PlayBeep()
{
	NSBeep();
}


NSString* executableLocationHG()
{
	switch (UseWhichMercurialBinaryFromDefaults())
	{
		case eUseMercurialBinarySpecifiedByUser:	return ExecutableLocationHGFromDefaults();
		default :
		case eUseMercurialBinaryIncludedInMacHg:	return [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"localhg"];
	}
}


int	bitCount(int num)
{
	int count = 0;
	while (num != 0)
	{
		count += num & 1;
		num = num >> 1;
	}
	return count;
}


NSString* riffleComponents(NSArray* components, NSString* separator)
{
	return [components componentsJoinedByString:separator];
}


NSString* trimString(NSString* string)
{
	return [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

NSString* trimTrailingString(NSString* string)
{
	NSString* trimmed = nil;
	[string getCapturesWithRegexAndComponents:@"(?s:^(.*?)\\s*$)" firstComponent:&trimmed];
	return trimmed;
}

NSString* collapseWhiteSpace(NSString* string)
{
	return [string stringByReplacingOccurrencesOfRegex:@"\\s+" withString:@""];
}

BOOL stringIsNonWhiteSpace(NSString* string)
{
	return [[string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Sorting
// -----------------------------------------------------------------------------------------------------------------------------------------

NSInteger sortIntsAscending(id num1, id num2, void* context)
{
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    if (v1 > v2)
        return NSOrderedDescending;
	return NSOrderedSame;
}

NSInteger sortIntsDescending(id num1, id num2, void* context)
{
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 > v2)
        return NSOrderedAscending;
    if (v1 < v2)
        return NSOrderedDescending;
	return NSOrderedSame;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Attributed Strings
// -----------------------------------------------------------------------------------------------------------------------------------------

NSDictionary* coloredFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSColor* textColor = [NSColor colorWithDeviceRed:(200.0/255.0) green:(13.0/255.0) blue:(13.0/255.0) alpha:1.0];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: textColor, NSForegroundColorAttributeName, nil];
	}
	return theDictionary;
}

NSAttributedString* coloredAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:coloredFontAttributes()]; }


NSDictionary* emphasizedSheetMessageFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		NSColor* textColor = [NSColor colorWithDeviceRed:(190.0/255.0) green:(13.0/255.0) blue:(13.0/255.0) alpha:1.0];
		NSFont* font = [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	return theDictionary;
}

NSDictionary* normalSheetMessageFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		NSFont* font = [NSFont messageFontOfSize:[NSFont smallSystemFontSize]];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	return theDictionary;
}

NSDictionary* fixedWidthResultsMessageFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSFont* font = [NSFont fontWithName:@"Monaco"  size:9];
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		float charWidth = [[font screenFontWithRenderingMode:NSFontDefaultRenderingMode] advancementForGlyph:(NSGlyph) ' '].width;
		[paragraphStyle setDefaultTabInterval:(charWidth * 4)];
		[paragraphStyle setTabStops:[NSArray array]];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	return theDictionary;
}

NSAttributedString*      emphasizedSheetMessageAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:emphasizedSheetMessageFontAttributes()]; }
NSAttributedString*          normalSheetMessageAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:normalSheetMessageFontAttributes()]; }
NSAttributedString*     fixedWidthResultsMessageAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:fixedWidthResultsMessageFontAttributes()]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Debugging
// -----------------------------------------------------------------------------------------------------------------------------------------

void printRect(NSString* message, NSRect rect)
{
	DebugLog(@"The bounds of %@ are origin (%f, %f), and size (%f, %f)", message, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

void printPoint(NSString* message, NSPoint point)
{
	DebugLog(@"The bounds of %@ are origin (%f, %f)", message, point.x, point.y);
}

void printParentViewHierarchy(NSView* aView)
{
	NSView* theView = aView;
	while(theView)
	{
		DebugLog(@"");
		DebugLog(@"class is %@", [theView class]);
		printRect(@"visible rect", [theView visibleRect]);
		printRect(@"bounds " , [theView bounds]);
		if ([theView isKindOfClass:[NSClipView class]])
			printRect(@"documentVisibleRect " , [(NSClipView*)theView documentVisibleRect]);
		if ([theView isKindOfClass:[NSScrollView class]])
			printRect(@"documentVisibleRect " , [(NSScrollView*)theView documentVisibleRect]);
		
		theView = [theView superview];
	}
}


void printChildViewHierarchyWithIndent(NSView* view, NSString* indent)
{
	DebugLog(@"%@%@", indent, [view className]);
	NSArray* subviews = [view subviews];
	for (int i = 0; i < [subviews count]; i++)
		printChildViewHierarchyWithIndent([subviews objectAtIndex:i], [indent stringByAppendingString:@"  "]);
}

void printChildViewHierarchy(NSView* view)
{
	printChildViewHierarchyWithIndent(view, @"  ");
}

void printAttributesForString(NSAttributedString* string)
{
    NSDictionary* attributeDict;
    NSRange effectiveRange = { 0, 0 };
	
    do {
        NSRange range;
        range = NSMakeRange (NSMaxRange(effectiveRange),
                             [string length] - NSMaxRange(effectiveRange));
		
        attributeDict = [string attributesAtIndex: range.location
							longestEffectiveRange: &effectiveRange
										  inRange: range];
		
        NSLog (@"Range: %@  Attributes: %@",
               NSStringFromRange(effectiveRange), attributeDict);
		
    } while (NSMaxRange(effectiveRange) < [string length]);
	
}

void _DebugLog(const char* file, int lineNumber, const char* funcName, NSString* format,...)
{
	va_list ap;
	
	va_start (ap, format);
	if (![format hasSuffix: @"\n"])
		format = [format stringByAppendingString: @"\n"];
	
	NSString* body =  [[NSString alloc] initWithFormat: format arguments: ap];
	va_end (ap);
	const char* threadName = [[[NSThread currentThread] name] UTF8String];
	NSString* fileName=[[NSString stringWithUTF8String:file] lastPathComponent];
	if (threadName)
		fprintf(stderr,"%s/%s (%s:%d) %s",threadName,funcName,[fileName UTF8String],lineNumber,[body UTF8String]);
	else
		fprintf(stderr,"%p/%s (%s:%d) %s",[NSThread currentThread],funcName,[fileName UTF8String],lineNumber,[body UTF8String]);
	[body release];	
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Extensions
// -----------------------------------------------------------------------------------------------------------------------------------------

// MARK: -
@implementation NSObject (NSObjectPlusObservations)

- (void) postNotificationWithName:(NSString*)notificationName
{
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

- (void) postNotificationWithName:(NSString*)notificationName userInfo:(NSDictionary*)info
{
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:info];
}

- (void) observe:(NSString*)notificationName byCalling:(SEL)notificationSelector
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:notificationSelector name:notificationName object:nil];
}

- (void) observe:(NSString*)notificationName from:(id)notificationSender byCalling:(SEL)notificationSelector
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:notificationSelector name:notificationName object:notificationSender];
}

- (void) stopObserving:(NSString*)notificationName from:(id)notificationSender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:notificationName object:notificationSender];
}

- (void) stopObserving
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


// MARK: -
@implementation NSObject (NSObjectPlusUndoManager)

- (id) prepareUndoWithTarget:(id)target
{
	if ([self respondsToSelector:@selector(undoManager)])
	{
		NSUndoManager* undo = [self performSelector:@selector(undoManager)];
		return [undo prepareWithInvocationTarget:target];
	}
	return nil;
}

@end




// MARK: -
@implementation NSString ( NSStringPlusComparisons )

- (BOOL) isNotEqualToString:(NSString*)aString	{ return ![self isEqualToString:aString]; }
- (BOOL) numericCompare:(NSString*)aString		{ return [self compare:aString options:NSNumericSearch]; }

@end


// MARK: -
@implementation NSString ( NSStringPlusMatches )
- (BOOL) getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 1)
		return NO;
	*first = [parts objectAtIndex:1];
	return YES;
}
- (BOOL) getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 2)
		return NO;
	*first  = [parts objectAtIndex:1];
	*second = [parts objectAtIndex:2];
	return YES;
}
- (BOOL) getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 3)
		return NO;
	*first  = [parts objectAtIndex:1];
	*second = [parts objectAtIndex:2];
	*third  = [parts objectAtIndex:3];
	return YES;
}
- (BOOL) getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third  fourthComponent:(NSString**)fourth
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 4)
		return NO;
	*first  = [parts objectAtIndex:1];
	*second = [parts objectAtIndex:2];
	*third  = [parts objectAtIndex:3];
	*fourth = [parts objectAtIndex:4];
	return YES;
}

- (BOOL) getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 1)
		return NO;
	*first = trimString([parts objectAtIndex:1]);
	return YES;
}
- (BOOL) getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 2)
		return NO;
	*first  = trimString([parts objectAtIndex:1]);
	*second = trimString([parts objectAtIndex:2]);
	return YES;
}
- (BOOL) getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 3)
		return NO;
	*first  = trimString([parts objectAtIndex:1]);
	*second = trimString([parts objectAtIndex:2]);
	*third  = trimString([parts objectAtIndex:3]);
	return YES;
}
- (BOOL) getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third  fourthComponent:(NSString**)fourth
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 4)
		return NO;
	*first  = trimString([parts objectAtIndex:1]);
	*second = trimString([parts objectAtIndex:2]);
	*third  = trimString([parts objectAtIndex:3]);
	*fourth = trimString([parts objectAtIndex:4]);
	return YES;
}




- (BOOL) matchesRegex:(NSString*)regEx options:(RKLRegexOptions)options
{
	NSRange MaximumRange = NSMakeRange(0UL,NSUIntegerMax);
	NSRange foundRange = [self rangeOfRegex:regEx options:options inRange:MaximumRange capture:0L error:nil];
	return foundRange.location != NSNotFound;
}
- (BOOL) containsString:(NSString*)str
{
	NSRange textRange =[self rangeOfString:str];
	return textRange.location != NSNotFound;
}
@end


// MARK: -
@implementation NSAttributedString ( NSAttributedStringPlusExtensions )
+ (NSAttributedString*) string:(NSString*)string withAttributes:(NSDictionary*)theAttributes
{
	return (string && theAttributes) ? [[NSAttributedString alloc] initWithString:string attributes:theAttributes] : nil;
}
+ (NSAttributedString*) string:(NSString*)s1 withAttributes:(NSDictionary*)a1 andString:(NSString*)s2 withAttributes:(NSDictionary*)a2
{
	NSMutableAttributedString* newString = [[NSMutableAttributedString alloc]init];
	if (s1 && a1)
		[newString appendString:s1 withAttributes:a1];
	if (s2 && a2)
		[newString appendString:s2 withAttributes:a2];
	return newString;
}


+(NSAttributedString*) hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: inString];
    NSRange range = NSMakeRange(0, [attrString length]);
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];	    // make the text appear in blue
    [attrString addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];		// next make the text appear with an underline
    [attrString endEditing];
    return attrString;
}
- (NSDictionary*)		attributesOfWholeString
{
	NSRange maximumRange = ((NSRange){.location= 0UL, .length= NSUIntegerMax});
	return [self attributesAtIndex:0 effectiveRange:&maximumRange];
}
@end

// MARK: -
@implementation NSMutableAttributedString ( NSMutableAttributedStringPlusInitilizers )
+ (NSMutableAttributedString*) string:(NSString*)string withAttributes:(NSDictionary*)theAttributes;
{
	return [[NSMutableAttributedString alloc] initWithString:string attributes:theAttributes];
}
- (void) appendString:(NSString*)string withAttributes:(NSDictionary*)theAttributes
{
	[self appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:theAttributes]];
}
@end


// MARK: -
@implementation NSDate ( NSDatePlusComparisons )
- (BOOL)	isBefore:(NSDate*)aDate
{
	return ([self compare:aDate] == NSOrderedAscending);
}
@end


// MARK: -
@implementation NSMutableArray ( NSMutableArrayPlusAccessors )
- (void)	addObject:(id)object1 followedBy:(id)object2
{
	[self addObject:object1];
	[self addObject:object2];
}

- (void)	addObject:(id)object1 followedBy:(id)object2 followedBy:(id)object3
{
	[self addObject:object1];
	[self addObject:object2];
	[self addObject:object3];
}

- (id) popLast
{
	@try
	{
		id ans = [self lastObject];
		if (ans)
			[self removeLastObject];
		return ans;
	}
	@catch (NSException* ne) { return nil; }
	return nil;	// Keep compiler happy
}

@end


// MARK: -
@implementation NSArray ( NSArrayPlusAccessors )

- (id) firstObject
{
	@try
	{
		return [self objectAtIndex:0];
	}
	@catch (NSException* ne) { return nil; }
	return nil;	// Keep compiler happy
}

@end




// MARK: -
@implementation NSDictionary ( NSDictionaryPlusAccessors )
- (id) synchronizedObjectForKey:(id)aKey			{ @synchronized(self) { return [self objectForKey:aKey]; }; /*keep gcc happy*/ return nil; }
- (NSArray*) synchronizedAllKeys					{ @synchronized(self) { return [self allKeys]; }; /*keep gcc happy*/ return nil; }
- (NSInteger) synchronizedCount						{ @synchronized(self) { return [self count]; }; /*keep gcc happy*/ return 0; }
- (id) synchronizedValueForNumberKey:(NSNumber*)key	{ @synchronized(self) { return [self valueForKey:[key stringValue]]; }; /*keep gcc happy*/ return nil; }
- (id) valueForNumberKey:(NSNumber*)key		{ return [self valueForKey:[key stringValue]]; }
@end


// MARK: -
@implementation NSMutableDictionary ( NSMutableDictionaryPlusAccessors )
- (void) synchronizedSetObject:(id)anObject forKey:(id)aKey			{ @synchronized(self) { [self setObject:anObject forKey:aKey]; }; }
- (void) synchronizedRemoveObjectForKey:(id)aKey					{ @synchronized(self) { [self removeObjectForKey:aKey]; }; }
- (void) synchronizedSetValue:(id)value forNumberKey:(NSNumber*)key	{ @synchronized(self) { [self setValue:value forKey:[key stringValue]]; }; }
- (void) setValue:(id)value forNumberKey:(NSNumber*)key				{ [self setValue:value forKey:[key stringValue]]; }
@end




// MARK: -
@implementation NSWorkspace ( NSWorkspacePlusExtensions )
+ (NSImage*) iconImageOfSize:(NSSize)size forPath:(NSString*)path
{
	NSImage* nodeImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
	if (!nodeImage)
        nodeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[path pathExtension]];        // No icon for actual file, try the extension.
	
	[nodeImage setSize:size];
    
	if (!nodeImage)
        nodeImage = [NSImage imageNamed:@"FSIconImage-Default"];
	
	return nodeImage;
}
@end


// MARK: -
@implementation NSFileManager ( NSFileManagerPlusAppending )
- (void) appendString:(NSString*)string toFilePath:(NSString*)path
{
	if (![self fileExistsAtPath:path])
		[self createFileAtPath:path contents:nil attributes:nil];
	
	NSFileHandle* output = [NSFileHandle fileHandleForWritingAtPath:path];
	[output seekToEndOfFile];
	[output writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}
@end


// MARK: -
@implementation NSFileHandle (CSFileHandleExtensions)
- (NSData*)	readDataToEndOfFileIgnoringErros
{
	int tryCount = 0;
	for (;;)
	{
		if (tryCount++ > 3)
			return nil;
		@try
		{
			return [self readDataToEndOfFile];
		}
		@catch (NSException *e)
		{
			if ([[e name] isEqualToString:NSFileHandleOperationException])
			{
				if ([[e reason] isEqualToString:@"*** -[NSConcreteFileHandle readDataOfLength:]: Bad file descriptor"])
				{
					usleep(0.3 * USEC_PER_SEC);
					continue;
				}
				return nil;
			}
			@throw;
		}
	}
}

@end

// MARK: -
@implementation NSAlert ( NSAlertPlusExtensions )
- (void) addSuppressionCheckBox
{
	NSAttributedString* smallSuppressionMessage = [NSAttributedString string:@"Do not show this message again" withAttributes: smallSystemFontAttributes];
	[self setShowsSuppressionButton:YES];
	[[self suppressionButton] setAttributedTitle:smallSuppressionMessage];	
}
@end


// MARK: -
@implementation NSColor ( NSColorPlusExtensions )
- (NSColor*) intensifySaturationAndBrightness:(double)factor
{
	CGFloat h,s,b,a;
	[self getHue:&h saturation:&s brightness:&b alpha:&a];
	return [NSColor colorWithCalibratedHue: h saturation:s*factor brightness:b*factor alpha:a];
}
@end


// MARK: -
@implementation NSView ( NSViewPlusExtensions )

- (void)	setCenterX:(CGFloat)coord
{
	NSRect theFrame = [self frame];
	CGFloat newOriginX = coord - theFrame.size.width / 2;
	if (newOriginX != theFrame.origin.x)
	{
		theFrame.origin.x = newOriginX;
		[[self animator] setFrame:theFrame];
	}
}

- (void)	setMinX:(CGFloat)coord
{
	NSRect theFrame = [self frame];
	CGFloat newOriginX = coord;
	if (newOriginX != theFrame.origin.x)
	{
		theFrame.origin.x = newOriginX;
		[[self animator] setFrame:theFrame];
	}
}

- (void)	setMaxX:(CGFloat)coord
{
	NSRect theFrame = [self frame];
	CGFloat newOriginX = coord - theFrame.size.width;
	if (newOriginX != theFrame.origin.x)
	{
		theFrame.origin.x = newOriginX;
		[[self animator] setFrame:theFrame];
	}
}

@end


// MARK: -
@implementation NSTableView ( NSTableViewPlusExtensions )
- (void) selectRow:(NSInteger)row	{ [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO]; }
- (BOOL) rowWasClicked				{ return [self clickedRow] != -1; }

- (NSInteger) chosenRow
{
	NSInteger clickedRow = [self clickedRow];
	return (clickedRow != -1) ? clickedRow : [self selectedRow];
}

- (void) scrollToRangeOfRowsLow:(NSInteger)lowTableRow high:(NSInteger)highTableRow
{
	// By doing these 3 scrolls we try to get the table to display the selected low and high rows somewhat in the middle or at least with 5
	// values either side of it in the table.
	NSInteger tableRowCount = [self numberOfRows];

	if (highTableRow != NSNotFound)
		[self scrollRowToVisible:MIN(highTableRow+5, tableRowCount)];
	if (lowTableRow != NSNotFound)
		[self scrollRowToVisible:MAX(0,lowTableRow-5)];
	if (highTableRow != NSNotFound)
		[self scrollRowToVisible:highTableRow];

	// Finally if we can fit in the last row then we do so since it generally looks better
	NSRect clippedView = [[self enclosingScrollView] documentVisibleRect];
	NSRange theRange = [self rowsInRect: clippedView];
	if (!NSLocationInRange(tableRowCount, theRange))
		if (lowTableRow == NSNotFound || tableRowCount - lowTableRow < theRange.length)
			[self scrollRowToVisible:(tableRowCount - 1)];
}

@end



