//
//  HistoryViewController.h
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "LogTableView.h"
#import "LabelsTableView.h"
#import "LogGraph.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HistoryViewController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface HistoryViewController : NSViewController
{
	MacHgDocument*			myDocument;
	IBOutlet HistoryView*	theHistoryView;
}
@property (readwrite,assign) MacHgDocument*	myDocument;
@property (readwrite,assign) HistoryView*	theHistoryView;

- (HistoryViewController*) initHistoryViewControllerWithDocument:(MacHgDocument*)doc;
- (void) unload;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  HistoryView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface HistoryView : NSView <AccessesDocument, ControllerForLogTableView, ControllerForLabelsTableView, NSUserInterfaceValidations >
{
	MacHgDocument*				myDocument;
	IBOutlet HistoryViewController*  parentController;

	// Main concertina view containing the sub panes.
	IBOutlet JHConcertinaView*	concertinaView;
	
	// History SubPane
	IBOutlet LogTableView*		logTableView;

	// Details SubPane
	IBOutlet NSView*			detailsView;
	IBOutlet LogTableTextView*	detailedEntryTextView;
	
	// Labels SubPane
	IBOutlet LabelsTableView*	theLabelsTableView_;
	IBOutlet NSButton*			removeLabelButton;

}

@property (readwrite,assign) MacHgDocument*	myDocument;
@property (readonly, assign) LogTableView*	logTableView;


// Initializations
- (void)	 unload;
- (void)	 prepareToOpenHistoryView;


// Notifications & Updating
- (NSString*) searchCaption;
- (IBAction) refreshHistoryView:(id)sender;
- (void)	 scrollToSelected;


// Menu Actions
- (IBAction) mainMenuCommitAllFiles:(id)sender;
- (IBAction) toolbarCommitFiles:(id)sender;
- (IBAction) mainMenuDiffAllFiles:(id)sender;
- (IBAction) toolbarDiffFiles:(id)sender;

- (IBAction) mainMenuRevertAllFiles:(id)sender;
- (IBAction) toolbarRevertFiles:(id)sender;


// Button Actions
- (IBAction) diffSelectedRevisions:(id)sender;


// LogTableView Contextual Menu
- (IBAction) historyMenuAddLabelToChosenRevision:(id)sender;
- (IBAction) historyMenuDiffAllToChosenRevision:(id)sender;
- (IBAction) historyMenuUpdateRepositoryToChosenRevision:(id)sender;
- (IBAction) historyMenuGotoChangeset:(id)sender;
- (IBAction) historyMenuMergeRevision:(id)sender;
- (IBAction) historyMenuManifestOfChosenRevision:(id)sender;
// -------
- (IBAction) historyMenuViewRevisionDifferences:(id)sender;
// -------
- (IBAction) mainMenuCollapseChangesets:(id)sender;
- (IBAction) mainMenuStripChangesets:(id)sender;
- (IBAction) mainMenuRebaseChangesets:(id)sender;
- (IBAction) mainMenuHistoryEditChangesets:(id)sender;
- (IBAction) mainMenuBackoutChangeset:(id)sender;

// LabelsTableView Contextual Menu
- (IBAction) labelsMenuMoveChosenLabel:(id) sender;
- (IBAction) labelsMenuRemoveChosenLabel:(id) sender;
- (IBAction) labelsMenuUpdateRepositoryToChosenRevision:(id)sender;


// Validation
- (BOOL)	validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
- (void)	labelsChanged;



@end
