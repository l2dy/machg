//
//  CommonHeader.h
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "MonitorFSEvents.h"
#import "BaseSheetWindowController.h"
#import "LNCStopwatch.h"
#import <dispatch/dispatch.h>
#import "RegexKitLite.h"

// Sidebar
@class Sidebar;
@class SidebarNode;
@class SidebarCell;

// Pane Contollers
@class BrowserViewController;
@class HistoryViewController;
@class DifferencesViewController;
@class BackingViewController;

// Pane Views
@class BrowserView;
@class HistoryView;
@class DifferencesView;
//@class BackingView;

// FSBrowser
@class FSBrowser;
@class FSNodeInfo;

// History / Log
@class LogEntry;
@class LogRecord;
@class RepositoryData;
@class LogGraph;
@class LogTableView;

// Labels
@class LabelData;
@class LabelsTableView;

// Patches
@class PatchData;
@class PatchesTableView;

// Processes
@class ProcessListController;
@class TaskExecutions;
@class ExecutionResult;

// Document
@class MacHgDocument;
@class RepositoryPaths;
@class AppController;

// Sheets
@class AddLabelSheetController;
@class BackoutSheetController;
@class CloneSheetController;
@class CollapseSheetController;
@class CommitSheetController;
@class ConnectionValidationController;
@class ExportPatchesSheetController;
@class HistoryEditSheetController;
@class ImportPatchesSheetController;
@class IncomingSheetController;
@class LocalRepositoryRefSheetController;
@class MergeSheetController;
@class MoveLabelSheetController;
@class OutgoingSheetController;
@class ProcessListController;
@class PullSheetController;
@class PushSheetController;
@class RebaseSheetController;
@class RenameFileSheetController;
@class ResultsWindowController;
@class RevertSheetController;
@class ServerRepositoryRefSheetController;
@class StripSheetController;
@class UpdateSheetController;

@class PreferenceController;
@class InitializationWizardController;
@class BaseSheetWindowController;

// Utilities
@class LNCStopwatch;
@class AttachedWindowController;
@class DisclosureBoxController;
@class RadialGradiantBox;
@class OptionController;
@class SingleTimedQueue;
@class ThickSplitView;
@class JHAccordionView;

@class BWSplitView;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Supporting enums
// -----------------------------------------------------------------------------------------------------------------------------------------

typedef enum
{
	eBrowserClickActionOpen				= 0,
	eBrowserClickActionRevealInFinder	= 1,
	eBrowserClickActionDiff				= 2,
	eBrowserClickActionAnnotate			= 3,
	eBrowserClickActionOpenTerminalHere = 4,
	eBrowserClickActionNoAction         = 5
} BrowserDoubleClickAction;

typedef enum
{
	eDiffFileAdded	 = 0,
	eDiffFileChanged = 1,
	eDiffFileRemoved = 2
} DiffButtonType;

typedef enum
{
	eOpenLastDocument	= 0,
	eOpenNewDocument	= 1,
	eDontOpenAnything	= 2
} OnStartupOpenWhatOption;

typedef enum
{
	eAfterMergeSwitchToBrowser	= 0,
	eAfterMergeSwitchToHistory	= 1
} AfterMergeSwitchToOption;

typedef enum
{
	eAfterMergeDoNothing	= 0,
	eAfterMergeOpenCommit	= 1
} AfterMergeDoOption;

typedef enum
{
	eSortRevisionsAscending	 = 0,
	eSortRevisionsDescending = 1
} RevisionSortOrderOption;

typedef enum
{
	eUseFileMergeForDiffs = 0,
	eUseOtherForDiffs	  = 1,
	eUseNothingForDiffs	  = 2
} ToolForDiffing;

typedef enum
{
	eMoveOrigFilesToTrash = 0,
	eLeaveOrigFilesAlone  = 1
} HandleOrigFilesOption;


// Represents the properties of a node as viewed by Mercurial
typedef enum
{
	eHGStatusNoStatus   = 0,
	eHGStatusIgnored    = 1<<1,
	eHGStatusClean      = 1<<2,
	eHGStatusUntracked  = 1<<3,
	eHGStatusAdded      = 1<<4,
	eHGStatusRemoved    = 1<<5,
	eHGStatusMissing    = 1<<6,
	eHGStatusModified   = 1<<7,
	eHGStatusResolved   = 1<<8,
	eHGStatusUnresolved = 1<<9,
	eHGStatusDirty      = 1<<10,	// When dirty the paths are in the act of being processed anew and are about to get new status'.
	
	
	eHGStatusInRepository		= eHGStatusIgnored | eHGStatusClean | eHGStatusAdded | eHGStatusRemoved | eHGStatusMissing | eHGStatusModified,
	eHGStatusNotIgnored         = eHGStatusClean | eHGStatusUntracked | eHGStatusAdded | eHGStatusRemoved | eHGStatusMissing | eHGStatusModified,
	eHGStatusChangedInSomeWay	= eHGStatusAdded | eHGStatusRemoved | eHGStatusMissing | eHGStatusModified,
	eHGStatusCommittable		= eHGStatusAdded | eHGStatusRemoved | eHGStatusModified,
	eHGStatusAddable			= eHGStatusUntracked,
	eHGStatusAddableOrRemovable	= eHGStatusUntracked | eHGStatusMissing,
	eHGStatusPrimary            = eHGStatusIgnored | eHGStatusClean | eHGStatusUntracked | eHGStatusAdded | eHGStatusRemoved | eHGStatusMissing | eHGStatusModified,
	eHGStatusSecondary          = eHGStatusResolved | eHGStatusUnresolved
} HGStatus;


