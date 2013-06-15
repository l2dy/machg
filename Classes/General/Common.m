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
#import <CommonCrypto/CommonDigest.h> // for SHA1String





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Defaults
// ------------------------------------------------------------------------------------

NSString* const kSidebarPBoardType						= @"SidebarNodePBoardType";
NSString* const kSidebarRootInitializationDummy			= @"SidebarRootInitializationDummy";
NSString* const kPatchesTablePBoardType					= @"PatchesTablePBoardType";
NSString* const kMacHgApp								= @"MacHgApp";


// Notifications
NSString* const kBrowserDisplayPreferencesChanged		= @"BrowserDisplayPreferencesChanged";
NSString* const kCommandKeyIsDown						= @"CommandKeyIsDown";
NSString* const kCommandKeyIsUp							= @"CommandKeyIsUp";
NSString* const kCompatibleRepositoryChanged			= @"CompatibleRepositoryChanged";
NSString* const kFileDiffsDisplayPreferencesChanged	    = @"FileDiffsDisplayPreferencesChanged";
NSString* const kFileWasExcluded						= @"FileWasExcluded";
NSString* const kFileWasIncluded						= @"FileWasIncluded";
NSString* const kHunkWasExcluded						= @"HunkWasExcluded";
NSString* const kHunkWasIncluded						= @"HunkWasIncluded";
NSString* const kLogEntriesDidChange                    = @"LogEntriesDidChange";
NSString* const kProcessAddedToProcessList				= @"ProcessAddedToProcessList";
NSString* const kProcessRemovedFromProcessList			= @"ProcessRemovedFromProcessList";
NSString* const kReceivedCompatibleRepositoryCount		= @"ReceivedCompatibleRepositoryCount";
NSString* const kRepositoryDataDidChange				= @"RepositoryDataDidChange";
NSString* const kRepositoryDataIsNew					= @"RepositoryDataIsNew";
NSString* const kRepositoryIdentityChanged				= @"RepositoryIdentityChanged";
NSString* const kRepositoryRootChanged					= @"RepositoryRootChanged";
NSString* const kSidebarSelectionDidChange				= @"SidebarSelectionDidChange";
NSString* const kUnderlyingRepositoryChanged			= @"UnderlyingRepositoryChanged";


// Dictionary Keys
NSString* const kRepositoryDataChangeType				= @"RepositoryDataChangeType";
NSString* const kRepositoryBranchNameChanged			= @"RepositoryBranchNameChanged";
NSString* const kRepositoryLabelsInfoChanged			= @"RepositoryLabelsInfoChanged";
NSString* const kRepositoryParentsOfCurrentRevChanged	= @"RepositoryParentsOfCurrentRevChanged";
NSString* const kRepositoryTipChanged					= @"RepositoryTipChanged";


/* To regenerate start with a list of names and then search and replace on (\w+) -->
extern NSString* const MHG\1;
BOOL		\1FromDefaults();

NSString* const MHG\1			= @"\1";
BOOL		\1FromDefaults()					{ return boolFromDefaultsForKey(MHG\1); }

*/


// These are the names of the preferences in the plist.
NSString* const MHGAddRemoveSimilarityFactor				= @"AddRemoveSimilarityFactor";
NSString* const MHGAddRemoveUsesSimilarity					= @"AddRemoveUsesSimilarity";
NSString* const MHGAfterMergeDo								= @"AfterMergeDo";
NSString* const MHGAfterMergeSwitchTo						= @"AfterMergeSwitchTo";
NSString* const MHGAllowHistoryEditingOfRepository			= @"AllowHistoryEditingOfRepository";
NSString* const MHGAutoExpandViewerOutlines					= @"AutoExpandViewerOutlines";
NSString* const MHGBrowserBehaviourCommandDoubleClick		= @"BrowserBehaviourCommandDoubleClick";
NSString* const MHGBrowserBehaviourCommandOptionDoubleClick	= @"BrowserBehaviourCommandOptionDoubleClick";
NSString* const MHGBrowserBehaviourDoubleClick				= @"BrowserBehaviourDoubleClick";
NSString* const MHGBrowserBehaviourOptionDoubleClick		= @"BrowserBehaviourOptionDoubleClick";
NSString* const MHGDateAndTimeFormat						= @"DateAndTimeFormat";
NSString* const MHGDefaultAnnotationOptionChangeset			= @"DefaultAnnotationOptionChangeset";
NSString* const MHGDefaultAnnotationOptionDate				= @"DefaultAnnotationOptionDate";
NSString* const MHGDefaultAnnotationOptionFollow			= @"DefaultAnnotationOptionFollow";
NSString* const MHGDefaultAnnotationOptionLineNumber		= @"DefaultAnnotationOptionLineNumber";
NSString* const MHGDefaultAnnotationOptionNumber			= @"DefaultAnnotationOptionNumber";
NSString* const MHGDefaultAnnotationOptionText				= @"DefaultAnnotationOptionText";
NSString* const MHGDefaultAnnotationOptionUser				= @"DefaultAnnotationOptionUser";
NSString* const MHGDefaultFilesView							= @"DefaultFilesView";
NSString* const MHGDefaultHGIgnoreContents              	= @"DefaultHGIgnoreContents";
NSString* const MHGDefaultWorkspacePath						= @"DefaultWorkspacePath";
NSString* const MHGDiffDisplaySizeLimit						= @"DiffDisplaySizeLimit";
NSString* const MHGDifferencesWebviewDiffStyle				= @"DifferencesWebviewDiffStyle";
NSString* const MHGDisplayFileIconsInBrowser				= @"DisplayFileIconsInBrowser";
NSString* const MHGDisplayResultsOfAddRemoveRenameFiles		= @"DisplayResultsOfAddRemoveRenameFiles";
NSString* const MHGDisplayResultsOfMerging					= @"DisplayResultsOfMerging";
NSString* const MHGDisplayResultsOfPulling					= @"DisplayResultsOfPulling";
NSString* const MHGDisplayResultsOfPushing					= @"DisplayResultsOfPushing";
NSString* const MHGDisplayResultsOfUpdating					= @"DisplayResultsOfUpdating";
NSString* const MHGDisplayWarningForAddRemoveRenameFiles	= @"DisplayWarningForAddRemoveRenameFiles";
NSString* const MHGDisplayWarningForAmend					= @"DisplayWarningForAmend";
NSString* const MHGDisplayWarningForBackout					= @"DisplayWarningForBackout";
NSString* const MHGDisplayWarningForBranchNameRemoval		= @"DisplayWarningForBranchNameRemoval";
NSString* const MHGDisplayWarningForCloseBranch				= @"DisplayWarningForCloseBranch";
NSString* const MHGDisplayWarningForFileDeletion			= @"DisplayWarningForFileDeletion";
NSString* const MHGDisplayWarningForMarkingFilesResolved	= @"DisplayWarningForMarkingFilesResolved";
NSString* const MHGDisplayWarningForMerging					= @"DisplayWarningForMerging";
NSString* const MHGDisplayWarningForPostMerge				= @"DisplayWarningForPostMerge";
NSString* const MHGDisplayWarningForPulling			    	= @"DisplayWarningForPulling";
NSString* const MHGDisplayWarningForPushing			    	= @"DisplayWarningForPushing";
NSString* const MHGDisplayWarningForRenamingFiles			= @"DisplayWarningForRenamingFiles";
NSString* const MHGDisplayWarningForRepositoryDeletion		= @"DisplayWarningForRepositoryDeletion";
NSString* const MHGDisplayWarningForRevertingFiles			= @"DisplayWarningForRevertingFiles";
NSString* const MHGDisplayWarningForRollbackFiles			= @"DisplayWarningForRollbackFiles";
NSString* const MHGDisplayWarningForTagRemoval				= @"DisplayWarningForTagRemoval";
NSString* const MHGDisplayWarningForUntrackingFiles			= @"DisplayWarningForUntrackingFiles";
NSString* const MHGDisplayWarningForUpdating				= @"DisplayWarningForUpdating";
NSString* const MHGFontSizeOfBrowserItems					= @"FontSizeOfBrowserItems";
NSString* const MHGFontSizeOfDifferencesWebview				= @"FontSizeOfDifferencesWebview";
NSString* const MHGHandleGeneratedOrigFiles					= @"HandleGeneratedOrigFiles";
NSString* const MHGIncludeHomeHgrcInHGRCPATH				= @"IncludeHomeHgrcInHGRCPATH";
NSString* const MHGLaunchCount								= @"LaunchCount";
NSString* const MHGLocalHGShellAliasName					= @"LocalHGShellAliasName";
NSString* const MHGLocalWhitelistedHGShellAliasName			= @"LocalWhitelistedHGShellAliasName";
NSString* const MHGLogEntryTableBookmarkHighlightColor		= @"LogEntryTableBookmarkHighlightColor";
NSString* const MHGLogEntryTableBranchHighlightColor		= @"LogEntryTableBranchHighlightColor";
NSString* const MHGLogEntryTableDisplayBranchColumn	    	= @"LogEntryTableDisplayBranchColumn";
NSString* const MHGLogEntryTableDisplayChangesetColumn		= @"LogEntryTableDisplayChangesetColumn";
NSString* const MHGLogEntryTableParentHighlightColor		= @"LogEntryTableParentHighlightColor";
NSString* const MHGLogEntryTableTagHighlightColor			= @"LogEntryTableTagHighlightColor";
NSString* const MHGLoggingLevelForHGCommands				= @"LoggingLevelForHGCommands";
NSString* const MHGMacHgLogFileLocation						= @"MacHgLogFileLocation";
NSString* const MHGNumContextLinesForDifferencesWebview 	= @"NumContextLinesForDifferencesWebview";
NSString* const MHGOnActivationOpen							= @"OnApplicationActivationOpenWhat";
NSString* const MHGRequireVerifiedServerCertificates		= @"RequireVerifiedServerCertificates";
NSString* const MHGRevisionSortOrder						= @"RevisionSortOrder";
NSString* const MHGShowAddedFilesInBrowser					= @"ShowAddedFilesInBrowser";
NSString* const MHGShowCleanFilesInBrowser					= @"ShowCleanFilesInBrowser";
NSString* const MHGShowFilePreviewInBrowser					= @"ShowFilePreviewInBrowser";
NSString* const MHGShowIgnoredFilesInBrowser				= @"ShowIgnoredFilesInBrowser";
NSString* const MHGShowMissingFilesInBrowser				= @"ShowMissingFilesInBrowser";
NSString* const MHGShowModifiedFilesInBrowser				= @"ShowModifiedFilesInBrowser";
NSString* const MHGShowRemovedFilesInBrowser				= @"ShowRemovedFilesInBrowser";
NSString* const MHGShowResolvedFilesInBrowser				= @"ShowResolvedFilesInBrowser";
NSString* const MHGShowUnresolvedFilesInBrowser				= @"ShowUnresolvedFilesInBrowser";
NSString* const MHGShowUntrackedFilesInBrowser				= @"ShowUntrackedFilesInBrowser";
NSString* const MHGSizeOfBrowserColumns						= @"SizeOfBrowserColumns";
NSString* const MHGSubrepoSubstateCommit					= @"SubrepoSubstateCommit";
NSString* const MHGToolNameForDiffing						= @"ToolNameForDiffing";
NSString* const MHGToolNameForMerging						= @"ToolNameForMerging";
NSString* const MHGUseWhichToolForDiffing					= @"UseWhichToolForDiffing";
NSString* const MHGUseWhichToolForMerging					= @"UseWhichToolForMerging";
NSString* const MHGWarnAboutBadMercurialConfiguration   	= @"WarnAboutBadMercurialConfiguration";




