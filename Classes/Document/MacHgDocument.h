//
//  MyDocument.h
//  MacHg
//
//  Created by Jason Harris on 12/3/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//


#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "FSViewer.h"
#import <Quartz/Quartz.h>	// Quartz framework provides the QLPreviewPanel public API

@class SidebarSplitView;
@class LoadedInitializationData;
@protocol MonitorFSEventListenerProtocol;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: MyDocument
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface MacHgDocument : NSDocument <MonitorFSEventListenerProtocol, QLPreviewPanelDataSource, QLPreviewPanelDelegate>
{
	IBOutlet NSBox*					mainContentBox;				// This is the view into which the panes will be attached.
	IBOutlet Sidebar*				sidebar_;					// The sidebar containing all of the repository references in the document
	IBOutlet SidebarSplitView*		mainSplitView;				// The splitview containing the sidebar on the lhs and the pane on the rhs
	IBOutlet NSWindow*				mainWindow_;
	IBOutlet ThickSplitView*		sidebarAndInformation_;		// The thick split view inside the lhs sidebar as a whole.
	IBOutlet NSSearchField*			toolbarSearchField_;		// This is the search field inside the toolbar item inside the toolbar.
	IBOutlet NSToolbarItem*			toolbarSearchItem_;			// This is the toolbarItem inside the toolbar. (It contains the search field)
	IBOutlet NSSegmentedControl*	toolbarSegementedControl_;	// This is the segmented control to switch views.

	
	// Information and Activity View
	IBOutlet ProcessListController* theProcessListController_;
	IBOutlet NSBox*					informationAndActivityBox_;
	IBOutlet NSBox*					informationBox_;

	// Customized Update Alert
	IBOutlet NSView*				updateAlertAccessoryView;
	IBOutlet NSButton*				updateAlertAccessoryCleanCheckBox;
	IBOutlet NSButton*				updateAlertAccessoryAlertSuppressionCheckBox;

 @private
	
	// Pane Controllers
	FilesViewController*				theFilesViewController_;
	HistoryViewController*				theHistoryViewController_;
	DifferencesViewController*			theDifferencesViewController_;
	BackingViewController*				theBackingViewController_;

	// Sheet Controllers
	AddLabelSheetController*			theAddLabelSheetController_;
	BackoutSheetController*				theBackoutSheetController_;
	CloneSheetController*				theCloneSheetController_;
	CollapseSheetController*			theCollapseSheetController_;
	CommitSheetController*				theCommitSheetController_;
	ExportPatchesSheetController*		theExportPatchesSheetController_;
	HistoryEditSheetController*			theHistoryEditSheetController_;
	ImportPatchesSheetController*		theImportPatchesSheetController_;
	IncomingSheetController*			theIncomingSheetController_;
	LocalRepositoryRefSheetController*	theLocalRepositoryRefSheetController_;
	MergeSheetController*				theMergeSheetController_;
	MoveLabelSheetController*			theMoveLabelSheetController_;
	OutgoingSheetController*			theOutgoingSheetController_;
	PullSheetController*				thePullSheetController_;
	PushSheetController*				thePushSheetController_;
	RebaseSheetController*				theRebaseSheetController_;
	RenameFileSheetController*			theRenameFileSheetController_;
	RevertSheetController*				theRevertSheetController_;
	ServerRepositoryRefSheetController*	theServerRepositoryRefSheetController_;
	StripSheetController*				theStripSheetController_;
	UpdateSheetController*				theUpdateSheetController_;

	
	// Initilizers for Pane and Sheet Controllers
	dispatch_once_t						theFilesViewControllerInitilizer_;
	dispatch_once_t						theHistoryViewControllerInitilizer_;
	dispatch_once_t						theDifferencesViewControllerInitilizer_;
	dispatch_once_t						theBackingViewControllerInitilizer_;
	dispatch_once_t						theAddLabelSheetControllerInitilizer_;
	dispatch_once_t						theBackoutSheetControllerInitilizer_;
	dispatch_once_t						theCloneSheetControllerInitilizer_;
	dispatch_once_t						theCollapseSheetControllerInitilizer_;
	dispatch_once_t						theCommitSheetControllerInitilizer_;
	dispatch_once_t						theExportPatchesSheetControllerInitilizer_;
	dispatch_once_t						theHistoryEditSheetControllerInitilizer_;
	dispatch_once_t						theImportPatchesSheetControllerInitilizer_;
	dispatch_once_t						theIncomingSheetControllerInitilizer_;
	dispatch_once_t						theLocalRepositoryRefSheetControllerInitilizer_;
	dispatch_once_t						theMergeSheetControllerInitilizer_;
	dispatch_once_t						theMoveLabelSheetControllerInitilizer_;
	dispatch_once_t						theOutgoingSheetControllerInitilizer_;
	dispatch_once_t						thePullSheetControllerInitilizer_;
	dispatch_once_t						thePushSheetControllerInitilizer_;
	dispatch_once_t						theRebaseSheetControllerInitilizer_;
	dispatch_once_t						theRenameFileSheetControllerInitilizer_;
	dispatch_once_t						theRevertSheetControllerInitilizer_;
	dispatch_once_t						theServerRepositoryRefSheetControllerInitilizer_;
	dispatch_once_t						theStripSheetControllerInitilizer_;
	dispatch_once_t						theUpdateSheetControllerInitilizer_;
	
	
	QLPreviewPanel*				quickLookPreviewPanel;
	SearchFieldCategory			toolbarSearchFieldCategory_;
	BOOL						toolbarSearchFieldQueryIsValid_;
	NSString*					toolbarSearchFieldValue_;
	
	// Queues and Events
	dispatch_queue_t			refreshBrowserSerialQueue_;
	dispatch_queue_t			mercurialTaskSerialQueue_;
	MonitorFSEvents*			events_;
	SingleTimedQueue*			queueForUnderlyingRepositoryChangedViaEvents_;
	NSInteger					eventsSuspensionCount_;
	NSMutableArray*				changedPathsDuringSuspension_;
	
	
	NSMutableDictionary*		connections_;			// Storage for option values of connections (push, pull, incoming,
														// outgoing, etc) between one repositories and another

	HunkExclusions*				hunkExclusions_;		// Storage for which hunks are being excluded from commits.

	PaneViewNum					currentPane_;			// The current Pane being shown by the document

	RepositoryData*				repositoryData_;		// This is the current collection of log entries (the entries which make up the current repository)

	LoadedInitializationData*	loadedDataProxy_;		// When readFromData is called we don't have a fully constructed
														// object yet so we store the bits we would set, eg which nodes in the
														// side bar are expanded, etc, then once the object is fully loaded we
														// use these stored values.
	BOOL						showingSheet_;			// Record if this document is currently showing a sheet at the moment.
														// Then in validateUserInterfaceItem I can detect if we are showing a
														// sheet and then not validate the menu items. There should be a
														// better way to detect this but after googling for a bit I can't see
														// it. If you know email me!
}

