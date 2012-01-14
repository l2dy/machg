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
	absolutePathsOfFilesToCommit = [[myDocument theFSViewer] filterPaths:paths byBitfield:eHGStatusChangedInSomeWay];
	
	[commitFilesTableView resetTableDataWithPaths:absolutePathsOfFilesToCommit];
	
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
	if (theAction == @selector(commitSheetDiffAction:))			return [commitFilesTableView rowsAreSelected];
	return NO;
}


- (IBAction) validateButtons:(id)sender
{
	NSIndexSet* selectedIndexes = [commitFilesTableView selectedRowIndexes];
	BOOL pathsAreSelected = [selectedIndexes count] > 0;
	//BOOL pathsCanBeExcluded = pathsAreSelected && ![excludedItems containsIndexes:selectedIndexes] && ![myDocument inMergeState];
	//BOOL pathsCanBeIncluded = pathsAreSelected && [excludedItems intersectsIndexes:selectedIndexes];
	BOOL canAllowAmend = AllowHistoryEditingOfRepositoryFromDefaults() && [myDocument isCurrentRevisionTip] && ![myDocument inMergeState];
	NSInteger fileCount = [[commitFilesTableView commitDataArray] count];
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
		[qrefreshArgs addObjectsFromArray:[commitFilesTableView filteredFilesToCommit]];
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
	NSArray* commitData = [commitFilesTableView commitDataArray];
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
	NSArray* pathsToDiff = [commitFilesTableView rowsAreSelected] ? [commitFilesTableView chosenFilesToCommit] : [commitFilesTableView allFilesToCommit];
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitFileInfo
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation CommitFileInfo

@synthesize hgStatus;
@synthesize filePath;
@synthesize absoluteFilePath;
@synthesize fileImage;
@synthesize statusImage;
@synthesize lineCount;
@synthesize additionLineCount;
@synthesize removalLineCount;
@synthesize commitState;
@synthesize parent;

- (id) initWithStatusLine:(NSString*)statusLine withRoot:(NSString*)rootPath andParent:(CommitFilesTableView*)theParent
{
	self = [super init];
	if (!self || [statusLine length] < 3)
		return self;

	static NSImage* additionImage = nil;
	static NSImage* modifiedImage = nil;
	static NSImage* removedImage  = nil;
	NSSize theIconSize = NSMakeSize(ICON_SIZE, ICON_SIZE);
	if (!modifiedImage)
	{
		additionImage = [NSImage imageNamed:@"StatusAdded.png"];
		modifiedImage = [NSImage imageNamed:@"StatusModified.png"];
		removedImage  = [NSImage imageNamed:@"StatusRemoved.png"];
		[additionImage	setSize:theIconSize];
		[modifiedImage	setSize:theIconSize];
		[removedImage	setSize:theIconSize];
	}
	
	NSString* statusLetter = [statusLine substringToIndex:1];
	
	hgStatus		 = [FSNodeInfo statusEnumFromLetter:statusLetter];
	filePath		 = [statusLine substringFromIndex:2];
	absoluteFilePath = [rootPath stringByAppendingPathComponent:filePath];
	fileImage		 = [NSWorkspace iconImageOfSize:theIconSize forPath:absoluteFilePath withDefault:@"FSIconImage-Default"];
	commitState      = eCommitCheckStateOn;
	parent           = theParent;

	if (bitsInCommon(hgStatus, eHGStatusAdded))		statusImage = additionImage;
	if (bitsInCommon(hgStatus, eHGStatusRemoved))	statusImage = removedImage;
	if (bitsInCommon(hgStatus, eHGStatusModified))	statusImage = modifiedImage;
	
	return self;
}

- (IBAction) flipCheckBoxState:(id)sender
{
	switch (commitState)
	{
		case eCommitCheckStateOff:		commitState = eCommitCheckStatePartial;	break;
		case eCommitCheckStatePartial:	commitState = eCommitCheckStateOn;		break;
		case eCommitCheckStateOn:		commitState = eCommitCheckStateOff;		break;
	}
	NSInteger thisRow = [[parent commitDataArray] indexOfObject:self];
	[parent setNeedsDisplayInRect:[parent rectOfRow:thisRow]];
}


@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  CommitFilesTableView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation CommitFilesTableView

@synthesize commitDataArray;


- (void) awakeFromNib
{
	[self setDelegate:self];
	[self setDataSource:self];
	[self setTarget:self];
	[self setDoubleAction:@selector(handleFilesToCommitTableDoubleClick:)];
	//[self setAction:@selector(handleFilesToCommitTableClick:)];
}

- (void) resetTableDataWithPaths:(NSArray*)paths
{
	// Store the paths of the files to be committed
	NSArray* absolutePathsOfFilesToCommit = [[[parentController myDocument] theFSViewer] filterPaths:paths byBitfield:eHGStatusChangedInSomeWay];
	NSString* rootPath = [[parentController myDocument] absolutePathOfRepositoryRoot];

	// Initialize the table source data and show the files which are about to be changed in the commit sheet.
	NSMutableArray* argsStatus = [NSMutableArray arrayWithObjects:@"status", @"--modified", @"--added", @"--removed", nil];
	[argsStatus addObjectsFromArray: absolutePathsOfFilesToCommit];
	ExecutionResult* hgStatusResults = [TaskExecutions executeMercurialWithArgs:argsStatus  fromRoot:rootPath  logging:eLoggingNone];
	NSArray* statusLines = [hgStatusResults.outStr componentsSeparatedByString:@"\n"];
	
	NSMutableArray* newCommitDataArray = [[NSMutableArray alloc]init];
	for (NSString* statusLine in statusLines)
		if (IsNotEmpty(statusLine))
			[newCommitDataArray addObject:[[CommitFileInfo alloc] initWithStatusLine:statusLine withRoot:rootPath andParent:self]];
	
	commitDataArray = newCommitDataArray;
	[self reloadData];
}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Table Data Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [commitDataArray count];
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	CommitFileInfo*	commitFileInfo = [commitDataArray objectAtIndex:rowIndex];
	NSString* columnIdentifier = [aTableColumn identifier];
	if ([columnIdentifier isEqualToString:@"path"])
		return [commitFileInfo filePath];
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification*)aNotification
{
	[parentController validateButtons:self];
}

