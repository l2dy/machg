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

NSString* kAmendOption	 = @"amendOption";




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface CommitSheetController (PrivateAPI)
- (IBAction)	validateButtons:(id)sender;
- (NSIndexSet*) chosenIndexesOfFilesToCommit;
- (void)		amendOptionChanged;
@end

@implementation CommitSheetController
@synthesize myDocument;
@synthesize	committerOption = committerOption_;
@synthesize	committer = committer_;
@synthesize	dateOption = dateOption_;
@synthesize	date = date_;
@synthesize	amendOption = amendOption_;





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


- (void) awakeFromNib
{
	[self  addObserver:self  forKeyPath:kAmendOption  options:NSKeyValueObservingOptionNew  context:NULL];
	cachedCommitMessageForAmend_ = nil;
	
	[filesToCommitTableView setTarget:self];
	[filesToCommitTableView setDoubleAction:@selector(handleFilesToCommitTableDoubleClick:)];
	[filesToCommitTableView setAction:@selector(handleFilesToCommitTableClick:)];
	[previousCommitMessagesTableView setTarget:self];
	[previousCommitMessagesTableView setDoubleAction:@selector(handlePreviousCommitMessagesTableDoubleClick:)];
	[previousCommitMessagesTableView setAction:@selector(handlePreviousCommitMessagesTableClick:)];	
}


- (void) observeValueForKeyPath:(NSString*)keyPath  ofObject:(id)object  change:(NSDictionary*)change  context:(void*)context
{
    if ([keyPath isEqualToString:kAmendOption])
		[self amendOptionChanged];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Handle Table Clicks
// -----------------------------------------------------------------------------------------------------------------------------------------

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

	BOOL amendIsPotentiallyPossible = YES;
	NSString* amendTooltipMessage = @"Amend will incorporate the files to be committed into the last changeset.";
	if (!AllowHistoryEditingOfRepositoryFromDefaults())
	{
		amendIsPotentiallyPossible = NO;
		amendTooltipMessage = @"History editing in the preferences needs to be enabled in order to use the amend option.";
	}
	else if ([myDocument inMergeState])
	{
		amendIsPotentiallyPossible = NO;
		amendTooltipMessage = @"The changeset to be amended to cannot be a merge changeset.";
	}
	else if (![myDocument isCurrentRevisionTip])
	{
		amendIsPotentiallyPossible = NO;
		amendTooltipMessage = @"The changeset to be amended to must be the tip revision.";
	}

	[disclosureController setToOpenState:NO];
	[self setCommitter:nonNil(userNameResult.outStr)];
	[self setCommitterOption:NO];
	[self setDate:[NSDate date]];
	[self setDateOption:NO];
	if ([amendButton state] == NSOnState)
		[self setAmendOption:NO];
	[amendButton setEnabled:amendIsPotentiallyPossible];
	[amendButton setToolTip:amendTooltipMessage];
	
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


// This sets the commit message field into a "disabled" appearance state when the amend option is checked, and swaps out the
// message, forthe old message, etc.
- (void) amendOptionChanged
{
	if ([self amendOption])
	{
		cachedCommitMessageForAmend_ = [NSString stringWithString:[commitMessageTextView string]];
		NSString* message = [logCommentsTableSourceData objectAtIndex:0];
		[commitMessageTextView setSelectedRange:NSMakeRange(0, [cachedCommitMessageForAmend_ length])];
		[commitMessageTextView insertText:message];		
		[commitMessageTextView setSelectedRange:NSMakeRange(0, 0)];

		NSColor* fakeDisableColor = [NSColor colorWithDeviceRed:(227.0/255.0) green:(227.0/255.0) blue:(227.0/255.0) alpha:1.0];
		[commitMessageTextView setEditable:NO];
		[commitMessageTextView setSelectable:NO];
		[commitMessageTextView setTextColor:[NSColor disabledControlTextColor]];
		[commitMessageTextView setBackgroundColor:fakeDisableColor];

		[theCommitSheet makeFirstResponder:theCommitSheet];	// Make the commit message field
	}
	else
	{
		[commitMessageTextView setEditable:YES];
		[commitMessageTextView setSelectable:YES];
		[commitMessageTextView setTextColor:[NSColor textColor]];
		[commitMessageTextView setBackgroundColor:[NSColor whiteColor]];
		[commitMessageTextView setSelectedRange:NSMakeRange(0, [[commitMessageTextView string] length])];
		[commitMessageTextView insertText:cachedCommitMessageForAmend_];
	}
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
// MARK: FilesToCommit TableView
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



- (void) primaryActionCommit:(NSArray*)pathsToCommit excluding:(NSArray*)excludedPaths
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{
		NSString* theMessage = [commitMessageTextView string];
		NSMutableArray* args = [NSMutableArray arrayWithObjects:@"commit", @"--message", theMessage, nil];
		
		[myDocument registerPendingRefresh:pathsToCommit];
		if (IsNotEmpty(excludedPaths) && ![myDocument inMergeState])
			for (NSString* excludedPath in excludedPaths)
				[args addObject:@"--exclude" followedBy:excludedPath];
		if ([self committerOption] && IsNotEmpty([self committer]))
			[args addObject:@"--user" followedBy:[self committer]];
		if ([self dateOption] && IsNotEmpty([self date]))
			[args addObject:@"--date" followedBy:[[self date] isodateDescription]];
		if (![myDocument inMergeState])
			[args addObjectsFromArray:pathsToCommit];
		
		[myDocument delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath];
			[myDocument addToChangedPathsDuringSuspension:pathsToCommit];
		}];			
	}];
}


