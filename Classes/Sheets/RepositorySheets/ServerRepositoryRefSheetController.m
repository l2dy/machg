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
#import "SingleTimedQueue.h"
#import "ShellHere.h"
#import "NSURL+Parameters.h"

@interface ServerRepositoryRefSheetController (PrivateAPI)
- (void) passwordChanged;
- (void) baseServerURLEndedEdits;
- (void) repositionTestConnectionButton;
@end


@implementation ServerRepositoryRefSheetController
@synthesize shortNameFieldValue		= shortNameFieldValue_;
@synthesize baseServerURLFieldValue = baseServerURLFieldValue_;
@synthesize fullServerURLFieldValue = fullServerURLFieldValue_;
@synthesize password				= password_;
@synthesize username				= username_;





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

- (void) awakeFromNib
{
	timeoutQueueForSecurity_ = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue() withTimeDelay:60.0 descriptiveName:@"queueForSecurityTimeout"];	// Our security details will timeout in 60 seconds
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Server Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) clearSheetValues
{
	[self setShortNameFieldValue:@""];
	[self setBaseServerURLFieldValue:@""];
	[self setUsername:@""];
	[self setPassword:@""];
	[self setShowRealPassword:YES];
	
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Autherization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) removeAuthorization
{
	AuthorizationRef myAuthorizationRef;
	AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &myAuthorizationRef);
	AuthorizationFree(myAuthorizationRef, kAuthorizationFlagDestroyRights);	
	[self setShowRealPassword:NO];
	[self passwordChanged];
}


- (BOOL) authorizeForShowingPassword;
{
	const char* macHgAuth = "com.jasonfharris.machg.viewpasswords";
	
	AuthorizationRef myAuthorizationRef;
	OSStatus myStatus;
	myStatus = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &myAuthorizationRef);
	
	AuthorizationItem myItems[1];
	myItems[0].name = macHgAuth;
	myItems[0].valueLength = 0;
	myItems[0].value = NULL;
	myItems[0].flags = 0;
	
	AuthorizationRights myRights;
	myRights.count = sizeof (myItems) / sizeof (myItems[0]);
	myRights.items = myItems;

	const char* cPrompt = [@"Administrative access is needed to expose the server password:\n\n" UTF8String];
	AuthorizationItem envItems[1];
    envItems[0].name = kAuthorizationEnvironmentPrompt;
    envItems[0].value = (void*)cPrompt;
    envItems[0].valueLength = strlen(cPrompt);
    envItems[0].flags = 0;
	AuthorizationItemSet environment = { 1, envItems };
	
	AuthorizationFlags myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
	
	myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, &environment, myFlags, NULL);

	// We timeout after 60 seconds if we don't use show the password again
	[timeoutQueueForSecurity_ addBlockOperation:^{
		[self removeAuthorization];
	}];
	return myStatus == noErr;
}


