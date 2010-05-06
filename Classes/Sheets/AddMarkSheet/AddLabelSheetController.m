//
//  AddLabelSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "AddLabelSheetController.h"
#import "MacHgDocument.h"
#import "FSNodeInfo.h"
#import "TaskExecutions.h"
#import "HistoryPaneController.h"
#import "LabelData.h"

NSString* kTheNewNameFieldValue	 = @"theNewNameFieldValue";
NSString* kTheRevisionFieldValue = @"theRevisionFieldValue";

@interface AddLabelSheetController (Private)
- (void) updateButtonsAndMessages;
@end



@implementation AddLabelSheetController
@synthesize theNewNameFieldValue	= theNewNameFieldValue_;
@synthesize theRevisionFieldValue	= theRevisionFieldValue_;
@synthesize theMovementMessage		= theMovementMessage_;
@synthesize theScopeMessage			= theScopeMessage_;
@synthesize theCommitMessageValue	= theCommitMessageValue_;
@synthesize forceValue				= forceValue_;
@synthesize addLabelTabNumber		= addLabelTabNumber_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (AddLabelSheetController*) initAddLabelSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"AddLabelSheet" owner:self];
	return self;
}



- (void) awakeFromNib
{
	[self  addObserver:self  forKeyPath:kTheNewNameFieldValue		options:NSKeyValueObservingOptionNew  context:NULL];
	[self  addObserver:self  forKeyPath:kTheRevisionFieldValue		options:NSKeyValueObservingOptionNew  context:NULL];
	[addLabelTabView setDelegate:self];
}

- (void) observeValueForKeyPath:(NSString*)keyPath  ofObject:(id)object  change:(NSDictionary*)change  context:(void*)context
{
    if ([keyPath isEqualToString:kTheNewNameFieldValue] || [keyPath isEqualToString:kTheRevisionFieldValue])
		[self updateButtonsAndMessages];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Update TabIndex and SegmentsIndexes
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) updateButtonsAndMessages
{
	BOOL local		= (addLabelTabNumber_ == eAddLabelTabLocalTag || addLabelTabNumber_ == eAddLabelTabBookmark);
	BOOL stationary = (addLabelTabNumber_ == eAddLabelTabLocalTag || addLabelTabNumber_ == eAddLabelTabGlobalTag);
	
	NSMutableAttributedString* newScopeMessage = [[NSMutableAttributedString alloc] init];
	if (local)
	{
		[newScopeMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"Local")];
		[newScopeMessage appendAttributedString: normalSheetMessageAttributedString(@" - the label will be created in only the current repository. When you push this repository, the label name will not appear in the repositories pushed to.")];
	}
	else
	{
		[newScopeMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"Global")];
		[newScopeMessage appendAttributedString: normalSheetMessageAttributedString(@" - the label will be globally tracked with the repository. When you push this repository, the label name will appear in all of the repositories pushed to.")];
	}
	[self setTheScopeMessage:newScopeMessage];

	
	NSMutableAttributedString* newMovementMessage = [[NSMutableAttributedString alloc] init];
	if (stationary)
	{
		[newMovementMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"Stationary")];
		[newMovementMessage appendAttributedString: normalSheetMessageAttributedString(@" - the label will always reference the same revision changeset.")];
	}
	else
	{
		[newMovementMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"Advancing")];
		[newMovementMessage appendAttributedString: normalSheetMessageAttributedString(@" - the label will advance as commits are made to the working branch of the repository.")];
	}
	[self setTheMovementMessage:newMovementMessage];
	
	
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"Revision ")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(IsNotEmpty(theRevisionFieldValue_) ? theRevisionFieldValue_ : @"...")];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be labeled with the name '")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString( IsNotEmpty(theNewNameFieldValue_) ? theNewNameFieldValue_ : @"...")];
	
	
	switch (addLabelTabNumber_)
	{
		case eAddLabelTabLocalTag:
		{
			[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"'. This tag will be added immediately without any \"commit\" to the repository.")];
			break;
		}
		case eAddLabelTabGlobalTag:
		{
			[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"'. This tag will be added by a \"commit\" to the repository.")];
			break;
		}
		case eAddLabelTabBookmark:
		{
			[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"'. This bookmark will be added immediately without any \"commit\" to the repository.")];
			break;
		}
		case eAddLabelTabBranch:
		{
			newSheetMessage = [[NSMutableAttributedString alloc] init];
			[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The current revision will be labeled with the name '")];
			[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString( IsNotEmpty(theNewNameFieldValue_) ? theNewNameFieldValue_ : @"...")];
			[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"'. This branch label will only appear after the next \"commit\" to the repository.")];
			break;
		}
	}
	[sheetInformativeMessageTextField setAttributedStringValue:newSheetMessage];
	
	switch (addLabelTabNumber_)
	{
		case eAddLabelTabLocalTag:	[okButton setEnabled:(IsNotEmpty(theNewNameFieldValue_) && IsNotEmpty(theRevisionFieldValue_))];	break;
		case eAddLabelTabGlobalTag:	[okButton setEnabled:(IsNotEmpty(theNewNameFieldValue_) && IsNotEmpty(theRevisionFieldValue_))];	break;
		case eAddLabelTabBookmark:	[okButton setEnabled:(IsNotEmpty(theNewNameFieldValue_) && IsNotEmpty(theRevisionFieldValue_))];	break;
		case eAddLabelTabBranch:	[okButton setEnabled:IsNotEmpty(theNewNameFieldValue_)];	break;
		default:
			return;
	}
	
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Pseudo Notifications
// -----------------------------------------------------------------------------------------------------------------------------------------

