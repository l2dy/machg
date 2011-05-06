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
#import "RepositoryData.h"

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
- (void)		setSheetTitle;
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

	//[disclosureController setToOpenState:NO withAnimation:NO];
	[self setCommitter:nonNil(userNameResult.outStr)];
	[self setCommitterOption:NO];
	[self setDate:[NSDate date]];
	[self setDateOption:NO];
	if ([amendButton state] == NSOnState)
		[self setAmendOption:NO];
	
	NSString* currentMessage = [commitMessageTextView string];
	[commitMessageTextView setSelectedRange:NSMakeRange(0, [currentMessage length])];
	[self setSheetTitle];
	[NSApp beginSheet:theCommitSheet modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[theCommitSheet makeFirstResponder:commitMessageTextView];

	// Store the paths of the files to be committed
	absolutePathsOfFilesToCommit = [[myDocument theBrowser] filterPaths:paths byBitfield:eHGStatusChangedInSomeWay];
	
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
	cachedCommitMessageForAmend_ = [NSString stringWithString:[logCommentsTableSourceData objectAtIndex:0]];

	[self validateButtons:self];
}


- (IBAction) openCommitSheetWithAllFiles:(id)sender
{
	committingAllFiles = YES;
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
	NSArray* paths = [myDocument absolutePathsOfBrowserChosenFiles];
	if ([paths count] <= 0)
		{ PlayBeep(); DebugLog(@"No files are selected to commit"); return; }

	[self openCommitSheetWithPaths:paths];
}


- (void) setSheetTitle
{
	NSString* newTitle = nil;
	BOOL mergedState = [[myDocument repositoryData] inMergeState];
	BOOL allFiles = committingAllFiles && IsEmpty(excludedItems);
	NSString* repositoryShortName = [myDocument selectedRepositoryShortName];
	if (mergedState)
		newTitle = fstr(@"Committing Merged Files in %@", repositoryShortName);
	else if (allFiles && !amendOption_)
		newTitle = fstr(@"Committing All Files in %@", repositoryShortName);
	else if (amendOption_)
		newTitle = fstr(@"Amending Selected Files in %@", repositoryShortName);
	else
		newTitle = fstr(@"Committing Selected Files in %@", repositoryShortName);
	[commitSheetTitle setStringValue:newTitle];
}

- (void) setTooltipMessgaes
{
	NSString* amendTooltipMessage = @"Amend will incorporate the files to be committed into the last changeset.";
	if (!AllowHistoryEditingOfRepositoryFromDefaults())
		amendTooltipMessage = @"History editing needs to be enabled in order to use the amend option.";
	else if ([myDocument inMergeState])
		amendTooltipMessage = @"The changeset to be amended cannot be a merge changeset.";
	else if (![myDocument isCurrentRevisionTip])
		amendTooltipMessage = @"The changeset to be amended must be the tip revision.";
	[amendButton setToolTip:amendTooltipMessage];
	
	NSString* excludeTooltipMessage = @"Exclude files from the commit.";
	if ([myDocument inMergeState])
		excludeTooltipMessage = @"Cannot exclude files during a merge commit.";
	else if (amendOption_)
		excludeTooltipMessage = @"Exclude files from the amend.";
	[excludePathsButton setToolTip:excludeTooltipMessage];

	NSString* includeTooltipMessage = @"Reinclude files for the commit.";
	if ([myDocument inMergeState])
		includeTooltipMessage = @"Cannot exclude files during a merge commit.";
	else if (amendOption_)
		includeTooltipMessage = @"Reinclude files for the amend.";
	[includePathsButton setToolTip:includeTooltipMessage];
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
	if (theAction == @selector(excludePathsAction:))			return [selectedIndexes count] > 0 && ![excludedItems containsIndexes:selectedIndexes] && ![myDocument inMergeState];
	if (theAction == @selector(includePathsAction:))			return [selectedIndexes count] > 0 && [excludedItems intersectsIndexes:selectedIndexes];
	return [myDocument validateUserInterfaceItem:anItem];
}


