//
//  MyDocument.m
//  MacHg
//
//  Created by Jason Harris on 12/3/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//


#import "MacHgDocument.h"
#import "MyWindowController.h"
#import "AppController.h"

#import "LogEntry.h"
#import "RepositoryData.h"

#import "FilesViewController.h"
#import "HistoryViewController.h"
#import "DifferencesViewController.h"
#import "BackingViewController.h"

#import "FSViewer.h"
#import "FSViewerPaneCell.h"	// Do we need this here?
#import "FSNodeInfo.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "ProcessListController.h"

#import "AddLabelSheetController.h"
#import "BackoutSheetController.h"
#import "CloneSheetController.h"
#import "CollapseSheetController.h"
#import "CommitSheetController.h"
#import "ExportPatchesSheetController.h"
#import "HistoryEditSheetController.h"
#import "ImportPatchesSheetController.h"
#import "IncomingSheetController.h"
#import "LocalRepositoryRefSheetController.h"
#import "MergeSheetController.h"
#import "MoveLabelSheetController.h"
#import "OutgoingSheetController.h"
#import "PullSheetController.h"
#import "PushSheetController.h"
#import "RebaseSheetController.h"
#import "RenameFileSheetController.h"
#import "RevertSheetController.h"
#import "ServerRepositoryRefSheetController.h"
#import "StripSheetController.h"
#import "UpdateSheetController.h"

#import "ResultsWindowController.h"

#import "MonitorFSEvents.h"
#import "SingleTimedQueue.h"
#import "TaskExecutions.h"
#import "PatchData.h"
#import "HunkExclusions.h"
//#import "LNCStopwatch.h"
#import <QuartzCore/CIFilter.h>





@interface MacHgDocument (PrivateAPI)
- (void) initializeRepositoryData;
- (void) populateOutlineContents;
- (void) validateViewSelector;
@end



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: My Document
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation MacHgDocument

@synthesize sidebar = sidebar_;
@synthesize mainWindow = mainWindow_;
@synthesize theProcessListController  = theProcessListController_;
@synthesize refreshBrowserSerialQueue = refreshBrowserSerialQueue_;
@synthesize mercurialTaskSerialQueue  = mercurialTaskSerialQueue_;
@synthesize events      = events_;
@synthesize connections = connections_;
@synthesize hunkExclusions = hunkExclusions_;
@synthesize toolbarSearchField = toolbarSearchField_;
@synthesize toolbarSearchFieldValue = toolbarSearchFieldValue_;
@synthesize toolbarSearchFieldCategory = toolbarSearchFieldCategory_;
@synthesize toolbarSearchFieldQueryIsValid = toolbarSearchFieldQueryIsValid_;
@synthesize toolbarSearchItem  = toolbarSearchItem_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: ForcedTesting
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) testBrowserLoad:(id)sender
{
	if ([self localRepoIsSelectedAndReady])
	{
		NSArray* absoluteChangedPaths = [self absolutePathOfRepositoryRootAsArray];
		[self refreshBrowserPaths:absoluteChangedPaths];
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Document Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self)
	{
		loadedDataProxy_ = nil;
		refreshBrowserSerialQueue_ = dispatch_queue_create("machg.refreshBrowserSerialQueue", NULL);
		mercurialTaskSerialQueue_  = dispatch_queue_create("machg.mercurialTaskSerialQueue", NULL);
		queueForUnderlyingRepositoryChangedViaEvents_ = [SingleTimedQueue SingleTimedQueueExecutingOn:mainQueue()  withTimeDelay:0.15  descriptiveName:@"queueForUnderlyingRepositoryChangedViaEvents"];
		events_ = [[MonitorFSEvents alloc]init];
		showingSheet_ = NO;
		eventsSuspensionCount_ = 0;
    }
    return self;
}

- (void) finalize
{
	[events_ stopWatchingPaths];
	dispatch_release(refreshBrowserSerialQueue_);
	dispatch_release(mercurialTaskSerialQueue_);
	[super finalize];
}


- (void) makeWindowControllers
{
	[super makeWindowControllers];
	MyWindowController* controller = [[MyWindowController alloc] initWithWindowNibName:@"MyDocument" owner:self];
	[self addWindowController:controller];
}


- (void) windowControllerDidLoadNib:(NSWindowController*) aController
{
    [super windowControllerDidLoadNib:aController];

	if (loadedDataProxy_)
	{
		[sidebar_ setRoot:[loadedDataProxy_->loadedSidebar root]];
		[sidebar_ reloadData];
		[sidebar_ restoreSavedExpandedness];
		[sidebar_ reloadData];
		connections_ = loadedDataProxy_->loadedConnections;
		hunkExclusions_ = loadedDataProxy_->loadedHunkExclusions;
	}
	else
		[self populateOutlineContents];

	if (!connections_)    connections_    = [[NSMutableDictionary alloc]init];
	if (!hunkExclusions_) hunkExclusions_ = [[HunkExclusions alloc]init];
	if ([hunkExclusions_ class] != [HunkExclusions class])
		hunkExclusions_ = [[HunkExclusions alloc]init];
	[self actionSwitchViewToBackingView:self];
}

- (void) LogNotification:(NSNotification*)aNotification
{
	DebugLog(@"received notification: %@", [aNotification name]);
}


- (void) awakeFromNib
{
	[self observe:kSidebarSelectionDidChange	from:self		  byCalling:@selector(validateViewSelector)];
	[self observe:kRepositoryRootChanged		from:self		  byCalling:@selector(repositoryRootDidChange)];
	[self observe:NSWindowDidMoveNotification	from:mainWindow_  byCalling:@selector(recordWindowFrameToDefaults)];
	[self observe:NSWindowDidResizeNotification	from:mainWindow_  byCalling:@selector(recordWindowFrameToDefaults)];
	[self observe:kRepositoryIdentityChanged	from:[AppController sharedAppController]  byCalling:@selector(saveDocumentIfNamed)];
	
	currentPane_ = -1;
	[informationAndActivityBox_ setContentView:informationBox_];
	[mainContentBox setWantsLayer:NO];		// We don't do cross fades since it speeds things up not to have the animation on. The
											// frames are still animated when going from one view to another.
	[[mainWindow_ windowController] setShouldCascadeWindows: NO];
	NSString* fileName = [self documentNameForAutosave];
	[sidebarAndInformation_ setAutosaveName:fstr(@"File:%@:LHSSidebarSplitPosition", fileName)];
	[mainSplitView setAutosaveName:fstr(@"File:%@:LHSMainSidebarSplitPosition", fileName)];

	// Set up search field and set size of NSMenuItems (I can't seem to find a way to do this through IB)
	toolbarSearchFieldCategory_ = eSearchByKeyword;
	toolbarSearchFieldValue_ = @"";
	toolbarSearchFieldQueryIsValid_ = YES;
	
	NSMenu* theSearchFieldMenu = [[[self toolbarSearchField] cell] searchMenuTemplate];
	[self setSearchCategory:[theSearchFieldMenu itemWithTag:eSearchByKeyword]];
	for (NSMenuItem* item in [theSearchFieldMenu itemArray])
		[item setAttributedTitle:normalSheetMessageAttributedString([item title])];
	
	[self validateViewSelector];

	// Test string matching.
	if (NO)
	{
		// test string matching. parsing the arguments of the following string should yield
		// ["--rev", "23", "--git", "--force", "--no-merges", "--remotecmd", "blargsplatter"]
		NSString* ex = @"--rev 23 --git --force --no-merges --remotecmd blargsplatter";
		NSArray* ans = [TaskExecutions parseArguments:ex];
		NSArray* res = [NSArray arrayWithObjects:@"--rev", @"23", @"--git", @"--force", @"--no-merges", @"--remotecmd", @"blargsplatter", nil];
		BOOL areEqual = YES;
		for (int i = 0; i < [res count]; i++)
			if (![[res objectAtIndex:i] isEqualToString:[ans objectAtIndex:i]])
				areEqual = NO;
		NSAssert(areEqual, @"string matching not working");
	}

}


- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)app
{
	return YES;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialize Controllers
// -----------------------------------------------------------------------------------------------------------------------------------------

- (FilesViewController*) theFilesViewController
{
	dispatch_once(&theFilesViewControllerInitilizer_, ^{
		theFilesViewController_ = [[FilesViewController alloc] initFilesViewControllerWithDocument:self]; });
	return theFilesViewController_;
}

- (HistoryViewController*) theHistoryViewController
{
	dispatch_once(&theHistoryViewControllerInitilizer_, ^{
		theHistoryViewController_ = [[HistoryViewController alloc] initHistoryViewControllerWithDocument:self]; });
	return theHistoryViewController_;
}

- (DifferencesViewController*) theDifferencesViewController
{
	dispatch_once(&theDifferencesViewControllerInitilizer_, ^{
		theDifferencesViewController_ = [[DifferencesViewController alloc] initDifferencesViewControllerWithDocument:self]; });
	return theDifferencesViewController_;
}

- (BackingViewController*) theBackingViewController
{
	dispatch_once(&theBackingViewControllerInitilizer_, ^{
		theBackingViewController_ = [[BackingViewController alloc] initBackingViewControllerWithDocument:self]; });
	return theBackingViewController_;
}


- (AddLabelSheetController*) theAddLabelSheetController
{
	dispatch_once(&theAddLabelSheetControllerInitilizer_, ^{
		theAddLabelSheetController_ = [[AddLabelSheetController alloc] initAddLabelSheetControllerWithDocument:self]; });
	return theAddLabelSheetController_;
}

- (BackoutSheetController*) theBackoutSheetController
{
	dispatch_once(&theBackoutSheetControllerInitilizer_, ^{
		theBackoutSheetController_ = [[BackoutSheetController alloc] initBackoutSheetControllerWithDocument:self]; });
	return theBackoutSheetController_;
}

- (CloneSheetController*) theCloneSheetController
{
	dispatch_once(&theCloneSheetControllerInitilizer_, ^{
		theCloneSheetController_ = [[CloneSheetController alloc] initCloneSheetControllerWithDocument:self]; });
	return theCloneSheetController_;
}

- (CollapseSheetController*) theCollapseSheetController
{
	dispatch_once(&theCollapseSheetControllerInitilizer_, ^{
		theCollapseSheetController_ = [[CollapseSheetController alloc] initCollapseSheetControllerWithDocument:self]; });
	return theCollapseSheetController_;
}

- (CommitSheetController*) theCommitSheetController
{
	dispatch_once(&theCommitSheetControllerInitilizer_, ^{
		theCommitSheetController_ = [[CommitSheetController alloc] initCommitSheetControllerWithDocument:self]; });
	return theCommitSheetController_;
}

- (ExportPatchesSheetController*) theExportPatchesSheetController
{
	dispatch_once(&theExportPatchesSheetControllerInitilizer_, ^{
		theExportPatchesSheetController_ = [[ExportPatchesSheetController alloc] initExportPatchesSheetControllerWithDocument:self]; });
	return theExportPatchesSheetController_;
}

- (HistoryEditSheetController*) theHistoryEditSheetController
{
	dispatch_once(&theHistoryEditSheetControllerInitilizer_, ^{
		theHistoryEditSheetController_ = [[HistoryEditSheetController alloc] initHistoryEditSheetControllerWithDocument:self]; });
	return theHistoryEditSheetController_;
}

- (ImportPatchesSheetController*) theImportPatchesSheetController
{
	dispatch_once(&theImportPatchesSheetControllerInitilizer_, ^{
		theImportPatchesSheetController_ = [[ImportPatchesSheetController alloc] initImportPatchesSheetControllerWithDocument:self]; });
	return theImportPatchesSheetController_;
}

- (IncomingSheetController*) theIncomingSheetController
{
	dispatch_once(&theIncomingSheetControllerInitilizer_, ^{
		theIncomingSheetController_ = [[IncomingSheetController alloc] initIncomingSheetControllerWithDocument:self]; });
	return theIncomingSheetController_;
}

- (LocalRepositoryRefSheetController*) theLocalRepositoryRefSheetController
{
	dispatch_once(&theLocalRepositoryRefSheetControllerInitilizer_, ^{
		theLocalRepositoryRefSheetController_ = [[LocalRepositoryRefSheetController alloc] initLocalRepositoryRefSheetControllerWithDocument:self]; });
	return theLocalRepositoryRefSheetController_;
}

- (MergeSheetController*) theMergeSheetController
{
	dispatch_once(&theMergeSheetControllerInitilizer_, ^{
		theMergeSheetController_ = [[MergeSheetController alloc] initMergeSheetControllerWithDocument:self]; });
	return theMergeSheetController_;
}

- (MoveLabelSheetController*) theMoveLabelSheetController
{
	dispatch_once(&theMoveLabelSheetControllerInitilizer_, ^{
		theMoveLabelSheetController_ = [[MoveLabelSheetController alloc] initMoveLabelSheetControllerWithDocument:self]; });
	return theMoveLabelSheetController_;
}

- (OutgoingSheetController*) theOutgoingSheetController
{
	dispatch_once(&theOutgoingSheetControllerInitilizer_, ^{
		theOutgoingSheetController_ = [[OutgoingSheetController alloc] initOutgoingSheetControllerWithDocument:self]; });
	return theOutgoingSheetController_;
}

- (PullSheetController*) thePullSheetController
{
	dispatch_once(&thePullSheetControllerInitilizer_, ^{
		thePullSheetController_ = [[PullSheetController alloc] initPullSheetControllerWithDocument:self]; });
	return thePullSheetController_;
}

- (PushSheetController*) thePushSheetController
{
	dispatch_once(&thePushSheetControllerInitilizer_, ^{
		thePushSheetController_ = [[PushSheetController alloc] initPushSheetControllerWithDocument:self]; });
	return thePushSheetController_;
}

- (RebaseSheetController*) theRebaseSheetController
{
	dispatch_once(&theRebaseSheetControllerInitilizer_, ^{
		theRebaseSheetController_ = [[RebaseSheetController alloc] initRebaseSheetControllerWithDocument:self]; });
	return theRebaseSheetController_;
}

- (RenameFileSheetController*) theRenameFileSheetController
{
	dispatch_once(&theRenameFileSheetControllerInitilizer_, ^{
		theRenameFileSheetController_ = [[RenameFileSheetController alloc] initRenameFileSheetControllerWithDocument:self]; });
	return theRenameFileSheetController_;
}

- (RevertSheetController*) theRevertSheetController
{
	dispatch_once(&theRevertSheetControllerInitilizer_, ^{
		theRevertSheetController_ = [[RevertSheetController alloc] initRevertSheetControllerWithDocument:self]; });
	return theRevertSheetController_;
}

- (ServerRepositoryRefSheetController*) theServerRepositoryRefSheetController
{
	dispatch_once(&theServerRepositoryRefSheetControllerInitilizer_, ^{
		theServerRepositoryRefSheetController_ = [[ServerRepositoryRefSheetController alloc] initServerRepositoryRefSheetControllerWithDocument:self]; });
	return theServerRepositoryRefSheetController_;
}

- (StripSheetController*) theStripSheetController
{
	dispatch_once(&theStripSheetControllerInitilizer_, ^{
		theStripSheetController_ = [[StripSheetController alloc] initStripSheetControllerWithDocument:self]; });
	return theStripSheetController_;
}

- (UpdateSheetController*) theUpdateSheetController
{
	dispatch_once(&theUpdateSheetControllerInitilizer_, ^{
		theUpdateSheetController_ = [[UpdateSheetController alloc] initUpdateSheetControllerWithDocument:self]; });
	return theUpdateSheetController_;
}


- (void) unloadFilesView
{
	[theFilesViewController_ unload];
	theFilesViewController_ = nil;
}

- (void) unloadHistoryView
{
	[theHistoryViewController_ unload];
	theHistoryViewController_ = nil;
}

- (void) unloadDifferencesView
{
	[theDifferencesViewController_ unload];
	theDifferencesViewController_ = nil;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  The Views
// -----------------------------------------------------------------------------------------------------------------------------------------

- (FilesView*)			theFilesView		{ return [[self theFilesViewController] theFilesView]; }
- (HistoryView*)		theHistoryView		{ return [[self theHistoryViewController] theHistoryView]; }
- (DifferencesView*)	theDifferencesView	{ return [[self theDifferencesViewController] theDifferencesView]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Document Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*)	documentNameForAutosave
{
	NSString* fileName = [[[self fileURL] path] lastPathComponent];
	return fileName ? fileName : @"UntitledDocument";
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Window Frame AutoSaving
// -----------------------------------------------------------------------------------------------------------------------------------------

// We need our own mechanisms here for window position autosaving instead of the normal Cocoa's because we need to save the sized
// of all of our panes, not just the main window.

- (void) recordWindowFrameToDefaults
{
	NSString* fileName = [self documentNameForAutosave];
	NSString* originKeyForAutoSave = fstr(@"File:%@:originPos", fileName);
	NSString* rectKeyForAutoSave   = fstr(@"File:%@:windowPosForView", fileName);
	NSRect frm = [mainWindow_ frame];
	NSString* topLeftOriginString = NSStringFromPoint(NSMakePoint(NSMinX(frm), NSMaxY(frm)));	// Record window origin top left
	NSString* rectString = NSStringFromRect(frm);
	[[NSUserDefaults standardUserDefaults] setObject:topLeftOriginString forKey:originKeyForAutoSave];
	[[NSUserDefaults standardUserDefaults] setObject:rectString forKey:rectKeyForAutoSave];
}

- (NSRect) getWindowFrameFromDefaults
{
	NSString* fileName = [self documentNameForAutosave];
	NSString* originKeyForAutoSave = fstr(@"File:%@:originPos", fileName);
	NSString* rectKeyForAutoSave   = fstr(@"File:%@:windowPosForView", fileName);
	NSString* topLeftOriginString  = [[NSUserDefaults standardUserDefaults] objectForKey:originKeyForAutoSave];
	NSString* rectString           = [[NSUserDefaults standardUserDefaults] objectForKey:rectKeyForAutoSave];
	if (!topLeftOriginString || !rectString)
		return NSZeroRect;
	NSPoint topLeftOrigin = NSPointFromString(topLeftOriginString);	// This is the window top left
	NSRect rect = NSRectFromString(rectString);
	rect.origin.x = topLeftOrigin.x;
	rect.origin.y = topLeftOrigin.y - rect.size.height;
	return rect;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Pane switching
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSView <NSUserInterfaceValidations>*) paneView:(PaneViewNum)paneNum
{
	switch (paneNum)
	{
		case eFilesView:		return [self theFilesView];
		case eHistoryView:		return [self theHistoryView];
		case eDifferencesView:	return [self theDifferencesView];
		case eBackingView:		return [[self theBackingViewController] view];
		default:				return nil;
	}
}


//Based on the new content view frame, calculate the window's new frame
- (NSRect) newWindowFrameWhenSwitchingContentTo:(NSRect)newContentFrame
{
	NSRect rectFromDefaults = [self getWindowFrameFromDefaults];
	if (!NSEqualRects(rectFromDefaults,NSZeroRect))
		return rectFromDefaults;

	NSRect oldWindowFrame  = [mainWindow_ frame];
	NSRect oldContentFrame = [mainContentBox frame];
	NSRect newWindowFrame  = oldWindowFrame;
	newWindowFrame.size.height += (newContentFrame.size.height - oldContentFrame.size.height);
	newWindowFrame.size.width  += (newContentFrame.size.width  - oldContentFrame.size.width);
	newWindowFrame.origin.y    -= (newContentFrame.size.height - oldContentFrame.size.height);
	return newWindowFrame;
}


// This sets the search field into a disabled state when not enabled and when enabled sets the enabled state, visually enables it,
// and restores the search term and label.
- (void) setSearchFieldEnabled:(BOOL)enabled value:(NSString*)value caption:(NSString*)caption
{
	[toolbarSearchField_ setStringValue:enabled ? nonNil(value) : @""];
	[toolbarSearchItem_	 setLabel: (enabled && IsNotEmpty(value)) ? caption : @"Search"];
	[toolbarSearchField_ setEnabled:enabled];
	[toolbarSearchItem_  setEnabled:enabled];
}

- (void) syncronizeSearchFieldTint
{
	if ([self currentPane] != eHistoryView)
	{
		CIFilter* grayFilter = [CIFilter filterWithName:@"CIWhitePointAdjust" keysAndValues:@"inputColor", [CIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.6], nil];
		[[toolbarSearchField_ layer] setFilters: [NSArray arrayWithObject:grayFilter]];
		return;
	}
	if (!toolbarSearchFieldQueryIsValid_ && IsNotEmpty(toolbarSearchFieldValue_))
	{
		CIFilter* pinkErrorFilter = [CIFilter filterWithName:@"CIWhitePointAdjust" keysAndValues:@"inputColor", [CIColor colorWithRed:0.9 green:0.6 blue:0.6 alpha:0.6], nil];
		[[toolbarSearchField_ layer] setFilters: [NSArray arrayWithObject:pinkErrorFilter]];
		return;
	}

	[[toolbarSearchField_ layer] setFilters: [NSArray array]];
}

- (NSView <NSUserInterfaceValidations>*) currentPaneView	{ return [self paneView:currentPane_]; }
- (PaneViewNum) currentPane									{ return currentPane_; }
- (void) setCurrentPane:(PaneViewNum)newPaneNum
{
	if (currentPane_ == newPaneNum)
		return;

	if ((newPaneNum != eBackingView) && ![self localRepoIsSelectedAndReady])
	{
		[self setCurrentPane:eBackingView];
		return;
	}

	if (newPaneNum != eBackingView)
	{
		BOOL ended = [mainWindow_ makeFirstResponder:mainWindow_];
		if (!ended)
			{ PlayBeep(); return; }
	}
	
	// Specific opening handling for some panes
	switch (newPaneNum)
	{
		case eFilesView:			[[self theFilesView] prepareToOpenFilesView];				break;
		case eHistoryView:			[[self theHistoryView] prepareToOpenHistoryView];			break;
		case eDifferencesView:		[[self theDifferencesView] prepareToOpenDifferencesView];	break;
		default:																				break;
	}	
	
	currentPane_ = newPaneNum;

	NSString* searchTerm    = toolbarSearchFieldValue_;
	NSString* searchCaption = theHistoryViewController_ ? [[self theHistoryView] searchCaption] : @"Search";
	[self setSearchFieldEnabled:(newPaneNum == eHistoryView) value:searchTerm caption:searchCaption];
	[self syncronizeSearchFieldTint];

	NSView* newView = [self paneView:newPaneNum];
	NSRect newFrame = [self newWindowFrameWhenSwitchingContentTo:[newView frame]];	// Figure out new frame size
	
	[mainContentBox setContentView:newView];
	[mainWindow_ setFrame:newFrame display:YES];

	// After the pane switch the selected rows in the logtables might actually be out of visible range due to the resizing of the
	// frame. Thus after the switch make sure you can see the current selection. Also once the target pane has been set to the
	// correct size we can restore and split view positions. 
	switch (newPaneNum)
	{
		case eFilesView:		[[self theFilesView]       restoreConcertinaSplitViewPositions];
								[[self theFilesView]       updateFilesViewButtonSelector];			break;
        case eHistoryView:      [[self theHistoryView]     restoreConcertinaSplitViewPositions];
								[[self theHistoryView]     scrollToSelected];						break;
        case eDifferencesView:  [[self theDifferencesView] restoreDifferencesSplitViewPositions];
								[[self theDifferencesView] scrollToSelected];						break;
        default:                break;
	}

	[self recordWindowFrameToDefaults];
	if ([self quicklookPreviewIsVisible])
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)	showingFilesView								{ return currentPane_ == eFilesView; }
- (BOOL)	showingHistoryView								{ return currentPane_ == eHistoryView; }
- (BOOL)	showingDifferencesView							{ return currentPane_ == eDifferencesView; }
- (BOOL)	showingBackingView								{ return currentPane_ == eBackingView; }
- (BOOL)	showingFilesOrHistoryView						{ return currentPane_ == eFilesView || currentPane_ == eHistoryView; }
- (BOOL)	showingFilesOrDifferencesView					{ return currentPane_ == eFilesView || currentPane_ == eDifferencesView; }
- (BOOL)	showingFilesOrHistoryOrDifferencesView			{ return currentPane_ == eFilesView || currentPane_ == eHistoryView || currentPane_ == eDifferencesView; }
- (BOOL)	showingASheet									{ return showingSheet_; }


- (IBAction) actionSwitchViewToFilesView:(id)sender			{ [self setCurrentPane:eFilesView]; }
- (IBAction) actionSwitchViewToBackingView:(id)sender		{ [self setCurrentPane:eBackingView]; }
- (IBAction) actionSwitchViewToDifferencesView:(id)sender	{ [self setCurrentPane:eDifferencesView]; }
- (IBAction) actionSwitchViewToHistoryView:(id)sender		{ [self setCurrentPane:eHistoryView]; }
- (IBAction) actionSwitchViewToFilesBrowserView:(id)sender	{ [self setCurrentPane:eFilesView]; [[[self theFilesView] theFSViewer] actionSwitchToFilesBrowser:sender]; }
- (IBAction) actionSwitchViewToFilesOutlineView:(id)sender	{ [self setCurrentPane:eFilesView]; [[[self theFilesView] theFSViewer] actionSwitchToFilesOutline:sender]; }
- (IBAction) actionSwitchViewToFilesTableView:(id)sender	{ [self setCurrentPane:eFilesView]; [[[self theFilesView] theFSViewer] actionSwitchToFilesTable:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: SplitView handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) populateOutlineContents
{
	SidebarNode* root         = [SidebarNode sectionNodeWithCaption:@"ROOT"];	// This isn't shown its the children of this which are shown.
	SidebarNode* repositories = [SidebarNode sectionNodeWithCaption:@"REPOSITORIES"];
	[root addChild:repositories];
	[sidebar_ setRoot:root];
	
	//	[sidebar_ expandItem:other];
	[sidebar_ reloadData];
	[sidebar_ expandAll];
	[sidebar_ reloadData];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Window Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) windowWillBeginSheet:(NSNotification*)notification	{ showingSheet_ = YES; }
- (void) windowDidEndSheet:(NSNotification*)notification	{ showingSheet_ = NO;  }
- (void) windowDidBecomeMain:(NSNotification*)notification	{ [sidebar_ becomeMain]; }
- (void) windowDidResignMain:(NSNotification*)notification	{ [sidebar_ resignMain]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quick Look Panel Support
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) acceptsPreviewPanelControl:(QLPreviewPanel*)panel	{ return YES; }

- (void) beginPreviewPanelControl:(QLPreviewPanel*)panel
{
    // This document is now responsible for the quick look preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    panel.delegate = self;
    panel.dataSource = self;
}

- (void) endPreviewPanelControl:(QLPreviewPanel*)panel
{
    // This document loses its responsibility for the quick look preview panel, until the next call to
    // -beginPreviewPanelControl: it must not change the panel's delegate, data source or refresh it.
    quickLookPreviewPanel = nil;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quick Look Panel Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) quicklookPreviewIsVisible
{
	return [QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible];
}

- (NSInteger) numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel*)panel
{
	NSView* currentPaneView = [self currentPaneView];
	if ([currentPaneView respondsToSelector:@selector(numberOfQuickLookPreviewItems)])
		return [(id)currentPaneView numberOfQuickLookPreviewItems];
	return 0;
}

- (id <QLPreviewItem>) previewPanel:(QLPreviewPanel*)panel previewItemAtIndex:(NSInteger)index
{
	NSView* currentPaneView = [self currentPaneView];
	if ([currentPaneView respondsToSelector:@selector(quickLookPreviewItems)])
	{
		NSArray* items = [currentPaneView performSelector:@selector(quickLookPreviewItems)];
		if ([items count] > index)
			return [items objectAtIndex:index];
	}
	return nil;
}

- (BOOL) previewPanel:(QLPreviewPanel*)panel handleEvent:(NSEvent*)event
{
    // redirect all key down events to the files view
    if ([event type] == NSKeyDown)
	{
        [[self theFSViewer] keyDown:event];
        return YES;
    }
    return NO;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect) previewPanel:(QLPreviewPanel*)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
	PathQuickLookPreviewItem* previewItem = DynamicCast(PathQuickLookPreviewItem, item);
	return previewItem ? [previewItem frameRectOfPath] : NSZeroRect;
}

- (IBAction) togglePreviewPanel:(id)previewPanel
{
    if ([self quicklookPreviewIsVisible])
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
	else
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Search Field Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

// Called when the user chooses to search on keyword, revset, or revisionID
- (IBAction)	setSearchCategory:(id)sender
{
	NSMenuItem* theChoosenMenuItem = DynamicCast(NSMenuItem, sender);
	if (!theChoosenMenuItem)
		return;
	NSSearchFieldCell* searchCell = [[self toolbarSearchField] cell];
	NSMenu* searchFieldMenu = [searchCell searchMenuTemplate];
	[[searchFieldMenu itemWithTag:toolbarSearchFieldCategory_] setState:NSOffState];
	toolbarSearchFieldCategory_ = [theChoosenMenuItem tag];
	[[searchFieldMenu itemWithTag:toolbarSearchFieldCategory_] setState:NSOnState];
	[searchCell setSearchMenuTemplate:searchFieldMenu];
	[[self toolbarSearchField] setStringValue:@""];
	[self searchFieldChanged:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Action Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) localRepoIsSelectedAndReady						{ return !showingSheet_ && [sidebar_ localRepoIsSelected]; }
- (BOOL) localRepoIsChosenAndReady							{ return !showingSheet_ && [sidebar_ localRepoIsChosen]; }
- (BOOL) localOrServerRepoIsSelectedAndReady				{ return !showingSheet_ && [sidebar_ localOrServerRepoIsSelected]; }
- (BOOL) localOrServerRepoIsChosenAndReady					{ return !showingSheet_ && [sidebar_ localOrServerRepoIsChosen]; }
- (BOOL) toolbarActionAppliesToFilesWith:(HGStatus)status	{ return ([self statusOfChosenPathsInFilesContain:status] || (![self nodesAreChosenInFiles] && [self repositoryHasFilesWhichContainStatus:status])); }

- (BOOL) validateAndSwitchMenuForCommitAllFiles:(id)anItem
{
	NSMenuItem* menuItem = DynamicCast(NSMenuItem, anItem);
	[menuItem setTitle:([[self repositoryData] inMergeState] ? @"Commit Merged Files…" : @"Commit All Files…")];
	return [self repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
}
- (BOOL) validateAndSwitchMenuForPreviewSelectedFiles:(id)anItem
{
	NSMenuItem* menuItem = DynamicCast(NSMenuItem, anItem);
	if (menuItem)
		[menuItem setTitle: [self quicklookPreviewIsVisible] ? @"Close Quick Look panel" : @"Open Quick Look panel"];
	return [self localRepoIsSelectedAndReady] &&
			(([self showingFilesView]       && [[[self theFilesView]       theFSViewer] nodesAreChosen]) ||
			 ([self showingDifferencesView] && [[[self theDifferencesView] theFSViewer] nodesAreChosen]) ||
			 ([self showingHistoryView]     && [[[self theHistoryView]   logTableView] revisionsAreSelected]));
}
- (BOOL) validateAndSwitchMenuForRemoveSidebarItems:(id)anItem
{
	NSMenuItem* menuItem = DynamicCast(NSMenuItem, anItem);
	[menuItem setTitle:[sidebar_ menuTitleForRemoveSidebarItems]];
	return !showingSheet_ && [sidebar_ chosenNode];
}


- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem, NSObject>)anItem
{
	SEL theAction = [anItem action];
	
	if (theAction == @selector(actionSwitchViewToFilesView:))			return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(actionSwitchViewToHistoryView:))			return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(actionSwitchViewToDifferencesView:))		return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(actionSwitchViewToFilesBrowserView:))	return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(actionSwitchViewToFilesOutlineView:))	return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(actionSwitchViewToFilesTableView:))		return [self localRepoIsSelectedAndReady];

	// Action Menu
	// -----------
	if (theAction == @selector(mainMenuCommitSelectedFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuCommitAllFiles:))				return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(toolbarCommitFiles:))					return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuDiffSelectedFiles:))				return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuDiffAllFiles:))					return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(toolbarDiffFiles:))						return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuAddRenameRemoveSelectedFiles:))	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuAddRenameRemoveAllFiles:))		return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(toolbarAddRenameRemoveFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	// ------	
	if (theAction == @selector(mainMenuRevertSelectedFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuRevertSelectedFilesToVersion:))	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuRevertAllFiles:))				return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(toolbarRevertFiles:))					return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuDeleteSelectedFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuAddSelectedFiles:))				return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuUntrackSelectedFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuRenameSelectedItem:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	// ------
	if (theAction == @selector(mainMenuRemergeSelectedFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuMarkResolvedSelectedFiles:))		return [[self currentPaneView] validateUserInterfaceItem:anItem];
	// ------
	if (theAction == @selector(mainMenuIgnoreSelectedFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuUnignoreSelectedFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuAnnotateSelectedFiles:))			return [[self currentPaneView] validateUserInterfaceItem:anItem];
	// ------	
	if (theAction == @selector(mainMenuRollbackCommit:))				return [[self currentPaneView] validateUserInterfaceItem:anItem];
	
	
	// Repository Menu
	// ---------------
	if (theAction == @selector(mainMenuCloneRepository:))				return [self localOrServerRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuPushToRepository:))				return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuPullFromRepository:))			return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuIncomingFromRepository:))		return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuOutgoingToRepository:))			return [self localRepoIsSelectedAndReady];
	// ------
	if (theAction == @selector(mainMenuUpdateRepository:))				return [self localRepoIsSelectedAndReady] && [self showingFilesOrHistoryView];
	if (theAction == @selector(mainMenuUpdateRepositoryToVersion:))		return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(toolbarUpdate:))							return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuGotoChangeset:))					return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuMergeWith:))						return [self localRepoIsSelectedAndReady] && [self showingFilesOrHistoryView] && [[self repositoryData]hasMultipleOpenHeads] && ![self repositoryHasFilesWhichContainStatus:eHGStatusSecondary];
	// ------
	if (theAction == @selector(mainMenuCollapseChangesets:))		 	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuHistoryEditChangesets:))		 	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuStripChangesets:))			 	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuRebaseChangesets:))			 	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(mainMenuBackoutChangeset:))			 	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	// ------
	if (theAction == @selector(mainMenuManifestOfCurrentVersion:))		return [self localRepoIsSelectedAndReady] && [self showingFilesOrHistoryView];
	if (theAction == @selector(mainMenuAddLabelToCurrentRevision:))		return [self localRepoIsSelectedAndReady] && [self showingFilesOrHistoryView];	
	// ------
	if (theAction == @selector(mainMenuAddLocalRepositoryRef:))			return !showingSheet_;
	if (theAction == @selector(mainMenuAddServerRepositoryRef:))		return !showingSheet_;
	if (theAction == @selector(mainMenuAddNewSidebarGroupItem:))		return !showingSheet_;
	if (theAction == @selector(mainMenuRemoveSidebarItems:))			return [self validateAndSwitchMenuForRemoveSidebarItems:anItem];
	if (theAction == @selector(mainMenuConfigureRepositoryRef:))		return [self localOrServerRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuConfigureLocalRepositoryRef:))	return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuConfigureServerRepositoryRef:))	return [self localOrServerRepoIsSelectedAndReady];
	// ------
	if (theAction == @selector(mainMenuRevealRepositoryInFinder:))		return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuOpenTerminalHere:))				return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(actionTestListingItem:))					return !showingSheet_ && ([sidebar_ selectedNode] ? YES : NO);

	
	if (theAction == @selector(mainMenuOpenSelectedFilesInFinder:))		return [self localRepoIsSelectedAndReady] && [self nodesAreChosenInFiles];
	if (theAction == @selector(mainMenuRevealSelectedFilesInFinder:))	return [self localRepoIsSelectedAndReady];
	
	
	if (theAction == @selector(historyMenuViewRevisionDifferences:)) 	return [[self currentPaneView] validateUserInterfaceItem:anItem];

	
	// Labels contextual items                                       
	if (theAction == @selector(labelsMenuAddLabelToCurrentRevision:))	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(labelsMenuMoveChosenLabel:))			 	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	if (theAction == @selector(labelsMenuRemoveChosenLabel:))		 	return [[self currentPaneView] validateUserInterfaceItem:anItem];
	// -------                                                       
	if (theAction == @selector(labelsMenuUpdateRepositoryToChosenRevision:))	return [[self currentPaneView] validateUserInterfaceItem:anItem];



	
	// Files Contextual Menu
	if (theAction == @selector(viewerMenuOpenSelectedFilesInFinder:))	return [self localRepoIsSelectedAndReady] && [self nodesAreChosenInFiles];
	if (theAction == @selector(browserMenuRevealSelectedFilesInFinder:))return [self localRepoIsSelectedAndReady];
	if (theAction == @selector(browserMenuOpenTerminalHere:))			return [self localRepoIsSelectedAndReady];
	// -------                                                       
	if (theAction == @selector(mainMenuImportPatches:))					return [self localRepoIsSelectedAndReady] && [self showingFilesOrHistoryView];
	if (theAction == @selector(mainMenuExportPatches:))					return [self localRepoIsSelectedAndReady] && [self showingFilesOrHistoryView];

	
	if (theAction == @selector(mainMenuNoAction:))						return !showingSheet_ && ([sidebar_ selectedNode] ? YES : NO);
	if (theAction == @selector(togglePreviewPanel:))					return [self validateAndSwitchMenuForPreviewSelectedFiles:anItem];
	

	// Miscellaneous actions
	if (theAction == @selector(differencesDisplayPreferencesChanged:))	return YES;

	// subclass of NSDocument, so invoke super's implementation
	return [super validateUserInterfaceItem:anItem];
}


