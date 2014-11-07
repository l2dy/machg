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
#import "AlterDetailsSheetController.h"
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  HistoryViewController
// ------------------------------------------------------------------------------------
// MARK: -

@implementation HistoryViewController
@synthesize myDocument = myDocument_;
@synthesize theHistoryView = theHistoryView_;

- (HistoryViewController*) initHistoryViewControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithNibName:@"HistoryView" bundle:nil];
	[self loadView];
	return self;
}

- (void) dealloc
{
	[self stopObserving];
}

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  HistoryView
// ------------------------------------------------------------------------------------
// MARK: -

@implementation HistoryView

@synthesize myDocument = myDocument_;
@synthesize parentController = parentController_;
@synthesize logTableView = logTableView_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
}


- (void) awakeFromNib
{
	myDocument_ = [parentController_ myDocument];
	[self observe:kRepositoryDataDidChange	from:myDocument_  byCalling:@selector(refreshHistoryView:)];
	[self observe:kRepositoryDataIsNew		from:myDocument_  byCalling:@selector(refreshHistoryView:)];
	[self observe:kLogEntriesDidChange		from:myDocument_  byCalling:@selector(refreshHistoryView:)];

	[self openSplitViewPaneToDefaultHeight: self];
	NSString* fileName = [myDocument_ documentNameForAutosave];
	[logTableView_ setAutosaveTableColumns:YES];
	[logTableView_ setAutosaveName:fstr(@"File:%@:HistoryTableViewColumnPositions", fileName)];
	[logTableView_ resetTable:self];
	[theLabelsTableView_ setAutosaveTableColumns:YES];
	[theLabelsTableView_ setAutosaveName:fstr(@"File:%@:HistoryLabelsTableViewColumnPositions", fileName)];
	
	[logTableView_ setTarget:self];
	[logTableView_ setDoubleAction:@selector(historyMenuDiffSelectedRevisions:)];
	
	[[myDocument_ mainWindow] makeFirstResponder:logTableView_];
}


- (void) restoreConcertinaSplitViewPositions
{
	if (IsNotEmpty([concertinaView autosavePositionName]))
		return;
	NSString* fileName = [myDocument_ documentNameForAutosave];
	NSString* autoSaveNameForConcertina = fstr(@"File:%@:HistoryViewConcertinaPositions", fileName);
	[concertinaView setAutosavePositionName:autoSaveNameForConcertina];
	[concertinaView restorePositionsFromDefaults];	
}


-(void) dealloc
{
	[self stopObserving];
}


