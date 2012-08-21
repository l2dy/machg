//
//  SidebarNode.m
//  Sidebar
//
//  Copyright 2009 Jason Harris. All rights reserved.
//  This was originally based on some code by Matteo Bertozzi on 3/8/09.
//  But its since been extensively modified beyond recognition of its original.
//
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt

#import "SidebarCell.h"
#import "SidebarNode.h"
#import "Sidebar.h"
#import "Common.h"
#import "MacHgDocument.h"
#import "CloneSheetController.h"
#import "RepositoryData.h"
#import "LogEntry.h"
#import "LabelData.h"
#import "LocalRepositoryRefSheetController.h"
#import "TaskExecutions.h"
#import "AppController.h"
#import "SingleTimedQueue.h"
#import "NSString+SymlinksAndAliases.h"
#import "ShellHere.h"
#import "CTBadge.h"
#include <sys/stat.h>


//
// For a nicer visual look I have made section node rows a little taller, and then to account for this space I override
// outlineView:heightOfRowByItem:, frameOfCellAtColumn:row:, frameOfOutlineCellAtRow: and offsetRectForSectionNode(...) 
//


#define NSMaxiumRange    ((NSRange){.location= 0UL, .length= NSUIntegerMax})

@interface Sidebar (PrivateMethods)
- (void) updateInformationTextView;
@end

@implementation Sidebar

@synthesize root = root_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Constructors/Destructors
// ------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	queueForAutomaticIncomingComputation_ = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue() withTimeDelay:2.0 descriptiveName:@"queueForAutomaticIncomingComputation"];	// Our auto computations start after 2.0 seconds
	queueForAutomaticOutgoingComputation_ = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue() withTimeDelay:2.0 descriptiveName:@"queueForAutomaticOutgoingComputation"];	// Our auto computations start after 2.0 seconds
	queueForUpdatingInformationTextView_  = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue() withTimeDelay:0.1 descriptiveName:@"queueForUpdatingInformationTextView"];	// Our updating of the info start after 0.1 seconds
	
	root_ = [SidebarNode sectionNodeWithCaption:kSidebarRootInitializationDummy];
	[self observe:kUnderlyingRepositoryChanged				from:myDocument  byCalling:@selector(underlyingRepositoryDidChange)];
	[self observe:kCompatibleRepositoryChanged				from:myDocument  byCalling:@selector(computeIncomingOutgoingToCompatibleRepositories)];
	[self observe:kReceivedCompatibleRepositoryCount		from:myDocument  byCalling:@selector(sidebarNodeDidChange:)];
	[self observe:kRepositoryDataIsNew						from:myDocument  byCalling:@selector(repositoryDataIsNew:)];
	[self observe:kRepositoryDataDidChange					from:myDocument  byCalling:@selector(repositoryDataDidChange:)];

	// Scroll to the top in case the outline contents is very long
	[[[self enclosingScrollView] verticalScroller] setFloatValue:0.0];
	[[[self enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0, 0)];
	

	// drag and drop support
	[self registerForDraggedTypes:@[kSidebarPBoardType, NSFilenamesPboardType]];

	// Set repository path control default string
	[repositoryPathControl_ setURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
	[repositoryPathControl_ setDoubleAction:@selector(pathControlDoubleClickAction:)];
	[repositoryPathControl_ setTarget:self];

	// Set up some appearance paramaeters
	[self setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];	// We do our own formatting so it looks like a source list
	[self setDraggingDestinationFeedbackStyle:NSTableViewDraggingDestinationFeedbackStyleSourceList];
	[self setRowHeight:[self rowHeight]+1.0];									// Tweak the row height a bit so it looks more like source lists.
	[self setIndentationPerLevel:13.0];
	
	// Set up Delegates & Data Source
	[self setDataSource:self];
	[self setDelegate:self];
	[self observe:kRepositoryIdentityChanged  from:nil  byCalling:@selector(computeIncomingOutgoingToCompatibleRepositories)];
}

- (void) setRoot:(SidebarNode*)root
{
	root_ = root;
}

- (void) underlyingRepositoryDidChange
{
	[self computeIncomingOutgoingToCompatibleRepositories];
}

- (void) repositoryDataIsNew:(NSNotification*)notification
{
	[self updateInformationTextView];
}

- (void) repositoryDataDidChange:(NSNotification*)notification
{
	[self updateInformationTextView];
}

- (void) sidebarNodeDidChange:(NSNotification*)notification
{
	NSString* nodePath = [notification userInfo][@"sidebarNodePath"];
	[self setNeedsDisplayForNodePath:nodePath];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Add / Remove nodes
// ------------------------------------------------------------------------------------

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
		SidebarNode* parent = [existingNode parent];
		if (existingIndex != NSNotFound && parent)
		{
			[parent insertChild:newNode atIndex:existingIndex + 1];
			[self reloadData];
			return;
		}
	}
	SidebarNode* node = [self lastSectionNode];
	if (!node)
		node = root_;
	[node addChild:newNode];
	[self reloadData];
}

