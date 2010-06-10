//
//  HistoryPaneController.m
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "HistoryPaneController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LabelsTableView.h"
#import "LabelData.h"
#import "RevertSheetController.h"
#import "UpdateSheetController.h"
#import "DifferencesPaneController.h"
#import "ResultsWindowController.h"
#import "LogTableView.h"
#import "AddLabelSheetController.h"
#import "MoveLabelSheetController.h"
#import "JHAccordionView.h"

@implementation HistoryPaneController
@synthesize myDocument;
@synthesize logTableView;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (HistoryPaneController*) initHistoryPaneControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"HistoryPane" owner:self];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
}


- (void) awakeFromNib
{
	[self observe:kRepositoryDataDidChange	from:[self myDocument]  byCalling:@selector(refreshHistoryPane:)];
	[self observe:kRepositoryDataIsNew		from:[self myDocument]  byCalling:@selector(refreshHistoryPane:)];
	[self observe:kLogEntriesDidChange		from:[self myDocument]  byCalling:@selector(refreshHistoryPane:)];

	[self openSplitViewPaneToDefaultHeight: self];
	NSString* fileName = [myDocument documentNameForAutosave];
	[accordionView setAutosaveName:[NSString stringWithFormat:@"File:%@:HistoryPaneSplitPositions", fileName]];
	[logTableView setAutosaveTableColumns:YES];
	[logTableView setAutosaveName:[NSString stringWithFormat:@"File:%@:HistoryTableViewColumnPositions", fileName]];
	[logTableView resetTable:self];
	[theLabelsTableView_ setAutosaveTableColumns:YES];
	[theLabelsTableView_ setAutosaveName:[NSString stringWithFormat:@"File:%@:HistoryLabelsTableViewColumnPositions", fileName]];
	
	[logTableView setTarget:self];
	[logTableView setDoubleAction:@selector(handleLogTableViewDoubleClick:)];	
	
	[[myDocument mainWindow] makeFirstResponder:logTableView];
}

-(void) unload
{
	[self stopObserving];
	[logTableView unload];
	logTableView = nil;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Notifications & Updating
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) searchCaption		{ return [NSString stringWithFormat:@"%d entries shown", [logTableView numberOfTableRows]]; }

- (IBAction) refreshHistoryPane:(id)sender
{
	NSString* newSearchMessage = IsEmpty([[myDocument toolbarSearchField] stringValue]) ? @"Search" : [self searchCaption];
	[[myDocument toolbarSearchItem] setLabel:newSearchMessage];
	[logTableView refreshTable:self];
}

- (void) scrollToSelected
{
	[logTableView scrollToSelected:self];
}





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
	NSString* theSelectedRevision = [[logTableView chosenEntry] revision];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:theSelectedRevision];
}

- (IBAction) historyMenuRevertAllToChosenRevision:(id)sender
{
	NSArray* rootPathAsArray = [NSArray arrayWithObject:[myDocument absolutePathOfRepositoryRoot]];
	NSString* theSelectedRevision = [[logTableView chosenEntry] revision];
	[myDocument primaryActionRevertFiles:rootPathAsArray toVersion:theSelectedRevision];
}

- (IBAction) historyMenuUpdateRepositoryToChosenRevision:(id)sender
{
	NSString* theSelectedRevision = [[logTableView chosenEntry] revision];
	[myDocument primaryActionUpdateFilesToVersion:theSelectedRevision withCleanOption:NO];
}

- (IBAction) historyMenuMergeRevision:(id)sender
{
	NSString* theSelectedRevision = [[logTableView chosenEntry] revision];
	[myDocument primaryActionMergeWithVersion:theSelectedRevision andOptions:nil withConfirmation:YES];
}

- (IBAction) historyMenuManifestOfChosenRevision:(id)sender
{
	NSString* theSelectedRevision = [[logTableView chosenEntry] revision];
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

	[myDocument actionSwitchViewToDifferencesPane:sender];
	NSTimeInterval t = [[NSAnimationContext currentContext] duration];
	[[myDocument theDifferencesPaneController] performSelector:@selector(compareLowHighValue:) withObject:pairAsValue afterDelay:t];	
}


