//  DifferencesViewController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#include <Carbon/Carbon.h>
#import "DifferencesViewController.h"
#import "AppController.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "ResultsWindowController.h"
#import "LogTableView.h"
#import "LogEntry.h"
#import "FSViewer.h"
#import "FSViewerPaneCell.h"
#import "FSNodeInfo.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  DifferencesViewController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation DifferencesViewController
@synthesize myDocument;
@synthesize theDifferencesView;

- (DifferencesViewController*) initDifferencesViewControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"DifferencesView" owner:self];
	return self;
}

- (void) unload { [theDifferencesView unload]; }

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  DifferencesView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation DifferencesView

@synthesize showAddedFilesInBrowser      = showAddedFilesInBrowser_;
@synthesize showIgnoredFilesInBrowser    = showIgnoredFilesInBrowser_;
@synthesize showMissingFilesInBrowser    = showMissingFilesInBrowser_;
@synthesize showModifiedFilesInBrowser   = showModifiedFilesInBrowser_;
@synthesize showRemovedFilesInBrowser    = showRemovedFilesInBrowser_;
@synthesize showUntrackedFilesInBrowser  = showUntrackedFilesInBrowser_;
@synthesize showCleanFilesInBrowser		 = showCleanFilesInBrowser_;
@synthesize showUnresolvedFilesInBrowser = showUnresolvedFilesInBrowser_;
@synthesize showResolvedFilesInBrowser   = showResolvedFilesInBrowser_;
@synthesize myDocument;
@synthesize theFSViewer;







- (IBAction) openSplitViewPanesToDefaultHeights: (id)sender
{
}

- (id) initWithFrame:(NSRect)frameRect
{
	awake_ = NO;
	return [super initWithFrame:frameRect];
}

- (void) awakeFromNib
{
	@synchronized(self)
	{
		if (awake_)
			return;
		awake_ = YES;
	}

	myDocument = [parentController myDocument];
	[self openSplitViewPanesToDefaultHeights: self];

	[theFSViewer setAreNodesVirtual:YES];
	[mainSplitView setPosition:400 ofDividerAtIndex:0];
	
	[compareLogTableView setCanSelectIncompleteRevision:YES];
	
	NSString* fileName = [myDocument documentNameForAutosave];
	[baseLogTableView setAutosaveTableColumns:YES];
	[baseLogTableView setAutosaveName:fstr(@"File:%@:DifferencesBaseTableViewColumnPositions", fileName)];
	[baseLogTableView reloadData];
	[compareLogTableView setAutosaveTableColumns:YES];
	[compareLogTableView setAutosaveName:fstr(@"File:%@:DifferencesCompareTableViewColumnPositions", fileName)];
	[compareLogTableView reloadData];
	
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	if (rootPath)
		[theFSViewer refreshBrowserPaths:[RepositoryPaths fromRootPath:rootPath] finishingBlock:nil];
}

- (BOOL) controlsMainFSViewer	{ return NO; }

- (void) unload
{
	[self stopObserving];
	[theFSViewer unload];
	[baseLogTableView unload];
	[compareLogTableView unload];
	theFSViewer = nil;
	baseLogTableView = nil;
	compareLogTableView = nil;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) clearInspectorFieldValues
{
	[self validateButtons:self];
}


- (IBAction) validateButtons:(id)sender
{
//	BOOL valid = ([[self pathFieldValue] length] > 0) && ([[self nickNameFieldValue] length] > 0);
//	[addExistingDifferenceOkButton setEnabled:valid];
//	[configureExistingDifferenceOkButton setEnabled:valid];
//	[initNewDifferenceOkButton setEnabled:valid];
//	NSString* differenceDotHGDirPath = [pathFieldValue_ stringByAppendingPathComponent:@".hg"];
//	BOOL dir;
//	BOOL differenceExistsAtPath = [[NSFileManager defaultManager]fileExistsAtPath:differenceDotHGDirPath isDirectory:&dir];
//	BOOL differenceExists = differenceExistsAtPath && dir;
//
//	[differencePathBoxForConfigureExistingDifference setHidden:!differenceExists];
//	[differencePathBoxForAddExistingDifference setHidden:!differenceExists];
}


