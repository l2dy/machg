//
//  ServerRepositoryRefSheetController.h
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "EMKeychainItem.h"

@interface ServerRepositoryRefSheetController : BaseSheetWindowController
{
	IBOutlet NSWindow*							theWindow;
	IBOutlet NSButton*							okButton;
	IBOutlet NSButton*							showPasswordButton;
	IBOutlet NSBox*								connectionStatusBox;
	IBOutlet NSBox*								passwordBox;
	IBOutlet NSTextField*						theTitleText;
	IBOutlet NSTextField*						theBaseServerTextField;
	IBOutlet NSTextField*						theUsernameTextField;
	IBOutlet NSTextField*						theSecurePasswordTextField;
	IBOutlet NSTextField*						theUnsecurePasswordTextField;
	IBOutlet NSTextField*						theFullServerTextField;
	IBOutlet ConnectionValidationController*	theConnectionValidationController;
	IBOutlet DisclosureBoxController*			advancedOptionsDisclosureController;		// The disclosure box for the advanced options
	IBOutlet DisclosureBoxController*			passwordBoxDisclosureController;			// The disclosure box for the password options

	EMGenericKeychainItem* passwordKeyChainItem_;
	SingleTimedQueue*	timeoutQueueForSecurity_;
	SidebarNode*		nodeToConfigure;
	
	BOOL				showRealPassword_;
	BOOL				cloneAfterAddition_;
}

@property (weak,readonly) MacHgDocument* myDocument;
@property NSString*	  shortNameFieldValue;
@property NSString*	  baseServerURLFieldValue;
@property NSString*	  username;
@property NSString*	  password;
@property NSString*	  repositoryIdentity;
@property NSString*	  fullServerURLFieldValue;


- (BOOL) showRealPassword;
- (void) setShowRealPassword:(BOOL)val;		// Setting this enables / disables the show password button
- (NSString*) generateFullServerURLIncludingPassword:(BOOL)includePass andMaskingPassword:(BOOL)mask;


// Initilization
- (ServerRepositoryRefSheetController*) initServerRepositoryRefSheetControllerWithDocument:(MacHgDocument*)doc;


// Sheet opening
- (void)	openSheetForNewRepositoryRef;
- (void)	openSheetForConfigureRepositoryRef:(SidebarNode*)node;
- (void)	openSheetForAddAndClone;


// Actions
- (IBAction) validateButtons:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) testConnectionInTerminal:(id)sender;
- (IBAction) toggleShowPassword:(id)sender;

// Delegate Methods for text fields
- (void)	 controlTextDidChange:(NSNotification*)aNotification;

@end