static inline BOOL		boolFromDefaultsForKey(NSString* key)		{ return [[NSUserDefaults standardUserDefaults] boolForKey:key]; }
static inline int		enumFromDefaultsForKey(NSString* key)		{ return [[NSUserDefaults standardUserDefaults] integerForKey:key]; }
static inline int		integerFromDefaultsForKey(NSString* key)	{ return [[NSUserDefaults standardUserDefaults] integerForKey:key]; }
static inline float		floatFromDefaultsForKey(NSString* key)		{ return [[NSUserDefaults standardUserDefaults] floatForKey:key]; }
static inline NSString* stringFromDefaultsForKey(NSString* key)		{ return [[NSUserDefaults standardUserDefaults] stringForKey:key]; }
static inline NSColor*	colorFromDefaultsForKey(NSString* key)		{ return [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:key]]; }

BOOL		AddRemoveUsesSimilarityFromDefaults()					{ return boolFromDefaultsForKey(MHGAddRemoveUsesSimilarity); }
BOOL		AllowHistoryEditingOfRepositoryFromDefaults()			{ return boolFromDefaultsForKey(MHGAllowHistoryEditingOfRepository); }
BOOL		AutoExpandViewerOutlinesFromDefaults()					{ return boolFromDefaultsForKey(MHGAutoExpandViewerOutlines); }
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
BOOL		DisplayWarningForAmendFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayWarningForAmend); }
BOOL		DisplayWarningForBackoutFromDefaults()					{ return boolFromDefaultsForKey(MHGDisplayWarningForBackout); }
BOOL		DisplayWarningForBranchNameRemovalFromDefaults()		{ return boolFromDefaultsForKey(MHGDisplayWarningForBranchNameRemoval); }
BOOL		DisplayWarningForCloseBranchFromDefaults()				{ return boolFromDefaultsForKey(MHGDisplayWarningForCloseBranch); }
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
BOOL		IncludeHomeHgrcInHGRCPATHFromDefaults()					{ return boolFromDefaultsForKey(MHGIncludeHomeHgrcInHGRCPATH); }
BOOL		LogEntryTableDisplayBranchColumnFromDefaults()			{ return boolFromDefaultsForKey(MHGLogEntryTableDisplayBranchColumn); }
BOOL		LogEntryTableDisplayChangesetColumnFromDefaults()		{ return boolFromDefaultsForKey(MHGLogEntryTableDisplayChangesetColumn); }
BOOL		RequireVerifiedServerCertificatesFromDefaults()			{ return boolFromDefaultsForKey(MHGRequireVerifiedServerCertificates); }
BOOL		ShowAddedFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowAddedFilesInBrowser); }
BOOL		ShowCleanFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowCleanFilesInBrowser); }
BOOL		ShowFilePreviewInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowFilePreviewInBrowser); }
BOOL		ShowIgnoredFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowIgnoredFilesInBrowser); }
BOOL		ShowMissingFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowMissingFilesInBrowser); }
BOOL		ShowModifiedFilesInBrowserFromDefaults()				{ return boolFromDefaultsForKey(MHGShowModifiedFilesInBrowser); }
BOOL		ShowRemovedFilesInBrowserFromDefaults()					{ return boolFromDefaultsForKey(MHGShowRemovedFilesInBrowser); }
BOOL		ShowResolvedFilesInBrowserFromDefaults()				{ return boolFromDefaultsForKey(MHGShowResolvedFilesInBrowser); }
BOOL		ShowUnresolvedFilesInBrowserFromDefaults()				{ return boolFromDefaultsForKey(MHGShowUnresolvedFilesInBrowser); }
BOOL		ShowUntrackedFilesInBrowserFromDefaults()				{ return boolFromDefaultsForKey(MHGShowUntrackedFilesInBrowser); }
BOOL		WarnAboutBadMercurialConfigurationFromDefaults()		{ return boolFromDefaultsForKey(MHGWarnAboutBadMercurialConfiguration); }


