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
#import "TaskExecutions.h"
#import "HistoryViewController.h"
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
@synthesize myDocument = myDocument_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (AddLabelSheetController*) initAddLabelSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"AddLabelSheet"];
	[self window];	// force / ensure the nib is loaded
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

- (void) dealloc
{
	[self removeObserver:self forKeyPath:kTheNewNameFieldValue];
	[self removeObserver:self forKeyPath:kTheRevisionFieldValue];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Update TabIndex and SegmentsIndexes
// ------------------------------------------------------------------------------------

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Pseudo Notifications
// ------------------------------------------------------------------------------------

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Tab handling
// ------------------------------------------------------------------------------------

- (IBAction) openAddLabelSheetForBookmark:(id)sender	{ [self setAddLabelTabNumber:eAddLabelTabBookmark];		[self openAddLabelSheet:sender]; }
- (IBAction) openAddLabelSheetForLocalTag:(id)sender	{ [self setAddLabelTabNumber:eAddLabelTabLocalTag];		[self openAddLabelSheet:sender]; }
- (IBAction) openAddLabelSheetForGlobalTag:(id)sender	{ [self setAddLabelTabNumber:eAddLabelTabGlobalTag];	[self openAddLabelSheet:sender]; }
- (IBAction) openAddLabelSheetForBranch:(id)sender		{ [self setAddLabelTabNumber:eAddLabelTabBranch];		[self openAddLabelSheet:sender]; }

- (IBAction) openAddLabelSheet:(id)sender
{
	HistoryView* theHistoryView = [myDocument_ theHistoryView];
	BOOL wasShowingHistoryView  = [myDocument_ showingHistoryView];
	[myDocument_ actionSwitchViewToHistoryView:sender];				// Open the log inspector
	[[myDocument_ toolbarSearchField] setStringValue:@""];			// reset the search term
	if (!wasShowingHistoryView)
		[[theHistoryView logTableView] scrollToCurrentRevision:sender];			// Scroll to the current revision
	[self setTheNewNameFieldValue:@""];
	[self setTheRevisionFieldValue:numberAsString([[theHistoryView logTableView] chosenRevision])];
	[commitMessageTextView setString:@""];
	[self setForceValue:NO];
	[self updateButtonsAndMessages];
	[myDocument_ beginSheet:theAddLabelSheet];
}


- (void) sheetButtonOk:(id)sender
{
	[theAddLabelSheet makeFirstResponder:theAddLabelSheet];	// Make the text fields of the sheet commit any changes they currently have
	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];

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
	if (forceValue_ == YES)
		[argsLabel addObject: @"--force"];
	if (addLabelTabNumber_ == eAddLabelTabLocalTag)
		[argsLabel addObject: @"--local"];
	if (addLabelTabNumber_ == eAddLabelTabBranch && [[commitMessageTextView string] length] > 0)
		[argsLabel addObject: @"--message" followedBy:[commitMessageTextView string]];
	[argsLabel addObject:theNewNameFieldValue_];
	ExecutionResult* results = [myDocument_ executeMercurialWithArgs:argsLabel fromRoot:rootPath whileDelayingEvents:YES];
	
	if ([results hasErrors])
		return;
	
	[myDocument_ endSheet:theAddLabelSheet];
	[myDocument_ postNotificationWithName:kUnderlyingRepositoryChanged];	// Check that we still need to post this notification. The command
																		// should like cause a refresh in any case.
}


- (IBAction) sheetButtonCancel:(id)sender
{
	[theAddLabelSheet makeFirstResponder:theAddLabelSheet];	// Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:theAddLabelSheet];
}


@end
