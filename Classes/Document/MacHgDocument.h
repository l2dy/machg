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
#import "FSBrowser.h"

@class LoadedInitializationData;
@protocol MonitorFSEventListenerProtocol;


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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: MyDocument
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface MacHgDocument : NSDocument <MonitorFSEventListenerProtocol>
{
	IBOutlet NSBox*					mainContentBox;				// This is the view into which the panes will be attached.
	IBOutlet Sidebar*				sidebar_;					// The sidebar containing all of the repository references in the document
	IBOutlet BWSplitView*			mainSplitView;				// The splitview containing the sidebar on the lhs and the pane on the rhs
	IBOutlet NSWindow*				mainWindow_;
	IBOutlet ThickSplitView*		sidebarAndInformation_;		// The thick split view inside the lhs sidebar as a whole.
	IBOutlet NSSearchField*			toolbarSearchField_;		// This is the search field inside the toolbar item inside the toolbar.
	IBOutlet NSToolbarItem*			toolbarSearchItem_;			// This is the toolbarItem inside the toolbar. (It contains the search field)

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
	BrowserPaneController*				theBrowserPaneController_;
	HistoryPaneController*				theHistoryPaneController_;
	DifferencesPaneController*			theDifferencesPaneController_;
	BackingPaneController*				theBackingPaneController_;

	// Sheet Controllers
	AddLabelSheetController*			theAddLabelSheetController_;
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

	
	// Queues and Events
	dispatch_queue_t			refreshBrowserSerialQueue_;
	dispatch_queue_t			mercurialTaskSerialQueue_;
	MonitorFSEvents*			events_;
	SingleTimedQueue*			queueForUnderlyingRepositoryChangedViaEvents_;
	NSInteger					eventsSuspensionCount_;
	NSMutableArray*				changedPathsDuringSuspension_;
	
	
	NSMutableDictionary*		connections_;			// Storage for option values of connections (push, pull, incoming,
														// outgoing, etc) between one repositories and another
	
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
@property (readonly,  assign) ProcessListController* theProcessListController;
@property (readonly,  assign) dispatch_queue_t		refreshBrowserSerialQueue;
@property (readonly,  assign) dispatch_queue_t		mercurialTaskSerialQueue;
@property (readonly,  assign) MonitorFSEvents*		events;
@property (readonly,  assign) NSSearchField*		toolbarSearchField;
@property (readonly,  assign) NSToolbarItem*		toolbarSearchItem;


// Access the controllers
- (BrowserPaneController*)			theBrowserPaneController;
- (HistoryPaneController*)			theHistoryPaneController;
- (DifferencesPaneController*)		theDifferencesPaneController;
- (BackingPaneController*)			theBackingPaneController;

- (AddLabelSheetController*)		theAddLabelSheetController;
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
- (BOOL)		showingBrowserPane;
- (BOOL)		showingHistoryPane;
- (BOOL)		showingDifferencesPane;
- (BOOL)		showingBackingPane;
- (BOOL)		showingBrowserOrHistoryPane;
- (BOOL)		showingBrowserOrDifferencesPane;
- (BOOL)		showingBrowserOrHistoryOrDifferencesPane;
- (PaneViewNum)	currentPane;
- (void)		setCurrentPane:(PaneViewNum)paneNum;
- (IBAction)	actionSwitchViewToBrowserPane:(id)sender;
- (IBAction)	actionSwitchViewToHistoryPane:(id)sender;
- (IBAction)	actionSwitchViewToDifferencesPane:(id)sender;
- (IBAction)	actionSwitchViewToBackingPane:(id)sender;


// Document Information
- (NSString*)	documentNameForAutosave;

// Undo
- (void)		removeAllUndoActionsForDocument;
- (void)		populateOutlineContents;


// Query the active repository
- (BOOL)		aRepositoryIsSelected;
- (NSString*)	absolutePathOfRepositoryRoot;
- (NSArray*)	absolutePathOfRepositoryRootAsArray;
- (NSString*)	selectedRepositoryShortName;
- (NSString*)	selectedRepositoryPath;
- (SidebarNode*) selectedRepositoryRepositoryRef;


// Query the browsed files of the repository
- (FSBrowser*)	theBrowser;
- (FSNodeInfo*)	rootNodeInfo;
- (BOOL)		singleFileIsChosenInBrowser;
- (BOOL)		nodesAreChosenInBrowser;
- (BOOL)		pathsAreSelectedInBrowserWhichContainStatus:(HGStatus)status;
- (BOOL)		repositoryHasFilesWhichContainStatus:(HGStatus)status;
- (HGStatus)	statusOfChosenPathsInBrowser;
- (NSArray*)	absolutePathsOfBrowserChosenFiles;
- (NSString*)	enclosingDirectoryOfBrowserChosenFiles;
- (NSArray*)	filterPaths:(NSArray*)absolutePaths byBitfield:(HGStatus)status;
- (FSNodeInfo*) nodeForPath:(NSString*)absolutePath;


// Version Information
- (NSString*)	getHGTipChangeset;
- (NSString*)	getHGParentsChangeset;	// Gives the parent changeset (if there are two it gives the first)
- (NSString*)	getHGParentsChangesets;
- (NSString*)	getHGTipRevision;
- (NSString*)	getHGParent1Revision;
- (NSString*)	getHGParentsRevisions;	// Gives the parent revision (if there are two it gives the first)
- (BOOL)		isCurrentRevisionTip;
- (BOOL)		inMergeState;
- (NSInteger)	computeNumberOfRevisions;


// Search Field
- (IBAction)	searchFieldChanged:(id)sender;


// Refresh / Regenrate Browser
- (ExecutionResult) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath whileDelayingEvents:(BOOL)delay;
- (void)		delayEventsUntilFinishBlock:(BlockProcess) theBlock;
- (void)		addToChangedPathsDuringSuspension:(NSArray*)paths;
- (void)		resumeEvents;
- (void)		registerPendingRefresh:(NSArray*)paths;
- (void)		registerPendingRefresh:(NSArray*)paths  visuallyDirtifyPaths:(BOOL)dirtify;
- (void)		refreshBrowserPaths:(NSArray*) absolutePaths;
- (void)		refreshBrowserPaths:(NSArray*) absolutePaths resumeEventsWhenFinished:(BOOL)resume;
- (IBAction)	refreshBrowserContent:(id)sender;
- (NSArray*)	statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath;


// File Menu
- (IBAction)	mainMenuImportPatches:(id)sender;
- (IBAction)	mainMenuExportPatches:(id)sender;


// Contextual Menu Actions
- (IBAction)	browserMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction)	browserMenuRevealSelectedFilesInFinder:(id)sender;
- (IBAction)	browserMenuOpenTerminalHere:(id)sender;