NSColor*	LogEntryTableParentHighlightColor()						{ return colorFromDefaultsForKey(MHGLogEntryTableParentHighlightColor); }
NSColor*	LogEntryTableTagHighlightColor()						{ return colorFromDefaultsForKey(MHGLogEntryTableTagHighlightColor); }
NSColor*	LogEntryTableBranchHighlightColor()						{ return colorFromDefaultsForKey(MHGLogEntryTableBranchHighlightColor); }
NSColor*	LogEntryTableBookmarkHighlightColor()					{ return colorFromDefaultsForKey(MHGLogEntryTableBookmarkHighlightColor); }


NSString*	AddRemoveSimilarityFactorFromDefaults()					{ return intAsString((int)(round(100 * floatFromDefaultsForKey(MHGAddRemoveSimilarityFactor)))); }
NSString*	DefaultHGIgnoreContentsFromDefaults()					{ return stringFromDefaultsForKey(MHGDefaultHGIgnoreContents); }
NSString*	DefaultWorkspacePathFromDefaults()						{ return [stringFromDefaultsForKey(MHGDefaultWorkspacePath) stringByStandardizingPath]; }
NSString*	LocalHGShellAliasNameFromDefaults()						{ return stringFromDefaultsForKey(MHGLocalHGShellAliasName); }
NSString*	LocalWhitelistedHGShellAliasNameFromDefaults()			{ return stringFromDefaultsForKey(MHGLocalWhitelistedHGShellAliasName); }
NSString*	MacHgLogFileLocation()									{ return stringFromDefaultsForKey(MHGMacHgLogFileLocation); }
NSString*	ToolNameForDiffingFromDefaults()						{ return stringFromDefaultsForKey(MHGToolNameForDiffing); }
NSString*	ToolNameForMergingFromDefaults()						{ return stringFromDefaultsForKey(MHGToolNameForMerging); }
float		DiffDisplaySizeLimitFromDefaults()						{ return floatFromDefaultsForKey(MHGDiffDisplaySizeLimit); }
float		fontSizeOfBrowserItemsFromDefaults()					{ return floatFromDefaultsForKey(MHGFontSizeOfBrowserItems); }
float		FontSizeOfDifferencesWebviewFromDefaults()				{ return floatFromDefaultsForKey(MHGFontSizeOfDifferencesWebview); }
float		sizeOfBrowserColumnsFromDefaults()						{ return floatFromDefaultsForKey(MHGSizeOfBrowserColumns); }
int			LoggingLevelForHGCommands()								{ return integerFromDefaultsForKey(MHGLoggingLevelForHGCommands); }
int			LaunchCountFromDefaults()								{ return integerFromDefaultsForKey(MHGLaunchCount); }
int			NumContextLinesForDifferencesWebviewFromDefaults()		{ return integerFromDefaultsForKey(MHGNumContextLinesForDifferencesWebview); }


BrowserDoubleClickAction browserBehaviourCommandDoubleClick()	    { return enumFromDefaultsForKey(MHGBrowserBehaviourCommandDoubleClick); }
BrowserDoubleClickAction browserBehaviourCommandOptionDoubleClick() { return enumFromDefaultsForKey(MHGBrowserBehaviourCommandOptionDoubleClick); }
BrowserDoubleClickAction browserBehaviourDoubleClick()			    { return enumFromDefaultsForKey(MHGBrowserBehaviourDoubleClick); }
BrowserDoubleClickAction browserBehaviourOptionDoubleClick()	    { return enumFromDefaultsForKey(MHGBrowserBehaviourOptionDoubleClick); }
AfterMergeDoOption			AfterMergeDoFromDefaults()			    { return enumFromDefaultsForKey(MHGAfterMergeDo); }
AfterMergeSwitchToOption	AfterMergeSwitchToFromDefaults()	    { return enumFromDefaultsForKey(MHGAfterMergeSwitchTo); }
DateAndTimeFormatOption		DateAndTimeFormatFromDefaults()		    { return enumFromDefaultsForKey(MHGDateAndTimeFormat); }
FSViewerNumberDefaultOption	DefaultFilesViewFromDefaults()		    { return enumFromDefaultsForKey(MHGDefaultFilesView); }
HandleOrigFilesOption		HandleGeneratedOrigFilesFromDefaults()  { return enumFromDefaultsForKey(MHGHandleGeneratedOrigFiles); }
OnActivationOpenWhatOption	OnActivationOpenFromDefaults()		    { return enumFromDefaultsForKey(MHGOnActivationOpen); }
RevisionSortOrderOption		RevisionSortOrderFromDefaults()		    { return enumFromDefaultsForKey(MHGRevisionSortOrder); }
SubrepoSubstateCommitOption	SubrepoSubstateCommitFromDefauts()		{ return enumFromDefaultsForKey(MHGSubrepoSubstateCommit); }
ToolForDiffing				UseWhichToolForDiffingFromDefaults()    { return enumFromDefaultsForKey(MHGUseWhichToolForDiffing); }
ToolForMerging				UseWhichToolForMergingFromDefaults()    { return enumFromDefaultsForKey(MHGUseWhichToolForMerging); }
WebviewDiffStyleOption    DifferencesWebviewDiffStyleFromDefaults() { return enumFromDefaultsForKey(MHGDifferencesWebviewDiffStyle); }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Processes
// ------------------------------------------------------------------------------------

void dispatchWithTimeOut(dispatch_queue_t q, NSTimeInterval t, BlockProcess theBlock)
{
	DispatchGroup group = dispatch_group_create();
	dispatch_group_async(group, q, theBlock);
	dispatch_group_wait(group, futureDispatchTime(t));
	dispatchGroupFinish(group);
}

void dispatchWithTimeOutBlock(dispatch_queue_t q, NSTimeInterval t, BlockProcess mainBlock, BlockProcess timeoutBlock)
{
	DispatchGroup group = dispatch_group_create();
	dispatch_group_async(group, q, mainBlock);
	long result = dispatch_group_wait(group, futureDispatchTime(t));
	if (result != 0)
		dispatch_group_async(group, q, timeoutBlock);
	dispatchGroupFinish(group);
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Dialogs
// ------------------------------------------------------------------------------------

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Path Operations
// ------------------------------------------------------------------------------------

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
	if ([path characterAtIndex: baseLength] != '/')
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
	NSMutableArray* urls = [[NSMutableArray alloc]init];
	for (NSString* path in absolutePaths)
		[urls addObject:[NSURL fileURLWithPath:path]];
	[[NSWorkspace sharedWorkspace] recycleURLs:urls completionHandler:nil];
}


NSString* caseSensitiveFilePath(NSString* filePath)
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
    const char* cFilePath = [fileManager fileSystemRepresentationWithPath:filePath];
    if (cFilePath == 0 || *cFilePath == L'\0')
		return nil;
	
    int len = PATH_MAX + 1;
    char cRealPath[len];
    memset(cRealPath, 0, len);
    char* result = realpath(cFilePath, cRealPath);
	return result ? [fileManager stringWithFileSystemRepresentation:result length:strlen(result)] : nil;
}


BOOL pathIsLink(NSString* path)
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
	return fileAttributes ? [[fileAttributes fileType] isEqualToString:NSFileTypeSymbolicLink] : NO;
}