- (IBAction)	mainMenuOpenSelectedFilesInFinder:(id)sender	{ [[self currentPaneView] performSelectorIfPossible:@selector(mainMenuOpenSelectedFilesInFinder:) withObject:sender]; }




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Action Menu
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuCommitSelectedFiles:(id)sender				{ [[self theCommitSheetController] openCommitSheetWithSelectedFiles:sender]; }
- (IBAction) mainMenuCommitAllFiles:(id)sender					{ [[self theCommitSheetController] openCommitSheetWithAllFiles:sender]; }
- (IBAction) mainMenuDiffSelectedFiles:(id)sender				{ [self viewDifferencesInCurrentRevisionFor:[self absolutePathsOfChosenFiles] toRevision:nil]; }	// nil indicates the current revision
- (IBAction) mainMenuDiffAllFiles:(id)sender					{ [self viewDifferencesInCurrentRevisionFor:[self absolutePathOfRepositoryRootAsArray] toRevision:nil]; }	// nil indicates the current revision
- (IBAction) mainMenuAddRenameRemoveSelectedFiles:(id)sender	{ [self primaryActionAddRenameRemoveFiles:[self absolutePathsOfChosenFiles]]; }
- (IBAction) mainMenuAddRenameRemoveAllFiles:(id)sender			{ [self primaryActionAddRenameRemoveFiles:[self absolutePathOfRepositoryRootAsArray]]; }

