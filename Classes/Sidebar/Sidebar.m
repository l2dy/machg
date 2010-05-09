//
//  SidebarNode.m
//  Sidebar
//  Original version created by Matteo Bertozzi on 3/8/09.
//  Copyright 2009 Matteo Bertozzi. All rights reserved.
//  Extensive modifications made by Jason Harris 29/11/09.
//  Copyright 2009 Jason Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt

#import "SidebarCell.h"
#import "SidebarNode.h"
#import "Sidebar.h"
#import "Common.h"
#import "MacHgDocument.h"
#import "CloneSheetController.h"
#import "RepositoryData.h"
#import "LogEntry.h"
#import "LocalRepositoryRefSheetController.h"
#import "TaskExecutions.h"
#import "AppController.h"
#import "SingleTimedQueue.h"
#import "NSString+SymlinksAndAliases.h"
#import "ShellHere.h"

@interface Sidebar (PrivateMethods)
- (void) updateInformationTextView;
@end

@implementation Sidebar

@synthesize root = root_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Constructors/Destructors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	queueForAutomaticIncomingComputation_ = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue() withTimeDelay:2.0 descriptiveName:@"queueForAutomaticIncomingComputation"];	// Our auto computations start after 2.0 seconds
	queueForAutomaticOutgoingComputation_ = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue() withTimeDelay:2.0 descriptiveName:@"queueForAutomaticOutgoingComputation"];	// Our auto computations start after 2.0 seconds

	root_ = [SidebarNode sectionNodeWithCaption:kSidebarRootInitializationDummy];
	[self observe:kUnderlyingRepositoryChanged		 from:myDocument  byCalling:@selector(underlyingRepositoryDidChange)];
	[self observe:kCompatibleRepositoryChanged		 from:myDocument  byCalling:@selector(computeIncomingOutgoingToCompatibleRepositories)];
	[self observe:kReceivedCompatibleRepositoryCount from:myDocument  byCalling:@selector(reloadData)];
	[self observe:kLogEntriesDidChange				 from:myDocument  byCalling:@selector(logEntriesDidChange:)];

	// Scroll to the top in case the outline contents is very long
	[[[self enclosingScrollView] verticalScroller] setFloatValue:0.0];
	[[[self enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0, 0)];
	[self setBackgroundColor:[NSColor colorWithCalibratedRed:0.72 green:0.74 blue:0.79 alpha:1.0]];
	
	// Make outline view appear with gradient selection, and behave like the Finder, iTunes, etc.
	[self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	
	// drag and drop support
	[self registerForDraggedTypes:[NSArray arrayWithObjects:kSidebarPBoardType, NSFilenamesPboardType, nil]];

	// Set repository path control default string
	[repositoryPathControl_ setURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
	[repositoryPathControl_ setDoubleAction:@selector(pathControlDoubleClickAction:)];
	[repositoryPathControl_ setTarget:self];

	// Set up Delegates & Data Source
	[self setDataSource:self];
	[self setDelegate:self];
}


- (void) setRoot:(SidebarNode*)root
{
	root_ = root;
}

- (void) selectNode:(SidebarNode*)node
{
	if (node)
		[self selectRow:[self rowForItem:node]];
}

// This method is used when we are undoing / redoing things. Its cheating a bit since I could introduce more targeted lightweight
// changes to the sidebar tree. However the whole size of the sidebar tree should be small. Something like:90 bytes per node, and
// then the NSMutableArray in there and so on. Maybe 1K or 2K bytes for a whole tree so I am not going to sweat this.
- (void) setRootAndUpdate:(SidebarNode*)root
{
	NSUndoManager* undoer = [self undoManager];
	if ([undoer isUndoing] || [undoer isRedoing])
		[[self prepareUndoWithTarget:self] setRootAndUpdate:root_];
	root_ = root;
	[self reloadData];
	[self restoreSavedExpandedness];
	[self reloadData];
	[self setNeedsDisplay:YES];
}


- (void) underlyingRepositoryDidChange
{
	[self updateInformationTextView];
	[self computeIncomingOutgoingToCompatibleRepositories];
}

- (void) logEntriesDidChange:(NSNotification*)notification
{
	NSString* changeType = [[notification userInfo] objectForKey:kLogEntryChangeType];
	if ([changeType isEqualTo:kLogEntryTagsChanged] || [changeType isEqualTo:kLogEntryBranchesChanged] || [changeType isEqualTo:kLogEntryBookmarksChanged] || [changeType isEqualTo:kLogEntryOpenHeadsChanged])
		[self updateInformationTextView];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Selection Queries
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BOOL) selectedNodeIsLocalRepositoryRef	{ return [[self selectedNode] isLocalRepositoryRef]; }
- (BOOL) selectedNodeIsServerRepositoryRef	{ return [[self selectedNode] isServerRepositoryRef]; }
- (SidebarNode*) selectedNode				{ return [self itemAtRow:[self selectedRow]]; }
- (SidebarNode*) chosenNode					{ return [self itemAtRow:[self chosenRow]]; }
- (SidebarNode*) clickedNode				{ return [self rowWasClicked] ? [self chosenNode] : nil; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Expand/Collapse
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) expandAll    { [super expandItem:nil expandChildren:YES]; }
- (void) collapseAll  { [super collapseItem:nil collapseChildren:YES]; }

// Once a sidebar is loaded we can restore this state of "expandedness" of the nodes of the side bar to match the state they were saved in.
- (void) restoreSavedExpandednessRecursive:(SidebarNode*)node
{
	if ([node isExpanded])
		[super expandItem:node expandChildren:NO];
	for (SidebarNode* childNode in [node children])
		[self restoreSavedExpandednessRecursive:childNode];
}


- (void) restoreSavedExpandedness { [self restoreSavedExpandednessRecursive:root_]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Data Source Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id)        outlineView:(NSOutlineView*)outlineView  child:(NSInteger)index  ofItem:(id)item	{ return item ? [item childNodeAtIndex:index] : [root_ childNodeAtIndex:index]; }
- (BOOL)      outlineView:(NSOutlineView*)outlineView  isItemExpandable:(id)item				{ return item ? ![item isRepositoryRef] : YES; }
- (NSInteger) outlineView:(NSOutlineView*)outlineView  numberOfChildrenOfItem:(id)item			{ return item ? [item numberOfChildren] : [root_ numberOfChildren]; }
- (id)        outlineView:(NSOutlineView*)outlineView  objectValueForTableColumn:(NSTableColumn*)tableColumn  byItem:(id)item	{ return [item shortName]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSCell*) outlineView:(NSOutlineView*)outlineView  dataCellForTableColumn:(NSTableColumn*)tableColumn item:(id)item	{ return [tableColumn dataCell]; }
- (BOOL)	outlineView:(NSOutlineView*)outlineView  shouldEditTableColumn:(NSTableColumn*)tableColumn  item:(id)item   { return YES; }
- (BOOL)	outlineView:(NSOutlineView*)outlineView  shouldSelectItem:(id)item											{ return YES; }
- (BOOL)	outlineView:(NSOutlineView*)outlineView  isGroupItem:(id)item												{ return ![item isRepositoryRef]; }
- (void)	outlineView:(NSOutlineView*)outlineView  willDisplayCell:(NSCell*)cell  forTableColumn:(NSTableColumn*)tableColumn  item:(id)item
{
	if ([cell isKindOfClass:[SidebarCell class]])
	{
		SidebarCell* badgeCell = (SidebarCell*) cell;
		SidebarNode* node = ExactDynamicCast(SidebarNode,item);
		SidebarNode* selectedNode = [self selectedNode];
		NSString* outgoingCount = [outgoingCounts objectForKey:[node path]];
		NSString* incomingCount = [incomingCounts objectForKey:[node path]];
		if (node != selectedNode && outgoingCount && incomingCount)
		{
			NSString* badgeString = [NSString stringWithFormat:@"%@↓:%@↑",incomingCount, outgoingCount];
			[badgeCell setBadgeString:badgeString];
			[badgeCell setHasBadge:YES];
		}
		else if (node != selectedNode && [node isCompatibleTo:selectedNode])
		{
			[badgeCell setBadgeString:@" "];
			[badgeCell setHasBadge:YES];
		}
		else
		{
			[badgeCell setBadgeString:nil];
			[badgeCell setHasBadge:NO];
		}
		[badgeCell setIcon:[node icon]];
		if ([node nodeKind] != kSidebarNodeKindSection)
			[badgeCell setAttributedStringValue:[node attributedStringForNode]];
	}
}





- (void) outlineViewSelectionDidChange:(NSNotification*)notification
{
	SidebarNode* selectedNode = [self selectedNode];

	outgoingCounts = [[NSMutableDictionary alloc]init];				// reset the outgoing counts which will get recomputed below.
	incomingCounts = [[NSMutableDictionary alloc]init];				// reset the outgoing counts which will get recomputed below.

	[myDocument postNotificationWithName:kSidebarSelectionDidChange];
	[myDocument postNotificationWithName:kRepositoryRootChanged];	// We have switched to a new root (possibly a nil root)

	if (selectedNode == nil || [selectedNode nodeKind] == kSidebarNodeKindSection)
	{
		[myDocument actionSwitchViewToBackingPane:self];
		[repositoryPathControl_ setURL:[NSURL URLWithString:@""]];
		[[informationTextView_ textStorage] setAttributedString:[NSAttributedString string:@"" withAttributes:systemFontAttributes]];
		[self reloadData];
		return;
	}

	if ([selectedNode isLocalRepositoryRef])
	{
		NSString* dotHgPath = [[selectedNode path] stringByAppendingString:@"/.hg"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:dotHgPath])
		{
			[myDocument actionSwitchViewToBackingPane:self];
			[[informationTextView_ textStorage] setAttributedString:[NSAttributedString string:@"" withAttributes:systemFontAttributes]];
			[repositoryPathControl_ setURL:[NSURL URLWithString:@""]];
			[self reloadData];
			return;
		}
		[repositoryPathControl_ setURL:[NSURL fileURLWithPath:[selectedNode path]]];
		[self updateInformationTextView];
		[self computeIncomingOutgoingToCompatibleRepositories];
	}

	if ([selectedNode isServerRepositoryRef])
	{
		[repositoryPathControl_ setURL:[NSURL URLWithString:[selectedNode path]]];
		[self updateInformationTextView];
		[myDocument actionSwitchViewToBackingPane:self];
		[self computeIncomingOutgoingToCompatibleRepositories];
	}
	[self reloadData];
}


// Override these so we can save the state if a node is expanded or not.
- (void) outlineViewItemDidCollapse:(NSNotification*)notification
{
	SidebarNode* node = [[notification userInfo] objectForKey:@"NSObject"];
	[node setIsExpanded:NO];
}
- (void) outlineViewItemDidExpand:(NSNotification*)notification
{
	SidebarNode* node = [[notification userInfo] objectForKey:@"NSObject"];
	[node setIsExpanded:YES];
}


- (void) controlTextDidEndEditing:(NSNotification*)aNotification
{
	if ([aNotification object] != self)
		return;

	SidebarNode* selectedNode = [self selectedNode];
	NSText* fieldEditor = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
	NSString* newString = [NSString stringWithString:[fieldEditor string]];		// Important to make a copy here. Apple says:

	if (newString == [selectedNode shortName])
		return;
	
	// Allow undo here.
	[[self prepareUndoWithTarget:self] setRootAndUpdate:[root_ copyNodeTree]];
	[[self undoManager] setActionName:@"Name Change"];

	// Do name change
	[selectedNode setShortName:newString];
	[self reloadData];
	[myDocument postNotificationWithName:kSidebarSelectionDidChange];
}

- (void) pathControlDoubleClickAction:(id)sender
{
	NSPathComponentCell* cell = [repositoryPathControl_ clickedPathComponentCell];   
	NSString* thePath = [[cell URL] path];
	[[NSWorkspace sharedWorkspace] selectFile:thePath inFileViewerRootedAtPath:nil];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Delegates Drag & Drop
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal  { return NSDragOperationMove; }
- (BOOL) outlineView:(NSOutlineView*)outlineView  writeItems:(NSArray*)items  toPasteboard:(NSPasteboard*)pboard
{
	[pboard declareTypes:[NSArray arrayWithObjects:kSidebarPBoardType, nil] owner:self];
	
	// keep track of this nodes for drag feedback in "validateDrop"
	dragNodesArray = items;
	
	return YES;
}


- (NSDragOperation) outlineView:(NSOutlineView*)outlineView  validateDrop:(id<NSDraggingInfo>)info  proposedItem:(id)item  proposedChildIndex:(NSInteger)index
{
	if (index < 0)
		return NSDragOperationNone;

	NSPasteboard* pboard = [info draggingPasteboard];	// get the pasteboard
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
	{
		NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
		NSArray* resolvedFilenames = [filenames resolveSymlinksAndAliasesInPaths];
		for (NSString* file in resolvedFilenames)
			if (pathIsExistentDirectory(file))
				return NSDragOperationCopy;
		return NSDragOperationNone;
	}

	if (item == nil)
		return NSDragOperationGeneric;
	
	if (![item isDraggable] && index >= 0)
		return NSDragOperationMove;
	
	return NSDragOperationNone;
}


// If we are dragging a repository folder into the sidebar in the finder, check to see is the repository has a stored reference to
// the server and if the server is not present in the document then add it to the sidebar as well.
- (BOOL) addServerIfAvailableAndNotPresent:(NSString*)file  at:(SidebarNode*)targetParent index:(NSInteger)index
{
	// Look for a server in [paths].default
	NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"paths.default", nil];
	ExecutionResult result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:file];
	BOOL isServer = [result.outStr matchesRegex:@"^ssh|http|https://"	options:RKLMultiline];
	if (!isServer || IsNotEmpty(result.errStr))
		return NO;
	
	// If the server is already present in the document don't add it again.
	NSArray* allRepositories = [self allRepositories];
	for (SidebarNode* repo in allRepositories)
		if ([repo isServerRepositoryRef] && [[repo path] isEqualToString:result.outStr])
			return NO;
	
	SidebarNode* serverNode = [SidebarNode nodeWithCaption:[file lastPathComponent]  forServerPath:result.outStr];
	[targetParent insertChild:serverNode atIndex:index];
	return YES;
}


