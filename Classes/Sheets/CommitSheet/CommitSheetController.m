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
#import "DisclosureBoxController.h"




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
@synthesize	committerOption = committerOption_;
@synthesize	committer = committer_;
@synthesize	dateOption = dateOption_;
@synthesize	date = date_;





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
	[filesToCommitTableView setTarget:self];
	[filesToCommitTableView setDoubleAction:@selector(handleFilesToCommitTableDoubleClick:)];
	[filesToCommitTableView setAction:@selector(handleFilesToCommitTableClick:)];
	[previousCommitMessagesTableView setTarget:self];
	[previousCommitMessagesTableView setDoubleAction:@selector(handlePreviousCommitMessagesTableDoubleClick:)];
	[previousCommitMessagesTableView setAction:@selector(handlePreviousCommitMessagesTableClick:)];
}

- (IBAction) handleFilesToCommitTableClick:(id)sender
{
	
}

- (IBAction) handleFilesToCommitTableDoubleClick:(id)sender
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
	filesToCommitTableSourceData = nil;
	logCommentsTableSourceData = nil;
	excludedItems = nil;
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];

	// Report the branch we are about to commit on in the dialog
	NSMutableArray* argsBranch = [NSMutableArray arrayWithObjects:@"branch", nil];
	ExecutionResult* hgBranchResults = [TaskExecutions executeMercurialWithArgs:argsBranch  fromRoot:rootPath  logging:eLoggingNone];
	NSString* newBranchSheetString = fstr(@"to branch: %@", hgBranchResults.outStr);
	[commitSheetBranchString setStringValue: newBranchSheetString];

	NSMutableArray* argsGetUserName = [NSMutableArray arrayWithObjects:@"showconfig", @"ui.username", nil];
	ExecutionResult* userNameResult = [TaskExecutions executeMercurialWithArgs:argsGetUserName  fromRoot:rootPath];
	BOOL amendIsPotentiallyPossible = AllowHistoryEditingOfRepositoryFromDefaults() && ![myDocument inMergeState] && [myDocument isCurrentRevisionTip];

	[disclosureController setToOpenState:NO];
	[self setCommitter:nonNil(userNameResult.outStr)];
	[self setCommitterOption:NO];
	[self setDate:[NSDate date]];
	[self setDateOption:NO];
	[amendButton setState:NO];
	[amendButton setEnabled:amendIsPotentiallyPossible];
	
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
	filesToCommitTableSourceData = [NSMutableArray arrayWithArray:[hgStatusResults.outStr componentsSeparatedByString:@"\n"]];
	if (IsEmpty([filesToCommitTableSourceData lastObject]))
		[filesToCommitTableSourceData removeLastObject];
	[filesToCommitTableView reloadData];
	
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
// MARK: -
// MARK:  Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	SEL theAction = [anItem action];	
	// CommitSheet contextual items
	NSIndexSet* selectedIndexes = [self chosenIndexesOfFilesToCommit];
	if (theAction == @selector(commitSheetDiffAction:))			return [self filesToCommitAreSelected];
	if (theAction == @selector(excludePathsAction:))			return [selectedIndexes count] > 0 && ![excludedItems containsIndexes:selectedIndexes];
	if (theAction == @selector(includePathsAction:))			return [selectedIndexes count] > 0 && [excludedItems intersectsIndexes:selectedIndexes];
	return [myDocument validateUserInterfaceItem:anItem];
}


- (IBAction) validateButtons:(id)sender
{
	NSIndexSet* selectedIndexes = [filesToCommitTableView selectedRowIndexes];
	BOOL pathsAreSelected = [selectedIndexes count] > 0;
	BOOL pathsCanBeExcluded = pathsAreSelected && ![excludedItems containsIndexes:selectedIndexes];
	BOOL pathsCanBeIncluded = pathsAreSelected && [excludedItems intersectsIndexes:selectedIndexes];
	NSString* diffButtonMessage = pathsAreSelected ? @"Diff Selected" : @"Diff All";
	BOOL okToCommit = ([filesToCommitTableSourceData count] > 0) && ([excludedItems count] < [filesToCommitTableSourceData count]);
	
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
	if (aTableView == filesToCommitTableView)
		return [filesToCommitTableSourceData count];
	if (aTableView == previousCommitMessagesTableView)
		return [logCommentsTableSourceData count];
	return 0;
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == filesToCommitTableView)
		return [filesToCommitTableSourceData objectAtIndex:rowIndex];
	if (aTableView == previousCommitMessagesTableView)
		return [logCommentsTableSourceData objectAtIndex:rowIndex];
	return @" ";
}

- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
	if ([aNotification object] == filesToCommitTableView)
		[self validateButtons:self];
}

- (void) tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == filesToCommitTableView)
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

- (BOOL) filesToCommitAreSelected	{ return [filesToCommitTableView numberOfSelectedRows] > 0; }

- (NSArray*) filesToCommit
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* toCommit = [[NSMutableArray alloc]init];
	for (NSString* file in filesToCommitTableSourceData)
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
	NSIndexSet* rows = [filesToCommitTableView selectedRowIndexes];
	[rows enumerateIndexesUsingBlock:^(NSUInteger row, BOOL* stop) {
		NSString* item = [filesToCommitTableSourceData objectAtIndex:row];
		NSString* relativePath = [item substringFromIndex:2];
		NSString* absolutePath = [rootPath stringByAppendingPathComponent:relativePath];
		[selectedCommitFiles addObject:absolutePath];
	}];
	return selectedCommitFiles;
}