- (void) primaryActionAmend:(NSArray*)pathsToCommit excluding:(NSArray*)excludedPaths
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	
	if (DisplayWarningForAmendFromDefaults())
	{
		BOOL pathsAreRootPath = [[pathsToCommit lastObject] isEqual:rootPath];
		NSString* mainMessage = fstr(@"Amending the latest revision with %@ files", pathsAreRootPath ? @"all" : @"the selected");
		NSString* subMessage  = fstr(@"Are you sure you want to amend the latest revision in the repository “%@”. This feature is still experimental and is undergoing testing. Use backups. If you are not familiar with Mercurial queues then you may not be able to recover if errors occur.",
									 [myDocument selectedRepositoryShortName]);
		
		int result = RunCriticalAlertPanelOptionsWithSuppression(mainMessage, subMessage, @"Amend", @"Cancel", nil, MHGDisplayWarningForAmend);
		if (result != NSAlertFirstButtonReturn)
			return;
	}	
	
	NSMutableArray*  qimportArgs   = [NSMutableArray arrayWithObjects:@"qimport", @"--rev", [myDocument getHGParent1Revision], @"--name", @"macHgAmendPatch", nil];
	ExecutionResult* qimportResult = [myDocument executeMercurialWithArgs:qimportArgs  fromRoot:rootPath  whileDelayingEvents:YES];
	if ([qimportResult hasErrors])
	{
		NSRunAlertPanel(@"Aborted Import", fstr(@"The Amend operation could not proceed. The patch import process reported the error: %@.", [qimportResult errStr]), @"OK", nil, nil);
		[amendButton setState:NSOffState];
		return;
	}
	
	[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{		

		[myDocument registerPendingRefresh:pathsToCommit];

		NSMutableArray* qrefreshArgs = [NSMutableArray arrayWithObjects:@"qrefresh", @"--short", nil];
		if (IsNotEmpty(excludedPaths))
			for (NSString* excludedPath in excludedPaths)
				[qrefreshArgs addObject:@"--exclude" followedBy:excludedPath];
		if ([self committerOption] && IsNotEmpty([self committer]))
			[qrefreshArgs addObject:@"--user" followedBy:[self committer]];
		if ([self dateOption] && IsNotEmpty([self date]))
			[qrefreshArgs addObject:@"--date" followedBy:[[self date] isodateDescription]];
		[qrefreshArgs addObjectsFromArray:pathsToCommit];
		ExecutionResult* qrefreshResult = [myDocument executeMercurialWithArgs:qrefreshArgs  fromRoot:rootPath  whileDelayingEvents:YES];
		if ([qrefreshResult hasErrors])
		{
			NSRunAlertPanel(@"Aborted Import", fstr(@"The Amend operation could not proceed. The patch refresh process reported the error: %@. Please back out any patch operations.", [qrefreshResult errStr]), @"OK", nil, nil);
			[amendButton setState:NSOffState];
			return;
		}
		
		NSMutableArray*  qfinishArgs   = [NSMutableArray arrayWithObjects:@"qfinish", @"macHgAmendPatch", nil];
		ExecutionResult* qfinishResult = [myDocument executeMercurialWithArgs:qfinishArgs  fromRoot:rootPath  whileDelayingEvents:YES];
		if ([qfinishResult hasErrors])
		{
			NSRunAlertPanel(@"Aborted Import", fstr(@"The Amend operation could not proceed. The patch finish process reported the error: %@. Please back out any patch operations.", [qfinishResult errStr]), @"OK", nil, nil);
			[amendButton setState:NSOffState];
			return;
		}
		
		[myDocument addToChangedPathsDuringSuspension:pathsToCommit];
	}];
}


- (IBAction) sheetButtonOk:(id)sender
{
	NSArray* excludedPaths = [self excludedPaths];
	NSArray* paths = committingAllFiles ? [myDocument absolutePathOfRepositoryRootAsArray] : absolutePathsOfFilesToCommit; 		// absolutePathsOfFilesToCommit is set when the sheet is opened.
	NSMutableArray* filteredAbsolutePathsOfFilesToCommit = [NSMutableArray arrayWithArray:paths];
	[filteredAbsolutePathsOfFilesToCommit removeObjectsInArray:excludedPaths];
	
	[theCommitSheet makeFirstResponder:theCommitSheet];	// Make the fields of the sheet commit any changes they currently have

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
		[self primaryActionCommit:filteredAbsolutePathsOfFilesToCommit excluding:excludedPaths];
	else if ([amendButton state] == NSOnState)
		[self primaryActionAmend:filteredAbsolutePathsOfFilesToCommit excluding:excludedPaths];

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
