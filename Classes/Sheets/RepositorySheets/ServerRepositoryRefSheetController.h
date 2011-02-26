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
	IBOutlet NSButton*							testConnectionButton;
	IBOutlet ConnectionValidationController*	theConnectionValidationController;
	IBOutlet NSTextField*						theTitleText;
	IBOutlet NSTextField*						theBaseServerTextField;
	IBOutlet NSTextField*						theFullServerTextField;
	IBOutlet NSTextField*						theUsernameTextField;
	IBOutlet NSTextField*						theSecurePasswordTextField;
	IBOutlet NSTextField*						theUnsecurePasswordTextField;

	
	MacHgDocument*		myDocument;
	
	NSString*			shortNameFieldValue_;
	NSString*			baseServerURLFieldValue_;
	NSString*			fullServerURLFieldValue_;
	SidebarNode*		nodeToConfigure;
	NSString*			username_;
	NSString*			password_;
	BOOL				showRealPassword_;
	EMGenericKeychainItem* passwordKeyChainItem_;
	SingleTimedQueue*	timeoutQueueForSecurity_;
	BOOL				cloneAfterAddition_;
}
@property (readwrite,assign) NSString*	  shortNameFieldValue;
@property (readwrite,assign) NSString*	  baseServerURLFieldValue;
@property (readwrite,assign) NSString*	  fullServerURLFieldValue;
@property (readwrite,assign) NSString*	  password;
@property (readwrite,assign) NSString*	  username;


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
