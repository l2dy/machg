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
	IBOutlet ConnectionValidationController*	theConnectionValidationController;
	IBOutlet NSTextField*						theTitleText;
	IBOutlet NSTextField*						theServerTextField;
	IBOutlet NSTextField*						theSecurePasswordTextField;
	IBOutlet NSTextField*						theUnsecurePasswordTextField;

	
	MacHgDocument*		myDocument;
	
	NSString*			shortNameFieldValue_;
	NSString*			serverFieldValue_;
	SidebarNode*		nodeToConfigure;
	NSString*			password_;
	BOOL				needsPassword_;
	BOOL				showRealPassword_;
	EMGenericKeychainItem* passwordKeyChainItem_;
}
@property (readwrite,assign) NSString*	  shortNameFieldValue;
@property (readwrite,assign) NSString*	  serverFieldValue;
@property (readwrite,assign) NSString*	  password;
@property (readwrite,assign) BOOL		  needsPassword;


- (BOOL) showRealPassword;
- (void) setShowRealPassword:(BOOL)val;		// Setting this enables / disables the show password button


// Initilization
- (ServerRepositoryRefSheetController*) initServerRepositoryRefSheetControllerWithDocument:(MacHgDocument*)doc;


// Sheet opening
- (void)	openSheetForNewRepositoryRef;
- (void)	openSheetForConfigureRepositoryRef:(SidebarNode*)node;


// Actions
- (IBAction) validateButtons:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) testConnectionInTerminal:(id)sender;
- (IBAction) toggleShowPassword:(id)sender;

// Delegate Methods for text fields
- (void)	 controlTextDidChange:(NSNotification*)aNotification;

@end