- (void) removeNodeFromSidebar:(SidebarNode*)node
{
	// Remove all the children
	for (SidebarNode* childNode in [node children])
		[self removeNodeFromSidebar:childNode];

	// Remove this node
	SidebarNode* parent = [node parent];
	if ([node isRepositoryRef])
		[self removeConnectionsFor:[node path]];
	[parent removeChild:node];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Selection Queries
// ------------------------------------------------------------------------------------

- (BOOL) localRepoIsSelected			{ return [[self selectedNode] isLocalRepositoryRef]  && ![self multipleNodesAreSelected]; }
- (BOOL) localRepoIsChosen				{ return [[self chosenNode]   isLocalRepositoryRef]  && ![self multipleNodesAreChosen]; }
- (BOOL) serverRepoIsSelected			{ return [[self selectedNode] isServerRepositoryRef] && ![self multipleNodesAreSelected]; }
- (BOOL) serverRepoIsChosen				{ return [[self selectedNode] isServerRepositoryRef] && ![self multipleNodesAreChosen]; }
- (BOOL) localOrServerRepoIsSelected	{ return [[self selectedNode] isRepositoryRef]       && ![self multipleNodesAreSelected]; }
- (BOOL) localOrServerRepoIsChosen		{ return [[self chosenNode]   isRepositoryRef]       && ![self multipleNodesAreChosen]; }
- (SidebarNode*) selectedNode			{ return [self selectedItem]; }
- (SidebarNode*) chosenNode				{ return [self chosenItem]; }
- (SidebarNode*) clickedNode			{ return [self clickedItem]; }
- (NSArray*)     selectedNodes			{ return [self selectedItems]; }
- (NSArray*)     chosenNodes			{ return [self chosenItems]; }
- (BOOL) multipleNodesAreSelected		{ return [self numberOfSelectedRows] > 1; }
- (BOOL) multipleNodesAreChosen			{ return [self multipleNodesAreSelected] && [self isRowSelected:[self chosenRow]]; }

- (SidebarNodeKind) combinedKindOfSelectedNodes
{
	SidebarNodeKind kinds = 0;
	for (SidebarNode* node in [self selectedNodes])
		kinds = unionBits(kinds, [node nodeKind]);
	return kinds;
}
- (SidebarNodeKind) combinedKindOfChosenNodes
{
	SidebarNodeKind kinds = 0;
	for (SidebarNode* node in [self chosenNodes])
		kinds = unionBits(kinds, [node nodeKind]);
	return kinds;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Modify Selection Methods
// ------------------------------------------------------------------------------------

- (void) selectNode:(SidebarNode*)node	{ [self selectItem:node]; }
- (void) selectNodes:(NSArray*)nodes	{ [self selectItems:nodes]; }

// This method is used when we are undoing / redoing things. It's cheating a bit since I could introduce more targeted lightweight
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Expand/Collapse
// ------------------------------------------------------------------------------------

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Data Source Delegates
// ------------------------------------------------------------------------------------

- (id)        outlineView:(NSOutlineView*)outlineView  child:(NSInteger)index  ofItem:(id)item	{ return item ? [item childNodeAtIndex:index] : [root_ childNodeAtIndex:index]; }
- (BOOL)      outlineView:(NSOutlineView*)outlineView  isItemExpandable:(id)item				{ return YES; }
- (NSInteger) outlineView:(NSOutlineView*)outlineView  numberOfChildrenOfItem:(id)item			{ return item ? [item numberOfChildren] : [root_ numberOfChildren]; }
- (id)        outlineView:(NSOutlineView*)outlineView  objectValueForTableColumn:(NSTableColumn*)tableColumn  byItem:(id)item	{ return [item shortName]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Drawing Utilities
// ------------------------------------------------------------------------------------

static CGFloat extraHeightForSectionNode(NSInteger rowIndex)
{
	if (rowIndex == 0)
		return GroupItemExtraBottomDepth;
	return GroupItemExtraTopHeight + GroupItemExtraBottomDepth;
}

static NSRect offsetRectForSectionNode(NSRect r, NSInteger rowIndex)
{
	CGFloat extraTop = (rowIndex != 0) ? GroupItemExtraTopHeight : 0;
	r.size.height -= extraTop + GroupItemExtraBottomDepth + 2;
	r.origin.y += extraTop + 5;
	return r;
}

static void drawHorizontalLine(CGFloat x, CGFloat y, CGFloat w, NSColor* color)
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:0.0f];
	[path moveToPoint:NSMakePoint(x,   y)];
	[path lineToPoint:NSMakePoint(x+w, y)];
	[color set];
	[path stroke];	
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegates
// ------------------------------------------------------------------------------------

- (NSCell*) outlineView:(NSOutlineView*)outlineView  dataCellForTableColumn:(NSTableColumn*)tableColumn item:(id)item	{ return [tableColumn dataCell]; }
- (BOOL)	outlineView:(NSOutlineView*)outlineView  shouldEditTableColumn:(NSTableColumn*)tableColumn  item:(id)item   { return YES; }
- (BOOL)	outlineView:(NSOutlineView*)outlineView  shouldSelectItem:(id)item											{ return YES; }
- (BOOL)	outlineView:(NSOutlineView*)outlineView  isGroupItem:(id)item												{ return NO; }
- (CGFloat) outlineView:(NSOutlineView*)outlineView  heightOfRowByItem:(id)item											{ return 18 + ([item isTopLevelSectionNode] ? extraHeightForSectionNode([self rowForItem:item]) : 0); }

- (NSRect)frameOfCellAtColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex
{
	NSRect r = [super frameOfCellAtColumn:columnIndex row:rowIndex];
	SidebarNode* item = [self itemAtRow:rowIndex];
	r.origin.y += 2;
	r.origin.x += 3;
	return [item isTopLevelSectionNode] ? NSOffsetRect(offsetRectForSectionNode(r, rowIndex), 0,-1) : r;
}

- (NSRect) frameOfOutlineCellAtRow:(NSInteger)rowIndex
{
	NSRect r = [super frameOfOutlineCellAtRow:rowIndex];
	SidebarNode* item = [self itemAtRow:rowIndex];
	if ([item isRepositoryRef] && [item numberOfChildren] == 0)
		return NSZeroRect;
	return [item isTopLevelSectionNode] ? offsetRectForSectionNode(r, rowIndex) : r;
}

- (void)	outlineView:(NSOutlineView*)outlineView  willDisplayCell:(NSCell*)cell  forTableColumn:(NSTableColumn*)tableColumn  item:(id)item
{
	if ([cell isKindOfClass:[SidebarCell class]])
	{
		SidebarCell* sidebarCell = (SidebarCell*) cell;
		SidebarNode* node = ExactDynamicCast(SidebarNode,item);
		SidebarNode* selectedNode = [self selectedNode];
		[sidebarCell setNode:node];

		NSString* outgoingCount = outgoingCounts[[node path]];
		NSString* incomingCount = incomingCounts[[node path]];
		BOOL selected = [self isRowSelected:[self rowForItem:node]];
		BOOL exists = [node isLocalRepositoryRef] && repositoryExistsAtPath([node path]);
		BOOL allowedBadge = exists || [node isServerRepositoryRef];

		if (!selected && outgoingCount && incomingCount && currentSelectionAllowsBadges_ && allowedBadge)
		{
			NSString* badgeString = fstr(@"%@↓:%@↑",incomingCount, outgoingCount);
			[sidebarCell setBadgeString:badgeString];
			[sidebarCell setHasBadge:YES];
		}
		else if (!selected && [node isCompatibleTo:selectedNode] && currentSelectionAllowsBadges_ && allowedBadge)
		{
			[sidebarCell setBadgeString:@" "];
			[sidebarCell setHasBadge:YES];
		}
		else
		{
			[sidebarCell setBadgeString:nil];
			[sidebarCell setHasBadge:NO];
		}

		// If the icon disagrees with the repo being present or not then update it.
		if ([node isLocalRepositoryRef])
		{
			NSString* name = [[node icon] name];
			BOOL nameIsMissingRepository = [name isEqualToString:@"MissingRepository"];
			if ((exists && nameIsMissingRepository) || (!exists && !nameIsMissingRepository))
				[node refreshNodeIcon];
		}
		
		[sidebarCell setIcon:[node icon]];
		[sidebarCell setAttributedStringValue:[node attributedStringForNodeAndSelected:selected]];		
	}
}



- (void) drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
	static NSColor* fillStartingActiveColor = nil;
	static NSColor* fillEndingActiveColor   = nil;
	static NSColor* topBorderActiveColor    = nil;
	static NSColor* bottomBorderActiveColor = nil;
	static NSGradient* gradientActive = nil;

	static NSColor* fillStartingInactiveColor = nil;
	static NSColor* fillEndingInactiveColor   = nil;
	static NSColor* topBorderInactiveColor    = nil;
	static NSColor* bottomBorderInactiveColor = nil;
	static NSGradient* gradientInactive = nil;
	
	if (!fillStartingActiveColor)
	{
		fillStartingActiveColor   = rgbColor255(127, 184, 233);
		fillEndingActiveColor     = rgbColor255( 77, 132, 210);
		topBorderActiveColor      = rgbColor255(108, 163, 222);
		bottomBorderActiveColor   = rgbColor255( 71, 119, 193);
		gradientActive            = [[NSGradient alloc] initWithStartingColor:fillStartingActiveColor endingColor:fillEndingActiveColor];

		fillStartingInactiveColor = rgbColor255(197, 203, 224);
		fillEndingInactiveColor   = rgbColor255(159, 169, 197);
		topBorderInactiveColor    = rgbColor255(189, 197, 215);
		bottomBorderInactiveColor = rgbColor255(150, 159, 186);
		gradientInactive          = [[NSGradient alloc] initWithStartingColor:fillStartingInactiveColor endingColor:fillEndingInactiveColor];
	}

	SidebarNode* node = [self itemAtRow:rowIndex];

	if ([node isSectionNode])
	{
		NSColor* backColor = [self backgroundColor];
		NSRect bounds = [self rectOfRow:rowIndex];
		[backColor set];
		[NSBezierPath fillRect:bounds];
	}
	
	if ([[self selectedRowIndexes] containsIndex:rowIndex])
	{
		BOOL active = [[[myDocument mainWindow] firstResponder] hasAncestor:self];	// We display active if we are in the rsponde chain
		NSRect cellBounds = [self rectOfRow:rowIndex];
		NSRect bounds =  [node isTopLevelSectionNode] ? offsetRectForSectionNode(cellBounds, rowIndex) : cellBounds;
		[(active ? gradientActive : gradientInactive) drawInRect:bounds angle:90];
		drawHorizontalLine(bounds.origin.x, bounds.origin.y + 0.5,						bounds.size.width, active ?    topBorderActiveColor :    topBorderInactiveColor);
		drawHorizontalLine(bounds.origin.x, bounds.origin.y + bounds.size.height - 0.5, bounds.size.width, active ? bottomBorderActiveColor : bottomBorderInactiveColor);
	}

	[super drawRow:rowIndex clipRect:clipRect];
}



- (void) outlineViewSelectionDidChange:(NSNotification*)notification
{
	SidebarNode* selectedNode = [self selectedNode];
	
	outgoingCounts = [[NSMutableDictionary alloc]init];				// reset the outgoing counts which will get recomputed below.
	incomingCounts = [[NSMutableDictionary alloc]init];				// reset the outgoing counts which will get recomputed below.

	[myDocument postNotificationWithName:kSidebarSelectionDidChange];
	[myDocument postNotificationWithName:kRepositoryRootChanged];	// We have switched to a new root (possibly a nil root)

	SidebarNode* node = [self selectedNode];
	currentSelectionAllowsBadges_ = ![self multipleNodesAreSelected] && node && ![node isMissingLocalRepositoryRef];
	
	if (selectedNode == nil || [selectedNode nodeKind] == kSidebarNodeKindSection || [self multipleNodesAreSelected])
	{
		[myDocument discardCurrentRepository];
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
			[myDocument discardCurrentRepository];
			[[informationTextView_ textStorage] setAttributedString:[NSAttributedString string:@"" withAttributes:systemFontAttributes]];
			[repositoryPathControl_ setURL:[NSURL URLWithString:@""]];
			[self reloadData];
			return;
		}
		[repositoryPathControl_ setURL:[NSURL fileURLWithPath:[selectedNode path]]];
		[[myDocument mainWindow] setRepresentedURL:[NSURL fileURLWithPath:dotHgPath]];
		[[AppController sharedAppController] computeRepositoryIdentityForPath:[selectedNode path]];
		[self computeIncomingOutgoingToCompatibleRepositories];
	}

	if ([selectedNode isServerRepositoryRef])
	{
		[repositoryPathControl_ setURL:[NSURL URLWithString:[selectedNode path]]];
		[self updateInformationTextView];
		[myDocument discardCurrentRepository];
		[self computeIncomingOutgoingToCompatibleRepositories];
	}
	[self reloadData];
}


