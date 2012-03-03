//
//  AlterDetailsSheetController.m
//  MacHg
//
//  Created by Jason Harris on 18/02/12.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "AlterDetailsSheetController.h"
#import "MacHgDocument.h"
#import "FSNodeInfo.h"
#import "TaskExecutions.h"
#import "DisclosureBoxController.h"
#import "LogEntry.h"
#import "HistoryViewController.h"


@interface AlterDetailsSheetController (PrivateAPI)
- (NSAttributedString*) formattedChooseChangesetSheetMessage;
- (NSAttributedString*) formattedAlterDetailsSheetMessage;
@end


@implementation AlterDetailsSheetController
@synthesize myDocument;
@synthesize commitMessage = commitMessage_;
@synthesize committer = committer_;
@synthesize commitDate = commitDate_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (AlterDetailsSheetController*) initAlterDetailsSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"AlterDetailsSheet" owner:self];
	return self;
}


- (void) awakeFromNib
{
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Validation
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) validateChooseChangesetButtons:(id)sender
{
	// We only allow the selection of a single revision
	if ([logTableView multipleRevisionsSelected])
		[logTableView selectAndScrollToRevision:[logTableView chosenRevision]];

	entryToAlter_ = [logTableView chosenEntry];
	if (!entryToAlter_)
	{
		[chooseChangesetInformativeMessageTextField setStringValue:@"No Revision Selected. You need to select a revision to edit"];
		[chooseChangesetButton setEnabled:NO];
		return;
	}
	
	[entryToAlter_ fullyLoadEntry];
	
	
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSString* editRevision = [entryToAlter_ revisionStr];
	NSString* revPattern = fstr(@"heads(descendants(rev(%@))) or (merge() and descendants(rev(%@)))", editRevision, editRevision);
	NSMutableArray* argsLog = [NSMutableArray arrayWithObjects:@"log", @"--limit", @"10", @"--template", @"{rev},", @"--rev", revPattern, nil];
	ExecutionResult* hgLogResults = [TaskExecutions executeMercurialWithArgs:argsLog  fromRoot:rootPath  logging:eLoggingNone];
	if ([hgLogResults hasErrors])
	{
		[chooseChangesetInformativeMessageTextField setStringValue:fstr(@"Problematic Revision. MacHg encountered an error when trying to determine information about the children of revision %@",editRevision)];
		[chooseChangesetButton setEnabled:NO];
		return;
	}

	NSArray* descdentHeadsAndMerges = [hgLogResults.outStr componentsSeparatedByString:@","];
	NSInteger count = [descdentHeadsAndMerges count];
	if (IsEmpty([descdentHeadsAndMerges lastObject]))
		count--;
	if (count > 1)
	{
		[chooseChangesetInformativeMessageTextField setStringValue:fstr(@"Not a Linear Descendant. MacHg can only edit linear descendants of a single head. That is, there can be no merges or forks in the revision tree between revision %@ and it's head.", editRevision)];
		[chooseChangesetButton setEnabled:NO];
		return;
	}

	[chooseChangesetInformativeMessageTextField setAttributedStringValue: [self formattedChooseChangesetSheetMessage]];
	[chooseChangesetButton setEnabled:YES];
	return;	
}

