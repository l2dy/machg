//
//  ServerRepositoryRefSheetController.h
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface ServerRepositoryRefSheetController : BaseSheetWindowController
{
	IBOutlet NSWindow*							theWindow;
	IBOutlet NSButton*							okButton;
	IBOutlet ConnectionValidationController*	theConnectionValidationController;
	IBOutlet NSTextField*						theTitleText;
	IBOutlet NSTextField*						theServerTextField;

	
	MacHgDocument*		myDocument;
	
	NSString*			shortNameFieldValue_;
	NSString*			serverFieldValue_;
	SidebarNode*		nodeToConfigure;
}
@property (readwrite,assign) NSString*	  shortNameFieldValue;
@property (readwrite,assign) NSString*	  serverFieldValue;

- (ServerRepositoryRefSheetController*) initServerRepositoryRefSheetControllerWithDocument:(MacHgDocument*)doc;

- (IBAction) validateButtons:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;

- (void)	openSheetForNewRepositoryRef;
- (void)	openSheetForConfigureRepositoryRef:(SidebarNode*)node;


// Delegate Methods for text fields
- (void)	 controlTextDidChange:(NSNotification*)aNotification;

@end