// Override these so we can save the state if a node is expanded or not.
- (void) outlineViewItemDidCollapse:(NSNotification*)notification
{
	SidebarNode* node = [notification userInfo][@"NSObject"];
	[node setIsExpanded:NO];
}
- (void) outlineViewItemDidExpand:(NSNotification*)notification
{
	SidebarNode* node = [notification userInfo][@"NSObject"];
	[node setIsExpanded:YES];
}


- (void) controlTextDidEndEditing:(NSNotification*)aNotification
{
	if ([aNotification object] != self)
		return;

	SidebarNode* selectedNode = [self selectedNode];
	NSText* fieldEditor = [aNotification userInfo][@"NSFieldEditor"];
	NSString* newString = [[fieldEditor string] copy];		// Important to make a copy here. Apple says:

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Drag & Drop Helpers
// ------------------------------------------------------------------------------------

// If we are adding a local repository to the document, check to see is the repository has a stored reference to the server and if
// the server is not present in the document then return a server node which can be added to the document as well.
- (NSArray*) serversIfAvailable:(NSString*)file includingAlreadyPresent:(BOOL)includeAlreadyPresent
{
	// Look for a server in [paths].default
	NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"paths", nil];
	ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:file];
	
	NSArray* paths = [result.outStr arrayOfCaptureComponentsMatchedByRegex:@"^paths\\.((?:[\\w-]+))\\s*=\\s*((?:ssh|http|https)://.*?)$" options:RKLMultiline range:NSMaxiumRange error:NULL];
	if ([paths count] == 0 || [result hasErrors])
		return nil;
	
	NSMutableArray* serversToAdd = [[NSMutableArray alloc]init];
	NSMutableArray* allRepositories = [NSMutableArray arrayWithArray:[self allRepositories]];
	NSString* captionBase = [file lastPathComponent];
	for (NSArray* path in paths)
	{
		NSString* serverId = trimString(path[1]);
		NSString* serverPath = path[2];
		NSString* url = trimmedURL(serverPath);
		
		// If the server is already present in the document don't add it again.
		BOOL isDefaultServer     = [serverId isEqualToString:@"default"];
		BOOL isDefaultPushServer = [serverId isEqualToString:@"default-push"];
		
		if (!isDefaultServer && !isDefaultPushServer)
			continue;
		BOOL duplicate = NO;
		if (!includeAlreadyPresent)
			for (SidebarNode* repo in allRepositories)
				if ([repo isServerRepositoryRef] && [trimmedURL([repo path]) isEqualToString:url])
				{
					duplicate = YES;
					break;
				}
		if (duplicate)
			continue;
		
		NSString* caption = isDefaultPushServer ? fstr(@"%@ (push)", captionBase) : captionBase;
		SidebarNode* serverNode = [SidebarNode nodeWithCaption:caption forServerPath:serverPath];
		[[AppController sharedAppController] computeRepositoryIdentityForPath:serverPath];
		if (isDefaultServer)
			[serversToAdd insertObject:serverNode atIndex:0];
		else
			[serversToAdd addObject:serverNode];
		[allRepositories addObject:serverNode];
	}
	return serversToAdd;
}