@property (nonatomic, assign) Sidebar*				sidebar;
@property (nonatomic, assign) NSWindow*				mainWindow;
@property (nonatomic, assign) NSMutableDictionary*	connections;
@property (nonatomic, assign) HunkExclusions*		hunkExclusions;
@property (readonly,  assign) ProcessListController* theProcessListController;
@property (readonly,  assign) dispatch_queue_t		refreshBrowserSerialQueue;
@property (readonly,  assign) dispatch_queue_t		mercurialTaskSerialQueue;
@property (readonly,  assign) MonitorFSEvents*		events;
@property (readonly,  assign) NSSearchField*		toolbarSearchField;
@property (readonly,  assign) NSString*				toolbarSearchFieldValue;
@property (readonly,  assign) SearchFieldCategory	toolbarSearchFieldCategory;
@property (nonatomic, assign) BOOL					toolbarSearchFieldQueryIsValid;
@property (readonly,  assign) NSToolbarItem*		toolbarSearchItem;

- (FilesView*)						theFilesView;
- (HistoryView*)					theHistoryView;
- (DifferencesView*)				theDifferencesView;


// Access the controllers
- (FilesViewController*)			theFilesViewController;
- (HistoryViewController*)			theHistoryViewController;
- (DifferencesViewController*)		theDifferencesViewController;
- (BackingViewController*)			theBackingViewController;

