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

#import "BrowserPaneController.h"
#import "HistoryPaneController.h"
#import "DifferencesPaneController.h"
#import "BackingPaneController.h"

#import "FSBrowser.h"
#import "FSBrowserCell.h"	// Do we need this here?
#import "FSNodeInfo.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "ProcessListController.h"

#import "AddLabelSheetController.h"
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
//#import "LNCStopwatch.h"
#import <QuartzCore/CIFilter.h>





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: RepositoryPaths
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation RepositoryPaths : NSObject

@synthesize absolutePaths = absolutePaths_;
@synthesize rootPath = rootPath_;

+ (RepositoryPaths*) fromPaths:(NSArray*)theAbsolutePaths withRootPath:(NSString*)theRootPath
{
	RepositoryPaths* repositoryPaths = [RepositoryPaths alloc];
	[repositoryPaths setAbsolutePaths:theAbsolutePaths];
	[repositoryPaths setRootPath:theRootPath];
	return repositoryPaths;
}
+ (RepositoryPaths*) fromPath:(NSString*)absolutePath  withRootPath:(NSString*)theRootPath;
{
	RepositoryPaths* repositoryPaths = [RepositoryPaths alloc];
	[repositoryPaths setAbsolutePaths:[NSArray arrayWithObject:absolutePath]];
	[repositoryPaths setRootPath:theRootPath];
	return repositoryPaths;
}
+ (RepositoryPaths*) fromRootPath:(NSString*)theRootPath { return [RepositoryPaths fromPath:theRootPath withRootPath:theRootPath]; }
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
@synthesize toolbarSearchField = toolbarSearchField_;
@synthesize toolbarSearchItem  = toolbarSearchItem_; 





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: ForcedTesting
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) testBrowserLoad:(id)sender;
{
	if ([sidebar_ selectedNodeIsLocalRepositoryRef])
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
		// loadedDataProxy_ = nil;		// We no longer need this have it collected
	}
	else
	{
		[self populateOutlineContents];
		connections_ = [[NSMutableDictionary alloc]init];
	}
	[self actionSwitchViewToBackingPane:self];
}

- (void) LogNotification:(NSNotification*)aNotification
{
	DebugLog(@"received notification: %@", [aNotification name]);
}