- (void) tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	NSString* columnIdentifier = [aTableColumn identifier];
	CommitFileInfo*	commitFileInfo = [commitDataArray objectAtIndex:rowIndex];
	if ([columnIdentifier isEqualToString:@"include"])
	{
		[aCell setCommitFileInfo:commitFileInfo];
		[aCell setTarget:commitFileInfo];
		[aCell setAction:@selector(flipCheckBoxState:)];
		[aCell setAllowsMixedState:YES];
		switch ([commitFileInfo commitState])
		{
			case eCommitCheckStateOff:		[aCell setState:NSOffState];	break;
			case eCommitCheckStatePartial:	[aCell setState:NSMixedState];	break;
			case eCommitCheckStateOn:		[aCell setState:NSOnState];		break;
		}
	}
	else if ([columnIdentifier isEqualToString:@"status"])
	{
		[aCell setCommitFileInfo:commitFileInfo];
		[aCell setImage:[commitFileInfo statusImage]];
	}
	else if ([columnIdentifier isEqualToString:@"icon"])
	{
		[aCell setCommitFileInfo:commitFileInfo];
		[aCell setImage:[commitFileInfo fileImage]];
	}
	
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Collection Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL)	 rowsAreSelected	{ return [self numberOfSelectedRows] > 0; }

- (NSArray*) filteredFilesToCommit
{
	return [self allFilesToCommit];
}

- (NSArray*) allFilesToCommit
{
	NSMutableArray* allFiles = [[NSMutableArray alloc]init];
	for (CommitFileInfo* cfiItem  in commitDataArray)
		[allFiles addObject:[cfiItem absoluteFilePath]];
	return allFiles;
}

- (NSString*) chosenFileToCommit
{
	CommitFileInfo* cfiItem = [commitDataArray objectAtIndex:[self chosenRow]];
	return [cfiItem absoluteFilePath];
}

- (NSArray*) selectedFilesToCommit
{
	NSMutableArray* selectedCommitFiles = [[NSMutableArray alloc]init];
	NSIndexSet* rows = [self selectedRowIndexes];
	[rows enumerateIndexesUsingBlock:^(NSUInteger row, BOOL* stop) {
		CommitFileInfo* cfiItem = [commitDataArray objectAtIndex:row];
		[selectedCommitFiles addObject:[cfiItem absoluteFilePath]];
	}];
	return selectedCommitFiles;
}

- (NSArray*) chosenFilesToCommit
{
	if (![self rowWasClicked] || [[self selectedRowIndexes] containsIndex:[self clickedRow]])
		return [self selectedFilesToCommit];
	return [NSArray arrayWithObject:[self chosenFileToCommit]];
}


- (IBAction) handleFilesToCommitTableDoubleClick:(id)sender
{
	NSArray* chosenFiles = [self chosenFilesToCommit];
	[[parentController myDocument] viewDifferencesInCurrentRevisionFor:chosenFiles toRevision:nil];	// no revision means don't include the --rev option
	[parentController makeMessageFieldFirstResponder];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

//- (NSImage*) iconImageOfSize:(NSSize)size
//{    
//	NSString* path = [self absolutePath];
//	NSString* defaultImageName = [self isDirectory] ? NSImageNameFolder : @"FSIconImage-Default";
//	return [NSWorkspace iconImageOfSize:size forPath:path withDefault:defaultImageName];
//}


@end


@implementation CommitFilesTableButtonCell
@synthesize commitFileInfo;
@end

@implementation CommitFilesTableImageCell
@synthesize commitFileInfo;
@end

@implementation CommitFilesTableTextCell
@synthesize commitFileInfo;

- (NSRect)drawingRectForBounds:(NSRect)theRect
{	
	NSRect newRect  = [super drawingRectForBounds:theRect];		// Get the parent's idea of where we should draw
	NSSize textSize = [self cellSizeForBounds:theRect];			// Get our ideal size for current text
	
	// Center that in the proposed rect
	float heightDelta = newRect.size.height - textSize.height;
	if (heightDelta > 0)
	{
		newRect.size.height -= heightDelta;
		newRect.origin.y += (heightDelta / 2);
	}
	return newRect;
}

@end