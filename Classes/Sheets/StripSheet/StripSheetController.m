//
//  StripSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "StripSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"
#import "HistoryViewController.h"
#import "Sidebar.h"
#import "SidebarNode.h"


@interface StripSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation StripSheetController
@synthesize myDocument;





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

- (NSIndexSet*) indexSetForStartingRevision:(NSNumber*)rev
{
	NSSet* descendants = [[myDocument repositoryData] descendantsOfRevisionNumber:rev];
	NSMutableIndexSet* newIndexes = [[NSMutableIndexSet alloc]init];
	for (NSNumber* revNum in descendants)
		[newIndexes addIndex:[logTableView tableRowForRevision:revNum]];
	return newIndexes;
}

- (NSString*) reasonForInvalidityOfSelectedEntries
{
	NSArray* entries = [logTableView selectedEntries];

	if ([entries count] < 1)
		return @"Unable to perform strip because no revisions are selected to strip. Select two or more consecutive revisions to strip.";

	return nil;
}

- (IBAction) validateButtons:(id)sender
{
	NSString* reasonForNonValid = [self reasonForInvalidityOfSelectedEntries];
	if (!reasonForNonValid)
		[okButton setEnabled:YES];
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
	if ([myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		NSRunAlertPanel(@"Outstanding Changes", @"Stripping is only allowed in repositories with no outstanding uncommitted changes.", @"OK", nil, nil);
		return;
	}	
		
	// Retarget a single click to select that entry and all descendants.
	[logTableView setAction:@selector(handleLogTableViewClick:)];
	[logTableView setTarget:self];
	
	NSString* newTitle = fstr(@"Stripping Selected Revisions in “%@”", [myDocument selectedRepositoryShortName]);
	[stripSheetTitle setStringValue:newTitle];

	[logTableView resetTable:self];
	
	NSArray* revs = [[[myDocument theHistoryView] logTableView] chosenRevisions];
	if ([revs count] <= 0)
		[logTableView scrollToRevision:[myDocument getHGTipRevision]];
	else
	{
		NSInteger minRev = numberAsInt([revs objectAtIndex:0]);
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

	[NSApp beginSheet:theStripSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[NSApp endSheet:theStripSheet];
	[theStripSheet orderOut:sender];

	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSString* repositoryName = [[[myDocument sidebar] selectedNode] shortName];
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];
	NSString* stripDescription = fstr(@"Stripping %d in “%@”", pair.lowRevision, repositoryName);
	NSMutableArray* argsStrip = [NSMutableArray arrayWithObjects:@"strip",  @"--config", @"extensions.mq=", nil];	// We are using MacHgs strip so command we need to specify that it is
																													// in the extensions folder of the included Mercurial
	[argsStrip addObject:@"--backup"];
	NSString* revisionNumber = fstr(@"%d", pair.lowRevision);
	[argsStrip addObject:revisionNumber];

	[myDocument dispatchToMercurialQueuedWithDescription:stripDescription  process:^{
		[myDocument delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:argsStrip  fromRoot:rootPath];
		}];			
	}];	
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[NSApp endSheet:theStripSheet];
	[theStripSheet orderOut:sender];
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
	if (![logTableView rowWasClicked])
		return [self indexSetForStartingRevision:stringAsNumber([logTableView revisionForTableRow:[proposedSelectionIndexes firstIndex]])];
	return [self indexSetForStartingRevision:[logTableView chosenRevision]];
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
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The selected revisions within ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.lowRevision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" through to ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.highRevision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be removed from the repository. This strip operation is destructive; it rewrites history. Therefore you should never strip any revisions that have already been pushed to other repositories, unless you really know what you are doing.")];
	return newSheetMessage;
}


@end
