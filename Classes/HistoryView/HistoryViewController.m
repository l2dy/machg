//
//  HistoryViewController.m
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "HistoryViewController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LabelsTableView.h"
#import "LabelData.h"
#import "BackoutSheetController.h"
#import "CloneSheetController.h"
#import "CollapseSheetController.h"
#import "CommitSheetController.h"
#import "StripSheetController.h"
#import "HistoryEditSheetController.h"
#import "RebaseSheetController.h"
#import "RevertSheetController.h"
#import "UpdateSheetController.h"
#import "DifferencesViewController.h"
#import "ResultsWindowController.h"
#import "LogTableView.h"
#import "AddLabelSheetController.h"
#import "MoveLabelSheetController.h"
#import "JHConcertinaView.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HistoryViewController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation HistoryViewController
@synthesize myDocument;
@synthesize theHistoryView;

- (HistoryViewController*) initHistoryViewControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"HistoryView" owner:self];
	return self;
}

- (void) unload
{
	[theHistoryView unload];
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HistoryView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation HistoryView

@synthesize myDocument;
@synthesize logTableView;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
}


- (void) awakeFromNib
{
	myDocument = [parentController myDocument];
	[self observe:kRepositoryDataDidChange	from:[self myDocument]  byCalling:@selector(refreshHistoryView:)];
	[self observe:kRepositoryDataIsNew		from:[self myDocument]  byCalling:@selector(refreshHistoryView:)];
	[self observe:kLogEntriesDidChange		from:[self myDocument]  byCalling:@selector(refreshHistoryView:)];

	[self openSplitViewPaneToDefaultHeight: self];
	NSString* fileName = [myDocument documentNameForAutosave];
	[logTableView setAutosaveTableColumns:YES];
	[logTableView setAutosaveName:fstr(@"File:%@:HistoryTableViewColumnPositions", fileName)];
	[logTableView resetTable:self];
	[theLabelsTableView_ setAutosaveTableColumns:YES];
	[theLabelsTableView_ setAutosaveName:fstr(@"File:%@:HistoryLabelsTableViewColumnPositions", fileName)];
	
	[logTableView setTarget:self];
	[logTableView setDoubleAction:@selector(diffSelectedRevisions:)];
	
	[[myDocument mainWindow] makeFirstResponder:logTableView];
}


- (void) restoreConcertinaSplitViewPositions
{
	if (IsNotEmpty([concertinaView autosavePositionName]))
		return;
	NSString* fileName = [myDocument documentNameForAutosave];
	NSString* autoSaveNameForConcertina = fstr(@"File:%@:HistoryViewConcertinaPositions", fileName);
	[concertinaView setAutosavePositionName:autoSaveNameForConcertina];
	[concertinaView restorePositionsFromDefaults];	
}


-(void) unload
{
	[self stopObserving];
	[logTableView unload];
	logTableView = nil;
}


