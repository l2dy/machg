//
//  BrowserViewController.m
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "BrowserViewController.h"
#import "FSBrowserCell.h"
#import "FSNodeInfo.h"
#import "MacHgDocument.h"
#import "CommitSheetController.h"
#import "RevertSheetController.h"
#import "RenameFileSheetController.h"




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  BrowserViewController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation BrowserViewController
@synthesize myDocument;
@synthesize theBrowserView;

- (BrowserViewController*) initBrowserViewControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"BrowserView" owner:self];
	//[[theBrowserView theBrowser] reloadData:nil]; 	// Prime the browser with an initial load of data.

	return self;
}

- (void) unload { [theBrowserView unload]; }
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  BrowserView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation BrowserView

@synthesize myDocument;
@synthesize theBrowser;





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
	[self observe:kRepositoryRootChanged		from:[self myDocument]  byCalling:@selector(repositoryRootDidChange)];

	// Tell the browser to send us messages when it is clicked.
	[theBrowser setTarget:self];
	[theBrowser setAction:@selector(browserSingleClick:)];
	[theBrowser setDoubleAction:@selector(browserDoubleClick:)];
	[theBrowser setAreNodesVirtual:NO];
    
	[theBrowser setIsMainFSBrowser:YES];
}

- (void) unload									{ }





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

- (IBAction) browserSingleClick:(id)browser	{ [self updateCurrentPreviewImage]; }
- (IBAction) browserDoubleClick:(id)browser
{
	SEL theAction = [self actionForDoubleClickEnum:[theBrowser actionEnumForBrowserDoubleClick]];
	[[NSApplication sharedApplication] sendAction:theAction to:nil from:browser];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Refreshing
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) repositoryRootDidChange				{ [theBrowser repositoryRootDidChange]; }

- (IBAction) refreshBrowserContent:(id)sender	{ return [myDocument refreshBrowserContent:myDocument]; }

- (NSArray*) statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath
{
	return [myDocument statusLinesForPaths:absolutePaths withRootPath:rootPath];
}

- (NSImage*) imageForMultipleCells:(NSArray*) cells
{
	FSNodeInfo* firstNode = [[cells objectAtIndex:0] nodeInfo];
	NSString* extension = [[firstNode absolutePath] pathExtension];
	for (FSBrowserCell* cell in cells)
		if (![extension isEqualToString:[[[cell nodeInfo] absolutePath] pathExtension]])
			return nil;	
	return [NSWorkspace iconImageOfSize:NSMakeSize(128,128) forPath:[firstNode absolutePath]];		
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Preview Image
// -----------------------------------------------------------------------------------------------------------------------------------------

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
	if (![theBrowser nodesAreSelected])
		attributedString = [NSAttributedString string:@"No Selection" withAttributes:smallCenteredSystemFontAttributes];
	else
	{
		NSArray* selectedCells = [theBrowser selectedCells];
		if ([selectedCells count] > 1)
		{
			attributedString = [NSAttributedString string:@"Multiple Selection" withAttributes:smallCenteredSystemFontAttributes];
			inspectorImage = [self imageForMultipleCells:selectedCells];
		}
		else if ([selectedCells count] == 1)
		{
			// Find the last selected cell and show its information
			FSBrowserCell* lastSelectedCell = [selectedCells objectAtIndex:[selectedCells count] - 1];
			FSNodeInfo* fsNode = [lastSelectedCell nodeInfo];
			attributedString = [fsNode attributedInspectorStringForFSNode];
			inspectorImage = [NSWorkspace iconImageOfSize:NSMakeSize(128,128) forPath:[fsNode absolutePath]];
		}
	}
    
	[nodeInspector setAttributedStringValue:attributedString];
	[nodeIconWell setImage:inspectorImage];
}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Standard  Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuCommitSelectedFiles:(id)sender				{ [[myDocument theCommitSheetController] openCommitSheetWithSelectedFiles:sender]; }
- (IBAction) mainMenuCommitAllFiles:(id)sender					{ [[myDocument theCommitSheetController] openCommitSheetWithAllFiles:sender]; }
- (IBAction) toolbarCommitFiles:(id)sender
{
	if ([theBrowser nodesAreChosen] && ![[myDocument repositoryData] inMergeState])
		[self mainMenuCommitSelectedFiles:sender];
	else
		[self mainMenuCommitAllFiles:sender];
}