- (BOOL) outlineView:(NSOutlineView*)outlineView  acceptDrop:(id<NSDraggingInfo>)info  item:(id)targetItem  childIndex:(NSInteger)index
{
	NSPasteboard* pboard = [info draggingPasteboard];	// get the pasteboard

	SidebarNode* targetParent = targetItem;
	if (targetParent == nil)
		targetParent = root_;

	// user is doing an intra-app drag within the outline view
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kSidebarPBoardType]])
	{
		SidebarNode* currentSelectedNode = [self selectedNode];
		NSInteger adjIdx = 0;

		SidebarNode* copiedTree = [root_ copyNodeTree];
		[[self prepareUndoWithTarget:self] setRootAndUpdate:copiedTree];
		[[self undoManager] setActionName:@"Drag"];
		
		// Compute new offset
		for (NSInteger i = 0; i < [dragNodesArray count]; ++i)
		{
			SidebarNode* node = [dragNodesArray objectAtIndex:i];
			if ([node parent] == targetParent)
				if ([targetParent indexOfChildNode:node] < index)
					adjIdx--;
		}
		
		for (NSInteger i = 0; i < [dragNodesArray count]; ++i)
		{
			SidebarNode* node = [dragNodesArray objectAtIndex:i];
			[[node parent] removeChild:node];
		}

		NSInteger newTargetIndex = index + adjIdx;
		for (NSInteger i = [dragNodesArray count] -1; i >=0; i--)
		{
			SidebarNode* node = [dragNodesArray objectAtIndex:i];
			[targetParent insertChild:node atIndex:newTargetIndex];
		}

		[self reloadData];
		[self selectNode:currentSelectedNode];
		return YES;
	}

	// We are dragging files in from the finder.
	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]])
	{
		SidebarNode* copiedTree = [root_ copyNodeTree];
		[[self prepareUndoWithTarget:self] setRootAndUpdate:copiedTree];
		[[self undoManager] setActionName:@"Drag"];
		
		NSArray* filenames = [pboard propertyListForType:NSFilenamesPboardType];
		NSArray* resolvedFilenames = [filenames resolveSymlinksAndAliasesInPaths];
		SidebarNode* newSelectedNode = nil;
		for (id file in resolvedFilenames)
			if (pathIsExistentDirectory(file) && repositoryExistsAtPath(file))
			{
				SidebarNode* node = [SidebarNode nodeForLocalURL:file];
				[targetParent insertChild:node atIndex:index];
				[[AppController sharedAppController] computeRepositoryIdentityForPath:file];
				[self addServerIfAvailableAndNotPresent:file at:targetParent index:index];
				newSelectedNode = node;
			}

		for (id file in resolvedFilenames)
			if (pathIsExistentDirectory(file) && !repositoryExistsAtPath(file))
			{
				NSString* fileName = [[NSFileManager defaultManager] displayNameAtPath:file];
				[[myDocument theLocalRepositoryRefSheetController] openSheetForNewRepositoryRefNamed:fileName atPath:file addNewRepositoryRefTo:targetParent atIndex:index];
				return YES;
			}

		[self reloadData];
		if (newSelectedNode)
			[self selectNode:newSelectedNode];
		[self outlineViewSelectionDidChange:nil];
		return YES;
	}
	
	return NO;
}