- (void) awakeFromNib
{
	[self observe:kRepositoryRootChanged		from:self  byCalling:@selector(repositoryRootDidChange)];
	[self observe:kUnderlyingRepositoryChanged	from:self  byCalling:@selector(underlyingRepositoryDidChange)];
	[self observe:NSWindowDidMoveNotification	from:mainWindow_  byCalling:@selector(recordWindowFrameToDefaults)];
	[self observe:NSWindowDidResizeNotification	from:mainWindow_  byCalling:@selector(recordWindowFrameToDefaults)];
	//[self observe:nil from:self byCalling:@selector(LogNotification:)];
	
	currentPane_ = -1;
	[informationAndActivityBox_ setContentView:informationBox_];
	[mainContentBox setWantsLayer:NO];		// We don't do cross fades since it speeds things up not to have the animation on. THe
											// frames are still animated when going from one view to another.
	[mainSplitView setPosition:200 ofDividerAtIndex:0];
	[[mainWindow_ windowController] setShouldCascadeWindows: NO];
	NSString* fileName = [self documentNameForAutosave];
	[sidebarAndInformation_ setAutosaveName:[NSString stringWithFormat:@"File:%@:LHSSidebarSplitPosition", fileName]];	

	// Test Mercurial is working by logging the status of a simple local directory where we know changes have occurred.
	if (NO)
	{
		NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", @"--cwd",@"/Users/jason/bin", nil];
		ExecutionResult* results = [TaskExecutions synchronouslyExecute:executableLocationHG() withArgs:argsStatus onTask:nil];
		if ([results hasErrors])
		{
			DebugLog(@"Calling mercurial is not working");
			return;
		}
		NSArray* parts = [trimString(results.outStr) componentsSeparatedByString:@"\n"];
		for (NSString* statusItem in parts)
			DebugLog(@"%@",statusItem);
	}
	
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

- (BrowserPaneController*) theBrowserPaneController
{
	if (theBrowserPaneController_)
		return theBrowserPaneController_;
	@synchronized(self)
	{
		if (!theBrowserPaneController_)
			theBrowserPaneController_ = [[BrowserPaneController alloc] initBrowserPaneControllerWithDocument:self];
	}
	return theBrowserPaneController_;
}

- (HistoryPaneController*) theHistoryPaneController
{
	if (theHistoryPaneController_)
		return theHistoryPaneController_;
	@synchronized(self)
	{
		if (!theHistoryPaneController_)
			theHistoryPaneController_ = [[HistoryPaneController alloc] initHistoryPaneControllerWithDocument:self];
	}
	return theHistoryPaneController_;
}

- (DifferencesPaneController*) theDifferencesPaneController
{
	if (theDifferencesPaneController_)
		return theDifferencesPaneController_;
	@synchronized(self)
	{
		if (!theDifferencesPaneController_)
			theDifferencesPaneController_ = [[DifferencesPaneController alloc] initDifferencesPaneControllerWithDocument:self];
	}
	return theDifferencesPaneController_;
}

- (BackingPaneController*) theBackingPaneController
{
	if (theBackingPaneController_)
		return theBackingPaneController_;
	@synchronized(self)
	{
		if (!theBackingPaneController_)
			theBackingPaneController_ = [[BackingPaneController alloc] initBackingPaneControllerWithDocument:self];
	}
	return theBackingPaneController_;
}


- (AddLabelSheetController*) theAddLabelSheetController
{
	if (theAddLabelSheetController_)
		return theAddLabelSheetController_;
	@synchronized(self)
	{
		if (!theAddLabelSheetController_)
			theAddLabelSheetController_ = [[AddLabelSheetController alloc] initAddLabelSheetControllerWithDocument:self];
	}
	return theAddLabelSheetController_;
}

- (CloneSheetController*) theCloneSheetController
{
	if (theCloneSheetController_)
		return theCloneSheetController_;
	@synchronized(self)
	{
		if (!theCloneSheetController_)
			theCloneSheetController_ = [[CloneSheetController alloc] initCloneSheetControllerWithDocument:self];
	}
	return theCloneSheetController_;
}

- (CollapseSheetController*) theCollapseSheetController
{
	if (theCollapseSheetController_)
		return theCollapseSheetController_;
	@synchronized(self)
	{
		if (!theCollapseSheetController_)
			theCollapseSheetController_ = [[CollapseSheetController alloc] initCollapseSheetControllerWithDocument:self];
	}
	return theCollapseSheetController_;
}

- (CommitSheetController*) theCommitSheetController
{
	if (theCommitSheetController_)
		return theCommitSheetController_;
	@synchronized(self)
	{
		if (!theCommitSheetController_)
			theCommitSheetController_ = [[CommitSheetController alloc] initCommitSheetControllerWithDocument:self];
	}
	return theCommitSheetController_;
}

- (ExportPatchesSheetController*) theExportPatchesSheetController
{
	if (theExportPatchesSheetController_)
		return theExportPatchesSheetController_;
	@synchronized(self)
	{
		if (!theExportPatchesSheetController_)
			theExportPatchesSheetController_ = [[ExportPatchesSheetController alloc] initExportPatchesSheetControllerWithDocument:self];
	}
	return theExportPatchesSheetController_;
}

- (HistoryEditSheetController*) theHistoryEditSheetController
{
	if (theHistoryEditSheetController_)
		return theHistoryEditSheetController_;
	@synchronized(self)
	{
		if (!theHistoryEditSheetController_)
			theHistoryEditSheetController_ = [[HistoryEditSheetController alloc] initHistoryEditSheetControllerWithDocument:self];
	}
	return theHistoryEditSheetController_;
}

- (ImportPatchesSheetController*) theImportPatchesSheetController
{
	if (theImportPatchesSheetController_)
		return theImportPatchesSheetController_;
	@synchronized(self)
	{
		if (!theImportPatchesSheetController_)
			theImportPatchesSheetController_ = [[ImportPatchesSheetController alloc] initImportPatchesSheetControllerWithDocument:self];
	}
	return theImportPatchesSheetController_;
}

- (IncomingSheetController*) theIncomingSheetController
{
	if (theIncomingSheetController_)
		return theIncomingSheetController_;
	@synchronized(self)
	{
		if (!theIncomingSheetController_)
			theIncomingSheetController_ = [[IncomingSheetController alloc] initIncomingSheetControllerWithDocument:self];
	}
	return theIncomingSheetController_;
}

- (LocalRepositoryRefSheetController*) theLocalRepositoryRefSheetController
{
	if (theLocalRepositoryRefSheetController_)
		return theLocalRepositoryRefSheetController_;
	@synchronized(self)
	{
		if (!theLocalRepositoryRefSheetController_)
			theLocalRepositoryRefSheetController_ = [[LocalRepositoryRefSheetController alloc] initLocalRepositoryRefSheetControllerWithDocument:self];
	}
	return theLocalRepositoryRefSheetController_;
}

- (MergeSheetController*) theMergeSheetController
{
	if (theMergeSheetController_)
		return theMergeSheetController_;
	@synchronized(self)
	{
		if (!theMergeSheetController_)
			theMergeSheetController_ = [[MergeSheetController alloc] initMergeSheetControllerWithDocument:self];
	}
	return theMergeSheetController_;
}

- (MoveLabelSheetController*) theMoveLabelSheetController
{
	if (theMoveLabelSheetController_)
		return theMoveLabelSheetController_;
	@synchronized(self)
	{
		if (!theMoveLabelSheetController_)
			theMoveLabelSheetController_ = [[MoveLabelSheetController alloc] initMoveLabelSheetControllerWithDocument:self];
	}
	return theMoveLabelSheetController_;
}

- (OutgoingSheetController*) theOutgoingSheetController
{
	if (theOutgoingSheetController_)
		return theOutgoingSheetController_;
	@synchronized(self)
	{
		if (!theOutgoingSheetController_)
			theOutgoingSheetController_ = [[OutgoingSheetController alloc] initOutgoingSheetControllerWithDocument:self];
	}
	return theOutgoingSheetController_;
}

- (PullSheetController*) thePullSheetController
{
	if (thePullSheetController_)
		return thePullSheetController_;
	@synchronized(self)
	{
		if (!thePullSheetController_)
			thePullSheetController_ = [[PullSheetController alloc] initPullSheetControllerWithDocument:self];
	}
	return thePullSheetController_;
}

- (PushSheetController*) thePushSheetController
{
	if (thePushSheetController_)
		return thePushSheetController_;
	@synchronized(self)
	{
		if (!thePushSheetController_)
			thePushSheetController_ = [[PushSheetController alloc] initPushSheetControllerWithDocument:self];
	}
	return thePushSheetController_;
}

- (RebaseSheetController*) theRebaseSheetController
{
	if (theRebaseSheetController_)
		return theRebaseSheetController_;
	@synchronized(self)
	{
		if (!theRebaseSheetController_)
			theRebaseSheetController_ = [[RebaseSheetController alloc] initRebaseSheetControllerWithDocument:self];
	}
	return theRebaseSheetController_;
}

- (RenameFileSheetController*) theRenameFileSheetController
{
	if (theRenameFileSheetController_)
		return theRenameFileSheetController_;
	@synchronized(self)
	{
		if (!theRenameFileSheetController_)
			theRenameFileSheetController_ = [[RenameFileSheetController alloc] initRenameFileSheetControllerWithDocument:self];
	}
	return theRenameFileSheetController_;
}

- (RevertSheetController*) theRevertSheetController
{
	if (theRevertSheetController_)
		return theRevertSheetController_;
	@synchronized(self)
	{
		if (!theRevertSheetController_)
			theRevertSheetController_ = [[RevertSheetController alloc] initRevertSheetControllerWithDocument:self];
	}
	return theRevertSheetController_;
}

- (ServerRepositoryRefSheetController*) theServerRepositoryRefSheetController
{
	if (theServerRepositoryRefSheetController_)
		return theServerRepositoryRefSheetController_;
	@synchronized(self)
	{
		if (!theServerRepositoryRefSheetController_)
			theServerRepositoryRefSheetController_ = [[ServerRepositoryRefSheetController alloc] initServerRepositoryRefSheetControllerWithDocument:self];
	}
	return theServerRepositoryRefSheetController_;
}

- (StripSheetController*) theStripSheetController
{
	if (theStripSheetController_)
		return theStripSheetController_;
	@synchronized(self)
	{
		if (!theStripSheetController_)
			theStripSheetController_ = [[StripSheetController alloc] initStripSheetControllerWithDocument:self];
	}
	return theStripSheetController_;
}

- (UpdateSheetController*) theUpdateSheetController
{
	if (theUpdateSheetController_)
		return theUpdateSheetController_;
	@synchronized(self)
	{
		if (!theUpdateSheetController_)
			theUpdateSheetController_ = [[UpdateSheetController alloc] initUpdateSheetControllerWithDocument:self];
	}
	return theUpdateSheetController_;
}


- (void) unloadBrowserPaneView
{
	[theBrowserPaneController_ unload];
	theBrowserPaneController_ = nil;
}

- (void) unloadHistoryPaneView
{
	[theHistoryPaneController_ unload];
	theHistoryPaneController_ = nil;
}

- (void) unloadDifferencesPaneView
{
	[theDifferencesPaneController_ unload];
	theDifferencesPaneController_ = nil;
}





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
	NSString* originKeyForAutoSave = [NSString stringWithFormat:@"File:%@:originPos", fileName];
	NSString* rectKeyForAutoSave   = [NSString stringWithFormat:@"File:%@:windowPosForView%d", fileName, currentPane_];
	NSRect frm = [mainWindow_ frame];
	NSString* topLeftOriginString = NSStringFromPoint(NSMakePoint(NSMinX(frm), NSMaxY(frm)));	// Record window origin top left
	NSString* rectString = NSStringFromRect(frm);
	[[NSUserDefaults standardUserDefaults] setObject:topLeftOriginString forKey:originKeyForAutoSave];
	[[NSUserDefaults standardUserDefaults] setObject:rectString forKey:rectKeyForAutoSave];
}