typedef enum
{
	eNoLabelType	 = 0,
	eLocalTag		 = 1<<1,
	eGlobalTag		 = 1<<2,
	eBookmark		 = 1<<3,
	eActiveBranch	 = 1<<4,
	eInactiveBranch  = 1<<5,
	eClosedBranch	 = 1<<6,
	eOpenHead		 = 1<<7,
	eTagLabel		 = eGlobalTag | eLocalTag,
	eOpenBranchLabel = eActiveBranch | eInactiveBranch,
	eBranchLabel	 = eActiveBranch | eInactiveBranch | eClosedBranch,
	eBookmarkLabel   = eBookmark,
	eLocalLabel		 = eLocalTag | eBookmark,
	eStationaryLabel = eLocalTag | eGlobalTag,
	eNotOpenHead     = eTagLabel | eBranchLabel | eBookmarkLabel
} LabelType;


// Represents the type of a node in the sidebar
typedef enum
{
	kSidebarNodeKindSection				= 0x01,
	kSidebarNodeKindFolder				= 0x02,
	kSidebarNodeKindLocalRepositoryRef	= 0x03,
	kSidebarNodeKindServerRepositoryRef	= 0x04
} SidebarNodeKind;


// Represents the stage of loading of a LogEntry. (We lazily load log entries for speed.)
typedef enum
{
	eLogEntryLoadedNone				= 0,	// Nothing is loaded
	eLogEntryLoading				= 1,	// We have started on a thread loading this log entry
	eLogEntryLoaded					= 4		// We have loaded all the information about a log entry
} LogEntryLoadStatus;


// Represents the stage of loading of a LogRecord. (We lazily load log records for speed.)
typedef enum
{
	eLogRecordLoadingPending = 0,		// We have started on a thread loading this log record for this changeset
	eLogRecordDetailsLoading = 1<<1,	// We are loading all the normal details: eg user, date, comments
	eLogRecordDetailsLoaded  = 1<<2,	// We have loaded all the normal details: eg user, date, comments
	eLogRecordFilesLoading   = 1<<3,	// We are loading all the file adds, mods, and removes
	eLogRecordFilesLoaded    = 1<<4,	// We have loaded all the file adds, mods, and removes
	
	eLogRecordDetailsAndFilesLoaded  = eLogRecordDetailsLoaded  | eLogRecordFilesLoaded
} LogRecordLoadStatus;


typedef enum
{
	eBrowserView     = 0x0,
	eHistoryView     = 0x01,
	eDifferencesView = 0x02,
	eBackingView     = 0x03
} PaneViewNum;

typedef enum
{
	eEnabled   = 0x0,
	eDisabled  = 0x01,
	eUnhandled = 0x02,
} Validation;

typedef struct
{
	NSInteger	lowRevision;
	NSInteger	highRevision;
} LowHighPair;

typedef struct
{
	NSString*	lowRevision;
	NSString*	highRevision;
} LowHighStringPair;


extern NSString* const kSidebarPBoardType;
extern NSString* const kSidebarRootInitializationDummy;

extern NSString* const kPatchesTablePBoardType;
extern NSString* const kMacHgApp;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Notifications
// -----------------------------------------------------------------------------------------------------------------------------------------

// It is sometimes quite important to use notifications. Eg if MacHg just calls underlying refresh methods directly after sending
// out a mercurial command, often mercurial isn't finished doing its thing before the refresh happens and so the refresh is
// incomplete. It's better to detect that Mercurial is finished and then refresh, where possible.

extern NSString* const kRepositoryRootChanged;				// The sidebar bookmark now points to a different repository

extern NSString* const kSidebarSelectionDidChange;			// The selection in the sidebar bookmark changed
extern NSString* const kUnderlyingRepositoryChanged;		// The underlying mercurial repository changed. (A commit or update
															// happened, etc.) Upon recite of this notifcaiton the RepositoryData
															// marks its stored data as stale. Subsequently the repository data is
															// reloaded when it is accessed.

extern NSString* const kRepositoryDataIsNew;				// The collection of log entries for the current repository was
															// changed to a new collection. Clients need to observe this and
															// refresh accordingly.