- (void) setButtonStatesToTheirPreferenceValues
{
	[self setShowAddedFilesInBrowser:ShowAddedFilesInBrowserFromDefaults()];
	[self setShowCleanFilesInBrowser:ShowCleanFilesInBrowserFromDefaults()];
	[self setShowIgnoredFilesInBrowser:ShowIgnoredFilesInBrowserFromDefaults()];
	[self setShowMissingFilesInBrowser:ShowMissingFilesInBrowserFromDefaults()];
	[self setShowModifiedFilesInBrowser:ShowModifiedFilesInBrowserFromDefaults()];
	[self setShowRemovedFilesInBrowser:ShowRemovedFilesInBrowserFromDefaults()];
	[self setShowResolvedFilesInBrowser:ShowResolvedFilesInBrowserFromDefaults()];
	[self setShowUntrackedFilesInBrowser:ShowUntrackedFilesInBrowserFromDefaults()];
	[self setShowUnresolvedFilesInBrowser:ShowUnresolvedFilesInBrowserFromDefaults()];
}

- (NSString*) revisionNumbers
{
	NSNumber* baseRev    = [baseLogTableView selectedRevision];
	NSNumber* compareRev = [compareLogTableView selectedRevision];
	if (IsEmpty(baseRev) || IsEmpty(compareRev))
		return nil;
	if ([compareRev isEqualTo:[compareLogTableView incompleteRevision]])
		return numberAsString(baseRev);
	return fstr(@"%@%:%@", baseRev, compareRev);
}

- (BOOL) equalRevisionsAreSelected
{
	NSNumber* baseRev    = [baseLogTableView selectedRevision];
	NSNumber* compareRev = [compareLogTableView selectedRevision];
	if (IsEmpty(baseRev) || IsEmpty(compareRev))
		return NO;
	return [baseRev isEqualToNumber:compareRev];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions Refresh   ----------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

// We should open the differences pane to show the differences of the rows selected in the history pane.
- (void) prepareToOpenDifferencesView
{
	[self refreshDifferencesView:self];
	LowHighPair pair  = [[[myDocument theHistoryView] logTableView] parentToHighestSelectedRevisions];
	NSNumber* lowRev  = (pair.lowRevision  != NSNotFound) ? intAsNumber(pair.lowRevision)  : [myDocument getHGParent1Revision];
	NSNumber* highRev = (pair.highRevision != NSNotFound) ? intAsNumber(pair.highRevision) : [myDocument getHGParent1Revision];
	NSInteger lowRow  = [baseLogTableView closestTableRowForRevision:lowRev];
	NSInteger highRow = [baseLogTableView closestTableRowForRevision:highRev];

	[baseLogTableView scrollToRevision:lowRev];

	if (lowRow != NSNotFound && highRow != NSNotFound)
	{
		dispatch_async(mainQueue(), ^{
			[compareLogTableView scrollToRangeOfRowsLow:lowRow high:lowRow];
			[compareLogTableView scrollRowToVisible:highRow];
			[compareLogTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:highRow] byExtendingSelection:NO];
		});		
	}
	else if (lowRow != NSNotFound)
		[compareLogTableView scrollToRevision:lowRev];
	else if (highRow != NSNotFound)
		[compareLogTableView scrollToRevision:highRev];
	
	[[myDocument mainWindow] makeFirstResponder:self];
	[self setButtonStatesToTheirPreferenceValues];
}


- (IBAction) refreshDifferencesView:(id)sender
{
	[baseLogTableView resetTable:self];
	[compareLogTableView resetTable:self];
}


