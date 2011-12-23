//
//  Sidebar.m
//
//  Copyright 2009 Jason Harris. All rights reserved.
//  This was originally based on some code by Matteo Bertozzi on 3/8/09.
//  But its since been extensively modified beyond recognition of its original.
//
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface Sidebar : NSOutlineView <NSOutlineViewDelegate, NSOutlineViewDataSource>
{
	SidebarNode*			root_;
	IBOutlet MacHgDocument*	myDocument;
	IBOutlet NSMenu*		sidebarContextualMenu;
	IBOutlet NSTextView*	informationTextView_;
	IBOutlet NSPathControl* repositoryPathControl_;
	NSMutableDictionary*	outgoingCounts;
	NSMutableDictionary*	incomingCounts;

  @private
	SingleTimedQueue*		queueForAutomaticIncomingComputation_;
	SingleTimedQueue*		queueForAutomaticOutgoingComputation_;
	SingleTimedQueue*		queueForUpdatingInformationTextView_;
	NSArray*				dragNodesArray;
	BOOL					currentSelectionAllowsBadges_;
}

@property (nonatomic, assign) SidebarNode* root;

// Actions
- (IBAction)	mainMenuConfigureRepositoryRef:(id)sender;
- (IBAction)	mainMenuConfigureLocalRepositoryRef:(id)sender;
- (IBAction)	mainMenuConfigureServerRepositoryRef:(id)sender;
- (IBAction)	mainMenuAddNewSidebarGroupItem:(id)sender;
- (IBAction)	mainMenuRemoveSidebarItem:(id)sender;
- (IBAction)	mainMenuRemoveSidebarItems:(id)sender;
- (IBAction)	mainMenuRevealRepositoryInFinder:(id)sender;
- (IBAction)	mainMenuOpenTerminalHere:(id)sender;

- (IBAction)	contextualMenuAddLocalRepositoryRef:(id)sender;
- (IBAction)	contextualMenuAddServerRepositoryRef:(id)sender;
- (IBAction)	contextualMenuAddNewSidebarGroupItem:(id)sender;
- (IBAction)	contextualMenuConfigureRepositoryRef:(id)sender;
- (IBAction)	contextualMenuConfigureLocalRepositoryRef:(id)sender;
- (IBAction)	contextualMenuConfigureServerRepositoryRef:(id)sender;
- (IBAction)	contextualMenuAddNewSidebarGroupItem:(id)sender;
- (IBAction)	contextualMenuCloneRepositoryRef:(id)sender;
- (IBAction)	contextualMenuRemoveSidebarItem:(id)sender;
- (IBAction)	contextualMenuRemoveSidebarItems:(id)sender;
- (IBAction)	contextualMenuRevealRepositoryInFinder:(id)sender;
- (IBAction)	contextualMenuOpenTerminalHere:(id)sender;


- (IBAction)	reloadSidebarData:(id)sender;


// Add / delete Nodes
- (void) addSidebarNode:(SidebarNode*)newNode;
- (void) addSidebarNode:(SidebarNode*)newNode afterNode:(SidebarNode*)existingNode;
- (void) removeNodeFromSidebar:(SidebarNode*)node;
- (NSArray*) serversIfAvailable:(NSString*)file includingAlreadyPresent:(BOOL)includeAlreadyPresent;


// Access Selection Methods
- (BOOL) localRepoIsSelected;
- (BOOL) localRepoIsChosen;
- (BOOL) localOrServerRepoIsSelected;
- (BOOL) localOrServerRepoIsChosen;
- (BOOL) serverRepoIsSelected;
- (BOOL) multipleNodesAreSelected;
- (BOOL) multipleNodesAreChosen;
- (SidebarNode*) selectedNode;
- (SidebarNode*) chosenNode;
- (SidebarNode*) clickedNode;
- (NSArray*)	 selectedNodes;
- (NSArray*)	 chosenNodes;
- (SidebarNodeKind) combinedKindOfSelectedNodes;
- (SidebarNodeKind) combinedKindOfChosenNodes;
- (SidebarNode*)	 lastSectionNode;


// Modify Selection Methods
- (void) selectNode:(SidebarNode*)node;
- (void) selectNodes:(NSArray*)nodes;
- (void) setRootAndUpdate:(SidebarNode*)root;


// Expand/Collapse Methods
- (void) expandAll;
- (void) collapseAll;
- (void) restoreSavedExpandedness;


// Drawing
- (void) becomeMain;
- (void) resignMain;


// Saving and Loading
- (void) encodeWithCoder:(NSCoder*)coder;
- (id)   initWithCoder:(NSCoder*)coder;


// Connections
- (NSArray*)  allRepositories;
- (NSArray*)  allCompatibleRepositories:(SidebarNode*)selectedNode;
- (void)      removeConnectionsFor:(NSString*) deadPath;
- (void)	  computeIncomingOutgoingToCompatibleRepositories;
- (NSString*) outgoingCountTo:(SidebarNode*)destination;
- (NSString*) incomingCountFrom:(SidebarNode*)source;

@end

#define GroupItemExtraTopHeight		12.0
#define GroupItemExtraBottomDepth	 5.0
