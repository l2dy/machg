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


@interface TransmitSheetController (PrivateAPI)
- (void) recenterMainGroupingBox;
@end


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: TransmitSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation TransmitSheetController
@synthesize allowOperationWithAnyRepository = allowOperationWithAnyRepository_;
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Pure methods
// -----------------------------------------------------------------------------------------------------------------------------------------
// These *MUST* be overridden in the child class

- (SidebarNode*)	sourceRepository		{ NSAssert(NO, @"Must Override sourceRepository method");		return nil; }
- (SidebarNode*)	destinationRepository	{ NSAssert(NO, @"Must Override destinationRepository method");	return nil; }
- (NSString*)		operationName			{ NSAssert(NO, @"Must Override operationName method");			return nil; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Popup Menu Delegate
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) menuWillOpen:(NSMenu*)menu
{
	[sheetWindow makeFirstResponder:sheetWindow];	// Make the fields of the sheet commit any changes they currently have
	[self setConnectionFromFieldsForSource:[self sourceRepository] andDestination:[self destinationRepository]];
}

- (void) menu:(NSMenu*)menu willHighlightItem:(NSMenuItem*)item
{
	NSMenuItem* useItem = item ? item : [compatibleRepositoriesPopup selectedItem];	// If the item is nil we are selecting outside the popup so fall back to the selected items values.
	SidebarNode* newRepository = DynamicCast(SidebarNode, [useItem  representedObject]);
	SidebarNode* destination = (destinationLabel == compatibleRepositoriesPopup) ? newRepository : [self destinationRepository];
	SidebarNode* source		 = (sourceLabel      == compatibleRepositoriesPopup) ? newRepository : [self sourceRepository];
	[self setFieldsFromConnectionForSource:source  andDestination:destination];
	[self layoutGroupsForSource:           source  andDestination:destination];
	[self updateIncomingOutgoingCountForSource:source andDestination:destination];
	[advancedOptionsBox setNeedsDisplay:YES];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Window Delegate
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void)windowDidResize:(NSNotification*)notification
{
	[self recenterMainGroupingBox];
}


- (void) windowDidEndLiveResize:(NSNotification*)notification
{
	[self recenterMainGroupingBox];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Derived Generic Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) populateAndSetupPopupMenu:(NSPopUpButton*)popup withItems:(NSArray*)items
{
	[popup removeAllItems];
	for (SidebarNode* r in items)
	{
		NSMenuItem* item = [[NSMenuItem alloc]init];
		NSDictionary* attributesToApply = [r isServerRepositoryRef] ? italicSystemFontAttributes : systemFontAttributes;
		NSAttributedString* menuTitle = [NSAttributedString string:[r shortName] withAttributes:attributesToApply];
		[item setAttributedTitle:menuTitle];
		[item setRepresentedObject:r];
		[[popup menu] addItem:item];
	}
	[popup sizeToFit];
	[popup selectItemAtIndex:0];
}


- (IBAction) syncForceOptionToAllowOperationAndRepopulate:(id)sender
{
	[forceOption setOverallState:[sheetButtonAllowOperationWithAnyRepository state]];
	[self setConnectionFromFieldsForSource:[self sourceRepository] andDestination:[self destinationRepository]];
	BOOL showAdvancedOptions = [OptionController containsOptionWhichIsSet:cmdOptions];
	[disclosureController setToOpenState:showAdvancedOptions withAnimation:NO];
	[self populatePopupMenuItemsAndRelayout:sender];
}

- (IBAction) populatePopupMenuItemsAndRelayout:(id)sender
{
	SidebarNode* oppositeToPopup = (sourceLabel == compatibleRepositoriesPopup) ? [self destinationRepository] : [self sourceRepository];
	NSArray* items = [[[self myDocument] sidebar] orderedRepositoryListCompatibleTo:oppositeToPopup allowingAnyRepository:[sheetButtonAllowOperationWithAnyRepository state]];
	[self populateAndSetupPopupMenu:compatibleRepositoriesPopup withItems:items];
	[[compatibleRepositoriesPopup menu] setDelegate:self];
	[self setFieldsFromConnectionForSource:[self sourceRepository]  andDestination:[self destinationRepository]];
	[self layoutGroupsForSource:           [self sourceRepository]  andDestination:[self destinationRepository]];
}

- (void) setConnectionFromFieldsForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* partialKey = fstr(@"%@§%@§%@§", [self operationName], [source path], [destination path]);
	[OptionController setConnections:[[self myDocument] connections] fromOptions:cmdOptions  forKey:partialKey];
}

- (void) setFieldsFromConnectionForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* partialKey = fstr(@"%@§%@§%@§", [self operationName], [source path], [destination path]);
	[OptionController setOptions:cmdOptions fromConnections:[[self myDocument] connections] forKey:partialKey];
}

- (void) updateIncomingOutgoingCount	{ [self updateIncomingOutgoingCountForSource:[self sourceRepository] andDestination:[self destinationRepository]]; }
- (void) updateIncomingOutgoingCountForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination;
{
	NSString* theCount;
	if ([[self operationName] isMatchedByRegex:@"Push|Outgoing"])
		theCount = [[myDocument sidebar] outgoingCountTo:destination];
	else
		theCount = [[myDocument sidebar] incomingCountFrom:source];
	NSString* newValue = (!theCount || [theCount isEqualTo:@"-"]) ? @"": theCount;
	[incomingOutgoingCount setStringValue:newValue];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) sourceRepositoryName		{ return [[self sourceRepository] shortName]; }
- (NSString*) destinationRepositoryName	{ return [[self destinationRepository] shortName]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Sheet Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openSheet:(id)sender;
{
	// Compute the root of this repository for later comparison.
	SidebarNode* selectedNode = [[myDocument sidebar] selectedNode];
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
	[NSApp beginSheet:sheetWindow modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
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
	[sourceURI			 setStringValue:sourcePath];
	[sourceURI			 sizeToFit];

	[destinationIconWell setImage:destinationIconImage];
	[destinationURI		 setStringValue:destinationPath];
	[destinationURI		 sizeToFit];
	
	NSTextField* sourceLabelTextField      = DynamicCast(NSTextField, sourceLabel);
	NSTextField* destinationLabelTextField = DynamicCast(NSTextField, destinationLabel);
	if (sourceLabelTextField)
	{
		[sourceLabelTextField setStringValue:[source shortName]];
		[sourceLabelTextField sizeToFit];
	}
	if (destinationLabelTextField)
	{
		[destinationLabelTextField setStringValue:[destination shortName]];
		[destinationLabelTextField sizeToFit];
	}

	[mainGroupingBox growToFit];
	[self recenterMainGroupingBox];
	return;	
}


@end