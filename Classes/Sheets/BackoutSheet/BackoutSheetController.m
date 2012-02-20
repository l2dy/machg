//
//  BackoutSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "BackoutSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"


@interface BackoutSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation BackoutSheetController

@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BackoutSheetController*) initBackoutSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"BackoutSheet" owner:self];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[inspectorSplitView setPosition:200 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theBackoutSheet makeFirstResponder:logTableView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) validate:(id)sender
{
	BOOL valid = [logTableView singleRevisionSelected];
	[okButton setEnabled:valid];
	[sheetInformativeMessageTextField setAttributedStringValue: (valid ? [self formattedSheetMessage] : normalSheetMessageAttributedString(@"You need to select a single revision in order to backout."))];
}


- (void) openBackoutSheetWithRevision:(NSNumber*)revision
{
	NSString* newTitle = fstr(@"Backout Selected Changeset in %@", [myDocument selectedRepositoryShortName]);
	[backoutSheetTitle setStringValue:newTitle];

	// Report the branch we are about to backout to in the dialog
	[sheetInformativeMessageTextField setStringValue:@""];

	
	[logTableView resetTable:self];
	[myDocument beginSheet:theBackoutSheet];
	[logTableView selectAndScrollToRevision:revision];
	[self validate:self];
}


- (IBAction) openBackoutSheetWithSelectedRevision:(id)sender
{
	NSArray* revs = [[[myDocument theHistoryView] logTableView] chosenRevisions];
	if ([revs count] > 0)
	{
		NSInteger minRev = numberAsInt([revs objectAtIndex:0]);
		NSInteger maxRev = numberAsInt([revs objectAtIndex:0]);
		for (NSNumber* revision in revs)
		{
			NSInteger revInt = numberAsInt(revision);
			minRev = MIN(revInt, minRev);
			maxRev = MAX(revInt, maxRev);
		}
		[self openBackoutSheetWithRevision:intAsNumber(minRev)];
	}
	else
		[self openBackoutSheetWithRevision:[myDocument getHGParent1Revision]];
}


- (IBAction) sheetButtonOk:(id)sender
{
	NSNumber* versionToBackoutTo = [logTableView selectedRevision];
	BOOL didReversion = [myDocument primaryActionBackoutFilesToVersion:versionToBackoutTo];
	if (!didReversion)
		return;

	[myDocument endSheet:theBackoutSheet];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[myDocument endSheet:theBackoutSheet];
}


- (IBAction) sheetButtonViewDifferencesForBackoutSheet:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	NSNumber* versionToBackoutTo = [logTableView selectedRevision];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:numberAsString(versionToBackoutTo)];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[self validate:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	BOOL outstandingChanges = [myDocument repositoryHasFilesWhichContainStatus:eHGStatusChangedInSomeWay];

	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	
	if (outstandingChanges)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"There are outstanding ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"uncommitted")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" modifications to the files in the repository. ")];
		return newSheetMessage;
	}
		
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The changeset ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(numberAsString([logTableView selectedRevision]))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be backed out (reversed).")];
		
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" The backout will be transplanted directly on top of the current parent ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(numberAsString([myDocument getHGParent1Revision]))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@".")];

	return newSheetMessage;
}


@end