- (IBAction) mainMenuCollapseChangesets:(id)sender	{ [myDocument mainMenuCollapseChangesets:sender]; }
- (IBAction) mainMenuStripChangesets:(id)sender		{ [myDocument mainMenuStripChangesets:sender]; }
- (IBAction) mainMenuRebaseChangesets:(id)sender		{ [myDocument mainMenuRebaseChangesets:sender]; }
- (IBAction) mainMenuHistoryEditChangesets:(id)sender	{ [myDocument mainMenuHistoryEditChangesets:sender]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  LogTableView Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) handleLogTableViewDoubleClick:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	LowHighPair pair = [logTableView parentToHighestSelectedRevisions];
	NSString* revisionNumbers = [NSString stringWithFormat:@"%d%:%d", pair.lowRevision, pair.highRevision];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:revisionNumbers];
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
	
	NSString* rev    = [label revision];
	NSString* name   = [label name];
	
	
	
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	switch ([label labelType])
	{
		case eLocalTag:
		case eGlobalTag:
		{
			if (DisplayWarningForTagRemovalFromDefaults())
			{
				NSString* subMessage = [NSString stringWithFormat:@"Are you sure you want to remove the tag “%@” from revision “%@”?", name, rev];
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
				NSString* subMessage = [NSString stringWithFormat:@"Are you sure you want to remove the bookmark “%@” from revision “%@”?", name, rev];
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
			BOOL needToUpdateToNewRevision = (![[[myDocument repositoryData] getHGParent] isEqualToString:rev]);
			
			if (DisplayWarningForTagRemovalFromDefaults())
			{
				NSString* subMessage;
				if (needToUpdateToNewRevision)
					subMessage = [NSString stringWithFormat:@"Are you sure you want to remove the branch “%@” from revision “%@”? (To do this Mercurial needs to update your repository to revision “%@”.)", name, rev];
				else
					subMessage = [NSString stringWithFormat:@"Are you sure you want to remove the branch “%@” from revision “%@”?", name, rev];
				
				int result = RunCriticalAlertPanelWithSuppression(@"Removing Selected Label", subMessage, @"Remove", @"Cancel", MHGDisplayWarningForTagRemoval);
				if (result != NSAlertFirstButtonReturn)
					return;
			}
			if (![[[myDocument repositoryData] getHGParent] isEqualToString:rev])
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
	[[[myDocument theHistoryPaneController] logTableView] scrollToRevision:[label revision]];
	[myDocument primaryActionUpdateFilesToVersion:[label revision] withCleanOption:NO];
}





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

- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	SEL theAction = [anItem action];
	
	// HistoryPane contextual items
	if (theAction == @selector(historyMenuAddLabelToChosenRevision:))			return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuDiffAllToChosenRevision:))			return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuRevertAllToChosenRevision:))			return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuUpdateRepositoryToChosenRevision:))	return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuMergeRevision:))						return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && ![self chosenRevisionsContainsIncompleteRevision];
	if (theAction == @selector(historyMenuManifestOfChosenRevision:))			return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && ![self chosenRevisionsContainsIncompleteRevision];
	// -------
	if (theAction == @selector(historyMenuViewRevisionDifferences:))			return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && ![self chosenRevisionsContainsIncompleteRevision];

	// HistoryPane contextual items
	if (theAction == @selector(labelsMenuAddLabelToCurrentRevision:))			return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane];
	if (theAction == @selector(labelsMenuMoveChosenLabel:))						return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && [theLabelsTableView_ chosenLabel] && ![[theLabelsTableView_ chosenLabel] isOpenHead];
	if (theAction == @selector(labelsMenuRemoveChosenLabel:))					return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && [theLabelsTableView_ chosenLabel] && ![[theLabelsTableView_ chosenLabel] isOpenHead];
	// -------
	if (theAction == @selector(labelsMenuUpdateRepositoryToChosenRevision:))	return [myDocument repositoryIsSelectedAndReady] && [myDocument showingHistoryPane] && [theLabelsTableView_ chosenLabel];
	
	return [myDocument validateUserInterfaceItem:anItem];
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



@end