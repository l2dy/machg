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
#import "PatchData.h"
#import "HunkExclusions.h"

NSString* kAmendOption	 = @"amendOption";



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitFSViewer
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation CommitFSViewer
- (void) awakeFromNib
{
	[super awakeFromNib];

	HunkExclusions* exclusions = [self hunkExclusions];
	[self observe:kHunkWasExcluded from:exclusions byCalling:@selector(nodeWasChanged:)];
	[self observe:kHunkWasIncluded from:exclusions byCalling:@selector(nodeWasChanged:)];
	[self observe:kFileWasExcluded from:exclusions byCalling:@selector(nodeWasChanged:)];
	[self observe:kFileWasIncluded from:exclusions byCalling:@selector(nodeWasChanged:)];
}

- (void) nodeWasChanged:(NSNotification*)notification
{
	if ([self showingFilesTable])
	{
		NSDictionary* userInfo = [notification userInfo];
		NSString* absolutePath = fstr(@"%@/%@", nonNil([userInfo objectForKey:kRootPath]), nonNil([userInfo objectForKey:kFileName]));
		FSNodeInfo* changedNode = [[self rootNodeInfo] nodeForPathFromRoot:absolutePath];
		if (changedNode)
			[[[self window] contentView] setNeedsDisplayInRect:[self rectInWindowForNode:changedNode]];
	}
	[(id)parentController performSelectorIfPossible:@selector(validateButtons:) withObject:self];
}

- (NSString*) nibNameForFilesTable   { return @"CommitFilesViewTable"; }
@end





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
@synthesize	commitSubstateOption = commitSubstateOption_;
@synthesize absolutePathsOfFilesToCommit = absolutePathsOfFilesToCommit_;





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

	// Handle the commit substate option
	hasHgSub_ = pathIsExistentFile(fstr(@"%@/.hgsub",rootPath));
	[self setCommitSubstateOption:SubrepoSubstateCommitFromDefauts() == eSubrepositorySubstateDoCommit];
	[commitSubstateButton setHidden:!hasHgSub_];
	
	NSString* currentMessage = [commitMessageTextView string];
	[commitMessageTextView setSelectedRange:NSMakeRange(0, [currentMessage length])];
	[self setSheetTitle];
	[myDocument beginSheet:theCommitSheet];
	[theCommitSheet makeFirstResponder:commitMessageTextView];

	// Store the paths of the files to be committed
	absolutePathsOfFilesToCommit_ = pruneContainedPaths([[myDocument theFSViewer] filterPaths:paths byBitfield:eHGStatusChangedInSomeWay]);
	
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
	BOOL allFiles = committingAllFiles;
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

- (BOOL) anyHunksToCommit
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	HunkExclusions* hunkExclusions = [self hunkExclusions];
	for(FSNodeInfo* node in [self tableLeafNodes])
	{
		NSString* fileName = pathDifference(rootPath, [node absolutePath]);
		NSSet* hunkExclusionSet = [hunkExclusions hunkExclusionSetForRoot:rootPath andFile:fileName];
		if (IsEmpty(hunkExclusionSet))
			return YES;
		NSSet* validHunkHashSet = [hunkExclusions validHunkHashSetForRoot:rootPath andFile:fileName];
		if (IsNotEmpty(validHunkHashSet) && ![validHunkHashSet isSubsetOfSet:hunkExclusionSet])
			return YES;
	}
	return NO;
}

- (IBAction) validateButtons:(id)sender
{
	BOOL pathsAreSelected = [commitFilesViewer nodesAreSelected];
	BOOL canAllowAmend = AllowHistoryEditingOfRepositoryFromDefaults() && [myDocument isCurrentRevisionTip] && ![myDocument inMergeState];
	BOOL okToCommit = IsNotEmpty([commitMessageTextView string]) && [self anyHunksToCommit];
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
// MARK:  Committing
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSArray*) argumentsForUserDataMessage
{
	NSString* theMessage = [commitMessageTextView string];
	NSMutableArray* args = [NSMutableArray arrayWithObjects:@"--message", theMessage, nil];
	if ([self committerOption] && IsNotEmpty([self committer]))
		[args addObject:@"--user" followedBy:[self committer]];
	if ([self dateOption] && IsNotEmpty([self date]))
		[args addObject:@"--date" followedBy:[[self date] isodateDescription]];
	return args;
}