- (void) prepareToOpenHistoryView
{
	[self resetHistoryView:self];
	[[myDocument_ mainWindow] makeFirstResponder:logTableView_];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Notifications & Updating
// ------------------------------------------------------------------------------------

- (NSString*) searchCaption		{ return fstr(@"%lu entries shown", (unsigned long)[[logTableView_ theTableRows] count]); }

- (NSString*) searchFieldValue	{ return [myDocument_ toolbarSearchFieldValue]; }


- (IBAction) refreshHistoryView:(id)sender
{
	NSString* newSearchMessage = IsEmpty([[myDocument_ toolbarSearchField] stringValue]) ? @"Search" : [self searchCaption];
	[[myDocument_ toolbarSearchItem] setLabel:newSearchMessage];
	[logTableView_ refreshTable:self];
	[theLabelsTableView_ refreshTable:self];
}

- (IBAction) resetHistoryView:(id)sender
{
	NSString* newSearchMessage = IsEmpty([[myDocument_ toolbarSearchField] stringValue]) ? @"Search" : [self searchCaption];
	[[myDocument_ toolbarSearchItem] setLabel:newSearchMessage];
	[logTableView_ resetTable:self];
	[theLabelsTableView_ resetTable:self];
}

- (IBAction) forceReinitilizeHistoryViews:(id)sender
{
	changesetHashToLogRecord = [[NSMutableDictionary alloc]init];
	[myDocument_ initializeRepositoryData];
	[self resetHistoryView:sender];
}

- (void) scrollToSelected
{
	[logTableView_ scrollToSelected:self];
}

- (void) expandLabelsTableinConcertina
{
	[concertinaView expandPane:theLabelsTableView_ toPecentageHeight:0.5];
}

- (void) manageLabelsOfType:(LabelType)labelTypes
{
	[myDocument_ actionSwitchViewToHistoryView:self];
	[self expandLabelsTableinConcertina];
	[theLabelsTableView_ setButtonsFromLabelType:labelTypes];
	[theLabelsTableView_ resetTable:self];
}



// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  General Menu Items
// ------------------------------------------------------------------------------------

- (IBAction) mainMenuRevertAllFiles:(id)sender			{ [myDocument_ primaryActionRevertFiles:[myDocument_ absolutePathOfRepositoryRootAsArray] toVersion:nil]; }
- (IBAction) toolbarRevertFiles:(id)sender				{ [self mainMenuRevertAllFiles:sender]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: History Altering Actions
// ------------------------------------------------------------------------------------

- (IBAction) mainMenuCollapseChangesets:(id)sender		{ [[myDocument_ theCollapseSheetController]		openCollapseSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuAlterDetails:(id)sender			{ [[myDocument_ theAlterDetailsSheetController]	openAlterDetailsChooseChangesetSheet:sender]; }
- (IBAction) mainMenuHistoryEditChangesets:(id)sender	{ [[myDocument_ theHistoryEditSheetController]	openHistoryEditSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuStripChangesets:(id)sender			{ [[myDocument_ theStripSheetController]		openStripSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuRebaseChangesets:(id)sender		{ [[myDocument_ theRebaseSheetController]		openRebaseSheetWithSelectedRevisions:sender]; }
- (IBAction) mainMenuBackoutChangeset:(id)sender		{ [[myDocument_ theBackoutSheetController]		openBackoutSheetWithSelectedRevision:sender]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Contextual Menus
// ------------------------------------------------------------------------------------

- (IBAction) historyMenuAddLabelToChosenRevision:(id)sender
{
	[[myDocument_ toolbarSearchField] setStringValue:@""];	// reset the search term
	[[myDocument_ theAddLabelSheetController] openAddLabelSheet:self];
}

- (IBAction) historyMenuDiffAllToChosenRevision:(id)sender
{
	NSArray* rootPathAsArray = @[ [myDocument_ absolutePathOfRepositoryRoot] ];
	NSNumber* theSelectedRevision = [[logTableView_ chosenEntry] revision];
	[myDocument_ viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:numberAsString(theSelectedRevision)];
}


- (IBAction) historyMenuUpdateRepositoryToChosenRevision:(id)sender
{
	NSNumber* theSelectedRevision = [[logTableView_ chosenEntry] revision];
	[myDocument_ primaryActionUpdateFilesToVersion:theSelectedRevision withCleanOption:NO withConfirmation:YES];
}

- (IBAction) historyMenuGotoChangeset:(id)sender
{
	[logTableView_ getAndScrollToChangeset:self];
}

- (IBAction) historyMenuMergeRevision:(id)sender
{
	NSNumber* theSelectedRevision = [[logTableView_ chosenEntry] revision];
	[myDocument_ primaryActionMergeWithVersion:theSelectedRevision andOptions:nil withConfirmation:YES];
}

- (IBAction) historyMenuManifestOfChosenRevision:(id)sender
{
	NSNumber* theSelectedRevision = [[logTableView_ chosenEntry] revision];
	[myDocument_ primaryActionDisplayManifestForVersion:theSelectedRevision];
}

- (IBAction) historyMenuViewRevisionDifferences:(id)sender
{
	LowHighPair pair = [logTableView_ lowestToHighestSelectedRevisions];
	LogEntry* lowRevEntry = [logTableView_ entryForTableRow:pair.lowRevision];
	NSArray* parents = [lowRevEntry parentsOfEntry];
	if ([parents count] == 0)
		pair.lowRevision = MAX(0,pair.lowRevision - 1);	// Step back one to see the differences from the previous version to this version.
	else
		pair.lowRevision = numberAsInt(parents[0]);
	NSValue* pairAsValue = MakeNSValue(LowHighPair, pair);

	[myDocument_ actionSwitchViewToDifferencesView:sender];
	NSTimeInterval t = [[NSAnimationContext currentContext] duration];
	[[myDocument_ theDifferencesView] performSelector:@selector(compareLowHighValue:) withObject:pairAsValue afterDelay:t];
}

- (IBAction) historyMenuDiffSelectedRevisions:(id)sender
{
	NSArray* rootPathAsArray = [myDocument_ absolutePathOfRepositoryRootAsArray];
	LowHighPair pair = [logTableView_ parentToHighestSelectedRevisions];
	NSString* revisionNumbers = fstr(@"%ld:%ld", pair.lowRevision, pair.highRevision);
	[myDocument_ viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:revisionNumbers];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  LogTableView Actions
// ------------------------------------------------------------------------------------


- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	if ([myDocument_ quicklookPreviewIsVisible])
		[[QLPreviewPanel sharedPreviewPanel] reloadData];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Labels Actions
// ------------------------------------------------------------------------------------

- (IBAction) labelsMenuMoveChosenLabel:(id) sender
{
	LabelData* label = [theLabelsTableView_ chosenLabel];
	if (!label)
	{
		PlayBeep();
		RunAlertPanel(@"No Label Selected", @"You need to select a label first to move it", @"OK", nil, nil);
		return;
	}
	[[myDocument_ theMoveLabelSheetController] openMoveLabelSheetForMoveLabel:label];
}



- (IBAction) labelsMenuRemoveChosenLabel:(id) sender
{
	LabelData* label = [theLabelsTableView_ chosenLabel];
	if (!label)
	{
		PlayBeep();
		RunAlertPanel(@"No Label Selected", @"You need to select a label first to remove it", @"OK", nil, nil);
		return;
	}
	
	NSNumber* rev    = [label revision];
	NSString* name   = [label name];
	
	
	
	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];
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
			[myDocument_ executeMercurialWithArgs:argsTag fromRoot:rootPath whileDelayingEvents:YES];
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
			[myDocument_ executeMercurialWithArgs:argsTag fromRoot:rootPath whileDelayingEvents:YES];
			break;
		}
		case eActiveBranch:
		case eInactiveBranch:
		case eClosedBranch:
		{
			BOOL needToUpdateToNewRevision = (![[[myDocument_ repositoryData] getHGParent1Revision] isEqualToNumber:rev]);
			
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
			if (![[[myDocument_ repositoryData] getHGParent1Revision] isEqualToNumber:rev])
			{
				BOOL didUpdateToReversion = [myDocument_ primaryActionUpdateFilesToVersion:rev withCleanOption:NO withConfirmation:YES];
				if (!didUpdateToReversion)
					return;
			}
			
			NSMutableArray* argsTag = [NSMutableArray arrayWithObjects:@"branch", @"--clean", nil];
			[myDocument_ executeMercurialWithArgs:argsTag fromRoot:rootPath whileDelayingEvents:YES];
			break;
		}
			
		default:
			break;
	}
}

- (IBAction) labelsMenuUpdateRepositoryToChosenRevision:(id)sender
{
	LabelData* label = [theLabelsTableView_ chosenLabel];
	[[[myDocument_ theHistoryView] logTableView] scrollToRevision:[label revision]];
	[myDocument_ primaryActionUpdateFilesToVersion:[label revision] withCleanOption:NO withConfirmation:YES];
}



// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Standard  Menu Actions
// ------------------------------------------------------------------------------------

- (IBAction) mainMenuCommitAllFiles:(id)sender					{ [[myDocument_ theCommitSheetController] openCommitSheetWithAllFiles:sender]; }
- (IBAction) toolbarCommitFiles:(id)sender						{ [self mainMenuCommitAllFiles:sender]; }

- (IBAction) mainMenuDiffAllFiles:(id)sender					{ [myDocument_ viewDifferencesInCurrentRevisionFor:[myDocument_ absolutePathOfRepositoryRootAsArray] toRevision:nil]; }	// nil indicates the current revision
- (IBAction) toolbarDiffFiles:(id)sender						{ [self historyMenuDiffSelectedRevisions:sender]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Validation
// ------------------------------------------------------------------------------------

- (BOOL) chosenRevisionsContainsIncompleteRevision
{
	if (![[myDocument_ repositoryData] includeIncompleteRevision])
		return NO;
	NSString* incompleteRevisionString = intAsString([[myDocument_ repositoryData] computeNumberOfRevisions]);
	return [[logTableView_ chosenRevisions] containsObject:incompleteRevisionString];
}

- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem, NSObject >)anItem
{
	SEL theAction = [anItem action];
	
	if (theAction == @selector(mainMenuCommitAllFiles:))						return [myDocument_ localRepoIsSelectedAndReady] && [myDocument_ validateAndSwitchMenuForCommitAllFiles:anItem];
	if (theAction == @selector(toolbarCommitFiles:))							return [myDocument_ localRepoIsSelectedAndReady] && [myDocument_ toolbarActionAppliesToFilesWith:eHGStatusCommittable];

	if (theAction == @selector(mainMenuDiffAllFiles:))							return [myDocument_ localRepoIsSelectedAndReady] && [myDocument_ repositoryHasFilesWhichContainStatus:eHGStatusModified];
	if (theAction == @selector(toolbarDiffFiles:))								return [myDocument_ localRepoIsSelectedAndReady] && ![logTableView_ noRevisionSelected];
	
	// ------
	if (theAction == @selector(mainMenuRollbackCommit:))						return [myDocument_ localRepoIsSelectedAndReady] && [myDocument_ showingFilesOrHistoryView] && [[myDocument_ repositoryData] isRollbackInformationAvailable];
	
	
	// History only methods
	if (theAction == @selector(mainMenuCollapseChangesets:))					return [myDocument_ localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuAlterDetails:))							return [myDocument_ localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuHistoryEditChangesets:))					return [myDocument_ localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuStripChangesets:))						return [myDocument_ localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuRebaseChangesets:))						return [myDocument_ localRepoIsSelectedAndReady] && AllowHistoryEditingOfRepositoryFromDefaults();
	if (theAction == @selector(mainMenuBackoutChangeset:))						return [myDocument_ localRepoIsSelectedAndReady] && ![myDocument_ repositoryHasFilesWhichContainStatus:eHGStatusChangedInSomeWay];
	
	// HistoryView contextual items
	if (theAction == @selector(historyMenuAddLabelToChosenRevision:))			return [myDocument_ localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuDiffSelectedRevisions:))				return [myDocument_ localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuDiffAllToChosenRevision:))			return [myDocument_ localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuUpdateRepositoryToChosenRevision:))	return [myDocument_ localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuGotoChangeset:))						return [myDocument_ localRepoIsSelectedAndReady] && [myDocument_ showingHistoryView];
	if (theAction == @selector(historyMenuMergeRevision:))						return [myDocument_ localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuManifestOfChosenRevision:))			return [myDocument_ localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];
	// -------
	if (theAction == @selector(historyMenuViewRevisionDifferences:))			return [myDocument_ localRepoIsSelectedAndReady] && ![self chosenRevisionsContainsIncompleteRevision];

	// Labels contextual items
	if (theAction == @selector(labelsMenuMoveChosenLabel:))						return [myDocument_ localRepoIsSelectedAndReady] && [theLabelsTableView_ chosenLabel] && ![[theLabelsTableView_ chosenLabel] isOpenHead];
	if (theAction == @selector(labelsMenuRemoveChosenLabel:))					return [myDocument_ localRepoIsSelectedAndReady] && [theLabelsTableView_ chosenLabel] && ![[theLabelsTableView_ chosenLabel] isOpenHead];
	// -------
	if (theAction == @selector(labelsMenuUpdateRepositoryToChosenRevision:))	return [myDocument_ localRepoIsSelectedAndReady] && [theLabelsTableView_ chosenLabel];
	
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Quicklook Handling
// ------------------------------------------------------------------------------------