extern NSString* const kRepositoryDataDidChange;			// The underlying, tip, parents, tags, and branches, of the repository
															// just got changed / refreshed. Clients need to observe this and
															// refresh accordingly.
extern NSString* const kLogEntriesDidChange;				// Some LogEntires which are part of the RepositoryData got
															// fleshed out.

// Non-critical notifications
extern NSString* const kBrowserDisplayPreferencesChanged;	// The user selected some preference or something so tables etc should
															// update their visual appearance.
extern NSString* const kCompatibleRepositoryChanged;		// A repository compatible to the current repository changed. (A push
															// happened, etc.)
extern NSString* const kReceivedCompatibleRepositoryCount;	// We just received the change count difference between the current
															// repository and a compatible repository.
extern NSString* const kCommandKeyIsDown;					// A command key has just been pressed. Adjust button titles.
extern NSString* const kCommandKeyIsUp;						// A command key has just been released. Adjust button titles.


// Currently no listeners
extern NSString* const kRepositoryIdentityChanged;			// The sidebar root changeset has been determined to be something different
															// to what it previously was


extern NSString* const kProcessAddedToProcessList;			// A process has been added to the process list
extern NSString* const kProcessRemovedFromProcessList;		// A process has been removed from the process list





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Dictionary constants
// -----------------------------------------------------------------------------------------------------------------------------------------

extern NSString* const kRepositoryDataChangeType;

extern NSString* const kRepositoryBranchNameChanged;		// The name of the branch for the current parent changed in the
															// current repository did change. Clients need to observe this and
															// refresh accordingly.
extern NSString* const kRepositoryLabelsInfoChanged;		// The labels of the current repository did change. Clients need to
															// observe this and refresh accordingly.
extern NSString* const kRepositoryParentsOfCurrentRevChanged; // The parents of the current repository did change. Clients need to
															  // observe this and refresh accordingly.
extern NSString* const kRepositoryTipChanged;				// The tip of the current repository did change. Clients need to
															// observe this and refresh accordingly.




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Forward declarations
// -----------------------------------------------------------------------------------------------------------------------------------------

// Defaults
extern NSString* const MHGAddRemoveSimilarityFactor;
extern NSString* const MHGAddRemoveUsesSimilarity;
extern NSString* const MHGAfterMergeDo;
extern NSString* const MHGAfterMergeSwitchTo;
extern NSString* const MHGAllowHistoryEditingOfRepository;
extern NSString* const MHGBrowserBehaviourCommandDoubleClick;
extern NSString* const MHGBrowserBehaviourCommandOptionDoubleClick;
extern NSString* const MHGBrowserBehaviourDoubleClick;
extern NSString* const MHGBrowserBehaviourOptionDoubleClick;
extern NSString* const MHGDefaultAnnotationOptionChangeset;
extern NSString* const MHGDefaultAnnotationOptionDate;
extern NSString* const MHGDefaultAnnotationOptionFollow;
extern NSString* const MHGDefaultAnnotationOptionLineNumber;
extern NSString* const MHGDefaultAnnotationOptionNumber;
extern NSString* const MHGDefaultAnnotationOptionText;
extern NSString* const MHGDefaultAnnotationOptionUser;
extern NSString* const MHGDefaultHGIgnoreContents;
extern NSString* const MHGDefaultWorkspacePath;
extern NSString* const MHGDisplayFileIconsInBrowser;
extern NSString* const MHGDisplayResultsOfAddRemoveRenameFiles;
extern NSString* const MHGDisplayResultsOfMerging;
extern NSString* const MHGDisplayResultsOfPulling;
extern NSString* const MHGDisplayResultsOfPushing;
extern NSString* const MHGDisplayResultsOfUpdating;
extern NSString* const MHGDisplayWarningForAddRemoveRenameFiles;
extern NSString* const MHGDisplayWarningForAmend;
extern NSString* const MHGDisplayWarningForBackout;
extern NSString* const MHGDisplayWarningForBranchNameRemoval;
extern NSString* const MHGDisplayWarningForFileDeletion;
extern NSString* const MHGDisplayWarningForMarkingFilesResolved;
extern NSString* const MHGDisplayWarningForMerging;
extern NSString* const MHGDisplayWarningForPostMerge;
extern NSString* const MHGDisplayWarningForPulling;
extern NSString* const MHGDisplayWarningForPushing;
extern NSString* const MHGDisplayWarningForRenamingFiles;
extern NSString* const MHGDisplayWarningForRepositoryDeletion;
extern NSString* const MHGDisplayWarningForRevertingFiles;
extern NSString* const MHGDisplayWarningForRollbackFiles;
extern NSString* const MHGDisplayWarningForTagRemoval;
extern NSString* const MHGDisplayWarningForUntrackingFiles;
extern NSString* const MHGDisplayWarningForUpdating;
extern NSString* const MHGFontSizeOfBrowserItems;
extern NSString* const MHGHandleCommandDefaults;
extern NSString* const MHGHandleGeneratedOrigFiles;
extern NSString* const MHGIncludeHomeHgrcInHGRCPATH;
extern NSString* const MHGLaunchCount;
extern NSString* const MHGLocalHGShellAliasName;
extern NSString* const MHGLocalWhitelistedHGShellAliasName;
extern NSString* const MHGLogEntryTableBookmarkHighlightColor;
extern NSString* const MHGLogEntryTableBranchHighlightColor;
extern NSString* const MHGLogEntryTableDisplayChangesetColumn;
extern NSString* const MHGLogEntryTableParentHighlightColor;
extern NSString* const MHGLogEntryTableTagHighlightColor;
extern NSString* const MHGLoggingLevelForHGCommands;
extern NSString* const MHGMacHgLogFileLocation;
extern NSString* const MHGOnStartupOpen;
extern NSString* const MHGRevisionSortOrder;
extern NSString* const MHGShowAddedFilesInBrowser;
extern NSString* const MHGShowCleanFilesInBrowser;
extern NSString* const MHGShowFilePreviewInBrowser;
extern NSString* const MHGShowIgnoredFilesInBrowser;
extern NSString* const MHGShowMissingFilesInBrowser;
extern NSString* const MHGShowModifiedFilesInBrowser;
extern NSString* const MHGShowRemovedFilesInBrowser;
extern NSString* const MHGShowResolvedFilesInBrowser;
extern NSString* const MHGShowUntrackedFilesInBrowser;
extern NSString* const MHGShowUnresolvedFilesInBrowser;
extern NSString* const MHGSizeOfBrowserColumns;
extern NSString* const MHGToolNameForDiffing;
extern NSString* const MHGUseFileMergeForMerge;
extern NSString* const MHGUseWhichToolForDiffing;
extern NSString* const MHGViewsHaveIndependentSizes;
extern NSString* const MHGWarnAboutBadMercurialConfiguration;