BOOL pathIsExistent(NSString* path)
{
	BOOL isDir = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
	return exists;
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


NSArray* pruneContainedPaths(NSArray* paths)
{
	// We jump through a few hoops here to ensure we don't have an n^2 algorithm and instead have a nearly linear algorithm. It
	// depends of course on fast sorting. 
	NSArray* sortedByLength = [paths sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSMutableArray* pruned = [[NSMutableArray alloc]init];
	NSString* currentBase = nil;
	for (NSString* path in sortedByLength)
	{
		if (currentBase && [path hasPrefix:currentBase])
		{
			NSInteger currentBaseLength = [currentBase length];
			if ([path length] <= [currentBase length])
				continue;
			if ([currentBase characterAtIndex:currentBaseLength-1]=='/' || [path characterAtIndex:currentBaseLength]=='/')
				continue;
		}
		else
			currentBase = path;
		[pruned addObject:path];
	}
	return pruned;
}

NSArray* restrictPathsToPaths(NSArray* inPaths, NSArray* inContainingPaths)
{
	//	NSArray* testPaths = [NSArray arrayWithObjects:@"aa/bb/cc", @"aa/bb/cc/dd", @"ab/bb/cc", @"cc", @"dd", nil];
	//	NSArray* containingPaths = [NSArray arrayWithObjects:@"aa/bb", @"cc/aa/", @"cc/bb/cc", @"dd", nil];
	//	NSArray* ans = restrictPathsToPaths(testPaths, containingPaths);
	// then result should be aa/bb/cc, aa/bb/cc/dd, cc/aa/, cc/bb/cc, dd
	
	NSArray* paths = [inPaths sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSArray* containingPaths = [inContainingPaths sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSInteger i = 0;
	NSInteger j = 0;
	NSMutableArray* restrictedPaths = [[NSMutableArray alloc]init];
	while (i < [paths count] && j < [containingPaths count])
	{
		NSString* si = paths[i];
		NSString* sj = containingPaths[j];
		if ([sj hasPrefix:si])
		{
			[restrictedPaths addObject:sj];
			j++;
			continue;
		}
		else if ([si hasPrefix:sj])
		{
			[restrictedPaths addObject:si];
			i++;
			continue;
		}
		if ([si compare:sj] == NSOrderedAscending)
		{
			i++;
			continue;
		}
		else
			j++;
	}
	return restrictedPaths;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Open Panel
// ------------------------------------------------------------------------------------


@interface OpenApplicationPanelDelegate : NSObject <NSOpenSavePanelDelegate> 
{
}
+ (OpenApplicationPanelDelegate*)	sharedOpenApplicationPanelDelegate;
@end

static OpenApplicationPanelDelegate* sharedOpenApplicationPanelDelegate_ = nil;

@implementation OpenApplicationPanelDelegate
+ (OpenApplicationPanelDelegate*) sharedOpenApplicationPanelDelegate
{
	if (!sharedOpenApplicationPanelDelegate_)
		sharedOpenApplicationPanelDelegate_ = [[self alloc] init];
	return sharedOpenApplicationPanelDelegate_;
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL*)url
{
	return [[[url path] pathExtension] isEqualToString:@"app"] || pathIsExistentDirectory([url path]);
}
@end





NSString* getSingleDirectoryPathFromOpenPanel()
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];
	[panel setAllowsMultipleSelection:NO];
	NSInteger result = [panel runModal];
	if (result == NSAlertAlternateReturn)
		return nil;
	NSArray* filenameURLs = [panel URLs];
	NSURL* filenameURL = [filenameURLs lastObject];
	return [filenameURL path];
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
	NSArray* filenameURLs = [panel URLs];
	NSURL* filenameURL = [filenameURLs lastObject];
	return [filenameURL path];
}


NSString* getSingleApplicationPathFromOpenPanel(NSString* forDocument)
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	NSString* message =  forDocument ? fstr(@"Choose an application to open the document “%@”", forDocument) : @"Choose an application";
	[panel setMessage:message];
	[panel setTitle:@"Choose Application."];
	[panel setDelegate:[OpenApplicationPanelDelegate sharedOpenApplicationPanelDelegate]];
	NSInteger result = [panel runModal];
	if (result == NSAlertAlternateReturn)
		return nil;
	NSArray* filenameURLs = [panel URLs];
	NSURL* filenameURL = [filenameURLs lastObject];
	return [filenameURL path];
}


NSArray* getListOfFilePathURLsFromOpenPanel(NSString* startingPath)
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setDirectoryURL:[NSURL fileURLWithPath:startingPath]];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:YES];
	NSInteger result = [panel runModal];
	if (result == NSAlertAlternateReturn)
		return nil;
	return [panel URLs];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// ------------------------------------------------------------------------------------

NSNumber*		NOasNumber  = nil;
NSNumber*		YESasNumber = nil;
NSNumber*		SlotNumber  = nil;
NSArray*		configurationForProgress = nil;

// Font attributes
NSDictionary*	boldSystemFontAttributes		      = nil;
NSDictionary*	graySystemFontAttributes              = nil;
NSDictionary*	italicSystemFontAttributes		      = nil;
NSDictionary*	smallBoldCenteredSystemFontAttributes = nil;
NSDictionary*	smallBoldSystemFontAttributes         = nil;
NSDictionary*	smallCenteredSystemFontAttributes     = nil;
NSDictionary*	smallItalicSystemFontAttributes       = nil;
NSDictionary*	smallSystemFontAttributes             = nil;
NSDictionary*	smallFixedWidthUserFontAttributes     = nil;
NSDictionary*	smallGraySystemFontAttributes         = nil;
NSDictionary*	standardSidebarFontAttributes         = nil;
NSDictionary*	systemFontAttributes			      = nil;

NSColor*		virginSidebarColor					  = nil;
NSColor*		virginSidebarSelectedColor			  = nil;
NSColor*		missingSidebarColor					  = nil;
NSColor*		missingSidebarSelectedColor			  = nil;

void PlayBeep()
{
	NSBeep();
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Locations
// ------------------------------------------------------------------------------------

NSString* executableLocationHG()
{
	return fstr(@"%@/%@",[[NSBundle mainBundle] resourcePath], @"localhg");
}


NSString* applicationSupportVersionedFolder()
{
	static NSString* answer = nil;
	if (!answer)
	{
		NSArray* searchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		NSString* applicationSupportFolder = searchPaths[0];
		NSString* shortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		answer = fstr(@"%@/%@/%@", applicationSupportFolder, [[NSProcessInfo processInfo] processName], shortVersion);
	}
	return answer;
}

NSString* applicationSupportFolder()
{
	static NSString* answer = nil;
	if (!answer)
	{
		NSArray* searchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		NSString* applicationSupportFolder = searchPaths[0];
		answer = fstr(@"%@/%@", applicationSupportFolder, [[NSProcessInfo processInfo] processName]);
	}
	return answer;
}

NSString* hgrcPath()
{
	NSString* macHgHGRCpath = fstr(@"%@/hgrc", applicationSupportFolder());
	if (!IncludeHomeHgrcInHGRCPATHFromDefaults())
		return macHgHGRCpath;

	NSString* homeHGRCpath  = [NSHomeDirectory() stringByAppendingPathComponent:@".hgrc"];
	return fstr(@"%@:%@", homeHGRCpath, macHgHGRCpath);		// macHgHGRCpath takes precedence
}

NSArray* aliasesForShell(NSString* path)
{
	NSString* mhgResources  = fstr(@"mhgResources='%@'", [[NSBundle mainBundle] resourcePath]);
	NSString* mhgAlias  = fstr(@"alias %@='\"${mhgResources}/localhg\"'", LocalHGShellAliasNameFromDefaults());
	NSString* ehgAlias  = fstr(@"alias %@='HGPLAIN=1 HGENCODING=UTF-8 HGRCPATH=\"%@\" \"${mhgResources}/localhg\"'", LocalWhitelistedHGShellAliasNameFromDefaults(), hgrcPath());
	NSString* terminalInfoScriptPath = fstr(@"\"${mhgResources}/terminalinformation.sh\"");
	NSString* terminalInfo  = fstr(@"%@ %@ %@", terminalInfoScriptPath, LocalHGShellAliasNameFromDefaults(), LocalWhitelistedHGShellAliasNameFromDefaults());
	NSString* combinedCmd = fstr(@"%@; %@; %@; %@", mhgResources, mhgAlias, ehgAlias, terminalInfo);
	return @[combinedCmd];
}

NSString* tempFilePathWithTemplate(NSString* nameTemplate)
{
	NSString* tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:nameTemplate];
	const char* tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
	char* tempFileNameCString = (char*)malloc(strlen(tempFileTemplateCString) + 1);
	strcpy(tempFileNameCString, tempFileTemplateCString);
	int fileDescriptor = mkstemp(tempFileNameCString);
	
	if (fileDescriptor == -1)
	{
		free(tempFileNameCString);
		return nil;
	}
	
	NSString* tempFileName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
	close(fileDescriptor);
	free(tempFileNameCString);
	return tempFileName;
}