- (IBAction) validateAlterDetailsButtons:(id)sender
{
	
	NSString* theMessage = [alterDetailsCommitMessageTextView string];
	BOOL fieldsAreValid = IsNotEmpty(theMessage) && IsNotEmpty(committer_) && IsNotEmpty(commitDate_);
	
	BOOL messageIsNew = IsNotEmpty(theMessage) && [theMessage isNotEqualToString:[entryToAlter_ fullComment]];
	BOOL committerIsNew = IsNotEmpty(committer_) && [committer_ isNotEqualToString:[entryToAlter_ fullAuthor]];
	BOOL dateIsNew = IsNotEmpty(commitDate_) && [commitDate_ isNotEqualTo:[entryToAlter_ rawDate]];

	NSColor* alteredColor = [NSColor colorWithCalibratedRed:1.0 green:0.9 blue:0.9 alpha:1.0];
	NSColor* messageBackground   = messageIsNew   ? alteredColor : [NSColor whiteColor];
	NSColor* committerBackground = committerIsNew ? alteredColor : [NSColor whiteColor];
	NSColor* dateBackground      = dateIsNew      ? alteredColor : [NSColor whiteColor];
	[alterDetailsCommitMessageTextView setBackgroundColor:messageBackground];
	[alterDetailsCommitterTextField    setBackgroundColor:committerBackground];
	[alterDetailsCommitterTextField    setDrawsBackground:YES];
	[alterDetailsDatePicker            setBackgroundColor:dateBackground];

	if (!fieldsAreValid)
	{
		NSString* fieldMessage = nil;
			if (IsEmpty(theMessage))   fieldMessage = @"Unable to proceed. The commit message is empty. All fields must be non-empty";
		else if (IsEmpty(committer_))  fieldMessage = @"Unable to proceed. The committer is empty. All fields must be non-empty";
		else if (IsEmpty(commitDate_)) fieldMessage = @"Unable to proceed. The commit date is empty. All fields must be non-empty";
		[alterDetailsInformativeMessageTextField setStringValue:fieldMessage];
		[alterDetailsButton setEnabled:NO];
		return;
	}
	
	if (!messageIsNew && !committerIsNew && !dateIsNew)
	{
		[alterDetailsInformativeMessageTextField setStringValue:@"One of the fields must be changed in order to alter the changeset details."];
		[alterDetailsButton setEnabled:NO];
		return;
	}
		
	[alterDetailsInformativeMessageTextField setAttributedStringValue:[self formattedAlterDetailsSheetMessage]];
	[alterDetailsButton setEnabled:YES];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) closeChooseChangesetSheet:(id)sender
{
	[myDocument endSheet:theChooseChangesetSheet];
}

- (IBAction) closeAlterDetailsSheet:(id)sender
{
	[myDocument endSheet:theAlterDetailsSheet];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	NSWindow* shownSheet = [myDocument shownSheet];
	if (shownSheet && (shownSheet == theChooseChangesetSheet || shownSheet == theAlterDetailsSheet))
		[myDocument endSheet:shownSheet];
}


