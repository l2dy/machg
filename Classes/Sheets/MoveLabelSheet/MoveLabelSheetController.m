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
#import "LabelData.h"
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

- (IBAction) validate:(id)sender
{
	NSString* versionToRevertTo = [logTableView selectedRevision];
	[sheetInformativeMessageTextField setAttributedStringValue: [self formattedSheetMessage]];
	BOOL enabled = (versionToRevertTo && [versionToRevertTo isNotEqualToString:[labelToMove_ revision]]);
	[okButton setEnabled:enabled];	
}


- (void) openMoveLabelSheetForMoveLabel:(LabelData*)label;
{
	labelToMove_ = label;

	// Report the label we are about to move
	NSString* newLabelToMoveMessage = [NSString stringWithFormat:@"%@ to move:%@", [label labelTypeDescription], [label name]];
	[labelToMoveTextField setStringValue:newLabelToMoveMessage];
	
	// Update the button and the sheet message
	[self validate:self];

	[logTableView resetTable:self];
	[NSApp beginSheet:theMoveLabelSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[logTableView scrollToRevision:[label revision]];
}


- (void) sheetButtonOk:(id)sender
{
	[theMoveLabelSheet makeFirstResponder:theMoveLabelSheet];	// Make the text fields of the sheet commit any changes they currently have
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSString* versionToRevertTo = [logTableView selectedRevision];

	NSString* command = @"";
	BOOL bailEarly = NO;
	switch ([labelToMove_ labelType])
	{
		case eLocalTag:
		case eGlobalTag:		command = @"tag";		break;
		case eBookmark:			command = @"bookmark";	break;
		case eActiveBranch:
		case eInactiveBranch:
		case eClosedBranch:
		{
			if ([versionToRevertTo isNotEqualToString:[[myDocument repositoryData] getHGParent]])
			{
				BOOL updatedToTagetRev = [myDocument primaryActionUpdateFilesToVersion:versionToRevertTo withCleanOption:NO];
				if (!updatedToTagetRev)
					bailEarly = YES;
			}
			command = @"branch";
			break;
		}

		default:bailEarly = YES;
	}
	
	if (bailEarly)
	{
		PlayBeep();
		[NSApp endSheet:theMoveLabelSheet];
		[theMoveLabelSheet orderOut:sender];
		return;
	}
		
	NSMutableArray* argsMoveLabel = [NSMutableArray arrayWithObjects:command, nil ];
	if (![labelToMove_ isBranch])
		[argsMoveLabel addObject: @"--rev" followedBy:versionToRevertTo];
	if ([labelToMove_ labelType] == eLocalTag)
		[argsMoveLabel addObject: @"--local"];
	[argsMoveLabel addObject: @"--force"];
	[argsMoveLabel addObject:[labelToMove_ name]];
	ExecutionResult* results = [myDocument executeMercurialWithArgs:argsMoveLabel fromRoot:rootPath whileDelayingEvents:YES];
	
	if ([results hasErrors])
		return;
	
	[NSApp endSheet:theMoveLabelSheet];
	[theMoveLabelSheet orderOut:sender];
	[myDocument postNotificationWithName:kUnderlyingRepositoryChanged];
}



- (IBAction) sheetButtonCancel:(id)sender;
{
	[NSApp endSheet:theMoveLabelSheet];
	[theMoveLabelSheet orderOut:sender];
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
	NSString* versionToRevertTo = [logTableView selectedRevision];
	
	if (!versionToRevertTo || [versionToRevertTo isEqualToString:[labelToMove_ revision]])
	{
		NSString* newSheetMessageText = [NSString stringWithFormat:@"select a revision to move the %@ %@ to which is different than the current revision %@", [labelToMove_ labelTypeDescription], [labelToMove_ name], [labelToMove_ revision]];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(newSheetMessageText)];
		return newSheetMessage;
	}

	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString([NSString stringWithFormat:@"The %@ %@ will be moved from revision ",[labelToMove_ labelTypeDescription], [labelToMove_ name]])];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString([labelToMove_ revision])];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" to the selected revision ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(versionToRevertTo)];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@".")];
	return newSheetMessage;
}


@end