NSString* tempDirectoryPathWithTemplate(NSString* nameTemplate, NSString* directoryPath)
{
	if (directoryPath && !pathIsExistentDirectory(directoryPath))
		[[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
	NSString* resolvedDirectoryPath = directoryPath ? directoryPath : NSTemporaryDirectory();

	NSString* tempDirectoryTemplate = [resolvedDirectoryPath stringByAppendingPathComponent:nameTemplate];
	const char* tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
	char* tempDirectoryNameCString = (char*)malloc(strlen(tempDirectoryTemplateCString) + 1);
	strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
	const char* result = mkdtemp(tempDirectoryNameCString);
	
	if (!result)
	{
		free(tempDirectoryNameCString);
		return nil;
	}
	
	NSString* tempDirectoryName = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(tempDirectoryNameCString)];
	free(tempDirectoryNameCString);
	return tempDirectoryName;
}




// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Bit Operations
// ------------------------------------------------------------------------------------

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: String Manipulation
// ------------------------------------------------------------------------------------

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

NSString* trimmedURL(NSString* string)
{
	NSString* trimmed = nil;
	[string getCapturesWithRegexAndComponents:@"(?s:^\\s*(.*?)/*\\s*$)" firstComponent:&trimmed];
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

NSString* riffleComponents(NSArray* components, NSString* separator)
{
	return [components componentsJoinedByString:separator];
}

NSString*	nonNil(NSString* string)
{
	return string ? string : @"";
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Sorting
// ------------------------------------------------------------------------------------

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Attributed Strings
// ------------------------------------------------------------------------------------

NSDictionary* coloredFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSColor* textColor = [NSColor colorWithDeviceRed:(200.0/255.0) green:(13.0/255.0) blue:(13.0/255.0) alpha:1.0];
		theDictionary = @{NSForegroundColorAttributeName: textColor};
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
		theDictionary = @{NSFontAttributeName: font, NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName: paragraphStyle};
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
		theDictionary = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle};
	}
	return theDictionary;
}

NSDictionary* grayedSheetMessageFontAttributes()
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		NSColor* textColor = [NSColor grayColor];
		NSFont* font = [NSFont messageFontOfSize:[NSFont smallSystemFontSize]];
		theDictionary = @{NSFontAttributeName: font, NSForegroundColorAttributeName: textColor, NSParagraphStyleAttributeName: paragraphStyle};
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
		[paragraphStyle setTabStops:@[]];
		theDictionary = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle};
	}
	return theDictionary;
}

NSAttributedString*       emphasizedSheetMessageAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:emphasizedSheetMessageFontAttributes()]; }
NSAttributedString*           normalSheetMessageAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:normalSheetMessageFontAttributes()]; }
NSAttributedString*           grayedSheetMessageAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:grayedSheetMessageFontAttributes()]; }
NSAttributedString*     fixedWidthResultsMessageAttributedString(NSString* string) { return [NSAttributedString string:string withAttributes:fixedWidthResultsMessageFontAttributes()]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Debugging
// ------------------------------------------------------------------------------------

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

void printResponderViewHierarchy(NSWindow* aWindow)
{
	NSResponder* theResponder = [aWindow firstResponder];
	while(theResponder)
	{
		DebugLog(@"");
		DebugLog(@"class is %@", [theResponder class]);
		DebugLog(@"description is %@", [theResponder description]);
//		if ([theResponder isKindOfClass:[NSView class]])
//			printRect(@"visible rect", [theResponder visibleRect]);
//		if ([theResponder isKindOfClass:[NSView class]])
//			printRect(@"bounds " , [theResponder bounds]);
//		if ([theView isKindOfClass:[NSClipView class]])
//			printRect(@"documentVisibleRect " , [(NSClipView*)theView documentVisibleRect]);
//		if ([theView isKindOfClass:[NSScrollView class]])
//			printRect(@"documentVisibleRect " , [(NSScrollView*)theView documentVisibleRect]);
		
		theResponder = [theResponder nextResponder];
	}
}

void printChildViewHierarchyWithIndent(NSView* view, NSString* indent)
{
	DebugLog(@"%@%@", indent, [view className]);
	NSArray* subviews = [view subviews];
	for (int i = 0; i < [subviews count]; i++)
		printChildViewHierarchyWithIndent(subviews[i], [indent stringByAppendingString:@"  "]);
}

void printChildViewHierarchy(NSView* view)
{
	printChildViewHierarchyWithIndent(view, @"  ");
}

void printAttributesForString(NSAttributedString* string)
{
    NSRange effectiveRange = { 0, 0 };
    do
	{
		NSRange range = NSMakeRange (NSMaxRange(effectiveRange), [string length] - NSMaxRange(effectiveRange));
		NSDictionary* attributeDict = [string attributesAtIndex: range.location longestEffectiveRange: &effectiveRange inRange: range];
        DebugLog(@"Range: %@  Attributes: %@", NSStringFromRange(effectiveRange), attributeDict);
    } while (NSMaxRange(effectiveRange) < [string length]);
	
}

void DebugLog_(const char* file, int lineNumber, const char* funcName, NSString* format,...)
{
	va_list ap;
	
	va_start (ap, format);
	if (![format hasSuffix: @"\n"])
		format = [format stringByAppendingString: @"\n"];
	
	NSString* body =  [[NSString alloc] initWithFormat: format arguments: ap];
	va_end (ap);
	const char* threadName = [[[NSThread currentThread] name] UTF8String];
	// NSString* fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
	if (threadName)
		fprintf(stderr,"%s/%-40s %s",threadName,funcName,[body UTF8String]);
	else
		fprintf(stderr,"%p/%-40s %s",[NSThread currentThread],funcName,[body UTF8String]);
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Extensions
// ------------------------------------------------------------------------------------

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
	[self stopObserving:notificationName from:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:notificationSelector name:notificationName object:nil];
}

- (void) observe:(NSString*)notificationName from:(id)notificationSender byCalling:(SEL)notificationSelector
{
	[self stopObserving:notificationName from:notificationSender];
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
@implementation NSObject (NSObjectPlusSelectorResponders)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (id) performSelectorIfPossible:(SEL)sel						{ return [self respondsToSelector:sel] ? [self performSelector:sel] : nil; }
- (id) performSelectorIfPossible:(SEL)sel withObject:(id)obj	{ return [self respondsToSelector:sel] ? [self performSelector:sel withObject:obj] : nil; }
#pragma clang diagnostic pop
@end



// MARK: -
@implementation NSString ( NSStringPlusComparisons )

- (unichar) firstCharacter						{ return [self characterAtIndex:0]; }
- (unichar) lastCharacter						{ return [self characterAtIndex:[self length]-1]; }
- (BOOL) isNotEqualToString:(NSString*)aString	{ return ![self isEqualToString:aString]; }
- (BOOL) differsOnlyInCaseFrom:(NSString*)aString
{
	return
		[self length] == [aString length] &&
		[self compare:aString options:NSCaseInsensitiveSearch] == NSOrderedSame &&
		[self compare:aString options:NSLiteralSearch] != NSOrderedSame;
}
- (NSComparisonResult)caseInsensitiveNumericCompare:(NSString*)aString
{
	return [self compare:aString options:(NSCaseInsensitiveSearch|NSNumericSearch|NSForcedOrderingSearch)];
}
- (BOOL) endsWithNewLine
{
	if ([self length] <= 0)
		return NO;
	static NSCharacterSet* newLines = nil;
	if (!newLines)
		newLines = [NSCharacterSet newlineCharacterSet];
	return [newLines characterIsMember:[self lastCharacter]];
}

- (NSArray*) stringDividedIntoLines
{
	NSMutableArray* lines = [[NSMutableArray alloc]init];
	NSInteger start = 0;
	while (start < [self length])
	{
		NSRange nextLine = [self lineRangeForRange:NSMakeRange(start, 1)];
		[lines addObject:[self substringWithRange:nextLine]];
		start = nextLine.location + nextLine.length;
	}
	return lines;
}

- (NSRange) fullRange
{
	return NSMakeRange(0, [self length]);
}

- (NSString*) SHA1HashString
{
	const char *cstr = [self UTF8String];
	unsigned char result[20];
	CC_SHA1(cstr, strlen(cstr), result);
	
	return [NSString stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15],
			result[16], result[17], result[18], result[19]
			];  
}

@end




// MARK: -
@implementation NSString ( NSStringPlusMatches )
- (BOOL) getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 1)
		return NO;
	if (first) *first = parts[1];
	return YES;
}
- (BOOL) getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 2)
		return NO;
	if (first)  *first  = parts[1];
	if (second) *second = parts[2];
	return YES;
}
- (BOOL) getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 3)
		return NO;
	if (first)  *first  = parts[1];
	if (second) *second = parts[2];
	if (third)  *third  = parts[3];
	return YES;
}
- (BOOL) getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third  fourthComponent:(NSString**)fourth
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 4)
		return NO;
	if (first)  *first  = parts[1];
	if (second) *second = parts[2];
	if (third)  *third  = parts[3];
	if (fourth) *fourth = parts[4];
	return YES;
}

