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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface CommitSheetController (PrivateAPI)
- (IBAction)	validateButtons:(id)sender;
- (NSIndexSet*) chosenIndexesOfFilesToCommit;
@end

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
	NSArray* chosenFiles = [self chosenFilesToCommit];
	[myDocument viewDifferencesInCurrentRevisionFor:chosenFiles toRevision:nil];	// no revision means don't include the --rev option
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Sheet opening
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) openCommitSheetWithPaths:(NSArray*)paths
{
	changedFilesTableSourceData = nil;
	logCommentsTableSourceData = nil;
	excludedItems = nil;
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];

	// Report the branch we are about to commit on in the dialog
	NSMutableArray* argsBranch = [NSMutableArray arrayWithObjects:@"branch", nil];
	ExecutionResult* hgBranchResults = [TaskExecutions executeMercurialWithArgs:argsBranch  fromRoot:rootPath  logging:eLoggingNone];
	NSString* newBranchSheetString = fstr(@"to branch: %@", hgBranchResults.outStr);
	[commitSheetBranchString setStringValue: newBranchSheetString];

	NSString* currentMessage = [commitMessageTextView string];
	[commitMessageTextView setSelectedRange:NSMakeRange(0, [currentMessage length])];
	[NSApp beginSheet:theCommitSheet modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[theCommitSheet makeFirstResponder:commitMessageTextView];

	// Store the paths of the files to be committed
	absolutePathsOfFilesToCommit = [myDocument filterPaths:paths byBitfield:eHGStatusChangedInSomeWay];
	
	// Initialize the table source data and show the files which are about to be changed in the commit sheet.
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", @"--modified", @"--added", @"--removed", nil];
	[argsStatus addObjectsFromArray: absolutePathsOfFilesToCommit];
	ExecutionResult* hgStatusResults = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	changedFilesTableSourceData = [NSMutableArray arrayWithArray:[hgStatusResults.outStr componentsSeparatedByString:@"\n"]];
	if (IsEmpty([changedFilesTableSourceData lastObject]))
		[changedFilesTableSourceData removeLastObject];
	[changedFilesTableView reloadData];
	
	// Fetch the last 10 log comments and set the sources so that the table view of these in the commit sheet shows them correctly.
	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--limit", @"10", @"--template", @"{desc}\n#^&^#\n", nil];
	ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:rootPath  logging:eLoggingNone];
	logCommentsTableSourceData = [hgLogResults.outStr componentsSeparatedByString:@"\n#^&^#\n"];
	[previousCommitMessagesTableView reloadData];
	[self validateButtons:self];
}


- (IBAction) openCommitSheetWithAllFiles:(id)sender
{
	[self hookUpClickActions];
	
	committingAllFiles = YES;
	BOOL mergedState = [[myDocument repositoryData] inMergeState];
	NSString* newTitle = fstr(@"Committing %@ Files in %@", mergedState ? @"Merged" : @"All", [myDocument selectedRepositoryShortName]);
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
	NSString* newTitle = fstr(@"Committing Selected Files in %@", [myDocument selectedRepositoryShortName]);
	[commitSheetTitle setStringValue:newTitle];
	NSArray* paths = [myDocument absolutePathsOfBrowserChosenFiles];
	if ([paths count] <= 0)
		{ PlayBeep(); DebugLog(@"No files are selected to commit"); return; }

	[self openCommitSheetWithPaths:paths];
}



// -----------------------------------------------------------------------------------------------------------------------------------------
//  Validation   ---------------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------


- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	SEL theAction = [anItem action];	
	// CommitSheet contextual items
	NSIndexSet* selectedIndexes = [self chosenIndexesOfFilesToCommit];
	if (theAction == @selector(commitSheetDiffAction:))			return [self filesToCommitAreSelected];
	if (theAction == @selector(exculdePathsAction:))			return [selectedIndexes count] > 0 && ![excludedItems containsIndexes:selectedIndexes];
	if (theAction == @selector(includePathsAction:))			return [selectedIndexes count] > 0 && [excludedItems intersectsIndexes:selectedIndexes];
	return [myDocument validateUserInterfaceItem:anItem];
}


- (IBAction) validateButtons:(id)sender
{
	NSIndexSet* selectedIndexes = [changedFilesTableView selectedRowIndexes];
	BOOL pathsAreSelected = [selectedIndexes count] > 0;
	BOOL pathsCanBeExcluded = pathsAreSelected && ![excludedItems containsIndexes:selectedIndexes];
	BOOL pathsCanBeIncluded = pathsAreSelected && [excludedItems intersectsIndexes:selectedIndexes];
	NSString* diffButtonMessage = pathsAreSelected ? @"Diff Selected" : @"Diff All";
	BOOL okToCommit = ([changedFilesTableSourceData count] > 0) && ([excludedItems count] < [changedFilesTableSourceData count]);
	
	dispatch_async(mainQueue(), ^{
		[diffButton setTitle:diffButtonMessage];
		[excludePathsButton setEnabled:pathsCanBeExcluded];
		[includePathsButton setEnabled:pathsCanBeIncluded];
		[okButton setEnabled:okToCommit];
	});
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Table Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

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

- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
	if ([aNotification object] == changedFilesTableView)
		[self validateButtons:self];
}

- (void) tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == changedFilesTableView)
		if ([excludedItems containsIndex:rowIndex])
		{
			NSColor* grayColor = [NSColor grayColor];
			NSDictionary* newColorAttribute = [NSDictionary dictionaryWithObject:grayColor forKey:NSForegroundColorAttributeName];
			NSMutableAttributedString* str = [[NSMutableAttributedString alloc]init];
			[str initWithAttributedString:[aCell attributedStringValue]];
			[str addAttributes:newColorAttribute range:NSMakeRange(0, [str length])];
			[aCell setAttributedStringValue:str];			
		}
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  ChangedFiles TableView
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) filesToCommitAreSelected	{ return [changedFilesTableView numberOfSelectedRows] > 0; }