- (NSRect) getWindowFrameFromDefaults
{
	NSString* fileName = [self documentNameForAutosave];
	NSString* originKeyForAutoSave = [NSString stringWithFormat:@"File:%@:originPos", fileName];
	NSString* rectKeyForAutoSave   = [NSString stringWithFormat:@"File:%@:windowPosForView%d", fileName, currentPane_];
	NSString* topLeftOriginString  = [[NSUserDefaults standardUserDefaults] objectForKey:originKeyForAutoSave];
	NSString* rectString           = [[NSUserDefaults standardUserDefaults] objectForKey:rectKeyForAutoSave];
	if (!topLeftOriginString || !rectString)
		return NSZeroRect;
	NSPoint topLeftOrigin = NSPointFromString([[NSUserDefaults standardUserDefaults] objectForKey:originKeyForAutoSave]);	// This is the window top left
	NSRect rect = NSRectFromString( [[NSUserDefaults standardUserDefaults] objectForKey:rectKeyForAutoSave]);
	rect.origin.x = topLeftOrigin.x;
	rect.origin.y = topLeftOrigin.y - rect.size.height;
	return rect;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Pane switching
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSView*) paneView:(PaneViewNum)paneNum
{
	switch (paneNum)
	{
		case eBrowserPaneView:		return [[self theBrowserPaneController] view];
		case eHistoryPaneView:		return [[self theHistoryPaneController] view];
		case eDifferencesPaneView:	return [[self theDifferencesPaneController] view];
		case eBackingPaneView:		return [[self theBackingPaneController] view];
		default:					return nil;
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
	newWindowFrame.origin.y -= (newContentFrame.size.height - oldContentFrame.size.height);
	return newWindowFrame;
}


// This sets the search field into a disabled state when not enabled and when enabled sets the enabled state, visually enables it,
// and restores the search term and label.
- (void) setSearchFieldEnabled:(BOOL)enabled value:(NSString*)value caption:(NSString*)caption
{
	CIFilter* grayFilter = [CIFilter filterWithName:@"CIWhitePointAdjust" keysAndValues:@"inputColor", [CIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.6], nil];
	NSArray* disabledAttributes = [NSArray arrayWithObject:grayFilter];
	NSArray* noAttributes = [NSArray array];
	NSString* nonNilValue = value ? value : @"";
	[toolbarSearchField_ setStringValue:enabled ? nonNilValue : @""];
	[[toolbarSearchField_ layer] setFilters: (enabled ? noAttributes : disabledAttributes)];
	[toolbarSearchItem_		setLabel: (enabled && IsNotEmpty(nonNilValue)) ? caption : @"Search"];
	[toolbarSearchField_	setEnabled:enabled];
	[toolbarSearchItem_		setEnabled:enabled];
}


- (PaneViewNum) currentPane								{ return currentPane_; }
- (void) setCurrentPane:(PaneViewNum)newPaneNum
{
	if (currentPane_ == newPaneNum)
		return;

	BOOL ended = [mainWindow_ makeFirstResponder:mainWindow_];
	if (!ended)
		{ PlayBeep(); return; }
	
	// Specific handling for some panes
	switch (newPaneNum)
	{
		case eDifferencesPaneView:		[[self theDifferencesPaneController] openDifferencesPane:self];		break;
		case eHistoryPaneView:			[[self theHistoryPaneController] refreshHistoryPane:self];			break;
	}
	
	NSString* searchTerm    = theHistoryPaneController_ ? [[[self theHistoryPaneController] logTableView] theSearchFilter] : @"";
	NSString* searchCaption = theHistoryPaneController_ ? [[self theHistoryPaneController] searchCaption] : @"Search";
	[self setSearchFieldEnabled:(newPaneNum == eHistoryPaneView) value:searchTerm caption:searchCaption];
	
	
	currentPane_ = newPaneNum;
	NSView* newView = [self paneView:newPaneNum];
	
	NSRect newFrame = [self newWindowFrameWhenSwitchingContentTo:[newView frame]];	// Figure out new frame size	
	[NSAnimationContext beginGrouping];												// Using an animation grouping because we may be changing the duration

	// With the shift key down, do slow-mo animation
	if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
	    [[NSAnimationContext currentContext] setDuration:1.0];
	
	// Call the animator instead of the view / window directly to switch the view out.
	[[mainContentBox animator] setContentView:newView];	
	[[mainWindow_ animator] setFrame:newFrame display:YES];

	// After the animation has finished the selected rows in the logtables might actually be out of visible range due to the
	// resizing of the frame. Thus at the end of the animation make sure you can see the current selection.
	switch (newPaneNum)
	{
		case eDifferencesPaneView:	[NSTimer scheduledTimerWithTimeInterval:[[NSAnimationContext currentContext] duration] target:[self theDifferencesPaneController]	selector:@selector(scrollToSelected) userInfo:nil repeats:NO]; break;
		case eHistoryPaneView:		[NSTimer scheduledTimerWithTimeInterval:[[NSAnimationContext currentContext] duration] target:[self theHistoryPaneController]		selector:@selector(scrollToSelected) userInfo:nil repeats:NO]; break;
	}
		
	[NSAnimationContext endGrouping];
	[self recordWindowFrameToDefaults];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)	showingBrowserPane								{ return currentPane_ == eBrowserPaneView; }
- (BOOL)	showingHistoryPane								{ return currentPane_ == eHistoryPaneView; }
- (BOOL)	showingDifferencesPane							{ return currentPane_ == eDifferencesPaneView; }
- (BOOL)	showingBackingPane								{ return currentPane_ == eBackingPaneView; }
- (BOOL)	showingBrowserOrHistoryPane						{ return currentPane_ == eBrowserPaneView || currentPane_ == eHistoryPaneView; }
- (BOOL)	showingBrowserOrDifferencesPane					{ return currentPane_ == eBrowserPaneView || currentPane_ == eDifferencesPaneView; }
- (BOOL)	showingBrowserOrHistoryOrDifferencesPane		{ return currentPane_ == eBrowserPaneView || currentPane_ == eHistoryPaneView || currentPane_ == eDifferencesPaneView; }

- (IBAction) actionSwitchViewToBrowserPane:(id)sender		{ [self setCurrentPane:eBrowserPaneView]; }
- (IBAction) actionSwitchViewToBackingPane:(id)sender		{ [self setCurrentPane:eBackingPaneView]; }
- (IBAction) actionSwitchViewToDifferencesPane:(id)sender	{ [self setCurrentPane:eDifferencesPaneView]; }
- (IBAction) actionSwitchViewToHistoryPane:(id)sender		{ [self setCurrentPane:eHistoryPaneView]; }





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
- (void) windowDidEndSheet:(NSNotification*)notification		{ showingSheet_ = NO;  }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Undo handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) removeAllUndoActionsForDocument
{
	NSUndoManager* undo = [sidebar_ undoManager];
	[undo removeAllActionsWithTarget:sidebar_];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Action Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) repositoryIsSelectedAndReady			{ return !showingSheet_ && ([[sidebar_ chosenNode] isLocalRepositoryRef] ? YES : NO); }