- (IBAction) mainMenuDiffSelectedFiles:(id)sender				{ [myDocument viewDifferencesInCurrentRevisionFor:[theBrowser absolutePathsOfBrowserChosenFiles] toRevision:nil]; }		// nil indicates the current revision
- (IBAction) mainMenuDiffAllFiles:(id)sender					{ [myDocument viewDifferencesInCurrentRevisionFor:[myDocument absolutePathOfRepositoryRootAsArray] toRevision:nil]; }	// nil indicates the current revision
- (IBAction) toolbarDiffFiles:(id)sender
{
	if ([theBrowser nodesAreChosen])
		[self mainMenuDiffSelectedFiles:sender];
	else
		[self mainMenuDiffAllFiles:sender];	
}

- (IBAction) mainMenuAddRenameRemoveSelectedFiles:(id)sender	{ [myDocument primaryActionAddRenameRemoveFiles:[theBrowser absolutePathsOfBrowserChosenFiles]]; }
- (IBAction) mainMenuAddRenameRemoveAllFiles:(id)sender			{ [myDocument primaryActionAddRenameRemoveFiles:[myDocument absolutePathOfRepositoryRootAsArray]]; }
- (IBAction) toolbarAddRenameRemoveFiles:(id)sender
{
	if ([theBrowser nodesAreChosen])
		[self mainMenuAddRenameRemoveSelectedFiles:sender];
	else
		[self mainMenuAddRenameRemoveAllFiles:sender];
}




- (IBAction) mainMenuRevertSelectedFiles:(id)sender				{ [myDocument primaryActionRevertFiles:[theBrowser absolutePathsOfBrowserChosenFiles] toVersion:nil]; }
- (IBAction) mainMenuRevertAllFiles:(id)sender					{ [myDocument primaryActionRevertFiles:[myDocument absolutePathOfRepositoryRootAsArray] toVersion:nil]; }
- (IBAction) mainMenuRevertSelectedFilesToVersion:(id)sender	{ [[myDocument theRevertSheetController] openRevertSheetWithSelectedFiles:sender]; }
- (IBAction) toolbarRevertFiles:(id)sender
{
	if ([theBrowser nodesAreChosen])
		[self mainMenuRevertSelectedFilesToVersion:sender];
	else
		[self mainMenuRevertAllFiles:sender];	
}



- (IBAction) mainMenuDeleteSelectedFiles:(id)sender				{ [myDocument primaryActionDeleteSelectedFiles:[theBrowser absolutePathsOfBrowserChosenFiles]]; }
- (IBAction) mainMenuAddSelectedFiles:(id)sender				{ [myDocument primaryActionAddSelectedFiles:[theBrowser absolutePathsOfBrowserChosenFiles]]; }
- (IBAction) mainMenuUntrackSelectedFiles:(id)sender			{ [myDocument primaryActionUntrackSelectedFiles:[theBrowser absolutePathsOfBrowserChosenFiles]]; }
- (IBAction) mainMenuRenameSelectedFile:(id)sender				{ [[myDocument theRenameFileSheetController] openRenameFileSheet:sender]; }