- (AddLabelSheetController*)		theAddLabelSheetController;
- (BackoutSheetController*)			theBackoutSheetController;
- (CloneSheetController*)			theCloneSheetController;
- (CollapseSheetController*)		theCollapseSheetController;
- (CommitSheetController*)			theCommitSheetController;
- (ExportPatchesSheetController*)	theExportPatchesSheetController;
- (HistoryEditSheetController*)		theHistoryEditSheetController;
- (ImportPatchesSheetController*)	theImportPatchesSheetController;
- (IncomingSheetController*)		theIncomingSheetController;
- (LocalRepositoryRefSheetController*)	theLocalRepositoryRefSheetController;
- (MergeSheetController*)			theMergeSheetController;
- (MoveLabelSheetController*)		theMoveLabelSheetController;
- (OutgoingSheetController*)		theOutgoingSheetController;
- (PullSheetController*)			thePullSheetController;
- (PushSheetController*)			thePushSheetController;
- (RebaseSheetController*)			theRebaseSheetController;
- (RenameFileSheetController*)		theRenameFileSheetController;
- (RevertSheetController*)			theRevertSheetController;
- (ServerRepositoryRefSheetController*)	theServerRepositoryRefSheetController;
- (StripSheetController*)			theStripSheetController;
- (UpdateSheetController*)			theUpdateSheetController;


// Testing
- (IBAction)	testBrowserLoad:(id)sender;


// Pane switching
- (BOOL)		showingFilesView;
- (BOOL)		showingHistoryView;
- (BOOL)		showingDifferencesView;
- (BOOL)		showingBackingView;
- (BOOL)		showingFilesOrHistoryView;
- (BOOL)		showingFilesOrDifferencesView;
- (BOOL)		showingFilesOrHistoryOrDifferencesView;
- (BOOL)		showingASheet;
- (PaneViewNum)	currentPane;
- (void)		setCurrentPane:(PaneViewNum)paneNum;
- (IBAction)	actionSwitchViewToFilesView:(id)sender;
- (IBAction)	actionSwitchViewToHistoryView:(id)sender;
- (IBAction)	actionSwitchViewToDifferencesView:(id)sender;
- (IBAction)	actionSwitchViewToBackingView:(id)sender;
- (IBAction)	actionSwitchViewToFilesBrowserView:(id)sender;
- (IBAction)	actionSwitchViewToFilesOutlineView:(id)sender;
- (IBAction)	actionSwitchViewToFilesTableView:(id)sender;


// Document Information
- (NSString*)	documentNameForAutosave;

// Undo
- (void)		removeAllUndoActionsForDocument;


// Query the active repository
- (BOOL)		localRepoIsSelectedAndReady;
- (BOOL)		localRepoIsChosenAndReady;
- (BOOL)		localOrServerRepoIsSelectedAndReady;
- (BOOL)		localOrServerRepoIsChosenAndReady;
- (NSString*)	absolutePathOfRepositoryRoot;				// Uses the root from the repository data
- (NSString*)	absolutePathOfRepositoryRootFromSidebar;	// Uses the root from the sidebar
- (NSArray*)	absolutePathOfRepositoryRootAsArray;
- (NSString*)	selectedRepositoryShortName;
- (NSString*)	selectedRepositoryPath;
- (SidebarNode*) selectedRepositoryRepositoryRef;
- (void)		discardCurrentRepository;


// Query the browsed files of the repository
- (FSViewer*)	theFSViewer;
- (FSNodeInfo*)	rootNodeInfo;
- (BOOL)		singleFileIsChosenInFiles;
- (BOOL)		singleItemIsChosenInFiles;
- (BOOL)		nodesAreChosenInFiles;
- (BOOL)		statusOfChosenPathsInFilesContain:(HGStatus)status;
- (BOOL)		repositoryHasFilesWhichContainStatus:(HGStatus)status;
- (HGStatus)	statusOfChosenPathsInFiles;
- (NSArray*)	absolutePathsOfChosenFiles;
- (NSString*)	enclosingDirectoryOfChosenFiles;
- (FSNodeInfo*) nodeForPath:(NSString*)absolutePath;


// RepositoryData and Version Information
- (RepositoryData*)	 repositoryData;
- (NSNumber*)	getHGParent1Revision;
- (NSNumber*)	getHGParent2Revision;
- (NSString*)	getHGParent1Changeset;
- (NSString*)	getHGParent2Changeset;
- (NSNumber*)	getHGTipRevision;
- (NSString*)	getHGTipChangeset;
- (NSNumber*)	getSelectedRevision;
- (BOOL)		isCurrentRevisionTip;
- (BOOL)		inMergeState;
- (NSInteger)	computeNumberOfRevisions;


// Search Field
- (IBAction)	searchFieldChanged:(id)sender;
- (IBAction)	setSearchCategory:(id)sender;
- (void)		syncronizeSearchFieldTint;