- (void) emmbedAnyNestedRepositoriesForPath:(NSString*)enclosingPath atNode:(SidebarNode*)node
{
	NSFileManager* localFileManager = [[NSFileManager alloc] init];
	NSDirectoryEnumerator* dirEnum = [localFileManager enumeratorAtPath:enclosingPath];
	
	NSString* path;
	while ((path = [dirEnum nextObject]))
	{
		NSString* fullPath = [enclosingPath stringByAppendingPathComponent:path];
		if (repositoryExistsAtPath(fullPath))
		{
			// Make sure the link is not a symbolic one or else we can sometimes get infinite recursion depdening on where the link points too
			struct stat fileInfo;
			if (lstat([[NSFileManager defaultManager] fileSystemRepresentationWithPath:fullPath], &fileInfo) < 0) continue;
			if (S_ISLNK(fileInfo.st_mode)) continue;

			SidebarNode* newNode = [SidebarNode nodeForLocalURL:fullPath];
			[node addChild:newNode];
			[newNode refreshNodeIcon];
			[self emmbedAnyNestedRepositoriesForPath:fullPath atNode:newNode];
			[dirEnum skipDescendants];
		}
	}
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Delegates Drag & Drop
// ------------------------------------------------------------------------------------

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal  { return isLocal ? (NSDragOperationMove|NSDragOperationCopy) : NSDragOperationNone; }
- (BOOL) outlineView:(NSOutlineView*)outlineView  writeItems:(NSArray*)items  toPasteboard:(NSPasteboard*)pasteboard
{
	[pasteboard declareTypes:@[kSidebarPBoardType] owner:self];
	
	// keep track of this nodes for drag feedback in "validateDrop"
	[[AppController sharedAppController] setDragNodesArray:items];
	
	return YES;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
	[super draggingUpdated:sender]; // let the outline update
	
	// If we drag to a different sidebar then copy, or when the option key is down, force a copy operation. When the option key is
	// down the mask is just the NSDragOperationCopy mask otherwise it is the mask (NSDragOperationCopy|NSDragOperationMove) 
	if ([sender draggingSource] != self || [sender draggingSourceOperationMask] == NSDragOperationCopy)	
		return NSDragOperationCopy;
	return NSDragOperationMove;
}


- (NSDragOperation) outlineView:(NSOutlineView*)outlineView  validateDrop:(id<NSDraggingInfo>)info  proposedItem:(id)item  proposedChildIndex:(NSInteger)index
{
	NSPasteboard* pasteboard = [info draggingPasteboard];	// get the pasteboard
	if ([pasteboard availableTypeFromArray:@[NSFilenamesPboardType]])
	{
		NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
		NSArray* resolvedFilenames = [filenames resolveSymlinksAndAliasesInPaths];
		for (NSString* file in resolvedFilenames)
			if (pathIsExistentDirectory(file))
				return NSDragOperationCopy;
		return NSDragOperationNone;
	}

	if (index == NSOutlineViewDropOnItemIndex)
		return NSDragOperationMove;

	if (item == nil)
		return NSDragOperationGeneric;
	
	return NSDragOperationMove;
	
	if (![item isDraggable] && index >= 0)
		return NSDragOperationMove;
	
	return NSDragOperationNone;
}


- (BOOL) outlineView:(NSOutlineView*)outlineView  acceptDrop:(id<NSDraggingInfo>)info  item:(id)targetItem  childIndex:(NSInteger)index
{
	NSPasteboard* pasteboard = [info draggingPasteboard];	// get the pasteboard

	SidebarNode* targetParent = targetItem;
	if (targetParent == nil)
		targetParent = root_;

	// user is doing an intra-app drag within the outline view
	if ([pasteboard availableTypeFromArray:@[kSidebarPBoardType]])
	{
		NSInteger adjIdx = 0;

		SidebarNode* copiedTree = [root_ copyNodeTree];
		[[self prepareUndoWithTarget:self] setRootAndUpdate:copiedTree];
		[[self undoManager] setActionName:@"Drag"];
		
		NSArray* dragNodesArray = [[AppController sharedAppController] dragNodesArray];
		Sidebar* sourceSidebar  = DynamicCast(Sidebar, [info draggingSource]);
		NSArray* currentSelectedNodes = [self selectedNodes];
		NSArray* currentSelectedSourceNodes = [sourceSidebar selectedNodes];
		BOOL copyNodes = (sourceSidebar != self) || ([info draggingSourceOperationMask] == NSDragOperationCopy);
		
		// We can't drag the item onto itself
		if ([dragNodesArray count] == 1 && dragNodesArray[0] == targetParent)
			return NO;
		
		if (!copyNodes)
		{
			// Compute new insertion offset
			for (NSInteger i = 0; i < [dragNodesArray count]; ++i)
			{
				SidebarNode* node = dragNodesArray[i];
				if ([node parent] == targetParent)
					if ([targetParent indexOfChildNode:node] < index)
						adjIdx--;
			}

			for (NSInteger i = 0; i < [dragNodesArray count]; ++i)
			{
				SidebarNode* node = dragNodesArray[i];
				[[node parent] removeChild:node];
			}
		}

		NSInteger newTargetIndex = index + adjIdx;
		if (newTargetIndex < 0)
			newTargetIndex = [targetParent numberOfChildren];
		for (NSInteger i = [dragNodesArray count] -1; i >=0; i--)
		{
			SidebarNode* node = dragNodesArray[i];
			SidebarNode* useNode = copyNodes ? [node copyNodeTree] : node;
			[targetParent insertChild:useNode atIndex:newTargetIndex];
		}

		if (sourceSidebar != self)
		{
			[sourceSidebar reloadData];
			[sourceSidebar selectNodes:currentSelectedSourceNodes];
		}
		[self reloadData];
		[self selectNodes:currentSelectedNodes];
		[myDocument saveDocumentIfNamed];
		return YES;
	}

	// We are dragging files in from the finder.
	if ([pasteboard availableTypeFromArray:@[NSFilenamesPboardType]])
	{
		SidebarNode* copiedTree = [root_ copyNodeTree];
		[[self prepareUndoWithTarget:self] setRootAndUpdate:copiedTree];
		[[self undoManager] setActionName:@"Drag"];
		
		NSArray* filenames = [pasteboard propertyListForType:NSFilenamesPboardType];
		NSArray* resolvedFilenames = [filenames resolveSymlinksAndAliasesInPaths];
		SidebarNode* newSelectedNode = nil;
		for (id path in [resolvedFilenames reverseObjectEnumerator])
			if (pathIsExistentDirectory(path) && repositoryExistsAtPath(path))
			{
				SidebarNode* node = [SidebarNode nodeForLocalURL:path];
				NSArray* servers  = [self serversIfAvailable:path includingAlreadyPresent:NO];
				[targetParent insertChild:node atIndex:index];
				[self emmbedAnyNestedRepositoriesForPath:path atNode:node];
				[[AppController sharedAppController] computeRepositoryIdentityForPath:path];
				if (servers)
					for (SidebarNode* serverNode in servers)
						[targetParent insertChild:serverNode atIndex:index];
				newSelectedNode = node;
			}

		for (id path in resolvedFilenames)
			if (pathIsExistentDirectory(path) && !repositoryExistsAtPath(path))
			{
				NSString* fileName = [[NSFileManager defaultManager] displayNameAtPath:path];
				[[myDocument theLocalRepositoryRefSheetController] openSheetForNewRepositoryRefNamed:fileName atPath:path addNewRepositoryRefTo:targetParent atIndex:index];
				return YES;
			}

		[self reloadData];
		if (newSelectedNode)
			[self selectNode:newSelectedNode];
		[self outlineViewSelectionDidChange:nil];
		[myDocument saveDocumentIfNamed];
		return YES;
	}
	
	return NO;
}


- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset
{
	CTBadge* badgeFactory = [CTBadge badgeWithColor:[NSColor redColor] labelColor:[NSColor whiteColor]];
	NSImage* badge = [badgeFactory smallBadgeForValue: [dragRows count]];
	
	if ([dragEvent modifierFlags] & NSAlternateKeyMask)
	{
		NSImage* addImage = [NSImage imageNamed:NSImageNameAddTemplate];
		[badge lockFocus];
		[addImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
		[badge unlockFocus];
	}
	return badge;
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Drawing
// ------------------------------------------------------------------------------------

// We are faking the source list look since apple has made it really non UI like since it has no disclosure arrows and the default
// source list indentation is all messed up. Thus when a document becomes main or resigns main we need to adjust the sidebar
// background like source lists do. 
- (void) becomeMain	{ [self setBackgroundColor:rgbColor255(220, 224, 231)]; }	// source list active
- (void) resignMain { [self setBackgroundColor:rgbColor255(238, 238, 238)]; }	// source list inactive


- (NSRect)	rectInWindowForNode:(SidebarNode*)node
{
	NSInteger row = [self rowForItem:node];
	NSRect itemRect = (row>=0) ? [self rectOfRow:row] : NSZeroRect;	
	
	// check that the path Rect is visible on screen
	if (NSIntersectsRect([self visibleRect], itemRect))
		return [self convertRectToBase:itemRect];			// convert item rect to screen coordinates
	return NSZeroRect;
}

- (void) setNeedsDisplayForNode:(SidebarNode*)node
{
	[[[self window] contentView] setNeedsDisplayInRect:[self rectInWindowForNode:node]];
}

- (void) setNeedsDisplayForNodePath:(NSString*)nodePath andNode:(SidebarNode*)node
{
	if ([node isRepositoryRef] && [nodePath isEqualToString:[node path]])
		[self setNeedsDisplayForNode:node];
	for (SidebarNode* child in [node children])
		[self setNeedsDisplayForNodePath:nodePath andNode:child];
}

- (void) setNeedsDisplayForNodePath:(NSString*)nodePath
{
	[self setNeedsDisplayForNodePath:nodePath andNode:root_];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  InformationTextView
// ------------------------------------------------------------------------------------

- (NSAttributedString*) informationTextViewMessage:(SidebarNode*)node
{	
	NSMutableAttributedString* attrString = [NSMutableAttributedString string:@"Name: " withAttributes:smallGraySystemFontAttributes];
	[attrString appendAttributedString: [NSAttributedString string:[node shortName] withAttributes:smallSystemFontAttributes]];
	
	if ([node isExistentLocalRepositoryRef])
	{
		RepositoryData* repositoryData = [myDocument repositoryData];
		NSNumber* parentRevision  = [repositoryData getHGParent1Revision];
		if (!parentRevision)
			return attrString;
		NSString* parentRevisionStr = numberAsString(parentRevision);
		NSString* parentRevisions = [repositoryData inMergeState] ? fstr(@"%@, %@", parentRevision, [repositoryData getHGParent2Revision]) : parentRevisionStr;

		NSArray*  labels    = [[repositoryData revisionNumberToLabels] synchronizedObjectForKey:parentRevision];
		NSArray*  tags      = [LabelData filterLabelsAndExtractNames:labels byType:eTagLabel];
		NSArray*  bookmarks = [LabelData filterLabelsAndExtractNames:labels byType:eBookmarkLabel];
		NSString* branch    = [repositoryData getHGBranchName];
		
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
		[attrString appendAttributedString: [NSAttributedString string:[node pathHidingAnyPassword] withAttributes:smallSystemFontAttributes]];
	}
	return attrString;
}


- (void) updateInformationTextView
{
	Sidebar* __weak weakSelf = self;
	NSTextView* __unsafe_unretained informationTextView = informationTextView_;
	[queueForUpdatingInformationTextView_ addBlockOperation:^{
		// We do this updating on the main thread since acessing the selectedNode can cause problems while the NSOutlineView
		// (sidebar) is being updated. 
		dispatch_async(mainQueue(), ^{
			SidebarNode* selectedNode = [weakSelf selectedNode];
			if ([selectedNode isRepositoryRef])
			{
				NSAttributedString* newInformativeMessage = [weakSelf informationTextViewMessage:selectedNode];
				dispatch_async(mainQueue(), ^{
					[[informationTextView textStorage] setAttributedString:newInformativeMessage];
				});
			}
		});
	}];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: SideBar Contextual Menu Delegates
// ------------------------------------------------------------------------------------

// The sidebarContextualMenu in the nib file has its delegate set to this sidebar. In menuNeedsUpdate, we dynamically update the
// menus based on the currently clicked upon row/column pair.
- (void) menuNeedsUpdate:(NSMenu*)theMenu
{
    if (theMenu == sidebarContextualMenu)
	{		
		// Remove all the items after the 3rd.
		int numberOfItems = [theMenu numberOfItems];
		for (int i = 3; i < numberOfItems; i++)
			[theMenu removeItemAtIndex:3];

		if ([self multipleNodesAreChosen])
		{
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:[self menuTitleForRemoveSidebarItems]				action:@selector(mainMenuRemoveSidebarItems:)			keyEquivalent:@""];
			return;
		}

		SidebarNode* node = [self clickedNode];
        if (node != nil && [node isLocalRepositoryRef])
		{
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:fstr(@"Clone “%@”…", [node shortName])			action:@selector(mainMenuCloneRepository:)				keyEquivalent:@""];
			[theMenu addItemWithTitle:fstr(@"Configure “%@”…", [node shortName])		action:@selector(mainMenuConfigureLocalRepositoryRef:)	keyEquivalent:@""];
			[theMenu addItemWithTitle:fstr(@"Delete Bookmark “%@”", [node shortName])	action:@selector(mainMenuRemoveSidebarItems:)			keyEquivalent:@""];
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:fstr(@"Reveal “%@” in Finder", [node shortName])	action:@selector(mainMenuRevealRepositoryInFinder:)		keyEquivalent:@""];
			[theMenu addItemWithTitle:@"Open Terminal Here"								action:@selector(mainMenuOpenTerminalHere:)				keyEquivalent:@""];
			return;
		}

		if (node != nil && [node isServerRepositoryRef])
		{
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:fstr(@"Clone “%@”…", [node shortName])			action:@selector(mainMenuCloneRepository:)				keyEquivalent:@""];
			[theMenu addItemWithTitle:fstr(@"Configure “%@”…", [node shortName])		action:@selector(mainMenuConfigureServerRepositoryRef:)	keyEquivalent:@""];
			[theMenu addItemWithTitle:fstr(@"Delete Bookmark “%@”", [node shortName])	action:@selector(mainMenuRemoveSidebarItems:)			keyEquivalent:@""];
			return;
		}

		if (node != nil)
		{
			[theMenu addItem:[NSMenuItem separatorItem]];
			[theMenu addItemWithTitle:fstr(@"Delete Group “%@”", [node shortName])		action:@selector(mainMenuRemoveSidebarItems:)				keyEquivalent:@""];
			return;
		}
    }
}









// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Action Validation
// ------------------------------------------------------------------------------------

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem, NSObject>)anItem
{
	SEL theAction = [anItem action];
	
	if (theAction == @selector(mainMenuAddNewSidebarGroupItem:))		return ![myDocument showingASheet];
	if (theAction == @selector(mainMenuRemoveSidebarItems:))			return [myDocument validateAndSwitchMenuForRemoveSidebarItems:anItem];
	if (theAction == @selector(mainMenuConfigureRepositoryRef:))		return [myDocument localOrServerRepoIsChosenAndReady];
	if (theAction == @selector(mainMenuConfigureLocalRepositoryRef:))	return [myDocument localRepoIsChosenAndReady];
	if (theAction == @selector(mainMenuConfigureServerRepositoryRef:))	return [myDocument localOrServerRepoIsChosenAndReady];
	if (theAction == @selector(mainMenuCloneRepository:))				return [myDocument localOrServerRepoIsChosenAndReady];
	if (theAction == @selector(mainMenuRevealRepositoryInFinder:))		return [myDocument localOrServerRepoIsChosenAndReady];
	if (theAction == @selector(mainMenuOpenTerminalHere:))				return [myDocument localOrServerRepoIsChosenAndReady];
	
	if (theAction == @selector(mainMenuRevealRepositoryInFinder:))		return [myDocument localRepoIsSelectedAndReady];
	if (theAction == @selector(mainMenuOpenTerminalHere:))				return [myDocument localRepoIsSelectedAndReady];

	return NO;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions
// ------------------------------------------------------------------------------------

- (IBAction) mainMenuConfigureLocalRepositoryRef:(id)sender			{ [myDocument mainMenuConfigureLocalRepositoryRef:sender]; }
- (IBAction) mainMenuConfigureServerRepositoryRef:(id)sender		{ [myDocument mainMenuConfigureServerRepositoryRef:sender]; }
- (IBAction) mainMenuCloneRepository:(id)sender						{ [myDocument mainMenuCloneRepository:sender]; }

- (IBAction) reloadSidebarData:(id)sender							{ [self reloadData]; }
- (IBAction) forceRefreshOfSidebarData:(id)sender					{ [self outlineViewSelectionDidChange:nil]; }

- (IBAction) mainMenuConfigureRepositoryRef:(id)sender
{
	SidebarNode* node = [self chosenNode];

	if ([node isLocalRepositoryRef])
		[myDocument mainMenuConfigureLocalRepositoryRef:sender];
	else if ([node isServerRepositoryRef])
		[myDocument mainMenuConfigureServerRepositoryRef:sender];
	else
		NSBeep();
}


- (IBAction) mainMenuAddNewSidebarGroupItem:(id)sender
{
	[[self prepareUndoWithTarget:self] setRootAndUpdate:[root_ copyNodeTree]];
	[[self undoManager] setActionName:@"Add New Group"];

	SidebarNode* newGroupNode = [SidebarNode sectionNodeWithCaption:@"NEW GROUP"];
	
	SidebarNode* targetNode = [self chosenNode];
	if ([self numberOfSelectedRows] <= 0 && !targetNode)
		[root_ insertChild:newGroupNode atIndex:[[root_ children] count]];
	else
	{
		SidebarNode* node = [self chosenNode];
		NSInteger index = [[node parent] indexOfChildNode:node] + 1;
		[[node parent] insertChild:newGroupNode atIndex:index];
	}
	[self reloadData];
}

- (NSString*) menuTitleForRemoveSidebarItems
{	
	NSArray* nodes = [self chosenNodes];
	if (IsEmpty(nodes))
		return @"Delete Repository Item";

	NSInteger nodeCount = [nodes count];
	if ([nodes count] == 1)
	{
		SidebarNode* node = [nodes firstObject];
		if ([node isLocalRepositoryRef])		return fstr(@"Delete Bookmark “%@”", [node shortName]);
		if ([node isServerRepositoryRef])		return fstr(@"Delete Bookmark “%@”", [node shortName]);
		if ([node isSectionNode])				return fstr(@"Delete Group “%@”",    [node shortName]);
		return @"Delete Item";
	}
				 
	NSInteger repositoryNodeCount = 0;
	NSInteger sectionNodeCount = 0;
	for (SidebarNode* node in nodes)
	{
		if		([node isRepositoryRef]) repositoryNodeCount++;
		else if ([node isSectionNode])  sectionNodeCount++;
	}
	if (repositoryNodeCount == nodeCount)  return @"Delete Bookmarks";
	if (   sectionNodeCount == nodeCount)  return @"Delete Groups";
		
	return @"Delete Items";
}

- (IBAction) mainMenuRemoveSidebarItems:(id)sender
{
	NSArray* theChosenNodes = [self chosenNodes];
	if (IsEmpty(theChosenNodes))
		{ NSBeep(); return; }
	
	BOOL restoreSelectionAfterRemove = [self clickedRowOutsideSelectedRows];
	NSArray* theSelectedNodes = [self selectedNodes];
	
	NSMutableArray* chosenNodesAndAllChildren = [NSMutableArray arrayWithArray:theChosenNodes];
	for (SidebarNode* node in theChosenNodes)
		[chosenNodesAndAllChildren addObjectsFromArray:[node allChildren]];
	NSArray* nodes = [[NSSet setWithArray:chosenNodesAndAllChildren] allObjects];
	
	NSInteger localRepoCount = 0;
	NSInteger serverRepoCount = 0;
	NSInteger sectionNodeCount = 0;
	NSInteger nodeCount = [nodes count];
	NSMutableArray*  existentLocalRepositories = [[NSMutableArray alloc]init];
	for (SidebarNode* node in nodes)
	{
		if ([node isExistentLocalRepositoryRef])
			if (![existentLocalRepositories containsObject:[node path]])
				[existentLocalRepositories addObject:[node path]];
		if ([node isLocalRepositoryRef]) localRepoCount++;
		if ([node isServerRepositoryRef]) serverRepoCount++;
		if ([node isSectionNode]) sectionNodeCount++;
	}
	
	NSInteger repoCount = localRepoCount + serverRepoCount;

	BOOL deleteRepositoriesAsWell = NO;
	if (DisplayWarningForRepositoryDeletionFromDefaults())
	{
		NSString* title   = fstr(@"Delete Repository %@%@",  (sectionNodeCount > 0) ? @"Item" : @"Bookmark",  (nodeCount > 1) ? @"s" : @"");
		NSString* okTitle = fstr(@"Delete %@%@",			 (sectionNodeCount > 0) ? @"Item" : @"Bookmark",  (nodeCount > 1) ? @"s" : @"");
		
		NSString* subMessage;
		if		(localRepoCount   == nodeCount && nodeCount == 1)	subMessage = fstr(@"Are you sure you want to delete the local bookmark “%@”?", [[nodes firstObject] shortName]);
		else if	(serverRepoCount  == nodeCount && nodeCount == 1)	subMessage = fstr(@"Are you sure you want to delete the server bookmark “%@”?", [[nodes firstObject] shortName]);
		else if	(sectionNodeCount == nodeCount && nodeCount == 1)	subMessage = fstr(@"Are you sure you want to delete the group “%@”?", [[nodes firstObject] shortName]);		
		else if	(repoCount        == nodeCount)						subMessage =      @"Are you sure you want to delete the chosen reopository bookmarks?";
		else														subMessage =      @"Are you sure you want to delete the chosen items?";

		int result;
		if ([existentLocalRepositories count] == 0)
			result = RunCriticalAlertPanelOptionsWithSuppression(title, subMessage, okTitle, @"Cancel", nil, MHGDisplayWarningForRepositoryDeletion);
		else
		{
			NSAlert* alert = NewAlertPanel(title, subMessage, okTitle, @"Cancel", nil);
			[removeSidebarItemsAlertAccessoryDeleteReposOnDiskCheckBox setState:NO];
			[removeSidebarItemsAlertAccessoryAlertSuppressionCheckBox setState:!DisplayWarningForRepositoryDeletionFromDefaults()];
			[alert setAccessoryView:removeSidebarItemsAlertAccessoryView];
			result = [alert runModal];
			if ([removeSidebarItemsAlertAccessoryAlertSuppressionCheckBox state] == NSOnState)
				[[NSUserDefaults standardUserDefaults] setBool:NO forKey:MHGDisplayWarningForRepositoryDeletion];
			deleteRepositoriesAsWell = [removeSidebarItemsAlertAccessoryDeleteReposOnDiskCheckBox state];
		}
		
		if (result != NSAlertFirstButtonReturn)
			return;
	}

	if (deleteRepositoriesAsWell)
	{
		moveFilesToTheTrash(existentLocalRepositories);
		[myDocument removeAllUndoActionsForDocument];
		[myDocument updateChangeCount:NSChangeDone];
	}
	else
	{
		[[self prepareUndoWithTarget:self] setRootAndUpdate:[root_ copyNodeTree]];					// With the undo restore the root node tree
		[[self undoManager] setActionName:[self menuTitleForRemoveSidebarItems]];		
		NSMutableDictionary* connectionsCopy = [[myDocument connections] mutableCopy];
		[[self prepareUndoWithTarget:myDocument] setConnections:connectionsCopy];
	}
	
	for (SidebarNode* node in nodes)
		[self removeNodeFromSidebar:node];

	[self reloadData];
	if (restoreSelectionAfterRemove)
		[self selectNodes:theSelectedNodes];
	else
		[self myDeselectAll];	
	[myDocument saveDocumentIfNamed];
}



- (IBAction) mainMenuRevealRepositoryInFinder:(id)sender
{
	SidebarNode* node = [self chosenNode];
	if (!node)
		return;
	
	NSString* thePath = [node path];
	[[NSWorkspace sharedWorkspace] selectFile:thePath inFileViewerRootedAtPath:nil];
}


- (IBAction) mainMenuOpenTerminalHere:(id)sender
{
	SidebarNode* node = [self chosenNode];
	if (!node)
	{
		PlayBeep();
		NSRunAlertPanel(@"No Bookmark Selected", @"You need to select a local bookmark", @"OK", nil, nil);
		return;
	}

	if (![node isLocalRepositoryRef])
	{
		PlayBeep();
		NSRunAlertPanel(@"No Local Bookmark Selected", @"You need to select a local bookmark", @"OK", nil, nil);
		return;
	}
	
	if (![node path])
	{
		PlayBeep();
		return;
	}

	NSString* commandDir = [node path];
	DoCommandsInTerminalAt(aliasesForShell(commandDir), commandDir);
}


// Uncoment to allow the delete key to do a sidebarMenuRemoveSidebarItem
//- (void) keyDown:(NSEvent *)theEvent
//{
//    NSString* key = [theEvent charactersIgnoringModifiers];
//	
//	if (IsNotEmpty(key))
//	{
//		unichar keyCode = [key characterAtIndex:0];
//		if (keyCode == NSDeleteCharacter || keyCode == NSBackspaceCharacter)
//			if ([self numberOfSelectedRows] > 0)
//			{
//				[self sidebarMenuRemoveSidebarItems:self];
//				return;
//			}
//	}
//
//	[super keyDown:theEvent];
//}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Saving and Loading
// ------------------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder*)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:root_ forKey:@"sideBarRoot"];
}


- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	if (!self)
		return nil;
	root_ = [coder decodeObjectForKey:@"sideBarRoot"];
	root_ = [root_ copyNodeTree];	// We do this to ensure the parent pointers are correct.
	return self;
}




// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Section Nodes
// ------------------------------------------------------------------------------------

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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: CompatibleRepositories
// ------------------------------------------------------------------------------------

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

- (NSArray*) allCompatibleRepositories:(SidebarNode*)selectedNode
{
	NSMutableArray* compatibleRepositories = [[NSMutableArray alloc] init];
	NSArray* allRepositories = [self allRepositories];
	for (SidebarNode* repo in allRepositories)
		if ([repo isCompatibleTo:selectedNode])
			[compatibleRepositories addObject:repo];

	return compatibleRepositories;
}


- (void) removeConnectionsFor:(NSString*) deadPath
{
	NSMutableArray* allOfTheKeys = [NSMutableArray arrayWithArray:[[myDocument connections] allKeys]];
	for (NSString* key in allOfTheKeys)
		if ([key containsString:deadPath])
			[[myDocument connections] removeObjectForKey:key];
}


- (NSString*) outgoingCountTo:(SidebarNode*)destination	{ return outgoingCounts[[destination path]]; }
- (NSString*) incomingCountFrom:(SidebarNode*)source	{ return incomingCounts[[source path]]; }