- (NSArray*) excludedPaths
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* excludedPaths = [[NSMutableArray alloc]init];
	[excludedItems enumerateIndexesUsingBlock:^(NSUInteger row, BOOL* stop) {
		NSString* item = [filesToCommitTableSourceData objectAtIndex:row];
		NSString* relativePath = [item substringFromIndex:2];
		NSString* absolutePath = [rootPath stringByAppendingPathComponent:relativePath];
		[excludedPaths addObject:absolutePath];
	}];
	return excludedPaths;
}


- (NSString*) chosenFileToCommit
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSString* file = [filesToCommitTableSourceData objectAtIndex:[filesToCommitTableView chosenRow]];
	NSString* relativePath = [file substringFromIndex:2];
	NSString* absolutePath = [rootPath stringByAppendingPathComponent:relativePath];	
	return absolutePath;
}

- (NSArray*) chosenFilesToCommit
{
	if (![filesToCommitTableView rowWasClicked] || [[filesToCommitTableView selectedRowIndexes] containsIndex:[filesToCommitTableView clickedRow]])
		return [self selectedFilesToCommit];
	return [NSArray arrayWithObject:[self chosenFileToCommit]];
}

- (NSIndexSet*) chosenIndexesOfFilesToCommit
{
	if (![filesToCommitTableView rowWasClicked] || [[filesToCommitTableView selectedRowIndexes] containsIndex:[filesToCommitTableView clickedRow]])
		return [filesToCommitTableView selectedRowIndexes];
	return [NSIndexSet indexSetWithIndex:[filesToCommitTableView chosenRow]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) excludePathsAction:(id)sender
{
	if (!excludedItems)
		excludedItems = [[NSMutableIndexSet alloc]init];
	[excludedItems addIndexes:[self chosenIndexesOfFilesToCommit]];
	[filesToCommitTableView reloadData];
	[self validateButtons:self];
}


- (IBAction) includePathsAction:(id)sender
{
	if (!excludedItems)
		return;	
	[excludedItems removeIndexes:[self chosenIndexesOfFilesToCommit]];
	[filesToCommitTableView reloadData];
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
	if (IsEmpty(filesToCommitTableSourceData) || [excludedPaths count] >= [filesToCommitTableSourceData count] || IsEmpty(filteredAbsolutePathsOfFilesToCommit))
	{
		PlayBeep();
		DebugLog(@"Nothing to commit");
		[NSApp endSheet:theCommitSheet];
		[theCommitSheet orderOut:sender];
		return;
	}

	
	[myDocument removeAllUndoActionsForDocument];
	
	if ([amendButton state] == NSOffState)
	{
		[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{
			NSString* theMessage = [commitMessageTextView string];
			NSMutableArray* args = [NSMutableArray arrayWithObjects:@"commit", @"--message", theMessage, nil];
			
			[myDocument registerPendingRefresh:filteredAbsolutePathsOfFilesToCommit];
			if (IsNotEmpty(excludedPaths))
				for (NSString* excludedPath in excludedPaths)
					[args addObject:@"--exclude" followedBy:excludedPath];
			if ([self committerOption] && IsNotEmpty([self committer]))
				[args addObject:@"--user" followedBy:[self committer]];
			if ([self dateOption] && IsNotEmpty([self date]))
				[args addObject:@"--date" followedBy:[[self date] isodateDescription]];
			[args addObjectsFromArray:filteredAbsolutePathsOfFilesToCommit];
			
			[myDocument delayEventsUntilFinishBlock:^{
				[TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath];
				[myDocument addToChangedPathsDuringSuspension:filteredAbsolutePathsOfFilesToCommit];
			}];			
		}];
		[NSApp endSheet:theCommitSheet];
		[theCommitSheet orderOut:sender];
		return;
	}

	NSMutableArray*  qimportArgs   = [NSMutableArray arrayWithObjects:@"qimport", @"--rev", [myDocument getHGParent1Revision], @"--name", @"macHgAmendPatch", nil];
	ExecutionResult* qimportResult = [myDocument executeMercurialWithArgs:qimportArgs  fromRoot:rootPath  whileDelayingEvents:YES];
	if ([qimportResult hasErrors])
	{
		PlayBeep();
		[amendButton setState:NSOffState];
		DebugLog(fstr(@"Could not amend to rev %@", [myDocument getHGParent1Revision]));
		return;
	}
	
	[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{
		NSMutableArray* qrefreshArgs = [NSMutableArray arrayWithObjects:@"qrefresh", @"--short", nil];
		
		[myDocument registerPendingRefresh:filteredAbsolutePathsOfFilesToCommit];
		if (IsNotEmpty(excludedPaths))
			for (NSString* excludedPath in excludedPaths)
				[qrefreshArgs addObject:@"--exclude" followedBy:excludedPath];
		if ([self committerOption] && IsNotEmpty([self committer]))
			[qrefreshArgs addObject:@"--user" followedBy:[self committer]];
		if ([self dateOption] && IsNotEmpty([self date]))
			[qrefreshArgs addObject:@"--date" followedBy:[[self date] isodateDescription]];
		[qrefreshArgs addObjectsFromArray:filteredAbsolutePathsOfFilesToCommit];
		ExecutionResult* qrefreshResult = [myDocument executeMercurialWithArgs:qrefreshArgs  fromRoot:rootPath  whileDelayingEvents:YES];
		
		NSMutableArray*  qfinishArgs   = [NSMutableArray arrayWithObjects:@"qfinish", @"macHgAmendPatch", nil];
		ExecutionResult* qfinishResult = [myDocument executeMercurialWithArgs:qfinishArgs  fromRoot:rootPath  whileDelayingEvents:YES];
			
		[myDocument addToChangedPathsDuringSuspension:filteredAbsolutePathsOfFilesToCommit];
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
