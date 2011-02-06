//
//  UpdateSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "UpdateSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"


@interface UpdateSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation UpdateSheetController

@synthesize cleanUpdate = cleanUpdate_;
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (UpdateSheetController*) initUpdateSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"UpdateSheet" owner:self];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[inspectorSplitView setPosition:200 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theUpdateSheet makeFirstResponder:logTableView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) validate:(id)sender
{
	BOOL valid = [logTableView singleRevisionSelected];
	[okButton setEnabled:valid];
	[sheetInformativeMessageTextField setAttributedStringValue: (valid ? [self formattedSheetMessage] : normalSheetMessageAttributedString(@"You need to select a single revision in order to update."))];
}


- (void) openUpdateSheetWithRevision:(NSNumber*)revision
{
	NSString* newTitle = fstr(@"Updating All Files in %@", [myDocument selectedRepositoryShortName]);
	[updateSheetTitle setStringValue:newTitle];
	[self setCleanUpdate:NO];

	// Report the branch we are about to update to in the dialog
	[sheetInformativeMessageTextField setStringValue:@""];
	
	[logTableView resetTable:self];
	[NSApp beginSheet:theUpdateSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[logTableView scrollToRevision:revision ? revision : [myDocument getHGParent1Revision]];
	[self validate:self];
}


- (IBAction) openUpdateSheetWithCurrentRevision:(id)sender
{
	[self openUpdateSheetWithRevision:[myDocument getHGParent1Revision]];
}


- (IBAction) openUpdateSheetWithSelectedRevision:(id)sender
{
	[self openUpdateSheetWithRevision:[myDocument getSelectedRevision]];
}


- (IBAction) sheetButtonOk:(id)sender
{
	NSNumber* versionToUpdateTo = [logTableView selectedRevision];
	BOOL didReversion = [myDocument primaryActionUpdateFilesToVersion:versionToUpdateTo withCleanOption:[self cleanUpdate]];
	if (!didReversion)
		return;

	[NSApp endSheet:theUpdateSheet];
	[theUpdateSheet orderOut:sender];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[NSApp endSheet:theUpdateSheet];
	[theUpdateSheet orderOut:sender];
}


- (IBAction) sheetButtonViewDifferencesForUpdateSheet:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	NSNumber* versionToUpdateTo = [logTableView selectedRevision];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:numberAsString(versionToUpdateTo)];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable;
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
	}
		
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The repository will be restored to the state of version ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(numberAsString([logTableView selectedRevision]))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@".")];
	
	if (!outstandingChanges)
		return newSheetMessage;
	
	if ([self cleanUpdate])
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" The modified files will be ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"overwritten")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@".")];
	}
	else
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" The modifications to the files will be transplanted to the new version ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(numberAsString([logTableView selectedRevision]))];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@".")];
	}
	return newSheetMessage;
}


@end