- (IBAction) openAlterDetailsChooseChangesetSheet:(id)sender
{
	if ([myDocument repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		PlayBeep();
		NSRunAlertPanel(@"Outstanding Changes", @"There are outstanding uncommitted changes. Please commit or discard these changes and repeat the edit operation.", @"Ok", nil, nil);
		return;
	}
	
	@try
	{
		NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
		NSMutableArray*  qseriesArgs   = [NSMutableArray arrayWithObjects:@"qseries", @"--config", @"extensions.hgext.mq=", nil];
		ExecutionResult* qseriesResult = [TaskExecutions executeMercurialWithArgs:qseriesArgs fromRoot:rootPath logging:eLoggingNone];
		if ([qseriesResult hasErrors])
			[NSException raise:@"QSeries" format:@"The Alter Details operation could not proceed. The process of testing for the presence of a mercurial queue reported: %@.", [qseriesResult errStr], nil];
		if (IsNotEmpty([qseriesResult outStr]))
		{
			NSRunAlertPanel(@"Existing Mercurial Queue", @"An existing mercurial queue is present in the repository. Please finish the mercurial queue and retry.", @"Ok", nil, nil);
			return;
		}
	}
	@catch (NSException* e)
	{
		dispatch_async(mainQueue(), ^{
			NSRunCriticalAlertPanel(@"Aborted Altering Details", [e reason], @"OK", nil, nil);
		});
		return;
	}
	
	
	NSString* newTitle = fstr(@"Altering a Selected Revision in “%@”", [myDocument selectedRepositoryShortName]);
	[chooseChangesetSheetTitle setStringValue:newTitle];

	[logTableView resetTable:self];

	LogEntry* initialEntry = [[[myDocument theHistoryView] logTableView] chosenEntry];

	[logTableView selectAndScrollToRevision:[initialEntry revision]];
	[myDocument beginSheet:theChooseChangesetSheet];
	[self validateChooseChangesetButtons:self];
}

- (IBAction) openAlterDetailsSheet:(id)sender
{
	NSString* newTitle = fstr(@"Alter Details of Changeset “%@”", [entryToAlter_ revisionStr]);
	[alterDetailsSheetTitle setStringValue:newTitle];

	[alterDetailsCommitMessageTextView setSelectedRange:NSMakeRange(0, [[alterDetailsCommitMessageTextView string] length])];
	[alterDetailsCommitMessageTextView insertText:[entryToAlter_ fullComment]];
	
	[self setCommitter:[entryToAlter_ fullAuthor]];
	[self setCommitDate:[entryToAlter_ rawDate]];
	[theAlterDetailsSheet makeFirstResponder:alterDetailsCommitMessageTextView];

	[self validateAlterDetailsButtons:self];
	[myDocument beginSheet:theAlterDetailsSheet];
}


- (IBAction) sheetButtonChooseChangesetAlter:(id)sender
{
	[self closeChooseChangesetSheet:sender];
	[self openAlterDetailsSheet:sender];
}


- (IBAction) sheetButtonAlterDetailsAlter:(id)sender
{
	NSString* theMessage = [alterDetailsCommitMessageTextView string];
	
	BOOL messageIsNew = IsNotEmpty(theMessage) && [theMessage isNotEqualToString:[entryToAlter_ fullComment]];
	BOOL committerIsNew = IsNotEmpty(committer_) && [committer_ isNotEqualToString:[entryToAlter_ fullAuthor]];
	BOOL dateIsNew = IsNotEmpty(commitDate_) && [commitDate_ isNotEqualTo:[entryToAlter_ rawDate]];

	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSString* revString = fstr(@"%@:",[entryToAlter_ revisionStr]);

	[myDocument dispatchToMercurialQueuedWithDescription:fstr(@"Altering %@",[entryToAlter_ revisionStr]) process:^{
		[myDocument delayEventsUntilFinishBlock:^{
			@try
			{
				NSMutableArray*  qimportArgs   = [NSMutableArray arrayWithObjects:@"qimport", @"--config", @"extensions.hgext.mq=", @"--rev", revString, nil];
				ExecutionResult* qimportResult = [TaskExecutions executeMercurialWithArgs:qimportArgs fromRoot:rootPath logging:eLoggingNone];
				if ([qimportResult hasErrors])
					[NSException raise:@"QImporting" format:@"The Alter Details operation could not proceed. The process of importing the child changesets reported: %@.", [qimportResult errStr], nil];
				
				NSMutableArray*  qrenameArgs   = [NSMutableArray arrayWithObjects:@"qrename", @"--config", @"extensions.hgext.mq=", @"macHgAlterDetails", nil];
				ExecutionResult* qrenameResult = [TaskExecutions executeMercurialWithArgs:qrenameArgs fromRoot:rootPath logging:eLoggingNone];
				if ([qrenameResult hasErrors])
					[NSException raise:@"QRenaming" format:@"The Alter Details operation could not proceed. The process of renaming the top child changesets reported: %@.", [qrenameResult errStr], nil];
				
				NSMutableArray*  qpopArgs   = [NSMutableArray arrayWithObjects:@"qpop", @"--config", @"extensions.hgext.mq=", @"--all", nil];
				ExecutionResult* qpopResult = [TaskExecutions executeMercurialWithArgs:qpopArgs fromRoot:rootPath logging:eLoggingNone];
				if ([qpopResult hasErrors])
					[NSException raise:@"QPopping" format:@"The Alter Details operation could not proceed. The process of popping the child changesets reported: %@.", [qpopResult errStr], nil];

				NSMutableArray*  qpushArgs   = [NSMutableArray arrayWithObjects:@"qpush", @"--config", @"extensions.hgext.mq=", nil];
				ExecutionResult* qpushResult = [TaskExecutions executeMercurialWithArgs:qpushArgs fromRoot:rootPath logging:eLoggingNone];
				if ([qpushResult hasErrors])
					[NSException raise:@"QPushing" format:@"The Alter Details operation could not proceed. The process of pushing the target changesets reported: %@.", [qpopResult errStr], nil];
				
				NSMutableArray* qrefreshArgs = [NSMutableArray arrayWithObjects:@"qrefresh", @"--config", @"extensions.hgext.mq=", @"--short", nil];
				if (messageIsNew)
					[qrefreshArgs addObject:@"--message" followedBy:theMessage];
				if (committerIsNew)
					[qrefreshArgs addObject:@"--user" followedBy:committer_];
				if (dateIsNew)
					[qrefreshArgs addObject:@"--date" followedBy:[commitDate_ isodateDescription]];
				ExecutionResult* qrefreshResult = [TaskExecutions executeMercurialWithArgs:qrefreshArgs  fromRoot:rootPath logging:eLoggingNone];
				if ([qrefreshResult hasErrors])
					[NSException raise:@"Refreshing" format:@"The Alter Details could not proceed. The altering process reported the error: %@. Please back out any patch operations.", [qrefreshResult errStr], nil];
				
				NSMutableArray*  qpushAllArgs   = [NSMutableArray arrayWithObjects:@"qpush", @"--config", @"extensions.hgext.mq=", @"macHgAlterDetails", nil];
				ExecutionResult* qpushAllResult = [TaskExecutions executeMercurialWithArgs:qpushAllArgs fromRoot:rootPath logging:eLoggingNone];
				if ([qpushAllResult hasErrors])
					[NSException raise:@"QPushing" format:@"The Alter Details operation could not proceed. The process of re-pushing the child changesets reported: %@.", [qpushAllResult errStr], nil];
				
				// Do the queue finish
				NSMutableArray*  qfinishArgs   = [NSMutableArray arrayWithObjects:@"qfinish", @"--config", @"extensions.hgext.mq=", @"--applied", nil];
				ExecutionResult* qfinishResult = [TaskExecutions executeMercurialWithArgs:qfinishArgs fromRoot:rootPath logging:eLoggingNone];
				if ([qfinishResult hasErrors])
					[NSException raise:@"Finishing" format:@"The amend operation could not proceed. The patch finish process reported the error: %@. Please back out any patch operations.", [qfinishResult errStr], nil];
			}
			@catch (NSException* e)
			{
				dispatch_async(mainQueue(), ^{
					NSRunCriticalAlertPanel(@"Aborted Altering Details", [e reason], @"OK", nil, nil);
				});
				return;
			}
			
		}];
	}];
	
	[self closeAlterDetailsSheet:sender];
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[self validateChooseChangesetButtons:self];
}

- (NSIndexSet*) tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes
{
	return [NSIndexSet indexSetWithIndex:[proposedSelectionIndexes firstIndex]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) controlTextDidChange:(NSNotification*)aNotification
{
	[self validateAlterDetailsButtons:[aNotification object]];
}

- (void)textDidChange:(NSNotification*) aNotification
{
	[self validateAlterDetailsButtons:[aNotification object]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSAttributedString*) formattedChooseChangesetSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	NSString* rev = numberAsString([logTableView chosenRevision]);
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"You can proceed to alter the commit message, committer, and date of the revisions ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(rev)];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@".")];
	return newSheetMessage;
}

- (NSAttributedString*) formattedAlterDetailsSheetMessage
{
	NSString* theMessage = [alterDetailsCommitMessageTextView string];
	BOOL messageIsNew = IsNotEmpty(theMessage) && [theMessage isNotEqualToString:[entryToAlter_ fullComment]];
	BOOL committerIsNew = IsNotEmpty(committer_) && [committer_ isNotEqualToString:[entryToAlter_ fullAuthor]];
	BOOL dateIsNew = IsNotEmpty(commitDate_) && [commitDate_ isNotEqualTo:[entryToAlter_ rawDate]];
	
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	NSString* rev = numberAsString([logTableView chosenRevision]);
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The ")];
	if (messageIsNew)
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"commit message")];
	if (committerIsNew)
	{
		if (messageIsNew)
			[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@", ")];
		if (!dateIsNew)
			[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"and ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"committer")];
	}
	if (dateIsNew)
	{
		if (messageIsNew || committerIsNew)
			[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@", and ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"date")];
	}
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" of revision ")];	
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(rev)];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be altered.")];
	return newSheetMessage;
}


@end
