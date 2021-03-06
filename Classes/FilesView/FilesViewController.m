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
#import "JHConcertinaView.h"





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilesViewController
// ------------------------------------------------------------------------------------
// MARK: -

@implementation FilesViewController
@synthesize myDocument = myDocument_;
@synthesize theFilesView = theFilesView_;

- (FilesViewController*) initFilesViewControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithNibName:@"FilesView" bundle:nil];
	[self loadView];
	return self;
}

- (void) dealloc { [self stopObserving]; }
@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilesView
// ------------------------------------------------------------------------------------
// MARK: -

@implementation FilesView

@synthesize myDocument = myDocument_;
@synthesize parentContoller = parentContoller_;
@synthesize theFSViewer = theFSViewer;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (id) initWithFrame:(NSRect)frameRect
{
	return [super initWithFrame:frameRect];
}

- (void) setMyDocumentFromParent
{
	myDocument_ = parentContoller_.myDocument;
}

- (void) awakeFromNib
{
	[self setMyDocumentFromParent];
	[self observe:kRepositoryDataIsNew		from:myDocument_  byCalling:@selector(repositoryDataIsNew)];
	theFSViewer.areNodesVirtual = NO;
}

- (void) dealloc
{
	[self stopObserving];
}

- (BOOL) controlsMainFSViewer	{ return YES; }