- (BOOL) getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 1)
		return NO;
	if (first)  *first = trimString(parts[1]);
	return YES;
}
- (BOOL) getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 2)
		return NO;
	if (first)  *first  = trimString(parts[1]);
	if (second) *second = trimString(parts[2]);
	return YES;
}
- (BOOL) getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 3)
		return NO;
	if (first)  *first  = trimString(parts[1]);
	if (second) *second = trimString(parts[2]);
	if (third)  *third  = trimString(parts[3]);
	return YES;
}
- (BOOL) getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third  fourthComponent:(NSString**)fourth
{
	NSArray* parts = [self captureComponentsMatchedByRegex:regEx];
	if ([parts count] <= 4)
		return NO;
	if (first)  *first  = trimString(parts[1]);
	if (second) *second = trimString(parts[2]);
	if (third)  *third  = trimString(parts[3]);
	if (fourth) *fourth = trimString(parts[4]);
	return YES;
}


- (BOOL) isMatchedByRegex:(NSString*)regEx options:(RKLRegexOptions)options
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
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:inString];
    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString]];
    [attrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor]];	    // make the text appear in blue
    [attrString addAttribute:NSUnderlineStyleAttributeName value:@(NSSingleUnderlineStyle)];		// next make the text appear with an underline
    [attrString endEditing];
    return attrString;
}
- (NSDictionary*)		attributesOfWholeString
{
	NSRange maximumRange = ((NSRange){.location= 0UL, .length= NSUIntegerMax});
	return [self attributesAtIndex:0 effectiveRange:&maximumRange];
}
- (NSRange) fullRange
{
	return NSMakeRange(0, [self length]);
}
@end




// MARK: -
@implementation NSMutableAttributedString ( NSMutableAttributedStringPlusInitilizers )
+ (NSMutableAttributedString*) string:(NSString*)string withAttributes:(NSDictionary*)theAttributes
{
	return [[NSMutableAttributedString alloc] initWithString:string attributes:theAttributes];
}
- (void) appendString:(NSString*)string withAttributes:(NSDictionary*)theAttributes
{
	[self appendAttributedString:[[NSAttributedString alloc] initWithString:string attributes:theAttributes]];
}
- (void) addAttribute:(NSString*)name value:(id)value
{
	[self addAttribute:name value:value range:[self fullRange]];
}
@end




// MARK: -
@implementation NSDate ( NSDatePlusUtilities )
- (BOOL)	  isBefore:(NSDate*)aDate	{ return [self compare:aDate] == NSOrderedAscending; }
- (NSString*) isodateDescription		{ return [self descriptionWithCalendarFormat:nil timeZone:nil locale:nil]; }

+ (NSDate*)   dateWithUTCdatePlusOffset:(NSString*)utcDatePlusOffset
{
	NSString* base;
	NSString* rest;
	BOOL matched;
	
	// Try to match a date of the form 'digits.digits +|-digits'
	matched = [utcDatePlusOffset getCapturesWithRegexAndTrimedComponents:@"^(\\d+\\.?\\d*)\\s*(\\+|-\\d+)$" firstComponent:&base secondComponent:&rest];
	if (matched)
	{
		// We ignore the offset since the UTC date contains all of the information
		double date   = [base floatValue];
		if (date != NAN)
			return [NSDate dateWithTimeIntervalSince1970: date];
	}
	
	// Try to match a date of the form 'digits.digits'
	matched = [utcDatePlusOffset getCapturesWithRegexAndTrimedComponents:@"^(\\d+\\.?\\d*)\\s*$" firstComponent:&base];
	if (matched)
	{
		double date   = [base floatValue];
		if (date != NAN)
			return [NSDate dateWithTimeIntervalSince1970: date];
	}
	
	return nil;
}
@end


// MARK: -
@implementation NSTimer ( NSTimerPlusUtilities )
- (void) synchronizedInvalidate
{
	@synchronized(self)
	{
		[self invalidate];
	}
}
@end



// MARK: -
@implementation NSIndexSet ( NSIndexSetPlusAccessors )
- (BOOL) intersectsIndexes:(NSIndexSet*)indexSet
{
	NSMutableIndexSet* set = [[NSMutableIndexSet alloc]init];
	[set addIndexes:self];
	[set addIndexes:indexSet];
	return [set count] < ([self count] + [indexSet count]);
}

- (BOOL) freeOfIndex:(NSInteger)index	{ return ![self containsIndex:index]; }
@end




// MARK: -
@implementation NSMutableArray ( NSMutableArrayPlusAccessors )
- (void) addObject:(id)object1 followedBy:(id)object2
{
	[self addObject:object1];
	[self addObject:object2];
}

- (void) addObject:(id)object1 followedBy:(id)object2 followedBy:(id)object3
{
	[self addObject:object1];
	[self addObject:object2];
	[self addObject:object3];
}

- (void) addObjectIfNonNil:(id)object1	{ if (object1) [self addObject:object1]; }


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

- (id) popFirst
{
	@try
	{
		id ans = [self firstObject];
		if (ans)
			[self removeFirstObject];
		return ans;
	}
	@catch (NSException* ne) { return nil; }
	return nil;	// Keep compiler happy
}

- (void) removeFirstObject	{ [self removeObjectAtIndex:0]; }

- (void) reverse
{
    NSUInteger i = 0;
    NSUInteger j = [self count] - 1;
    while (i < j)
	{
        [self exchangeObjectAtIndex:i withObjectAtIndex:j];
        i++;
        j--;
    }
}

@end




// MARK: -
@implementation NSArray ( NSArrayPlusAccessors )

- (id) firstObject
{
	@try
	{
		return self[0];
	}
	@catch (NSException* ne) { return nil; }
	return nil;	// Keep compiler happy
}

- (NSArray*) reversedArray
{
    return [[self reverseObjectEnumerator] allObjects];
}

- (NSArray*) arrayByRemovingObject:(id)object
{
	NSMutableArray* a = [self mutableCopy];
	[a removeObject:object];
	return [NSArray arrayWithArray:a];
}

- (NSArray*) arrayByRemovingFirst
{
	if (self.count <= 1)
		return @[];
	return [self subarrayWithRange:NSMakeRange(1,self.count -1)];
}

- (NSArray*) arrayByRemovingLast
{
	if (self.count <= 1)
		return @[];
	return [self subarrayWithRange:NSMakeRange(0,self.count -1)];
}

- (NSArray*) trimArray
{
	NSRange r;
	bool foundStart = false;
	for (int i = 0; i < self.count; i++)
		if (IsNotEmpty(self[i]))
		{
			r.location = i;
			foundStart = true;
			break;
		}
	if (!foundStart)
		return @[];
	r.length = 0;	// Keep analyzer happy
	for (int i = self.count - 1; i >= r.location; i--)
		if (IsNotEmpty(self[i]))
		{
			r.length = 1 + i - r.location;
			break;
		}
	return [self subarrayWithRange:r];
}