- (NSUInteger) hitTestForEvent:(NSEvent*)event  inRect:(NSRect)cellFrame  ofView:(NSView*)controlView
{
	if ([controlView isKindOfClass:[Sidebar class]])
	{
		Sidebar* sidebar = (Sidebar*) controlView;
		SidebarNode* node = [sidebar selectedNode];
		if (![node isDraggable])
			return NSCellHitTrackableArea;
	}
	
	return NSCellHitContentArea;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  InformationTextView
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSAttributedString*) informationTextViewMessage:(SidebarNode*)node
{	
	NSMutableAttributedString* attrString = [NSMutableAttributedString string:@"Name: " withAttributes:smallGraySystemFontAttributes];
	[attrString appendAttributedString: [NSAttributedString string:[node shortName] withAttributes:smallSystemFontAttributes]];
	
	if ([node isExistentLocalRepositoryRef])
	{
		RepositoryData* repositoryData = [myDocument repositoryData];
		NSString* parentRevisions = [repositoryData getHGParentsRevisions];
		NSString* parentRevision  = [repositoryData getHGParent1Revision];
		if (!parentRevisions || !parentRevision)
			return attrString;
		LogEntry* parentEntry = [repositoryData entryForRevisionString: [repositoryData getHGParent1Revision]];
		NSArray*  tags        = [parentEntry tags];
		NSArray*  bookmarks   = [parentEntry bookmarks];
		NSString* branch      = [repositoryData getHGBranchName];
		
		if (IsNotEmpty(parentRevisions))
		{
			NSString* parentField = [repositoryData inMergeState] ? @"\nParents: " : @"\nParent: ";
			[attrString appendAttributedString: [NSAttributedString string:parentField     withAttributes:smallGraySystemFontAttributes]];
			[attrString appendAttributedString: [NSAttributedString string:parentRevisions withAttributes:smallSystemFontAttributes]];		
		}		
		if (IsNotEmpty(tags))
		{
			[attrString appendAttributedString: [NSAttributedString string:@"\nTags: " withAttributes:smallGraySystemFontAttributes]];
			[attrString appendAttributedString: [NSAttributedString string:[tags componentsJoinedByString:@", "] withAttributes:smallSystemFontAttributes]];		
		}
		if (IsNotEmpty(bookmarks))
		{
			NSString* bookmarksField = [bookmarks count] > 1 ? @"\nBookmarks: " : @"\nBookmark: ";
			[attrString appendAttributedString: [NSAttributedString string:bookmarksField withAttributes:smallGraySystemFontAttributes]];
			[attrString appendAttributedString: [NSAttributedString string:[bookmarks componentsJoinedByString:@", "] withAttributes:smallSystemFontAttributes]];		
		}
		if (IsNotEmpty(branch))
		{
			[attrString appendAttributedString: [NSAttributedString string:@"\nBranch: " withAttributes:smallGraySystemFontAttributes]];
			[attrString appendAttributedString: [NSAttributedString string:branch		 withAttributes:smallSystemFontAttributes]];		
		}
	}
	
	if (IsNotEmpty([node path]))
	{
		NSString* pathType;
		if      ([node isServerRepositoryRef]) pathType = @"\nURL: ";
		else if ([node isLocalRepositoryRef])  pathType = @"\nPath: ";
		else							       pathType = @"\n";
		
		[attrString appendAttributedString: [NSAttributedString string:pathType withAttributes:smallGraySystemFontAttributes]];
		[attrString appendAttributedString: [NSAttributedString string:[node path] withAttributes:smallSystemFontAttributes]];
	}
	return attrString;
}