- (BOOL) repositoryOrServerIsSelectedAndReady	{ return !showingSheet_ && ([[sidebar_ chosenNode] isRepositoryRef] ? YES : NO); }
- (BOOL) validateAndSwitchMenuForCommitAllFiles:(NSMenuItem*)menuItem
{
	if (!menuItem)
		return NO;
	[menuItem setTitle:([[self repositoryData] inMergeState] ? @"Commit Merged Files..." : @"Commit All Files...")];
	return [self repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
}
- (BOOL) validateAndSwitchMenuForCommitSelectedFiles:(NSMenuItem*)menuItem
{
	if (!menuItem)
		return NO;
	BOOL inMergeState = [[self repositoryData] inMergeState];
	[menuItem setTitle: inMergeState ? @"Commit Merged Files..." : @"Commit Selected Files..."];
	return inMergeState ? [self repositoryHasFilesWhichContainStatus:eHGStatusCommittable] : ([self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusCommittable] && [self showingBrowserPane]);
}


- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem, NSObject>)anItem
{
	SEL theAction = [anItem action];
	
	if (theAction == @selector(actionSwitchViewToBrowserPane:))			return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(actionSwitchViewToHistoryPane:))			return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(actionSwitchViewToDifferencesPane:))		return [self repositoryIsSelectedAndReady];

	// Files
	if (theAction == @selector(mainMenuCommitSelectedFiles:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane] && [self validateAndSwitchMenuForCommitSelectedFiles:DynamicCast(NSMenuItem, anItem)];
	if (theAction == @selector(mainMenuCommitAllFiles:))				return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane] && [self validateAndSwitchMenuForCommitAllFiles:DynamicCast(NSMenuItem, anItem)];
	if (theAction == @selector(mainMenuDiffSelectedFiles:))				return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(mainMenuDiffAllFiles:))					return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane] && [self repositoryHasFilesWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(mainMenuAddRenameRemoveSelectedFiles:))	return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusAddableOrRemovable];
	if (theAction == @selector(mainMenuAddRenameRemoveAllFiles:))		return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self repositoryHasFilesWhichContainStatus:eHGStatusAddableOrRemovable];
	// ------
	if (theAction == @selector(mainMenuRevertSelectedFiles:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusChangedInSomeWay];
	if (theAction == @selector(mainMenuRevertAllFiles:))				return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane] && [self repositoryHasFilesWhichContainStatus:eHGStatusChangedInSomeWay];
	if (theAction == @selector(mainMenuRevertSelectedFilesToVersion:))	return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self nodesAreChosenInBrowser];
	if (theAction == @selector(mainMenuRevertAllFilesToVersion:))		return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane];
	if (theAction == @selector(mainMenuDeleteSelectedFiles:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self nodesAreChosenInBrowser];
	if (theAction == @selector(mainMenuUntrackSelectedFiles:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusInRepository];
	if (theAction == @selector(mainMenuAddSelectedFiles:))				return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusAddable];
	if (theAction == @selector(mainMenuRenameSelectedFile:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusInRepository] && [self singleFileIsChosenInBrowser];
	// ------
	if (theAction == @selector(mainMenuRemergeSelectedFiles:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusSecondary];
	if (theAction == @selector(mainMenuMarkResolvedSelectedFiles:))		return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusUnresolved];
	// ------
	if (theAction == @selector(mainMenuIgnoreSelectedFiles:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusNotIgnored];
	if (theAction == @selector(mainMenuUnignoreSelectedFiles:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusIgnored];
	if (theAction == @selector(mainMenuAnnotateSelectedFiles:))			return [self repositoryIsSelectedAndReady] && [self showingBrowserPane] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusInRepository];
	// ------
	if (theAction == @selector(mainMenuRollbackCommit:))				return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane];
	
	
	// Repository actions
	if (theAction == @selector(mainMenuCloneRepository:))				return [self repositoryOrServerIsSelectedAndReady];
	if (theAction == @selector(mainMenuPushToRepository:))				return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(mainMenuPullFromRepository:))			return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(mainMenuIncomingFromRepository:))		return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(mainMenuOutgoingToRepository:))			return [self repositoryIsSelectedAndReady];
	// ------
	if (theAction == @selector(mainMenuUpdateRepository:))				return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane];
	if (theAction == @selector(mainMenuUpdateRepositoryToVersion:))		return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(mainMenuMergeWith:))						return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane] && [[self repositoryData]hasMultipleOpenHeads] && ![self repositoryHasFilesWhichContainStatus:eHGStatusSecondary];
	// ------
	if (theAction == @selector(mainMenuCollapseChangesets:))			return [self repositoryIsSelectedAndReady] && [self showingHistoryPane] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuHistoryEditChangesets:))			return [self repositoryIsSelectedAndReady] && [self showingHistoryPane] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuStripChangesets:))				return [self repositoryIsSelectedAndReady] && [self showingHistoryPane] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuRebaseChangesets:))				return [self repositoryIsSelectedAndReady] && [self showingHistoryPane] && AllowHistoryEditingOfRepositoryFromDefaults();
	// ------
	if (theAction == @selector(mainMenuManifestOfCurrentVersion:))		return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane];
	if (theAction == @selector(mainMenuAddLabelToCurrentRevision:))		return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane];
	// ------
	if (theAction == @selector(sidebarMenuAddLocalRepositoryRef:))		return !showingSheet_;
	if (theAction == @selector(sidebarMenuAddServerRepositoryRef:))		return !showingSheet_;
	if (theAction == @selector(sidebarMenuAddNewSidebarGroupItem:))		return !showingSheet_;
	if (theAction == @selector(sidebarMenuRemoveSidebarItem:))			return !showingSheet_ && ([sidebar_ chosenNode] ? YES : NO);
	if (theAction == @selector(sidebarMenuConfigureLocalRepositoryRef:))return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(sidebarMenuConfigureServerRepositoryRef:))return [self repositoryOrServerIsSelectedAndReady];
	// ------
	if (theAction == @selector(sidebarMenuRevealRepositoryInFinder:))	return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(sidebarMenuOpenTerminalHere:))			return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(actionTestListingItem:))					return !showingSheet_ && ([sidebar_ selectedNode] ? YES : NO);
	
	if (theAction == @selector(browserMenuOpenSelectedFilesInFinder:))	return [self repositoryIsSelectedAndReady] && [self nodesAreChosenInBrowser];
	if (theAction == @selector(browserMenuRevealSelectedFilesInFinder:))return [self repositoryIsSelectedAndReady];
	if (theAction == @selector(browserMenuOpenTerminalHere:))			return [self repositoryIsSelectedAndReady];

	
	// File Menu
	if (theAction == @selector(mainMenuImportPatches:))					return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane];
	if (theAction == @selector(mainMenuExportPatches:))					return [self repositoryIsSelectedAndReady] && [self showingBrowserOrHistoryPane];
	
	if (theAction == @selector(mainMenuNoAction:))						return !showingSheet_ && ([sidebar_ selectedNode] ? YES : NO);
	
	
	// subclass of NSDocument, so invoke super's implementation
	return [super validateUserInterfaceItem:anItem];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Repository Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction)	mainMenuManifestOfCurrentVersion:(id)sender	{ [self primaryActionDisplayManifestForVersion:[self getHGParent1Revision]]; }
- (IBAction)	mainMenuPushToRepository:(id)sender			{ [[self thePushSheetController]		openSheet:sender]; }
- (IBAction)	mainMenuPullFromRepository:(id)sender		{ [[self thePullSheetController]		openSheet:sender]; }
- (IBAction)	mainMenuIncomingFromRepository:(id)sender	{ [[self theIncomingSheetController]	openSheet:sender]; }
- (IBAction)	mainMenuOutgoingToRepository:(id)sender		{ [[self theOutgoingSheetController]	openSheet:sender]; }

- (IBAction) mainMenuCloneRepository:(id)sender
{
	SidebarNode* node = [sidebar_ chosenNode];
	if (!node)
		return;
	
	[[self theCloneSheetController] openCloneSheetWithSource:node];
}





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

		loadedDataProxy_->loadedSidebar     = [archiver decodeObjectForKey:@"sidebar"];
		loadedDataProxy_->loadedConnections = [archiver decodeObjectForKey:@"connections"];
		loadedDataProxy_->loadedCurrentPane = [archiver decodeIntForKey:@"currentPane"];

		if (!loadedDataProxy_->loadedConnections)
			loadedDataProxy_->loadedConnections = [[NSMutableDictionary alloc]init];
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
// MARK: RepositoryData Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) initializeRepositoryData
{
	@synchronized(self)
	{
		DebugLog(@"Initializing log entry collection");
		NSString* rootPath = [self absolutePathOfRepositoryRoot];
		repositoryData_ = [[RepositoryData alloc] initWithRootPath:rootPath andDocument:self];
	}
	[self postNotificationWithName:kRepositoryDataIsNew];
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Suspension / Resumption of events
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) eventsAreSuspended
{
	return eventsSuspensionCount_ > 0;
}

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
		[self refreshBrowserPaths:changedPaths resumeEventsWhenFinished:YES];
		return;
	}

	BOOL postNotification = [queueForUnderlyingRepositoryChangedViaEvents_ operationQueued];
	[queueForUnderlyingRepositoryChangedViaEvents_ resumeQueue];
	if (postNotification)
		[queueForUnderlyingRepositoryChangedViaEvents_ 
			addBlockOperation: ^{[self postNotificationWithName:kUnderlyingRepositoryChanged];}
					withDelay: 1.5];
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
	if (!delay)
		return [TaskExecutions  executeMercurialWithArgs:args  fromRoot:rootPath];

	__block ExecutionResult* results;
	[self delayEventsUntilFinishBlock:^{
		results = [TaskExecutions  executeMercurialWithArgs:args  fromRoot:rootPath];
	}];
	return results;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSEvents
// -----------------------------------------------------------------------------------------------------------------------------------------

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
	BOOL postNotification = NO;
	for (NSString* path in eventPaths)
		if (pathContainedIn(rootDotHGDirPath, path))
			postNotification = YES;
		else
			[filteredPaths addObject:path];

	if (postNotification)
		[queueForUnderlyingRepositoryChangedViaEvents_ addBlockOperation:^{
			[self postNotificationWithName:kUnderlyingRepositoryChanged]; }];
	
	NSArray* canonicalized = pruneContainedPaths(filteredPaths);
	DebugLog(@"Some file paths changed. File events are %@.\nThe raw paths are %@. The canonicalized paths are %@", [self eventsAreSuspended]? @"suspended":@"acted on immediately", eventPaths, canonicalized);
	if (![self eventsAreSuspended])
		[self refreshBrowserPaths:canonicalized resumeEventsWhenFinished:NO];
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
		[[self theBrowser] markPathsDirty:[RepositoryPaths fromPaths:paths withRootPath:rootPath]];		// Mark the paths as dirty and redisplay them...
	}
}


