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

// Pane Controllers
@class FilesViewController;
@class HistoryViewController;
@class DifferencesViewController;
@class BackingViewController;

// Pane Views
@class FilesView;
@class HistoryView;
@class DifferencesView;
@class BackingView;

// FSViewer
@class FSViewer;
@class FSViewerBrowser;
@class FSViewerOutline;
@class FSViewerTable;
@class FSNodeInfo;
@class FSViewerSelectionState;

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
@class ProcessController;
@class TaskExecutions;
@class ShellTask;
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
@class AboutWindowController;
@class BaseSheetWindowController;

// Utilities
@class LNCStopwatch;
@class AttachedWindowController;
@class DisclosureBoxController;
@class ConnectionValidationController;
@class RadialGradiantBox;
@class OptionController;
@class SingleTimedQueue;
@class ThickSplitView;
@class JHConcertinaView;

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
	eAllPasswordsAreMangled = 0,
	eKeyChainPasswordsAreMangled = 1,
	eAllPasswordsAreVisible = 3
} PasswordVisibilityType;

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
} OnActivationOpenWhatOption;

typedef enum
{
	eAfterMergeSwitchToFiles	= 0,
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
	eDateAbsolute = 0,
	eDateRelative = 1,
} DateAndTimeFormatOption;

typedef enum
{
	eFilesBrowserDefault    = 0x0,
	eFilesOutlineDefault    = 0x01,
	eFilesTableDefault		= 0x02
} FSViewerNumberDefaultOption;


typedef enum
{
	eUseNothingForDiffs		 = -1,
	eUseFileMergeForDiffs	 = 0,
	eUseAraxisMergeForDiffs  = 1,
	eUseP4MergeForDiffs		 = 2,
	eUseDiffMergeForDiffs	 = 3,
	eUseKDiff3ForDiffs		 = 4,
	eUseDelatWalkerForDiffs	 = 5,
	eUseKaleidoscopeForDiffs = 6,	// First diff only tool
	eUseChangesForDiffs		 = 7,
	eUseDiffForkForDiffs	 = 8,
	eUseBBEditForDiffs		 = 9,
	eUseTextWranglerForDiffs = 10,
	eUseOtherForDiffs		 = 11
} ToolForDiffing;

typedef enum
{
	eUseNothingForMerges		= -1,
	eUseFileMergeForMerges		= 0,
	eUseAraxisMergeForMerges	= 1,
	eUseP4MergeForMerges		= 2,
	eUseDiffMergeForMerges		= 3,
	eUseKDiff3ForMerges			= 4,
	eUseDelatWalkerForMerges	= 5,
	eUseChangesForMerges		= 6,
	eUseOtherForMerges			= 7
} ToolForMerging;


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
	eHGStatusPresent            = eHGStatusClean | eHGStatusAdded | eHGStatusModified,
	eHGStatusPrimary            = eHGStatusIgnored | eHGStatusClean | eHGStatusUntracked | eHGStatusAdded | eHGStatusRemoved | eHGStatusMissing | eHGStatusModified,
	eHGStatusSecondary          = eHGStatusResolved | eHGStatusUnresolved,
	eHGStatusAll				= eHGStatusPrimary | eHGStatusSecondary | eHGStatusDirty
} HGStatus;


typedef enum
{
	eCommitCheckStateOff	 = 0,
	eCommitCheckStatePartial = 1<<1,
	eCommitCheckStateOn      = 1<<2
} CommitCheckBoxState;


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
	kSidebarNodeKindNone				= 0,
	kSidebarNodeKindSection				= 1<<1,
	kSidebarNodeKindFolder				= 1<<2,
	kSidebarNodeKindLocalRepositoryRef	= 1<<3,
	kSidebarNodeKindServerRepositoryRef	= 1<<4,
	kSidebarNodeKindRepository			= kSidebarNodeKindLocalRepositoryRef | kSidebarNodeKindServerRepositoryRef
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


// Represents the type of search we do in the search field
typedef enum
{
	eSearchByKeyword		= 0,	// search by a keyword
	eSearchByRevisionID		= 1,	// search by a revision or changeset id
	eSearchByRevesetQuery	= 2		// search by a revset query
} SearchFieldCategory;

typedef enum
{
	eFilesView       = 0x0,
	eHistoryView     = 0x01,
	eDifferencesView = 0x02,
	eBackingView     = 0x03
} PaneViewNum;

