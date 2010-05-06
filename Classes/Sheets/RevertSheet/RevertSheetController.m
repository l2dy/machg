//
//  RevertSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "RevertSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"

@implementation RevertSheetController
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (RevertSheetController*) initRevertSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"RevertSheet" owner:self];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[inspectorSplitView setPosition:200 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theRevertSheet makeFirstResponder:logTableView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) openRevertSheetWithPaths:(NSArray*)paths andRevision:(NSString*)revision
{
	// Report the branch we are about to revert on in the dialog
	NSString* newSheetMessage = [NSString stringWithFormat:@"The following files will be reverted to the versions as of the revision selected below (%@)", [logTableView selectedRevision]];
	[sheetInformativeMessageTextField setStringValue: newSheetMessage];
	absolutePathsOfFilesToRevert = paths;
	
	[logTableView resetTable:self];
	[selectedFilesTextView setString:[paths componentsJoinedByString:@"\n"]];
	[NSApp beginSheet:theRevertSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[logTableView scrollToRevision:revision];
}


- (IBAction) openRevertSheetWithAllFiles:(id)sender
{
	NSString* newTitle = [NSString stringWithFormat:@"Reverting All Files in %@", [myDocument selectedRepositoryShortName]];
	[revertSheetTitle setStringValue:newTitle];
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	[self openRevertSheetWithPaths:[NSArray arrayWithObject:rootPath] andRevision:[myDocument getHGParent1Revision]];
}

- (IBAction) openRevertSheetWithSelectedFiles:(id)sender
{
	NSString* newTitle = [NSString stringWithFormat:@"Reverting Selected Files in %@", [myDocument selectedRepositoryShortName]];
	[revertSheetTitle setStringValue:newTitle];
	NSArray* paths = [myDocument absolutePathsOfBrowserChosenFiles];
	if ([paths count] <= 0)
		{ PlayBeep(); DebugLog(@"No files are selected to revert"); return; }
	
	[self openRevertSheetWithPaths:paths  andRevision:[myDocument getHGParent1Revision]];
}


- (IBAction) sheetButtonOkForRevertSheet:(id)sender;
{
	NSString* versionToRevertTo = [logTableView selectedRevision];
	BOOL didReversion = [myDocument primaryActionRevertFiles:absolutePathsOfFilesToRevert toVersion:versionToRevertTo];
	if (!didReversion)
		return;

	[NSApp endSheet:theRevertSheet];
	[theRevertSheet orderOut:sender];
}

- (IBAction) sheetButtonCancelForRevertSheet:(id)sender;
{
	[NSApp endSheet:theRevertSheet];
	[theRevertSheet orderOut:sender];
}


- (IBAction) sheetButtonViewDifferencesForRevertSheet:(id)sender
{
	NSString* versionToRevertTo = [logTableView selectedRevision];
	[myDocument viewDifferencesInCurrentRevisionFor:absolutePathsOfFilesToRevert toRevision:versionToRevertTo];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable;
{
	[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The contents of the files within the selected file paths will be replaced with their contents as of version ")];
	NSString* rev = [logTableView selectedRevision];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(rev ? rev : @"-")];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@". Any tracked files which have been modified will be moved aside. Any newly added or removed files will return to their former status.")];
	return newSheetMessage;
}


@end