- (void) prepareToOpenFilesView
{
	[myDocument_.mainWindow makeFirstResponder:self];
	[theFSViewer prepareToOpenFSViewerPane];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Browser Clicks
// ------------------------------------------------------------------------------------

// Given a browser action enum we can convert this to the appropriate selector and send that off to the object.
- (SEL) actionForDoubleClickEnum:(BrowserDoubleClickAction)theActionEnum
{
	switch (theActionEnum)
	{
		case eBrowserClickActionOpen:				return @selector(viewerMenuOpenSelectedFilesInFinder:);
		case eBrowserClickActionRevealInFinder:		return @selector(browserMenuRevealSelectedFilesInFinder:);
		case eBrowserClickActionDiff:				return @selector(mainMenuDiffSelectedFiles:);
		case eBrowserClickActionAnnotate:			return @selector(mainMenuAnnotateSelectedFiles:);
		case eBrowserClickActionOpenTerminalHere:	return @selector(browserMenuOpenTerminalHere:);
		default:									return @selector(mainMenuNoAction:);
	}
}

- (IBAction) fsviewerAction:(id)browser	{ [self updateCurrentPreviewImage]; }
- (IBAction) fsviewerDoubleAction:(id)browser
{
	SEL theAction = [self actionForDoubleClickEnum:theFSViewer.actionEnumForBrowserDoubleClick];
	[NSApplication.sharedApplication sendAction:theAction to:nil from:browser];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Refreshing
// ------------------------------------------------------------------------------------

- (void) didSwitchViewTo:(FSViewerNum)viewNumber	{ }
- (void) repositoryDataIsNew						{ [theFSViewer repositoryDataIsNew]; }
- (IBAction) refreshBrowserContent:(id)sender		{ return [myDocument_ refreshBrowserContent:myDocument_]; }

- (void) restoreConcertinaSplitViewPositions
{
	if (IsNotEmpty(concertinaView.autosavePositionName))
		return;
	NSString* fileName = myDocument_.documentNameForAutosave;
	NSString* autoSaveNameForConcertina = fstr(@"File:%@:FilesViewConcertinaPositions", fileName);
	concertinaView.autosavePositionName = autoSaveNameForConcertina;
	[concertinaView restorePositionsFromDefaults];	
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  FSViewerController Protocol Methods
// ------------------------------------------------------------------------------------

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
	
	if (results.hasErrors)
	{
		// Try a second time
		sleep(0.5);
		results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	}
	if (results.errStr.length > 0)
	{
		[results logMercurialResult];
		// for an error rather than warning fail by returning nil. Maybe later we will return error codes.
		if (results.hasErrors)
			return  nil;
	}
	NSArray* lines = [results.outStr componentsSeparatedByString:@"\n"];
	return IsNotEmpty(lines) ? lines : @[];
}


// Get any resolve status lines and change the resolved code 'R' to 'V' so that this status letter doesn't conflict with the other
// status letters.
- (NSArray*) resolveStatusLines:(NSArray*)absolutePaths  withRootPath:(NSString*)rootPath
{
	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsResolveStatus = [NSMutableArray arrayWithObjects:@"resolve", @"--list", nil];
	[argsResolveStatus addObjectsFromArray:absolutePaths];
	
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsResolveStatus fromRoot:rootPath  logging:eLoggingNone];
	if (results.hasErrors)
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

- (BOOL) writePaths:(NSArray*)paths toPasteboard:(NSPasteboard*)pasteboard
{
	[pasteboard declareTypes:@[NSFilenamesPboardType] owner:self];
	[pasteboard setPropertyList:paths forType:NSFilenamesPboardType];	
	return IsNotEmpty(paths) ? YES : NO;
}

- (BOOL)			autoExpandViewerOutlines	{ return AutoExpandViewerOutlinesFromDefaults(); } 
- (HunkExclusions*) hunkExclusions		{ return myDocument_.hunkExclusions; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quicklook Handling
// ------------------------------------------------------------------------------------

- (NSInteger) numberOfQuickLookPreviewItems		{ return theFSViewer.numberOfQuickLookPreviewItems; }

- (NSArray*) quickLookPreviewItems				{ return theFSViewer.quickLookPreviewItems; }

- (void) keyDown:(NSEvent *)theEvent
{
    NSString* key = theEvent.charactersIgnoringModifiers;
    if ([key isEqual:@" "])
        [myDocument_ togglePreviewPanel:self];
	else
        [super keyDown:theEvent];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Preview Image
// ------------------------------------------------------------------------------------

- (NSImage*) imageForMultipleNodes:(NSArray*) nodes
{
	FSNodeInfo* firstNode = nodes[0];
	NSString* extension = firstNode.absolutePath.pathExtension;
	for (FSNodeInfo* node in nodes)
		if (![extension isEqualToString:node.absolutePath.pathExtension])
			return nil;
	return firstNode.iconImageForPreview;
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
	if (!theFSViewer.nodesAreSelected)
		attributedString = [NSAttributedString string:@"No Selection" withAttributes:smallCenteredSystemFontAttributes];
	else
	{
		NSArray* selectedNodes = theFSViewer.selectedNodes;
		if (selectedNodes.count > 1)
		{
			attributedString = [NSAttributedString string:@"Multiple Selection" withAttributes:smallCenteredSystemFontAttributes];
			inspectorImage = [self imageForMultipleNodes:selectedNodes];
		}
		else if (selectedNodes.count == 1)
		{
			// Find the last selected cell and show its information
			FSNodeInfo* lastSelectedNode = selectedNodes[selectedNodes.count - 1];
			attributedString   = lastSelectedNode.attributedInspectorStringForFSNode;
			inspectorImage     = lastSelectedNode.iconImageForPreview;
		}
	}
    
	nodeInspector.attributedStringValue = attributedString;
	nodeIconWell.image = inspectorImage;
	
	// The browser selection might have changed update the quick look preview image if necessary. It would be really nice to have
	// a NSBrowserSelectionDidChangeNotification
	if (myDocument_.quicklookPreviewIsVisible)
		[QLPreviewPanel.sharedPreviewPanel reloadData];
}








// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Contextual Menu actions
// ------------------------------------------------------------------------------------

- (IBAction) mainMenuOpenSelectedFilesInFinder:(id)sender		{ [theFSViewer viewerMenuOpenSelectedFilesInFinder:sender]; }
- (IBAction) mainMenuRevealSelectedFilesInFinder:(id)sender		{ [theFSViewer browserMenuRevealSelectedFilesInFinder:sender]; }
- (IBAction) mainMenuOpenTerminalHere:(id)sender				{ [theFSViewer browserMenuOpenTerminalHere:sender]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Action Validation
// ------------------------------------------------------------------------------------

- (BOOL) toolbarActionAppliesToFilesWith:(HGStatus)status	{ return ([theFSViewer statusOfChosenPathsInFilesContain:status] || (!theFSViewer.nodesAreChosen && [theFSViewer repositoryHasFilesWhichContainStatus:status])); }

- (BOOL) validateAndSwitchMenuForCommitSelectedFiles:(NSMenuItem*)menuItem
{
	if (!menuItem)
		return NO;
	BOOL inMergeState = myDocument_.repositoryData.inMergeState;
	[menuItem setTitle: inMergeState ? @"Commit Merged Files???" : @"Commit Selected Files???"];
	return inMergeState ? [myDocument_ repositoryHasFilesWhichContainStatus:eHGStatusCommittable] : ([myDocument_ statusOfChosenPathsInFilesContain:eHGStatusCommittable] && myDocument_.showingFilesView);
}

- (BOOL) validateAndSwitchMenuForRenameSelectedItem:(NSMenuItem*)menuItem
{
	if (!menuItem)
		return NO;
	NSArray* chosenNodes = theFSViewer.chosenNodes;
	if (chosenNodes.count != 1)
		return NO;
	BOOL isDirectory = [chosenNodes.firstObject isDirectory];
	[menuItem setTitle: isDirectory ? @"Rename Selected Directory???" : @"Rename Selected File???"];
	return [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusInRepository];
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem, NSObject>)anItem
{
	SEL theAction = anItem.action;

	if (theAction == @selector(mainMenuCommitSelectedFiles:))			return myDocument_.localRepoIsSelectedAndReady && [self validateAndSwitchMenuForCommitSelectedFiles:DynamicCast(NSMenuItem, anItem)];
	if (theAction == @selector(mainMenuCommitAllFiles:))				return myDocument_.localRepoIsSelectedAndReady && [myDocument_ validateAndSwitchMenuForCommitAllFiles:anItem];
	if (theAction == @selector(toolbarCommitFiles:))					return myDocument_.localRepoIsSelectedAndReady && (myDocument_.repositoryData.inMergeState || [self toolbarActionAppliesToFilesWith:eHGStatusCommittable]);
	
	if (theAction == @selector(mainMenuDiffSelectedFiles:))				return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusModified];
	if (theAction == @selector(mainMenuDiffAllFiles:))					return myDocument_.localRepoIsSelectedAndReady && [theFSViewer repositoryHasFilesWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(toolbarDiffFiles:))						return myDocument_.localRepoIsSelectedAndReady && [self toolbarActionAppliesToFilesWith:eHGStatusModified];

	if (theAction == @selector(mainMenuAddRenameRemoveSelectedFiles:))	return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusAddableOrRemovable];
	if (theAction == @selector(mainMenuAddRenameRemoveAllFiles:))		return myDocument_.localRepoIsSelectedAndReady && [theFSViewer repositoryHasFilesWhichContainStatus:eHGStatusAddableOrRemovable];
	if (theAction == @selector(toolbarAddRenameRemoveFiles:))			return myDocument_.localRepoIsSelectedAndReady && [self toolbarActionAppliesToFilesWith:eHGStatusAddableOrRemovable];
	// ------	
	if (theAction == @selector(mainMenuRevertSelectedFiles:))			return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusChangedInSomeWay];
	if (theAction == @selector(mainMenuRevertAllFiles:))				return myDocument_.localRepoIsSelectedAndReady && [theFSViewer repositoryHasFilesWhichContainStatus:eHGStatusChangedInSomeWay];
	if (theAction == @selector(mainMenuRevertSelectedFilesToVersion:))	return myDocument_.localRepoIsSelectedAndReady && theFSViewer.nodesAreChosen;
	if (theAction == @selector(toolbarRevertFiles:))					return myDocument_.localRepoIsSelectedAndReady && [self toolbarActionAppliesToFilesWith:eHGStatusChangedInSomeWay];
	
	if (theAction == @selector(mainMenuDeleteSelectedFiles:))			return myDocument_.localRepoIsSelectedAndReady && theFSViewer.nodesAreChosen;
	if (theAction == @selector(mainMenuAddSelectedFiles:))				return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusAddable];
	if (theAction == @selector(mainMenuUntrackSelectedFiles:))			return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusInRepository];
	if (theAction == @selector(mainMenuRenameSelectedItem:))			return myDocument_.localRepoIsSelectedAndReady && [self validateAndSwitchMenuForRenameSelectedItem:DynamicCast(NSMenuItem, anItem)];
	// ------
	if (theAction == @selector(mainMenuRemergeSelectedFiles:))			return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusSecondary];
	if (theAction == @selector(mainMenuMarkResolvedSelectedFiles:))		return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusUnresolved];
	// ------
	if (theAction == @selector(mainMenuIgnoreSelectedFiles:))			return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusNotIgnored];
	if (theAction == @selector(mainMenuUnignoreSelectedFiles:))			return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusIgnored];
	if (theAction == @selector(mainMenuAnnotateSelectedFiles:))			return myDocument_.localRepoIsSelectedAndReady && [theFSViewer statusOfChosenPathsInFilesContain:eHGStatusInRepository];
	// ------
	if (theAction == @selector(mainMenuRollbackCommit:))				return myDocument_.localRepoIsSelectedAndReady && myDocument_.repositoryData.isRollbackInformationAvailable;

	if (theAction == @selector(mainMenuOpenSelectedFilesInFinder:))		return myDocument_.localRepoIsSelectedAndReady && theFSViewer.nodesAreChosen;
	if (theAction == @selector(mainMenuRevealSelectedFilesInFinder:))	return myDocument_.localRepoIsSelectedAndReady;
	if (theAction == @selector(mainMenuOpenTerminalHere:))				return myDocument_.localRepoIsSelectedAndReady;

	return NO;
}