- (void) didSwitchViewTo:(FSViewerNum)viewNumber
{
}


- (void) scrollToSelected
{
	[baseLogTableView scrollToSelected:self];
	[compareLogTableView scrollRowToVisible:[compareLogTableView selectedRow]];
}

- (IBAction) redisplayBrowser:(id)sender
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	if (rootPath)
		[theFSViewer refreshBrowserPaths:[RepositoryPaths fromRootPath:rootPath]  finishingBlock:nil];
}


- (void) updateCurrentPreviewImage
{
	// In order to improve performance, we only want to update the preview image if the user pauses for at
	// least a moment on a select node. This allows one to scroll through the nodes at a more acceptable pace.
	// First, we cancel the previous request so we don't get a whole bunch of them queued up.
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCurrentPreviewImageDoIt) object:nil];
	[self performSelector:@selector(updateCurrentPreviewImageDoIt) withObject:nil afterDelay:0.05];
}


- (void) updateCurrentPreviewImageDoIt
{
	// The browser selection might have changed update the quick look preview image if necessary. It would be really nice to have
	// a NSBrowserSelectionDidChangeNotification
	if ([myDocument quicklookPreviewIsVisible])
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Selecting revisions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) compareLowHighValue:(NSValue*)pairAsValue
{
	LowHighPair pair;
	[pairAsValue getValue:&pair];
	[self compareLow:intAsString(pair.lowRevision) toHigh:intAsString(pair.highRevision)];
}

- (void) compareLow:(NSString*)low toHigh:(NSString*)high
{
	LowHighPair pair = MakeLowHighPair(stringAsInt(low), stringAsInt(high));
	[baseLogTableView    scrollToRangeOfRevisions:pair];
	[baseLogTableView    scrollToRevision:intAsNumber(pair.lowRevision)];
	[compareLogTableView scrollToRangeOfRevisions:pair];
	[compareLogTableView scrollToRevision:intAsNumber(pair.highRevision)];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Contextual Menu actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuOpenSelectedFilesInFinder:(id)sender		{ [self differencesMenuOpenSelectedFilesInFinder:sender]; }
- (IBAction) mainMenuRevealSelectedFilesInFinder:(id)sender		{ [theFSViewer browserMenuRevealSelectedFilesInFinder:sender]; }
- (IBAction) mainMenuOpenTerminalHere:(id)sender				{ [theFSViewer browserMenuOpenTerminalHere:sender]; }


- (IBAction) mainMenuDiffSelectedFiles:(id)sender
{
	NSArray* selectedPaths = [theFSViewer absolutePathsOfChosenFiles];
	[myDocument viewDifferencesInCurrentRevisionFor:selectedPaths toRevision:[self revisionNumbers]];
}
- (IBAction) mainMenuDiffAllFiles:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:[self revisionNumbers]];
}
- (IBAction) toolbarDiffFiles:(id)sender
{
	if ([theFSViewer nodesAreChosen])
		[self mainMenuDiffSelectedFiles:sender];
	else
		[self mainMenuDiffAllFiles:sender];
}


- (IBAction) differencesMenuAnnotateBaseRevisionOfSelectedFiles:(id)sender
{
	NSArray* selectedFiles = [theFSViewer absolutePathsOfChosenFiles];
	NSArray* options = [[AppController sharedAppController] annotationOptionsFromDefaults];
	[myDocument primaryActionAnnotateSelectedFiles:selectedFiles withRevision:[baseLogTableView selectedCompleteRevision] andOptions:options];
}

- (IBAction) differencesMenuAnnotateCompareRevisionOfSelectedFiles:(id)sender
{
	NSArray* selectedFiles = [theFSViewer absolutePathsOfChosenFiles];
	NSArray* options = [[AppController sharedAppController] annotationOptionsFromDefaults];
	[myDocument primaryActionAnnotateSelectedFiles:selectedFiles withRevision:[compareLogTableView selectedCompleteRevision] andOptions:options];
}