- (void) handleCommitSubrepoSubstateOption:(NSMutableArray*)commandArgs
{
	if (hasHgSub_ && [commitSubstateButton state] == NSOffState)
	{
		[commandArgs addObject:@"-X" followedBy:@".hgsub"];
		[commandArgs addObject:@"-X" followedBy:@".hgsubstate"];
	}
}

- (void) sheetActionSimpleCommit:(NSArray*)pathsToCommit
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	[myDocument dispatchToMercurialQueuedWithDescription:@"Committing Files" process:^{
		NSMutableArray* args = [NSMutableArray arrayWithObjects:@"commit", nil];
		[self handleCommitSubrepoSubstateOption:args];
		[myDocument registerPendingRefresh:pathsToCommit];
		[args addObjectsFromArray:[self argumentsForUserDataMessage]];
		if (![myDocument inMergeState])
			[args addObjectsFromArray:pathsToCommit];
		
		[myDocument delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath];
			[myDocument addToChangedPathsDuringSuspension:pathsToCommit];
		}];			
	}];
}

- (BOOL) commit_setupForAmend
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	
	if (DisplayWarningForAmendFromDefaults())
	{
		BOOL pathsAreRootPath = [[absolutePathsOfFilesToCommit_ lastObject] isEqual:rootPath];
		NSString* mainMessage = fstr(@"Amending the latest revision with %@ files", pathsAreRootPath ? @"all" : @"the selected");
		NSString* subMessage  = fstr(@"Are you sure you want to amend the latest revision in the repository “%@”.", [myDocument selectedRepositoryShortName]);
		int result = RunCriticalAlertPanelOptionsWithSuppression(mainMessage, subMessage, @"Amend", @"Cancel", nil, MHGDisplayWarningForAmend);
		if (result != NSAlertFirstButtonReturn)
			[NSException raise:@"UserCanceled" format:@"The user canceled this operation", nil];
	}	
	
	NSString* parent1RevisionStr = numberAsString([myDocument getHGParent1Revision]);
	NSMutableArray*  qimportArgs   = [NSMutableArray arrayWithObjects:@"qimport", @"--config", @"extensions.hgext.mq=", @"--rev", parent1RevisionStr, @"--name", @"macHgAmendPatch", @"--git", nil];
	ExecutionResult* qimportResult = [myDocument executeMercurialWithArgs:qimportArgs  fromRoot:rootPath  whileDelayingEvents:YES];
	if ([qimportResult hasErrors])
		[NSException raise:@"QImporting" format:@"The Amend operation could not proceed. The process of importing the existing patch reported the error: %@.", [qimportResult errStr], nil];
	return YES;
}

- (void) commit_backupContestedFiles:(NSArray*)contestedPaths into:(NSString*)tempDirectoryPath withRoot:(NSString*)rootPath
{
	if (IsEmpty(contestedPaths))
		return;
	if (!tempDirectoryPath)
		[NSException raise:@"TempDirectory" format:@"Unable to create a necessary temporary directory. Aborting the operation.", nil];
	for (NSString* originalPath in contestedPaths)
	{
		NSError* err = nil;
		NSString* backupPath =  fstr(@"%@/%@",tempDirectoryPath, pathDifference(rootPath, originalPath));
		[[NSFileManager defaultManager] copyItemAtPath:originalPath toPath:backupPath withIntermediateDirectories:YES error:&err];
		if (err)
		{
			NSString* operation = ([amendButton state] == NSOnState) ? @"amend" : @"commit";
			[NSException raise:@"Backup" format:@"Unable to backup files before the main %@ (Mac OS reports: %@). Aborting the %@.", operation, [err localizedDescription], operation, nil];
		}
	}	
}

- (void) commit_restoreContestedFiles:(NSArray*)contestedPaths from:(NSString*)tempDirectoryPath withRoot:(NSString*)rootPath
{
	for (NSString* originalPath in contestedPaths)
	{
		NSError* err = nil;
		NSString* backupPath =  fstr(@"%@/%@",tempDirectoryPath, pathDifference(rootPath, originalPath));
		[[NSFileManager defaultManager] removeItemAtPath:originalPath error:&err];
		[NSApp presentAnyErrorsAndClear:&err];
		[[NSFileManager defaultManager] copyItemAtPath:backupPath toPath:originalPath error:&err];
		[NSApp presentAnyErrorsAndClear:&err];
	}
	moveFilesToTheTrash([NSArray arrayWithObject:tempDirectoryPath]);
}