- (IBAction) mainMenuRevertSelectedFiles:(id)sender				{ [self primaryActionRevertFiles:[self absolutePathsOfChosenFiles] toVersion:nil]; }
- (IBAction) mainMenuRevertAllFiles:(id)sender					{ [self primaryActionRevertFiles:[self absolutePathOfRepositoryRootAsArray] toVersion:nil]; }
- (IBAction) mainMenuRevertSelectedFilesToVersion:(id)sender	{ [[self theRevertSheetController] openRevertSheetWithSelectedFiles:sender]; }
- (IBAction) mainMenuDeleteSelectedFiles:(id)sender				{ [self primaryActionDeleteSelectedFiles:[self absolutePathsOfChosenFiles]]; }
- (IBAction) mainMenuAddSelectedFiles:(id)sender				{ [self primaryActionAddSelectedFiles:[self absolutePathsOfChosenFiles]]; }
- (IBAction) mainMenuUntrackSelectedFiles:(id)sender			{ [self primaryActionUntrackSelectedFiles:[self absolutePathsOfChosenFiles]]; }
- (IBAction) mainMenuRenameSelectedItem:(id)sender				{ [[self theRenameFileSheetController] openRenameFileSheet:sender]; }

- (IBAction) mainMenuRemergeSelectedFiles:(id)sender			{ [self primaryActionRemerge:[self absolutePathsOfChosenFiles] withConfirmation:YES]; }
- (IBAction) mainMenuMarkResolvedSelectedFiles:(id)sender		{ [self primaryActionMarkResolved:[self absolutePathsOfChosenFiles] withConfirmation:NO]; }

