//
//  HistoryEditSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "HistoryEditSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"
#import "HistoryViewController.h"
#import "Sidebar.h"
#import "SidebarNode.h"



@interface HistoryEditSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation HistoryEditSheetController
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (HistoryEditSheetController*) initHistoryEditSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"HistoryEditSheet" owner:self];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[inspectorSplitView setPosition:350 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theHistoryEditSheet makeFirstResponder:logTableView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSIndexSet*) indexSetForStartingRevision:(NSString*)rev
{
	NSSet* descendants = [[myDocument repositoryData] descendantsOfRev:stringAsNumber(rev)];
	NSMutableIndexSet* newIndexes = [[NSMutableIndexSet alloc]init];
	for (NSNumber* revNum in descendants)
		[newIndexes addIndex:[logTableView tableRowForRevision:numberAsString(revNum)]];
	return newIndexes;
}

- (NSString*) reasonForInvalidityOfSelectedEntries
{
	NSArray* entries = [logTableView selectedEntries];
	
	if ([entries count] < 1)
		return @"Unable to edit the history because no revisions are selected to edit. Select one or more consecutive revisions to edit.";
	
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
// MARK:  Handle Interrupted HistoryEdit
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) historyEditInProgress
{
	NSString* repositoryDotHGDirPath = [[myDocument absolutePathOfRepositoryRoot] stringByAppendingPathComponent:@".hg"];
	NSString* histEditStatePath = [repositoryDotHGDirPath stringByAppendingPathComponent:@"histedit-state"];
	return [[NSFileManager defaultManager] fileExistsAtPath:histEditStatePath];
}