- (void) updateInformationTextView
{
	SidebarNode* selectedNode = [self selectedNode];
	if ([selectedNode isRepositoryRef])
	{
		NSAttributedString* newInformativeMessage = [self informationTextViewMessage:selectedNode];
		dispatch_async(mainQueue(), ^{
			[[informationTextView_ textStorage] setAttributedString:newInformativeMessage];
		});
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: SideBar Contextual Menu Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

// The sidebarContextualMenu in the nib file has its delegate set to this sidebar. In menuNeedsUpdate, we dynamically update the
// menus based on the currently clicked upon row/column pair.
- (void) menuNeedsUpdate:(NSMenu*)theMenu
{
    if (theMenu == sidebarContextualMenu)
	{
		SidebarNode* node = [self clickedNode];
    
		// Remove all the items after the 3rd.
		int numberOfItems = [theMenu numberOfItems];
		for (int i = 3; i < numberOfItems; i++)
			[theMenu removeItemAtIndex:3];

        if (node != nil && [node isLocalRepositoryRef])
		{
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:[NSString stringWithFormat:@"Clone “%@”", [node shortName]]				action:@selector(mainMenuCloneRepository:)					keyEquivalent:@""];
			[theMenu addItemWithTitle:[NSString stringWithFormat:@"Configure “%@”", [node shortName]]			action:@selector(sidebarMenuConfigureLocalRepositoryRef:)	keyEquivalent:@""];
			[theMenu addItemWithTitle:[NSString stringWithFormat:@"Delete Reference “%@”", [node shortName]]	action:@selector(sidebarMenuRemoveSidebarItem:)				keyEquivalent:@""];
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:[NSString stringWithFormat:@"Reveal “%@” in Finder", [node shortName]]	action:@selector(sidebarMenuRevealRepositoryInFinder:)		keyEquivalent:@""];
			[theMenu addItemWithTitle:@"Open Terminal Here"														action:@selector(sidebarMenuOpenTerminalHere:)				keyEquivalent:@""];
			return;
		}

		if (node != nil && [node isServerRepositoryRef])
		{
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:[NSString stringWithFormat:@"Clone “%@”", [node shortName]]				action:@selector(mainMenuCloneRepository:)					keyEquivalent:@""];
			[theMenu addItemWithTitle:[NSString stringWithFormat:@"Configure “%@”", [node shortName]]			action:@selector(sidebarMenuConfigureServerRepositoryRef:)	keyEquivalent:@""];
			[theMenu addItemWithTitle:[NSString stringWithFormat:@"Delete Reference “%@”", [node shortName]]	action:@selector(sidebarMenuRemoveSidebarItem:)				keyEquivalent:@""];
			return;
		}

		if (node != nil)
		{
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:[NSString stringWithFormat:@"Delete Group “%@”", [node shortName]]		action:@selector(sidebarMenuRemoveSidebarItem:)				keyEquivalent:@""];
			return;
		}
    }
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  AddSidebarNode
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) addSidebarNode:(SidebarNode*)newNode
{
	SidebarNode* node = [self chosenNode];
	[self addSidebarNode:newNode afterNode:node];
}