typedef enum
{
	eFilesNoView	 = 0x0,
	eFilesBrowser    = 0x01,
	eFilesOutline    = 0x02,
	eFilesTable		 = 0x03
} FSViewerNum;

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
															// happened, etc.) Upon recite of this notification the RepositoryData
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
extern NSString* const kDifferencesDisplayPreferencesChanged;// The user selected some preference or something so that the file
															// view differences should update their visual appearance. 

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
extern NSString* const MHGDateAndTimeFormat;
extern NSString* const MHGDefaultAnnotationOptionChangeset;
extern NSString* const MHGDefaultAnnotationOptionDate;
extern NSString* const MHGDefaultAnnotationOptionFollow;
extern NSString* const MHGDefaultAnnotationOptionLineNumber;
extern NSString* const MHGDefaultAnnotationOptionNumber;
extern NSString* const MHGDefaultAnnotationOptionText;
extern NSString* const MHGDefaultAnnotationOptionUser;
extern NSString* const MHGDefaultFilesView;
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
extern NSString* const MHGFontSizeOfDifferencesWebview;
extern NSString* const MHGHandleCommandDefaults;
extern NSString* const MHGHandleGeneratedOrigFiles;
extern NSString* const MHGIncludeHomeHgrcInHGRCPATH;
extern NSString* const MHGLaunchCount;
extern NSString* const MHGLocalHGShellAliasName;
extern NSString* const MHGLocalWhitelistedHGShellAliasName;
extern NSString* const MHGLogEntryTableBookmarkHighlightColor;
extern NSString* const MHGLogEntryTableBranchHighlightColor;
extern NSString* const MHGLogEntryTableDisplayBranchColumn;
extern NSString* const MHGLogEntryTableDisplayChangesetColumn;
extern NSString* const MHGLogEntryTableParentHighlightColor;
extern NSString* const MHGLogEntryTableTagHighlightColor;
extern NSString* const MHGLoggingLevelForHGCommands;
extern NSString* const MHGMacHgLogFileLocation;
extern NSString* const MHGNumContextLinesForDifferencesWebview;
extern NSString* const MHGOnActivationOpen;
extern NSString* const MHGRequireVerifiedServerCertificates;
extern NSString* const MHGRevisionSortOrder;
extern NSString* const MHGShowAddedFilesInBrowser;
extern NSString* const MHGShowCleanFilesInBrowser;
extern NSString* const MHGShowFilePreviewInBrowser;
extern NSString* const MHGShowIgnoredFilesInBrowser;
extern NSString* const MHGShowMissingFilesInBrowser;
extern NSString* const MHGShowModifiedFilesInBrowser;
extern NSString* const MHGShowRemovedFilesInBrowser;
extern NSString* const MHGShowResolvedFilesInBrowser;
extern NSString* const MHGShowUnresolvedFilesInBrowser;
extern NSString* const MHGShowUntrackedFilesInBrowser;
extern NSString* const MHGSizeOfBrowserColumns;
extern NSString* const MHGToolNameForDiffing;
extern NSString* const MHGToolNameForMerging;
extern NSString* const MHGUseWhichToolForDiffing;
extern NSString* const MHGUseWhichToolForMerging;
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
BOOL		RequireVerifiedServerCertificatesFromDefaults();
BOOL		ShowAddedFilesInBrowserFromDefaults();
BOOL		ShowCleanFilesInBrowserFromDefaults();
BOOL		ShowFilePreviewInBrowserFromDefaults();
BOOL		ShowIgnoredFilesInBrowserFromDefaults();
BOOL		ShowMissingFilesInBrowserFromDefaults();
BOOL		ShowModifiedFilesInBrowserFromDefaults();
BOOL		ShowRemovedFilesInBrowserFromDefaults();
BOOL		ShowResolvedFilesInBrowserFromDefaults();
BOOL		ShowUnresolvedFilesInBrowserFromDefaults();
BOOL		ShowUntrackedFilesInBrowserFromDefaults();
BOOL		WarnAboutBadMercurialConfigurationFromDefaults();




float		fontSizeOfBrowserItemsFromDefaults();
float		sizeOfBrowserColumnsFromDefaults();
float		FontSizeOfDifferencesWebviewFromDefaults();

int			LoggingLevelForHGCommands();
int			LaunchCountFromDefaults();
int			NumContextLinesForDifferencesWebviewFromDefaults();
NSString*	AddRemoveSimilarityFactorFromDefaults();
NSString*	DefaultHGIgnoreContentsFromDefaults();
NSString*	DefaultWorkspacePathFromDefaults();
NSString*	LocalHGShellAliasNameFromDefaults();
NSString*	LocalWhitelistedHGShellAliasNameFromDefaults();
NSString*	MacHgLogFileLocation();
NSString*	ToolNameForDiffingFromDefaults();
NSString*	ToolNameForMergingFromDefaults();
NSColor*	LogEntryTableTagHighlightColor();
NSColor*	LogEntryTableParentHighlightColor();
NSColor*	LogEntryTableBranchHighlightColor();
NSColor*	LogEntryTableBookmarkHighlightColor();