// Delegate Method
- (void) tabView:(NSTabView*)tabView didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	[self updateButtonsAndMessages];
}

- (IBAction) didSelectSegment:(id)sender
{
	[self updateButtonsAndMessages];
}

- (IBAction) didChangeFieldContents:(id)sender
{
	[self updateButtonsAndMessages];	
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Tab handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openAddLabelSheet:(id)sender
{
	HistoryPaneController*	theHistoryPane = [myDocument theHistoryPaneController];
	BOOL wasShowingHistoryPane = [myDocument showingHistoryPane];
	[myDocument actionSwitchViewToHistoryPane:sender];				// Open the log inspector
	[[myDocument toolbarSearchField] setStringValue:@""];			// reset the search term
	if (!wasShowingHistoryPane)
		[[theHistoryPane logTableView] scrollToCurrentRevision:sender];			// Scroll to the current revision
	[self setTheNewNameFieldValue:@""];
	[self setTheRevisionFieldValue:[[theHistoryPane logTableView] chosenRevision]];
	[commitMessageTextView setString:@""];
	[self setForceValue:NO];
	[self updateButtonsAndMessages];
	[NSApp beginSheet:theAddLabelSheet modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


// Open the add label sheet and fill in the label name with the given label name and set the force flag to true. The user then
// needs to fill in the new revision number.
- (void) openAddLabelSheetForMoveLabel:(LabelData*)label
{
	HistoryPaneController*	theHistoryPane = [myDocument theHistoryPaneController];
	BOOL wasShowingHistoryPane = [myDocument showingHistoryPane];
	[myDocument actionSwitchViewToHistoryPane:self];				// Open the log inspector
	[[myDocument toolbarSearchField] setStringValue:@""];			// reset the search term
	if (!wasShowingHistoryPane)
		[[theHistoryPane logTableView] scrollToCurrentRevision:self];			// Scroll to the current revision
	
	
	switch ([label labelType])
	{
		case eLocalTag:		[addLabelTabView selectTabViewItemAtIndex:0];	break;
		case eGlobalTag:	[addLabelTabView selectTabViewItemAtIndex:1];	break;
		case eBookmark:		[addLabelTabView selectTabViewItemAtIndex:2];	break;
		case eActiveBranch:
		case eInactiveBranch:
		case eClosedBranch: [addLabelTabView selectTabViewItemAtIndex:3];	break;
	}
	
	[self setTheNewNameFieldValue:[label name]];
	[self setForceValue:YES];
	[self setTheRevisionFieldValue:@""];
	[commitMessageTextView setString:[NSString stringWithFormat:@"Move label %@", [label name]]];
	[self updateButtonsAndMessages];
	[NSApp beginSheet:theAddLabelSheet modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];	
}




- (void) sheetButtonOkForAddLabelSheet:(id)sender
{
	[theAddLabelSheet makeFirstResponder:theAddLabelSheet];	// Make the text fields of the sheet commit any changes they currently have
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];

	NSString* command = @"";
	switch (addLabelTabNumber_)
	{
		case eAddLabelTabLocalTag:	command = @"tag";		break;
		case eAddLabelTabGlobalTag:	command = @"tag";		break;
		case eAddLabelTabBookmark:	command = @"bookmark";	break;
		case eAddLabelTabBranch:	command = @"branch";	break;
	}
	NSMutableArray* argsLabel = [NSMutableArray arrayWithObjects:command, nil ];
	if (addLabelTabNumber_ != eAddLabelTabBranch)
		[argsLabel addObject: @"--rev" followedBy:theRevisionFieldValue_];
	if ((addLabelTabNumber_ == eAddLabelTabBranch || addLabelTabNumber_ == eAddLabelTabLocalTag) && forceValue_ == YES)
		[argsLabel addObject: @"--force"];
	if (addLabelTabNumber_ == eAddLabelTabLocalTag)
		[argsLabel addObject: @"--local"];
	if (addLabelTabNumber_ == eAddLabelTabBranch && [[commitMessageTextView string] length] > 0)
		[argsLabel addObject: @"--message" followedBy:[commitMessageTextView string]];
	[argsLabel addObject:theNewNameFieldValue_];
	ExecutionResult results = [myDocument executeMercurialWithArgs:argsLabel fromRoot:rootPath whileDelayingEvents:YES];
	
	if ([results.errStr length] > 0)
		return;
	
	[NSApp endSheet:theAddLabelSheet];
	[theAddLabelSheet orderOut:sender];
}


- (IBAction) sheetButtonCancelForAddLabelSheet:(id)sender
{
	[theAddLabelSheet makeFirstResponder:theAddLabelSheet];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theAddLabelSheet];
	[theAddLabelSheet orderOut:sender];
}


@end
