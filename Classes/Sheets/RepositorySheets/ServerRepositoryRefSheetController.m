//
//  ServerRepositoryRefSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ServerRepositoryRefSheetController.h"
#import "LocalRepositoryRefSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "ConnectionValidationController.h"
#import "AppController.h"
#import "SingleTimedQueue.h"
#import "ShellHere.h"
#import "NSURL+Parameters.h"
#import "DisclosureBoxController.h"

@interface ServerRepositoryRefSheetController (PrivateAPI)
- (void) passwordChanged;
- (void) baseServerURLChanged;
- (void) baseServerURLEndedEdits;
- (void) repositionConnectionStatusBox;
@end


@implementation ServerRepositoryRefSheetController
@synthesize shortNameFieldValue		= shortNameFieldValue_;
@synthesize baseServerURLFieldValue = baseServerURLFieldValue_;
@synthesize password				= password_;
@synthesize username				= username_;
@synthesize repositoryIdentity		= repositoryIdentity_;
@synthesize fullServerURLFieldValue = fullServerURLFieldValue_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Server Methods
// ------------------------------------------------------------------------------------

- (void) clearSheetValues
{
	[self setShortNameFieldValue:@""];
	[self setBaseServerURLFieldValue:@""];
	[self setUsername:@""];
	[self setPassword:@""];
	[self setShowRealPassword:YES];
	[self setRepositoryIdentity:@""];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Autherization
// ------------------------------------------------------------------------------------

- (void) removeAuthorization
{
	AuthorizationRef myAuthorizationRef;
	AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &myAuthorizationRef);
	AuthorizationFree(myAuthorizationRef, kAuthorizationFlagDestroyRights);
	[self setShowRealPassword:NO];
	[self passwordChanged];
}