- (void) addSidebarNode:(SidebarNode*)newNode afterNode:(SidebarNode*)existingNode
{
	if (!existingNode)
		existingNode = [self chosenNode];
	if (existingNode)
	{
		NSInteger existingIndex = [[existingNode parent] indexOfChildNode:existingNode];
		if (existingIndex != NSNotFound && [existingNode parent])
		{
			[[existingNode parent] insertChild:newNode atIndex:existingIndex + 1];
			[self reloadData];
			return;
		}
	}
	SidebarNode* node = [self lastSectionNode];
	if (!node)
		node = root_;
	[[node children] addObject:newNode];
	[newNode setParent:node];
	[self reloadData];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) reloadSidebarData:(id)sender							{ [self reloadData]; }

- (IBAction) sidebarMenuAddLocalRepositoryRef:(id)sender			{ [[myDocument  theLocalRepositoryRefSheetController]	openSheetForNewRepositoryRef]; }
- (IBAction) sidebarMenuAddServerRepositoryRef:(id)sender			{ [[myDocument theServerRepositoryRefSheetController]	openSheetForNewRepositoryRef]; }
- (IBAction) sidebarMenuConfigureLocalRepositoryRef:(id)sender		{ [[myDocument  theLocalRepositoryRefSheetController]	openSheetForConfigureRepositoryRef:[self chosenNode]]; }
- (IBAction) sidebarMenuConfigureServerRepositoryRef:(id)sender		{ [[myDocument theServerRepositoryRefSheetController]	openSheetForConfigureRepositoryRef:[self chosenNode]]; }