- (IBAction) mainMenuIgnoreSelectedFiles:(id)sender				{ [myDocument primaryActionIgnoreSelectedFiles:[theBrowser absolutePathsOfBrowserChosenFiles]]; }
- (IBAction) mainMenuUnignoreSelectedFiles:(id)sender			{ [myDocument primaryActionUnignoreSelectedFiles:[theBrowser absolutePathsOfBrowserChosenFiles]]; }
- (IBAction) mainMenuAnnotateSelectedFiles:(id)sender			{ [myDocument primaryActionAnnotateSelectedFiles:[theBrowser absolutePathsOfBrowserChosenFiles]]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Contextual Menu actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuOpenSelectedFilesInFinder:(id)sender		{ [theBrowser browserMenuOpenSelectedFilesInFinder:sender]; }
- (IBAction) mainMenuRevealSelectedFilesInFinder:(id)sender		{ [theBrowser browserMenuRevealSelectedFilesInFinder:sender]; }
- (IBAction) mainMenuOpenTerminalHere:(id)sender				{ [theBrowser browserMenuOpenTerminalHere:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Action Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) toolbarActionAppliesToFilesWith:(HGStatus)status	{ return ([theBrowser statusOfChosenPathsInBrowserContain:status] || (![theBrowser nodesAreChosen] && [theBrowser repositoryHasFilesWhichContainStatus:status])); }


- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem, NSObject>)anItem
{
	SEL theAction = [anItem action];

	if (theAction == @selector(mainMenuCommitSelectedFiles:))			return [myDocument repositoryIsSelectedAndReady] && [myDocument validateAndSwitchMenuForCommitSelectedFiles:DynamicCast(NSMenuItem, anItem)];
	if (theAction == @selector(mainMenuCommitAllFiles:))				return [myDocument repositoryIsSelectedAndReady] && [myDocument validateAndSwitchMenuForCommitAllFiles:DynamicCast(NSMenuItem, anItem)];
	if (theAction == @selector(toolbarCommitFiles:))					return [myDocument repositoryIsSelectedAndReady] && ([[myDocument repositoryData] inMergeState] || [self toolbarActionAppliesToFilesWith:eHGStatusCommittable]);
	
	if (theAction == @selector(mainMenuDiffSelectedFiles:))				return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusModified];
	if (theAction == @selector(mainMenuDiffAllFiles:))					return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusModified];
	if (theAction == @selector(toolbarDiffFiles:))						return [myDocument repositoryIsSelectedAndReady] && [self toolbarActionAppliesToFilesWith:eHGStatusModified];

	if (theAction == @selector(mainMenuAddRenameRemoveSelectedFiles:))	return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusAddableOrRemovable];
	if (theAction == @selector(mainMenuAddRenameRemoveAllFiles:))		return [myDocument repositoryIsSelectedAndReady] && [theBrowser repositoryHasFilesWhichContainStatus:eHGStatusAddableOrRemovable];
	if (theAction == @selector(toolbarAddRenameRemoveFiles:))			return [myDocument repositoryIsSelectedAndReady] && [self toolbarActionAppliesToFilesWith:eHGStatusAddableOrRemovable];
	// ------	
	if (theAction == @selector(mainMenuRevertSelectedFiles:))			return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusChangedInSomeWay];
	if (theAction == @selector(mainMenuRevertAllFiles:))				return [myDocument repositoryIsSelectedAndReady] && [theBrowser repositoryHasFilesWhichContainStatus:eHGStatusChangedInSomeWay];
	if (theAction == @selector(mainMenuRevertSelectedFilesToVersion:))	return [myDocument repositoryIsSelectedAndReady] && [theBrowser nodesAreChosen];
	if (theAction == @selector(toolbarRevertFiles:))					return [myDocument repositoryIsSelectedAndReady] && [self toolbarActionAppliesToFilesWith:eHGStatusChangedInSomeWay];
	
	if (theAction == @selector(mainMenuDeleteSelectedFiles:))			return [myDocument repositoryIsSelectedAndReady] && [theBrowser nodesAreChosen];
	if (theAction == @selector(mainMenuAddSelectedFiles:))				return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusAddable];
	if (theAction == @selector(mainMenuUntrackSelectedFiles:))			return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusInRepository];
	if (theAction == @selector(mainMenuRenameSelectedFile:))			return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusInRepository] && [theBrowser singleItemIsChosenInBrower];
	// ------
	if (theAction == @selector(mainMenuRemergeSelectedFiles:))			return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusSecondary];
	if (theAction == @selector(mainMenuMarkResolvedSelectedFiles:))		return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusUnresolved];
	// ------
	if (theAction == @selector(mainMenuIgnoreSelectedFiles:))			return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusNotIgnored];
	if (theAction == @selector(mainMenuUnignoreSelectedFiles:))			return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusIgnored];
	if (theAction == @selector(mainMenuAnnotateSelectedFiles:))			return [myDocument repositoryIsSelectedAndReady] && [theBrowser statusOfChosenPathsInBrowserContain:eHGStatusInRepository];
	// ------

	if (theAction == @selector(mainMenuOpenSelectedFilesInFinder:))		return [myDocument repositoryIsSelectedAndReady] && [theBrowser nodesAreChosen];
	if (theAction == @selector(mainMenuRevealSelectedFilesInFinder:))	return [myDocument repositoryIsSelectedAndReady];
	if (theAction == @selector(mainMenuOpenTerminalHere:))				return [myDocument repositoryIsSelectedAndReady];

	return NO;
}




@end



