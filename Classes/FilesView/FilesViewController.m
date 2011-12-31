//
//  FilesViewController.m
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "FilesViewController.h"
#import "FSViewerPaneCell.h"
#import "FSNodeInfo.h"
#import "MacHgDocument.h"
#import "CommitSheetController.h"
#import "RevertSheetController.h"
#import "RenameFileSheetController.h"
#import "TaskExecutions.h"
#import "RepositoryData.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilesViewController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation FilesViewController
@synthesize myDocument;
@synthesize theFilesView;

- (FilesViewController*) initFilesViewControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"FilesView" owner:self];
	return self;
}

- (void) unload { [theFilesView unload]; }
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilesView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation FilesView

@synthesize myDocument;
@synthesize theFSViewer;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

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

	myDocument = [parentContoller myDocument];
	[self observe:kRepositoryDataIsNew		from:[self myDocument]  byCalling:@selector(repositoryDataIsNew)];
	[FilesViewBrowserSegement setState:NO];
	[FilesViewOutlineSegement setState:NO];
	[FilesViewTableSegement setState:NO];

	[theFSViewer setAreNodesVirtual:NO];
}

- (BOOL) controlsMainFSViewer	{ return YES; }

- (void) unload					{ }

- (void) prepareToOpenFilesView
{
	[[myDocument mainWindow] makeFirstResponder:self];
	[theFSViewer prepareToOpenFSViewerPane];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Browser Clicks
// -----------------------------------------------------------------------------------------------------------------------------------------

// Given a browser action enum we can convert this to the appropriate selector and send that off to the object.
- (SEL) actionForDoubleClickEnum:(BrowserDoubleClickAction)theActionEnum
{
	switch (theActionEnum)
	{
		case eBrowserClickActionOpen:				return @selector(browserMenuOpenSelectedFilesInFinder:);
		case eBrowserClickActionRevealInFinder:		return @selector(browserMenuRevealSelectedFilesInFinder:);
		case eBrowserClickActionDiff:				return @selector(mainMenuDiffSelectedFiles:);
		case eBrowserClickActionAnnotate:			return @selector(mainMenuAnnotateSelectedFiles:);
		case eBrowserClickActionOpenTerminalHere:	return @selector(browserMenuOpenTerminalHere:);
		default:									return @selector(mainMenuNoAction:);
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
// MARK:  Refreshing
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void)	 didSwitchViewTo:(FSViewerNum)viewNumber
{
	[FilesViewBrowserSegement setState:(viewNumber == eFilesBrowser)];
	[FilesViewOutlineSegement setState:(viewNumber == eFilesOutline)];
	[FilesViewTableSegement   setState:(viewNumber == eFilesTable)];
}

- (void) repositoryDataIsNew					{ [theFSViewer repositoryDataIsNew]; }

- (IBAction) refreshBrowserContent:(id)sender	{ return [myDocument refreshBrowserContent:myDocument]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FSBrowser Protocol Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSArray*) statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath
{
	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", nil];
	if (ShowIgnoredFilesInBrowserFromDefaults())	[argsStatus addObject:@"--ignored"];
	if (ShowCleanFilesInBrowserFromDefaults())		[argsStatus addObject:@"--clean"];
	if (ShowUntrackedFilesInBrowserFromDefaults())	[argsStatus addObject:@"--unknown"];
	if (ShowAddedFilesInBrowserFromDefaults())		[argsStatus addObject:@"--added"];
	if (ShowRemovedFilesInBrowserFromDefaults())	[argsStatus addObject:@"--removed"];
	if (ShowMissingFilesInBrowserFromDefaults())	[argsStatus addObject:@"--deleted"];
	if (ShowModifiedFilesInBrowserFromDefaults())	[argsStatus addObject:@"--modified"];
	[argsStatus addObjectsFromArray:absolutePaths];
	
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	
	if ([results hasErrors])
	{
		// Try a second time
		sleep(0.5);
		results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	}
	if ([results.errStr length] > 0)
	{
		[results logMercurialResult];
		// for an error rather than warning fail by returning nil. Maybe later we will return error codes.
		if ([results hasErrors])
			return  nil;
	}
	NSArray* lines = [results.outStr componentsSeparatedByString:@"\n"];
	return IsNotEmpty(lines) ? lines : [NSArray array];
}


// Get any resolve status lines and change the resolved code 'R' to 'V' so that this status letter doesn't conflict with the other
// status letters.
- (NSArray*) resolveStatusLines:(NSArray*)absolutePaths  withRootPath:(NSString*)rootPath
{
	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsResolveStatus = [NSMutableArray arrayWithObjects:@"resolve", @"--list", nil];
	[argsResolveStatus addObjectsFromArray:absolutePaths];
	
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsResolveStatus fromRoot:rootPath  logging:eLoggingNone];
	if ([results hasErrors])
	{
		[results logMercurialResult];
		return nil;
	}
	NSArray* lines = [results.outStr componentsSeparatedByString:@"\n"];
	NSMutableArray* newLines = [[NSMutableArray alloc] init];
	for (NSString* line in lines)
		if (IsNotEmpty(line))
		{
			if ([line characterAtIndex:0] == 'R')
				[newLines addObject:fstr(@"V%@",[line substringFromIndex:1])];
			else
				[newLines addObject:line];
		}
	return newLines;
}

- (BOOL) writeRowsWithIndexes:(NSIndexSet*)rowIndexes inColumn:(NSInteger)column toPasteboard:(NSPasteboard*)pasteboard
{
	NSMutableArray* paths = [[NSMutableArray alloc] init];
	for (NSInteger row = [rowIndexes firstIndex]; row != NSNotFound; row = [rowIndexes indexGreaterThanIndex: row])
	{
		FSNodeInfo* node = [[theFSViewer theFilesBrowser] itemAtRow:row inColumn:column];
		[paths addObject:[node absolutePath]];
	}

	[pasteboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
	[pasteboard setPropertyList:paths forType:NSFilenamesPboardType];
	
	return IsNotEmpty(paths) ? YES : NO;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quicklook Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfQuickLookPreviewItems		{ return [theFSViewer numberOfQuickLookPreviewItems]; }

- (NSArray*) quickLookPreviewItems				{ return [theFSViewer quickLookPreviewItems]; }

- (void) keyDown:(NSEvent *)theEvent
{
    NSString* key = [theEvent charactersIgnoringModifiers];
    if ([key isEqual:@" "])
        [[self myDocument] togglePreviewPanel:self];
	else
        [super keyDown:theEvent];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Preview Image
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSImage*) imageForMultipleNodes:(NSArray*) nodes
{
	FSNodeInfo* firstNode = [nodes objectAtIndex:0];
	NSString* extension = [[firstNode absolutePath] pathExtension];
	for (FSNodeInfo* node in nodes)
		if (![extension isEqualToString:[[node absolutePath] pathExtension]])
			return nil;
	return [firstNode iconImageForPreview];
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
	// Determine the selection and display it's icon and inspector information on the right side of the UI.
	NSImage* inspectorImage = nil;
	NSAttributedString* attributedString = nil;
	if (![theFSViewer nodesAreSelected])
		attributedString = [NSAttributedString string:@"No Selection" withAttributes:smallCenteredSystemFontAttributes];
	else
	{
		NSArray* selectedNodes = [theFSViewer selectedNodes];
		if ([selectedNodes count] > 1)
		{
			attributedString = [NSAttributedString string:@"Multiple Selection" withAttributes:smallCenteredSystemFontAttributes];
			inspectorImage = [self imageForMultipleNodes:selectedNodes];
		}
		else if ([selectedNodes count] == 1)
		{
			// Find the last selected cell and show its information
			FSNodeInfo* lastSelectedNode = [selectedNodes objectAtIndex:[selectedNodes count] - 1];
			attributedString   = [lastSelectedNode attributedInspectorStringForFSNode];
			inspectorImage     = [lastSelectedNode iconImageForPreview];
		}
	}
    
	[nodeInspector setAttributedStringValue:attributedString];
	[nodeIconWell setImage:inspectorImage];
	
	// The browser selection might have changed update the quick look preview image if necessary. It would be really nice to have
	// a NSBrowserSelectionDidChangeNotification
	if ([myDocument quicklookPreviewIsVisible])
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
}








// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Contextual Menu actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuOpenSelectedFilesInFinder:(id)sender		{ [theFSViewer browserMenuOpenSelectedFilesInFinder:sender]; }
- (IBAction) mainMenuRevealSelectedFilesInFinder:(id)sender		{ [theFSViewer browserMenuRevealSelectedFilesInFinder:sender]; }
- (IBAction) mainMenuOpenTerminalHere:(id)sender				{ [theFSViewer browserMenuOpenTerminalHere:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Action Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) toolbarActionAppliesToFilesWith:(HGStatus)status	{ return ([theFSViewer statusOfChosenPathsInFilesContain:status] || (![theFSViewer nodesAreChosen] && [theFSViewer repositoryHasFilesWhichContainStatus:status])); }

- (BOOL) validateAndSwitchMenuForCommitSelectedFiles:(NSMenuItem*)menuItem
{
	if (!menuItem)
		return NO;
	BOOL inMergeState = [[myDocument repositoryData] inMergeState];
	[menuItem setTitle: inMergeState ? @"Commit Merged Files…" : @"Commit Selected Files…"];
	return inMergeState ? [myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable] : ([myDocument statusOfChosenPathsInFilesContain:eHGStatusCommittable] && [myDocument showingFilesView]);
}

- (BOOL) validateAndSwitchMenuForRenameSelectedItem:(NSMenuItem*)menuItem
{
	if (!menuItem)
		return NO;
	NSArray* chosenNodes = [theFSViewer chosenNodes];
	if ([chosenNodes count] != 1)
		return NO;
	BOOL isDirectory = [[chosenNodes firstObject] isDirectory];
	[menuItem setTitle: isDirectory ? @"Rename Selected Directory…" : @"Rename Selected File…"];
	return [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusInRepository];
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem, NSObject>)anItem
{
	SEL theAction = [anItem action];

	if (theAction == @selector(mainMenuCommitSelectedFiles:))			return [myDocument localRepoIsSelectedAndReady] && [self validateAndSwitchMenuForCommitSelectedFiles:DynamicCast(NSMenuItem, anItem)];
	if (theAction == @selector(mainMenuCommitAllFiles:))				return [myDocument localRepoIsSelectedAndReady] && [myDocument validateAndSwitchMenuForCommitAllFiles:anItem];
	if (theAction == @selector(toolbarCommitFiles:))					return [myDocument localRepoIsSelectedAndReady] && ([[myDocument repositoryData] inMergeState] || [self toolbarActionAppliesToFilesWith:eHGStatusCommittable]);
	
	if (theAction == @selector(mainMenuDiffSelectedFiles:))				return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusModified];
	if (theAction == @selector(mainMenuDiffAllFiles:))					return [myDocument localRepoIsSelectedAndReady] && [theFSViewer repositoryHasFilesWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(toolbarDiffFiles:))						return [myDocument localRepoIsSelectedAndReady] && [self toolbarActionAppliesToFilesWith:eHGStatusModified];

	if (theAction == @selector(mainMenuAddRenameRemoveSelectedFiles:))	return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusAddableOrRemovable];
	if (theAction == @selector(mainMenuAddRenameRemoveAllFiles:))		return [myDocument localRepoIsSelectedAndReady] && [theFSViewer repositoryHasFilesWhichContainStatus:eHGStatusAddableOrRemovable];
	if (theAction == @selector(toolbarAddRenameRemoveFiles:))			return [myDocument localRepoIsSelectedAndReady] && [self toolbarActionAppliesToFilesWith:eHGStatusAddableOrRemovable];
	// ------	
	if (theAction == @selector(mainMenuRevertSelectedFiles:))			return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusChangedInSomeWay];
	if (theAction == @selector(mainMenuRevertAllFiles:))				return [myDocument localRepoIsSelectedAndReady] && [theFSViewer repositoryHasFilesWhichContainStatus:eHGStatusChangedInSomeWay];
	if (theAction == @selector(mainMenuRevertSelectedFilesToVersion:))	return [myDocument localRepoIsSelectedAndReady] && [theFSViewer nodesAreChosen];
	if (theAction == @selector(toolbarRevertFiles:))					return [myDocument localRepoIsSelectedAndReady] && [self toolbarActionAppliesToFilesWith:eHGStatusChangedInSomeWay];
	
	if (theAction == @selector(mainMenuDeleteSelectedFiles:))			return [myDocument localRepoIsSelectedAndReady] && [theFSViewer nodesAreChosen];
	if (theAction == @selector(mainMenuAddSelectedFiles:))				return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusAddable];
	if (theAction == @selector(mainMenuUntrackSelectedFiles:))			return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusInRepository];
	if (theAction == @selector(mainMenuRenameSelectedItem:))			return [myDocument localRepoIsSelectedAndReady] && [self validateAndSwitchMenuForRenameSelectedItem:DynamicCast(NSMenuItem, anItem)];
	// ------
	if (theAction == @selector(mainMenuRemergeSelectedFiles:))			return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusSecondary];
	if (theAction == @selector(mainMenuMarkResolvedSelectedFiles:))		return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusUnresolved];
	// ------
	if (theAction == @selector(mainMenuIgnoreSelectedFiles:))			return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusNotIgnored];
	if (theAction == @selector(mainMenuUnignoreSelectedFiles:))			return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusIgnored];
	if (theAction == @selector(mainMenuAnnotateSelectedFiles:))			return [myDocument localRepoIsSelectedAndReady] && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusInRepository];
	// ------
	if (theAction == @selector(mainMenuRollbackCommit:))				return [myDocument localRepoIsSelectedAndReady] && [[myDocument repositoryData] isRollbackInformationAvailable];

	if (theAction == @selector(mainMenuOpenSelectedFilesInFinder:))		return [myDocument localRepoIsSelectedAndReady] && [theFSViewer nodesAreChosen];
	if (theAction == @selector(mainMenuRevealSelectedFilesInFinder:))	return [myDocument localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuOpenTerminalHere:))				return [myDocument localRepoIsSelectedAndReady];

	return NO;
}




@end