- (IBAction) sidebarMenuAddNewSidebarGroupItem:(id)sender
{
	[[self prepareUndoWithTarget:self] setRootAndUpdate:[root_ copyNodeTree]];
	[[self undoManager] setActionName:@"Add New Group"];

	SidebarNode* newGroupNode = [SidebarNode sectionNodeWithCaption:@"NEW GROUP"];
	
	if ([self numberOfSelectedRows] <= 0)
		[root_ insertChild:newGroupNode atIndex:[[root_ children] count]];
	else
	{
		SidebarNode* node = [self selectedNode];
		NSInteger index = [[node parent] indexOfChildNode:node] + 1;
		[[node parent] insertChild:newGroupNode atIndex:index];
	}
	[self reloadData];
}


- (IBAction) sidebarMenuRemoveSidebarItem:(id)sender
{
	SidebarNode* node = [self chosenNode];
	if (!node)
		return;

	BOOL deleteRepositoryAsWell = NO;
	if (DisplayWarningForRepositoryDeletionFromDefaults() && [node isExistentLocalRepositoryRef])
	{
		NSString* subMessage = [NSString stringWithFormat:@"Are you sure you want to delete the bookmark “%@”", [node shortName]];
		int result = RunCriticalAlertPanelOptionsWithSuppression( @"Delete Repository Bookmark", subMessage, @"Delete Bookmark", @"Cancel", @"Delete Bookmark and Repository", MHGDisplayWarningForRepositoryDeletion);
		if (result == NSAlertSecondButtonReturn)
			return;
		if (result == NSAlertThirdButtonReturn)
			deleteRepositoryAsWell = YES;
	}
	else if (DisplayWarningForRepositoryDeletionFromDefaults() && [node isServerRepositoryRef])
	{
		NSString* subMessage = [NSString stringWithFormat:@"Are you sure you want to delete the server bookmark “%@”", [node shortName]];
		int result = RunCriticalAlertPanelOptionsWithSuppression( @"Delete Repository Bookmark", subMessage, @"Delete Bookmark", @"Cancel", nil, MHGDisplayWarningForRepositoryDeletion);
		if (result == NSAlertSecondButtonReturn)
			return;
	}
	else if (DisplayWarningForRepositoryDeletionFromDefaults() && [node isSectionNode])
	{
		NSString* subMessage = [NSString stringWithFormat:@"Are you sure you want to delete the group “%@”", [node shortName]];
		int result = RunCriticalAlertPanelOptionsWithSuppression( @"Delete Group", subMessage, @"Delete Group", @"Cancel", nil, MHGDisplayWarningForRepositoryDeletion);
		if (result == NSAlertSecondButtonReturn)
			return;
	}
	else if (!DisplayWarningForRepositoryDeletionFromDefaults() && [node isExistentLocalRepositoryRef])
	{
		NSString* subMessage = [NSString stringWithFormat:@"The bookmark “%@” will be deleted. Do you also want to move to the trash the underlying repository located at: \n   %@", [node shortName],[node path]];
		NSInteger result = NSRunCriticalAlertPanel(@"Delete Repository?", subMessage, @"Leave Repository Alone", @"Delete Repository", nil);
		if (result == NSAlertAlternateReturn)
			deleteRepositoryAsWell = YES;
	}

	
	if (deleteRepositoryAsWell)
	{
		moveFilesToTheTrash([NSArray arrayWithObject:[node path]]);
		[myDocument removeAllUndoActionsForDocument];
		[myDocument updateChangeCount:NSChangeDone];
		[self removeConnectionsFor:[node path]];
		[[node parent] removeChild:node];
		[self deselectAll:self];
		[self reloadData];
		[myDocument actionSwitchViewToBackingPane:self];
		return;
	};
	

	[[self prepareUndoWithTarget:self] setRootAndUpdate:[root_ copyNodeTree]];									// With the undo restore the root node tree
	[[self undoManager] setActionName:@"Delete Item"];
	[[node parent] removeChild:node];
	if ([node isRepositoryRef])
	{
		NSMutableDictionary* connectionsCopy = [NSMutableDictionary dictionaryWithDictionary:[myDocument connections]];
		[[self prepareUndoWithTarget:myDocument] setConnections:connectionsCopy];
		[self removeConnectionsFor:[node path]];
	}
	[self deselectAll:self];
	[self reloadData];
	[myDocument actionSwitchViewToBackingPane:self];
}


