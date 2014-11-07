//
//  RebaseSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "RebaseSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"
#import "HistoryViewController.h"
#import "AppController.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "ProcessListController.h"


@interface RebaseSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation RebaseSheetController
@synthesize myDocument = myDocument_;
@synthesize keepOriginalRevisions = keepOriginalRevisions_;
@synthesize keepOriginalBranchNames = keepOriginalBranchNames_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (RebaseSheetController*) initRebaseSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"RebaseSheet"];
	[self window];	// force / ensure the nib is loaded
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[sourceSV		setPosition:350 ofDividerAtIndex: 0];
	[destinationSV	setPosition:350 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theRebaseSheet makeFirstResponder:sourceLogTableView];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// ------------------------------------------------------------------------------------

- (NSIndexSet*) indexSetForStartingRevision:(NSNumber*)rev
{
	NSSet* descendants = [[myDocument_ repositoryData] descendantsOfRevisionNumber:rev];
	NSMutableIndexSet* newIndexes = [[NSMutableIndexSet alloc]init];
	for (NSNumber* revNum in descendants)
		[newIndexes addIndex:[sourceLogTableView tableRowForRevision:revNum]];
	return newIndexes;
}

- (NSString*) reasonForInvalidityOfSelectedEntries
{
	NSArray* sourceEntries = [sourceLogTableView selectedEntries];
	
	if ([sourceEntries count] < 1)
		return @"Unable to perform rebase because no revisions are selected to rebase. Select a tree of revisions to rebase.";

	NSArray* destinationEntries = [destinationLogTableView selectedEntries];
	
	if ([destinationEntries count] < 1)
		return @"Unable to perform rebase because no revisions are selected to rebase onto. Select a single revision as the target of the rebase.";

	return nil;
}