- (void) sheetActionCommitWithUncontestedPaths:(NSArray*)uncontestedPaths andContestedPaths:(NSArray*)contestedPaths amending:(BOOL)amend
{
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSString* operation = amend ? @"amend" : @"commit";
	NSString* errorTitle = fstr(@"Aborted %@", amend ? @"Amend" : @"Commit");
	NSString* operationTitle = fstr(@"%@ Files", amend ? @"Amending" : @"Committing");
	
	// Get contested Patch File
	NSString* contestedPatchFile = nil;
	if (IsNotEmpty(contestedPaths))
	{
		NSMutableArray* argsDiff = [NSMutableArray arrayWithObjects:@"diff", nil];
		[argsDiff addObjectsFromArray:contestedPaths];
		ExecutionResult* diffResult = [TaskExecutions executeMercurialWithArgs:argsDiff  fromRoot:rootPath logging:eLoggingNone];
		PatchData* patchData = IsNotEmpty(diffResult.outStr) ? [PatchData patchDataFromDiffContents:diffResult.outStr] : nil;
		contestedPatchFile = [patchData tempFileWithPatchBodyExcluding:[self hunkExclusions] withRoot:rootPath];
	}
	
	// Create temporary Directory and copy contested files to this directory
	NSString* commitPartsDirectory = fstr(@"%@/%@", rootPath, @".hg/macHgParts");
	NSString* tempDirectoryPath = tempDirectoryPathWithTemplate(@"MacHgContestedFilePatchBackupDir.XXXXXXXXXX", commitPartsDirectory);
	@try
	{
		[self commit_backupContestedFiles:contestedPaths into:tempDirectoryPath withRoot:rootPath];
		if (amend)
			[self commit_setupForAmend];
	}
	@catch (NSException* e)
	{
		if ([[e name] isEqualToString:@"UserCanceled"])
			return;
		NSRunCriticalAlertPanel(errorTitle, [e reason], @"OK", nil, nil);
		return;
	}
	
	NSArray* commitCommandArguments = [self argumentsForUserDataMessage];
	
	[myDocument dispatchToMercurialQueuedWithDescription:operationTitle process:^{

		[myDocument registerPendingRefresh:uncontestedPaths];
		[myDocument registerPendingRefresh:contestedPaths];

		[myDocument delayEventsUntilFinishBlock:^{
			@try
			{
				// Revert the contested files to their original state
				if (IsNotEmpty(contestedPaths))
				{
					NSMutableArray* argsRevert = [NSMutableArray arrayWithObjects:@"revert", @"--no-backup", nil];
					[argsRevert addObjectsFromArray:contestedPaths];
					ExecutionResult* revertResult = [TaskExecutions executeMercurialWithArgs:argsRevert  fromRoot:rootPath logging:eLoggingNone];
					if ([revertResult hasErrors])
						[NSException raise:@"Reverting" format:@"During the process needed to %@ the files, the step of reverting the files with excluded hunks reported the error: %@.", operation, [revertResult errStr], nil];
				}

				// Patch the contested files to the desired state, (if all the hunks are descelected in the contested files the
				// patch will be empty) 
				if (contestedPatchFile)
				{
					NSMutableArray*  importArgs   = [NSMutableArray arrayWithObjects:@"import", @"--no-commit", @"--force", contestedPatchFile, nil];
					ExecutionResult* importResult = [TaskExecutions executeMercurialWithArgs:importArgs  fromRoot:rootPath logging:eLoggingNone];
					if ([importResult hasErrors])
						[NSException raise:@"Importing" format:@"During the process needed to %@ the files, the step of adjusting the files to exclude the specified hunks reported the error: %@.", operation, [importResult errStr], nil];
				}
				
				if (!amend)
				{
					// Do the commit
					NSMutableArray* commitArgs = [NSMutableArray arrayWithObjects:@"commit", nil];
					[self handleCommitSubrepoSubstateOption:commitArgs];
					[commitArgs addObjectsFromArray:commitCommandArguments];
					[commitArgs addObjectsFromArray:uncontestedPaths];
					[commitArgs addObjectsFromArray:contestedPaths];
					ExecutionResult* commitResult = [TaskExecutions executeMercurialWithArgs:commitArgs  fromRoot:rootPath logging:eLoggingNone];
					if ([commitResult hasErrors])
						[NSException raise:@"Committing" format:@"During the process needed to %@ the files, the step of commiting the adjusted files reported the error: %@.", operation, [commitResult errStr], nil];
				}
				else
				{
					// Do the refresh
					NSMutableArray* qrefreshArgs = [NSMutableArray arrayWithObjects:@"qrefresh", @"--config", @"extensions.hgext.mq=", @"--short", nil];
					[self handleCommitSubrepoSubstateOption:qrefreshArgs];
					[qrefreshArgs addObjectsFromArray:commitCommandArguments];
					[qrefreshArgs addObjectsFromArray:uncontestedPaths];
					[qrefreshArgs addObjectsFromArray:contestedPaths];
					ExecutionResult* qrefreshResult = [myDocument executeMercurialWithArgs:qrefreshArgs  fromRoot:rootPath  whileDelayingEvents:YES];
					if ([qrefreshResult hasErrors])
						[NSException raise:@"Refreshing" format:@"The amend operation could not proceed. The patch refresh process reported the error: %@. Please back out any patch operations.", [qrefreshResult errStr], nil];
					
					// Do the queue finish
					NSMutableArray*  qfinishArgs   = [NSMutableArray arrayWithObjects:@"qfinish", @"--config", @"extensions.hgext.mq=", @"macHgAmendPatch", nil];
					ExecutionResult* qfinishResult = [myDocument executeMercurialWithArgs:qfinishArgs  fromRoot:rootPath  whileDelayingEvents:YES];
					if ([qfinishResult hasErrors])
						[NSException raise:@"Finishing" format:@"The amend operation could not proceed. The patch finish process reported the error: %@. Please back out any patch operations.", [qfinishResult errStr], nil];
				}
			}
			@catch (NSException * e)
			{
				[amendButton setState:NSOffState];
				NSRunCriticalAlertPanel(errorTitle, [e reason], @"OK", nil, nil);
			}
			@finally
			{
				// Replace the contested files with their original backups
				[self commit_restoreContestedFiles:contestedPaths from:tempDirectoryPath withRoot:rootPath];
				[myDocument addToChangedPathsDuringSuspension:contestedPaths];
				[myDocument addToChangedPathsDuringSuspension:uncontestedPaths];
			}
		}];			
	}];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) sheetButtonOk:(id)sender
{
	NSString* root = [myDocument absolutePathOfRepositoryRoot];
	
	[theCommitSheet makeFirstResponder:theCommitSheet];	// Make the fields of the sheet commit any changes they currently have

	NSArray* commitData = [self tableLeafPaths];
	NSArray*   contestedPaths = [[self hunkExclusions]   contestedPathsIn:commitData  forRoot:root];
	NSArray* uncontestedPaths = [[self hunkExclusions] uncontestedPathsIn:commitData  forRoot:root];
	BOOL inMerge = [[myDocument repositoryData] inMergeState];
	BOOL simpleOperation = 	IsEmpty(contestedPaths);
	BOOL amend = ([amendButton state] == NSOnState);
	
	// This is more a check here, error handling should have caught this before now if the files were empty.
	if (IsEmpty(commitData))
	{
		PlayBeep();
		DebugLog(@"Nothing to commit");
		[NSApp endSheet:theCommitSheet];
		[theCommitSheet orderOut:sender];
		return;
	}

	[myDocument removeAllUndoActionsForDocument];
	
	if ((simpleOperation && !amend) || inMerge)
		[self sheetActionSimpleCommit:absolutePathsOfFilesToCommit_];
	else
		[self sheetActionCommitWithUncontestedPaths:uncontestedPaths andContestedPaths:contestedPaths amending:amend];

	[myDocument endSheet:theCommitSheet];
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
	[myDocument endSheet:theCommitSheet];
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
	NSArray* restrictedPaths = restrictPathsToPaths(absolutePaths,absolutePathsOfFilesToCommit_);

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
	NSArray* restrictedPaths = restrictPathsToPaths(absolutePaths,absolutePathsOfFilesToCommit_);
	
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

- (HunkExclusions*) hunkExclusions
{
	return [myDocument hunkExclusions];
}


- (void)			setMyDocumentFromParent					{ };
- (void)			didSwitchViewTo:(FSViewerNum)viewNumber { };
- (BOOL)			controlsMainFSViewer					{ return NO; }
- (void)			updateCurrentPreviewImage				{ };



@end