BOOL		AddRemoveUsesSimilarityFromDefaults();
BOOL		AllowHistoryEditingOfRepositoryFromDefaults();
BOOL		DefaultAnnotationOptionChangesetFromDefaults();
BOOL		DefaultAnnotationOptionDateFromDefaults();
BOOL		DefaultAnnotationOptionFollowFromDefaults();
BOOL		DefaultAnnotationOptionLineNumberFromDefaults();
BOOL		DefaultAnnotationOptionNumberFromDefaults();
BOOL		DefaultAnnotationOptionTextFromDefaults();
BOOL		DefaultAnnotationOptionUserFromDefaults();
BOOL		DisplayFileIconsInBrowserFromDefaults();
BOOL		DisplayResultsOfAddRemoveRenameFilesFromDefaults();
BOOL		DisplayResultsOfMergingFromDefaults();
BOOL		DisplayResultsOfPullingFromDefaults();
BOOL		DisplayResultsOfPushingFromDefaults();
BOOL		DisplayResultsOfUpdatingFromDefaults();
BOOL		DisplayWarningForAddRemoveRenameFilesFromDefaults();
BOOL		DisplayWarningForAmendFromDefaults();
BOOL		DisplayWarningForBackoutFromDefaults();
BOOL		DisplayWarningForBranchNameRemovalFromDefaults();
BOOL		DisplayWarningForFileDeletionFromDefaults();
BOOL		DisplayWarningForMarkingFilesResolvedFromDefaults();
BOOL		DisplayWarningForMergingFromDefaults();
BOOL		DisplayWarningForPostMergeFromDefaults();
BOOL		DisplayWarningForPullingFromDefaults();
BOOL		DisplayWarningForPushingFromDefaults();
BOOL		DisplayWarningForRenamingFilesFromDefaults();
BOOL		DisplayWarningForRepositoryDeletionFromDefaults();
BOOL		DisplayWarningForRevertingFilesFromDefaults();
BOOL		DisplayWarningForRollbackFilesFromDefaults();
BOOL		DisplayWarningForTagRemovalFromDefaults();
BOOL		DisplayWarningForUntrackingFilesFromDefaults();
BOOL		DisplayWarningForUpdatingFromDefaults();
BOOL		IncludeHomeHgrcInHGRCPATHFromDefaults();
BOOL		ShowAddedFilesInBrowserFromDefaults();
BOOL		ShowCleanFilesInBrowserFromDefaults();
BOOL		ShowFilePreviewInBrowserFromDefaults();
BOOL		ShowIgnoredFilesInBrowserFromDefaults();
BOOL		ShowMissingFilesInBrowserFromDefaults();
BOOL		ShowModifiedFilesInBrowserFromDefaults();
BOOL		ShowRemovedFilesInBrowserFromDefaults();
BOOL		ShowResolvedFilesInBrowserFromDefaults();
BOOL		ShowUntrackedFilesInBrowserFromDefaults();
BOOL		ShowUnresolvedFilesInBrowserFromDefaults();
BOOL		UseFileMergeForDiffFromDefaults();
BOOL		UseFileMergeForMergeFromDefaults();
BOOL		ViewsHaveIndependentSizesFromDefaults();
BOOL		WarnAboutBadMercurialConfigurationFromDefaults();




