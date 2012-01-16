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

@interface FilesView : NSView <AccessesDocument, ControllerForFSViewer, NSUserInterfaceValidations, NSWindowDelegate>
{
	IBOutlet FilesViewController* parentContoller;
	IBOutlet FSViewer*		theFSViewer;
	IBOutlet StatusSidebarSplitView*	statusSidebarSplitView;
	IBOutlet JHConcertinaView*	concertinaView;	// Main concertina view containing the sub panes.
	IBOutlet NSImageView*	nodeIconWell;		// Image well showing the selected items icon.
	IBOutlet NSTextField*	nodeInspector;		// Text field showing the selected items attributes.
	IBOutlet NSButton*		FilesViewBrowserSegement;
	IBOutlet NSButton*		FilesViewOutlineSegement;
	IBOutlet NSButton*		FilesViewTableSegement;
	IBOutlet NSButton*		DifferencesViewTogglePreferences;
	MacHgDocument*			myDocument;
	
	IBOutlet NSView*		preferencesViewForAttachedWindow;
    MAAttachedWindow*		attachedDifferencesPreferenceWindow;
}

@property (readwrite,assign) MacHgDocument*	myDocument;
@property (readonly,assign)  FSViewer*		theFSViewer;

- (void)	 unload;
- (void)	 prepareToOpenFilesView;
- (NSInteger) numberOfQuickLookPreviewItems;

- (void)	 updateFilesViewButtonSelector;
- (void)	 didSwitchViewTo:(FSViewerNum)viewNumber;
- (IBAction) refreshBrowserContent:(id)sender;
- (void)	 restoreConcertinaSplitViewPositions;


// Actions
- (IBAction) browserAction:(id)browser;			// Respond to a single click or a key down event
- (IBAction) browserDoubleAction:(id)browser;	// Respond to a double click
- (IBAction) differencesDisplayPreferencesChanged:(id)sender;	// Respond to a change in the display preferences
- (IBAction) toggleAttachedDifferencesPreferencesWindow:(id)sender;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  StatusSidebar
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface StatusSidebarSplitView : NSSplitView <NSSplitViewDelegate, NSAnimationDelegate>
{
	IBOutlet NSView*		theContent;
	IBOutlet NSView*		theSidebar;

	IBOutlet NSBox*			statusSidebarContent;
	IBOutlet NSView*		expandedStatusSidebarGroup;
	IBOutlet NSView*		collapsedStatusSidebarGroup;
	IBOutlet NSButton*		toggleStatusSidebarButton;
	BOOL					minimized;
	NSViewAnimation*		viewAnimation;
}

- (IBAction) maximize:(id)sender;
- (IBAction) minimize:(id)sender;

@end