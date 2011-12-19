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

@end