- (BOOL) authorizeForShowingPassword
{
	const char* macHgAuth = "com.jasonfharris.machg.viewpasswords";
	
	AuthorizationRef myAuthorizationRef;
	AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &myAuthorizationRef);
	
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
	
	OSStatus myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights, &environment, myFlags, NULL);

	// We timeout after 60 seconds if we don't use show the password again
	ServerRepositoryRefSheetController* __weak weakSelf = self;
	[timeoutQueueForSecurity_ addBlockOperation:^{
		[weakSelf removeAuthorization];
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// ------------------------------------------------------------------------------------

- (IBAction) validateButtons:(id)sender
{
	// If we are using ssh then hide all password details since Mercurial can't handle passed in passwords for ssh.
	BOOL sshConnection = [[self baseServerURLFieldValue] isMatchedByRegex:@"^ssh://"];
	[passwordBoxDisclosureController setToOpenState:!sshConnection withAnimation:YES];
	if (sshConnection && IsNotEmpty(password_))
	{
		[self setPassword:@""];
		[self passwordChanged];
	}

	BOOL valid = ([[self baseServerURLFieldValue] length] > 0) && ([[self shortNameFieldValue] length] > 0);
	[okButton setEnabled:valid];
	ServerRepositoryRefSheetController* __weak weakSelf = self;
	if (sender == theBaseServerTextField || sender == self || sender == theUsernameTextField || sender == theSecurePasswordTextField || sender == theUnsecurePasswordTextField)
	{
		[theConnectionValidationController testConnection:sender];
		[timeoutQueueForSecurity_ addBlockOperation:^{
			[weakSelf removeAuthorization];
		}];
		
	}
}


// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Sheet Opening
// ------------------------------------------------------------------------------------

- (void) openSheetForNewRepositoryRef
{
	[self clearSheetValues];
	[advancedOptionsDisclosureController setToOpenState:NO withAnimation:NO];
	[self validateButtons:self];
	
	nodeToConfigure = nil;
	passwordKeyChainItem_ = nil;
	cloneAfterAddition_ = NO;
	[theTitleText setStringValue:@"Add Server Repository"];
	[okButton setTitle:@"Add Server"];
	[theConnectionValidationController resetForSheetOpen];
	[myDocument beginSheet:theWindow];
}


- (void) openSheetForAddAndClone
{
	[self clearSheetValues];
	[advancedOptionsDisclosureController setToOpenState:NO withAnimation:NO];
	[self validateButtons:self];
	
	nodeToConfigure = nil;
	passwordKeyChainItem_ = nil;
	cloneAfterAddition_ = YES;
	[theTitleText setStringValue:@"Add and Clone Server Repository"];
	[okButton setTitle:@"Add and Clone"];
	[theConnectionValidationController resetForSheetOpen];
	[myDocument beginSheet:theWindow];
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
	[advancedOptionsDisclosureController setToOpenState:NO withAnimation:NO];
	
	if ([node isServerRepositoryRef])
	{
		[self setShortNameFieldValue:[node shortName]];
		[self setBaseServerURLFieldValue:[node path]];
		[self baseServerURLEndedEdits];
		[self setRepositoryIdentity:[node repositoryIdentity]];
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
	[myDocument beginSheet:theWindow];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// ------------------------------------------------------------------------------------

- (IBAction) testConnectionInTerminal:(id)sender
{
	if (IsNotEmpty(password_) && ![self authorizeForShowingPassword])
		return;

	NSString* fullServerURL = [self generateFullServerURLIncludingPassword:YES andMaskingPassword:NO];
	NSMutableArray* argsIdentify = [NSMutableArray arrayWithObjects:@"identify", @"--insecure", @"--noninteractive", @"--rev", @"0", fullServerURL, nil];
	NSMutableArray* newArgs = [TaskExecutions preProcessMercurialCommandArgs:argsIdentify fromRoot:@"/tmp"];
	[newArgs insertObject:LocalWhitelistedHGShellAliasNameFromDefaults() atIndex:0];
	NSString* identityCommand = [newArgs componentsJoinedByString:@" "];
	
	NSString* testDir = @"/tmp";
	NSMutableArray* commands = [NSMutableArray arrayWithArray:aliasesForShell(testDir)];
	[commands addObject:identityCommand];
	DoCommandsInTerminalAt(commands, testDir);
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
	NSString* newId      = IsNotEmpty(repositoryIdentity_) ? repositoryIdentity_ : nil;
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
		[theSidebar selectNode:newNode];
	}

	if (IsNotEmpty(newId) && IsNotEmpty(newPath))
		[[[AppController sharedAppController] repositoryIdentityForPath] synchronizedSetObject:newId forKey:newPath];

	if (passwordKeyChainItem_)
	{
		if ([newPath isNotEqualToString:passwordKeyChainItem_.username])
			passwordKeyChainItem_ = nil;
		else if (IsEmpty(password_))
		{
			// JFH_FIXME: This should relly be [passwordKeyChainItem_ removeFromKeychain] but this is causing the keychain to temporarily get corrupted. So instead just leave the empty password for the given user.
			passwordKeyChainItem_.password = @"";
			passwordKeyChainItem_ = nil;
		}
	}
	
	if (IsNotEmpty(password_))
	{
		if (!passwordKeyChainItem_)
			passwordKeyChainItem_ = [EMGenericKeychainItem genericKeychainItemForService:kMacHgApp withUsername:newPath];
		if (passwordKeyChainItem_)
			passwordKeyChainItem_.password = password_;
		else
			passwordKeyChainItem_ = [EMGenericKeychainItem addGenericKeychainItemForService:kMacHgApp withUsername:newPath password:[self password]];
	}

	[[AppController sharedAppController] computeRepositoryIdentityForPath:newPath];
	
	[myDocument endSheet:theWindow];
	[[myDocument sidebar] reloadData];
	[myDocument saveDocumentIfNamed];
	[myDocument postNotificationWithName:kSidebarSelectionDidChange];
	if (cloneAfterAddition_)
		[myDocument mainMenuCloneRepository:self];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[theWindow makeFirstResponder:theWindow];	// Make the text fields of the sheet commit any changes they currently have
	[myDocument endSheet:theWindow];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Button positioning
// ------------------------------------------------------------------------------------

- (void) repositionConnectionStatusBox
{
	[theFullServerTextField sizeToFit];
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.1];
	[connectionStatusBox setToRightOf:theFullServerTextField bySpacing:10];
	[NSAnimationContext endGrouping];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Field updating
// ------------------------------------------------------------------------------------

- (NSString*) generateFullServerURLIncludingPassword:(BOOL)includePass andMaskingPassword:(BOOL)mask
{
	if (IsEmpty(baseServerURLFieldValue_))
		return nil;
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
	if (IsEmpty(baseServerURLFieldValue_))
		return;

	// Clean up base server of newlines.
	BOOL commitNew = NO;
	if ([baseServerURLFieldValue_ isMatchedByRegex:@"\n|\r"])
	{
		baseServerURLFieldValue_ = [baseServerURLFieldValue_ stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		baseServerURLFieldValue_ = [baseServerURLFieldValue_ stringByReplacingOccurrencesOfString:@"\r" withString:@""];
		commitNew = YES;
	}
	
	NSURL* theBaseURL = [NSURL URLWithString:baseServerURLFieldValue_];

	if (IsNotEmpty([theBaseURL password]))
		[self setPassword:[theBaseURL password]];
	if (IsNotEmpty([theBaseURL user]))
		[self setUsername:[theBaseURL user]];
	if (commitNew)
		[self setBaseServerURLFieldValue:[[theBaseURL URLByDeletingUserAndPassword] absoluteString]];

	[self setFullServerURLFieldValue:[self generateFullServerURLIncludingPassword:YES andMaskingPassword:!showRealPassword_]];
	[self performSelector:@selector(repositionConnectionStatusBox) withObject:nil afterDelay:0.05];
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
	[self performSelector:@selector(repositionConnectionStatusBox) withObject:nil afterDelay:0.05];
}

- (void) passwordChanged
{
	[self setFullServerURLFieldValue:[self generateFullServerURLIncludingPassword:YES andMaskingPassword:!showRealPassword_]];
	[self performSelector:@selector(repositionConnectionStatusBox) withObject:nil afterDelay:0.05];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// ------------------------------------------------------------------------------------

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