- (IBAction)	actionTestListingItem:(id)sender
{
	
	return;
	DebugLog(@"Currently watching Paths:%@", [events_ isWatchingPaths] ? @"Yes":@"No");
	NSMutableArray* watchedPaths  = [events_ watchedPaths];
	DebugLog(@"The currently watched  Paths : %@", watchedPaths);
	DebugLog(@"streamDescription %@", [events_ streamDescription]);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Version Information
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) getHGTipChangeset			{ return [[self repositoryData] getHGTipChangeset]; }
- (NSString*) getHGParentsChangeset		{ return [[self repositoryData] getHGParentsChangeset]; }
- (NSString*) getHGParentsChangesets	{ return [[self repositoryData] getHGParentsChangesets]; }
- (NSString*) getHGTipRevision			{ return [[self repositoryData] getHGTipRevision]; }
- (NSString*) getHGParent1Revision		{ return [[self repositoryData] getHGParent1Revision]; }
- (NSString*) getHGParentsRevisions		{ return [[self repositoryData] getHGParentsRevisions]; }
- (BOOL)      isCurrentRevisionTip		{ return [[self repositoryData] isCurrentRevisionTip]; }
- (BOOL)	  inMergeState				{ return [[self repositoryData] inMergeState]; }
- (NSInteger) computeNumberOfRevisions	{ return [[self repositoryData] computeNumberOfRevisions]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Path and Selection Operations
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)			aRepositoryIsSelected					{ return [[sidebar_ selectedNode] isLocalRepositoryRef]; }
- (NSString*)		absolutePathOfRepositoryRoot			{ SidebarNode* repo = [sidebar_ selectedNode]; return [repo isLocalRepositoryRef] ? [repo path] : nil; }
- (NSString*)		selectedRepositoryShortName				{ SidebarNode* repo = [sidebar_ selectedNode]; return [repo isLocalRepositoryRef]  ? [repo shortName]  : nil; }
- (NSString*)		selectedRepositoryPath					{ SidebarNode* repo = [sidebar_ selectedNode]; return [repo isRepositoryRef] ? [repo path] : nil; }
- (SidebarNode*)	selectedRepositoryRepositoryRef			{ SidebarNode* repo = [sidebar_ selectedNode]; return [repo isRepositoryRef] ? repo : nil; }
- (NSArray*)		absolutePathOfRepositoryRootAsArray		{ return [NSArray arrayWithObject:[self absolutePathOfRepositoryRoot]]; }

- (FSBrowser*)		theBrowser								{ return [[self theBrowserPaneController] theBrowser]; }
- (FSNodeInfo*)		rootNodeInfo							{ return [[self theBrowser] rootNodeInfo]; }
- (FSNodeInfo*)		nodeForPath:(NSString*)absolutePath		{ return [[self rootNodeInfo] nodeForPathFromRoot:absolutePath]; }
- (BOOL)			singleFileIsChosenInBrowser				{ return [[self theBrowser] singleFileIsChosenInBrowser]; }
- (BOOL)			nodesAreChosenInBrowser					{ return [[self theBrowser] nodesAreChosen]; }
- (HGStatus)		statusOfChosenPathsInBrowser			{ return [[self theBrowser] statusOfChosenPathsInBrowser]; }
- (NSArray*)		absolutePathsOfBrowserChosenFiles		{ return [[self theBrowser] absolutePathsOfBrowserChosenFiles]; }
- (NSString*)		enclosingDirectoryOfBrowserChosenFiles	{ return [[self theBrowser] enclosingDirectoryOfBrowserChosenFiles]; }

- (BOOL) pathsAreSelectedInBrowserWhichContainStatus:(HGStatus)status	{ return bitsInCommon(status, [[self theBrowser] statusOfChosenPathsInBrowser]); }
- (BOOL) repositoryHasFilesWhichContainStatus:(HGStatus)status			{ return bitsInCommon(status, [[[self theBrowser] rootNodeInfo] hgStatus]); }

- (NSArray*) filterPaths:(NSArray*)absolutePaths byBitfield:(HGStatus)status
{
	FSNodeInfo* theRoot = [self rootNodeInfo];
	NSMutableArray* remainingPaths = [[NSMutableArray alloc] init];
	for (NSString* path in absolutePaths)
	{
		FSNodeInfo* node = [theRoot nodeForPathFromRoot:path];
		BOOL includePath = bitsInCommon([node hgStatus], status);
		if (includePath)
			[remainingPaths addObject:path];
	}
	return remainingPaths;
}


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
// MARK: Notifications
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) repositoryRootDidChange
{
	SidebarNode* node = [sidebar_ selectedNode];
	
	if (![node isExistentLocalRepositoryRef])
	{
		repositoryData_ = nil;
		[self actionSwitchViewToBackingPane:self];
		return;
	}

	if ([node isLocalRepositoryRef] && [self showingBackingPane])
		[self actionSwitchViewToBrowserPane:self];
	
	[self initializeRepositoryData];

	if ([node isLocalRepositoryRef])
		[self setupEventlistener];
}


- (void) underlyingRepositoryDidChange
{
	[self initializeRepositoryData];
}


- (IBAction) searchFieldChanged:(id)sender
{
	if ([self showingHistoryPane])
	{
		HistoryPaneController* hpc = [self theHistoryPaneController];
		LogTableView* logTableView = [hpc logTableView];
		[logTableView setTheSearchFilter:[[self toolbarSearchField] stringValue]];
		[logTableView resetTable:hpc];
		[hpc refreshHistoryPane:sender];
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Refresh / Regenrate Browser
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) refreshBrowserPaths:(NSArray*)absoluteChangedPaths  { [self refreshBrowserPaths:absoluteChangedPaths resumeEventsWhenFinished:NO]; }
- (void) refreshBrowserPaths:(NSArray*)absoluteChangedPaths  resumeEventsWhenFinished:(BOOL)resume
{
	[[self theBrowser] refreshBrowserPaths:[RepositoryPaths fromPaths:absoluteChangedPaths withRootPath:[self absolutePathOfRepositoryRoot]] resumeEventsWhenFinished:resume];
}


- (IBAction) refreshBrowserContent:(id)sender
{
	BOOL repoIsSelected = [self aRepositoryIsSelected];
	if (!repoIsSelected)
		return;
		
	NSString* rootPath = [self absolutePathOfRepositoryRoot];	
	[[self theBrowser] refreshBrowserPaths:[RepositoryPaths fromRootPath:rootPath] resumeEventsWhenFinished:NO];
	[self setupEventlistener];
}


- (NSArray*) statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath
{
	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", nil];
	if (ShowIgnoredFilesInBrowserFromDefaults())	[argsStatus addObject:@"--ignored"];
	if (ShowCleanFilesInBrowserFromDefaults())		[argsStatus addObject:@"--clean"];
	if (ShowUnknownFilesInBrowserFromDefaults())	[argsStatus addObject:@"--unknown"];
	if (ShowAddedFilesInBrowserFromDefaults())		[argsStatus addObject:@"--added"];
	if (ShowRemovedFilesInBrowserFromDefaults())	[argsStatus addObject:@"--removed"];
	if (ShowMissingFilesInBrowserFromDefaults())	[argsStatus addObject:@"--deleted"];
	if (ShowModifiedFilesInBrowserFromDefaults())	[argsStatus addObject:@"--modified"];
	[argsStatus addObjectsFromArray:absolutePaths];

	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone onTask:nil];

	if ([results.errStr length] > 0)
	{
		[TaskExecutions logMercurialResult:results];
		// for an error rather than warning fail by returning nil. Maybe later we will return error codes.
		if ([results hasErrors])
			return  nil;			
	}
	return [results.outStr componentsSeparatedByString:@"\n"];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  File Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction)	mainMenuImportPatches:(id)sender				{ [[self theImportPatchesSheetController] openImportPatchesSheet:sender]; }