- (IBAction) differencesMenuNoAction:(id)sender { }

- (IBAction) differencesMenuOpenSelectedFilesInFinder:(id)sender
{
	NSNumber* compareRev       = [compareLogTableView selectedRevision];
	if (IsEmpty(compareRev))
		return;
	BOOL isNotIncompleteRev    = ![compareRev isEqualTo:[compareLogTableView incompleteRevision]];
	NSString* compareChangeset = isNotIncompleteRev ? [[compareLogTableView selectedEntry] changeset] : nil;

	NSArray* nodes = [theFSViewer selectedNodes];
	for (FSNodeInfo* node in nodes)
	{
		// If the node has children its a directory which means we don't want to take a snapshot of it.
		if (IsNotEmpty([node childNodes]))
			continue;
		NSString* path = [node absolutePath];
		NSString* pathOfCachedCopy = [myDocument loadCachedCopyOfPath:path forChangeset:compareChangeset];
		if (pathOfCachedCopy)
			[[NSWorkspace sharedWorkspace] openFile:pathOfCachedCopy];
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

// Test to see if we can make a valid snapshot of at least some of the selected nodes in the differences view
- (BOOL) nodesAreChosenInFilesWhichAreSnapshotable
{
	NSArray* nodes = [theFSViewer chosenNodes];
	for (FSNodeInfo* node in nodes)
		if (IsEmpty([node childNodes]))
			if (bitsInCommon([node hgStatus], eHGStatusPresent))
				return YES;
	return NO;
}

- (BOOL) statusOfChosenPathsInFilesContain:(HGStatus)status		{ return bitsInCommon(status, [theFSViewer statusOfChosenPathsInFiles]); }
- (BOOL) repositoryHasFilesWhichContainStatus:(HGStatus)status	{ return bitsInCommon(status, [[theFSViewer rootNodeInfo] hgStatus]); }
- (BOOL) nodesAreChosenInFiles									{ return [theFSViewer nodesAreChosen]; }
- (BOOL) toolbarActionAppliesToFilesWith:(HGStatus)status		{ return ([self statusOfChosenPathsInFilesContain:status] || (![self nodesAreChosenInFiles] && [self repositoryHasFilesWhichContainStatus:status])); }

- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	SEL theAction = [anItem action];

	if (theAction == @selector(mainMenuDiffSelectedFiles:))				return [myDocument localRepoIsSelectedAndReady] && [self statusOfChosenPathsInFilesContain:eHGStatusModified];
	if (theAction == @selector(mainMenuDiffAllFiles:))					return [myDocument localRepoIsSelectedAndReady] && [self repositoryHasFilesWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(toolbarDiffFiles:))						return [myDocument localRepoIsSelectedAndReady] && [self toolbarActionAppliesToFilesWith:eHGStatusModified];
	
	if (theAction == @selector(mainMenuOpenSelectedFilesInFinder:))		return [myDocument localRepoIsSelectedAndReady] && [self nodesAreChosenInFilesWhichAreSnapshotable];
	if (theAction == @selector(mainMenuRevealSelectedFilesInFinder:))	return [myDocument localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuOpenTerminalHere:))				return [myDocument localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuDiffSelectedFiles:))				return [myDocument localRepoIsSelectedAndReady] && [self statusOfChosenPathsInFilesContain:eHGStatusModified];
	if (theAction == @selector(mainMenuDiffAllFiles:))					return [myDocument localRepoIsSelectedAndReady] && [self repositoryHasFilesWhichContainStatus:eHGStatusModified];

	if (theAction == @selector(differencesMenuAnnotateBaseRevisionOfSelectedFiles:))	return [myDocument localRepoIsSelectedAndReady] && [self nodesAreChosenInFilesWhichAreSnapshotable];
	if (theAction == @selector(differencesMenuAnnotateCompareRevisionOfSelectedFiles:))	return [myDocument localRepoIsSelectedAndReady] && [self nodesAreChosenInFilesWhichAreSnapshotable];
	if (theAction == @selector(differencesMenuOpenSelectedFilesInFinder:))				return [myDocument localRepoIsSelectedAndReady] && [self nodesAreChosenInFilesWhichAreSnapshotable];

	return NO;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate / Protocol Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (SEL) actionForDoubleClickEnum:(BrowserDoubleClickAction)theActionEnum
{
	switch (theActionEnum)
	{
		case eBrowserClickActionOpen:				return @selector(mainMenuOpenSelectedFilesInFinder:);
		case eBrowserClickActionRevealInFinder:		return @selector(mainMenuRevealSelectedFilesInFinder:);
		case eBrowserClickActionDiff:				return @selector(mainMenuDiffSelectedFiles:);
		case eBrowserClickActionAnnotate:			return @selector(differencesMenuAnnotateCompareRevisionOfSelectedFiles:);
		case eBrowserClickActionOpenTerminalHere:	return @selector(mainMenuOpenTerminalHere:);
		default:									return @selector(differencesMenuNoAction:);
	}
}