- (void) prepareToOpenHistoryView
{
	[self resetHistoryView:self];
	[[myDocument mainWindow] makeFirstResponder:logTableView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Notifications & Updating
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) searchCaption		{ return fstr(@"%d entries shown", [[logTableView theTableRows] count]); }

- (NSString*) searchFieldValue	{ return [myDocument toolbarSearchFieldValue]; }


- (IBAction) refreshHistoryView:(id)sender
{
	NSString* newSearchMessage = IsEmpty([[myDocument toolbarSearchField] stringValue]) ? @"Search" : [self searchCaption];
	[[myDocument toolbarSearchItem] setLabel:newSearchMessage];
	[logTableView refreshTable:self];
	[theLabelsTableView_ refreshTable:self];
}

- (IBAction) resetHistoryView:(id)sender
{
	NSString* newSearchMessage = IsEmpty([[myDocument toolbarSearchField] stringValue]) ? @"Search" : [self searchCaption];
	[[myDocument toolbarSearchItem] setLabel:newSearchMessage];
	[logTableView resetTable:self];
	[theLabelsTableView_ resetTable:self];
}

- (void) scrollToSelected
{
	[logTableView scrollToSelected:self];
}

- (void) expandLabelsTableinConcertina
{
	[concertinaView expandPane:theLabelsTableView_ toPecentageHeight:0.5];
}

- (void) manageLabelsOfType:(LabelType)labelTypes
{
	[myDocument actionSwitchViewToHistoryView:self];
	[self expandLabelsTableinConcertina];
	[theLabelsTableView_ setButtonsFromLabelType:labelTypes];
	[theLabelsTableView_ resetTable:self];
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  General Menu Items
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuRevertAllFiles:(id)sender			{ [myDocument primaryActionRevertFiles:[myDocument absolutePathOfRepositoryRootAsArray] toVersion:nil]; }
- (IBAction) toolbarRevertFiles:(id)sender				{ [self mainMenuRevertAllFiles:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: History Altering Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuCollapseChangesets:(id)sender		{ [[myDocument theCollapseSheetController]		openCollapseSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuHistoryEditChangesets:(id)sender	{ [[myDocument theHistoryEditSheetController]	openHistoryEditSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuStripChangesets:(id)sender			{ [[myDocument theStripSheetController]			openStripSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuRebaseChangesets:(id)sender		{ [[myDocument theRebaseSheetController]		openRebaseSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuBackoutChangeset:(id)sender		{ [[myDocument theBackoutSheetController]		openBackoutSheetWithSelectedRevision:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Contextual Menus
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) historyMenuAddLabelToChosenRevision:(id)sender
{
	[[myDocument toolbarSearchField] setStringValue:@""];	// reset the search term
	[[myDocument theAddLabelSheetController] openAddLabelSheet:self];
}

- (IBAction) historyMenuDiffAllToChosenRevision:(id)sender
{
	NSArray* rootPathAsArray = [NSArray arrayWithObject:[myDocument absolutePathOfRepositoryRoot]];
	NSNumber* theSelectedRevision = [[logTableView chosenEntry] revision];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:numberAsString(theSelectedRevision)];
}


- (IBAction) historyMenuUpdateRepositoryToChosenRevision:(id)sender
{
	NSNumber* theSelectedRevision = [[logTableView chosenEntry] revision];
	[myDocument primaryActionUpdateFilesToVersion:theSelectedRevision withCleanOption:NO];
}

- (IBAction) historyMenuGotoChangeset:(id)sender
{
	[logTableView getAndScrollToChangeset:self];
}

- (IBAction) historyMenuMergeRevision:(id)sender
{
	NSNumber* theSelectedRevision = [[logTableView chosenEntry] revision];
	[myDocument primaryActionMergeWithVersion:theSelectedRevision andOptions:nil withConfirmation:YES];
}

- (IBAction) historyMenuManifestOfChosenRevision:(id)sender
{
	NSNumber* theSelectedRevision = [[logTableView chosenEntry] revision];
	[myDocument primaryActionDisplayManifestForVersion:theSelectedRevision];
}

- (IBAction) historyMenuViewRevisionDifferences:(id)sender
{
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];
	LogEntry* lowRevEntry = [logTableView entryForTableRow:pair.lowRevision];
	NSArray* parents = [lowRevEntry parentsOfEntry];
	if ([parents count] == 0)
		pair.lowRevision = MAX(0,pair.lowRevision - 1);	// Step back one to see the differences from the previous version to this version.
	else
		pair.lowRevision = numberAsInt([parents objectAtIndex:0]);
	NSValue* pairAsValue = MakeNSValue(LowHighPair, pair);

	[myDocument actionSwitchViewToDifferencesView:sender];
	NSTimeInterval t = [[NSAnimationContext currentContext] duration];
	[[myDocument theDifferencesView] performSelector:@selector(compareLowHighValue:) withObject:pairAsValue afterDelay:t];
}






// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  LogTableView Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) diffSelectedRevisions:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	LowHighPair pair = [logTableView parentToHighestSelectedRevisions];
	NSString* revisionNumbers = fstr(@"%d%:%d", pair.lowRevision, pair.highRevision);
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:revisionNumbers];
}

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	if ([myDocument quicklookPreviewIsVisible])
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Labels Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) labelsMenuMoveChosenLabel:(id) sender
{
	LabelData* label = [theLabelsTableView_ chosenLabel];
	if (!label)
	{
		PlayBeep();
		NSRunAlertPanel(@"No Label Selected", @"You need to select a label first to move it", @"OK", nil, nil);
		return;
	}
	[[myDocument theMoveLabelSheetController] openMoveLabelSheetForMoveLabel:label];
}



- (IBAction) labelsMenuRemoveChosenLabel:(id) sender
{
	LabelData* label = [theLabelsTableView_ chosenLabel];
	if (!label)
	{
		PlayBeep();
		NSRunAlertPanel(@"No Label Selected", @"You need to select a label first to remove it", @"OK", nil, nil);
		return;
	}
	
	NSNumber* rev    = [label revision];
	NSString* name   = [label name];
	
	
	
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	switch ([label labelType])
	{
		case eLocalTag:
		case eGlobalTag:
		{
			if (DisplayWarningForTagRemovalFromDefaults())
			{
				NSString* subMessage = fstr(@"Are you sure you want to remove the tag “%@” from revision “%@”?", name, rev);
				int result = RunCriticalAlertPanelWithSuppression(@"Removing Selected Label", subMessage, @"Remove", @"Cancel", MHGDisplayWarningForTagRemoval);
				if (result != NSAlertFirstButtonReturn)
					return;
			}
			
			NSMutableArray* argsTag = [NSMutableArray arrayWithObject:@"tag"];
			if ([label labelType] == eLocalTag)
				[argsTag addObject:@"--local"];
			[argsTag addObject:@"--remove" followedBy:name];
			[myDocument executeMercurialWithArgs:argsTag fromRoot:rootPath whileDelayingEvents:YES];
			break;
		}
		case eBookmark:
		{
			if (DisplayWarningForTagRemovalFromDefaults())
			{
				NSString* subMessage = fstr(@"Are you sure you want to remove the bookmark “%@” from revision “%@”?", name, rev);
				int result = RunCriticalAlertPanelWithSuppression(@"Removing Selected Label", subMessage, @"Remove", @"Cancel", MHGDisplayWarningForTagRemoval);
				if (result != NSAlertFirstButtonReturn)
					return;
			}
			NSMutableArray* argsTag = [NSMutableArray arrayWithObjects:@"bookmarks", @"--delete", name, nil];
			[myDocument executeMercurialWithArgs:argsTag fromRoot:rootPath whileDelayingEvents:YES];
			break;
		}
		case eActiveBranch:
		case eInactiveBranch:
		case eClosedBranch:
		{
			BOOL needToUpdateToNewRevision = (![[[myDocument repositoryData] getHGParent1Revision] isEqualToNumber:rev]);
			
			if (DisplayWarningForTagRemovalFromDefaults())
			{
				NSString* subMessage;
				if (needToUpdateToNewRevision)
					subMessage = fstr(@"Are you sure you want to remove the branch “%@” from revision “%@”? (To do this Mercurial needs to update your repository to revision “%@”.)", name, rev);
				else
					subMessage = fstr(@"Are you sure you want to remove the branch “%@” from revision “%@”?", name, rev);
				
				int result = RunCriticalAlertPanelWithSuppression(@"Removing Selected Label", subMessage, @"Remove", @"Cancel", MHGDisplayWarningForTagRemoval);
				if (result != NSAlertFirstButtonReturn)
					return;
			}
			if (![[[myDocument repositoryData] getHGParent1Revision] isEqualToNumber:rev])
			{
				BOOL didUpdateToReversion = [myDocument primaryActionUpdateFilesToVersion:rev withCleanOption:NO];
				if (!didUpdateToReversion)
					return;
			}
			
			NSMutableArray* argsTag = [NSMutableArray arrayWithObjects:@"branch", @"--clean", nil];
			[myDocument executeMercurialWithArgs:argsTag fromRoot:rootPath whileDelayingEvents:YES];
			break;
		}
			
		default:
			break;
	}
}

- (IBAction) labelsMenuUpdateRepositoryToChosenRevision:(id)sender
{
	LabelData* label = [theLabelsTableView_ chosenLabel];
	[[[myDocument theHistoryView] logTableView] scrollToRevision:[label revision]];
	[myDocument primaryActionUpdateFilesToVersion:[label revision] withCleanOption:NO];
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Standard  Menu Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) mainMenuCommitAllFiles:(id)sender					{ [[myDocument theCommitSheetController] openCommitSheetWithAllFiles:sender]; }
- (IBAction) toolbarCommitFiles:(id)sender						{ [self mainMenuCommitAllFiles:sender]; }

- (IBAction) mainMenuDiffAllFiles:(id)sender					{ [myDocument viewDifferencesInCurrentRevisionFor:[myDocument absolutePathOfRepositoryRootAsArray] toRevision:nil]; }	// nil indicates the current revision
- (IBAction) toolbarDiffFiles:(id)sender						{ [self diffSelectedRevisions:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) chosenRevisionsContainsIncompleteRevision
{
	if (![[myDocument repositoryData] includeIncompleteRevision])
		return NO;
	NSString* incompleteRevisionString = intAsString([[myDocument repositoryData] computeNumberOfRevisions]);
	return [[[self logTableView] chosenRevisions] containsObject:incompleteRevisionString];
}

- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem, NSObject >)anItem
{
	SEL theAction = [anItem action];
	
	if (theAction == @selector(mainMenuCommitAllFiles:))						return [myDocument localRepoIsSelectedAndReady] && [myDocument validateAndSwitchMenuForCommitAllFiles:anItem];
	if (theAction == @selector(toolbarCommitFiles:))							return [myDocument localRepoIsSelectedAndReady] && [myDocument toolbarActionAppliesToFilesWith:eHGStatusCommittable];

	if (theAction == @selector(mainMenuDiffAllFiles:))							return [myDocument localRepoIsSelectedAndReady] && [myDocument repositoryHasFilesWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(toolbarDiffFiles:))								return [myDocument localRepoIsSelectedAndReady] && ![logTableView noRevisionSelected];
	
	// ------
	if (theAction == @selector(mainMenuRollbackCommit:))						return [myDocument localRepoIsSelectedAndReady] && [myDocument showingFilesOrHistoryView] && [[myDocument repositoryData] isRollbackInformationAvailable];
	
	
	// History only methods
	if (theAction == @selector(mainMenuCollapseChangesets:))					return [myDocument localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuHistoryEditChangesets:))					return [myDocument localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuStripChangesets:))						return [myDocument localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuRebaseChangesets:))						return [myDocument localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuBackoutChangeset:))						return [myDocument localRepoIsSelectedAndReady] && ![myDocument repositoryHasFilesWhichContainStatus:eHGStatusChangedInSomeWay];
	
	// HistoryView contextual items
	if (theAction == @selector(historyMenuAddLabelToChosenRevision:))			return [myDocument localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuDiffAllToChosenRevision:))			return [myDocument localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuUpdateRepositoryToChosenRevision:))	return [myDocument localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuGotoChangeset:))						return [myDocument localRepoIsSelectedAndReady] && [myDocument showingHistoryView];
	if (theAction == @selector(historyMenuMergeRevision:))						return [myDocument localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuManifestOfChosenRevision:))			return [myDocument localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	// -------
	if (theAction == @selector(historyMenuViewRevisionDifferences:))			return [myDocument localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];

	// Labels contextual items
	if (theAction == @selector(labelsMenuMoveChosenLabel:))						return [myDocument localRepoIsSelectedAndReady] && [theLabelsTableView_ chosenLabel] && ![[theLabelsTableView_ chosenLabel] isOpenHead];
	if (theAction == @selector(labelsMenuRemoveChosenLabel:))					return [myDocument localRepoIsSelectedAndReady] && [theLabelsTableView_ chosenLabel] && ![[theLabelsTableView_ chosenLabel] isOpenHead];
	// -------
	if (theAction == @selector(labelsMenuUpdateRepositoryToChosenRevision:))	return [myDocument localRepoIsSelectedAndReady] && [theLabelsTableView_ chosenLabel];
	
	return NO;
}

// Maybe move this to the parent controller for the LabelsTableView
- (IBAction) validateButtons:(id)sender
{
	LabelData* label = [theLabelsTableView_ selectedLabel];
	BOOL newState = (label && ![label isOpenHead]);
	dispatch_async(mainQueue(), ^{
		[removeLabelButton setEnabled:newState]; });
}


- (void)	labelsChanged
{
	[self validateButtons:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quicklook Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSArray*) quickLookPreviewItems
{	
	NSArray* entries = [logTableView selectedEntries];
	if ([entries count] <= 0)
		return [NSArray array];
		
	for (LogEntry* entry in entries)
		 if (![entry isFullyLoaded])
			 [entry fullyLoadEntry];

	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* quickLookPreviewItems = [[NSMutableArray alloc] init];
	NSMutableSet* absolutePaths = [[NSMutableSet alloc]init];

	LogEntry* highestEntry = [logTableView highestSelectedEntry];
	NSString* highestSelectedChangeset = [highestEntry changeset];
	NSRect itemRect = [logTableView rectOfRowInWindow:[logTableView tableRowForRevision:[highestEntry revision]]];

	for (LogEntry* entry in entries)
	{
		for (NSString* path in [entry filesAdded])
			[absolutePaths addObject:[rootPath stringByAppendingPathComponent:path]];
		for (NSString* path in [entry filesModified])
			 [absolutePaths addObject:[rootPath stringByAppendingPathComponent:path]];
	}

	for (NSString* absolutePath in absolutePaths)
	{
		NSString* pathOfCachedCopy = [myDocument loadCachedCopyOfPath:absolutePath forChangeset:highestSelectedChangeset];
		if (pathOfCachedCopy)
			[quickLookPreviewItems addObject:[PathQuickLookPreviewItem previewItemForPath:pathOfCachedCopy withRect:itemRect]];
	}
	
	return quickLookPreviewItems;
}

- (NSInteger) numberOfQuickLookPreviewItems		{ return [[self quickLookPreviewItems] count]; }

- (void) keyDown:(NSEvent *)theEvent
{
    NSString* key = [theEvent charactersIgnoringModifiers];
    if ([key isEqual:@" "])
        [[self myDocument] togglePreviewPanel:self];
	else
        [super keyDown:theEvent];
}


@end