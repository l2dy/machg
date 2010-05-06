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


- (void) openUpdateSheetWithRevision:(NSString*)revision
{
	NSString* newTitle = [NSString stringWithFormat:@"Updating All Files in %@", [myDocument selectedRepositoryShortName]];
	[updateSheetTitle setStringValue:newTitle];
	[self setCleanUpdate:NO];

	// Report the branch we are about to update to in the dialog
	[sheetInformativeMessageTextField setStringValue:@""];
	
	[logTableView resetTable:self];
	[NSApp beginSheet:theUpdateSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[logTableView scrollToRevision:revision];
	[self validate:self];
}


- (IBAction) openUpdateSheetWithCurrentRevision:(id)sender
{
	[self openUpdateSheetWithRevision:[myDocument getHGParent1Revision]];
}


- (IBAction) sheetButtonOkForUpdateSheet:(id)sender
{
	NSString* versionToUpdateTo = [logTableView selectedRevision];
	BOOL didReversion = [myDocument primaryActionUpdateFilesToVersion:versionToUpdateTo withCleanOption:[self cleanUpdate]];
	if (!didReversion)
		return;

	[NSApp endSheet:theUpdateSheet];
	[theUpdateSheet orderOut:sender];
}

- (IBAction) sheetButtonCancelForUpdateSheet:(id)sender
{
	[NSApp endSheet:theUpdateSheet];
	[theUpdateSheet orderOut:sender];
}


- (IBAction) sheetButtonViewDifferencesForUpdateSheet:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	NSString* versionToUpdateTo = [logTableView selectedRevision];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:versionToUpdateTo];
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
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The repository will be restored to the state of version ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString([logTableView selectedRevision])];
	if ([self cleanUpdate])
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@". Any modified files will be ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"overwritten")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@".")];
	}else
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@". Any modified files will be moved aside.")];
	return newSheetMessage;
}


@end