- (IBAction) sidebarMenuRevealRepositoryInFinder:(id)sender
{
	SidebarNode* node = [self chosenNode];
	if (!node)
		return;
	
	NSString* thePath = [node path];
	[[NSWorkspace sharedWorkspace] selectFile:thePath inFileViewerRootedAtPath:nil];
}


- (IBAction) sidebarMenuOpenTerminalHere:(id)sender
{
	SidebarNode* node = [self chosenNode];
	if (!node)
	{
		PlayBeep();
		NSRunAlertPanel(@"No Bookmark Selected", @"You need to select a local bookmark", @"Ok", nil, nil);
		return;
	}

	if (![node isLocalRepositoryRef])
	{
		PlayBeep();
		NSRunAlertPanel(@"No Local Bookmark Selected", @"You need to select a local bookmark", @"Ok", nil, nil);
		return;
	}
	
	if (![node path])
	{
		PlayBeep();
		return;
	}
	OpenTerminalAt([node path]);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Saving and Loading
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:root_ forKey:@"sideBarRoot"];
}


- (id) initWithCoder:(NSCoder*)coder
{
	[super initWithCoder:coder];
	root_ = [coder decodeObjectForKey:@"sideBarRoot"];
	root_ = [root_ copyNodeTree];	// We do this to ensure the parent pointers are correct.
	return self;
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Section Nodes
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) allSectionNodesOf:(SidebarNode*)node storedIn:(NSMutableArray*)arr
{
	if ([node isSectionNode])
		[arr addObject:node];
	for (SidebarNode* child in [node children])
		[self allSectionNodesOf:child storedIn:arr];
}

// Produce a list of a reference of each section group in the sidebar tree
- (NSArray*) allSectionNodes
{
	NSMutableArray* arr = [[NSMutableArray alloc]init];
	[self allSectionNodesOf:root_ storedIn:arr];
	return arr;
}

- (SidebarNode*) lastSectionNode	{ return [[self allSectionNodes] lastObject]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: CompatibleRepositories
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) allRepositoriesOf:(SidebarNode*)node storedIn:(NSMutableArray*)arr
{
	if ([node isRepositoryRef])
		[arr addObject:[node copyNodeTree]];
	for (SidebarNode* child in [node children])
		[self allRepositoriesOf:child storedIn:arr];
}

// Produce a list of a copy of each repository in the sidebar tree
- (NSArray*) allRepositories
{
	NSMutableArray* arr = [[NSMutableArray alloc]init];
	[self allRepositoriesOf:root_ storedIn:arr];
	return arr;
}

- (NSArray*) allCompatibleRepositories:(SidebarNode*)selectedNode;
{
	NSMutableArray* compatibleRepositories = [[NSMutableArray alloc] init];
	NSArray* allRepositories = [self allRepositories];
	for (SidebarNode* repo in allRepositories)
		if ([repo isCompatibleTo:selectedNode])
			[compatibleRepositories addObject:repo];
	return compatibleRepositories;
}


- (NSArray*) orderedRepositoryListCompatibleTo:(SidebarNode*)node allowingAnyRepository:(BOOL)allowAnyRepository
{
	NSMutableArray* items = [NSMutableArray arrayWithArray:[node recentConnections]];
	
	NSArray* compatibleRepositories = node ? [self allCompatibleRepositories:node] : nil;
	for (SidebarNode* r in compatibleRepositories)
		if (![items containsObject:r])
			[items addObject:r];
	
	if (allowAnyRepository)
	{
		NSArray* allRepositories = [self allRepositories];
		for (SidebarNode* r in allRepositories)
			if (![items containsObject:r])
				[items addObject:r];
	}
	
	[items removeObject:node];
	return items;
}