@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  StatusSidebar
// ------------------------------------------------------------------------------------
// MARK: -

const CGFloat collapsedWidth =  3;	// This is the width of the view in its collapsed form
const CGFloat  expandedWidth = 148;	// This is the width of the view in its expanded form

@implementation StatusSidebarSplitView

- (NSString*) isMinimizedAutoSaveName { return fstr(@"File:%@:StatusSidebarIsMinimized", parentView.myDocument.documentNameForAutosave); }

- (void) awakeFromNib
{
	self.delegate = self;

	statusSidebarContent.contentView = expandedStatusSidebarGroup;

	viewAnimation = [[NSViewAnimation alloc] init];
	viewAnimation.animationBlockingMode = NSAnimationBlocking;
	viewAnimation.animationCurve = NSAnimationEaseInOut;
	viewAnimation.delegate = self;
	
	BOOL shouldBeMinimized = [NSUserDefaults.standardUserDefaults boolForKey:self.isMinimizedAutoSaveName];
	if (shouldBeMinimized)
		[self minimize:self];
	else
		[self maximize:self];
}

- (CGFloat) targetDividerPosition					{ return self.frame.size.width - (minimized ? collapsedWidth : expandedWidth); }

- (void) animationDidEnd:(NSAnimation*)animation	{ [self setPosition:self.targetDividerPosition ofDividerAtIndex:0]; }


