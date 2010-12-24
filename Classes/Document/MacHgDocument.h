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
	BrowserViewController*				theBrowserViewController_;
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

- (BrowserView*)					theBrowserView;
- (HistoryView*)					theHistoryView;
- (DifferencesView*)				theDifferencesView;


// Access the controllers
- (BrowserViewController*)			theBrowserViewController;
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
- (BOOL)		showingBrowserView;
- (BOOL)		showingHistoryView;
- (BOOL)		showingDifferencesView;
- (BOOL)		showingBackingView;
- (BOOL)		showingBrowserOrHistoryView;
- (BOOL)		showingBrowserOrDifferencesView;
- (BOOL)		showingBrowserOrHistoryOrDifferencesView;
- (BOOL)		showingASheet;
- (PaneViewNum)	currentPane;
- (void)		setCurrentPane:(PaneViewNum)paneNum;
- (IBAction)	actionSwitchViewToBrowserView:(id)sender;
- (IBAction)	actionSwitchViewToHistoryView:(id)sender;
- (IBAction)	actionSwitchViewToDifferencesView:(id)sender;
- (IBAction)	actionSwitchViewToBackingView:(id)sender;


// Document Information
- (NSString*)	documentNameForAutosave;

// Undo
- (void)		removeAllUndoActionsForDocument;


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
- (BOOL)		singleFileIsChosenInBrower;
- (BOOL)		singleItemIsChosenInBrower;
- (BOOL)		nodesAreChosenInBrowser;
- (BOOL)		pathsAreSelectedInBrowserWhichContainStatus:(HGStatus)status;
- (BOOL)		repositoryHasFilesWhichContainStatus:(HGStatus)status;
- (HGStatus)	statusOfChosenPathsInBrowser;
- (NSArray*)	absolutePathsOfBrowserChosenFiles;
- (NSString*)	enclosingDirectoryOfBrowserChosenFiles;
- (NSArray*)	filterPaths:(NSArray*)absolutePaths byBitfield:(HGStatus)status;
- (FSNodeInfo*) nodeForPath:(NSString*)absolutePath;


// Version Information
- (NSNumber*)	getHGParent1Revision;
- (NSNumber*)	getHGParent2Revision;
- (NSString*)	getHGParent1Changeset;
- (NSString*)	getHGParent2Changeset;
- (NSNumber*)	getHGTipRevision;
- (NSString*)	getHGTipChangeset;
- (BOOL)		isCurrentRevisionTip;
- (BOOL)		inMergeState;
- (NSInteger)	computeNumberOfRevisions;


// Search Field
- (IBAction)	searchFieldChanged:(id)sender;


// Refresh / Regenrate Browser
- (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath whileDelayingEvents:(BOOL)delay;
- (void)		delayEventsUntilFinishBlock:(BlockProcess) theBlock;
- (void)		addToChangedPathsDuringSuspension:(NSArray*)paths;
- (void)		resumeEvents;
- (BOOL)		underlyingRepositoryChangedEventIsQueued;
- (void)		registerPendingRefresh:(NSArray*)paths;
- (void)		registerPendingRefresh:(NSArray*)paths  visuallyDirtifyPaths:(BOOL)dirtify;
- (void)		refreshBrowserPaths:(NSArray*) absolutePaths;
- (void)		refreshBrowserPaths:(NSArray*) absolutePaths finishingBlock:(BlockProcess)theBlock;
- (IBAction)	refreshBrowserContent:(id)sender;
- (NSArray*)	statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath;


// File Menu
- (IBAction)	mainMenuImportPatches:(id)sender;
- (IBAction)	mainMenuExportPatches:(id)sender;


// All Files Menu Actions
- (IBAction)	mainMenuUpdateRepository:(id)sender;
- (IBAction)	mainMenuUpdateRepositoryToVersion:(id)sender;


// Switching actions
- (IBAction)	toolbarUpdate:(id)sender;


- (IBAction)	mainMenuAddLabelToCurrentRevision:(id)sender;
- (IBAction)	mainMenuMergeWith:(id)sender;
- (IBAction)	mainMenuRemergeSelectedFiles:(id)sender;
- (IBAction)	mainMenuMarkResolvedSelectedFiles:(id)sender;


// Viewing Menu Actions
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
- (IBAction)	mainMenuOpenTerminalHere:(id)sender;
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


- (IBAction)	actionTestListingItem:(id)sender;
- (IBAction)	doLinkUp:(id)sender;


// Validation
- (BOOL)		validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
- (BOOL)		repositoryIsSelectedAndReady;
- (BOOL)		repositoryOrServerIsSelectedAndReady;
- (BOOL)		toolbarActionAppliesToFilesWith:(HGStatus)status;
- (BOOL)		validateAndSwitchMenuForCommitAllFiles:(NSMenuItem*)menuItem;
- (BOOL)		validateAndSwitchMenuForCommitSelectedFiles:(NSMenuItem*)menuItem;


// Saving
- (void)		saveDocumentIfNamed;


// RepositoryData handling
- (RepositoryData*)	 repositoryData;


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