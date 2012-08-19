//
//  StripSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "HistoryViewController.h"
#import "LogEntry.h"
#import "LogTableView.h"
#import "MacHgDocument.h"
#import "ProcessListController.h"
#import "RepositoryData.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "StripSheetController.h"
#import "TaskExecutions.h"





@interface StripSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation StripSheetController
@synthesize myDocument;
@synthesize forceOption = forceOption_;
@synthesize backupOption = backupOption_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (StripSheetController*) initStripSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"StripSheet" owner:self];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[inspectorSplitView setPosition:350 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theStripSheet makeFirstResponder:logTableView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) incompleteRevisionWillBeStripped
{
	NSUInteger incompleteRow = [logTableView tableRowForRevision:[[myDocument repositoryData] incompleteRevision]];
	return (incompleteRow != NSNotFound && [logTableView isRowSelected:incompleteRow]);
}

- (NSIndexSet*) indexSetForStartingRevision:(NSNumber*)rev
{
	LogEntry* incompleteRevisionEntry = [[myDocument repositoryData] incompleteRevisionEntry];
	if (theSameNumbers(rev,[incompleteRevisionEntry revision]))
		return [NSIndexSet indexSet];
	
	NSSet* descendants = [[myDocument repositoryData] descendantsOfRevisionNumber:rev];
	NSMutableIndexSet* newIndexes = [[NSMutableIndexSet alloc]init];
	for (NSNumber* revNum in descendants)
		[newIndexes addIndex:[logTableView tableRowForRevision:revNum]];
	
	// Add the incompleteRevision if applicable
	if (incompleteRevisionEntry && [descendants containsObject:[incompleteRevisionEntry firstParent]])
		[newIndexes addIndex:[logTableView tableRowForRevision:[incompleteRevisionEntry revision]]];

	return newIndexes;
}

- (NSString*) reasonForInvalidityOfSelectedEntries
{
	NSArray* entries = [logTableView selectedEntries];

	if ([entries count] < 1)
		return @"Unable to perform the strip because no revisions are selected to strip. Select one or more consecutive revisions to strip.";

	if (![self forceOption] && [self incompleteRevisionWillBeStripped])
		return @"Unable to perform the strip because there are uncommitted changes. Enable the checkbox 'Force' option to ignore the uncommitted changes.";

	return nil;
}

- (IBAction) validateButtons:(id)sender
{
	NSString* reasonForNonValid = [self reasonForInvalidityOfSelectedEntries];
	if (!reasonForNonValid)
	{
		[okButton setEnabled:YES];
		[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
	}
	else
	{
		[okButton setEnabled:NO];
		[sheetInformativeMessageTextField setStringValue: reasonForNonValid];
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openStripSheetWithSelectedRevisions:(id)sender
{
	// Retarget a single click to select that entry and all descendants.
	[logTableView setAction:@selector(handleLogTableViewClick:)];
	[logTableView setTarget:self];
	
	NSString* newTitle = fstr(@"Stripping Selected Revisions in “%@”", [myDocument selectedRepositoryShortName]);
	[stripSheetTitle setStringValue:newTitle];
	[self setForceOption:NO];
	[self setBackupOption:YES];

	[logTableView resetTable:self];
	[logTableView setCanSelectIncompleteRevision:YES];
	
	if ([myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		NSInteger result = NSRunAlertPanel(@"Outstanding Changes", @"There are outstanding uncommitted changes. Are you sure you want to continue?", @"Cancel", @"Ok", nil);
		if (result == NSAlertDefaultReturn)
			return;
	}
	
	NSArray* revs = [[[myDocument theHistoryView] logTableView] chosenRevisions];
	if ([revs count] <= 0)
		[logTableView scrollToRevision:[myDocument getHGTipRevision]];
	else
	{
		NSInteger minRev = numberAsInt(revs[0]);
		for (NSNumber* revision in revs)
		{
			NSInteger revInt = numberAsInt(revision);
			minRev = MIN(revInt, minRev);
		}
		NSIndexSet* newIndexes = [self indexSetForStartingRevision:intAsNumber(minRev)];
		[logTableView selectAndScrollToIndexSet:newIndexes];
	}
	
	[self validateButtons:self];
	if ([okButton isEnabled])
		[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];

	[myDocument beginSheet:theStripSheet];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[myDocument endSheet:theStripSheet];

	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSString* repositoryName = [[[myDocument sidebar] selectedNode] shortName];
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];
	NSString* stripDescription = fstr(@"Stripping %d in “%@”", pair.lowRevision, repositoryName);
	NSMutableArray* argsStrip = [NSMutableArray arrayWithObjects:@"strip",  @"--config", @"extensions.hgext.mq=", nil];	// We are using MacHgs strip so command we need to specify that it is
																													// in the extensions folder of the included Mercurial
    [argsStrip addObjectsFromArray:configurationForProgress];
	if ([self forceOption])
		[argsStrip addObject:@"--force"];		
	if (![self backupOption])
		[argsStrip addObject:@"--no-backup"];		
	NSString* revisionNumber = fstr(@"%d", pair.lowRevision);
	[argsStrip addObject:revisionNumber];

	ProcessController* processController = [ProcessController processControllerWithMessage:stripDescription forList:[myDocument theProcessListController]];
	dispatch_async([myDocument mercurialTaskSerialQueue], ^{
		[myDocument executeMercurialWithArgs:argsStrip  fromRoot:rootPath  withDelegate:processController  whileDelayingEvents:YES];
		[processController terminateController];
	});		
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[myDocument endSheet:theStripSheet];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[self validateButtons:self];
	if ([okButton isEnabled])
		[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
}

- (NSIndexSet*) tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes
{
	return proposedSelectionIndexes;
}

- (IBAction) handleLogTableViewClick:(id)sender
{
	NSIndexSet* newIndexes = [self indexSetForStartingRevision:[logTableView chosenRevision]];
	[logTableView selectRowIndexes:newIndexes byExtendingSelection:NO];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];

	BOOL willEraseUncommitted = [self incompleteRevisionWillBeStripped];
	BOOL singleRevision = pair.lowRevision == pair.highRevision;
	if (singleRevision)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The selected revision ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.lowRevision))];
	}
	else
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The selected revisions within ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.lowRevision))];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" through to ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.highRevision))];
	}
	if (willEraseUncommitted)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" (and the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"uncommitted changes")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(fstr(@" deriving from %@)", singleRevision ? @"this revision": @"these revisions"))];
	}
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be removed from the repository. This strip operation is destructive; it rewrites history. Therefore you should never strip any revisions that have already been pushed to other repositories, unless you really know what you are doing.")];
	return newSheetMessage;
}


@end