- (void) doContinueOrAbort
{
	NSInteger result = NSRunCriticalAlertPanel(@"Edit in Progress", @"A history edit operation is in progress, continue with the operation or abort the operation", @"Continue", @"Abort", @"Cancel");

	// If we are canceling the operation we are done.
	if (result == NSAlertOtherReturn)
		return;
	
	NSMutableArray* argsHistoryEdit = [NSMutableArray arrayWithObjects:@"histedit", nil];
	
	// If we are using MacHgs historyEdit command we need to specify that it is in the extensions folder of the included Mercurial
	if (UseWhichMercurialBinaryFromDefaults() == eUseMercurialBinaryIncludedInMacHg)
	{
		NSString* absPathToHistEdit = fstr(@"hgext.histedit=%@/%@",[[NSBundle mainBundle] builtInPlugInsPath], @"LocalMercurial/hgext/histedit");
		[argsHistoryEdit addObject:@"--config" followedBy:absPathToHistEdit];
	}
	[argsHistoryEdit addObject: (result == NSAlertDefaultReturn ? @"--continue" : @"--abort")];
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	
	ExecutionResult* results = [myDocument  executeMercurialWithArgs:argsHistoryEdit  fromRoot:rootPath  whileDelayingEvents:YES];

	if (results.outStr)
	{
		NSString* operation = (result == NSAlertDefaultReturn ? @"Continue" : @"Abort");
		NSString* titleMessage = fstr(@"Results of History Edit %@",operation);
		NSRunAlertPanel(titleMessage, @"Mercurial reported the result of the history edit %@:\n\ncode %d:\n%@", @"OK", nil, nil, operation, results.result, results.outStr);
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Primary History Sheet
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openHistoryEditSheetWithSelectedRevisions:(id)sender
{
	if ([self historyEditInProgress])
	{
		[self doContinueOrAbort];
		return;
	}
	
	if ([myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		NSRunAlertPanel(@"Outstanding Changes", @"History editing is only allowed in repositories with no outstanding uncommitted changes.", @"OK", nil, nil);
		return;
	}
	
	// Retarget a single click to select that entry and all descendants.
	[logTableView setAction:@selector(handleLogTableViewClick:)];
	[logTableView setTarget:self];
	
	NSString* newTitle = fstr(@"Editing Selected Revisions in “%@”", [myDocument selectedRepositoryShortName]);
	[historyEditSheetTitle setStringValue:newTitle];
		
	[logTableView resetTable:self];
	
	NSArray* revs = [[[myDocument theHistoryView] logTableView] chosenRevisions];
	if ([revs count] <= 0)
		[logTableView scrollToRevision:[myDocument getHGTipRevision]];		
	{
		NSInteger minRev = stringAsInt([revs objectAtIndex:0]);
		for (NSString* stringRev in revs)
		{
			NSInteger revInt = stringAsInt(stringRev);
			minRev = MIN(revInt, minRev);
		}
		NSIndexSet* newIndexes = [self indexSetForStartingRevision:intAsString(minRev)];
		[logTableView selectAndScrollToIndexSet:newIndexes];
	}
	
	[self validateButtons:self];
	if ([okButton isEnabled])
		[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
	[self setWindow:theHistoryEditSheet];
	[NSApp beginSheet:theHistoryEditSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	
}


- (IBAction) sheetButtonOkForHistoryEditSheet:(id)sender;
{
	[NSApp endSheet:theHistoryEditSheet];
	[theHistoryEditSheet orderOut:sender];
	[self openHistoryEditConfirmationSheet:self];
}

- (IBAction) sheetButtonCancelForHistoryEditSheet:(id)sender;
{
	[NSApp endSheet:theHistoryEditSheet];
	[theHistoryEditSheet orderOut:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Confirmation Sheet
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openHistoryEditConfirmationSheet:(id)sender
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];
	NSMutableArray* argsHistoryEdit = [NSMutableArray arrayWithObjects:@"histedit", nil];
	
	// If we are using MacHgs historyEdit command we need to specify that it is in the extensions folder of the included Mercurial
	if (UseWhichMercurialBinaryFromDefaults() == eUseMercurialBinaryIncludedInMacHg)
	{
		NSString* absPathToHistEdit = fstr(@"hgext.histedit=%@/%@",[[NSBundle mainBundle] builtInPlugInsPath], @"LocalMercurial/hgext/histedit");
		[argsHistoryEdit addObject:@"--config" followedBy:absPathToHistEdit];
	}
	[argsHistoryEdit addObject:@"--startingrules"];
	[argsHistoryEdit addObject:intAsString(pair.lowRevision)];
		
	ExecutionResult* results = [myDocument  executeMercurialWithArgs:argsHistoryEdit  fromRoot:rootPath  whileDelayingEvents:YES];
	if (results.result != 0)
		return;
	[[confirmationSheetMessage textStorage] setAttributedString:normalSheetMessageAttributedString(results.outStr)];
	[theHistoryEditConfirmationSheet makeFirstResponder:confirmationSheetMessage];
	
	[sheetConfirmationInformativeMessageTextField setAttributedStringValue:[sheetInformativeMessageTextField attributedStringValue]];
	[self setWindow:theHistoryEditConfirmationSheet];
	[NSApp beginSheet:theHistoryEditConfirmationSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];	
}

- (IBAction) sheetButtonOkForHistoryEditConfirmationSheet:(id)sender
{
	[theHistoryEditConfirmationSheet makeFirstResponder:theHistoryEditConfirmationSheet];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theHistoryEditConfirmationSheet];
	[theHistoryEditConfirmationSheet orderOut:sender];

	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];
	NSString* repositoryName = [[[myDocument sidebar] selectedNode] shortName];
	NSString* historyEditDescription = fstr(@"Editing descendants of %d in “%@”", pair.lowRevision, repositoryName);
	NSMutableArray* argsHistoryEdit = [NSMutableArray arrayWithObjects:@"histedit", nil];
	
	// If we are using MacHgs historyEdit command we need to specify that it is in the extensions folder of the included Mercurial
	if (UseWhichMercurialBinaryFromDefaults() == eUseMercurialBinaryIncludedInMacHg)
	{
		NSString* absPathToHistEdit = fstr(@"hgext.histedit=%@/%@",[[NSBundle mainBundle] builtInPlugInsPath], @"LocalMercurial/hgext/histedit");
		[argsHistoryEdit addObject:@"--config" followedBy:absPathToHistEdit];
	}
	[argsHistoryEdit addObject:@"--rules" followedBy:[confirmationSheetMessage string]];
	[argsHistoryEdit addObject:intAsString(pair.lowRevision)];

	[myDocument dispatchToMercurialQueuedWithDescription:historyEditDescription  process:^{
		[myDocument  executeMercurialWithArgs:argsHistoryEdit  fromRoot:rootPath  whileDelayingEvents:YES];
	}];
}
- (IBAction) sheetButtonCancelForHistoryEditConfirmationSheet:(id)sender
{
	[NSApp endSheet:theHistoryEditConfirmationSheet];
	[theHistoryEditConfirmationSheet orderOut:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable;
{
	[self validateButtons:self];
	if ([okButton isEnabled])
		[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
}

- (NSIndexSet*) tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes
{
	return proposedSelectionIndexes;
	if (![logTableView rowWasClicked])
		return [self indexSetForStartingRevision:[logTableView revisionForTableRow:[proposedSelectionIndexes firstIndex]]];
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
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The revisions from ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.lowRevision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" through to ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.highRevision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be edited. This historyEdit operation is destructive; it rewrites history. Therefore you should never historyEdit any revisions that have already been pushed to other repositories, unless you really know what you are doing.")];
	return newSheetMessage;
}


@end