- (IBAction) validateButtons:(id)sender
{
	NSString* reasonForNonValid = [self reasonForInvalidityOfSelectedEntries];
	if (!reasonForNonValid)
		[okButton setEnabled:YES];
	else
	{
		[okButton setEnabled:NO];
		[sheetInformativeMessageTextField setStringValue: reasonForNonValid];
	}
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Handle Interrupted Rebase
// ------------------------------------------------------------------------------------

- (void) doContinueOrAbort
{
	NSInteger result = RunCriticalAlertPanel(@"Rebase in Progress", @"A rebase operation is in progress, continue with the operation or abort the operation", @"Continue", @"Abort", @"Cancel");
	
	// If we are canceling the operation we are done.
	if (result == NSAlertOtherReturn)
		return;
	
	NSMutableArray* argsRebase = [NSMutableArray arrayWithObjects:@"rebase", nil];
	
	BOOL abort = (result == NSAlertAlternateReturn);
	[argsRebase addObject: abort ? @"--abort" : @"--continue"];
	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];
	ExecutionResult* results = [myDocument_  executeMercurialWithArgs:argsRebase  fromRoot:rootPath  whileDelayingEvents:YES];
	if (results.outStr)
	{
		NSString* operation = (abort ? @"Abort" :  @"Continue");
		NSString* titleMessage = fstr(@"Results of Rebase %@",operation);
		NSString* message = fstr(@"Mercurial reported the result of the rebase %@:\n\ncode %d:\n%@", operation, results.result, results.outStr);
		RunAlertPanel(titleMessage, message, @"OK", nil, nil);
	}
	if (abort)
		[[myDocument_ repositoryData] deleteRebaseState];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// ------------------------------------------------------------------------------------

- (IBAction) openRebaseSheetWithSelectedRevisions:(id)sender
{
	if ([[myDocument_ repositoryData] rebaseInProgress])
	{
		[self doContinueOrAbort];
		return;
	}

	if ([myDocument_ repositoryHasFilesWhichContainStatus:eHGStatusCommittable])
	{
		RunAlertPanel(@"Outstanding Changes", @"Rebasing is only allowed in repositories with no outstanding uncommitted changes.", @"OK", nil, nil);
		return;
	}	
	
	// Retarget a single click to select that entry and all descendants.
	[sourceLogTableView setAction:@selector(handleLogTableViewClick:)];
	[sourceLogTableView setTarget:self];
	
	//
	// Initialize Source LogTableView
	//
	[sourceLogTableView resetTable:self];
	NSArray* revs = [[[myDocument_ theHistoryView] logTableView] chosenRevisions];
	if ([revs count] <= 0)
		[sourceLogTableView scrollToRevision:[myDocument_ getHGTipRevision]];
	else
	{
		NSInteger minRev = numberAsInt(revs[0]);
		for (NSNumber* revision in revs)
		{
			NSInteger revInt = numberAsInt(revision);
			minRev = MIN(revInt, minRev);
		}
		NSIndexSet* newIndexes = [self indexSetForStartingRevision:intAsNumber(minRev)];
		[sourceLogTableView selectAndScrollToIndexSet:newIndexes];
	}

	//
	// Initialize Destination LogTableView
	//
	[destinationLogTableView resetTable:self];
	[destinationLogTableView scrollToRevision:[myDocument_ getHGTipRevision]];
	[destinationLogTableView deselectAll:self];

	// Set Sheet Title
	NSString* newTitle = fstr(@"Rebasing Selected Revisions in “%@”", [myDocument_ selectedRepositoryShortName]);
	[rebaseSheetTitle setStringValue:newTitle];

	[self setKeepOriginalRevisions:NO];
	[self setKeepOriginalBranchNames:NO];
	
	[self validateButtons:self];
	if ([okButton isEnabled])
		[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
	
	[myDocument_ beginSheet:theRebaseSheet];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[myDocument_ endSheet:theRebaseSheet];

	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];
	NSString* repositoryName = [[[myDocument_ sidebar] selectedNode] shortName];
	LowHighPair pair = [sourceLogTableView lowestToHighestSelectedRevisions];
	NSNumber* destinationRev = [destinationLogTableView selectedRevision];
	NSString* rebaseDescription = fstr(@"rebasing %ld-%ld in “%@”", pair.lowRevision, pair.highRevision, repositoryName);
	NSMutableArray* argsRebase = [NSMutableArray arrayWithObjects:@"rebase", @"--config", @"extensions.hgext.rebase=", nil];	// We are using MacHgs rebase command so we need to specify that it is
																														// in the extensions folder of the included Mercurial
	[argsRebase addObjectsFromArray:configurationForProgress];
	NSString* mergeToolName = [[AppController sharedAppController] scriptNameForMergeTool:UseWhichToolForMergingFromDefaults()];
	[argsRebase addObject:@"--config" followedBy:fstr(@"merge-tools.%@.priority=100", mergeToolName)];	// Unfortunately rebase doesn't take a --tool option yet
	[argsRebase addObject:@"--detach"];
	[argsRebase addObject:@"--source" followedBy:intAsString(pair.lowRevision)];
	[argsRebase addObject:@"--dest" followedBy:numberAsString(destinationRev)];
	if ([self keepOriginalRevisions])
		[argsRebase addObject:@"--keep"];
	if ([self keepOriginalBranchNames])
		[argsRebase addObject:@"--keepbranches"];

	ProcessController* processController = [ProcessController processControllerWithMessage:rebaseDescription forList:[myDocument_ theProcessListController]];
	dispatch_async([myDocument_ mercurialTaskSerialQueue], ^{
		[myDocument_ executeMercurialWithArgs:argsRebase  fromRoot:rootPath  withDelegate:processController  whileDelayingEvents:YES];
		[processController terminateController];
	});		
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[myDocument_ endSheet:theRebaseSheet];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// ------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[self validateButtons:self];
	if ([okButton isEnabled])
		[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
}


- (NSIndexSet*) tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes
{
	NSRange range = MakeRangeFirstLast([proposedSelectionIndexes firstIndex], [proposedSelectionIndexes lastIndex]);
	return [NSIndexSet indexSetWithIndexesInRange:range];
}


- (IBAction) handleLogTableViewClick:(id)sender
{
	NSIndexSet* newIndexes = [self indexSetForStartingRevision:[sourceLogTableView chosenRevision]];
	[sourceLogTableView selectRowIndexes:newIndexes byExtendingSelection:NO];
}


- (CGFloat) firstPaneHeight:(NSSplitView*)theSplitView
{
	return [[theSplitView subviews][0] frame].size.height;
}


- (void) splitViewDidResizeSubviews:(NSNotification*)aNotification
{
	CGFloat svOnePosition = [self firstPaneHeight:sourceSV];
	CGFloat svTwoPosition = [self firstPaneHeight:destinationSV ];
	
	if ([aNotification object] == sourceSV)
		if (svOnePosition != svTwoPosition)
			[destinationSV setPosition:svOnePosition ofDividerAtIndex:0];
	
	if ([aNotification object] == destinationSV)
		if (svOnePosition != svTwoPosition)
			[sourceSV setPosition:svTwoPosition ofDividerAtIndex:0];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// ------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	LowHighPair sourcePair = [sourceLogTableView lowestToHighestSelectedRevisions];
	NSNumber* destinationRev = [destinationLogTableView selectedRevision];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The selected revisions within ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(sourcePair.lowRevision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" through to ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(sourcePair.highRevision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be rebased onto the revision ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(numberAsString(destinationRev))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@". This rebase operation is destructive; it rewrites history. Therefore you should never rebase any revisions that have already been pushed to other repositories, unless you really know what you are doing.")];
	return newSheetMessage;
}


@end


// MARK: -

@implementation ClippedStandardSplitView

- (void) awakeFromNib
{
	[self setDelegate:self];
}

- (CGFloat)splitView:(NSSplitView*)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex	{ return self.frame.size.width-200.0; }
- (CGFloat)splitView:(NSSplitView*)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex	{ return 200.0; }
- (CGFloat)splitView:(NSSplitView*)splitView constrainSplitPosition:(CGFloat)proposedPosition		 ofSubviewAt:(NSInteger)dividerIndex	{ return constrainFloat(proposedPosition, 200.0, self.frame.size.width-200.0); }

- (void) drawDividerInRect:(NSRect)aRect
{
	NSRect slice;
	NSRect clippedRect;
	NSDivideRect(aRect, &slice, &clippedRect, 20, NSMinYEdge);
	[super drawDividerInRect:clippedRect];
}

@end


