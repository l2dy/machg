//  DifferencesViewController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#include <Carbon/Carbon.h>
#import "DifferencesViewController.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "ResultsWindowController.h"
#import "LogTableView.h"
#import "FSBrowser.h"
#import "FSBrowserCell.h"
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
@synthesize showUnknownFilesInBrowser    = showUnknownFilesInBrowser_;
@synthesize showCleanFilesInBrowser		 = showCleanFilesInBrowser_;
@synthesize showUnresolvedFilesInBrowser = showUnresolvedFilesInBrowser_;
@synthesize showResolvedFilesInBrowser   = showResolvedFilesInBrowser_;
@synthesize myDocument;
@synthesize theBrowser;







- (IBAction) openSplitViewPanesToDefaultHeights: (id)sender
{
}


- (void) awakeFromNib
{
	myDocument = [parentController myDocument];
	[self openSplitViewPanesToDefaultHeights: self];

	// Tell the browser to send us messages when it is clicked.
	[theBrowser setTarget:self];
	[theBrowser setAction:@selector(browserSingleClick:)];
	[theBrowser setDoubleAction:@selector(browserDoubleClick:)];
	[theBrowser setAreNodesVirtual:YES];
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
		[theBrowser refreshBrowserPaths:[RepositoryPaths fromRootPath:rootPath] resumeEventsWhenFinished:NO];
}

- (void) unload
{
	[self stopObserving];
	[theBrowser unload];
	[baseLogTableView unload];
	[compareLogTableView unload];
	theBrowser = nil;
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
	[self setShowUnknownFilesInBrowser:ShowUnknownFilesInBrowserFromDefaults()];
	[self setShowUnresolvedFilesInBrowser:ShowUnresolvedFilesInBrowserFromDefaults()];
}

- (NSString*) revisionNumbers
{
	NSString* baseRev    = [baseLogTableView selectedRevision];
	NSString* compareRev = [compareLogTableView selectedRevision];
	if (IsEmpty(baseRev) || IsEmpty(compareRev))
		return nil;
	if ([compareRev isEqualTo:[compareLogTableView incompleteRevision]])
		return baseRev;	
	return fstr(@"%@%:%@", baseRev, compareRev);
}




// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions Refresh   ----------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

// We should open the differences pane to show the differences of the rows selected in the history pane.
- (IBAction) openDifferencesView:(id)sender
{
	[self refreshDifferencesView:sender];
	LowHighPair pair  = [[[myDocument theHistoryView] logTableView] parentToHighestSelectedRevisions];
	NSString* lowRev  = (pair.lowRevision != NSNotFound)  ? intAsString(pair.lowRevision)  : [myDocument getHGParent1Revision];
	NSString* highRev = (pair.highRevision != NSNotFound) ? intAsString(pair.highRevision) : [myDocument getHGParent1Revision];
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
	
	[self setButtonStatesToTheirPreferenceValues];
}


- (IBAction) refreshDifferencesView:(id)sender
{
	[baseLogTableView resetTable:self];
	[compareLogTableView resetTable:self];
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
		[theBrowser refreshBrowserPaths:[RepositoryPaths fromRootPath:rootPath]  resumeEventsWhenFinished:NO];
}

- (void) updateCurrentPreviewImage
{
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
	[baseLogTableView    scrollToRevision:intAsString(pair.lowRevision)];
	[compareLogTableView scrollToRangeOfRevisions:pair];
	[compareLogTableView scrollToRevision:intAsString(pair.highRevision)];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Override Menu Item Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) differencesMenuOpenSelectedFilesInFinder:(id)sender	{ [theBrowser browserMenuOpenSelectedFilesInFinder:sender]; }
- (IBAction) differencesMenuRevealSelectedFilesInFinder:(id)sender	{ [theBrowser browserMenuRevealSelectedFilesInFinder:sender]; }
- (IBAction) differencesMenuOpenTerminalHere:(id)sender				{ [theBrowser browserMenuOpenTerminalHere:sender]; }
- (IBAction) differencesMenuDiffSelectedFiles:(id)sender
{
	NSArray* selectedPaths = [theBrowser absolutePathsOfBrowserChosenFiles];
	[myDocument viewDifferencesInCurrentRevisionFor:selectedPaths toRevision:[self revisionNumbers]];
}
- (IBAction) differencesMenuDiffAllFiles:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:[self revisionNumbers]];
}

- (IBAction)	mainMenuDiffSelectedFiles:(id)sender
{
	[self differencesMenuDiffSelectedFiles:sender];
}


