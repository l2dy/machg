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

- (void) openMoveLabelSheetForMoveLabel:(LabelData*)label;
{
	labelToMove_ = label;
	// Report the branch we are about to revert on in the dialog
	NSString* newSheetMessage = [NSString stringWithFormat:@"The following files will be reverted to the versions as of the revision selected below (%@)", [label name]];
	NSString* newLabelToMoveMessage = [NSString stringWithFormat:@"%@ to move:%@", [label labelTypeDescription], [label name]];

	[sheetInformativeMessageTextField setStringValue: newSheetMessage];
	[labelToMoveTextField setStringValue:newLabelToMoveMessage];
	
	[logTableView resetTable:self];
	[NSApp beginSheet:theMoveLabelSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[logTableView scrollToRevision:[label revision]];
}


- (void) sheetButtonOkForMoveLabelSheet:(id)sender
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
	ExecutionResult results = [myDocument executeMercurialWithArgs:argsMoveLabel fromRoot:rootPath whileDelayingEvents:YES];
	
	if ([results.errStr length] > 0)
		return;
	
	[NSApp endSheet:theMoveLabelSheet];
	[theMoveLabelSheet orderOut:sender];
	[myDocument postNotificationWithName:kUnderlyingRepositoryChanged];
}



- (IBAction) sheetButtonCancelForMoveLabelSheet:(id)sender;
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