AfterMergeDoOption				AfterMergeDoFromDefaults();
AfterMergeSwitchToOption		AfterMergeSwitchToFromDefaults();
RevisionSortOrderOption			RevisionSortOrderFromDefaults();
DateAndTimeFormatOption			DateAndTimeFormatFromDefaults();
HandleOrigFilesOption			HandleGeneratedOrigFilesFromDefaults();
OnActivationOpenWhatOption		OnActivationOpenFromDefaults();
ToolForDiffing					UseWhichToolForDiffingFromDefaults();
ToolForMerging					UseWhichToolForMergingFromDefaults();
FSViewerNumberDefaultOption		DefaultFilesViewFromDefaults();

BrowserDoubleClickAction		browserBehaviourDoubleClick();
BrowserDoubleClickAction		browserBehaviourCommandDoubleClick();
BrowserDoubleClickAction		browserBehaviourOptionDoubleClick();
BrowserDoubleClickAction		browserBehaviourCommandOptionDoubleClick();





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Globals
// -----------------------------------------------------------------------------------------------------------------------------------------

extern NSMutableDictionary* changesetHashToLogRecord;	// Global dictionary of LogRecords

extern NSNumber*		NOasNumber;
extern NSNumber*		YESasNumber;
extern NSNumber*		SlotNumber;
extern NSArray*			configurationForProgress;


// Font Attributes
extern NSDictionary*	boldSystemFontAttributes;
extern NSDictionary*	italicSystemFontAttributes;
extern NSDictionary*	smallBoldCenteredSystemFontAttributes;
extern NSDictionary*	smallBoldSystemFontAttributes;
extern NSDictionary*	smallCenteredSystemFontAttributes;
extern NSDictionary*	smallItalicSystemFontAttributes;
extern NSDictionary*	smallSystemFontAttributes;
extern NSDictionary*	smallFixedWidthUserFontAttributes;
extern NSDictionary*	smallGraySystemFontAttributes;
extern NSDictionary*	standardSidebarFontAttributes;
extern NSDictionary*	systemFontAttributes;
extern NSDictionary*	graySystemFontAttributes;

extern NSColor*			virginSidebarColor;
extern NSColor*			virginSidebarSelectedColor;
extern NSColor*			missingSidebarColor;
extern NSColor*			missingSidebarSelectedColor;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Icon sizes
// -----------------------------------------------------------------------------------------------------------------------------------------

#define ICON_INSET_VERT		 2.0	// The size of empty space between the icon end the top/bottom of the cell
#define ICON_SIZE			16.0	// Our Icons are ICON_SIZE x ICON_SIZE
#define ICON_INSET_HORIZ 	 4.0	// Distance to inset the icon from the left edge.
#define ICON_INTERSPACING	 5.0	// Distance between the status icons and the file icon if the file icon is present.
#define ICON_TEXT_SPACING	 4.0	// Distance between the end of the icon and the text part
#define IconOverlapCompression 3	// This controls how squished the icons look when there are multiple icons representing the
									// status of a directory. With this setting just a 3rd of an icon pokes out behind the icon in
									// front of it. This looks to be a nice balance between composite images not being too large
									// and still seeing the multiple icons which make up the status.




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