- (IBAction)	mainMenuExportPatches:(id)sender				{ [[self theExportPatchesSheetController] openExportPatchesSheetWithSelectedRevisions:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) browserMenuOpenSelectedFilesInFinder:(id)sender	{ [[self theBrowser] browserMenuOpenSelectedFilesInFinder:sender]; }
- (IBAction) browserMenuRevealSelectedFilesInFinder:(id)sender	{ [[self theBrowser] browserMenuRevealSelectedFilesInFinder:sender]; }
- (IBAction) browserMenuOpenTerminalHere:(id)sender				{ [[self theBrowser] browserMenuOpenTerminalHere:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Standard  Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuCommitSelectedFiles:(id)sender				{ [[self theCommitSheetController] openCommitSheetWithSelectedFiles:sender]; }
- (IBAction) mainMenuCommitAllFiles:(id)sender					{ [[self theCommitSheetController] openCommitSheetWithAllFiles:sender]; }

- (IBAction) mainMenuAddRenameRemoveSelectedFiles:(id)sender	{ [self primaryActionAddRenameRemoveFiles:[self absolutePathsOfBrowserChosenFiles]]; }
- (IBAction) mainMenuAddRenameRemoveAllFiles:(id)sender			{ [self primaryActionAddRenameRemoveFiles:[self absolutePathOfRepositoryRootAsArray]]; }

- (IBAction) mainMenuDiffSelectedFiles:(id)sender				{ [self viewDifferencesInCurrentRevisionFor:[self absolutePathsOfBrowserChosenFiles] toRevision:nil]; }		// nil indicates the current revision
- (IBAction) mainMenuDiffAllFiles:(id)sender					{ [self viewDifferencesInCurrentRevisionFor:[self absolutePathOfRepositoryRootAsArray] toRevision:nil]; }	// nil indicates the current revision





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Selected Files Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuRevertSelectedFiles:(id)sender				{ [self primaryActionRevertFiles:[self absolutePathsOfBrowserChosenFiles] toVersion:nil]; }
- (IBAction) mainMenuRevertAllFiles:(id)sender					{ [self primaryActionRevertFiles:[self absolutePathOfRepositoryRootAsArray] toVersion:nil]; }
- (IBAction) mainMenuRevertSelectedFilesToVersion:(id)sender	{ [[self theRevertSheetController] openRevertSheetWithSelectedFiles:sender]; }
- (IBAction) mainMenuRevertAllFilesToVersion:(id)sender			{ [[self theRevertSheetController] openRevertSheetWithAllFiles:sender]; }
- (IBAction) mainMenuRenameSelectedFile:(id)sender				{ [[self theRenameFileSheetController] openRenameFileSheet:sender]; }


- (IBAction) mainMenuDeleteSelectedFiles:(id)sender
{
	if (![self nodesAreChosenInBrowser])
		{ PlayBeep(); DebugLog(@"No files selected to remove"); return; }
	
	NSArray* theSelectedFiles = [self absolutePathsOfBrowserChosenFiles];
	if (DisplayWarningForFileDeletionFromDefaults())
	{
		int result = RunCriticalAlertPanelWithSuppression( @"Delete Selected Files", @"Are you sure you want to move the selected files to the trash?", @"Delete Files", @"Cancel", MHGDisplayWarningForFileDeletion);
		if (result != NSAlertFirstButtonReturn)
			return;
	}
	
	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Delete Files" process:^{
		[self registerPendingRefresh:theSelectedFiles visuallyDirtifyPaths:NO];
		NSString* rootPath = [self absolutePathOfRepositoryRoot];
		moveFilesToTheTrash(theSelectedFiles);
		[self refreshBrowserPaths:parentPaths(theSelectedFiles,rootPath) resumeEventsWhenFinished:NO];
	}];
}


- (IBAction) mainMenuAddSelectedFiles:(id)sender
{
	NSArray* paths = [self absolutePathsOfBrowserChosenFiles];
	if ([paths count] <= 0)
		{ PlayBeep(); DebugLog(@"No files selected to add"); return; }

	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	
	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Add Selected Files" process:^{
		[self registerPendingRefresh:paths];
		NSMutableArray* argsAdd = [NSMutableArray arrayWithObjects:@"add", nil];
		[argsAdd addObjectsFromArray:paths];
		[self delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:argsAdd  fromRoot:rootPath];
			[self addToChangedPathsDuringSuspension:paths];
		}];
	}];
}


