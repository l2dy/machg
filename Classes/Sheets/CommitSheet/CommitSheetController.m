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
#import "FSNodeInfo.h"
#import "FSViewerTable.h"

NSString* kAmendOption	 = @"amendOption";




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface CommitSheetController (PrivateAPI)
- (IBAction)	validateButtons:(id)sender;
- (void)		amendOptionChanged;
- (void)		setSheetTitle;
- (NSArray*)	tableLeafNodes;
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

- (IBAction) handlePreviousCommitMessagesTableClick:(id)sender
{	
}

- (IBAction) handlePreviousCommitMessagesTableDoubleClick:(id)sender
{
	NSString* message = [logCommentsTableSourceData objectAtIndex:[previousCommitMessagesTableView clickedRow]];
	[commitMessageTextView insertText:message];
	[theCommitSheet makeFirstResponder:commitMessageTextView];
}


- (IBAction) browserAction:(id)browser
{
}

- (IBAction) browserDoubleAction:(id)browser
{
	[self commitSheetDiffAction:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Sheet opening
// -----------------------------------------------------------------------------------------------------------------------------------------



- (void) openCommitSheetWithPaths:(NSArray*)paths
{
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
	absolutePathsOfFilesToCommit = pruneContainedPaths([[myDocument theFSViewer] filterPaths:paths byBitfield:eHGStatusChangedInSomeWay]);
	
	[commitFilesViewer	actionSwitchToFilesTable:self];
	[commitFilesViewer	repositoryDataIsNew];

	// Fetch the last 10 log comments and set the sources so that the table view of these in the commit sheet shows them correctly.
	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--limit", @"10", @"--template", @"{desc}\n#^&^#\n", nil];
	ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:rootPath  logging:eLoggingNone];
	logCommentsTableSourceData = [hgLogResults.outStr componentsSeparatedByString:@"\n#^&^#\n"];
	[previousCommitMessagesTableView reloadData];
	cachedCommitMessageForAmend_ = [[logCommentsTableSourceData objectAtIndex:0] copy];

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
	NSArray* paths = [myDocument absolutePathsOfChosenFiles];
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
	// [excludePathsButton setToolTip:excludeTooltipMessage];

	NSString* includeTooltipMessage = @"Reinclude files for the commit.";
	if ([myDocument inMergeState])
		includeTooltipMessage = @"Cannot exclude files during a merge commit.";
	else if (amendOption_)
		includeTooltipMessage = @"Reinclude files for the amend.";
	//[includePathsButton setToolTip:includeTooltipMessage];
}

- (void) makeMessageFieldFirstResponder
{
	[theCommitSheet makeFirstResponder:commitMessageTextView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	SEL theAction = [anItem action];
	// CommitSheet contextual items
	if (theAction == @selector(commitSheetDiffAction:))			return [commitFilesViewer nodesAreSelected];
	return NO;
}


- (IBAction) validateButtons:(id)sender
{
	BOOL pathsAreSelected = [commitFilesViewer nodesAreSelected];
	BOOL canAllowAmend = AllowHistoryEditingOfRepositoryFromDefaults() && [myDocument isCurrentRevisionTip] && ![myDocument inMergeState];
	NSInteger fileCount = [[self tableLeafNodes] count];
	BOOL okToCommit = (fileCount > 0) && ([excludedItems count] < fileCount) && IsNotEmpty([commitMessageTextView string]);
	NSString* diffButtonMessage = pathsAreSelected ? @"Diff Selected" : @"Diff All";
	
	dispatch_async(mainQueue(), ^{
		[diffButton setTitle:diffButtonMessage];
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
	NSString* currentMessage = [[commitMessageTextView string] copy];
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
	if (aTableView == previousCommitMessagesTableView)
		return [logCommentsTableSourceData count];
	return 0;
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == previousCommitMessagesTableView)
		return [logCommentsTableSourceData objectAtIndex:rowIndex];
	return @" ";
}

- (NSArray*) tableLeafNodes
{
	return [[commitFilesViewer theFilesTable] leafNodeForTableRow];
}

- (NSArray*) tableLeafPaths
{
	return pathsOfFSNodes([[commitFilesViewer theFilesTable] leafNodeForTableRow]);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) sheetActionCommit:(NSArray*)pathsToCommit excluding:(NSArray*)excludedPaths
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


- (void) sheetActionAmend:(NSArray*)pathsToCommit excluding:(NSArray*)excludedPaths
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
	NSMutableArray*  qimportArgs   = [NSMutableArray arrayWithObjects:@"qimport", @"--config", @"extensions.hgext.mq=", @"--rev", parent1RevisionStr, @"--name", @"macHgAmendPatch", nil];
	ExecutionResult* qimportResult = [myDocument executeMercurialWithArgs:qimportArgs  fromRoot:rootPath  whileDelayingEvents:YES];
	if ([qimportResult hasErrors])
	{
		NSRunAlertPanel(@"Aborted Import", fstr(@"The Amend operation could not proceed. The patch import process reported the error: %@.", [qimportResult errStr]), @"OK", nil, nil);
		[amendButton setState:NSOffState];
		return;
	}
	
	[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{

		[myDocument registerPendingRefresh:pathsToCommit];

		NSMutableArray* qrefreshArgs = [NSMutableArray arrayWithObjects:@"qrefresh", @"--config", @"extensions.hgext.mq=", @"--short", nil];
		if ([self committerOption] && IsNotEmpty([self committer]))
			[qrefreshArgs addObject:@"--user" followedBy:[self committer]];
		if ([self dateOption] && IsNotEmpty([self date]))
			[qrefreshArgs addObject:@"--date" followedBy:[[self date] isodateDescription]];
		[qrefreshArgs addObject:@"--message" followedBy:[commitMessageTextView string]];
		[qrefreshArgs addObjectsFromArray:[self tableLeafPaths]];
		ExecutionResult* qrefreshResult = [myDocument executeMercurialWithArgs:qrefreshArgs  fromRoot:rootPath  whileDelayingEvents:YES];
		if ([qrefreshResult hasErrors])
		{
			NSRunAlertPanel(@"Aborted Import", fstr(@"The Amend operation could not proceed. The patch refresh process reported the error: %@. Please back out any patch operations.", [qrefreshResult errStr]), @"OK", nil, nil);
			[amendButton setState:NSOffState];
			return;
		}
		
		NSMutableArray*  qfinishArgs   = [NSMutableArray arrayWithObjects:@"qfinish", @"--config", @"extensions.hgext.mq=", @"macHgAmendPatch", nil];
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
	NSArray* paths = committingAllFiles ? [myDocument absolutePathOfRepositoryRootAsArray] : absolutePathsOfFilesToCommit; 		// absolutePathsOfFilesToCommit is set when the sheet is opened.
	NSMutableArray* filteredAbsolutePathsOfFilesToCommit = [NSMutableArray arrayWithArray:paths];
	//[filteredAbsolutePathsOfFilesToCommit removeObjectsInArray:excludedPaths];
	
	[theCommitSheet makeFirstResponder:theCommitSheet];	// Make the fields of the sheet commit any changes they currently have

	// This is more a check here, error handling should have caught this before now if the files were empty.
	NSArray* excludedPaths = [NSArray array];
	NSArray* commitData = [self tableLeafPaths];
	if (IsEmpty(commitData) || 
		//[excludedPaths count] >= [commitData count] || 
		IsEmpty(filteredAbsolutePathsOfFilesToCommit))
	{
		PlayBeep();
		DebugLog(@"Nothing to commit");
		[NSApp endSheet:theCommitSheet];
		[theCommitSheet orderOut:sender];
		return;
	}

	
	[myDocument removeAllUndoActionsForDocument];
	
	if ([amendButton state] == NSOffState)
		[self sheetActionCommit:filteredAbsolutePathsOfFilesToCommit excluding:excludedPaths];
	else if ([amendButton state] == NSOnState)
		[self sheetActionAmend:filteredAbsolutePathsOfFilesToCommit excluding:excludedPaths];

	[NSApp endSheet:theCommitSheet];
	[theCommitSheet orderOut:sender];
}


- (IBAction) commitSheetDiffAction:(id)sender
{
	NSArray* nodesToDiff = [commitFilesViewer nodesAreSelected] ? [commitFilesViewer chosenNodes] : [self tableLeafNodes];
	NSArray* pathsToDiff = pathsOfFSNodes(nodesToDiff);
	[myDocument viewDifferencesInCurrentRevisionFor:pathsToDiff toRevision:nil]; // nil indicates the current revision
	[self makeMessageFieldFirstResponder];
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FSViewer Protocol Methods
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

// All Controllers which embed a FSBrowser must conform to this protocol
- (NSArray*) statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath
{
	NSArray* restrictedPaths = restrictPathsToPaths(absolutePaths,absolutePathsOfFilesToCommit);

	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", @"--added", @"--removed", @"--deleted", @"--modified", nil];
	[argsStatus addObjectsFromArray:restrictedPaths];
	
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	
	if ([results hasErrors])
	{
		// Try a second time
		sleep(0.5);
		results = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	}
	if ([results.errStr length] > 0)
	{
		[results logMercurialResult];
		// for an error rather than warning fail by returning nil. Maybe later we will return error codes.
		if ([results hasErrors])
			return  nil;
	}
	NSArray* lines = [results.outStr componentsSeparatedByString:@"\n"];
	return IsNotEmpty(lines) ? lines : [NSArray array];
}

// Get any resolve status lines and change the resolved code 'R' to 'V' so that this status letter doesn't conflict with the other
// status letters.
- (NSArray*) resolveStatusLines:(NSArray*)absolutePaths  withRootPath:(NSString*)rootPath
{
	NSArray* restrictedPaths = restrictPathsToPaths(absolutePaths,absolutePathsOfFilesToCommit);
	
	// Get status of everything relevant and return this array for use by the node tree to re-flush stale parts of it (or all of it.)
	NSMutableArray* argsResolveStatus = [NSMutableArray arrayWithObjects:@"resolve", @"--list", nil];
	[argsResolveStatus addObjectsFromArray:restrictedPaths];
	
	ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsResolveStatus fromRoot:rootPath  logging:eLoggingNone];
	if ([results hasErrors])
	{
		[results logMercurialResult];
		return nil;
	}
	NSArray* lines = [results.outStr componentsSeparatedByString:@"\n"];
	NSMutableArray* newLines = [[NSMutableArray alloc] init];
	for (NSString* line in lines)
		if (IsNotEmpty(line))
		{
			if ([line characterAtIndex:0] == 'R')
				[newLines addObject:fstr(@"V%@",[line substringFromIndex:1])];
			else
				[newLines addObject:line];
		}
	return newLines;
}

- (BOOL) writePaths:(NSArray*)paths toPasteboard:(NSPasteboard*)pasteboard
{
	[pasteboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
	[pasteboard setPropertyList:paths forType:NSFilenamesPboardType];	
	return IsNotEmpty(paths) ? YES : NO;
}


- (void)			setMyDocumentFromParent					{ };
- (void)			didSwitchViewTo:(FSViewerNum)viewNumber { };
- (BOOL)			controlsMainFSViewer					{ return NO; }
- (void)			updateCurrentPreviewImage				{ };



@end