- (IBAction) mainMenuIgnoreSelectedFiles:(id)sender				{ [self primaryActionIgnoreSelectedFiles:[self absolutePathsOfChosenFiles]]; }
- (IBAction) mainMenuUnignoreSelectedFiles:(id)sender			{ [self primaryActionUnignoreSelectedFiles:[self absolutePathsOfChosenFiles]]; }
- (IBAction) mainMenuAnnotateSelectedFiles:(id)sender			{ [self primaryActionAnnotateSelectedFiles:[self absolutePathsOfChosenFiles]]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Toolbar Actions
// -----------------------------------------------------------------------------------------------------------------------------------------


- (IBAction) toolbarCommitFiles:(id)sender
{
	if ([[self theFSViewer] nodesAreChosen] && ![[self repositoryData] inMergeState])
		[self mainMenuCommitSelectedFiles:sender];
	else
		[self mainMenuCommitAllFiles:sender];
}

- (IBAction) toolbarDiffFiles:(id)sender
{
	if ([[self theFSViewer] nodesAreChosen])
		[self mainMenuDiffSelectedFiles:sender];
	else
		[self mainMenuDiffAllFiles:sender];
}

- (IBAction) toolbarAddRenameRemoveFiles:(id)sender
{
	if ([[self theFSViewer] nodesAreChosen])
		[self mainMenuAddRenameRemoveSelectedFiles:sender];
	else
		[self mainMenuAddRenameRemoveAllFiles:sender];
}

- (IBAction) toolbarRevertFiles:(id)sender
{
	if ([[self theFSViewer] nodesAreChosen])
		[self mainMenuRevertSelectedFilesToVersion:sender];
	else
		[self mainMenuRevertAllFiles:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  File Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuImportPatches:(id)sender				{ [[self theImportPatchesSheetController] openImportPatchesSheet:sender]; }
- (IBAction) mainMenuExportPatches:(id)sender				{ [[self theExportPatchesSheetController] openExportPatchesSheetWithSelectedRevisions:sender]; }




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: History Altering Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuCollapseChangesets:(id)sender			{ [[self theCollapseSheetController]	openCollapseSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuHistoryEditChangesets:(id)sender		{ [[self theHistoryEditSheetController]	openHistoryEditSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuStripChangesets:(id)sender				{ [[self theStripSheetController]		openStripSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuRebaseChangesets:(id)sender			{ [[self theRebaseSheetController]		openRebaseSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuBackoutChangeset:(id)sender			{ [[self theBackoutSheetController]		openBackoutSheetWithSelectedRevision:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Repository Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuManifestOfCurrentVersion:(id)sender	{ [self primaryActionDisplayManifestForVersion:[self getHGParent1Revision]]; }
- (IBAction) mainMenuPushToRepository:(id)sender			{ [[self thePushSheetController]		openSheet:sender]; }
- (IBAction) mainMenuPullFromRepository:(id)sender			{ [[self thePullSheetController]		openSheet:sender]; }
- (IBAction) mainMenuIncomingFromRepository:(id)sender		{ [[self theIncomingSheetController]	openSheet:sender]; }
- (IBAction) mainMenuOutgoingToRepository:(id)sender		{ [[self theOutgoingSheetController]	openSheet:sender]; }

- (IBAction) mainMenuCloneRepository:(id)sender
{
	SidebarNode* node = [sidebar_ chosenNode];
	if (!node)
		return;
	
	[[self theCloneSheetController] openCloneSheetWithSource:node];
}

- (IBAction) mainMenuGotoChangeset:(id)sender
{
	if (![self localRepoIsSelectedAndReady])
		return;
	if (![self showingHistoryView])
		[self actionSwitchViewToHistoryView:sender];
	[[self theHistoryView] historyMenuGotoChangeset:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: All Files Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuUpdateRepository:(id)sender				{ [self primaryActionUpdateFilesToVersion:[self getHGTipRevision] withCleanOption:NO]; }
- (IBAction) mainMenuUpdateRepositoryToVersion:(id)sender		{ [[self theUpdateSheetController] openUpdateSheetWithSelectedRevision:sender]; }
- (IBAction) toolbarUpdate:(id)sender							{ [[self theUpdateSheetController] openUpdateSheetWithSelectedRevision:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Merging
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuMergeWith:(id)sender						{ [[self theMergeSheetController] openMergeSheet:sender]; }
- (IBAction) mainMenuAddLabelToCurrentRevision:(id)sender		{ [[self theAddLabelSheetController] openAddLabelSheet:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Proxies for SideBar Methods
// -----------------------------------------------------------------------------------------------------------------------------------------


- (IBAction) mainMenuAddLocalRepositoryRef:(id)sender			{ [[self  theLocalRepositoryRefSheetController]	openSheetForNewRepositoryRef]; }
- (IBAction) mainMenuAddServerRepositoryRef:(id)sender			{ [[self theServerRepositoryRefSheetController]	openSheetForNewRepositoryRef]; }
- (IBAction) mainMenuConfigureLocalRepositoryRef:(id)sender		{ [[self  theLocalRepositoryRefSheetController]	openSheetForConfigureRepositoryRef:[sidebar_ chosenNode]]; }
- (IBAction) mainMenuConfigureServerRepositoryRef:(id)sender	{ [[self theServerRepositoryRefSheetController]	openSheetForConfigureRepositoryRef:[sidebar_ chosenNode]]; }

- (IBAction) mainMenuConfigureRepositoryRef:(id)sender			{ return [sidebar_ mainMenuConfigureRepositoryRef:sender]; }
- (IBAction) mainMenuAddNewSidebarGroupItem:(id)sender			{ return [sidebar_ mainMenuAddNewSidebarGroupItem:sender]; }
- (IBAction) mainMenuRemoveSidebarItems:(id)sender				{ return [sidebar_ mainMenuRemoveSidebarItems:sender]; }
- (IBAction) mainMenuRevealRepositoryInFinder:(id)sender		{ return [sidebar_ mainMenuRevealRepositoryInFinder:sender]; }
- (IBAction) mainMenuRevealSelectedFilesInFinder:(id)sender		{ return [sidebar_ mainMenuRevealRepositoryInFinder:sender]; }
- (IBAction) mainMenuOpenTerminalHere:(id)sender				{ return [sidebar_ mainMenuOpenTerminalHere:sender]; }
- (IBAction) mainMenuAddAndCloneServerRepositoryRef:(id)sender	{ [[self theServerRepositoryRefSheetController] openSheetForAddAndClone]; }







// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Saving & Loading
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSData*) dataOfType:(NSString*)typeName error:(NSError**)outError
{
	[mainWindow_ endEditingFor:nil];								// End editing

    NSMutableData* data = [[NSMutableData alloc] init];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
    [archiver setOutputFormat: NSPropertyListBinaryFormat_v1_0];
	
    [archiver encodeObject:sidebar_ forKey: @"sidebar"];
	[archiver encodeObject:connections_ forKey:@"connections"];
	[archiver encodeObject:hunkExclusions_ forKey:@"hunkExclusions"];
    [archiver encodeInt:currentPane_ forKey:@"currentPane"];

    [archiver finishEncoding];
	
	// There are no errors for now
	if (outError)
		*outError = nil;
    
	return data;


}



- (BOOL) readFromData:(NSData*)data ofType:(NSString*)typeName error:(NSError**)outError
{
	DebugLog(@"About to read data of type %@", typeName);
	loadedDataProxy_ = [[LoadedInitializationData alloc] init];
	@try
	{
		NSKeyedUnarchiver* archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: data];

		loadedDataProxy_->loadedSidebar			= [archiver decodeObjectForKey:@"sidebar"];
		loadedDataProxy_->loadedConnections		= [archiver decodeObjectForKey:@"connections"];
		loadedDataProxy_->loadedCurrentPane		= [archiver decodeIntForKey:@"currentPane"];
		@try {
			loadedDataProxy_->loadedHunkExclusions	= [archiver decodeObjectForKey:@"hunkExclusions"];		
		}
		@catch (NSException * e) {
			loadedDataProxy_->loadedHunkExclusions = [[HunkExclusions alloc]init];
		}
		
		if (!loadedDataProxy_->loadedConnections)	 loadedDataProxy_->loadedConnections    = [[NSMutableDictionary alloc]init];
		if (!loadedDataProxy_->loadedHunkExclusions) loadedDataProxy_->loadedHunkExclusions = [[HunkExclusions alloc]init];
	}
	@catch (NSException* e)
	{
		if (outError)
		{
			NSDictionary* d = [NSDictionary dictionaryWithObject:@"The data is corrupted." forKey:NSLocalizedFailureReasonErrorKey];
			*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:d];
		}
		return NO;
	}
	
	// Use read in data
	return YES;
}

- (void) saveDocumentIfNamed
{
	NSString* fileName = [[[self fileURL] path] lastPathComponent];
	if (fileName)
		[self saveDocument:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Cache handling
// -----------------------------------------------------------------------------------------------------------------------------------------


// Load the version of the absolutePath for as of the given changeset into the caches directory. If we have already loaded the
// file then simply return the path of this cached snapshot of the file.
- (NSString*) loadCachedCopyOfPath:(NSString*)absolutePath forChangeset:(NSString*)changeset
{
	NSString* cacheDir = [[AppController sharedAppController] cacheDirectory];
	if (!cacheDir)
		return nil;
	
	// If we don't have a changeset then just use the current absolute path
	if (!changeset)
		return absolutePath;
	
	NSString* baseDir  = [cacheDir stringByAppendingPathComponent:fstr(@"snapshots/%@", changeset)];
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSString* theRelativePath = pathDifference(rootPath, absolutePath);
	NSString* newPath = [baseDir stringByAppendingPathComponent:theRelativePath];
	
	// If the snapshot file already exists then we have cached it before and we are done
	if (pathIsExistent(newPath))
		return newPath;
	
	// Create the intermediate directories if we have to
	NSString* containingDir = [newPath stringByDeletingLastPathComponent];
	if (!pathIsExistentDirectory(containingDir))
	{
		NSError* err = nil;
		NSFileManager* fileManager = [NSFileManager defaultManager];
		[fileManager createDirectoryAtPath:containingDir withIntermediateDirectories:YES attributes:nil error:&err];
		[NSApp presentAnyErrorsAndClear:&err];
	}
	
	NSMutableArray* argsCat = [NSMutableArray arrayWithObjects:@"cat", @"--output", newPath, @"--rev", changeset, theRelativePath, nil];
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsCat  fromRoot:rootPath  logging:eLogAllToFile];
	if ([results hasErrors])
		return nil;
	return newPath;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Suspension / Resumption of events
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) eventsAreSuspended											{ return eventsSuspensionCount_ > 0; }
- (BOOL) underlyingRepositoryChangedEventIsQueued					{ return [queueForUnderlyingRepositoryChangedViaEvents_ operationQueued]; }
- (SingleTimedQueue*) queueForUnderlyingRepositoryChangedViaEvents	{ return queueForUnderlyingRepositoryChangedViaEvents_; }

- (void) suspendEvents
{
	eventsSuspensionCount_++;
	[queueForUnderlyingRepositoryChangedViaEvents_ suspendQueue];
}

- (void) resumeEvents
{
	eventsSuspensionCount_--;
	if (eventsSuspensionCount_ < 0)
	{
		DebugLog(@"eventsSuspensionCount went negative");
		eventsSuspensionCount_ = 0;
	}
	if (eventsSuspensionCount_ > 0)
		return;

	// The refresh can cause other events to fire like updating the underlying repository, so we can't resume until all the refreshing is done.
	BOOL doRefresh = IsNotEmpty(changedPathsDuringSuspension_);
	if (doRefresh)
	{
		eventsSuspensionCount_++;
		NSArray* changedPaths = changedPathsDuringSuspension_;
		changedPathsDuringSuspension_ = nil;
		[self refreshBrowserPaths:changedPaths finishingBlock:^{[self resumeEvents];}];
		return;
	}

	BOOL postNotification = [queueForUnderlyingRepositoryChangedViaEvents_ operationQueued];
	[queueForUnderlyingRepositoryChangedViaEvents_ resumeQueue];
	if (postNotification)
	{
		DebugLog(@"resume events: queueing underlying repository changed event.");
		[queueForUnderlyingRepositoryChangedViaEvents_
			addBlockOperation: ^{[self postNotificationWithName:kUnderlyingRepositoryChanged];}
					withDelay: 0.5];
	}
}

- (void) delayEventsUntilFinishBlock:(BlockProcess) theBlock
{
	[self suspendEvents];
	theBlock();
	dispatch_async(mainQueue(), ^{
		[events_ flushEventStreamSync];
		[self resumeEvents];
	});
}

- (void) addToChangedPathsDuringSuspension:(NSArray*)paths
{
	if (!changedPathsDuringSuspension_)
		changedPathsDuringSuspension_ = [[NSMutableArray alloc]init];
	@synchronized(changedPathsDuringSuspension_)
		{ [changedPathsDuringSuspension_ addObjectsFromArray:paths]; }
}


- (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath whileDelayingEvents:(BOOL)delay
{
	return [self  executeMercurialWithArgs:args  fromRoot:rootPath  withDelegate: nil  whileDelayingEvents:delay];
}

- (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  withDelegate:(id <ShellTaskDelegate>)delegate  whileDelayingEvents:(BOOL)delay
{
	if (!delay)
		return [TaskExecutions  executeMercurialWithArgs:args  fromRoot:rootPath  logging:eLogAllIssueErrors  withDelegate:delegate];
	
	__block ExecutionResult* results;
	[self delayEventsUntilFinishBlock:^{
		results = [TaskExecutions  executeMercurialWithArgs:args  fromRoot:rootPath  logging:eLogAllIssueErrors  withDelegate:delegate];
	}];
	return results;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSEvents
// -----------------------------------------------------------------------------------------------------------------------------------------

// When looking at FSEvents we should discard event paths which match something in the regex which represents the .hgignore files
- (BOOL) absolutePathMatchedByHGIgnore:(NSString*)path
{
	NSString* regex = [[self repositoryData] combinedHGIgnoreRegEx];
	if (IsEmpty(regex))
		return NO;
	
	// Check all sub directories for a match
	NSString* relativePath = pathDifference([[self repositoryData] rootPath], path);
	NSArray* pathComponents = [relativePath pathComponents];
	NSString* builtPath = @"";
	for (NSString* component in pathComponents)
	{
		builtPath = [builtPath stringByAppendingPathComponent:component];
		if ([builtPath isMatchedByRegex:regex options:RKLMultiline])
			return YES;
	}
	return NO;
}


// Sets up the event listener using FSEvents and sets its delegate to this controller. The event stream is started by calling
// startWatchingPaths: while passing the paths to be watched.
- (void) setupEventlistener
{
	dispatchSpliced(mainQueue(), ^{
		[events_ setDelegate:self];
		NSMutableArray* paths = [NSMutableArray arrayWithObject:[self absolutePathOfRepositoryRoot]];
		[events_ stopWatchingPaths];
		[events_ startWatchingPaths:paths];
	});
}


// This is the only method to be implemented to conform to the FSEventListenerProtocol.
// We get the path and if its inside the repository meta data we prepare to post the underlying repository changed notification,
// otherwise we update the changed directories in the browser. If we are delaying the events then cache them until later.
- (void) fileEventsOccurredIn:(NSArray*)eventPaths
{
	NSMutableArray* filteredPaths = [[NSMutableArray alloc]init];
	NSString* rootDotHGDirPath = [[self absolutePathOfRepositoryRoot] stringByAppendingPathComponent:@".hg"];
	NSString* rootDotHGFSChecksDirPath   = fstr(@"%@/fschecks",			rootDotHGDirPath);
	NSString* rootDotHGCacheDirPath      = fstr(@"%@/cache",			rootDotHGDirPath);
	NSString* rootDotHGMacHgUndoDirPath  = fstr(@"%@/macHgUndo",		rootDotHGDirPath);
	NSString* rootDotHGMacHgPartsDirPath = fstr(@"%@/macHgParts",		rootDotHGDirPath);
	NSString* rootDotHGGitCaches         = fstr(@"%@/git/refs/heads",	rootDotHGDirPath);
	NSString* rootDotHGGit               = fstr(@"%@/hggit",			rootDotHGDirPath);
	BOOL postNotification = NO;
	for (NSString* path in eventPaths)
	{
		if (pathContainedIn(rootDotHGDirPath, path))
		{
			if (pathContainedIn(rootDotHGFSChecksDirPath, path))
				continue;	// If the path is further contained in just the fschecks dir then we ignore it since Mercurial uses this internally.
			if (pathContainedIn(rootDotHGCacheDirPath, path))
				continue;	// If the path is further contained in just the caches dir then we ignore it since Mercurial uses this internally.
			if (pathContainedIn(rootDotHGMacHgUndoDirPath, path))
				continue;	// If the path is further contained in the undo directory then we also ignore it since we are doing a backup for undo.
			if (pathContainedIn(rootDotHGMacHgPartsDirPath, path))
				continue;	// If the path is further contained in the parts directory then we also ignore it since we are use this internally for complex committing / amending.
			if (pathContainedIn(rootDotHGGitCaches, path))
				continue;	// If the path is further contained in the caches for hggit then hggit is using this interally
			if (pathContainedIn(rootDotHGGit, path))
				continue;	// If the path is further contained in the caches hggit uses then hggit is using this interally
			postNotification = YES;
			continue;
		}

		if ([self absolutePathMatchedByHGIgnore:path])
			continue;

		[filteredPaths addObject:path];
	}

	if (postNotification && ![self underlyingRepositoryChangedEventIsQueued])
	{
		DebugLog(@"fileEventsOccurredIn : queueing underlying repository changed event.");
		[queueForUnderlyingRepositoryChangedViaEvents_ addBlockOperation:^{
			[self postNotificationWithName:kUnderlyingRepositoryChanged]; }];
	}
	
	NSArray* canonicalized = pruneContainedPaths(filteredPaths);
	if (IsEmpty(canonicalized))
		return;

	DebugLog(@"Some file paths changed. File events are %@.\nThe raw paths are %@. The canonicalized paths are %@", [self eventsAreSuspended]? @"suspended":@"acted on immediately", eventPaths, canonicalized);
	if (![self eventsAreSuspended])
		[self refreshBrowserPaths:canonicalized];
	else
		[self addToChangedPathsDuringSuspension:canonicalized];
}




// You call this before doing operations on the given paths. It visually updates the colors of the paths to look "indeterminate"
// while the update is going on. It also suspends notifications of FSEvents on the path since we are going to do a complete
// refresh of the paths in any case.
- (void) registerPendingRefresh:(NSArray*)paths { return [self registerPendingRefresh:paths  visuallyDirtifyPaths:YES]; }
- (void) registerPendingRefresh:(NSArray*)paths  visuallyDirtifyPaths:(BOOL)dirtify
{
	if (dirtify)
	{
		NSString* rootPath = [self absolutePathOfRepositoryRoot];
		[[self theFSViewer] markPathsDirty:[RepositoryPaths fromPaths:paths withRootPath:rootPath]];		// Mark the paths as dirty and redisplay them...
	}
}


- (IBAction)	actionTestListingItem:(id)sender
{	
	return;
//	DebugLog(@"Currently watching Paths:%@", [events_ isWatchingPaths] ? @"Yes":@"No");
//	NSMutableArray* watchedPaths  = [events_ watchedPaths];
//	DebugLog(@"The currently watched  Paths : %@", watchedPaths);
//	DebugLog(@"streamDescription %@", [events_ streamDescription]);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: RepositoryData Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) initializeRepositoryData
{
	@synchronized(self)
	{
		DebugLog(@"Initializing log entry collection");
		[repositoryData_ stopObserving];	// Stop any old repositoryData object from receiving notifications.
		NSString* rootPath = [self absolutePathOfRepositoryRootFromSidebar];
		repositoryData_ = [[RepositoryData alloc] initWithRootPath:rootPath andDocument:self];
	}
}

- (RepositoryData*) repositoryData
{
	if (repositoryData_)
		return repositoryData_;
	@synchronized(self)
	{
		if (!repositoryData_)
			[self initializeRepositoryData];
	}
	return repositoryData_;
}

- (void) discardCurrentRepository
{
	[events_ stopWatchingPaths];
	[self actionSwitchViewToBackingView:self];
	[[self mainWindow] setRepresentedURL:[self fileURL]];	// The drop down represents the path to the MacHg document
	[repositoryData_ stopObserving];						// Stop any abandoned repositoryData objects from receiving notifications.
	[repositoryData_ markAsDiscarded];
	repositoryData_ = nil;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Version Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSNumber*) getHGParent1Revision		{ return [[self repositoryData] getHGParent1Revision]; }
- (NSNumber*) getHGParent2Revision		{ return [[self repositoryData] getHGParent2Revision]; }
- (NSString*) getHGParent1Changeset		{ return [[self repositoryData] getHGParent1Changeset]; }
- (NSString*) getHGParent2Changeset		{ return [[self repositoryData] getHGParent2Changeset]; }
- (NSNumber*) getHGTipRevision			{ return [[self repositoryData] getHGTipRevision]; }
- (NSString*) getHGTipChangeset			{ return [[self repositoryData] getHGTipChangeset]; }
- (NSNumber*) getSelectedRevision		{ return theHistoryViewController_ ? [[[self theHistoryView] logTableView] selectedRevision] : nil; }
- (BOOL)      isCurrentRevisionTip		{ return [[self repositoryData] isCurrentRevisionTip]; }
- (BOOL)	  inMergeState				{ return [[self repositoryData] inMergeState]; }
- (NSInteger) computeNumberOfRevisions	{ return [[self repositoryData] computeNumberOfRevisions]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path and Selection Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*)		absolutePathOfRepositoryRoot			{ return [repositoryData_ rootPath]; }
- (NSString*)		absolutePathOfRepositoryRootFromSidebar	{ SidebarNode* repo = [sidebar_ selectedNode]; return [repo isLocalRepositoryRef] ? [repo path] : nil; }
- (NSString*)		selectedRepositoryShortName				{ SidebarNode* repo = [sidebar_ selectedNode]; return [repo isLocalRepositoryRef]  ? [repo shortName]  : nil; }
- (NSString*)		selectedRepositoryPath					{ SidebarNode* repo = [sidebar_ selectedNode]; return [repo isRepositoryRef] ? [repo path] : nil; }
- (SidebarNode*)	selectedRepositoryRepositoryRef			{ SidebarNode* repo = [sidebar_ selectedNode]; return [repo isRepositoryRef] ? repo : nil; }
- (NSArray*)		absolutePathOfRepositoryRootAsArray		{ return [NSArray arrayWithObject:[self absolutePathOfRepositoryRoot]]; }

- (FSViewer*)		theFSViewer								{ return [[self theFilesView] theFSViewer]; }
- (FSNodeInfo*)		rootNodeInfo							{ return [[self theFSViewer] rootNodeInfo]; }
- (FSNodeInfo*)		nodeForPath:(NSString*)absolutePath		{ return [[self rootNodeInfo] nodeForPathFromRoot:absolutePath]; }
- (BOOL)			singleFileIsChosenInFiles				{ return [[self theFSViewer] singleFileIsChosenInFiles]; }
- (BOOL)			singleItemIsChosenInFiles				{ return [[self theFSViewer] singleItemIsChosenInFiles]; }
- (BOOL)			nodesAreChosenInFiles					{ return [[self theFSViewer] nodesAreChosen]; }
- (HGStatus)		statusOfChosenPathsInFiles				{ return [[self theFSViewer] statusOfChosenPathsInFiles]; }
- (NSArray*)		absolutePathsOfChosenFiles				{ return [[self theFSViewer] absolutePathsOfChosenFiles]; }
- (NSString*)		enclosingDirectoryOfChosenFiles			{ return [[self theFSViewer] enclosingDirectoryOfChosenFiles]; }

- (BOOL) statusOfChosenPathsInFilesContain:(HGStatus)status	{ return bitsInCommon(status, [[self theFSViewer] statusOfChosenPathsInFiles]); }
- (BOOL) repositoryHasFilesWhichContainStatus:(HGStatus)status	{ return bitsInCommon(status, [[[self theFSViewer] rootNodeInfo] hgStatus]); }

// Move any "unknown" files ending in .orig to the trash.
- (void) pruneDotOrigFiles:(NSArray*)paths
{
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", @"--unknown", @"--no-status", nil];
	[argsStatus addObjectsFromArray:paths];
	NSString* rootPath = [self absolutePathOfRepositoryRoot];

	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	
	if ([results hasErrors])
	{
		PlayBeep();
		return;
	}
	NSArray* prunePaths = [results.outStr componentsSeparatedByString:@"\n"];
	NSMutableArray* filesToTrash = [[NSMutableArray alloc]init];
	for (NSString* prunePath in prunePaths)
		if ([[prunePath pathExtension] isEqualToString:@"orig"])
			[filesToTrash addObject:[rootPath stringByAppendingPathComponent:prunePath]];
	
	moveFilesToTheTrash(filesToTrash);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Undo handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) removeAllUndoActionsForDocument
{
	NSUndoManager* undo = [sidebar_ undoManager];
	[undo removeAllActionsWithTarget:sidebar_];
}



- (void) pushRepositoryCopyForUndo:(NSError**)error
{
	[self delayEventsUntilFinishBlock:^{
		NSString* root    = [self absolutePathOfRepositoryRoot];
		NSString* undoDir = fstr(@"%@/.hg/macHgUndo", root);
		NSString* copyDir = fstr(@"%@/copy", undoDir);
		NSError* err = nil;

		NSFileManager* localFileManager =[[NSFileManager alloc] init];
		[localFileManager setDelegate:self];
		
		[localFileManager createDirectoryAtPath:copyDir withIntermediateDirectories:YES attributes:nil error:&err];
		if (err)
		{
			if (!error)
				[NSApp presentError:err];
			else
				*error = err;
			return;
		}
		
		NSDirectoryEnumerator* dirEnum = [localFileManager enumeratorAtPath:root];
		
		NSString* path;
		while ( (path = [dirEnum nextObject]) )
		{
			NSDictionary* pathAttributes = [dirEnum fileAttributes];
			NSString* pathType = [pathAttributes fileType];
			NSString* srcPath = [root stringByAppendingPathComponent:path];
			NSString* dstPath = [copyDir stringByAppendingPathComponent:path];
			
			
			if ([localFileManager fileExistsAtPath:dstPath isDirectory:nil])
				continue;
			
			if (pathContainedIn(@".hg/macHgUndo",path))
			{
				[dirEnum skipDescendants];
				continue;
			}
			
			if (pathType == NSFileTypeSymbolicLink)
				[localFileManager copyItemAtPath:srcPath toPath:dstPath error:&err];
			else if (pathType == NSFileTypeDirectory)
				[localFileManager createDirectoryAtPath:dstPath withIntermediateDirectories:YES attributes:nil error:&err];
			else if (pathType == NSFileTypeRegular)
				[localFileManager linkItemAtPath:srcPath toPath:dstPath error:&err];
			else
				[localFileManager linkItemAtPath:srcPath toPath:dstPath error:&err];
			if (err)
			{
				if (!error)
					[NSApp presentError:err];
				else
					*error = err;
				return;
			}
		}
	}];
}

- (IBAction) doLinkUp:(id)sender
{
	NSError* err = nil;
	[self pushRepositoryCopyForUndo:&err];
	[NSApp presentAnyErrorsAndClear:&err];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Notifications
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) validateViewSelector
{
	BOOL enabled = [self localRepoIsSelectedAndReady];
	[toolbarSegementedControl_ setEnabled:enabled forSegment:0];
	[toolbarSegementedControl_ setEnabled:enabled forSegment:1];
	[toolbarSegementedControl_ setEnabled:enabled forSegment:2];
}


- (void) repositoryRootDidChange
{
	SidebarNode* node = [sidebar_ selectedNode];
	BOOL multipleSelection = [[sidebar_ selectedRowIndexes] count] > 1;
	
	if (![node isExistentLocalRepositoryRef] || multipleSelection)
	{
		[self discardCurrentRepository];
		return;
	}

	if ([node isLocalRepositoryRef] && [self showingBackingView])
		[self actionSwitchViewToFilesView:self];

	NSString* rootPath = [self absolutePathOfRepositoryRootFromSidebar];
	BOOL rootPathChanged = !repositoryData_ || ![[repositoryData_ rootPath] isEqualToString:rootPath];
	if (rootPathChanged)
		[self initializeRepositoryData];

	if ([node isLocalRepositoryRef])
		[self setupEventlistener];
}


- (IBAction) searchFieldChanged:(id)sender
{
	if ([self showingHistoryView])
	{
		HistoryView* hpv = [self theHistoryView];
		LogTableView* logTableView = [hpv logTableView];	
		toolbarSearchFieldValue_ = [[self toolbarSearchField] stringValue];
		[logTableView resetTable:hpv];
		[hpv refreshHistoryView:sender];
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Refresh / Regenrate Browser
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) refreshBrowserPaths:(NSArray*)absoluteChangedPaths  { [self refreshBrowserPaths:absoluteChangedPaths finishingBlock:nil]; }
- (void) refreshBrowserPaths:(NSArray*)absoluteChangedPaths  finishingBlock:(BlockProcess)theBlock
{
	[[self theFSViewer] refreshBrowserPaths:[RepositoryPaths fromPaths:absoluteChangedPaths withRootPath:[self absolutePathOfRepositoryRoot]] finishingBlock:theBlock];
}


- (IBAction) refreshBrowserContent:(id)sender
{
	if (![sidebar_ localRepoIsSelected])
		return;		
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	[[self theFSViewer] refreshBrowserPaths:[RepositoryPaths fromRootPath:rootPath] finishingBlock:nil];
	[self setupEventlistener];
}






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Selected Files Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) primaryActionDeleteSelectedFiles:(NSArray*)theSelectedFiles
{
	if (IsEmpty(theSelectedFiles))
		{ PlayBeep(); DebugLog(@"No files selected to remove"); return NO; }
	
	if (DisplayWarningForFileDeletionFromDefaults())
	{
		int result = RunCriticalAlertPanelWithSuppression( @"Delete Selected Files", @"Are you sure you want to move the selected files to the trash?", @"Delete Files", @"Cancel", MHGDisplayWarningForFileDeletion);
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}
	
	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Delete Files" process:^{
		[self registerPendingRefresh:theSelectedFiles visuallyDirtifyPaths:NO];
		NSString* rootPath = [self absolutePathOfRepositoryRoot];
		moveFilesToTheTrash(theSelectedFiles);
		[self refreshBrowserPaths:parentPaths(theSelectedFiles,rootPath)];
	}];
	return YES;
}


- (BOOL) primaryActionAddSelectedFiles:(NSArray*)theSelectedFiles
{
	if (IsEmpty(theSelectedFiles))
		{ PlayBeep(); DebugLog(@"No files selected to add"); return NO; }

	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	
	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Add Selected Files" process:^{
		[self registerPendingRefresh:theSelectedFiles];
		NSMutableArray* argsAdd = [NSMutableArray arrayWithObjects:@"add", nil];
		[argsAdd addObjectsFromArray:theSelectedFiles];
		[self delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:argsAdd  fromRoot:rootPath];
			[self addToChangedPathsDuringSuspension:theSelectedFiles];
		}];
	}];
	return YES;
}


- (BOOL) primaryActionUntrackSelectedFiles:(NSArray*)theSelectedFiles
{
	if (IsEmpty(theSelectedFiles))
		{ PlayBeep(); DebugLog(@"No files selected to untrack"); return NO; }
	
	if (DisplayWarningForUntrackingFilesFromDefaults())
	{
		NSString* subMessage = @"Are you sure you want to stop tracking the selected files?";
		int result = RunCriticalAlertPanelWithSuppression(@"Untrack Selected Files", subMessage, @"Stop Tracking Files", @"Cancel", MHGDisplayWarningForUntrackingFiles);
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}
	
	[self removeAllUndoActionsForDocument];
	NSArray* pathsForHGToUntrack = [[self theFSViewer] filterPaths:theSelectedFiles byBitfield:eHGStatusInRepository];
	if ([pathsForHGToUntrack count] > 0)
		[self dispatchToMercurialQueuedWithDescription:@"Untrack Files" process:^{
			[self registerPendingRefresh:pathsForHGToUntrack];
			NSString* rootPath = [self absolutePathOfRepositoryRoot];
			NSMutableArray* argsForget = [NSMutableArray arrayWithObjects:@"forget", nil];
			[argsForget addObjectsFromArray:pathsForHGToUntrack];
			[self delayEventsUntilFinishBlock:^{
				[TaskExecutions executeMercurialWithArgs:argsForget  fromRoot:rootPath];
				[self addToChangedPathsDuringSuspension:pathsForHGToUntrack];
			}];
		}];
	return YES;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Ignore / Unignore Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

static inline NSString* QuoteRegExCharacters(NSString* theName)
{
	NSString* regexString       = @"(\\#|\\*|\\+|\\(|\\)|\\?|\\.|\\[|\\]|\\||\\^|\\$)";
	NSString* replaceWithString = @"\\\\$1";
	return [theName stringByReplacingOccurrencesOfRegex:regexString withString:replaceWithString];
}


- (BOOL) primaryActionIgnoreSelectedFiles:(NSArray*)theSelectedFiles
{
	NSString* root = [self absolutePathOfRepositoryRoot];
	NSString* hgignorePath = [root stringByAppendingPathComponent:@".hgignore"];
	if (IsEmpty(theSelectedFiles))
		return NO;

	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Ignoring Files" process:^{
		NSError* err = nil;
		NSMutableArray* pathsToRefresh = [NSMutableArray arrayWithArray:theSelectedFiles];
		[pathsToRefresh addObject:hgignorePath];
		[self registerPendingRefresh:pathsToRefresh];
		NSMutableString* hgignoreContents = [NSMutableString stringWithContentsOfFile:hgignorePath encoding:NSUTF8StringEncoding error:nil];
		if (!hgignoreContents)
			hgignoreContents = [[NSMutableString alloc] init];
		else if (![hgignoreContents endsWithNewLine])
			[hgignoreContents appendString:@"\n"];
		
		for (NSString* file in theSelectedFiles)
		{
			NSString* rootRelativeFile = QuoteRegExCharacters(pathDifference(root, file));
			NSRange range = [hgignoreContents rangeOfString:rootRelativeFile];
			if (range.location == NSNotFound)
				[hgignoreContents appendFormat:@"%@\n",rootRelativeFile];
		}
		[hgignoreContents writeToFile:hgignorePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
		[NSApp presentAnyErrorsAndClear:&err];
		[self refreshBrowserPaths:pathsToRefresh];
	}];
	return YES;
}


- (BOOL) primaryActionUnignoreSelectedFiles:(NSArray*)theSelectedFiles
{
	NSString* root = [self absolutePathOfRepositoryRoot];
	NSString* hgignorePath = [root stringByAppendingPathComponent:@".hgignore"];
	if (IsEmpty(theSelectedFiles))
		return NO;

	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Unignoring Files" process:^{
		NSMutableArray* pathsToRefresh = [NSMutableArray arrayWithArray:theSelectedFiles];
		[pathsToRefresh addObject:hgignorePath];
		[self registerPendingRefresh:pathsToRefresh];
		NSString* hgignoreContents = [NSString stringWithContentsOfFile:hgignorePath encoding:NSUTF8StringEncoding error:nil];
		if (hgignoreContents)
		{
			for (NSString* file in theSelectedFiles)
			{
				NSString* rootRelativeFile = QuoteRegExCharacters(pathDifference(root, file));
				hgignoreContents = [hgignoreContents stringByReplacingOccurrencesOfString:rootRelativeFile withString:@""];
			}

			NSError* err = nil;
			hgignoreContents = [hgignoreContents stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
			[hgignoreContents writeToFile:hgignorePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
			[NSApp presentAnyErrorsAndClear:&err];
			
			[self refreshBrowserPaths:pathsToRefresh];
		}
	}];
	return YES;
}


- (BOOL) primaryActionAnnotateSelectedFiles:(NSArray*)theSelectedFiles
{	
	NSNumber* revision = [self getHGParent1Revision];
	NSArray* options = [[AppController sharedAppController] annotationOptionsFromDefaults];
	[self primaryActionAnnotateSelectedFiles:theSelectedFiles withRevision:revision andOptions:options];
	return YES;
}


- (IBAction) mainMenuRollbackCommit:(id)sender
{
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSArray* rootPathAsArray = [self absolutePathOfRepositoryRootAsArray];
	if (!rootPath)
		return;
	
	if (DisplayWarningForRollbackFilesFromDefaults())
	{
		NSString* subMessage = @"Are you sure you want to roll back the repository to just before the last commit? (This can't be undone)";
		int choice = RunCriticalAlertPanelWithSuppression(@"Rolling Back Last Commit", subMessage, @"Roll Back", @"Cancel", MHGDisplayWarningForRollbackFiles);
		if (choice != NSAlertFirstButtonReturn)
			return;
	}
	
	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Rolling Back" process:^{
		NSMutableArray* argsRollback = [NSMutableArray arrayWithObjects:@"rollback", nil];
		[self delayEventsUntilFinishBlock:^{
			[TaskExecutions  executeMercurialWithArgs:argsRollback  fromRoot:rootPath];
			[self addToChangedPathsDuringSuspension:rootPathAsArray];
		}];
	}];
}




// We use this as the selector to send back when we don't want to do anything. (It helps with the programming to have this
// especially when we are dynamically choosing selectors, etc.)
- (IBAction) mainMenuNoAction:(id)sender
{
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Primary Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) primaryActionRevertFiles:(NSArray*)absolutePaths toVersion:(NSNumber*)version
{
	NSArray* filteredPaths = version ? absolutePaths : [[self theFSViewer] filterPaths:absolutePaths byBitfield:eHGStatusChangedInSomeWay];
	
	if ([filteredPaths count] <= 0)
		{ PlayBeep(); DebugLog(@"No files selected to revert"); return NO; }
	
	if (DisplayWarningForRevertingFilesFromDefaults())
	{
		BOOL pathsAreRootPath = [[filteredPaths lastObject] isEqual:[self absolutePathOfRepositoryRoot]];
		NSString* mainMessage = fstr(@"Reverting %@ Files", pathsAreRootPath ? @"All" : @"Selected");
		NSString* subMessage  = fstr( @"Are you sure you want to revert %@ in the repository “%@” to %@? (Any modified files will be moved to the trash)",
								 pathsAreRootPath ? @"all files" : @"the selected files",
								 [self selectedRepositoryShortName],
								 version ? fstr(@"revision “%@”", version) :
								 ([self isCurrentRevisionTip] ? @"the latest revision" : @"current revision"));
		
		int result = RunCriticalAlertPanelOptionsWithSuppression(mainMessage, subMessage, @"Revert", @"Cancel", @"Options…", MHGDisplayWarningForRevertingFiles);
		if (result == NSAlertThirdButtonReturn) // Options
		{
			[[self theRevertSheetController] openRevertSheetWithPaths:absolutePaths andRevision:version];
			return NO;
		}
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}
	
	[self removeAllUndoActionsForDocument];
	NSString* rootPath = [self absolutePathOfRepositoryRoot];

	[self dispatchToMercurialQueuedWithDescription:@"Reverting Files" process:^{
		[self registerPendingRefresh:filteredPaths];
		NSMutableArray* argsRevert = [NSMutableArray arrayWithObjects:@"revert", nil];
		if (version)
		{
			NSString* versionStr = numberAsString(version);
			[argsRevert addObject:@"--rev"];
			[argsRevert addObject:versionStr];
		}
		[argsRevert addObjectsFromArray:filteredPaths];
		NSArray* theParentPaths = parentPaths(filteredPaths,rootPath);
		
		[self delayEventsUntilFinishBlock:^{
			[TaskExecutions  executeMercurialWithArgs:argsRevert  fromRoot:rootPath];
			if (HandleGeneratedOrigFilesFromDefaults() == eMoveOrigFilesToTrash)
				[self pruneDotOrigFiles:theParentPaths];
			[self addToChangedPathsDuringSuspension:theParentPaths];
		}];
		
	}];
	return YES;
}

   
- (BOOL) primaryActionAddRenameRemoveFiles:(NSArray*)absolutePaths
{
	if (IsEmpty(absolutePaths))
		{ PlayBeep(); DebugLog(@"No files selected to AddRenameRemove"); return NO; }
	
	NSArray* theSelectedFiles = absolutePaths;
	if ([theSelectedFiles count] <= 0)
		return NO;
	if (DisplayWarningForAddRemoveRenameFilesFromDefaults())
	{
		NSString* subMessage;
		NSString* mainMessage;
		NSString* buttonMessage;
		BOOL rootOperation = [absolutePaths count] == 1 && [[self absolutePathOfRepositoryRoot] isEqualTo:[absolutePaths objectAtIndex:0]];
		BOOL useSimilarity = AddRemoveUsesSimilarityFromDefaults();
		if (useSimilarity && rootOperation)
		{
			subMessage = @"Mark all missing files for removal, mark all unknown files for addition, and mark any moved files as renamed?";
			mainMessage = @"Adding, Renaming and Removing Files";
			buttonMessage = @"AddRenameRemove Files";
		}
		else if (useSimilarity && !rootOperation)
		{
			subMessage = @"Within the selected files, mark all missing files for removal, mark all unknown files for addition, and mark any moved files as renamed?";
			mainMessage = @"Adding, Renaming and Removing Selected Files";
			buttonMessage = @"AddRenameRemove Files";
		}
		else if (!useSimilarity && rootOperation)
		{
			subMessage = @"Mark all missing files for removal and mark all unknown files for addition?";
			mainMessage = @"Adding and Removing Files";
			buttonMessage = @"AddRemove Files";
		}
		else if (!useSimilarity && !rootOperation)
		{
			subMessage = @"Within the selected files, mark all missing files for removal and mark all unknown files for addition?";
			mainMessage = @"Adding and Removing Selected Files";
			buttonMessage = @"AddRemove Files";
		}

		int result = RunCriticalAlertPanelWithSuppression(mainMessage, subMessage, buttonMessage, @"Cancel", MHGDisplayWarningForAddRemoveRenameFiles);
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}
	
	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Add Rename Remove Files" process:^{
		[self registerPendingRefresh:theSelectedFiles];
		NSString* rootPath = [self absolutePathOfRepositoryRoot];
		NSMutableArray* argsAddRemove = [NSMutableArray arrayWithObject:@"addremove"];
		[argsAddRemove addObject:@"--verbose"];
		if (AddRemoveUsesSimilarityFromDefaults())
			[argsAddRemove addObject:@"--similarity" followedBy:AddRemoveSimilarityFactorFromDefaults()];
		[argsAddRemove addObjectsFromArray:theSelectedFiles];
		
		__block ExecutionResult* results;
		[self delayEventsUntilFinishBlock:^{
			results = [TaskExecutions executeMercurialWithArgs:argsAddRemove  fromRoot:rootPath];
			[self addToChangedPathsDuringSuspension:theSelectedFiles];
		}];
		
		if (DisplayResultsOfAddRemoveRenameFilesFromDefaults())
		{
			NSString* messageString = fstr(@"Results of Add Remove Files in “%@”", [self selectedRepositoryShortName]);
			NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
			NSString* windowTitle = fstr(@"AddRemove Results - %@", [self selectedRepositoryShortName]);
			[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:windowTitle onScreen:[[self mainWindow] screen]];
		}		
	}];
	return YES;
}


- (BOOL) primaryActionUpdateFilesToVersion:(NSNumber*)version withCleanOption:(BOOL)clean
{
	BOOL containsChangedFiles = [self repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
	if (DisplayWarningForUpdatingFromDefaults() || [self repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		NSString* mainMessage = @"Updating All Files";
		NSString* subMessage  = fstr( @"Are you sure you want to update the repository “%@” to revision “%@”?",
								 [self selectedRepositoryShortName],
								 version);
		if (containsChangedFiles)
			subMessage = fstr(@"There are uncommitted changes. %@", subMessage);
		
		NSAlert* alert = NewAlertPanel(mainMessage, subMessage, @"Update", @"Cancel", @"Options…");
		[updateAlertAccessoryCleanCheckBox setState:clean];
		[updateAlertAccessoryAlertSuppressionCheckBox setState:NO];
		[alert setAccessoryView:updateAlertAccessoryView];
		int result = [alert runModal];
		if ([updateAlertAccessoryAlertSuppressionCheckBox state] == NSOnState)
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:MHGDisplayWarningForUpdating];
		clean = [updateAlertAccessoryCleanCheckBox state];
		if (result == NSAlertThirdButtonReturn) // Options
		{
			[[self theUpdateSheetController] openUpdateSheetWithRevision:version];
			return NO;
		}
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}
	
	[self removeAllUndoActionsForDocument];
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSString* versionStr = numberAsString(version);
	[self dispatchToMercurialQueuedWithDescription:@"Updating Files" process:^{
		
		if (clean)
		{
			[[self repositoryData] deleteRebaseState];
			[[self repositoryData] deleteHistoryEditState];
		}
		
		NSMutableArray* argsUpdate = [NSMutableArray arrayWithObjects:@"update", @"--rev", versionStr, nil];
		if (clean)
			[argsUpdate addObject:@"--clean"];

		ExecutionResult* results = [self executeMercurialWithArgs:argsUpdate  fromRoot:rootPath whileDelayingEvents:YES];

		if (DisplayResultsOfUpdatingFromDefaults())
		{
			NSString* messageString = fstr(@"Results of Updating “%@”",  [self selectedRepositoryShortName]);
			NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
			NSString* windowTitle = fstr(@"Update Results - %@", [self selectedRepositoryShortName]);
			[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:windowTitle onScreen:[[self mainWindow] screen]];
		}
	}];
	return YES;
}

- (BOOL) primaryActionBackoutFilesToVersion:(NSNumber*)version
{
	BOOL containsChangedFiles = [self repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
	if (containsChangedFiles)
	{
		NSRunAlertPanel(@"Backout Aborted", @"There are uncommitted changes in the repository. Backing out (Reversing) a changeset can only be performed on “clean” repositories.", @"OK", nil, nil);
		return NO;
	}
	
	if (DisplayWarningForUpdatingFromDefaults())
	{
		NSString* mainMessage = fstr(@"Backout Changeset “%@”?", version);
		NSString* subMessage  = fstr(@"Are you sure you want to backout (reverse) the changeset “%@” in the repository “%@”?",
									 version, [self selectedRepositoryShortName]);

		int result = RunCriticalAlertPanelOptionsWithSuppression(mainMessage, subMessage, @"Backout", @"Cancel", @"Options…", MHGDisplayWarningForBackout);
		if (result == NSAlertThirdButtonReturn) // Options
		{
			[[self theBackoutSheetController] openBackoutSheetWithRevision:version];
			return NO;
		}
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}

	
	[self removeAllUndoActionsForDocument];
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSString* versionStr = numberAsString(version);
	[self dispatchToMercurialQueuedWithDescription:@"Backout" process:^{
		NSString* scriptName = [[AppController sharedAppController] scriptNameForMergeTool:UseWhichToolForMergingFromDefaults()];
		NSMutableArray* argsBackout = [NSMutableArray arrayWithObjects:@"backout", @"--rev", versionStr, @"--tool", scriptName, nil];
		ExecutionResult* results = [self executeMercurialWithArgs:argsBackout  fromRoot:rootPath whileDelayingEvents:YES];

		if (YES) // There is no DisplayResultsOfBackoutFromDefaults() since it's not that common...
		{
			NSString* messageString = fstr(@"Results of Backing out “%@” in “%@”",  version, [self selectedRepositoryShortName]);
			NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
			NSString* windowTitle = fstr(@"Backout Results - %@", [self selectedRepositoryShortName]);
			[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:windowTitle onScreen:[[self mainWindow] screen]];
		}
		
		NSRunAlertPanel(@"Backed out Changeset",
						fstr(@"The changeset “%@” has been backed out. You now need to examine the modified files, resolve any conflicts, and finally commit all the changes to complete the backout.", version), @"OK", nil, nil);
		
	}];
	return YES;
}


- (BOOL) primaryActionMergeWithVersion:(NSNumber*)mergeVersion andOptions:(NSArray*)options withConfirmation:(BOOL)confirm
{
	if (confirm && DisplayWarningForMergingFromDefaults())
	{
		NSString* mainMessage = fstr(@"Merging %@", mergeVersion);
		NSString* subMessage  = fstr( @"Are you sure you want to merge version %@ into the %@ in the repository “%@”?",
								 mergeVersion,
								 ([self isCurrentRevisionTip] ? @"latest revision" : @"current revision"),
								 [self selectedRepositoryShortName]);
		
		int result = RunCriticalAlertPanelOptionsWithSuppression(mainMessage, subMessage, @"Merge", @"Cancel", @"Options…", MHGDisplayWarningForMerging);
		if (result == NSAlertThirdButtonReturn) // Options
		{
			[[self theMergeSheetController] openMergeSheetWithRevision:mergeVersion];
			return NO;
		}
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}
	
	[self removeAllUndoActionsForDocument];
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSArray* rootPathAsArray = [self absolutePathOfRepositoryRootAsArray];
	[self registerPendingRefresh:rootPathAsArray];

	NSString* mergeVersionStr = numberAsString(mergeVersion);
	NSString* scriptName = [[AppController sharedAppController] scriptNameForMergeTool:UseWhichToolForMergingFromDefaults()];
	NSMutableArray* argsMerge = [NSMutableArray arrayWithObjects:@"merge", @"--rev", mergeVersionStr, @"--tool", scriptName, nil];
	[argsMerge addObjectsFromArray:options];

	__block ExecutionResult* results;
	[self delayEventsUntilFinishBlock:^{
		results = [TaskExecutions executeMercurialWithArgs:argsMerge  fromRoot:rootPath];
		[self addToChangedPathsDuringSuspension:rootPathAsArray];
	}];
	
	if ([results hasErrors])
		return NO;

	switch (AfterMergeSwitchToFromDefaults())
	{
		case eAfterMergeSwitchToFiles:		[self actionSwitchViewToFilesView:self];	break;
		case eAfterMergeSwitchToHistory:	[self actionSwitchViewToHistoryView:self];	break;
	}

	if (DisplayResultsOfMergingFromDefaults())
	{
		NSString* messageString = fstr(@"Results of Merging “%@”",  [self selectedRepositoryShortName]);
		NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
		NSString* windowTitle = fstr(@"Merge Results - %@", [self selectedRepositoryShortName]);
		[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:windowTitle onScreen:[[self mainWindow] screen]];
	}
	
	if (DisplayWarningForPostMergeFromDefaults())
		NSRunAlertPanel(@"Merged Files", @"You now need to examine the merged files, resolve any conflicts, and finally commit all the merged files to complete the merge.", @"OK", nil, nil);

	switch (AfterMergeDoFromDefaults())
	{
		case eAfterMergeDoNothing:			break;
		case eAfterMergeOpenCommit:			[[self theCommitSheetController] openCommitSheetWithAllFiles:self];
	}


	return YES;
}


- (BOOL) primaryActionRemerge:(NSArray*)absolutePaths withConfirmation:(BOOL)confirm
{
	if (confirm && DisplayWarningForMergingFromDefaults())
	{
		NSString* what = ([absolutePaths count] == 1) ? [[absolutePaths lastObject] lastPathComponent] : @"the selected files";
		NSString* mainMessage = fstr(@"Remerging %@", what);
		NSString* subMessage  = fstr( @"Are you sure you want to throw away any changes you have made to %@ and remerge versions %@ and %@ in the repository “%@”?",
									 what,
									 [self getHGParent1Revision],
									 [self getHGParent2Revision],
									 [self selectedRepositoryShortName]);
		
		int result = RunCriticalAlertPanelWithSuppression(mainMessage, subMessage, @"Remerge", @"Cancel", MHGDisplayWarningForMerging);
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}
	
	[self removeAllUndoActionsForDocument];
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSArray* rootPathAsArray = [self absolutePathOfRepositoryRootAsArray];
	[self registerPendingRefresh:rootPathAsArray];
	NSMutableArray* argsResolve = [NSMutableArray arrayWithObjects:@"resolve", nil];
	[argsResolve addObjectsFromArray:absolutePaths];
	[self delayEventsUntilFinishBlock:^{
		[TaskExecutions executeMercurialWithArgs:argsResolve fromRoot:rootPath];
		[self addToChangedPathsDuringSuspension:rootPathAsArray];
	}];
	return YES;
}


- (BOOL) primaryActionMarkResolved:(NSArray*)absolutePaths withConfirmation:(BOOL)confirm
{
	if (confirm && DisplayWarningForMarkingFilesResolvedFromDefaults())
	{
		NSString* what = ([absolutePaths count] == 1) ? [[absolutePaths lastObject] lastPathComponent] : @"the selected files";
		NSString* mainMessage = fstr(@"Marking %@ as resolved", what);
		NSString* subMessage  = fstr( @"Are you sure you want to mark %@ as resolved in the repository “%@”?",
								 what,
								 [self selectedRepositoryShortName]);

		int result = RunCriticalAlertPanelWithSuppression(mainMessage, subMessage, @"Mark Resolved", @"Cancel", MHGDisplayWarningForMarkingFilesResolved);
		if (result != NSAlertFirstButtonReturn)
			return NO;
	}
	
	[self removeAllUndoActionsForDocument];
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSArray* rootPathAsArray = [self absolutePathOfRepositoryRootAsArray];
	[self registerPendingRefresh:rootPathAsArray];
	NSMutableArray* argsResolve = [NSMutableArray arrayWithObjects:@"resolve", @"--mark", nil];
	[argsResolve addObjectsFromArray:absolutePaths];
	[self delayEventsUntilFinishBlock:^{
		[TaskExecutions executeMercurialWithArgs:argsResolve fromRoot:rootPath];
		[self addToChangedPathsDuringSuspension:rootPathAsArray];
	}];
	return YES;
}


- (void) primaryActionDisplayManifestForVersion:(NSNumber*)version
{
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSString* thisRepositoryName = [self selectedRepositoryShortName];
	NSString* versionStr = numberAsString(version);
	[self dispatchToMercurialQueuedWithDescription:@"Generating Manifest" process:^{
		NSMutableArray* argsManifest = [NSMutableArray arrayWithObjects:@"manifest", @"--rev", versionStr, nil];
		ExecutionResult* results = [self executeMercurialWithArgs:argsManifest  fromRoot:rootPath  whileDelayingEvents:YES];
		NSString* messageString = fstr(@"Manifest of “%@” revision “%@”", thisRepositoryName, version);
		NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
		NSString* windowTitle =	fstr(@"Manifest Results - %@", [self selectedRepositoryShortName]);
		[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:windowTitle onScreen:[[self mainWindow] screen]];
	}];
}

- (NSArray*) filterPaths:(NSArray*)absolutePaths byManifestOfRevision:(NSNumber*)version
{	
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSString* versionStr = numberAsString(version);
	NSMutableArray* argsManifest = [NSMutableArray arrayWithObjects:@"manifest", @"--rev", versionStr, nil];
	ExecutionResult* results = [self executeMercurialWithArgs:argsManifest  fromRoot:rootPath  whileDelayingEvents:YES];
	NSArray* allFiles = [results.outStr componentsSeparatedByString:@"\n"];
	NSMutableSet* allPaths = [[NSMutableSet alloc]init];
	for (NSString* file in allFiles)
	{
		NSArray* pathComponents = [file pathComponents];
		NSString* builtPath = @"";
		for (NSString* component in pathComponents)
		{
			builtPath = [builtPath stringByAppendingPathComponent:component];
			[allPaths addObject:builtPath];
		}		
	}
	
	NSMutableArray* filteredPaths = [[NSMutableArray alloc]init];
	for (NSString* path in absolutePaths)
		if ([allPaths containsObject:pathDifference(rootPath,path)])
			[filteredPaths addObject:path];
	return filteredPaths;
}

- (void) primaryActionAnnotateSelectedFiles:(NSArray*)absolutePaths withRevision:(NSNumber*)version andOptions:(NSArray*)options
{
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSArray* filteredPaths = [self filterPaths:absolutePaths byManifestOfRevision:version];
	
	int numberOfFilesToAnnotate = [filteredPaths count];
	if (numberOfFilesToAnnotate < 1)
		{ PlayBeep(); return; }
	if (numberOfFilesToAnnotate > 10)
	{
		int choice = NSRunAlertPanel(@"Many Annotations", @"There are %d files which will have annotations, are you sure you want to display all these annotations?", @"Show Annotations", @"Cancel", nil, numberOfFilesToAnnotate);
		if (choice != NSAlertDefaultReturn)
			return;
	}

	NSString* versionStr = numberAsString(version);
	[self dispatchToMercurialQueuedWithDescription:@"Generating Annotations" process:^{
		DispatchGroup group = dispatch_group_create();
		for (NSString* file in filteredPaths)
			dispatch_group_async(group, globalQueue(), ^{
				NSMutableArray* argsAnnotate = [NSMutableArray arrayWithObjects:@"annotate", @"--rev", versionStr, nil];
				[argsAnnotate addObjectsFromArray:options];
				[argsAnnotate addObject:file];
				ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsAnnotate  fromRoot:rootPath];
				NSString* fileName = [file lastPathComponent];
				NSString* messageString = fstr(@"Annotations of “%@” for revision “%@”", fileName, version);
				NSString* windowTitle   = fstr(@"%@ : %@ Annotations", fileName, version);
				NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(nonNil(results.outStr));
				[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:windowTitle onScreen:[[self mainWindow] screen]];
			});
		dispatchGroupWaitAndFinish(group);
	}];
}

- (void) viewDifferencesInCurrentRevisionFor:(NSArray*)absolutePaths toRevision:(NSString*)versionToCompareTo
{
	// For each path in the paths to compare we get the status of all files which have changed within this path, and diff those files
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	[self dispatchToMercurialQueuedWithDescription:@"Generating Differences" process:^{
		NSMutableArray* statusArgs = [NSMutableArray arrayWithObjects:@"status", @"--modified", @"--added", @"--removed", @"--no-status", nil];
		if (versionToCompareTo)
			[statusArgs addObject:@"--rev" followedBy:versionToCompareTo];
		[statusArgs addObjectsFromArray:absolutePaths];
		ExecutionResult* statusResults = [TaskExecutions executeMercurialWithArgs:statusArgs fromRoot:rootPath  logging:eLoggingNone];
		if (IsEmpty(statusResults.outStr))
			return;
		NSArray* filesWhichHaveDifferences = [trimTrailingString(statusResults.outStr) componentsSeparatedByString:@"\n"];
		
		int numberOfFilesToDiff = [filesWhichHaveDifferences count];
		if (numberOfFilesToDiff > 20)
		{
			int choice = NSRunAlertPanel(@"Many Differences", @"There are %d files which will have changes, are you sure you want to display all these differences?", @"Show Differences", @"Cancel", nil, numberOfFilesToDiff);
			if (choice != NSAlertDefaultReturn)
				return;
		}
		
		DispatchGroup group = dispatch_group_create();

		ToolForDiffing diffTool = UseWhichToolForDiffingFromDefaults();
		[[AppController sharedAppController] preLaunchDiffToolIfNeeded:diffTool];
		NSString* cmd = [[AppController sharedAppController] scriptNameForDiffTool:diffTool];
		if ([[AppController sharedAppController] diffToolWantsGroupedFiles:diffTool])
		{
			dispatch_group_async(group, globalQueue(), ^{
				NSMutableArray* diffArgs = [NSMutableArray arrayWithObjects: cmd, @"--config", @"extensions.hgext.extdiff=", @"--cwd", rootPath, nil];
				if (versionToCompareTo)
					[diffArgs addObject:@"--rev" followedBy:versionToCompareTo];
				[diffArgs addObjectsFromArray:filesWhichHaveDifferences];
				
				TLMTask* task     = [[TLMTask alloc] init];
				NSString* hgPath = executableLocationHG();
				[task setLaunchPath: hgPath];
				[task setEnvironment:[TaskExecutions environmentForHg]];
				[task setArguments:diffArgs];
				[task launch];			// Start the process
			});
		}
		else
		{
			for (NSString* file in filesWhichHaveDifferences)
				if (IsNotEmpty(file))
					dispatch_group_async(group, globalQueue(), ^{
						NSMutableArray* diffArgs = [NSMutableArray arrayWithObjects: cmd, @"--config", @"extensions.hgext.extdiff=", @"--cwd", rootPath, nil];
						if (versionToCompareTo)
							[diffArgs addObject:@"--rev" followedBy:versionToCompareTo];
						[diffArgs addObject:file];
						
						TLMTask* task     = [[TLMTask alloc] init];
						NSString* hgPath = executableLocationHG();
						[task setLaunchPath: hgPath];
						[task setEnvironment:[TaskExecutions environmentForHg]];
						[task setArguments:diffArgs];
						[task launch];			// Start the process
					});
		}
		dispatchGroupWaitAndFinish(group);
	}];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Processes Management
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) dispatchToMercurialQueuedWithDescription:(NSString*)processDescription process:(BlockProcess)block
{
	NSNumber* processNum = [theProcessListController_ addProcessIndicator:processDescription];
	dispatch_async(mercurialTaskSerialQueue_, ^{
		block();
		[theProcessListController_ removeProcessIndicator:processNum];
	});
}



@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LoadedInitializationData
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation  LoadedInitializationData
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: SidebarSplitView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation SidebarSplitView

- (void) awakeFromNib
{
	[self setDelegate:self];
}

- (CGFloat)splitView:(NSSplitView*)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex	{ return 400.0; }
- (CGFloat)splitView:(NSSplitView*)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex	{ return 150.0; }
- (CGFloat)splitView:(NSSplitView*)splitView constrainSplitPosition:(CGFloat)proposedPosition		 ofSubviewAt:(NSInteger)dividerIndex	{ return constrainFloat(proposedPosition, 150.0, 400.0); }

- (void) splitView:(NSSplitView*)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{	
	NSRect sidebarGroupFrame	= [sidebarGroup frame];
	NSRect contentGroupFrame	= [contentGroup frame];
	sidebarGroupFrame.size.width = constrainFloat(sidebarGroupFrame.size.width, 150.0, 400.0);
	contentGroupFrame.size.width = self.frame.size.width - sidebarGroupFrame.size.width;
	contentGroupFrame.origin.x = sidebarGroupFrame.size.width;
	[contentGroup setFrame:contentGroupFrame];
	[sidebarGroup setFrame:sidebarGroupFrame];
	[self adjustSubviews];
}

- (NSRect) splitView:(NSSplitView*)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex
{
	return [resizeThumb convertRect:[resizeThumb bounds] toView:splitView]; 
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: RepositoryPaths
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation RepositoryPaths

@synthesize absolutePaths = absolutePaths_;
@synthesize rootPath = rootPath_;

+ (RepositoryPaths*) fromPaths:(NSArray*)theAbsolutePaths withRootPath:(NSString*)theRootPath
{
	RepositoryPaths* repositoryPaths = [RepositoryPaths alloc];
	[repositoryPaths setAbsolutePaths:theAbsolutePaths];
	[repositoryPaths setRootPath:theRootPath];
	return repositoryPaths;
}
+ (RepositoryPaths*) fromPath:(NSString*)absolutePath  withRootPath:(NSString*)theRootPath
{
	RepositoryPaths* repositoryPaths = [RepositoryPaths alloc];
	[repositoryPaths setAbsolutePaths:[NSArray arrayWithObject:absolutePath]];
	[repositoryPaths setRootPath:theRootPath];
	return repositoryPaths;
}
+ (RepositoryPaths*) fromRootPath:(NSString*)theRootPath { return [RepositoryPaths fromPath:theRootPath withRootPath:theRootPath]; }
@end
