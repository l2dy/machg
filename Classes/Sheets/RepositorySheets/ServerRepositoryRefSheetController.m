//
//  ServerRepositoryRefSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ServerRepositoryRefSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "ConnectionValidationController.h"
#import "AppController.h"


@implementation ServerRepositoryRefSheetController
@synthesize shortNameFieldValue = shortNameFieldValue_;
@synthesize serverFieldValue    = serverFieldValue_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (ServerRepositoryRefSheetController*) initServerRepositoryRefSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"ServerRepositoryRefSheet" owner:self];
	return self;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Server Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) clearSheetFieldValues
{
	[self setShortNameFieldValue:@""];
	[self setServerFieldValue:@""];
	[self validateButtons:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) validateButtons:(id)sender
{
	BOOL valid = ([[self serverFieldValue] length] > 0) && ([[self shortNameFieldValue] length] > 0);
	[okButton setEnabled:valid];
	if (sender == theServerTextField || sender == self)
		[theConnectionValidationController testConnection:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions AddRepository   --------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) openSheetForNewRepositoryRef
{
	[self clearSheetFieldValues];
	nodeToConfigure = nil;
	[theTitleText setStringValue:@"Add Server Repository"];

	[NSApp beginSheet:theWindow modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (void) openSheetForConfigureRepositoryRef:(SidebarNode*)node
{
	// If the user has chosen the wrong type of configuration do the correct thing.
	if ([node isLocalRepositoryRef])
	{
		[[myDocument theLocalRepositoryRefSheetController] openSheetForConfigureRepositoryRef:node];
		return;
	}
	
	nodeToConfigure = node;
	if ([node isServerRepositoryRef])
	{
		[self setShortNameFieldValue:[node shortName]];
		[self setServerFieldValue:[node path]];
	}
	else
		[self clearSheetFieldValues];

	[theTitleText setStringValue:@"Configure Server Repository"];
	[self validateButtons:self];
	[NSApp beginSheet:theWindow modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (IBAction) sheetButtonOk:(id)sender;
{
	[theWindow makeFirstResponder:theWindow];	// Make the text fields of the sheet commit any changes they currently have

	Sidebar* theSidebar = [myDocument sidebar];
	[[theSidebar prepareUndoWithTarget:theSidebar] setRootAndUpdate:[[theSidebar root] copyNodeTree]];
	[[theSidebar undoManager] setActionName: (nodeToConfigure ? @"Configure Repository" : @"Add Server Repository")];

	NSString* newName    = [shortNameFieldValue_ copy];
	NSString* newPath    = [serverFieldValue_ copy];
	if (nodeToConfigure)
	{
		[theSidebar removeConnectionsFor:[nodeToConfigure path]];
		[nodeToConfigure setPath:newPath];
		[nodeToConfigure setShortName:newName];
		[nodeToConfigure refreshNodeIcon];
	}
	else
	{
		SidebarNode* newNode = [SidebarNode nodeWithCaption:newName  forServerPath:newPath];
		[newNode refreshNodeIcon];
		[[myDocument sidebar] addSidebarNode:newNode];
	}

	[[AppController sharedAppController] computeRepositoryIdentityForPath:newPath];
	
	[NSApp endSheet:theWindow];
	[theWindow orderOut:sender];
	[[myDocument sidebar] reloadData];
	[myDocument postNotificationWithName:kSidebarSelectionDidChange];
}

- (IBAction) sheetButtonCancel:(id)sender;
{
	[theWindow makeFirstResponder:theWindow];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theWindow];
	[theWindow orderOut:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) controlTextDidChange:(NSNotification*)aNotification
{
	[self validateButtons:[aNotification object]];
}



@end