// Primary Menu Actions
- (IBAction)	mainMenuCommitSelectedFiles:(id)sender;
- (IBAction)	mainMenuAddSelectedFiles:(id)sender;
- (IBAction)	mainMenuDiffSelectedFiles:(id)sender;


// Selected Files Menu Actions
- (IBAction)	mainMenuRevertSelectedFiles:(id)sender;
- (IBAction)	mainMenuRevertSelectedFilesToVersion:(id)sender;
- (IBAction)	mainMenuDeleteSelectedFiles:(id)sender;
- (IBAction)	mainMenuUntrackSelectedFiles:(id)sender;
- (IBAction)	mainMenuAddRenameRemoveSelectedFiles:(id)sender;
- (IBAction)	mainMenuRenameSelectedFile:(id)sender;


// All Files Menu Actions
- (IBAction)	mainMenuCommitAllFiles:(id)sender;
- (IBAction)	mainMenuAddRenameRemoveAllFiles:(id)sender;
- (IBAction)	mainMenuDiffAllFiles:(id)sender;
- (IBAction)	mainMenuRevertAllFiles:(id)sender;
- (IBAction)	mainMenuRevertAllFilesToVersion:(id)sender;
- (IBAction)	mainMenuUpdateRepository:(id)sender;
- (IBAction)	mainMenuUpdateRepositoryToVersion:(id)sender;


