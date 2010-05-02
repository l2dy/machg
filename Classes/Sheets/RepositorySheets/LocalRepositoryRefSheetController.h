//
//  LocalRepositoryRefSheetController.h
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface LocalRepositoryRefSheetController : BaseSheetWindowController
{
	IBOutlet NSWindow*					theWindow;
	IBOutlet NSButton*					okButton;
	IBOutlet NSBox*						repositoryPathBox;
	IBOutlet NSTextField*				theTitleText;

	MacHgDocument*		myDocument;
	
	NSString*			shortNameFieldValue_;
	NSString*			pathFieldValue_;
	SidebarNode*		nodeToConfigure;			// If we are configuring a node, this is the one to configure
	SidebarNode*		addNewRepositoryRefTo;		// If we are creating a new RepositoryRef add it after this RepositoryRef
	NSInteger			addNewRepositoryRefAtIndex;	// If we are creating a new RepositoryRef add it after this RepositoryRef
}
@property (readwrite,assign) NSString*	  shortNameFieldValue;
@property (readwrite,assign) NSString*	  pathFieldValue;

- (LocalRepositoryRefSheetController*) initLocalRepositoryRefSheetControllerWithDocument:(MacHgDocument*)doc;

- (IBAction) browseToPath: (id)sender;
- (IBAction) validateButtons:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;

// Open the sheet
- (void)	 openSheetForNewRepositoryRef;
- (void)	 openSheetForNewRepositoryRefNamed:(NSString*)name atPath:(NSString*)path addNewRepositoryRefTo:(SidebarNode*)parent atIndex:(NSInteger)index;
- (void)	 openSheetForConfigureRepositoryRef:(SidebarNode*)node;

// Delegate Methods for text fields
- (void)	 controlTextDidChange:(NSNotification*)aNotification;

@end