// Refresh / Regenrate Browser
- (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  whileDelayingEvents:(BOOL)delay;
- (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  withDelegate:(id <ShellTaskDelegate>)delegate  whileDelayingEvents:(BOOL)delay;
- (void)		delayEventsUntilFinishBlock:(BlockProcess) theBlock;
- (void)		addToChangedPathsDuringSuspension:(NSArray*)paths;
- (void)		resumeEvents;
- (BOOL)		underlyingRepositoryChangedEventIsQueued;
- (SingleTimedQueue*) queueForUnderlyingRepositoryChangedViaEvents;
- (void)		registerPendingRefresh:(NSArray*)paths;
- (void)		registerPendingRefresh:(NSArray*)paths  visuallyDirtifyPaths:(BOOL)dirtify;
- (void)		refreshBrowserPaths:(NSArray*) absolutePaths;
- (void)		refreshBrowserPaths:(NSArray*) absolutePaths finishingBlock:(BlockProcess)theBlock;
- (IBAction)	refreshBrowserContent:(id)sender;


//
// Action Menu
// 
- (IBAction)	mainMenuCommitSelectedFiles:(id)sender;
- (IBAction)	mainMenuCommitAllFiles:(id)sender;
- (IBAction)	toolbarCommitFiles:(id)sender;
- (IBAction)	mainMenuDiffSelectedFiles:(id)sender;
- (IBAction)	mainMenuDiffAllFiles:(id)sender;
- (IBAction)	toolbarDiffFiles:(id)sender;
- (IBAction)	mainMenuAddRenameRemoveSelectedFiles:(id)sender;
- (IBAction)	mainMenuAddRenameRemoveAllFiles:(id)sender;
- (IBAction)	toolbarAddRenameRemoveFiles:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuRevertSelectedFiles:(id)sender;
- (IBAction)	mainMenuRevertAllFiles:(id)sender;
- (IBAction)	mainMenuRevertSelectedFilesToVersion:(id)sender;
- (IBAction)	toolbarRevertFiles:(id)sender;
- (IBAction)	mainMenuDeleteSelectedFiles:(id)sender;
- (IBAction)	mainMenuAddSelectedFiles:(id)sender;
- (IBAction)	mainMenuUntrackSelectedFiles:(id)sender;
- (IBAction)	mainMenuRenameSelectedItem:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuRemergeSelectedFiles:(id)sender;
- (IBAction)	mainMenuMarkResolvedSelectedFiles:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuIgnoreSelectedFiles:(id)sender;
- (IBAction)	mainMenuUnignoreSelectedFiles:(id)sender;
- (IBAction)	mainMenuAnnotateSelectedFiles:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuRollbackCommit:(id)sender;
- (IBAction)	mainMenuNoAction:(id)sender;



//
// Repository Menu Actions
//
- (IBAction)	mainMenuCloneRepository:(id)sender;
- (IBAction)	mainMenuPullFromRepository:(id)sender;
- (IBAction)	mainMenuPushToRepository:(id)sender;
- (IBAction)	mainMenuIncomingFromRepository:(id)sender;
- (IBAction)	mainMenuOutgoingToRepository:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuUpdateRepository:(id)sender;
- (IBAction)	mainMenuUpdateRepositoryToVersion:(id)sender;
- (IBAction)	mainMenuGotoChangeset:(id)sender;
- (IBAction)	mainMenuMergeWith:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuCollapseChangesets:(id)sender;
- (IBAction)	mainMenuStripChangesets:(id)sender;
- (IBAction)	mainMenuRebaseChangesets:(id)sender;
- (IBAction)	mainMenuHistoryEditChangesets:(id)sender;
- (IBAction)	mainMenuBackoutChangeset:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuManifestOfCurrentVersion:(id)sender;
- (IBAction)	mainMenuAddLabelToCurrentRevision:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuAddLocalRepositoryRef:(id)sender;
- (IBAction)	mainMenuAddServerRepositoryRef:(id)sender;
- (IBAction)	mainMenuAddNewSidebarGroupItem:(id)sender;
- (IBAction)	mainMenuRemoveSidebarItems:(id)sender;
- (IBAction)	mainMenuConfigureRepositoryRef:(id)sender;
- (IBAction)	mainMenuConfigureLocalRepositoryRef:(id)sender;
- (IBAction)	mainMenuConfigureServerRepositoryRef:(id)sender;
// ------------------------------------------------------
- (IBAction)	mainMenuRevealSelectedFilesInFinder:(id)sender;
- (IBAction)	mainMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction)	mainMenuOpenTerminalHere:(id)sender;



// File Menu
- (IBAction)	mainMenuImportPatches:(id)sender;
- (IBAction)	mainMenuExportPatches:(id)sender;


// Switching actions
- (IBAction)	toolbarUpdate:(id)sender;

- (IBAction)	mainMenuRevealRepositoryInFinder:(id)sender;


// Proxies for SideBar Methods
- (IBAction)	mainMenuAddAndCloneServerRepositoryRef:(id)sender;


// Do some primary actions
- (BOOL)		primaryActionAddRenameRemoveFiles:(NSArray*)absolutePaths;
- (BOOL)		primaryActionRevertFiles:(NSArray*)absolutePaths toVersion:(NSNumber*)version;
- (BOOL)		primaryActionDeleteSelectedFiles:(NSArray*)theSelectedFiles;
- (BOOL)		primaryActionAddSelectedFiles:(NSArray*)theSelectedFiles;
- (BOOL)		primaryActionUntrackSelectedFiles:(NSArray*)theSelectedFiles;
- (BOOL)		primaryActionRemerge:(NSArray*)absolutePaths withConfirmation:(BOOL)confirm;
- (BOOL)		primaryActionMarkResolved:(NSArray*)absolutePaths withConfirmation:(BOOL)confirm;
- (BOOL)		primaryActionIgnoreSelectedFiles:(NSArray*)theSelectedFiles;
- (BOOL)		primaryActionUnignoreSelectedFiles:(NSArray*)theSelectedFiles;
- (BOOL)		primaryActionAnnotateSelectedFiles:(NSArray*)theSelectedFiles;
- (BOOL)		primaryActionUpdateFilesToVersion:(NSNumber*)version withCleanOption:(BOOL)clean;
- (BOOL)		primaryActionBackoutFilesToVersion:(NSNumber*)version;
- (BOOL)		primaryActionMergeWithVersion:(NSNumber*)mergeVersion andOptions:(NSArray*)options withConfirmation:(BOOL)confirm;
- (void)		primaryActionDisplayManifestForVersion:(NSNumber*)version;
- (void)		primaryActionAnnotateSelectedFiles:(NSArray*)absolutePaths withRevision:(NSNumber*)version andOptions:(NSArray*)options;
- (void)		viewDifferencesInCurrentRevisionFor:(NSArray*)absolutePaths toRevision:(NSString*)versionToCompareTo;


// Quicklook handling
- (BOOL)		quicklookPreviewIsVisible;
- (IBAction)    togglePreviewPanel:(id)previewPanel;


// Validation
- (BOOL)		validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
- (BOOL)		localRepoIsSelectedAndReady;
- (BOOL)		localOrServerRepoIsSelectedAndReady;
- (BOOL)		toolbarActionAppliesToFilesWith:(HGStatus)status;
- (BOOL)		validateAndSwitchMenuForCommitAllFiles:(id)menuItem;
- (BOOL)		validateAndSwitchMenuForRemoveSidebarItems:(id)menuItem;


// Saving
- (void)		saveDocumentIfNamed;


// Cache handling
- (NSString*)	loadCachedCopyOfPath:(NSString*)absolutePath forChangeset:(NSString*)changeset;


// Processes Management
- (void)		dispatchToMercurialQueuedWithDescription:(NSString*)processDescription process:(BlockProcess)block;


- (IBAction)	actionTestListingItem:(id)sender;
- (IBAction)	doLinkUp:(id)sender;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LoadedInitializationData
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface LoadedInitializationData : NSObject
{
  @public
	Sidebar*				loadedSidebar;
	NSMutableDictionary*	loadedConnections;
	HunkExclusions*			loadedHunkExclusions;
	NSInteger				loadedCurrentPane;
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: SidebarSplitView
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface SidebarSplitView : NSSplitView <NSSplitViewDelegate>
{
	IBOutlet NSView*	sidebarGroup;
	IBOutlet NSView*	contentGroup;
	IBOutlet NSView*	resizeThumb;
}
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: RepositoryPaths
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface RepositoryPaths : NSObject
{
	NSArray* absolutePaths_;	// an array of absolute path NSStrings
	NSString* rootPath_;		// the absolute root of the repository
}

@property (readwrite,assign) NSArray*		absolutePaths;
@property (readwrite,assign) NSString*		rootPath;

+ (RepositoryPaths*) fromPaths:(NSArray*)theAbsolutePaths withRootPath:(NSString*)theRootPath;
+ (RepositoryPaths*) fromPath:(NSString*)absolutePath     withRootPath:(NSString*)theRootPath;
+ (RepositoryPaths*) fromRootPath:(NSString*)theRootPath;
@end

