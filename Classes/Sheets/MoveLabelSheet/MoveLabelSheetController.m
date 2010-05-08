//
//  MoveLabelSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "MoveLabelSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"

@implementation MoveLabelSheetController
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (MoveLabelSheetController*) initMoveLabelSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"MoveLabelSheet" owner:self];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[inspectorSplitView setPosition:200 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theMoveLabelSheet makeFirstResponder:logTableView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) openMoveLabelSheetWithPaths:(NSArray*)paths andRevision:(NSString*)revision
{
	// Report the branch we are about to revert on in the dialog
	NSString* newSheetMessage = [NSString stringWithFormat:@"The following files will be reverted to the versions as of the revision selected below (%@)", [logTableView selectedRevision]];
	[sheetInformativeMessageTextField setStringValue: newSheetMessage];
	absolutePathsOfFilesToRevert = paths;
	
	[logTableView resetTable:self];
	[labelToMoveTextField setStringValue:[paths componentsJoinedByString:@"\n"]];
	[NSApp beginSheet:theMoveLabelSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[logTableView scrollToRevision:revision];
}


- (IBAction) openMoveLabelSheetWithAllFiles:(id)sender
{
	NSString* newTitle = [NSString stringWithFormat:@"Reverting All Files in %@", [myDocument selectedRepositoryShortName]];
	[moveLabelSheetTitle setStringValue:newTitle];
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	[self openMoveLabelSheetWithPaths:[NSArray arrayWithObject:rootPath] andRevision:[myDocument getHGParent1Revision]];
}

- (IBAction) openMoveLabelSheetWithSelectedFiles:(id)sender
{
	NSString* newTitle = [NSString stringWithFormat:@"Reverting Selected Files in %@", [myDocument selectedRepositoryShortName]];
	[moveLabelSheetTitle setStringValue:newTitle];
	NSArray* paths = [myDocument absolutePathsOfBrowserChosenFiles];
	if ([paths count] <= 0)
	{ PlayBeep(); DebugLog(@"No files are selected to revert"); return; }
	
	[self openMoveLabelSheetWithPaths:paths  andRevision:[myDocument getHGParent1Revision]];
}


- (IBAction) sheetButtonOkForMoveLabelSheet:(id)sender;
{
	NSString* versionToRevertTo = [logTableView selectedRevision];
	BOOL didReversion = [myDocument primaryActionRevertFiles:absolutePathsOfFilesToRevert toVersion:versionToRevertTo];
	if (!didReversion)
		return;
	
	[NSApp endSheet:theMoveLabelSheet];
	[theMoveLabelSheet orderOut:sender];
}

- (IBAction) sheetButtonCancelForMoveLabelSheet:(id)sender;
{
	[NSApp endSheet:theMoveLabelSheet];
	[theMoveLabelSheet orderOut:sender];
}


- (IBAction) sheetButtonViewDifferencesForMoveLabelSheet:(id)sender
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