- (void) removeConnectionsFor:(NSString*) deadPath
{
	NSMutableArray* allOfTheKeys = [NSMutableArray arrayWithArray:[[myDocument connections] allKeys]];
	for (NSString* key in allOfTheKeys)
		if ([key containsString:deadPath])
			[[myDocument connections] removeObjectForKey:key];
	[root_ pruneRecentConnectionsOf:deadPath];
}


- (NSString*) outgoingCountTo:(SidebarNode*)destination	{ return [outgoingCounts objectForKey:[destination path]]; }
- (NSString*) incomingCountFrom:(SidebarNode*)source	{ return [incomingCounts objectForKey:[source path]]; }


- (void) computeIncomingOutgoingToCompatibleRepositories
{
	SidebarNode* theSelectedNode  = [self selectedNode];
	NSString* rootPath = [theSelectedNode path];
	
	if (![theSelectedNode isExistentLocalRepositoryRef])
		return;

	// Normally there is a lot of mercurial stuff happening and processor load just after we call
	// computeIncomingOutgoingToCompatibleRepositories so to be nice to the processor we delay the computation of these things by
	// putting them in SingleTimedQueue's.


	[queueForAutomaticOutgoingComputation_ addBlockOperation:^{
		NSArray* compatibleRepositories = [self allCompatibleRepositories:theSelectedNode];
		for (SidebarNode* repo in compatibleRepositories)
		{
			__block NSTask* theTask = [[NSTask alloc]init];
			dispatchWithTimeOutBlock(globalQueue(), 30.0 /* try for 30 seconds to get result of "outgoing"*/,
									 
									 // Main Block
									 ^{
										 NSMutableArray* argsOutgoing = [NSMutableArray arrayWithObjects:@"outgoing", @"--quiet", @"--template", @"+", [repo path], nil];
										 ExecutionResult results = [TaskExecutions executeMercurialWithArgs:argsOutgoing  fromRoot:rootPath  logging:eLoggingNone  onTask:theTask];
										 dispatch_async(mainQueue(), ^{
											 if (![rootPath isEqualTo:[[self selectedNode] path]])
												 return;
											 if (IsEmpty(results.errStr))
												 [outgoingCounts setObject:intAsString([results.outStr length]) forKey:[repo path]];
											 else
												 [outgoingCounts setObject:@"-" forKey:[repo path]];
											 [self reloadData];
											 [myDocument postNotificationWithName:kReceivedCompatibleRepositoryCount];
										 });										 
									 },
									 
									 // Timeout Block
									 ^{
										 [theTask cancelTask];	// We timed out so kill the task which timed out...
										 dispatch_async(mainQueue(), ^{
											 if (![rootPath isEqualTo:[[self selectedNode] path]])
												 return;											 
											 [outgoingCounts setObject:@"-" forKey:[repo path]];
											 [self reloadData];
										 });										 
									 });
		}
	}];

	[queueForAutomaticIncomingComputation_ addBlockOperation:^{
		NSArray* compatibleRepositories = [self allCompatibleRepositories:theSelectedNode];
		for (SidebarNode* repo in compatibleRepositories)
		{
			__block NSTask* theTask = [[NSTask alloc]init];
			dispatchWithTimeOutBlock(globalQueue(), 30.0 /* try for 30 seconds to get result of "outgoing"*/,
									 
									 // Main Block
									 ^{
										 NSMutableArray* argsOutgoing = [NSMutableArray arrayWithObjects:@"incoming", @"--quiet", @"--template", @"-", [repo path], nil];
										 ExecutionResult results = [TaskExecutions executeMercurialWithArgs:argsOutgoing  fromRoot:rootPath  logging:eLoggingNone  onTask:theTask];
										 dispatch_async(mainQueue(), ^{
											 if (![rootPath isEqualTo:[[self selectedNode] path]])
												 return;
											 if (IsEmpty(results.errStr))
												 [incomingCounts setObject:intAsString([results.outStr length]) forKey:[repo path]];
											 else
												 [incomingCounts setObject:@"-" forKey:[repo path]];
											 [self reloadData];
											 [myDocument postNotificationWithName:kReceivedCompatibleRepositoryCount];
										 });										 
									 },
									 
									 // Timeout Block
									 ^{
										 [theTask cancelTask];	// We timed out so kill the task which timed out...
										 dispatch_async(mainQueue(), ^{
											 if (![rootPath isEqualTo:[[self selectedNode] path]])
												 return;											 
											 [incomingCounts setObject:@"-" forKey:[repo path]];
											 [self reloadData];
										 });										 
									 });
		}
	}];

}

@end

