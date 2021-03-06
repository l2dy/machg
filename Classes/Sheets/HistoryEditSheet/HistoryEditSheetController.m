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
@synthesize myDocument = myDocument_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (HistoryEditSheetController*) initHistoryEditSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"HistoryEditSheet"];
	[self window];	// force / ensure the nib is loaded
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// ------------------------------------------------------------------------------------

- (NSIndexSet*) indexSetForStartingRevision:(NSNumber*)rev
{
	NSSet* descendants = [myDocument_.repositoryData descendantsOfRevisionNumber:rev];
	NSMutableIndexSet* newIndexes = [[NSMutableIndexSet alloc]init];
	for (NSNumber* revNum in descendants)
	{
		NSInteger row = [logTableView tableRowForRevision:revNum];
		if (row != NSNotFound)
			[newIndexes addIndex:row];
	}
	return newIndexes;
}

- (NSString*) reasonForInvalidityOfSelectedEntries
{
	NSArray* entries = logTableView.selectedEntries;
	
	if (entries.count < 1)
		return @"Unable to edit the history because no revisions are selected to edit. Select one or more consecutive revisions to edit.";
	
	return nil;
}

- (IBAction) validateButtons:(id)sender
{
	NSString* reasonForNonValid = self.reasonForInvalidityOfSelectedEntries;
	if (!reasonForNonValid)
		okButton.enabled = YES;
	else
	{
		okButton.enabled = NO;
		sheetInformativeMessageTextField.stringValue =  reasonForNonValid;
	}
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Handle Interrupted HistoryEdit
// ------------------------------------------------------------------------------------

- (void) doContinueOrAbort
{
	NSInteger result = RunCriticalAlertPanel(@"Edit in Progress", @"A history edit operation is in progress, continue with the operation or abort the operation", @"Continue", @"Abort", @"Cancel");

	// If we are canceling the operation we are done.
	if (result == NSAlertThirdButtonReturn)
		return;
	
	NSMutableArray* argsHistoryEdit = [NSMutableArray arrayWithObjects:@"histedit", @"--config", @"extensions.hgext.histedit=", nil];

	BOOL abort = (result == NSAlertSecondButtonReturn);
	[argsHistoryEdit addObject: (abort ? @"--abort" : @"--continue")];
	NSString* rootPath = myDocument_.absolutePathOfRepositoryRoot;
	
	ExecutionResult* results = [myDocument_  executeMercurialWithArgs:argsHistoryEdit  fromRoot:rootPath  whileDelayingEvents:YES];

	if (results.outStr)
	{
		NSString* operation = (abort ? @"Abort" : @"Continue");
		NSString* titleMessage = fstr(@"Results of History Edit %@",operation);
		NSString* message = fstr(@"Mercurial reported the result of the history edit %@:\n\ncode %d:\n%@", operation, results.result, results.outStr);
		RunAlertPanel(titleMessage, message, @"OK", nil, nil);
	}
	if (abort)
		[myDocument_.repositoryData deleteHistoryEditState];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Primary History Sheet
// ------------------------------------------------------------------------------------

- (IBAction) openHistoryEditSheetWithSelectedRevisions:(id)sender
{
	if (myDocument_.repositoryData.historyEditInProgress)
	{
		[self doContinueOrAbort];
		return;
	}
	
	if ([myDocument_ repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		RunAlertPanel(@"Outstanding Changes", @"History editing is only allowed in repositories with no outstanding uncommitted changes.", @"OK", nil, nil);
		return;
	}
	
	// Retarget a single click to select that entry and all descendants.
	[logTableView setAction:@selector(handleLogTableViewClick:)];
	logTableView.target = self;
	
	NSString* newTitle = fstr(@"Editing Selected Revisions in ???%@???", myDocument_.selectedRepositoryShortName);
	historyEditSheetTitle.stringValue = newTitle;
		
	[logTableView resetTable:self];
	
	NSArray* revs = [myDocument_.theHistoryView.logTableView chosenRevisions];
	if (revs.count <= 0)
		[logTableView scrollToRevision:myDocument_.getHGTipRevision];
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
	if (okButton.isEnabled)
		sheetInformativeMessageTextField.attributedStringValue =  self.formattedSheetMessage;
	self.window = theHistoryEditSheet;
	[myDocument_ beginSheet:theHistoryEditSheet];
	
}


- (IBAction) sheetButtonOkForHistoryEditSheet:(id)sender
{
	[myDocument_ endSheet:theHistoryEditSheet];
	[self openHistoryEditConfirmationSheet:self];
}

- (IBAction) sheetButtonCancelForHistoryEditSheet:(id)sender
{
	[myDocument_ endSheet:theHistoryEditSheet];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Confirmation Sheet
// ------------------------------------------------------------------------------------

- (IBAction) openHistoryEditConfirmationSheet:(id)sender
{
	NSString* rootPath = myDocument_.absolutePathOfRepositoryRoot;
	LowHighPair pair = logTableView.lowestToHighestSelectedRevisions;
	NSMutableArray* argsHistoryEdit = [NSMutableArray arrayWithObjects:@"histedit", @"--config", @"extensions.hgext.histedit=", nil];
	
	[argsHistoryEdit addObject:@"--startingrules"];
	[argsHistoryEdit addObject:intAsString(pair.lowRevision)];
		
	ExecutionResult* results = [myDocument_  executeMercurialWithArgs:argsHistoryEdit  fromRoot:rootPath  whileDelayingEvents:YES];
	if (results.result != 0)
		return;
	[confirmationSheetMessage.textStorage setAttributedString:normalSheetMessageAttributedString(results.outStr)];
	[theHistoryEditConfirmationSheet makeFirstResponder:confirmationSheetMessage];
	
	sheetConfirmationInformativeMessageTextField.attributedStringValue = sheetInformativeMessageTextField.attributedStringValue;
	self.window = theHistoryEditConfirmationSheet;
	[myDocument_ beginSheet:theHistoryEditConfirmationSheet];
}

- (IBAction) sheetButtonOkForHistoryEditConfirmationSheet:(id)sender
{
	[theHistoryEditConfirmationSheet makeFirstResponder:theHistoryEditConfirmationSheet];	// Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:theHistoryEditConfirmationSheet];

	NSString* rootPath = myDocument_.absolutePathOfRepositoryRoot;
	LowHighPair pair = logTableView.lowestToHighestSelectedRevisions;
	NSString* repositoryName = [myDocument_.sidebar.selectedNode shortName];
	NSString* historyEditDescription = fstr(@"Editing descendants of %ld in ???%@???", pair.lowRevision, repositoryName);
	NSMutableArray* argsHistoryEdit = [NSMutableArray arrayWithObjects:@"histedit", @"--config", @"extensions.hgext.histedit=", nil];
	
	[argsHistoryEdit addObject:@"--rules" followedBy:confirmationSheetMessage.string];
	[argsHistoryEdit addObject:intAsString(pair.lowRevision)];

	[myDocument_ dispatchToMercurialQueuedWithDescription:historyEditDescription  process:^{
		[myDocument_ executeMercurialWithArgs:argsHistoryEdit  fromRoot:rootPath  whileDelayingEvents:YES];
	}];	
}
- (IBAction) sheetButtonCancelForHistoryEditConfirmationSheet:(id)sender
{
	[myDocument_ endSheet:theHistoryEditConfirmationSheet];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// ------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[self validateButtons:self];
	if (okButton.isEnabled)
		sheetInformativeMessageTextField.attributedStringValue =  self.formattedSheetMessage;
}

- (NSIndexSet*) tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes
{
	return proposedSelectionIndexes;
	if (!logTableView.rowWasClicked)
		return [self indexSetForStartingRevision:stringAsNumber([logTableView revisionForTableRow:proposedSelectionIndexes.firstIndex])];
	return [self indexSetForStartingRevision:logTableView.chosenRevision];
}

- (IBAction) handleLogTableViewClick:(id)sender
{
	NSIndexSet* newIndexes = [self indexSetForStartingRevision:logTableView.chosenRevision];
	[logTableView selectRowIndexes:newIndexes byExtendingSelection:NO];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// ------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	LowHighPair pair = logTableView.lowestToHighestSelectedRevisions;
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The revisions from ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.lowRevision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" through to ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.highRevision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be edited. This historyEdit operation is destructive; it rewrites history. Therefore you should never historyEdit any revisions that have already been pushed to other repositories, unless you really know what you are doing.")];
	return newSheetMessage;
}


@end