float		fontSizeOfBrowserItemsFromDefaults();
float		sizeOfBrowserColumnsFromDefaults();
int			LoggingLevelForHGCommands();
int			LaunchCountFromDefaults();
NSString*	AddRemoveSimilarityFactorFromDefaults();
NSString*	DefaultHGIgnoreContentsFromDefaults();
NSString*	DefaultWorkspacePathFromDefaults();
NSString*	LocalHGShellAliasNameFromDefaults();
NSString*	LocalWhitelistedHGShellAliasNameFromDefaults();
NSString*	MacHgLogFileLocation();
NSString*	ToolNameForDiffingFromDefaults();
NSColor*	LogEntryTableTagHighlightColor();
NSColor*	LogEntryTableParentHighlightColor();
NSColor*	LogEntryTableBranchHighlightColor();
NSColor*	LogEntryTableBookmarkHighlightColor();


AfterMergeDoOption				AfterMergeDoFromDefaults();
AfterMergeSwitchToOption		AfterMergeSwitchToFromDefaults();
RevisionSortOrderOption			RevisionSortOrderFromDefaults();
HandleOrigFilesOption			HandleGeneratedOrigFilesFromDefaults();
OnStartupOpenWhatOption			OnStartupOpenFromDefaults();
ToolForDiffing					UseWhichToolForDiffingFromDefaults();

BrowserDoubleClickAction		browserBehaviourDoubleClick();
BrowserDoubleClickAction		browserBehaviourCommandDoubleClick();
BrowserDoubleClickAction		browserBehaviourOptionDoubleClick();
BrowserDoubleClickAction		browserBehaviourCommandOptionDoubleClick();





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Globals
// -----------------------------------------------------------------------------------------------------------------------------------------

extern NSMutableDictionary* changesetHashToLogRecord;	// Global dictonary of LogRecords

extern NSNumber*		NOasNumber;
extern NSNumber*		YESasNumber;
extern NSNumber*		SlotNumber;


// Font Attributes
extern NSDictionary*	boldSystemFontAttributes;
extern NSDictionary*	italicSidebarFontAttributes;
extern NSDictionary*	italicSystemFontAttributes;
extern NSDictionary*	italicVirginSidebarFontAttributes;
extern NSDictionary*	smallBoldCenteredSystemFontAttributes;
extern NSDictionary*	smallBoldSystemFontAttributes;
extern NSDictionary*	smallCenteredSystemFontAttributes;
extern NSDictionary*	smallItalicSystemFontAttributes;
extern NSDictionary*	smallSystemFontAttributes;
extern NSDictionary*	smallGraySystemFontAttributes;
extern NSDictionary*	standardSidebarFontAttributes;
extern NSDictionary*	standardVirginSidebarFontAttributes;
extern NSDictionary*	systemFontAttributes;
extern NSDictionary*	graySystemFontAttributes;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Processes
// -----------------------------------------------------------------------------------------------------------------------------------------

typedef void (^BlockProcess)(void);
typedef dispatch_group_t DispatchGroup;

static inline dispatch_queue_t	globalQueue()										{ return dispatch_get_global_queue(0,0); }
static inline dispatch_queue_t	mainQueue()											{ return dispatch_get_main_queue(); }
static inline void dispatchGroupWait(dispatch_group_t group)						{ dispatch_group_wait(group, DISPATCH_TIME_FOREVER); }
static inline void dispatchGroupWaitTime(dispatch_group_t group, dispatch_time_t t)	{ dispatch_group_wait(group, t); }
static inline void dispatchGroupWaitAndFinish(dispatch_group_t group)				{ dispatch_group_wait(group, DISPATCH_TIME_FOREVER); dispatch_release(group); }
static inline void dispatchGroupFinish(dispatch_group_t group)						{ dispatch_release(group); }
void dispatchWithTimeOut(dispatch_queue_t q, NSTimeInterval t, BlockProcess theBlock);
void dispatchWithTimeOutBlock(dispatch_queue_t q, NSTimeInterval t, BlockProcess mainBlock, BlockProcess timeoutBlock);

static inline void dispatchSpliced(dispatch_queue_t q, BlockProcess theBlock)
{
	if (dispatch_get_current_queue() != q)
		dispatch_sync(q, theBlock);
	else
		theBlock();
}

static inline void NoAnimationBlock(BlockProcess theBlock)
{
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.0];
	theBlock();
	[NSAnimationContext endGrouping];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Dialogs
// -----------------------------------------------------------------------------------------------------------------------------------------

