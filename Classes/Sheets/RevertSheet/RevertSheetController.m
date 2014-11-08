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


@interface RevertSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation RevertSheetController
@synthesize myDocument = myDocument_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (RevertSheetController*) initRevertSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"RevertSheet"];
	[self window];	// force / ensure the nib is loaded
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// ------------------------------------------------------------------------------------

- (void) openRevertSheetWithPaths:(NSArray*)paths andRevision:(NSNumber*)revision
{
	// Report the branch we are about to revert on in the dialog
	NSString* newSheetMessage = fstr(@"The following files will be reverted to the versions as of the revision selected below (%@)", [logTableView selectedRevision]);
	[sheetInformativeMessageTextField setStringValue: newSheetMessage];
	absolutePathsOfFilesToRevert = paths;
	
	[logTableView resetTable:self];
	[selectedFilesTextView setString:[paths componentsJoinedByString:@"\n"]];
	[myDocument_ beginSheet:theRevertSheet];
	[logTableView scrollToRevision:revision];
}


- (IBAction) openRevertSheetWithAllFiles:(id)sender
{
	NSString* newTitle = fstr(@"Reverting All Files in %@", [myDocument_ selectedRepositoryShortName]);
	[revertSheetTitle setStringValue:newTitle];
	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];
	[self openRevertSheetWithPaths:@[rootPath] andRevision:[myDocument_ getHGParent1Revision]];
}

- (IBAction) openRevertSheetWithSelectedFiles:(id)sender
{
	NSString* newTitle = fstr(@"Reverting Selected Files in %@", [myDocument_ selectedRepositoryShortName]);
	[revertSheetTitle setStringValue:newTitle];
	NSArray* paths = [myDocument_ absolutePathsOfChosenFiles];
	if ([paths count] <= 0)
		{ PlayBeep(); DebugLog(@"No files are selected to revert"); return; }
	
	[self openRevertSheetWithPaths:paths  andRevision:[myDocument_ getHGParent1Revision]];
}


- (IBAction) sheetButtonOk:(id)sender
{
	NSNumber* versionToRevertTo = [logTableView selectedRevision];
	BOOL didReversion = [myDocument_ primaryActionRevertFiles:absolutePathsOfFilesToRevert toVersion:versionToRevertTo];
	if (!didReversion)
		return;

	[myDocument_ endSheet:theRevertSheet];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[myDocument_ endSheet:theRevertSheet];
}


- (IBAction) sheetButtonViewDifferencesForRevertSheet:(id)sender
{
	NSNumber* versionToRevertTo = [logTableView selectedRevision];
	[myDocument_ viewDifferencesInCurrentRevisionFor:absolutePathsOfFilesToRevert toRevision:numberAsString(versionToRevertTo)];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// ------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[sheetInformativeMessageTextField setAttributedStringValue: self.formattedSheetMessage];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// ------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The contents of the files within the selected file paths will be replaced with their contents as of version ")];
	NSNumber* revision = [logTableView selectedRevision];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(revision ? numberAsString(revision) : @"-")];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@". Any tracked files which have been modified will be moved aside. Any newly added or removed files will return to their former status.")];
	return newSheetMessage;
}


@end
