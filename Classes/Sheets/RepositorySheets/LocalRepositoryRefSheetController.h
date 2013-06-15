//
//  LocalRepositoryRefSheetController.h
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@class PathTextField;



@interface LocalRepositoryRefSheetController : BaseSheetWindowController
{
	IBOutlet NSWindow*					theLocalRepositoryRefSheet;
	IBOutlet NSButton*					okButton;
	IBOutlet NSBox*						repositoryPathBox;
	IBOutlet NSTextField*				theTitleText;
	IBOutlet NSTextField*				shortNameField;
	IBOutlet PathTextField*				pathField;
	
	SidebarNode*		nodeToConfigure;			// If we are configuring a node, this is the one to configure
	SidebarNode*		addNewRepositoryRefTo;		// If we are creating a new RepositoryRef add it after this RepositoryRef
	NSInteger			addNewRepositoryRefAtIndex;	// If we are creating a new RepositoryRef add it after this RepositoryRef
}

@property (weak,readonly) MacHgDocument* myDocument;
@property NSString*	  shortNameFieldValue;
@property NSString*	  pathFieldValue;

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


@interface PathTextField : NSTextField
@end