NSAlert*	NewAlertPanel(NSString* title, NSString* message, NSString* defaultButton, NSString* alternateButton, NSString* otherButton);
NSInteger	RunAlertExtractingSuppressionResult(NSAlert* alert, NSString* keyForBooleanDefault);
NSInteger	RunCriticalAlertPanelWithSuppression(		NSString* title, NSString* message, NSString* defaultButton, NSString* alternateButton, NSString* keyForBooleanDefault);
NSInteger	RunCriticalAlertPanelOptionsWithSuppression(NSString* title, NSString* message, NSString* defaultButton, NSString* alternateButton, NSString* otherButton, NSString* keyForBooleanDefault);





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

BOOL		pathContainedIn(NSString* base, NSString* path);		// is the given path contained in base
NSString*	pathDifference(NSString* base, NSString* path);			// This gives the difference of the paths. eg the difference from the
																	// base /foo/bar to the subfile /foo/bar/fish/rover is fish/rover.
NSArray*	parentPaths(NSArray* filteredPaths, NSString* rootPath);// Return the array of parents of the given paths. The paths can't
																	// "escape" outside of the rootPath.

void		moveFilesToTheTrash(NSArray* absolutePaths);
NSString*	caseSensitiveFilePath(NSString* filePath);
BOOL		pathIsLink(NSString* path);
BOOL		pathIsExistent(NSString* path);
BOOL		pathIsExistentDirectory(NSString* path);
BOOL		pathIsExistentFile(NSString* path);
BOOL		pathIsReadable(NSString* path);
BOOL		pathIsVisible(NSString* path);
BOOL		repositoryExistsAtPath(NSString* path);			// Does a repository exist at the given local file path.
NSArray*	pruneDisallowedPaths(NSArray* paths);
NSArray*	pruneContainedPaths(NSArray* paths);





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  URL operations
// -----------------------------------------------------------------------------------------------------------------------------------------

NSString*	FullServerURLWithPassword(NSString* baseURL, BOOL usesPassword, NSString* password);	// Specify password (used during server configuration)
NSString*	FullServerURL(NSString* baseURL, BOOL usesPassword);						// Use password from the keychain





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Bit Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