- (IBAction) browserAction:(id)browser	{ [self updateCurrentPreviewImage]; }
- (IBAction) browserDoubleAction:(id)browser
{
	SEL theAction = [self actionForDoubleClickEnum:[theFSViewer actionEnumForBrowserDoubleClick]];
	[[NSApplication sharedApplication] sendAction:theAction to:nil from:browser];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate / Protocol Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void)	logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[baseHeaderMessage setStringValue:fstr(@"Base Revision: %@", [baseLogTableView selectedRevision])];
	[compareHeaderMessage setStringValue:fstr(@"Compare Revision: %@", [compareLogTableView selectedRevision])];
	[self redisplayBrowser:self];
	[[myDocument mainWindow] makeFirstResponder:theLogTable];
}


- (NSArray*) statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath
{
	NSString* revNumbers = [self revisionNumbers];
	if (IsEmpty(revNumbers))
		return nil;

	// We need to handle the case when both revisions are the same. In this case its just doing a manifest and marking up the
	// output with a prefixed 'C ' to indicate clean.
	if ([self equalRevisionsAreSelected])
	{
		NSMutableArray* argsManifest = [NSMutableArray arrayWithObjects:@"manifest", @"--rev", numberAsString([baseLogTableView selectedRevision]), nil];
		ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsManifest  fromRoot:rootPath  logging:eLoggingNone];
		if ([results hasErrors])
		{
			[results logMercurialResult];
			return nil;
		}
		NSMutableArray* statusStrings = [[NSMutableArray alloc]init];
		NSArray* strings = [results.outStr componentsSeparatedByString:@"\n"];
		for (NSString* string in strings)
			[statusStrings addObject:fstr(@"C %@",string)];
		return statusStrings;
	}
	
	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", nil];

	if ([self showIgnoredFilesInBrowser])	[argsStatus addObject:@"--ignored"];
	if ([self showCleanFilesInBrowser])		[argsStatus addObject:@"--clean"];
	if ([self showUntrackedFilesInBrowser])	[argsStatus addObject:@"--unknown"];
	if ([self showAddedFilesInBrowser])		[argsStatus addObject:@"--added"];
	if ([self showRemovedFilesInBrowser])	[argsStatus addObject:@"--removed"];
	if ([self showMissingFilesInBrowser])	[argsStatus addObject:@"--deleted"];
	if ([self showModifiedFilesInBrowser])	[argsStatus addObject:@"--modified"];
	[argsStatus addObject:@"--rev" followedBy:revNumbers];
	[argsStatus addObjectsFromArray:absolutePaths];

	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	if ([results hasErrors])
	{
		[results logMercurialResult];
		return nil;
	}
	return [results.outStr componentsSeparatedByString:@"\n"];
}