- (IBAction)	mainMenuAddLabelToCurrentRevision:(id)sender;
- (IBAction)	mainMenuMergeWith:(id)sender;
- (IBAction)	mainMenuRemergeSelectedFiles:(id)sender;
- (IBAction)	mainMenuMarkResolvedSelectedFiles:(id)sender;


// Viewing Menu Actions
- (IBAction)	mainMenuIgnoreSelectedFiles:(id)sender;
- (IBAction)	mainMenuUnignoreSelectedFiles:(id)sender;
- (IBAction)	mainMenuAnnotateSelectedFiles:(id)sender;

- (IBAction)	mainMenuRollbackCommit:(id)sender;
- (IBAction)	mainMenuNoAction:(id)sender;


// Repository Menu Actions
- (IBAction)	mainMenuManifestOfCurrentVersion:(id)sender;
- (IBAction)	mainMenuCloneRepository:(id)sender;
- (IBAction)	mainMenuPushToRepository:(id)sender;
- (IBAction)	mainMenuPullFromRepository:(id)sender;
- (IBAction)	mainMenuIncomingFromRepository:(id)sender;
- (IBAction)	mainMenuOutgoingToRepository:(id)sender;


// Proxies for SideBar Methods
- (IBAction)	sidebarMenuAddLocalRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuAddServerRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuConfigureLocalRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuConfigureServerRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuAddNewSidebarGroupItem:(id)sender;
- (IBAction)	sidebarMenuRemoveSidebarItem:(id)sender;
- (IBAction)	sidebarMenuRevealRepositoryInFinder:(id)sender;
- (IBAction)	sidebarMenuOpenTerminalHere:(id)sender;


// History Editing Actions
- (IBAction)	mainMenuCollapseChangesets:(id)sender;
- (IBAction)	mainMenuStripChangesets:(id)sender;
- (IBAction)	mainMenuRebaseChangesets:(id)sender;
- (IBAction)	mainMenuHistoryEditChangesets:(id)sender;


// Do some primary actions
- (BOOL)		primaryActionRevertFiles:(NSArray*)absolutePaths toVersion:(NSString*)version;
- (BOOL)		primaryActionAddRenameRemoveFiles:(NSArray*)absolutePaths;
- (BOOL)		primaryActionUpdateFilesToVersion:(NSString*)version withCleanOption:(BOOL)clean;
- (BOOL)		primaryActionMergeWithVersion:(NSString*)mergeVersion andOptions:(NSArray*)options withConfirmation:(BOOL)confirm;
- (BOOL)		primaryActionRemerge:(NSArray*)absolutePaths withConfirmation:(BOOL)confirm;
- (BOOL)		primaryActionMarkResolved:(NSArray*)absolutePaths withConfirmation:(BOOL)confirm;
- (void)		primaryActionDisplayManifestForVersion:(NSString*)version;
- (void)		primaryActionAnnotateSelectedFiles:(NSArray*)absolutePaths withRevision:(NSString*)version andOptions:(NSArray*)options;
- (void)		viewDifferencesInCurrentRevisionFor:(NSArray*)absolutePaths toRevision:(NSString*)versionToCompareTo;


- (IBAction)	actionTestListingItem:(id)sender;


// Validation
- (BOOL)		validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
- (BOOL)		repositoryIsSelectedAndReady;


// Saving
- (void)		saveDocumentIfNamed;


// RepositoryData handling
- (RepositoryData*)	 repositoryData;
- (void)		initializeRepositoryData;


// Processes Management
- (void)		dispatchToMercurialQueuedWithDescription:(NSString*)processDescription process:(BlockProcess)block;


@end


@interface LoadedInitializationData : NSObject
{
  @public
	Sidebar*				loadedSidebar;
	NSMutableDictionary*	loadedConnections;
	NSInteger				loadedCurrentPane;
}

@end