extern int			bitCount(int num1);
static inline BOOL	bitsInCommon(int num1, int num2)	{ return (num1 & num2) != 0; }
static inline int	unionBits(int num1, int num2)		{ return num1 | num2; }
static inline int	andBits(int num1, int num2)			{ return num1 & num2; }
static inline int	unsetBits(int num1, int num2)		{ return num1 & ~num2; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: String Manipulation
// -----------------------------------------------------------------------------------------------------------------------------------------

NSString*	trimString(NSString* string);
NSString*	trimTrailingString(NSString* string);
NSString*	collapseWhiteSpace(NSString* string);
BOOL		stringIsNonWhiteSpace(NSString* string);
NSString*	riffleComponents(NSArray* components, NSString* separator);
NSString*	nonNil(NSString* string);




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Locations
// -----------------------------------------------------------------------------------------------------------------------------------------

NSString*	executableLocationHG();								// The resolved executable location
NSString*	applicationSupportFolder();							// the resolved app support dir eg				~/Library/Application Support/MacHg
NSString*	applicationSupportVersionedFolder();				// the resolved versioned app support dir eg	~/Library/Application Support/MacHg/0.9.5
NSString*	hgrcPath();											// the search path MacHg will pass to Mercurial to look for hgrc files (Mercurial configuration files.)
NSArray*	aliasesForShell();									// the aliases for the local hg commands




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Type Conversion
// -----------------------------------------------------------------------------------------------------------------------------------------

static inline NSString*	intAsString(int i)				{ return [NSString stringWithFormat:@"%d", i]; }
static inline int		stringAsInt(NSString* str)		{ return [str intValue]; }

static inline NSNumber*	intAsNumber(int i)				{ return [NSNumber numberWithInt:i]; }
static inline int		numberAsInt(NSNumber* num)		{ return [num intValue]; }

static inline NSString*	numberAsString(NSNumber* num)	{ return [num stringValue]; }
static inline NSNumber*	stringAsNumber(NSString* str)	{ return [NSNumber numberWithInt:[str intValue]]; }

static inline NSString* dupString(NSString* str)		{ return str ? [NSString stringWithString:str] : nil; }

#define DynamicCast(type,obj)  (([(obj) isKindOfClass:[type class]]) ? ((type*)(obj)) : nil)	// Return the casted object if it is of the right type which we
																								// determine at run time

#define ExactDynamicCast(type,obj) (([(obj) class] == [type class]) ? ((type*)(obj)) : nil)		// Return the casted object if it is of the exact type which we
																								// determine at run time

static inline NSInteger constrainInteger(NSInteger val, NSInteger min, NSInteger max)	{ if (val < min) return min; if (val > max) return max; return val; }

static inline BOOL theSameNumbers(NSNumber* a, NSNumber* b)	{ return (!a && !b) || (a && b && [a isEqualToNumber:b]); }
static inline BOOL theSameStrings(NSString* a, NSString* b)	{ return (!a && !b) || (a && b && [a isEqualToString:b]); }

static inline NSNumber* minimumNumber(NSNumber* a, NSNumber* b)
{
	if (a && b) return ([a compare:b] == NSOrderedAscending) ? a : b;
	if (!a) return b;
	if (!b) return a;
	return nil;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Common Functions
// -----------------------------------------------------------------------------------------------------------------------------------------

NSString*			getSingleDirectoryPathFromOpenPanel();
NSString*			getSingleFilePathFromOpenPanel();
NSArray*			getListOfFilePathsFromOpenPanel(NSString* startingPath);

static inline BOOL IsEmpty(id thing)
{
    return
		thing == nil ||
		([thing respondsToSelector:@selector(length)] && [(NSData*)thing length] == 0) ||
		([thing respondsToSelector:@selector(count)]  && [(NSArray*)thing count] == 0);
}


static inline BOOL IsNotEmpty(id thing) { return !IsEmpty(thing); }

NS_INLINE NSRange		MakeRangeFirstLast(NSUInteger first, NSUInteger last)	{ NSUInteger min = MIN(first, last); NSUInteger max = MAX(first, last); return (NSRange){.location = min, .length = max + 1 - min}; }
NS_INLINE LowHighPair	MakeLowHighPair(NSInteger low, NSInteger high)			{ return (LowHighPair){.lowRevision = low, .highRevision = high}; }

#define MakeNSValue(type,obj) ([NSValue value:&obj  withObjCType:@encode(type)])

extern void PlayBeep();

static inline NSRect UnionWidthHeight(NSRect r, CGFloat w, CGFloat h) { r.size.width = MAX(r.size.width, w); r.size.height = MAX(r.size.height, h); return r;}
static inline NSRect UnionSize(NSRect r, NSSize s) { r.size.width = MAX(r.size.width, s.width); r.size.height = MAX(r.size.height, s.height); return r;}

static inline NSString* fstr(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString* string = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return string;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Sorting
// -----------------------------------------------------------------------------------------------------------------------------------------

typedef NSInteger (*ComparitorFunction)(id, id, void*);

NSInteger sortIntsAscending(id num1, id num2, void* context);
NSInteger sortIntsDescending(id num1, id num2, void* context);





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Attributed Strings
// -----------------------------------------------------------------------------------------------------------------------------------------

NSAttributedString*	emphasizedSheetMessageAttributedString(NSString* string);
NSAttributedString*	normalSheetMessageAttributedString(NSString* string);
NSAttributedString* grayedSheetMessageAttributedString(NSString* string);
NSAttributedString*	fixedWidthResultsMessageAttributedString(NSString* string);





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Debugging
// -----------------------------------------------------------------------------------------------------------------------------------------

void printRect(NSString* message, NSRect rect);
void printPoint(NSString* message, NSPoint point);
void printChildViewHierarchy(NSView* view);
void printParentViewHierarchy(NSView* aView);
void printResponderViewHierarchy(NSWindow* aWindow);
void printAttributesForString(NSAttributedString* string);

#ifdef DEBUG
#  define DebugLog(args...) DebugLog_(__FILE__,__LINE__,__PRETTY_FUNCTION__,args)
#else
#  define DebugLog(x...) do {} while(0)
#endif
void DebugLog_(const char* file, int lineNumber, const char* funcName, NSString* format,...);





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Extensions
// -----------------------------------------------------------------------------------------------------------------------------------------

@protocol AccessesDocument
- (MacHgDocument*)	myDocument;
@end


// MARK: -
@interface NSObject (NSObjectPlusObservations)
- (void)	postNotificationWithName:(NSString*)notificationName;
- (void)	postNotificationWithName:(NSString*)notificationName userInfo:(NSDictionary*)info;
- (void)	observe:(NSString*)notificationName byCalling:(SEL)notificationSelector;
- (void)	observe:(NSString*)notificationName from:(id)notificationSender byCalling:(SEL)notificationSelector;
- (void)	stopObserving:(NSString*)notificationName from:(id)notificationSender;
- (void)	stopObserving;
@end


// MARK: -
@interface NSObject (NSObjectPlusUndoManager)
- (id)		prepareUndoWithTarget:(id)target;
@end


// MARK: -
@interface NSString ( NSStringPlusComparisons )
- (BOOL)	isNotEqualToString:(NSString*)aString;
- (BOOL)	differsOnlyInCaseFrom:(NSString*)aString;
- (BOOL)	endsWithNewLine;
@end


// MARK: -
@interface NSString ( NSStringPlusMatches )
// Get the first capture group. Or first and second capture group. Like the RegExKit getCapturesWithRegexAndReferences, but it's
// simpler since it's just the captures in order.
- (BOOL)	getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first;
- (BOOL)	getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second;
- (BOOL)	getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third;
- (BOOL)	getCapturesWithRegexAndComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third  fourthComponent:(NSString**)fourth;

- (BOOL)	getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first;
- (BOOL)	getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second;
- (BOOL)	getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third;
- (BOOL)	getCapturesWithRegexAndTrimedComponents:(NSString*)regEx  firstComponent:(NSString**)first  secondComponent:(NSString**)second  thirdComponent:(NSString**)third  fourthComponent:(NSString**)fourth;

- (BOOL)	isMatchedByRegex:(NSString*)regEx options:(RKLRegexOptions)options;
- (BOOL)	containsString:(NSString*)str;
@end


// MARK: -
@interface NSAttributedString ( NSAttributedStringPlusExtensions)
+ (NSAttributedString*) string:(NSString*)string withAttributes:(NSDictionary*)theAttributes;
+ (NSAttributedString*) string:(NSString*)s1 withAttributes:(NSDictionary*)a1 andString:(NSString*)s2 withAttributes:(NSDictionary*)a2;
+ (NSAttributedString*) hyperlinkFromString:(NSString*)inString withURL:(NSURL*)aURL;
- (NSDictionary*)		attributesOfWholeString;
@end
// MARK: -
@interface NSMutableAttributedString ( NSMutableAttributedStringPlusInitilizers)
+ (NSMutableAttributedString*) string:(NSString*)string withAttributes:(NSDictionary*)theAttributes;
- (void) appendString:(NSString*)string withAttributes:(NSDictionary*)theAttributes;
@end


// MARK: -
@interface NSDate ( NSDatePlusUtilities )
- (BOOL)	  isBefore:(NSDate*)aDate;
- (NSString*) isodateDescription;
+ (NSDate*)   dateWithUTCdatePlusOffset:(NSString*)utcDatePlusOffset;
@end


// MARK: -
@interface NSIndexSet ( NSIndexSetPlusAccessors )
- (BOOL)	intersectsIndexes:(NSIndexSet*)indexSet;
- (BOOL)	freeOfIndex:(NSInteger)index;
@end


// MARK: -
@interface NSMutableArray ( NSMutableArrayPlusAccessors )
- (void)	addObject:(id)object1 followedBy:(id)object2;
- (void)	addObject:(id)object1 followedBy:(id)object2 followedBy:(id)object3;
- (void)	addObjectIfNonNil:(id)object1;
- (id)		popLast;
- (id)		popFirst;
- (void)	removeFirstObject;
- (void)	reverse;
@end


// MARK: -
@interface NSArray ( NSArrayPlusAccessors )
- (id)		firstObject;
- (NSArray*) reversedArray;
@end


// MARK: -
@interface NSDictionary ( NSDictionaryPlusAccessors )
- (id)		  synchronizedObjectForKey:(id)aKey;
- (NSArray*)  synchronizedAllKeys;
- (NSInteger) synchronizedCount;
- (id)		  synchronizedObjectForIntKey:(NSInteger)key;
- (id)		  objectForIntKey:(NSInteger)key;
@end


// MARK: -
@interface NSMutableDictionary ( NSMutableDictionaryPlusAccessors )
- (void)	synchronizedSetObject:(id)anObject forKey:(id)aKey;
- (void)	synchronizedRemoveObjectForKey:(id)aKey;
- (void)	copyValueOfKey:(id)aKey from:(NSDictionary*)aDict;
- (void)	synchronizedSetObject:(id)value forIntKey:(NSInteger)key;
- (void)	setObject:(id)value forIntKey:(NSInteger)key;
@end


// MARK: -
@interface NSWorkspace ( NSWorkspacePlusExtensions )
+ (NSImage*) iconImageOfSize:(NSSize)size forPath:(NSString*)path;
@end


// MARK: -
@interface NSFileManager ( NSFileManagerPlusAppending )
- (void)	appendString:(NSString*)string toFilePath:(NSString*)path;
@end


// MARK: -
@interface NSFileHandle (CSFileHandleExtensions)
- (NSData*)	readDataToEndOfFileIgnoringErros;
@end


// MARK: -
@interface NSAlert ( NSAlertPlusExtensions )
- (void)	addSuppressionCheckBox;
@end


// MARK: -
@interface NSColor ( NSColorPlusExtensions )
- (NSColor*) intensifySaturationAndBrightness:(double)factor;
@end


// MARK: -
@interface NSView ( NSViewPlusExtensions )
- (void)	setCenterX:(CGFloat)coord;
- (void)	setMinX:(CGFloat)coord;
- (void)	setMaxX:(CGFloat)coord;
@end


// MARK: -
@interface NSTableView ( NSTableViewPlusExtensions )
- (void)	selectRow:(NSInteger)row;
- (BOOL)	rowWasClicked;
- (NSInteger) chosenRow;	// If n row was clicked on (that triggered an action) in the table then return
							// that, or else return the selected row
- (void) scrollToRangeOfRowsLow:(NSInteger)lowTableRow high:(NSInteger)highTableRow;
@end