- (void) animateContentToNewFrame:(NSRect)endFrame
{
	[viewAnimation stopAnimation];
	
	float duration = ([self.window.currentEvent modifierFlags] & NSShiftKeyMask) ? 1.25 : 0.25;
	viewAnimation.duration = duration;
	
	NSDictionary* resizeDictionary = @{NSViewAnimationTargetKey: theContent,
									  NSViewAnimationStartFrameKey: [NSValue valueWithRect:theContent.frame],
									  NSViewAnimationEndFrameKey: [NSValue valueWithRect:endFrame]};
	
	NSArray* animationArray = @[resizeDictionary];
	viewAnimation.viewAnimations = animationArray;
	[viewAnimation startAnimation];	
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  StatusSidebarSplitview actions 
// ------------------------------------------------------------------------------------

- (IBAction) maximize:(id)sender
{
	[NSUserDefaults.standardUserDefaults setBool:NO  forKey:self.isMinimizedAutoSaveName];
	if (!minimized)
		return;

	dividerStatusBox.hidden = YES;
	[toggleStatusSidebarButton setImage:[NSImage imageNamed:@"SidebarClose"]];
	[toggleStatusSidebarButton setAction:@selector(minimize:)];

	minimized = NO;
	NSRect endFrame = self.frame;
	endFrame.size.width -= expandedWidth;
	[self animateContentToNewFrame:endFrame];
}

- (IBAction) minimize:(id)sender
{
	[NSUserDefaults.standardUserDefaults setBool:YES  forKey:self.isMinimizedAutoSaveName];
	if (minimized)
		return;

	dividerStatusBox.hidden = NO;
	[toggleStatusSidebarButton setImage:[NSImage imageNamed:@"SidebarOpen"]];
	[toggleStatusSidebarButton setAction:@selector(maximize:)];

	minimized = YES;
	NSRect endFrame = self.frame;
	endFrame.size.width -= collapsedWidth;
	[self animateContentToNewFrame:endFrame];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Splitview delegates 
// ------------------------------------------------------------------------------------

- (CGFloat) splitView:(NSSplitView*)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
	if (viewAnimation.isAnimating)
		return theContent.frame.size.width;

	CGFloat crossOverPoint = self.frame.size.width - (expandedWidth+collapsedWidth)/2;
	if (minimized && proposedPosition<(crossOverPoint - 3))
		[self maximize:self];
	else if (!minimized && proposedPosition>(crossOverPoint + 3))
		[self minimize:self];
	return self.targetDividerPosition;
}

- (CGFloat)splitView:(NSSplitView*)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return self.frame.size.width - collapsedWidth;
}

- (CGFloat)splitView:(NSSplitView*)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	return self.frame.size.width - expandedWidth;
}

- (void) splitView:(NSSplitView*)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{	
	NSRect contentFrame	= theContent.frame;
	NSRect sidebarFrame	= theSidebar.frame;
	if (viewAnimation.isAnimating)
	{
		sidebarFrame.origin.x = contentFrame.size.width;		
		sidebarFrame.size.width = self.frame.size.width - contentFrame.size.width;
	}
	else
	{
		sidebarFrame.size.width = minimized ? collapsedWidth : expandedWidth;
		contentFrame.size.width = self.frame.size.width - sidebarFrame.size.width;
		sidebarFrame.origin.x = contentFrame.size.width;
	}
	theContent.frame = contentFrame;
	theSidebar.frame = sidebarFrame;
	[self adjustSubviews];
}

- (void) splitViewDidResizeSubviews:(NSNotification*)notification
{
	[self display];
}

@end
