//
//  CommitSheetController.m
//  MacHg
//
//  Created by Jason Harris on 30/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "CommitSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"


@implementation CommitSheetController
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (CommitSheetController*) initCommitSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"CommitSheet" owner:self];
	return self;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Handle Table Clicks
// -----------------------------------------------------------------------------------------------------------------------------------------

// We should be able to do this just on the awake from nib but it doesn't seem to be working.
- (void) hookUpClickActions
{
	[changedFilesTableView setTarget:self];
	[changedFilesTableView setDoubleAction:@selector(handleChangedFilesTableDoubleClick:)];
	[changedFilesTableView setAction:@selector(handleChangedFilesTableClick:)];
	[previousCommitMessagesTableView setTarget:self];
	[previousCommitMessagesTableView setDoubleAction:@selector(handlePreviousCommitMessagesTableDoubleClick:)];
	[previousCommitMessagesTableView setAction:@selector(handlePreviousCommitMessagesTableClick:)];
}

- (IBAction) handleChangedFilesTableClick:(id)sender
{
	
}

- (IBAction) handleChangedFilesTableDoubleClick:(id)sender
{
	NSString* statusAndFile = [changedFilesTableSourceData objectAtIndex:[changedFilesTableView clickedRow]];
	NSArray* theRelativePathAsArray = [NSArray arrayWithObject:[statusAndFile substringFromIndex:2]];
	[myDocument viewDifferencesInCurrentRevisionFor:theRelativePathAsArray toRevision:nil];	// no revision means don't include the --rev option
	[theCommitSheet makeFirstResponder:commitMessageTextView];
}

- (IBAction) handlePreviousCommitMessagesTableClick:(id)sender
{
	
}

- (IBAction) handlePreviousCommitMessagesTableDoubleClick:(id)sender
{
	NSString* message = [logCommentsTableSourceData objectAtIndex:[previousCommitMessagesTableView clickedRow]];
	[commitMessageTextView insertText:message];
	[theCommitSheet makeFirstResponder:commitMessageTextView];
}

- (void) openCommitSheetWithPaths:(NSArray*)paths
{
	changedFilesTableSourceData = nil;
	logCommentsTableSourceData = nil;
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];

	// Report the branch we are about to commit on in the dialog
	NSMutableArray* argsBranch = [NSMutableArray arrayWithObjects:@"branch", nil];
	ExecutionResult hgBranchResults = [TaskExecutions executeMercurialWithArgs:argsBranch  fromRoot:rootPath  logging:eLoggingNone];
	NSString* newBranchSheetString = [NSString stringWithFormat:@"to branch: %@", hgBranchResults.outStr];
	[commitSheetBranchString setStringValue: newBranchSheetString];

	NSString* currentMessage = [commitMessageTextView string];
	[commitMessageTextView setSelectedRange:NSMakeRange(0, [currentMessage length])];
	[NSApp beginSheet:theCommitSheet modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[theCommitSheet makeFirstResponder:commitMessageTextView];

	absolutePathsOfFilesToCommit = [myDocument filterPaths:paths byBitfield:eHGStatusChangedInSomeWay];
	
	// Show the files which are about to be changed in the commit sheet.
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", @"--modified", @"--added", @"--removed", nil];
	[argsStatus addObjectsFromArray: absolutePathsOfFilesToCommit];
	ExecutionResult hgStatusResults = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	changedFilesTableSourceData = [hgStatusResults.outStr componentsSeparatedByString:@"\n"];
	[changedFilesTableView reloadData];
	
	// Fetch the last 10 log comments and set the sources so that the table view of these in the commit sheet shows them correctly.
	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--limit", @"10", @"--template", @"{desc}\n#^&^#\n", nil];
	ExecutionResult hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:rootPath  logging:eLoggingNone];
	logCommentsTableSourceData = [hgLogResults.outStr componentsSeparatedByString:@"\n#^&^#\n"];
	[previousCommitMessagesTableView reloadData];
}


- (IBAction) openCommitSheetWithAllFiles:(id)sender
{
	[self hookUpClickActions];
	
	committingAllFiles = YES;
	BOOL mergedState = [[myDocument repositoryData] inMergeState];
	NSString* newTitle = [NSString stringWithFormat:@"Committing %@ Files in %@", mergedState ? @"Merged" : @"All", [myDocument selectedRepositoryShortName]];
	[commitSheetTitle setStringValue:newTitle];
	[self openCommitSheetWithPaths:[myDocument absolutePathOfRepositoryRootAsArray]];
}

- (IBAction) openCommitSheetWithSelectedFiles:(id)sender
{
	if ([[myDocument repositoryData] inMergeState])
	{
		[self openCommitSheetWithAllFiles:sender];
		return;
	}
	
	[self hookUpClickActions];

	committingAllFiles = NO;
	NSString* newTitle = [NSString stringWithFormat:@"Committing Selected Files in %@", [myDocument selectedRepositoryShortName]];
	[commitSheetTitle setStringValue:newTitle];
	NSArray* paths = [myDocument absolutePathsOfBrowserChosenFiles];
	if ([paths count] <= 0)
		{ PlayBeep(); DebugLog(@"No files are selected to commit"); return; }

	[self openCommitSheetWithPaths:paths];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
	if (aTableView == changedFilesTableView)
		return [changedFilesTableSourceData count];
	if (aTableView == previousCommitMessagesTableView)
		return [logCommentsTableSourceData count];
	return 0;
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == changedFilesTableView)
		return [changedFilesTableSourceData objectAtIndex:rowIndex];
	if (aTableView == previousCommitMessagesTableView)
		return [logCommentsTableSourceData objectAtIndex:rowIndex];
	return @" ";
}



- (IBAction) commitSheetButtonOk:(id)sender
{
	// This is more a check here, error handling should have caught this before now if the files were empty.
	if (!absolutePathsOfFilesToCommit || [absolutePathsOfFilesToCommit count] <= 0)
	{
		PlayBeep();
		DebugLog(@"Nothing to commit");
		[NSApp endSheet:theCommitSheet];
		[theCommitSheet orderOut:sender];
		return;
	}

	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	[myDocument removeAllUndoActionsForDocument];
	[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{
		NSString* theMessage = [commitMessageTextView string];
		NSMutableArray* args = [NSMutableArray arrayWithObjects:@"commit", @"--message", theMessage, nil];
		NSArray* dirtifyPaths = committingAllFiles ? [myDocument absolutePathOfRepositoryRootAsArray] : absolutePathsOfFilesToCommit;
		if (committingAllFiles)
			[myDocument registerPendingRefresh:dirtifyPaths];
		else
		{
			// absolutePathsOfFilesToCommit is set when the sheet is opened.
			[myDocument registerPendingRefresh:dirtifyPaths];
			[args addObjectsFromArray:absolutePathsOfFilesToCommit];
		}
		[myDocument delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath];
			[myDocument addToChangedPathsDuringSuspension:dirtifyPaths];
		}];
	}];
	[NSApp endSheet:theCommitSheet];
	[theCommitSheet orderOut:sender];
}


- (IBAction) commitSheetButtonDiffAll:(id)sender
{
	[myDocument viewDifferencesInCurrentRevisionFor:absolutePathsOfFilesToCommit toRevision:nil]; // nil indicates the current revision
}


- (IBAction) commitSheetButtonCancel:(id)sender
{
	[NSApp endSheet:theCommitSheet];
	[theCommitSheet orderOut:sender];
}


@end