- (IBAction) mainMenuUntrackSelectedFiles:(id)sender
{
	if (![self nodesAreChosenInBrowser])
		{ PlayBeep(); DebugLog(@"No files selected to untrack"); return; }
	
	NSArray* theSelectedFiles = [self absolutePathsOfBrowserChosenFiles];
	if (DisplayWarningForUntrackingFilesFromDefaults())
	{
		NSString* subMessage = @"Are you sure you want to stop tracking the selected files?";
		int result = RunCriticalAlertPanelWithSuppression(@"Untrack Selected Files", subMessage, @"Stop Tracking Files", @"Cancel", MHGDisplayWarningForUntrackingFiles);
		if (result != NSAlertFirstButtonReturn)
			return;
	}
	
	[self removeAllUndoActionsForDocument];
	NSArray* pathsForHGToUntrack = [self filterPaths:theSelectedFiles byBitfield:eHGStatusInRepository];
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
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: All Files Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuUpdateRepository:(id)sender				{ [self primaryActionUpdateFilesToVersion:@"tip" withCleanOption:NO]; }
- (IBAction) mainMenuUpdateRepositoryToVersion:(id)sender		{ [[self theUpdateSheetController] openUpdateSheetWithCurrentRevision:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Merging
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuMergeWith:(id)sender						{ [[self theMergeSheetController] openMergeSheet:sender]; }
- (IBAction) mainMenuRemergeSelectedFiles:(id)sender			{ [self primaryActionRemerge:[self absolutePathsOfBrowserChosenFiles] withConfirmation:YES]; }
- (IBAction) mainMenuMarkResolvedSelectedFiles:(id)sender		{ [self primaryActionMarkResolved:[self absolutePathsOfBrowserChosenFiles] withConfirmation:NO]; }
- (IBAction) mainMenuAddLabelToCurrentRevision:(id)sender		{ [[self theAddLabelSheetController] openAddLabelSheet:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Proxies for SideBar Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) sidebarMenuAddLocalRepositoryRef:(id)sender		{ return [sidebar_ sidebarMenuAddLocalRepositoryRef:sender]; }
- (IBAction) sidebarMenuAddServerRepositoryRef:(id)sender		{ return [sidebar_ sidebarMenuAddServerRepositoryRef:sender]; }
- (IBAction) sidebarMenuConfigureLocalRepositoryRef:(id)sender	{ return [sidebar_ sidebarMenuConfigureLocalRepositoryRef:sender]; }
- (IBAction) sidebarMenuConfigureServerRepositoryRef:(id)sender	{ return [sidebar_ sidebarMenuConfigureServerRepositoryRef:sender]; }
- (IBAction) sidebarMenuAddNewSidebarGroupItem:(id)sender		{ return [sidebar_ sidebarMenuAddNewSidebarGroupItem:sender]; }
- (IBAction) sidebarMenuRemoveSidebarItem:(id)sender			{ return [sidebar_ sidebarMenuRemoveSidebarItem:sender]; }
- (IBAction) sidebarMenuRevealRepositoryInFinder:(id)sender		{ return [sidebar_ sidebarMenuRevealRepositoryInFinder:sender]; }
- (IBAction) sidebarMenuOpenTerminalHere:(id)sender				{ return [sidebar_ sidebarMenuOpenTerminalHere:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: History Altering Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuCollapseChangesets:(id)sender				{ [[self theCollapseSheetController] openCollapseSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuHistoryEditChangesets:(id)sender			{ [[self theHistoryEditSheetController] openHistoryEditSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuStripChangesets:(id)sender					{ [[self theStripSheetController] openStripSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuRebaseChangesets:(id)sender				{ [[self theRebaseSheetController] openRebaseSheetWithSelectedRevisions:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Viewing Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuIgnoreSelectedFiles:(id)sender
{
	NSString* root = [self absolutePathOfRepositoryRoot];
	NSString* hgignorePath = [root stringByAppendingPathComponent:@".hgignore"];
	NSArray* theSelectedFiles = [self absolutePathsOfBrowserChosenFiles];
	if ([theSelectedFiles count] < 1)
		return;

	[self removeAllUndoActionsForDocument];
	[self dispatchToMercurialQueuedWithDescription:@"Ignoring Files" process:^{
		NSMutableArray* pathsToRefresh = [NSMutableArray arrayWithArray:theSelectedFiles];
		[pathsToRefresh addObject:hgignorePath];
		[self registerPendingRefresh:pathsToRefresh];
		NSMutableString* hgignoreContents = [NSMutableString stringWithContentsOfFile:hgignorePath encoding:NSUTF8StringEncoding error:nil];
		if (!hgignoreContents)
			hgignoreContents = [[NSMutableString alloc] init];
		
		for (NSString* file in theSelectedFiles)
		{
			NSString* rootRelativeFIle = pathDifference(root, file);
			NSRange range = [hgignoreContents rangeOfString:rootRelativeFIle];
			if (range.location == NSNotFound)
				[hgignoreContents appendFormat:@"%@\n",rootRelativeFIle];
		}
		[hgignoreContents writeToFile:hgignorePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
		[self refreshBrowserPaths:pathsToRefresh resumeEventsWhenFinished:NO];
	}];
}


- (IBAction) mainMenuUnignoreSelectedFiles:(id)sender;
{
	NSString* root = [self absolutePathOfRepositoryRoot];
	NSString* hgignorePath = [root stringByAppendingPathComponent:@".hgignore"];
	NSArray* theSelectedFiles = [self absolutePathsOfBrowserChosenFiles];
	if ([theSelectedFiles count] < 1)
		return;

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
				NSString* rootRelativeFIle = pathDifference(root, file);
				hgignoreContents = [hgignoreContents stringByReplacingOccurrencesOfString:rootRelativeFIle withString:@""];
			}
			
			hgignoreContents = [hgignoreContents stringByReplacingOccurrencesOfString:@"\n\n" withString:@"\n"];
			[hgignoreContents writeToFile:hgignorePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
			
			[self refreshBrowserPaths:pathsToRefresh resumeEventsWhenFinished:NO];
		}
	}];
}


- (IBAction) mainMenuAnnotateSelectedFiles:(id)sender
{
	NSArray* selectedFiles = [self absolutePathsOfBrowserChosenFiles];
	NSMutableArray* options = [[NSMutableArray alloc] init];
	
	if (DefaultAnnotationOptionChangesetFromDefaults())		[options addObject:@"--changeset"];
	if (DefaultAnnotationOptionDateFromDefaults())			[options addObject:@"--date"];
	if (DefaultAnnotationOptionFollowFromDefaults())		[options addObject:@"--follow"];
	if (DefaultAnnotationOptionLineNumberFromDefaults())	[options addObject:@"--line-number"];
	if (DefaultAnnotationOptionNumberFromDefaults())		[options addObject:@"--number"];
	if (DefaultAnnotationOptionTextFromDefaults())			[options addObject:@"--text"];
	if (DefaultAnnotationOptionUserFromDefaults())			[options addObject:@"--user"];
	
	[self primaryActionAnnotateSelectedFiles:selectedFiles withRevision:[self getHGParent1Revision] andOptions:options];
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

- (BOOL) primaryActionRevertFiles:(NSArray*)absolutePaths toVersion:(NSString*)version
{
	NSArray* filteredPaths = version ? absolutePaths : [self filterPaths:absolutePaths byBitfield:eHGStatusChangedInSomeWay];
	
	if ([filteredPaths count] <= 0)
		{ PlayBeep(); DebugLog(@"No files selected to revert"); return NO; }
	
	if (DisplayWarningForRevertingFilesFromDefaults())
	{
		BOOL pathsAreRootPath = [[filteredPaths lastObject] isEqual:[self absolutePathOfRepositoryRoot]];
		NSString* mainMessage = [NSString stringWithFormat:@"Reverting %@ Files", pathsAreRootPath ? @"All" : @"Selected"];
		NSString* subMessage  = [NSString stringWithFormat: @"Are you sure you want to revert %@ in the repository “%@” to %@? (Any modified files will be moved to the trash)",
								 pathsAreRootPath ? @"all files" : @"the selected files",
								 [self selectedRepositoryShortName],
								 version ? [NSString stringWithFormat:@"revision “%@”", version] :
								 ([self isCurrentRevisionTip] ? @"the latest revision" : @"current revision")];
		
		int result = RunCriticalAlertPanelOptionsWithSuppression(mainMessage, subMessage, @"Revert", @"Cancel", @"Options...", MHGDisplayWarningForRevertingFiles);
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
			[argsRevert addObject:@"--rev"];
			[argsRevert addObject:version];
		}
		[argsRevert addObjectsFromArray:filteredPaths];
		NSArray* theParentPaths = parentPaths(filteredPaths,rootPath);
		
		[self delayEventsUntilFinishBlock:^{
			[TaskExecutions  executeMercurialWithArgs:argsRevert  fromRoot:rootPath];
			if (HandleGeneratedOrigFilesFromDefaults() == eMoveOrigFilesToTrash)
				[self pruneDotOrigFiles:theParentPaths];
			[self addToChangedPathsDuringSuspension:parentPaths(theParentPaths,rootPath)];
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
			NSString* messageString = [NSString stringWithFormat:@"Results of Add Remove Files in “%@”",  [self selectedRepositoryShortName]];
			NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
			[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:@"AddRemove Results"];
		}		
	}];
	return YES;
}


- (BOOL) primaryActionUpdateFilesToVersion:(NSString*)version withCleanOption:(BOOL)clean
{
	BOOL containsChangedFiles = [self repositoryHasFilesWhichContainStatus:eHGStatusCommittable];
	if (DisplayWarningForUpdatingFromDefaults() || [self repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		NSString* mainMessage = @"Updating All Files";
		NSString* subMessage  = [NSString stringWithFormat: @"Are you sure you want to update the repository “%@” to revision “%@”?",
								 [self selectedRepositoryShortName],
								 version];
		if (containsChangedFiles)
			subMessage = [NSString stringWithFormat:@"There are uncommitted changes. %@", subMessage];
		
		NSAlert* alert = NewAlertPanel(mainMessage, subMessage, @"Update", @"Cancel", @"Options...");
		[updateAlertAccessoryCleanCheckBox setState:clean];
		[updateAlertAccessoryAlertSuppressionCheckBox setState:NO];
		[updateAlertAccessoryAlertSuppressionCheckBox setHidden:!DisplayWarningForUpdatingFromDefaults()];
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
	[self dispatchToMercurialQueuedWithDescription:@"Updating Files" process:^{
		NSMutableArray* argsUpdate = [NSMutableArray arrayWithObjects:@"update", @"--rev", version, nil];
		if (clean)
			[argsUpdate addObject:@"--clean"];

		ExecutionResult* results = [self executeMercurialWithArgs:argsUpdate  fromRoot:rootPath whileDelayingEvents:YES];

		if (DisplayResultsOfUpdatingFromDefaults())
		{
			NSString* messageString = [NSString stringWithFormat:@"Results of Updating “%@”",  [self selectedRepositoryShortName]];
			NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
			[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:@"Update Results"];
		}
	}];
	return YES;
}


- (BOOL) primaryActionMergeWithVersion:(NSString*)mergeVersion andOptions:(NSArray*)options withConfirmation:(BOOL)confirm
{
	if (confirm && DisplayWarningForMergingFromDefaults())
	{
		NSString* mainMessage = [NSString stringWithFormat:@"Merging %@", mergeVersion];
		NSString* subMessage  = [NSString stringWithFormat: @"Are you sure you want to merge version %@ into the %@ in the repository “%@”?",
								 mergeVersion,
								 ([self isCurrentRevisionTip] ? @"latest revision" : @"current revision"),
								 [self selectedRepositoryShortName]];
		
		int result = RunCriticalAlertPanelOptionsWithSuppression(mainMessage, subMessage, @"Merge", @"Cancel", @"Options...", MHGDisplayWarningForMerging);
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

	NSMutableArray* argsMerge = [NSMutableArray arrayWithObjects:@"merge", @"--rev", mergeVersion, nil];
	[argsMerge addObjectsFromArray:options];

	if (UseFileMergeForMergeFromDefaults())
	{
		[argsMerge addObject:@"--config" followedBy:@"merge-tools.filemerge.args= $local $other -ancestor $base -merge $output"];
		[argsMerge addObject:@"--config" followedBy: fstr(@"merge-tools.filemerge.executable=%@/opendiff-w.sh",[[NSBundle mainBundle] resourcePath]) ];
		[argsMerge addObject:@"--config" followedBy: @"merge-tools.priority=100"];	// Use FileMerge with a priority of 100. This should be more than the other tools.
	}

	__block ExecutionResult* results;
	[self delayEventsUntilFinishBlock:^{
		results = [TaskExecutions executeMercurialWithArgs:argsMerge  fromRoot:rootPath];
		[self addToChangedPathsDuringSuspension:rootPathAsArray];
	}];
	
	if ([results hasErrors])
		return NO;

	switch (AfterMergeSwitchToFromDefaults())
	{
		case eAfterMergeSwitchToBrowser:	[self actionSwitchViewToBrowserPane:self]; break;
		case eAfterMergeSwitchToHistory:	[self actionSwitchViewToHistoryPane:self]; break;
	}

	if (DisplayResultsOfMergingFromDefaults())
	{
		NSString* messageString = [NSString stringWithFormat:@"Results of Merging “%@”",  [self selectedRepositoryShortName]];
		NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
		[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:@"Merge Results"];
	}
	
	if (DisplayWarningForPostMergeFromDefaults())
		NSRunAlertPanel(@"Merged Files", @"You now need to examine the merged files, resolve and conflicts, and finally commit all the merged files to complete the merge.", @"Ok", nil, nil);

	switch (AfterMergeDoFromDefaults())
	{
		case eAfterMergeDoNothing:			break;
		case eAfterMergeOpenCommit:			[self mainMenuCommitAllFiles:self];
	}


	return YES;
}


- (BOOL) primaryActionRemerge:(NSArray*)absolutePaths withConfirmation:(BOOL)confirm
{
	if (confirm && DisplayWarningForMergingFromDefaults())
	{
		NSString* what = ([absolutePaths count] == 1) ? [[absolutePaths lastObject] lastPathComponent] : @"the selected files";
		NSString* mainMessage = [NSString stringWithFormat:@"Remerging %@", what];
		NSString* subMessage  = [NSString stringWithFormat: @"Are you sure you want to throw away any changes you have made to %@ and remerge versions %@ in the repository “%@”?",
								 what,
								 [self getHGParentsRevisions],
								 [self selectedRepositoryShortName]];

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
		NSString* mainMessage = [NSString stringWithFormat:@"Marking %@ as resolved", what];
		NSString* subMessage  = [NSString stringWithFormat: @"Are you sure you want to mark %@ as resolved in the repository “%@”?",
								 what,
								 [self selectedRepositoryShortName]];

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


- (void) primaryActionDisplayManifestForVersion:(NSString*)version
{
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSString* thisRepositoryName = [self selectedRepositoryShortName];
	[self dispatchToMercurialQueuedWithDescription:@"Generating Manifest" process:^{
		NSMutableArray* argsManifest = [NSMutableArray arrayWithObjects:@"manifest", @"--rev", version, nil];
		ExecutionResult* results = [self executeMercurialWithArgs:argsManifest  fromRoot:rootPath  whileDelayingEvents:YES];
		NSString* messageString = [NSString stringWithFormat:@"Manifest of “%@” revision “%@”", thisRepositoryName, version];
		NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
		[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:@"Manifest Results"];
	}];
}


- (void) primaryActionAnnotateSelectedFiles:(NSArray*)absolutePaths withRevision:(NSString*)version andOptions:(NSArray*)options
{
	NSString* rootPath = [self absolutePathOfRepositoryRoot];
	NSArray* filteredPaths = [self filterPaths:absolutePaths byBitfield:eHGStatusInRepository];
	
	int numberOfFilesToAnnotate = [filteredPaths count];
	if (numberOfFilesToAnnotate < 1)
		{ PlayBeep(); return; }
	if (numberOfFilesToAnnotate > 10)
	{
		int choice = NSRunAlertPanel(@"Many Annotations", @"There are %d files which will have annotations, are you sure you want to display all these annotations?", @"Show Annotations", @"Cancel", nil, numberOfFilesToAnnotate);
		if (choice != NSAlertDefaultReturn)
			return;
	}

	[self dispatchToMercurialQueuedWithDescription:@"Generating Annotations" process:^{
		DispatchGroup group = dispatch_group_create();
		for (NSString* file in filteredPaths)
			dispatch_group_async(group, globalQueue(), ^{
				NSMutableArray* argsAnnotate = [NSMutableArray arrayWithObjects:@"annotate", @"--rev", version, nil];
				[argsAnnotate addObjectsFromArray:options];
				[argsAnnotate addObject:file];
				ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsAnnotate  fromRoot:rootPath];
				NSString* fileName = [file lastPathComponent];
				NSString* messageString = [NSString stringWithFormat:@"Annotations of “%@” for revision “%@”", fileName, version];
				NSString* windowTitle   = [NSString stringWithFormat:@"%@ : %@ Annotations", fileName, version];
				NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
				[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:windowTitle];
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
		NSArray* filesWhichHaveDifferences = [trimTrailingString(statusResults.outStr) componentsSeparatedByString:@"\n"];
		
		int numberOfFilesToDiff = [filesWhichHaveDifferences count];
		if (numberOfFilesToDiff > 20)
		{
			int choice = NSRunAlertPanel(@"Many Differences", @"There are %d files which will have changes, are you sure you want to display all these differences?", @"Show Differences", @"Cancel", nil, numberOfFilesToDiff);
			if (choice != NSAlertDefaultReturn)
				return;
		}
		
		DispatchGroup group = dispatch_group_create();

		for (NSString* file in filesWhichHaveDifferences)
			dispatch_group_async(group, globalQueue(), ^{
				NSString* cmd;
				if (UseWhichToolForDiffingFromDefaults() == eUseFileMergeForDiffs)
					cmd = @"opendiff";
				else if (IsNotEmpty(ToolNameForDiffingFromDefaults()))
					cmd = ToolNameForDiffingFromDefaults();
				else
					cmd = @"diff";

				NSMutableArray* diffArgs = [NSMutableArray arrayWithObjects: cmd, @"--cwd", rootPath, nil];
				if (UseWhichToolForDiffingFromDefaults() == eUseFileMergeForDiffs)
				{
					NSString* absPathToDiffScript = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"fmdiff.sh"];
					NSString* cmdOverride = [NSString stringWithFormat:@"extdiff.cmd.opendiff=%@",absPathToDiffScript];
					[diffArgs addObject:@"--config" followedBy:cmdOverride];
					[diffArgs addObject:@"--config" followedBy:@"extensions.hgext.extdiff="];
				}
				if (versionToCompareTo)
					[diffArgs addObject:@"--rev" followedBy:versionToCompareTo];
				[diffArgs addObject:file];
				
				NSTask* task     = [[NSTask alloc] init];
				NSString* hgPath = executableLocationHG();
				[task setLaunchPath: hgPath];
				[task setArguments:diffArgs];
				[task launch];			// Start the process
			});
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





#pragma mark -
@implementation  LoadedInitializationData
@end