- (NSArray*) filesToCommit
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* toCommit = [[NSMutableArray alloc]init];
	for (NSString* file in changedFilesTableSourceData)
	{
		NSString* relativePath = [file substringFromIndex:2];
		NSString* absolutePath = [rootPath stringByAppendingPathComponent:relativePath];
		[toCommit addObject:absolutePath];
	};
	return toCommit;
}


- (NSArray*) selectedFilesToCommit
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* selectedCommitFiles = [[NSMutableArray alloc]init];
	NSIndexSet* rows = [changedFilesTableView selectedRowIndexes];
	[rows enumerateIndexesUsingBlock:^(NSUInteger row, BOOL* stop) {
		NSString* item = [changedFilesTableSourceData objectAtIndex:row];
		NSString* relativePath = [item substringFromIndex:2];
		NSString* absolutePath = [rootPath stringByAppendingPathComponent:relativePath];
		[selectedCommitFiles addObject:absolutePath];
	}];
	return selectedCommitFiles;
}


- (NSArray*) excludedPaths
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* exludedPaths = [[NSMutableArray alloc]init];
	[excludedItems enumerateIndexesUsingBlock:^(NSUInteger row, BOOL* stop) {
		NSString* item = [changedFilesTableSourceData objectAtIndex:row];
		NSString* relativePath = [item substringFromIndex:2];
		NSString* absolutePath = [rootPath stringByAppendingPathComponent:relativePath];
		[exludedPaths addObject:absolutePath];
	}];
	return exludedPaths;
}


- (NSString*) chosenFileToCommit
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSString* file = [changedFilesTableSourceData objectAtIndex:[changedFilesTableView chosenRow]];
	NSString* relativePath = [file substringFromIndex:2];
	NSString* absolutePath = [rootPath stringByAppendingPathComponent:relativePath];	
	return absolutePath;
}

- (NSArray*) chosenFilesToCommit
{
	if (![changedFilesTableView rowWasClicked] || [[changedFilesTableView selectedRowIndexes] containsIndex:[changedFilesTableView clickedRow]])
		return [self selectedFilesToCommit];
	return [NSArray arrayWithObject:[self chosenFileToCommit]];
}

- (NSIndexSet*) chosenIndexesOfFilesToCommit
{
	if (![changedFilesTableView rowWasClicked] || [[changedFilesTableView selectedRowIndexes] containsIndex:[changedFilesTableView clickedRow]])
		return [changedFilesTableView selectedRowIndexes];
	return [NSIndexSet indexSetWithIndex:[changedFilesTableView chosenRow]];
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) exculdePathsAction:(id)sender
{
	if (!excludedItems)
		excludedItems = [[NSMutableIndexSet alloc]init];
	[excludedItems addIndexes:[self chosenIndexesOfFilesToCommit]];
	[changedFilesTableView reloadData];
	[self validateButtons:self];
}


- (IBAction) includePathsAction:(id)sender
{
	if (!excludedItems)
		return;	
	[excludedItems removeIndexes:[self chosenIndexesOfFilesToCommit]];
	[changedFilesTableView reloadData];
	[self validateButtons:self];
}


- (IBAction) sheetButtonOk:(id)sender
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSArray* excludedPaths = [self excludedPaths];
	NSArray* paths = committingAllFiles ? [myDocument absolutePathOfRepositoryRootAsArray] : absolutePathsOfFilesToCommit; 		// absolutePathsOfFilesToCommit is set when the sheet is opened.
	NSMutableArray* filteredAbsolutePathsOfFilesToCommit = [NSMutableArray arrayWithArray:paths];
	[filteredAbsolutePathsOfFilesToCommit removeObjectsInArray:excludedPaths];
	
	// This is more a check here, error handling should have caught this before now if the files were empty.
	if (IsEmpty(changedFilesTableSourceData) || [excludedPaths count] >= [changedFilesTableSourceData count] || IsEmpty(filteredAbsolutePathsOfFilesToCommit))
	{
		PlayBeep();
		DebugLog(@"Nothing to commit");
		[NSApp endSheet:theCommitSheet];
		[theCommitSheet orderOut:sender];
		return;
	}

	[myDocument removeAllUndoActionsForDocument];
	[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{
		NSString* theMessage = [commitMessageTextView string];
		NSMutableArray* args = [NSMutableArray arrayWithObjects:@"commit", @"--message", theMessage, nil];

		[myDocument registerPendingRefresh:filteredAbsolutePathsOfFilesToCommit];
		if (IsNotEmpty(excludedPaths))
			for (NSString* exludedPath in excludedPaths)
				[args addObject:@"--exclude" followedBy:exludedPath];
		[args addObjectsFromArray:filteredAbsolutePathsOfFilesToCommit];

		[myDocument delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath];
			[myDocument addToChangedPathsDuringSuspension:filteredAbsolutePathsOfFilesToCommit];
		}];
	}];
	[NSApp endSheet:theCommitSheet];
	[theCommitSheet orderOut:sender];
}


- (IBAction) commitSheetDiffAction:(id)sender
{
	NSArray* pathsToDiff = [self filesToCommitAreSelected] ? [self chosenFilesToCommit] : [self filesToCommit];
	[myDocument viewDifferencesInCurrentRevisionFor:pathsToDiff toRevision:nil]; // nil indicates the current revision
}


- (IBAction) sheetButtonCancel:(id)sender
{
	[NSApp endSheet:theCommitSheet];
	[theCommitSheet orderOut:sender];
}


@end
