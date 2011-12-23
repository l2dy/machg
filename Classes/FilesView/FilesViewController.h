//
//  FilesViewController.h
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "FSViewer.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilesViewController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface FilesViewController : NSViewController
{
	MacHgDocument*			myDocument;
	IBOutlet FilesView*		theFilesView;
}
@property (readwrite,assign) MacHgDocument*	myDocument;
@property (readwrite,assign) FilesView*	theFilesView;

- (FilesViewController*) initFilesViewControllerWithDocument:(MacHgDocument*)doc;
- (void) unload;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilesView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface FilesView : NSView <AccessesDocument, ControllerForFSViewer, NSUserInterfaceValidations>
{
	IBOutlet FilesViewController* parentContoller;
	IBOutlet FSViewer*		theFSViewer;
	IBOutlet NSImageView*	nodeIconWell;	// Image well showing the selected items icon.
	IBOutlet NSTextField*	nodeInspector;	// Text field showing the selected items attributes.
	MacHgDocument*			myDocument;
	BOOL					awake_;			// Ensure awakeFromNib fires only once
}

@property (readwrite,assign) MacHgDocument*	myDocument;
@property (readonly,assign)  FSViewer*		theFSViewer;

- (void)	 unload;
- (void)	 prepareToOpenFilesView;
- (NSInteger) numberOfQuickLookPreviewItems;

- (IBAction) refreshBrowserContent:(id)sender;


// Actions
- (IBAction) browserAction:(id)browser;			// Respond to a single click or a key down event
- (IBAction) browserDoubleAction:(id)browser;	// Respond to a double click

- (IBAction) mainMenuCommitSelectedFiles:(id)sender;
- (IBAction) mainMenuCommitAllFiles:(id)sender;
- (IBAction) toolbarCommitFiles:(id)sender;

- (IBAction) mainMenuDiffSelectedFiles:(id)sender;
- (IBAction) mainMenuDiffAllFiles:(id)sender;
- (IBAction) toolbarDiffFiles:(id)sender;

- (IBAction) mainMenuAddRenameRemoveSelectedFiles:(id)sender;
- (IBAction) mainMenuAddRenameRemoveAllFiles:(id)sender;
- (IBAction) toolbarAddRenameRemoveFiles:(id)sender;

- (IBAction) mainMenuDeleteSelectedFiles:(id)sender;
- (IBAction) mainMenuAddSelectedFiles:(id)sender;
- (IBAction) mainMenuUntrackSelectedFiles:(id)sender;
- (IBAction) mainMenuRenameSelectedItem:(id)sender;

- (IBAction) mainMenuRevertSelectedFiles:(id)sender;
- (IBAction) mainMenuRevertAllFiles:(id)sender;
- (IBAction) mainMenuRevertSelectedFilesToVersion:(id)sender;
- (IBAction) toolbarRevertFiles:(id)sender;


- (IBAction) mainMenuIgnoreSelectedFiles:(id)sender;
- (IBAction) mainMenuUnignoreSelectedFiles:(id)sender;
- (IBAction) mainMenuAnnotateSelectedFiles:(id)sender;


// Contextual Menu Actions
- (IBAction) mainMenuOpenSelectedFilesInFinder:(id)sender;
- (IBAction) mainMenuRevealSelectedFilesInFinder:(id)sender;
- (IBAction) mainMenuOpenTerminalHere:(id)sender;

@end