- (NSArray*) filterArrayWithBlock:(ArrayFilterBlock)block
{
	NSMutableArray* filtered = [[NSMutableArray alloc]init];
	for (id obj in self)
		if (block(obj))
			[filtered addObject:obj];
	return [NSArray arrayWithArray:filtered];
}

@end





// MARK: -
@implementation NSDictionary ( NSDictionaryPlusAccessors )
- (id) synchronizedObjectForKey:(id)aKey			{ @synchronized(self) { return self[aKey]; }; /*keep gcc happy*/ return nil; }
- (NSArray*) synchronizedAllKeys					{ @synchronized(self) { return [self allKeys]; }; /*keep gcc happy*/ return nil; }
- (NSInteger) synchronizedCount						{ @synchronized(self) { return [self count]; }; /*keep gcc happy*/ return 0; }
- (id) synchronizedObjectForIntKey:(NSInteger)key	{ @synchronized(self) { return self[intAsNumber(key)]; }; /*keep gcc happy*/ return nil; }
- (id) objectForIntKey:(NSInteger)key				{ return self[intAsNumber(key)]; }
@end




// MARK: -
@implementation NSMutableDictionary ( NSMutableDictionaryPlusAccessors )
- (void) synchronizedSetObject:(id)anObject forKey:(id)aKey			{ @synchronized(self) { self[aKey] = anObject; }; }
- (void) synchronizedRemoveObjectForKey:(id)aKey					{ @synchronized(self) { [self removeObjectForKey:aKey]; }; }
- (void) copyValueOfKey:(id)aKey from:(NSDictionary*)aDict			{ id val = aDict[aKey]; if (val) self[aKey] = val; }
- (void) synchronizedSetObject:(id)value forIntKey:(NSInteger)key	{ @synchronized(self) { self[intAsNumber(key)] = value; }; }
- (void) setObject:(id)value forIntKey:(NSInteger)key				{ self[intAsNumber(key)] = value; }
- (id)	 objectForKey:(id)key addingIfNil:(Class)class				{ id val = self[key]; if (!val) { val = [[class alloc] init]; self[key] = val; } return val; }
@end




// MARK: -
@implementation NSTask (NSTaskPlusExtensions)
- (void) cancelTask
{
	if ([self isRunning])
		[self terminate];
}
@end




// MARK: -
@implementation NSWorkspace ( NSWorkspacePlusExtensions )
+ (NSImage*) iconImageOfSize:(NSSize)size forPath:(NSString*)path	{ return [self iconImageOfSize:size forPath:path withDefault:nil]; }
+ (NSImage*) iconImageOfSize:(NSSize)size forPath:(NSString*)path withDefault:(NSString*)defaultImageName;
{
	NSImage* nodeImage = nil;
	if (pathIsExistent(path))
		nodeImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
	if (!nodeImage && IsNotEmpty([path pathExtension]))
		nodeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[path pathExtension]];        // No icon for actual file, try the extension.    
	if (!nodeImage && defaultImageName)
		nodeImage = [NSImage imageNamed:defaultImageName];
	if (!nodeImage)
		nodeImage = [[NSWorkspace sharedWorkspace] iconForFile:path];

	[nodeImage setSize:size];

	return nodeImage;
}
@end



// MARK: -
@implementation NSApplication ( NSApplicationPlusExtensions )
- (BOOL) presentAnyErrorsAndClear:(NSError**)err
{
	if (err && *err)
	{
		[self presentError:*err];
		*err = nil;
	}
	return YES; // Keep static analyzer happy
}

+ (NSArray*) applicationsForURL:(NSURL*)url
{
	return CFBridgingRelease(LSCopyApplicationURLsForURL((__bridge CFURLRef)url, kLSRolesEditor | kLSRolesViewer));
}

