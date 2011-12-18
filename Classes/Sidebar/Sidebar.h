//
//  SidebarNode.m
//  Sidebar
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
}

@property (nonatomic, assign) SidebarNode* root;

// Actions
- (IBAction)	sidebarMenuAddLocalRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuAddServerRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuConfigureRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuConfigureLocalRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuConfigureServerRepositoryRef:(id)sender;
- (IBAction)	sidebarMenuAddNewSidebarGroupItem:(id)sender;
- (IBAction)	sidebarMenuRemoveSidebarItem:(id)sender;
- (IBAction)	sidebarMenuRevealRepositoryInFinder:(id)sender;
- (IBAction)	sidebarMenuOpenTerminalHere:(id)sender;

- (IBAction)	reloadSidebarData:(id)sender;


// Addition of Nodes
- (void) addSidebarNode:(SidebarNode*)newNode;
- (void) addSidebarNode:(SidebarNode*)newNode afterNode:(SidebarNode*)existingNode;
- (NSArray*) serversIfAvailable:(NSString*)file includingAlreadyPresent:(BOOL)includeAlreadyPresent;


// Selection Methods
- (BOOL) selectedNodeIsLocalRepositoryRef;
- (BOOL) selectedNodeIsServerRepositoryRef;
- (void) selectNode:(SidebarNode*)node;
- (void) setRootAndUpdate:(SidebarNode*)root;
- (SidebarNode*) selectedNode;
- (SidebarNode*) chosenNode;				// If a node was clicked on (that triggered an action) then return
											// that, or else return the selected node
- (BOOL) multipleNodesAreSelected;
- (SidebarNode*) lastSectionNode;


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
