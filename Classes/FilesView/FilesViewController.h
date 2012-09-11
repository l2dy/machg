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
@class StatusSidebarSplitView;
@class MAAttachedWindow;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilesViewController
// ------------------------------------------------------------------------------------
// MARK: -

@interface FilesViewController : NSViewController

@property (weak,readonly) MacHgDocument*	myDocument;
@property IBOutlet FilesView*				theFilesView;

- (FilesViewController*) initFilesViewControllerWithDocument:(MacHgDocument*)doc;
- (void) unload;
@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  FilesView
// ------------------------------------------------------------------------------------
// MARK: -

@interface FilesView : NSView <AccessesDocument, ControllerForFSViewer, NSUserInterfaceValidations>
{
	IBOutlet StatusSidebarSplitView*	statusSidebarSplitView;
	IBOutlet JHConcertinaView*			concertinaView;		// Main concertina view containing the sub panes.
	IBOutlet NSImageView*				nodeIconWell;		// Image well showing the selected items icon.
	IBOutlet NSTextField*				nodeInspector;		// Text field showing the selected items attributes.
}

@property (weak,readonly) MacHgDocument*			myDocument;
@property (assign) IBOutlet FilesViewController*	parentContoller;
@property (readonly) IBOutlet FSViewer*				theFSViewer;

- (void)	 unload;
- (void)	 prepareToOpenFilesView;
- (NSInteger) numberOfQuickLookPreviewItems;

- (void)	 didSwitchViewTo:(FSViewerNum)viewNumber;
- (IBAction) refreshBrowserContent:(id)sender;
- (void)	 restoreConcertinaSplitViewPositions;


// Actions
- (IBAction) fsviewerAction:(id)browser;					// Respond to a single click or a key down event
- (IBAction) fsviewerDoubleAction:(id)browser;				// Respond to a double click

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  StatusSidebar
// ------------------------------------------------------------------------------------
// MARK: -

@interface StatusSidebarSplitView : NSSplitView <NSSplitViewDelegate, NSAnimationDelegate>
{
	IBOutlet FilesView* __weak	parentView;
	IBOutlet NSView*		theContent;
	IBOutlet NSView*		theSidebar;

	IBOutlet NSBox*			statusSidebarContent;
	IBOutlet NSView*		expandedStatusSidebarGroup;
	IBOutlet NSButton*		toggleStatusSidebarButton;
	IBOutlet NSBox*			dividerStatusBox;	
	BOOL					minimized;
	NSViewAnimation*		viewAnimation;
}

- (IBAction) maximize:(id)sender;
- (IBAction) minimize:(id)sender;

@end