+ (NSURL*) applicationForURL:(NSURL*)url
{
	CFURLRef appCFURL = nil;
	LSGetApplicationForURL( (__bridge CFURLRef)url, kLSRolesEditor | kLSRolesViewer, NULL, &appCFURL);
	NSURL* appURL = CFBridgingRelease(appCFURL);
	return appURL;
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
- (BOOL) copyItemAtPath:(NSString*)src toPath:(NSString*)dest withIntermediateDirectories:(BOOL)intermediates error:(NSError**)error
{
	NSString* destDir = [dest stringByDeletingLastPathComponent];
	if (intermediates && !pathIsExistentDirectory(destDir))
	{
		NSError* err = nil;
		[self createDirectoryAtPath:destDir withIntermediateDirectories:YES attributes:nil error:&err];
		[NSApp presentAnyErrorsAndClear:&err];
	}
	return [self copyItemAtPath:src toPath:dest error:error];
}


@end




// MARK: -
@implementation NSFileHandle (CSFileHandleExtensions)
- (NSData*)	readDataToEndOfFileIgnoringErrors
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


- (NSData*)	availableDataIgnoringErrors
{
	@try
	{
		return [self availableData];
	}
	@catch (NSException *e)
	{
		if ([[e name] isEqualToString:NSFileHandleOperationException] && [[e reason] isMatchedByRegex:@"\\[NSConcreteFileHandle availableData\\]"])
			return nil;
		@throw;
	}
	return nil;
}

@end




// MARK: -
@implementation NSAlert ( NSAlertPlusExtensions )
- (void) addSuppressionCheckBox
{
	NSAttributedString* smallSuppressionMessage = [NSAttributedString string:@"Do not show this kind of message again" withAttributes: smallSystemFontAttributes];
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

+ (NSColor*) errorColor		{ return rgbColor255(255.0, 239.0, 242.0); }
+ (NSColor*) successColor	{ return rgbColor255(240.0, 255.0, 234.0); }

//  Use this method to draw 1 px wide lines independent of scale factor. Handy for resolution independent drawing. Still needs some work - there are issues with drawing at the edges of views.
- (void) bwDrawPixelThickLineAtPosition:(int)posInPixels withInset:(int)insetInPixels inRect:(NSRect)aRect inView:(NSView*)view horizontal:(BOOL)isHorizontal flip:(BOOL)shouldFlip
{
	// Convert the given rectangle from points to pixels
	aRect = [view convertRectToBase:aRect];
	
	// Round up the rect's values to integers
	aRect = NSIntegralRect(aRect);
	
	// Add or subtract 0.5 so the lines are drawn within pixel bounds 
	if (isHorizontal)
	{
		if ([view isFlipped])
			aRect.origin.y -= 0.5;
		else
			aRect.origin.y += 0.5;
	}
	else
	{
		aRect.origin.x += 0.5;
	}
	
	NSSize sizeInPixels = aRect.size;
	
	// Convert the rect back to points for drawing
	aRect = [view convertRectFromBase:aRect];
	
	// Flip the position so it's at the other side of the rect
	if (shouldFlip)
	{
		if (isHorizontal)
			posInPixels = sizeInPixels.height - posInPixels - 1;
		else
			posInPixels = sizeInPixels.width - posInPixels - 1;
	}
	
	float posInPoints   =   posInPixels / [[NSScreen mainScreen] userSpaceScaleFactor];
	float insetInPoints = insetInPixels / [[NSScreen mainScreen] userSpaceScaleFactor];
	
	// Calculate line start and end points
	float startX, startY, endX, endY;
	
	if (isHorizontal)
	{
		startX = aRect.origin.x + insetInPoints;
		startY = aRect.origin.y + posInPoints;
		endX   = aRect.origin.x + aRect.size.width - insetInPoints;
		endY   = aRect.origin.y + posInPoints;
	}
	else
	{
		startX = aRect.origin.x + posInPoints;
		startY = aRect.origin.y + insetInPoints;
		endX   = aRect.origin.x + posInPoints;
		endY   = aRect.origin.y + aRect.size.height - insetInPoints;
	}
	
	// Draw line
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:0.0f];
	[path moveToPoint:NSMakePoint(startX,startY)];
	[path lineToPoint:NSMakePoint(endX,endY)];
	[self set];
	[path stroke];
}

@end




// MARK: -
@implementation NSView ( NSViewPlusExtensions )

- (void) setCenterX:(CGFloat)coord { [self setCenterX:coord animate:YES]; }
- (void) setCenterX:(CGFloat)coord animate:(BOOL)animate
{
	NSRect theFrame = [self frame];
	CGFloat newOriginX = round(coord - theFrame.size.width / 2);
	if (newOriginX < 0)
		newOriginX = 0;
	if (newOriginX != theFrame.origin.x)
	{
		theFrame.origin.x = newOriginX;
		if (animate)
			[[self animator] setFrame:theFrame];
		else
			[self setFrame:theFrame];
	}
}

- (void) setMinX:(CGFloat)coord
{
	NSRect theFrame = [self frame];
	CGFloat newOriginX = coord;
	if (newOriginX != theFrame.origin.x)
	{
		theFrame.origin.x = newOriginX;
		[[self animator] setFrame:theFrame];
	}
}

- (void) setMaxX:(CGFloat)coord
{
	NSRect theFrame = [self frame];
	CGFloat newOriginX = coord - theFrame.size.width;
	if (newOriginX != theFrame.origin.x)
	{
		theFrame.origin.x = newOriginX;
		[[self animator] setFrame:theFrame];
	}
}

- (void) setToRightOf:(NSView*)theView bySpacing:(CGFloat)coord
{
	NSRect theViewFrame = [theView frame];
	NSRect selfFrame = [self frame];
	selfFrame.origin.x = NSMaxX(theViewFrame) + 10;
	[[self animator] setFrame:selfFrame];
}

- (NSBox*) enclosingBoxView
{
	NSView* theView = self;
	while(theView)
	{
		if ([theView isKindOfClass:[NSBox class]])
			return (NSBox*)theView;
		theView = [theView superview];
	}
	return nil;
}

- (NSView*) enclosingViewOfClass:(Class)class
{
	NSView* theView = self;
	while(theView)
	{
		if ([theView isKindOfClass:class])
			return theView;
		theView = [theView superview];
	}
	return nil;
}

@end

// MARK: -
@implementation NSWindow ( NSWindowPlusExtensions )

// Given controls which resize with the window, look at the controls contents and if they don't fit in the given control resize
// the window appropriately.
- (void) resizeSoContentsFitInFields: (NSControl*)arg, ...
{
	NSMutableArray* arrayOfControls = [[NSMutableArray alloc]init];
    va_list args;
    va_start(args, arg);
    while( arg ) {
        [arrayOfControls addObject: arg];
        arg = va_arg(args, NSControl*);
    }
    va_end(args);
	
	CGFloat maxWidth = 0;
	CGFloat delta = 100000;
	for (NSControl* control in arrayOfControls)
		if ([control autoresizingMask] | NSViewWidthSizable)
			maxWidth = MAX(maxWidth, [[control attributedStringValue] size].width);
	for (NSControl* control in arrayOfControls)
		if ([control autoresizingMask] | NSViewWidthSizable)
			delta = MIN(delta, [control bounds].size.width - maxWidth);
	if (delta < 50 || delta > 300)
	{
		NSRect frame = [self frame];
		frame.size.width -= delta - 100;
		frame.size.width = MAX(frame.size.width, [self minSize].width);
		frame.size.width = MIN(frame.size.width, [self maxSize].width);
		[self setFrame:frame display:YES animate:NO];
	}
}

@end


// MARK: -
@implementation NSResponder ( NSResponderPlusExtensions )
- (BOOL) hasAncestor:(NSResponder*)responder
{
	for (NSResponder* resp = self; resp; resp = [resp nextResponder])
		if (resp == responder)
			return YES;
	return NO;
}
@end


// MARK: -
@implementation NSBox ( NSBoxPlusExtensions )

- (void) growToFit
{
	NSRect oldFrame = [self frame];
	[self sizeToFit];
	NSRect newFrame = [self frame];
	NSSize maxSize = UnionSizeWIthSize(newFrame.size, oldFrame.size);
	newFrame = UnionRectWithSize(newFrame, maxSize);
	[self setFrame:newFrame];
}

@end




// MARK: -
@implementation NSTableView ( NSTableViewPlusExtensions )
- (void) selectRow:(NSInteger)row		{ [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO]; }
- (void) myDeselectAll					{ [self selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO]; }		// There is a bug with deselectAll in the 10.6 api / use. I can't track it down exactly but here is a reference:
																														// http://stackoverflow.com/questions/8377205/enabling-empty-selection-on-view-based-nstableviews
																														// http://stackoverflow.com/questions/1296798/cant-make-empty-selection-in-nstableview
																														// http://www.cocoabuilder.com/archive/cocoa/242930-nstableview-empty-selection-not-working.html
- (BOOL) rowWasClicked					{ return [self clickedRow] != -1; }
- (NSInteger) chosenRow					{ NSInteger clickedRow = [self clickedRow];	return (clickedRow >= 0) ? clickedRow : [self selectedRow]; }
- (BOOL) clickedRowInSelectedRows		{ NSInteger clickedRow = [self clickedRow]; return (clickedRow >= 0) &&  [self isRowSelected:clickedRow]; }
- (BOOL) clickedRowOutsideSelectedRows	{ NSInteger clickedRow = [self clickedRow]; return (clickedRow >= 0) && ![self isRowSelected:clickedRow]; }
- (BOOL) selectedRowsWereChosen			{ NSInteger clickedRow = [self clickedRow]; return ((clickedRow == -1) && ([self numberOfSelectedRows] > 0)) || ((clickedRow >= 0) && [self isRowSelected:clickedRow]); }

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



// MARK: -
@implementation NSOutlineView ( NSOutlineViewPlusExtensions )
- (id) safeItemAtRow:(NSInteger)row
{
	@try
	{
		return [self itemAtRow:row];
	}
	@catch (NSException* ne)
	{
		return nil;
	}
	return nil;
}
- (id) selectedItem		{ return ([self numberOfSelectedRows] > 0) ? [self safeItemAtRow:[self selectedRow]] : nil; }
- (id) clickedItem		{ NSInteger clickedRow = [self clickedRow];  return (clickedRow >= 0) ? [self safeItemAtRow:clickedRow] : nil; }
- (id) chosenItem		{ NSInteger clickedRow = [self clickedRow];  return (clickedRow >= 0) ? [self safeItemAtRow:clickedRow] : [self selectedItem]; }

- (NSArray*) selectedItems
{
	NSMutableArray* nodes = [[NSMutableArray alloc]init];
	
	// We need to only call itemAtRow on the main thread. Bad things seem to happen if we don't...
	__block NSIndexSet* rows;
	dispatchSpliced(mainQueue(), ^{
		rows = [self selectedRowIndexes];
		[rows enumerateIndexesUsingBlock:^(NSUInteger row, BOOL* stop) {
			[nodes addObjectIfNonNil:[self itemAtRow:row]];
		}];
	});
	return nodes;	
}

- (NSArray*) chosenItems
{
	if (![self rowWasClicked] && [self numberOfSelectedRows] == 0)
		return @[];
	return [self isRowSelected:[self chosenRow]] ? [self selectedItems] : @[ [self chosenItem] ];
}

- (void) selectItem:(id)item
{
	NSInteger row = item ? [self rowForItem:item] : -1;
	if (row >= 0)
		[self selectRow:row];
}

- (void) selectItems:(NSArray*)items
{
	NSMutableIndexSet* indexes = [[NSMutableIndexSet alloc]init];
	for (id item in items)
	{
		NSInteger row = item ? [self rowForItem:item] : -1;
		if (row >= 0)
			[indexes addIndex:row];
	}
	[self selectRowIndexes:indexes byExtendingSelection:NO];
}
@end



