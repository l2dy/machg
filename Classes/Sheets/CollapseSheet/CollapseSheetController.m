//
//  CollapseSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "CollapseSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"
#import "HistoryViewController.h"
#import "Sidebar.h"
#import "SidebarNode.h"

@interface CollapseSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation CollapseSheetController
@synthesize myDocument = myDocument_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (CollapseSheetController*) initCollapseSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"CollapseSheet"];
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
	[theCollapseSheet makeFirstResponder:logTableView];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// ------------------------------------------------------------------------------------

static BOOL RevOutside(NSInteger num, NSInteger low, NSInteger high) { return num < low || high < num; }

// Look for a reason to disallow the given collapse before sending it off to 'hg collapse' it's better that we can detect these
// cases rather than having the collapse tool bail.
- (NSString*) reasonForInvalidityOfSelectedEntries
{
	NSArray* entries = logTableView.selectedEntries;

	if (entries.count < 1)
		return @"Unable to perform collapse because no revisions are selected to collapse. Select two or more consecutive revisions to collapse.";

	if (entries.count < 2)
		return @"Unable to perform collapse because a single revision is selected. Select two or more consecutive revisions to collapse.";
	
	LowHighPair pair = logTableView.lowestToHighestSelectedRevisions;
	NSInteger low  = pair.lowRevision;
	NSInteger high = pair.highRevision;
	
	for (LogEntry* entry in entries)
	{
		NSInteger entryIntRev = [entry revisionInt];

		if (RevOutside(entryIntRev, low, high))
			return fstr(@"Unable to perform collapse because the revision %@ lies outside the range %ld to %ld.", entry.revision, low, high);

		NSArray* parentsOfRev  = entry.parentsOfEntry;
		NSArray* childrenOfRev = entry.childrenOfEntry;
		if (entryIntRev != low)
			for (NSNumber* parent in parentsOfRev)
				if (RevOutside(numberAsInt(parent), low, high) && RevOutside(numberAsInt(parent), entryIntRev - 1, entryIntRev + 1))
					return fstr(@"Unable to perform collapse because one of the selected revisions, %@, has a parent revision %d which lies outside the selected range of revisions %ld to %ld. All revisions to collapse must have their parents contained in the selected range of revisions.", entry.revision, numberAsInt(parent), low, high);
		if (entryIntRev != high)
			for (NSNumber* child in childrenOfRev)
				if (RevOutside(numberAsInt(child), low, high) && RevOutside(numberAsInt(child), entryIntRev - 1, entryIntRev + 1))
					return fstr(@"Unable to perform collapse because one of the selected revisions, %@, has a child %d which lies outside the selected revisions %ld to %ld. All revisions to collapse (except the last) must have their children contained in the selected range of revisions.", entry.revision, numberAsInt(child), low, high);
	}
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
// MARK: Actions Log Inspector
// ------------------------------------------------------------------------------------

- (IBAction) openCollapseSheetWithSelectedRevisions:(id)sender
{
	
	if ([myDocument_ repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		RunAlertPanel(@"Outstanding Changes", @"Collapsing is only allowed in repositories with no outstanding uncommitted changes.", @"OK", nil, nil);
		return;
	}	
	
	NSString* newTitle = fstr(@"Collapsing Selected Revisions in ???%@???", myDocument_.selectedRepositoryShortName);
	collapseSheetTitle.stringValue = newTitle;
	
	// Report the branch we are about to collapse on in the dialog
	NSString* newSheetMessage = fstr(@"The following files will be collapsed to the versions as of the revision selected below (%@)", logTableView.selectedRevision);
	sheetInformativeMessageTextField.stringValue =  newSheetMessage;
	
	[logTableView resetTable:self];
	
	NSArray* revs = [myDocument_.theHistoryView.logTableView chosenRevisions];
	if (revs.count <= 0)
		[logTableView selectAndScrollToRevision:myDocument_.getHGTipRevision];
	else
	{
		NSInteger minRev = numberAsInt(revs[0]);
		NSInteger maxRev = numberAsInt(revs[0]);
		for (NSNumber* revision in revs)
		{
			NSInteger revInt = numberAsInt(revision);
			minRev = MIN(revInt, minRev);
			maxRev = MAX(revInt, maxRev);
		}
		NSInteger minTableRow = [logTableView tableRowForIntegerRevision:minRev];
		NSInteger maxTableRow = [logTableView tableRowForIntegerRevision:maxRev];
		NSIndexSet* firstLastIndexSet = [NSIndexSet indexSetWithIndexesInRange:MakeRangeFirstLast(minTableRow, maxTableRow)];
		[logTableView selectAndScrollToIndexSet:firstLastIndexSet];
	}
	
	[self validateButtons:self];
	self.window = theCollapseSheet;
	[myDocument_ beginSheet:theCollapseSheet];
}


- (IBAction) sheetButtonOkForCollapseSheet:(id)sender
{
	[myDocument_ endSheet:theCollapseSheet];
	[self openCollapseSheetWithCombinedCommitMessage:self];
}

- (IBAction) sheetButtonCancelForCollapseSheet:(id)sender
{
	[myDocument_ endSheet:theCollapseSheet];
}


- (IBAction) openCollapseSheetWithCombinedCommitMessage:(id)sender
{
	NSArray* entries = logTableView.selectedEntries;
	NSMutableString* combinedMessage = [[NSMutableString alloc] init];
	for (LogEntry* entry in entries)
		[combinedMessage appendFormat:@"%@\n", entry.fullComment];

	[combinedCommitMessage.textStorage setAttributedString:normalSheetMessageAttributedString(combinedMessage)];
	[theCollapseConfirmationSheet makeFirstResponder:combinedCommitMessage];

	sheetConfirmationInformativeMessageTextField.attributedStringValue = sheetInformativeMessageTextField.attributedStringValue;
	self.window = theCollapseConfirmationSheet;
	[myDocument_ beginSheet:theCollapseConfirmationSheet];
	[[sheetConfirmationInformativeMessageTextField.enclosingScrollView contentView] scrollToPoint:NSMakePoint(0,0)];
}

- (IBAction) sheetButtonOkForCollapseConfirmationSheet:(id)sender
{
	[theCollapseConfirmationSheet makeFirstResponder:theCollapseConfirmationSheet];	// Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:theCollapseConfirmationSheet];

	NSString* rootPath = myDocument_.absolutePathOfRepositoryRoot;
	NSString* repositoryName = [myDocument_.sidebar.selectedNode shortName];
	LowHighPair pair = logTableView.lowestToHighestSelectedRevisions;
	NSString* collapseDescription = fstr(@"Collapsing %ld-%ld in ???%@???", pair.lowRevision, pair.highRevision, repositoryName);
	NSMutableArray* argsCollapse  = [NSMutableArray arrayWithObjects:@"collapse",  @"--config", @"extensions.hgext.collapse=", nil];

	NSString* revisionNumbers = fstr(@"%ld:%ld", pair.lowRevision, pair.highRevision);
	[argsCollapse addObject:@"--rev" followedBy:revisionNumbers];
	[argsCollapse addObject:@"--force"];
	[argsCollapse addObject:@"--message" followedBy:combinedCommitMessage.string];

	[myDocument_ dispatchToMercurialQueuedWithDescription:collapseDescription  process:^{
		[myDocument_ delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:argsCollapse  fromRoot:rootPath];
			NSNumber* collapsedRevision = intAsNumber(pair.lowRevision);
			[[myDocument_.theHistoryView logTableView] selectAndScrollToRevision:collapsedRevision];
		}];			
	}];	
}
- (IBAction) sheetButtonCancelForCollapseConfirmationSheet:(id)sender
{
	[myDocument_ endSheet:theCollapseConfirmationSheet];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	NSWindow* shownSheet = myDocument_.shownSheet;
	if (shownSheet && (shownSheet == theCollapseSheet || shownSheet == theCollapseConfirmationSheet))
		[myDocument_ endSheet:shownSheet];
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
	NSRange range = MakeRangeFirstLast(proposedSelectionIndexes.firstIndex, proposedSelectionIndexes.lastIndex);
	return [NSIndexSet indexSetWithIndexesInRange:range];
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
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be removed and combined into a single revision which will be inserted in place of the selected range of revisions. This collapse operation is destructive; it rewrites history. Therefore you should never collapse any revisions that have already been pushed to other repositories, unless you really know what you are doing.")];
	return newSheetMessage;
}


@end