#define exectueOnlyOnce(block)	\
{								\
static dispatch_once_t doOnce;	\
dispatch_once(&doOnce, (block));\
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
BOOL		repositoryExistsAtPath(NSString* path);			// Does a repository exist at the given local file path.
NSArray*	pruneDisallowedPaths(NSArray* paths);
NSArray*	pruneContainedPaths(NSArray* paths);





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
NSString*	trimmedURL(NSString* string);
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
NSArray*	aliasesForShell(NSString* path);					// the aliases for the local hg commands
NSString*	tempFilePathWithTemplate(NSString* nameTemplate);	// return the file name of a temporary file in the temporary directory based on nameTemplate




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Type Conversion
// -----------------------------------------------------------------------------------------------------------------------------------------

static inline NSString*	intAsString(int i)				{ return [NSString stringWithFormat:@"%d", i]; }
static inline int		stringAsInt(NSString* str)		{ return [str intValue]; }

static inline NSNumber*	intAsNumber(int i)				{ return [NSNumber numberWithInt:i]; }
static inline int		numberAsInt(NSNumber* num)		{ return [num intValue]; }

static inline NSNumber*	floatAsNumber(float f)			{ return [NSNumber numberWithFloat:f]; }
static inline float		numberAsFloat(NSNumber* num)	{ return [num floatValue]; }

static inline NSNumber*	boolAsNumber(bool b)			{ return [NSNumber numberWithBool:b]; }
static inline BOOL		numberAsBool(NSNumber* num)		{ return [num boolValue]; }

static inline NSString*	numberAsString(NSNumber* num)	{ return [num stringValue]; }
static inline NSNumber*	stringAsNumber(NSString* str)	{ return [NSNumber numberWithInt:[str intValue]]; }

static inline NSString* dupString(NSString* str)		{ return str ? [NSString stringWithString:str] : nil; }

#define DynamicCast(type,obj)  (([(obj) isKindOfClass:[type class]]) ? ((type*)(obj)) : nil)	// Return the casted object if it is of the right type which we
																								// determine at run time

#define ExactDynamicCast(type,obj) (([(obj) class] == [type class]) ? ((type*)(obj)) : nil)		// Return the casted object if it is of the exact type which we
																								// determine at run time

static inline NSInteger constrainInteger(NSInteger val, NSInteger min, NSInteger max)	{ if (val < min) return min; if (val > max) return max; return val; }
static inline CGFloat   constrainFloat(  CGFloat   val, CGFloat   min, CGFloat   max)	{ if (val < min) return min; if (val > max) return max; return val; }

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
// MARK:  Open Panel
// -----------------------------------------------------------------------------------------------------------------------------------------

NSString*			getSingleDirectoryPathFromOpenPanel();
NSString*			getSingleFilePathFromOpenPanel();
NSString*			getSingleApplicationPathFromOpenPanel(NSString* forDocument);
NSArray*			getListOfFilePathsFromOpenPanel(NSString* startingPath);





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Common Functions
// -----------------------------------------------------------------------------------------------------------------------------------------

static inline BOOL IsEmpty(id thing)
{
    return
		thing == nil ||
		([thing respondsToSelector:@selector(length)] && [(NSData*)thing length] == 0) ||
		([thing respondsToSelector:@selector(count)]  && [(NSArray*)thing count] == 0);
}


static inline BOOL		IsNotEmpty(id thing) { return !IsEmpty(thing); }

NS_INLINE NSRange		MakeRangeFirstLast(NSUInteger first, NSUInteger last)	 { NSUInteger min = MIN(first, last); NSUInteger max = MAX(first, last); return (NSRange){.location = min, .length = max + 1 - min}; }
NS_INLINE LowHighPair	MakeLowHighPair(NSInteger low, NSInteger high)			 { return (LowHighPair){.lowRevision = low, .highRevision = high}; }

static inline NSColor*	rgbColor255( CGFloat r, CGFloat g, CGFloat b)			 { return [NSColor colorWithDeviceRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]; }
static inline NSColor*	rgbaColor255(CGFloat r, CGFloat g, CGFloat b, CGFloat a) { return [NSColor colorWithDeviceRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]; }

extern void				PlayBeep();

static inline NSRect	UnionWidthHeight(NSRect r, CGFloat w, CGFloat h) { r.size.width = MAX(r.size.width, w); r.size.height = MAX(r.size.height, h); return r;}
static inline NSRect	UnionRectWithSize(NSRect r, NSSize s) { r.size.width = MAX(r.size.width, s.width); r.size.height = MAX(r.size.height, s.height); return r;}
static inline NSSize	UnionSizeWIthSize(NSSize r, NSSize s) { return NSMakeSize(MAX(r.width, s.width), MAX(r.height, s.height)); }

static inline NSString* fstr(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString* string = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    return string;
}

#define MakeNSValue(type,obj) ([NSValue value:&obj  withObjCType:@encode(type)])



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

// MARK: -
@protocol AccessesDocument
- (MacHgDocument*)	myDocument;
@end


// MARK: -
@protocol ShellTaskDelegate <NSObject>
@optional
- (void) gotError:(NSString*)errorString;
- (void) gotOutput:(NSString*)outputString;
- (void) taskFinished;
- (void) shellTaskCreated:(ShellTask*)shellTask;
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
@interface NSObject (NSObjectPlusSelectorResponders)
- (id) performSelectorIfPossible:(SEL)sel;
- (id) performSelectorIfPossible:(SEL)sel withObject:(id)obj;
@end


// MARK: -
@interface NSString ( NSStringPlusExtensions )
- (BOOL)	isNotEqualToString:(NSString*)aString;
- (BOOL)	differsOnlyInCaseFrom:(NSString*)aString;
- (NSComparisonResult)caseInsensitiveNumericCompare:(NSString*)aString;
- (BOOL)	endsWithNewLine;
- (NSString*) SHA1HashString;
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
- (void) addAttribute:(NSString*)name value:(id)value;
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
typedef BOOL (^ArrayFilterBlock)(id);
@interface NSArray ( NSArrayPlusAccessors )
- (id)		 firstObject;
- (NSArray*) reversedArray;
- (NSArray*) arrayByRemovingObject:(id)object;
- (NSArray*) filterArrayWithBlock:(ArrayFilterBlock)block;
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
- (id)		objectForKey:(id)key addingIfNil:(Class)class;
@end


// MARK: -
@interface NSTask (NSTaskPlusExtensions)
- (void) cancelTask;
@end


// MARK: -
@interface NSWorkspace ( NSWorkspacePlusExtensions )
+ (NSImage*) iconImageOfSize:(NSSize)size forPath:(NSString*)path;
+ (NSImage*) iconImageOfSize:(NSSize)size forPath:(NSString*)path withDefault:(NSString*)imageName;
@end


// MARK: -
@interface NSApplication ( NSApplicationPlusExtensions )
- (void)	 presentAnyErrorsAndClear:(NSError**)err;
+ (NSArray*) applicationsForURL:(NSURL*)url;
+ (NSURL*)	 applicationForURL:(NSURL*)url;
@end


// MARK: -
@interface NSFileManager ( NSFileManagerPlusAppending )
- (void)	appendString:(NSString*)string toFilePath:(NSString*)path;
@end


// MARK: -
@interface NSFileHandle (CSFileHandleExtensions)
- (NSData*)	readDataToEndOfFileIgnoringErrors;
- (NSData*)	availableDataIgnoringErrors;
@end


// MARK: -
@interface NSAlert ( NSAlertPlusExtensions )
- (void)	addSuppressionCheckBox;
@end


// MARK: -
@interface NSColor ( NSColorPlusExtensions )
- (NSColor*) intensifySaturationAndBrightness:(double)factor;
+ (NSColor*) errorColor;
+ (NSColor*) successColor;
- (void)	 bwDrawPixelThickLineAtPosition:(int)posInPixels withInset:(int)insetInPixels inRect:(NSRect)aRect inView:(NSView*)view horizontal:(BOOL)isHorizontal flip:(BOOL)shouldFlip;
@end


// MARK: -
@interface NSView ( NSViewPlusExtensions )
- (void)	setCenterX:(CGFloat)coord;
- (void)	setCenterX:(CGFloat)coord animate:(BOOL)animate;
- (void)	setMinX:(CGFloat)coord;
- (void)	setMaxX:(CGFloat)coord;
- (void)	setToRightOf:(NSView*)theView bySpacing:(CGFloat)coord;
- (NSBox*)  enclosingBoxView;
- (NSView*) enclosingViewOfClass:(Class)class;
@end


// MARK: -
@interface NSWindow ( NSWindowPlusExtensions )
- (void)	resizeSoContentsFitInFields:(NSControl*)ctrl1, ... NS_REQUIRES_NIL_TERMINATION;
@end


// MARK: -
@interface NSResponder ( NSResponderPlusExtensions )
- (BOOL)	hasAncestor:(NSResponder*)responder;
@end


// MARK: -
@interface NSBox ( NSBoxPlusExtensions )
- (void)	growToFit;
@end


// MARK: -
@interface NSTableView ( NSTableViewPlusExtensions )
- (void)	selectRow:(NSInteger)row;
- (BOOL)	rowWasClicked;
- (NSInteger) chosenRow;	// If a row was clicked on (that triggered an action) in the table then return
							// that, or else return the selected row
- (BOOL)	clickedRowInSelectedRows;
- (BOOL)	clickedRowOutsideSelectedRows;
- (BOOL)	selectedRowsWereChosen;
- (void)	scrollToRangeOfRowsLow:(NSInteger)lowTableRow high:(NSInteger)highTableRow;
@end



// MARK: -
@interface NSOutlineView ( NSOutlineViewPlusExtensions )
- (id) selectedItem;
- (id) clickedItem;
- (NSArray*) selectedItems;
- (id) chosenItem;				// If a row was clicked on (that triggered an action) in the outline then return that item for that
								// row, or else return the selected item 
- (NSArray*) chosenItems;		// If a row was clicked on (that triggered an action) in the outline then if that row is in the
								// selection then return the selected items, or else just return the item at that row. If no row
								// was clicked then return the selected items.

- (void) selectItem:(id)item;
- (void) selectItems:(NSArray*)items;
@end