- (BOOL) showRealPassword	{ return showRealPassword_; }
- (void) setShowRealPassword:(BOOL)val
{
	if (val != showRealPassword_)
	{
		[self willChangeValueForKey:@"showRealPassword"];
		showRealPassword_ = val;
		[self didChangeValueForKey:@"showRealPassword"];
	}
	[showPasswordButton setState:val];
	[self passwordChanged];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) validateButtons:(id)sender
{
	BOOL valid = ([[self baseServerURLFieldValue] length] > 0) && ([[self shortNameFieldValue] length] > 0);
	[okButton setEnabled:valid];
	if (sender == theBaseServerTextField || sender == self || sender == theUsernameTextField || sender == theSecurePasswordTextField || sender == theUnsecurePasswordTextField)
	{
		[theConnectionValidationController testConnection:sender];
		[timeoutQueueForSecurity_ addBlockOperation:^{
			[self removeAuthorization];
		}];
		
	}
}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Sheet Opening
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) openSheetForNewRepositoryRef
{
	[self clearSheetValues];
	[self validateButtons:self];
	
	nodeToConfigure = nil;
	passwordKeyChainItem_ = nil;
	cloneAfterAddition_ = NO;
	[theTitleText setStringValue:@"Add Server Repository"];
	[okButton setTitle:@"Add Server"];
	[theConnectionValidationController resetForSheetOpen];
	[NSApp beginSheet:theWindow modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (void) openSheetForAddAndClone
{
	[self clearSheetValues];
	[self validateButtons:self];
	
	nodeToConfigure = nil;
	passwordKeyChainItem_ = nil;
	cloneAfterAddition_ = YES;
	[theTitleText setStringValue:@"Add and Clone Server Repository"];
	[okButton setTitle:@"Add and Clone"];
	[theConnectionValidationController resetForSheetOpen];
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
	[self clearSheetValues];
	
	if ([node isServerRepositoryRef])
	{
		[self setShortNameFieldValue:[node shortName]];
		[self setBaseServerURLFieldValue:[node path]];
		[self baseServerURLEndedEdits];
	}
	
	passwordKeyChainItem_ = [EMGenericKeychainItem genericKeychainItemForService:kMacHgApp withUsername:[node path]];
	if (passwordKeyChainItem_)
	{
		[self setPassword:passwordKeyChainItem_.password];
		[self setShowRealPassword:NO];
	}
	else
	{
		passwordKeyChainItem_ = nil;
		if (IsEmpty(password_))
			[self setShowRealPassword:YES];
	}
	[self passwordChanged];

	[theTitleText setStringValue:@"Configure Server Repository"];
	[okButton setTitle:@"Configure Server"];
	cloneAfterAddition_ = NO;
	[theConnectionValidationController resetForSheetOpen];
	[self validateButtons:self];
	[NSApp beginSheet:theWindow modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) testConnectionInTerminal:(id)sender
{
	if (IsNotEmpty(password_) && ![self authorizeForShowingPassword])
		return;

	NSString* fullServerURL = [self generateFullServerURLIncludingPassword:YES andMaskingPassword:NO];
	NSMutableArray* argsIdentify = [NSMutableArray arrayWithObjects:@"identify", @"--insecure", @"--noninteractive", @"--rev", @"0", fullServerURL, nil];
	NSMutableArray* newArgs = [TaskExecutions preProcessMercurialCommandArgs:argsIdentify fromRoot:@"/tmp"];
	[newArgs insertObject:LocalWhitelistedHGShellAliasNameFromDefaults() atIndex:0];
	NSString* identityCommand = [newArgs componentsJoinedByString:@" "];
	
	NSMutableArray* commands = [NSMutableArray arrayWithArray:aliasesForShell()];
	[commands addObject:identityCommand];
	DoCommandsInTerminalAt(commands, @"/tmp");
}


- (IBAction) toggleShowPassword:(id)sender
{
	if ([self showRealPassword] == YES)
	{
		[self setShowRealPassword:NO];
		return;
	}

	if (![self authorizeForShowingPassword])
	{
		[showPasswordButton setState:NSOffState];
		[self passwordChanged];
		return;
	}

	[self setShowRealPassword:YES];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[theWindow makeFirstResponder:theWindow];	// Make the text fields of the sheet commit any changes they currently have

	Sidebar* theSidebar = [myDocument sidebar];
	[[theSidebar prepareUndoWithTarget:theSidebar] setRootAndUpdate:[[theSidebar root] copyNodeTree]];
	[[theSidebar undoManager] setActionName: (nodeToConfigure ? @"Configure Repository" : @"Add Server Repository")];

	NSString* newName    = [shortNameFieldValue_ copy];
	NSString* newPath    = [self generateFullServerURLIncludingPassword:NO andMaskingPassword:NO];
	if (nodeToConfigure)
	{
		[theSidebar removeConnectionsFor:[nodeToConfigure path]];
		[nodeToConfigure setPath:newPath];
		[nodeToConfigure setHasPassword:IsNotEmpty(password_)];
		[nodeToConfigure setShortName:newName];
		[nodeToConfigure refreshNodeIcon];
	}
	else
	{
		SidebarNode* newNode = [SidebarNode nodeWithCaption:newName  forServerPath:newPath];
		[newNode setHasPassword:IsNotEmpty(password_)];
		[newNode refreshNodeIcon];
		[[myDocument sidebar] addSidebarNode:newNode];
		[theSidebar selectNode:newNode];
	}
	
	[passwordKeyChainItem_ removeFromKeychain];

	if (IsNotEmpty(password_))
	{
		EMGenericKeychainItem* newKeychainItem = [EMGenericKeychainItem genericKeychainItemForService:kMacHgApp withUsername:newPath];
		if (newKeychainItem)
		{
			newKeychainItem.username = newPath;
			newKeychainItem.password = [self password];
		}
		else
			[EMGenericKeychainItem addGenericKeychainItemForService:kMacHgApp withUsername:newPath password:[self password]];
	}

	[[AppController sharedAppController] computeRepositoryIdentityForPath:newPath];
	
	[NSApp endSheet:theWindow];
	[theWindow orderOut:sender];
	[[myDocument sidebar] reloadData];
	[myDocument saveDocumentIfNamed];
	[myDocument postNotificationWithName:kSidebarSelectionDidChange];
	if (cloneAfterAddition_)
		[myDocument mainMenuCloneRepository:self];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[theWindow makeFirstResponder:theWindow];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theWindow];
	[theWindow orderOut:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Button positioning
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) repositionTestConnectionButton
{
	[theFullServerTextField sizeToFit];
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.1];
	[testConnectionButton setToRightOf:theFullServerTextField bySpacing:10];
	[NSAnimationContext endGrouping];	
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Field updating
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) generateFullServerURLIncludingPassword:(BOOL)includePass andMaskingPassword:(BOOL)mask
{
	NSURL* theBaseURL = [NSURL URLWithString:baseServerURLFieldValue_];
	BOOL valid = [theBaseURL scheme] && [theBaseURL host];
	if (!valid || IsEmpty(username_))
		return baseServerURLFieldValue_;
	
	NSURL* withUser     = [theBaseURL URLByReplacingUser:username_];
	if (!includePass || IsEmpty(password_))
		return [withUser absoluteString];
	
	NSURL* withPassword = [withUser URLByReplacingPassword:mask ? @"***" : password_];
	return [withPassword absoluteString];
}

- (void) baseServerURLChanged
{
	NSURL* theBaseURL = [NSURL URLWithString:baseServerURLFieldValue_];

	if (IsNotEmpty([theBaseURL password]))
		[self setPassword:[theBaseURL password]];
	if (IsNotEmpty([theBaseURL user]))
		[self setUsername:[theBaseURL user]];

	[self setFullServerURLFieldValue:[self generateFullServerURLIncludingPassword:YES andMaskingPassword:!showRealPassword_]];
	[self performSelector:@selector(repositionTestConnectionButton) withObject:nil afterDelay:0.05];
}

- (void) baseServerURLEndedEdits
{
	[self baseServerURLChanged];
	NSURL* theBaseURL = [NSURL URLWithString:baseServerURLFieldValue_];
	if (IsEmpty([theBaseURL password]) && IsEmpty([theBaseURL user]))
		return;
	[self setBaseServerURLFieldValue:[[theBaseURL URLByDeletingUserAndPassword] absoluteString]];
}


- (void) usernameChanged
{
	[self setFullServerURLFieldValue:[self generateFullServerURLIncludingPassword:YES andMaskingPassword:!showRealPassword_]];
	[self performSelector:@selector(repositionTestConnectionButton) withObject:nil afterDelay:0.05];
}

- (void) passwordChanged
{
	[self setFullServerURLFieldValue:[self generateFullServerURLIncludingPassword:YES andMaskingPassword:!showRealPassword_]];
	[self performSelector:@selector(repositionTestConnectionButton) withObject:nil afterDelay:0.05];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) controlTextDidChange:(NSNotification*)aNotification
{
	id sender = [aNotification object];
	if		(sender == theBaseServerTextField)			[self baseServerURLChanged];
	else if (sender == theUsernameTextField)			[self usernameChanged];
	else if (sender == theSecurePasswordTextField)		[self passwordChanged];
	else if (sender == theUnsecurePasswordTextField)	[self passwordChanged];
	
	[self validateButtons:[aNotification object]];
}

- (void) controlTextDidEndEditing:(NSNotification*)aNotification
{
	id sender = [aNotification object];
	if		(sender == theBaseServerTextField)			[self baseServerURLEndedEdits];
}


@end
