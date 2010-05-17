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
	IBOutlet ConnectionValidationController*	theConnectionValidationController;
	IBOutlet NSTextField*						theTitleText;
	IBOutlet NSTextField*						theServerTextField;
	IBOutlet NSTextField*						thePasswordTextField;

	
	MacHgDocument*		myDocument;
	
	NSString*			shortNameFieldValue_;
	NSString*			serverFieldValue_;
	SidebarNode*		nodeToConfigure;
	NSString*			password_;
	BOOL				needsPassword_;
	BOOL				showRealPassword_;
	EMGenericKeychainItem* passwordKeyChainItem_;
	
	SingleTimedQueue*	timeoutQueueForSecurity_;
}
@property (readwrite,assign) NSString*	  shortNameFieldValue;
@property (readwrite,assign) NSString*	  serverFieldValue;
@property (readwrite,assign) NSString*	  password;
@property (readwrite,assign) BOOL		  needsPassword;
@property (readwrite,assign) BOOL		  showRealPassword;

- (ServerRepositoryRefSheetController*) initServerRepositoryRefSheetControllerWithDocument:(MacHgDocument*)doc;

- (IBAction) validateButtons:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) authorize:(id)sender;


- (void)	openSheetForNewRepositoryRef;
- (void)	openSheetForConfigureRepositoryRef:(SidebarNode*)node;


// Delegate Methods for text fields
- (void)	 controlTextDidChange:(NSNotification*)aNotification;



@end
