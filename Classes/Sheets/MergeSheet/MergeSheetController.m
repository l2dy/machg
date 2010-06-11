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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  MergeSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface MergeSheetController (PrivateAPI)
- (NSAttributedString*) normalFormattedSheetMessage;
- (NSAttributedString*) ancestorFormattedSheetMessage;
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
	NSString* theParentRevision   = [[myDocument repositoryData]getHGParent1Revision];
	BOOL canMerge = YES;
	
	NSAttributedString* message = nil;
	
	if (!theSelectedRevision || [theSelectedRevision isEqualToString:theParentRevision])
	{
		message  = normalSheetMessageAttributedString(@"");
		canMerge = NO;
	}
	
	if (!message)
	{
		NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
		NSMutableArray* argsDebugAncestor = [NSMutableArray arrayWithObjects:@"debugancestor", theSelectedRevision, theParentRevision, nil];
		ExecutionResult* results = [myDocument executeMercurialWithArgs:argsDebugAncestor fromRoot:rootPath whileDelayingEvents:YES];
		if (results.outStr)
		{
			NSString* ancestor = trimString([results.outStr stringByMatching:@"(\\d+):[\\d\\w]+\\s*" capture:1L]);
			if ([ancestor isEqualToString:theParentRevision] || [ancestor isEqualToString:theSelectedRevision])
			{
				message = [self ancestorFormattedSheetMessage];
				canMerge = NO;
			}
		}
	}

	if (!message)
	{
		message = [self normalFormattedSheetMessage];
		canMerge = YES;
	}
	
	dispatch_async(mainQueue(), ^{
		[sheetButtonOkForMergeSheet setEnabled:canMerge];
		[sheetInformativeMessageTextField setAttributedStringValue: message];
	});
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

- (NSAttributedString*) normalFormattedSheetMessage
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


- (NSAttributedString*) ancestorFormattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	[newSheetMessage appendAttributedString: grayedSheetMessageAttributedString(@"Cannot merge (")];
	NSString* rev = [logTableView selectedRevision];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(rev ? rev : @"-")];
	[newSheetMessage appendAttributedString: grayedSheetMessageAttributedString(@") into the current revision (")];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString([myDocument isCurrentRevisionTip] ? @"tip" : [myDocument getHGParent1Revision])];
	[newSheetMessage appendAttributedString: grayedSheetMessageAttributedString(@") since one of the revisions is a direct ancestor of the other.")];
	return newSheetMessage;
}


@end