- (void) computeIncomingOutgoingToCompatibleRepositories
{
	SidebarNode* theSelectedNode  = [self selectedNode];
	NSString* rootPath = [theSelectedNode path];
	
	if (![theSelectedNode isExistentLocalRepositoryRef])
		return;

	// Normally there is a lot of mercurial stuff happening and processor load just after we call
	// computeIncomingOutgoingToCompatibleRepositories so to be nice to the processor we delay the computation of these things by
	// putting them in SingleTimedQueue's, and wait until the main document is not so busy.

	Sidebar* __weak weakSelf = self;
	MacHgDocument* __weak weakMyDocument = myDocument;
	NSArray* compatibleRepositories = [self allCompatibleRepositories:theSelectedNode];
	[queueForAutomaticOutgoingComputation_ addBlockOperation:^{

		// Order local repositories before server repositories for speed
		NSArray* sortedCompatibleRepositories = [compatibleRepositories sortedArrayUsingComparator: ^(id obj1, id obj2) {
			if ([obj1 nodeKind] < [obj2 nodeKind]) return (NSComparisonResult)NSOrderedAscending;
			if ([obj1 nodeKind] > [obj2 nodeKind]) return (NSComparisonResult)NSOrderedDescending;
			return (NSComparisonResult)NSOrderedSame;
		}];
		
		for (SidebarNode* repo in sortedCompatibleRepositories)
		{
			__weak ShellTaskController* theOutgoingController = [[ShellTaskController alloc]init];
			dispatchWithTimeOutBlock(globalQueue(), 30.0 /* try for 30 seconds to get result of "outgoing"*/,
									 
									 // Main Block
									 ^{
										 NSMutableArray* argsOutgoing = [NSMutableArray arrayWithObjects:@"outgoing", @"--insecure", @"--quiet", @"--noninteractive", @"--template", @"+", [repo fullURLPath], nil];
										 ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsOutgoing  fromRoot:rootPath  logging:eLoggingNone  withDelegate:theOutgoingController];
										 dispatch_async(mainQueue(), ^{
											 if (![rootPath isEqualTo:[[weakSelf selectedNode] path]])
												 return;
											 if ([results hasNoErrors])
												 outgoingCounts[[repo path]] = intAsString([results.outStr length]);
											 else
												 outgoingCounts[[repo path]] = @"-";
											 NSDictionary* info = @{@"sidebarNodePath": [repo path]};
											 [weakMyDocument postNotificationWithName:kReceivedCompatibleRepositoryCount userInfo:info];
										 });										 
									 },
									 
									 // Timeout Block
									 ^{
										 [[theOutgoingController shellTask] cancelTask];	// We timed out so kill the task which timed out...
										 dispatch_async(mainQueue(), ^{
											 if (![rootPath isEqualTo:[[weakSelf selectedNode] path]])
												 return;
											 outgoingCounts[[repo path]] = @"-";
											 [weakSelf setNeedsDisplayForNodePath:[repo path]];
										 });										 
									 });
		}
	}];

	[queueForAutomaticIncomingComputation_ addBlockOperation:^{
		for (SidebarNode* repo in compatibleRepositories)
		{
			__weak ShellTaskController* theIncomingController = [[ShellTaskController alloc]init];
			dispatchWithTimeOutBlock(globalQueue(), 30.0 /* try for 30 seconds to get result of "outgoing"*/,
									 
									 // Main Block
									 ^{
										 NSMutableArray* argsOutgoing = [NSMutableArray arrayWithObjects:@"incoming", @"--insecure", @"--quiet", @"--noninteractive", @"--template", @"-", [repo fullURLPath], nil];
										 ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsOutgoing  fromRoot:rootPath  logging:eLoggingNone  withDelegate:theIncomingController];
										 dispatch_async(mainQueue(), ^{
											 if (![rootPath isEqualTo:[[weakSelf selectedNode] path]])
												 return;
											 if ([results hasNoErrors])
												 incomingCounts[[repo path]] = intAsString([results.outStr length]);
											 else
												 incomingCounts[[repo path]] = @"-";
											 NSDictionary* info = @{@"sidebarNodePath": [repo path]};
											 [weakMyDocument postNotificationWithName:kReceivedCompatibleRepositoryCount userInfo:info];
										 });										 
									 },
									 
									 // Timeout Block
									 ^{
										 [[theIncomingController shellTask] cancelTask];	// We timed out so kill the task which timed out...
										 dispatch_async(mainQueue(), ^{
											 if (![rootPath isEqualTo:[[weakSelf selectedNode] path]])
												 return;
											 incomingCounts[[repo path]] = @"-";
											 [weakSelf setNeedsDisplayForNodePath:[repo path]];
										 });										 
									 });
		}
	}];

}

@end