- (IBAction) differencesMenuAnnotateSelectedFiles:(id)sender
{
	NSArray* selectedFiles = [theBrowser absolutePathsOfBrowserChosenFiles];
	NSMutableArray* options = [[NSMutableArray alloc] init];
	
	if (DefaultAnnotationOptionChangesetFromDefaults())		[options addObject:@"--changeset"];
	if (DefaultAnnotationOptionDateFromDefaults())			[options addObject:@"--date"];
	if (DefaultAnnotationOptionFollowFromDefaults())		[options addObject:@"--follow"];
	if (DefaultAnnotationOptionLineNumberFromDefaults())	[options addObject:@"--line-number"];
	if (DefaultAnnotationOptionNumberFromDefaults())		[options addObject:@"--number"];
	if (DefaultAnnotationOptionTextFromDefaults())			[options addObject:@"--text"];
	if (DefaultAnnotationOptionUserFromDefaults())			[options addObject:@"--user"];
	
	[myDocument primaryActionAnnotateSelectedFiles:selectedFiles withRevision:[compareLogTableView selectedRevision] andOptions:options];
}


- (IBAction) differencesMenuNoAction:(id)sender { }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) pathsAreSelectedInBrowserWhichContainStatus:(HGStatus)status	{ return bitsInCommon(status, [theBrowser statusOfChosenPathsInBrowser]); }
- (BOOL) repositoryHasFilesWhichContainStatus:(HGStatus)status			{ return bitsInCommon(status, [[theBrowser rootNodeInfo] hgStatus]); }
- (BOOL) nodesAreChosenInBrowser										{ return [theBrowser nodesAreChosen]; }
- (BOOL) toolbarActionAppliesToFilesWith:(HGStatus)status				{ return ([self pathsAreSelectedInBrowserWhichContainStatus:status] || (![self nodesAreChosenInBrowser] && [self repositoryHasFilesWhichContainStatus:status])); }

- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	SEL theAction = [anItem action];
	
	if (theAction == @selector(differencesMenuOpenSelectedFilesInFinder:))		return [myDocument repositoryIsSelectedAndReady] && [self nodesAreChosenInBrowser];
	if (theAction == @selector(differencesMenuRevealSelectedFilesInFinder:))	return [myDocument repositoryIsSelectedAndReady];
	if (theAction == @selector(differencesMenuOpenTerminalHere:))				return [myDocument repositoryIsSelectedAndReady];
	if (theAction == @selector(differencesMenuDiffSelectedFiles:))				return [myDocument repositoryIsSelectedAndReady] && [myDocument showingDifferencesView] && [self pathsAreSelectedInBrowserWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(differencesMenuDiffAllFiles:))					return [myDocument repositoryIsSelectedAndReady] && [myDocument showingDifferencesView] && [self repositoryHasFilesWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(mainMenuDiffSelectedFiles:))
		return YES;
	
	return [myDocument validateUserInterfaceItem:anItem];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate / Protocol Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (SEL) actionForDoubleClickEnum:(BrowserDoubleClickAction)theActionEnum
{
	switch (theActionEnum)
	{
		case eBrowserClickActionOpen:				return @selector(differencesMenuOpenSelectedFilesInFinder:);
		case eBrowserClickActionRevealInFinder:		return @selector(differencesMenuRevealSelectedFilesInFinder:);
		case eBrowserClickActionDiff:				return @selector(differencesMenuDiffSelectedFiles:);
		case eBrowserClickActionAnnotate:			return @selector(differencesMenuAnnotateSelectedFiles:);
		case eBrowserClickActionOpenTerminalHere:	return @selector(differencesMenuOpenTerminalHere:);
		default:									return @selector(differencesMenuNoAction:);
	}
}

- (IBAction) browserSingleClick:(id)browser	{ }
- (IBAction) browserDoubleClick:(id)browser	{ SEL theAction = [self actionForDoubleClickEnum:[theBrowser actionEnumForBrowserDoubleClick]]; [self performSelector:theAction withObject:browser]; }





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

	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", nil];

	if ([self showIgnoredFilesInBrowser])	[argsStatus addObject:@"--ignored"];
	if ([self showCleanFilesInBrowser])		[argsStatus addObject:@"--clean"];
	if ([self showUnknownFilesInBrowser])	[argsStatus addObject:@"--unknown"];
	if ([self showAddedFilesInBrowser])		[argsStatus addObject:@"--added"];
	if ([self showRemovedFilesInBrowser])	[argsStatus addObject:@"--removed"];
	if ([self showMissingFilesInBrowser])	[argsStatus addObject:@"--deleted"];
	if ([self showModifiedFilesInBrowser])	[argsStatus addObject:@"--modified"];
	[argsStatus addObject:@"--rev" followedBy:revNumbers];
	[argsStatus addObjectsFromArray:absolutePaths];

	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	if ([results hasErrors])
	{
		[TaskExecutions logMercurialResult:results];
		return nil;
	}
	return [results.outStr componentsSeparatedByString:@"\n"];
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



@end
