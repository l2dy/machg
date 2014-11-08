//
//  SheetController.m
//  MacHg
//
//  Created by Jason Harris on 1/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "TransmitSheetController.h"
#import "SidebarNode.h"
#import "OptionController.h"
#import "DisclosureBoxController.h"
#import "MacHgDocument.h"
#import "Sidebar.h"

#define ICON_SIZE			16.0	// Our Icons are ICON_SIZE x ICON_SIZE


@interface TransmitSheetController (PrivateAPI)
- (void) recenterMainGroupingBox;
@end


// ------------------------------------------------------------------------------------
// MARK: -
// MARK: TransmitSheetController
// ------------------------------------------------------------------------------------
// MARK: -

@implementation TransmitSheetController
@synthesize allowOperationWithAnyRepository = allowOperationWithAnyRepository_;
@synthesize myDocument = myDocument_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Pure methods
// ------------------------------------------------------------------------------------
// These *MUST* be overridden in the child class

- (SidebarNode*)		sourceRepository		{ NSAssert(NO, @"Must Override sourceRepository method");		return nil; }
- (SidebarNode*)		destinationRepository	{ NSAssert(NO, @"Must Override destinationRepository method");	return nil; }
- (NSString*)			operationName			{ NSAssert(NO, @"Must Override operationName method");			return nil; }
- (OptionController*)	commonRevOption			{ NSAssert(NO, @"Must Override commonRevOption method");		return nil; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Popup Menu Delegate
// ------------------------------------------------------------------------------------

- (void) menuWillOpen:(NSMenu*)menu
{
	[sheetWindow makeFirstResponder:sheetWindow];	// Make the fields of the sheet commit any changes they currently have
	[self setConnectionFromFieldsForSource:self.sourceRepository andDestination:self.destinationRepository];
}

- (void) menu:(NSMenu*)menu willHighlightItem:(NSMenuItem*)item
{
	NSMenuItem* useItem = item ? item : [compatibleRepositoriesPopup selectedItem];	// If the item is nil we are selecting outside the popup so fall back to the selected items values.
	SidebarNode* newRepository = DynamicCast(SidebarNode, [useItem  representedObject]);
	SidebarNode* destination = (destinationLabel == compatibleRepositoriesPopup) ? newRepository : self.destinationRepository;
	SidebarNode* source		 = (sourceLabel      == compatibleRepositoriesPopup) ? newRepository : self.sourceRepository;
	[self setFieldsFromConnectionForSource:source  andDestination:destination];
	[self layoutGroupsForSource:           source  andDestination:destination];
	[self updateIncomingOutgoingCountForSource:source andDestination:destination];
	[advancedOptionsBox setNeedsDisplay:YES];
}

// When we are about to display the menu, add icons to all the menu items.
- (void)menuNeedsUpdate:(NSMenu*)menu
{
	if (menu == [compatibleRepositoriesPopup menu])		
		for (NSMenuItem* item in [menu itemArray])
		{
			SidebarNode* node = DynamicCast(SidebarNode, [item representedObject]);
			if ([node isRepositoryRef])
			{
				NSImage* image = [node icon];
				if ([image size].width != ICON_SIZE || [image size].height != ICON_SIZE)
				{
					image = [image copy];
					[image setSize:NSMakeSize(ICON_SIZE, ICON_SIZE)];
				}
				[item setImage:image];
			}
		}	
}

// We have finished displaying the menu, hide the icons in the menu.
- (void)menuDidClose:(NSMenu*)menu
{
	if (menu == [compatibleRepositoriesPopup menu])
		for (NSMenuItem* item in [menu itemArray])
		{
			SidebarNode* node = DynamicCast(SidebarNode, [item representedObject]);
			if ([node isRepositoryRef])
				[item setImage:nil];
		}		
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Window Delegate
// ------------------------------------------------------------------------------------

- (void)windowDidResize:(NSNotification*)notification
{
	[self recenterMainGroupingBox];
}


- (void) windowDidEndLiveResize:(NSNotification*)notification
{
	[self recenterMainGroupingBox];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Popup Menu Handling
// ------------------------------------------------------------------------------------

- (NSInteger) indexOfPopup:(NSPopUpButton*)popup matchingPath:(NSString*)path
{
	for (NSInteger i = 0; i < [[popup menu] numberOfItems]; i++)
	{
		SidebarNode* representedObject = [[[popup menu] itemAtIndex:i] representedObject];
		if ([trimmedURL([representedObject path]) isEqualToString:trimmedURL(path)])
			return i;
	}
	return NSNotFound;
}


- (void) chooseInitialPopupItem:(NSPopUpButton*)popup
{
	NSMutableArray* orderedPaths = [[NSMutableArray alloc] init];
	NSString* matchingPath = (sourceLabel == compatibleRepositoriesPopup) ? [self.destinationRepository recentPullConnection] : [self.sourceRepository recentPushConnection];
	[orderedPaths addObjectIfNonNil:matchingPath];
	
	Sidebar* theSidebar = myDocument_.sidebar;
	SidebarNode* selectedNode = [theSidebar selectedNode];
	NSArray* allServers = [theSidebar serversIfAvailable:[selectedNode path] includingAlreadyPresent:YES];
	for (SidebarNode* node in allServers)
		[orderedPaths addObjectIfNonNil:[node path]];
	
	for (NSString* path in orderedPaths)
	{
		NSInteger index = [self indexOfPopup:popup matchingPath:path];
		if (index != NSNotFound)
		{
			[popup selectItemAtIndex:index];
			return;
		}
	}
	
	// If we didn't find any of our perfered paths, then choose the first repository reference available
	for (NSInteger index = 0; index < [[popup menu] numberOfItems]; index++)
	{
		SidebarNode* representedObject = [[[popup menu] itemAtIndex:index] representedObject];
		if ([representedObject isRepositoryRef])
		{
			[popup selectItemAtIndex:index];
			return;
		}		
	}	
}


- (void) populateNewAndSetupPopupMenu:(NSPopUpButton*)popup withSubtree:(SidebarNode*)node atLevel:(NSInteger)level
{
	// Don't include the currently selected node since we don't push / pull to ourselves.
	if ([trimmedURL([[myDocument_ selectedRepositoryRepositoryRef] path]) isEqualToString:trimmedURL([node path])])
		return;
	
	NSMenuItem* item = [[NSMenuItem alloc]init];
	NSDictionary* attributesForMenuTitle = graySystemFontAttributes;
	if ([node isRepositoryRef])
	{
		attributesForMenuTitle = [node isServerRepositoryRef] ? italicSystemFontAttributes : systemFontAttributes;
		[item setRepresentedObject:node];
	}
	
	NSAttributedString* menuTitle = [NSAttributedString string:[node shortName] withAttributes:attributesForMenuTitle];
	[item setAttributedTitle:menuTitle];
	[item setEnabled:[node isRepositoryRef]];
	[item setIndentationLevel:level];
	[[popup menu] addItem:item];
	for (SidebarNode* child in [node children])
		[self populateNewAndSetupPopupMenu:popup withSubtree:child atLevel:level+1];
}

- (void) populateNewAndSetupPopupMenu:(NSPopUpButton*)popup withItems:(SidebarNode*)root
{
	[popup removeAllItems];
	[[popup menu] setAutoenablesItems:NO];

	// Get the default servers
	Sidebar* theSidebar = myDocument_.sidebar;
	SidebarNode* selectedNode = [theSidebar selectedNode];
	NSArray* missingServers   = [theSidebar serversIfAvailable:[selectedNode path] includingAlreadyPresent:NO];

	for (SidebarNode* r in [root children])
		[self populateNewAndSetupPopupMenu:popup withSubtree:r atLevel:0];
	[popup sizeToFit];

	// If there are some servers in the [paths] section of the config file then add these
	if (IsNotEmpty(missingServers))
	{
		SidebarNode* serverGroup = [SidebarNode sectionNodeWithCaption:@"Default Servers"];
		[serverGroup setChildren:[NSMutableArray arrayWithArray:missingServers]];
		[self populateNewAndSetupPopupMenu:popup withSubtree:serverGroup atLevel:0];
	}
	
	[self chooseInitialPopupItem:popup];
}

- (IBAction) populatePopupMenuItemsAndRelayout:(id)sender
{
	SidebarNode* oppositeToPopup = (sourceLabel == compatibleRepositoriesPopup) ? self.destinationRepository : self.sourceRepository;
	SidebarNode* compatibleRoot = [myDocument_.sidebar.root copySubtreeCompatibleTo:oppositeToPopup];
	SidebarNode* root = [sheetButtonAllowOperationWithAnyRepository state] ? myDocument_.sidebar.root : compatibleRoot;
	[self populateNewAndSetupPopupMenu:compatibleRepositoriesPopup withItems:root];
	[[compatibleRepositoriesPopup menu] setDelegate:self];
	
	[self setFieldsFromConnectionForSource:self.sourceRepository  andDestination:self.destinationRepository];
	[self layoutGroupsForSource:           self.sourceRepository  andDestination:self.destinationRepository];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Derived Generic Methods
// ------------------------------------------------------------------------------------

- (IBAction) syncForceOptionToAllowOperationAndRepopulate:(id)sender
{
	[forceOption setOverallState:[sheetButtonAllowOperationWithAnyRepository state]];
	[self setConnectionFromFieldsForSource:self.sourceRepository andDestination:self.destinationRepository];
	BOOL showAdvancedOptions = [OptionController containsOptionWhichIsSet:cmdOptions];
	[disclosureController setToOpenState:showAdvancedOptions withAnimation:NO];
	[self populatePopupMenuItemsAndRelayout:sender];
}

- (void) setConnectionFromFieldsForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* partialKey = fstr(@"%@§%@§%@§", self.operationName, nonNil([source path]), nonNil([destination path]));
	[OptionController setConnections:myDocument_.connections fromOptions:cmdOptions  forKey:partialKey];
}

- (void) setFieldsFromConnectionForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* partialKey = fstr(@"%@§%@§%@§", self.operationName, nonNil([source path]), nonNil([destination path]));
	[OptionController setOptions:cmdOptions fromConnections:myDocument_.connections forKey:partialKey];
}

- (void) updateIncomingOutgoingCount	{ [self updateIncomingOutgoingCountForSource:self.sourceRepository andDestination:self.destinationRepository]; }
- (void) updateIncomingOutgoingCountForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* theCount;
	if ([self.operationName isMatchedByRegex:@"Push|Outgoing"])
		theCount = [myDocument_.sidebar outgoingCountTo:destination];
	else
		theCount = [myDocument_.sidebar incomingCountFrom:source];
	NSString* newValue = (!theCount || [theCount isEqualTo:@"-"]) ? @"": theCount;
	[incomingOutgoingCount setStringValue:newValue];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// ------------------------------------------------------------------------------------

- (NSString*) sourceRepositoryName		{ return [self.sourceRepository shortName]; }
- (NSString*) destinationRepositoryName	{ return [self.destinationRepository shortName]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Sheet Handling
// ------------------------------------------------------------------------------------

- (IBAction) openSheet:(id)sender
{
	// Compute the root of this repository for later comparison.
	SidebarNode* selectedNode = [myDocument_.sidebar selectedNode];
	if (!selectedNode || ![selectedNode isLocalRepositoryRef])
		return;

	// Setup popup and fields with connections from selected popup item
	NoAnimationBlock(^{
		[self setAllowOperationWithAnyRepository:NO];
		[self populatePopupMenuItemsAndRelayout:self];
		[self updateIncomingOutgoingCount];
		BOOL showAdvancedOptions = [OptionController containsOptionWhichIsSet:cmdOptions];
		[disclosureController setToOpenState:showAdvancedOptions withAnimation:NO];
		[mainGroupingBox sizeToFit];	// On open we reset the size of the main grouping box to its smallest size
		[self recenterMainGroupingBox];
	});
	[sheetWindow setDelegate:self];
	[myDocument_ beginSheet:sheetWindow];
}


- (void) recenterMainGroupingBox
{
	CGFloat centerWindow = [sheetWindow frame].size.width/2;
	[mainGroupingBox setCenterX:centerWindow animate:![sheetWindow inLiveResize]];
}


// Layout the source group and destination group nicely centered and spaced symmetrically. Each group consists of an icon, a static
// text label ("Source:" / "Destination:") and the label or popup.
- (void) layoutGroupsForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* sourcePath          = [source pathHidingAnyPassword];
	NSString* destinationPath     = [destination pathHidingAnyPassword];
	NSImage* sourceIconImage      = [source isLocalRepositoryRef]      ? [NSWorkspace iconImageOfSize:[sourceIconWell frame].size forPath:sourcePath]      : [NSImage imageNamed:NSImageNameNetwork];
	NSImage* destinationIconImage = [destination isLocalRepositoryRef] ? [NSWorkspace iconImageOfSize:[sourceIconWell frame].size forPath:destinationPath] : [NSImage imageNamed:NSImageNameNetwork];

	[sourceIconWell      setImage:sourceIconImage];
	[sourceURI			 setStringValue:nonNil(sourcePath)];
	[sourceURI			 sizeToFit];

	[destinationIconWell setImage:destinationIconImage];
	[destinationURI		 setStringValue:nonNil(destinationPath)];
	[destinationURI		 sizeToFit];
	
	NSTextField* sourceLabelTextField      = DynamicCast(NSTextField, sourceLabel);
	NSTextField* destinationLabelTextField = DynamicCast(NSTextField, destinationLabel);
	if (sourceLabelTextField)
	{
		[sourceLabelTextField setStringValue:nonNil([source shortName])];
		[sourceLabelTextField sizeToFit];
	}
	if (destinationLabelTextField)
	{
		[destinationLabelTextField setStringValue:nonNil([destination shortName])];
		[destinationLabelTextField sizeToFit];
	}

	[mainGroupingBox growToFit];
	[self recenterMainGroupingBox];
	return;
}


@end