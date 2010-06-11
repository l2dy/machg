//  MergeSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "MergeSheetController.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "ResultsWindowController.h"

@interface MergeSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation MergeSheetController

@synthesize forceTheMerge						= forceTheMerge_;
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (MergeSheetController*) initMergeSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"MergeSheet" owner:self];
	return self;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) clearSheetFieldValues
{
	[self validateButtons:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Validation   ---------------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------


- (IBAction) validateButtons:(id)sender
{
	NSString* theSelectedRevision = [logTableView selectedRevision];
	BOOL canMerge = theSelectedRevision && [theSelectedRevision isNotEqualToString:[[myDocument repositoryData]getHGParent1Revision]];
	[sheetButtonOkForMergeSheet setEnabled:canMerge];
	[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions Merge   ------------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------


- (void) openMergeSheetWithRevision:(NSString*)revision
{
	[self openMergeSheet:self];
	[logTableView selectAndScrollToRevision:revision];
	[logTableView scrollToRevision:revision];
}


- (IBAction) openMergeSheet:(id)sender;
{
	[NSApp beginSheet:mergeSheetWindow modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[self validateButtons:self];
	[logTableView resetTable:self];
}


- (IBAction) sheetButtonOk:(id)sender;
{
	[mergeSheetWindow makeFirstResponder:mergeSheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:mergeSheetWindow];
	[mergeSheetWindow orderOut:sender];
	NSString* theSelectedRevision = [logTableView selectedRevision];
	NSArray* theOptions = [self forceTheMerge] ? [NSArray arrayWithObject:@"--force"] : nil;
	[myDocument primaryActionMergeWithVersion:theSelectedRevision andOptions:theOptions withConfirmation:NO];
}


- (IBAction) sheetButtonCancel:(id)sender;
{
	[mergeSheetWindow makeFirstResponder:mergeSheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:mergeSheetWindow];
	[mergeSheetWindow orderOut:sender];
}


- (IBAction) sheetButtonViewDifferencesForMergeSheet:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	NSString* versionToMergeWith = [logTableView selectedRevision];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:versionToMergeWith];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable;
{
	[self validateButtons:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The revision selected above (")];
	NSString* rev = [logTableView selectedRevision];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(rev ? rev : @"-")];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@") will be merged into the current revision (")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString([myDocument isCurrentRevisionTip] ? @"tip" : [myDocument getHGParent1Revision])];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@").")];
	return newSheetMessage;
}


@end