- (NSArray*) quickLookPreviewItems
{	
	NSArray* entries = [logTableView_ selectedEntries];
	if ([entries count] <= 0)
		return @[];
		
	for (LogEntry* entry in entries)
		 if (![entry isFullyLoaded])
			 [entry fullyLoadEntry];

	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];
	NSMutableArray* quickLookPreviewItems = [[NSMutableArray alloc] init];
	NSMutableSet* absolutePaths = [[NSMutableSet alloc]init];

	LogEntry* highestEntry = [logTableView_ highestSelectedEntry];
	NSString* highestSelectedChangeset = [highestEntry changeset];
	NSRect itemRect = [logTableView_ rectOfRowInWindow:[logTableView_ tableRowForRevision:[highestEntry revision]]];

	for (LogEntry* entry in entries)
	{
		for (NSString* path in [entry filesAdded])
			[absolutePaths addObject:[rootPath stringByAppendingPathComponent:path]];
		for (NSString* path in [entry filesModified])
			 [absolutePaths addObject:[rootPath stringByAppendingPathComponent:path]];
	}

	for (NSString* absolutePath in absolutePaths)
	{
		NSString* pathOfCachedCopy = [myDocument_ loadCachedCopyOfPath:absolutePath forChangeset:highestSelectedChangeset];
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
        [myDocument_ togglePreviewPanel:self];
	else
        [super keyDown:theEvent];
}


@end