- (IBAction) validateButtons:(id)sender
{
	NSIndexSet* selectedIndexes = [filesToCommitTableView selectedRowIndexes];
	BOOL pathsAreSelected = [selectedIndexes count] > 0;
	BOOL pathsCanBeExcluded = pathsAreSelected && ![excludedItems containsIndexes:selectedIndexes] && ![myDocument inMergeState];
	BOOL pathsCanBeIncluded = pathsAreSelected && [excludedItems intersectsIndexes:selectedIndexes];
	BOOL canAllowAmend = AllowHistoryEditingOfRepositoryFromDefaults() && [myDocument isCurrentRevisionTip] && ![myDocument inMergeState];
	BOOL okToCommit = ([filesToCommitTableSourceData count] > 0) && ([excludedItems count] < [filesToCommitTableSourceData count]) && IsNotEmpty([commitMessageTextView string]);
	NSString* diffButtonMessage = pathsAreSelected ? @"Diff Selected" : @"Diff All";
	
	dispatch_async(mainQueue(), ^{
		[diffButton setTitle:diffButtonMessage];
		[excludePathsButton setEnabled:pathsCanBeExcluded];
		[includePathsButton setEnabled:pathsCanBeIncluded];
		[okButton setEnabled:okToCommit];
		[amendButton setEnabled:canAllowAmend];
		[self setTooltipMessgaes];
		[self setSheetTitle];
	});
}


// This sets the commit message field into a "disabled" appearance state when the amend option is checked, and swaps out the
// message, forthe old message, etc.
- (void) amendOptionChanged
{
	NSString* currentMessage = [NSString stringWithString:[commitMessageTextView string]];
	[commitMessageTextView setSelectedRange:NSMakeRange(0, [currentMessage length])];
	[commitMessageTextView insertText:cachedCommitMessageForAmend_];
	cachedCommitMessageForAmend_ = currentMessage;
	[self validateButtons:self];
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


- (NSArray*) includedPaths
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* includedPathItems = [NSMutableArray arrayWithArray:filesToCommitTableSourceData];
	if (excludedItems)
		[includedPathItems removeObjectsAtIndexes:excludedItems];

	NSMutableArray* includedPaths = [[NSMutableArray alloc] init];
	for (NSString* item in includedPathItems)
	{
		NSString* relativePath = [item substringFromIndex:2];
		NSString* absolutePath = [rootPath stringByAppendingPathComponent:relativePath];
		[includedPaths addObject:absolutePath];
	};
	return includedPaths;
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
		NSString* subMessage  = fstr(@"Are you sure you want to amend the latest revision in the repository “%@”.",
									 [myDocument selectedRepositoryShortName]);
		
		int result = RunCriticalAlertPanelOptionsWithSuppression(mainMessage, subMessage, @"Amend", @"Cancel", nil, MHGDisplayWarningForAmend);
		if (result != NSAlertFirstButtonReturn)
			return;
	}	
	
	NSString* parent1RevisionStr = numberAsString([myDocument getHGParent1Revision]);
	NSMutableArray*  qimportArgs   = [NSMutableArray arrayWithObjects:@"qimport", @"--config", @"extensions.mq=", @"--rev", parent1RevisionStr, @"--name", @"macHgAmendPatch", nil];
	ExecutionResult* qimportResult = [myDocument executeMercurialWithArgs:qimportArgs  fromRoot:rootPath  whileDelayingEvents:YES];
	if ([qimportResult hasErrors])
	{
		NSRunAlertPanel(@"Aborted Import", fstr(@"The Amend operation could not proceed. The patch import process reported the error: %@.", [qimportResult errStr]), @"OK", nil, nil);
		[amendButton setState:NSOffState];
		return;
	}
	
	[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{

		[myDocument registerPendingRefresh:pathsToCommit];

		NSMutableArray* qrefreshArgs = [NSMutableArray arrayWithObjects:@"qrefresh", @"--config", @"extensions.mq=", @"--short", nil];
		if (IsNotEmpty(excludedPaths))
		if ([self committerOption] && IsNotEmpty([self committer]))
			[qrefreshArgs addObject:@"--user" followedBy:[self committer]];
		if ([self dateOption] && IsNotEmpty([self date]))
			[qrefreshArgs addObject:@"--date" followedBy:[[self date] isodateDescription]];
		[qrefreshArgs addObject:@"--message" followedBy:[commitMessageTextView string]];
		[qrefreshArgs addObjectsFromArray:[self includedPaths]];
		ExecutionResult* qrefreshResult = [myDocument executeMercurialWithArgs:qrefreshArgs  fromRoot:rootPath  whileDelayingEvents:YES];
		if ([qrefreshResult hasErrors])
		{
			NSRunAlertPanel(@"Aborted Import", fstr(@"The Amend operation could not proceed. The patch refresh process reported the error: %@. Please back out any patch operations.", [qrefreshResult errStr]), @"OK", nil, nil);
			[amendButton setState:NSOffState];
			return;
		}
		
		NSMutableArray*  qfinishArgs   = [NSMutableArray arrayWithObjects:@"qfinish", @"--config", @"extensions.mq=", @"macHgAmendPatch", nil];
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


- (void)textDidChange:(NSNotification*) aNotification
{
	[self validateButtons:[aNotification object]];
}

@end