- (NSArray*) resolveStatusLines:(NSArray*)absolutePaths  withRootPath:(NSString*)rootPath
{
	return [[NSArray alloc]init]; // We never list any resolved / unresolved files in the differences view
}


- (BOOL) writeRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard*)pasteboard
{
	NSNumber* compareRev       = [compareLogTableView selectedRevision];
	if (IsEmpty(compareRev))
		return NO;
	BOOL isNotIncompleteRev    = ![compareRev isEqualTo:[compareLogTableView incompleteRevision]];
	NSString* compareChangeset = isNotIncompleteRev ? [[compareLogTableView selectedEntry] changeset] : nil;

	NSMutableArray* pathsOfCachedItems = [[NSMutableArray alloc] init];
	for (NSInteger row = [rowIndexes firstIndex]; row != NSNotFound; row = [rowIndexes indexGreaterThanIndex: row])
	{
		FSNodeInfo* node = [[theFSViewer theFilesBrowser] itemAtRow:row inColumn:column];
		NSString* path = [node absolutePath];
		NSString* pathOfCachedCopy = [myDocument loadCachedCopyOfPath:path forChangeset:compareChangeset];
		[pathsOfCachedItems addObjectIfNonNil:pathOfCachedCopy];
	}

	[pasteboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
	[pasteboard setPropertyList:pathsOfCachedItems forType:NSFilenamesPboardType];
	
	return IsNotEmpty(pathsOfCachedItems) ? YES : NO;
}


- (CGFloat) firstPaneHeight:(NSSplitView*)theSplitView
{
	return [[[theSplitView subviews] objectAtIndex:0] frame].size.height;
}

- (void) splitViewDidResizeSubviews:(NSNotification*)aNotification
{
	CGFloat svOnePosition = [self firstPaneHeight:baseSV];
	CGFloat svTwoPosition = [self firstPaneHeight:compareSV ];
	
	if ([aNotification object] == baseSV)
		if (svOnePosition != svTwoPosition)
			[compareSV setPosition:svOnePosition ofDividerAtIndex:0];
	
	if ([aNotification object] == compareSV)
		if (svOnePosition != svTwoPosition)
			[baseSV setPosition:svTwoPosition ofDividerAtIndex:0];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quicklook Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfQuickLookPreviewItems		{ return [[theFSViewer absolutePathsOfSelectedFilesInBrowser] count]; }

- (NSArray*) quickLookPreviewItems
{
	if (![theFSViewer nodesAreSelected])
		return [NSArray array];

	NSNumber* compareRev       = [compareLogTableView selectedRevision];
	if (IsEmpty(compareRev))
		return [NSArray array];
	BOOL isNotIncompleteRev    = ![compareRev isEqualTo:[compareLogTableView incompleteRevision]];
	NSString* compareChangeset = isNotIncompleteRev ? [[compareLogTableView selectedEntry] changeset] : nil;

	NSMutableArray* quickLookPreviewItems = [[NSMutableArray alloc] init];
	NSArray* nodes = [theFSViewer selectedNodes];
	for (FSNodeInfo* node in nodes)
	{
		NSString* path = [node absolutePath];
		if (!path)
			continue;
		NSRect screenRect = [theFSViewer screenRectForNode:node];
		NSString* pathOfCachedCopy = [myDocument loadCachedCopyOfPath:path forChangeset:compareChangeset];
		if (pathOfCachedCopy)
			[quickLookPreviewItems addObject:[PathQuickLookPreviewItem previewItemForPath:pathOfCachedCopy withRect:screenRect]];
	}
	return quickLookPreviewItems;
}

- (void) keyDown:(NSEvent *)theEvent
{
    NSString* key = [theEvent charactersIgnoringModifiers];
    if ([key isEqual:@" "])
        [[self myDocument] togglePreviewPanel:self];
	else
        [super keyDown:theEvent];
}


@end
