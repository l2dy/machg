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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  HistoryViewController
// ------------------------------------------------------------------------------------
// MARK: -

@interface HistoryViewController : NSViewController

@property (weak,readonly) MacHgDocument*	myDocument;
@property HistoryView*	theHistoryView;

- (HistoryViewController*) initHistoryViewControllerWithDocument:(MacHgDocument*)doc;
- (void) unload;
@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  HistoryView
// ------------------------------------------------------------------------------------
// MARK: -

@interface HistoryView : NSView <AccessesDocument, ControllerForLogTableView, ControllerForLabelsTableView, NSUserInterfaceValidations >
{

	// Main concertina view containing the sub panes.
	IBOutlet JHConcertinaView*	concertinaView;
	
	// Details SubPane
	IBOutlet NSView*			detailsView;
	IBOutlet LogTableTextView*	detailedEntryTextView;
	
	// Labels SubPane
	IBOutlet LabelsTableView*	theLabelsTableView_;
	IBOutlet NSButton*			removeLabelButton;

}

@property (weak,readonly) MacHgDocument*			myDocument;
@property (assign) IBOutlet HistoryViewController*	parentController;
@property (readonly) IBOutlet LogTableView*			logTableView;			// History SubPane


// Initializations
- (void)	 unload;
- (void)	 prepareToOpenHistoryView;


// Notifications & Updating
- (NSString*) searchCaption;
- (IBAction) refreshHistoryView:(id)sender;
- (IBAction) resetHistoryView:(id)sender;
- (IBAction) forceReinitilizeHistoryViews:(id)sender;
- (void)	 restoreConcertinaSplitViewPositions;
- (void)	 scrollToSelected;
- (void)	 expandLabelsTableinConcertina;
- (void)	 manageLabelsOfType:(LabelType)labelType;


// Menu Actions
- (IBAction) mainMenuCommitAllFiles:(id)sender;
- (IBAction) toolbarCommitFiles:(id)sender;
- (IBAction) mainMenuDiffAllFiles:(id)sender;
- (IBAction) toolbarDiffFiles:(id)sender;

- (IBAction) mainMenuRevertAllFiles:(id)sender;
- (IBAction) toolbarRevertFiles:(id)sender;


// Button Actions
- (IBAction) historyMenuDiffSelectedRevisions:(id)sender;


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
- (IBAction) mainMenuAlterDetails:(id)sender;
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
