//
//  TitledButton.m
//  MacHg
//
//  Created by Jason Harris on 3/12/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ScrollToForLogTable.h"
#import "Common.h"
#import "MacHgDocument.h"
#import "RepositoryData.h"
#import "LogTableView.h"
#import "LabelData.h"

@implementation ScrollToForLogTable





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	tagToLabelDictionary	  = nil;	
	bookmarkToLabelDictionary = nil;
	branchToLabelDictionary   = nil;
	openHeadToLabelDictionary = nil;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Handle Clicks
// -----------------------------------------------------------------------------------------------------------------------------------------

- (RepositoryData*) repositoryData { return [[logTable myDocument] repositoryData]; }

- (NSMenuItem*) menuItemForLabel:(LabelData*)label
{
	NSMenuItem* item = [[NSMenuItem alloc]init];
	NSMutableAttributedString* menuTitle = [[NSMutableAttributedString alloc] init];
	if (IsEmpty([label name]))
		[menuTitle appendAttributedString:[NSAttributedString string:[label revision] withAttributes:systemFontAttributes]];
	else
	{
		[menuTitle appendAttributedString:[NSAttributedString string:[label name] withAttributes:systemFontAttributes]];
		[menuTitle appendAttributedString:[NSAttributedString string:[NSString stringWithFormat:@" (%@)",[label revision]] withAttributes:graySystemFontAttributes]];
	}
	[item setRepresentedObject:label];
	[item setTarget:self];
	[item setAction:@selector(scrollToLabel:)];
	[item setAttributedTitle:menuTitle];
	return item;
}

- (void) updatePopupMenu
{
	NSMenuItem* menuItemScrollToTag = [[NSMenuItem alloc] initWithTitle:@"Scroll to Tag" action:NULL keyEquivalent:@""];
	NSMenu* menuOfTags  = [[NSMenu alloc]init];
	tagToLabelDictionary = [[self repositoryData] tagToLabelDictionary];
	NSArray* sortedTagLabels = [[tagToLabelDictionary allValues] sortedArrayUsingDescriptors:[LabelData descriptorsForSortByRevisionAscending]];
	for (LabelData* label in sortedTagLabels)
		[menuOfTags addItem:[self menuItemForLabel:label]];
	[menuItemScrollToTag setSubmenu:menuOfTags];

	NSMenuItem* menuItemScrollToBookmark = [[NSMenuItem alloc] initWithTitle:@"Scroll to Bookmark" action:NULL keyEquivalent:@""];
	NSMenu* menuOfBookmarks  = [[NSMenu alloc]init];
	bookmarkToLabelDictionary = [[self repositoryData] bookmarkToLabelDictionary];
	NSArray* sortedBookmarkLabels = [[bookmarkToLabelDictionary allValues] sortedArrayUsingDescriptors:[LabelData descriptorsForSortByRevisionAscending]];
	for (LabelData* label in sortedBookmarkLabels)
		[menuOfBookmarks addItem:[self menuItemForLabel:label]];
	[menuItemScrollToBookmark setSubmenu:menuOfBookmarks];

	NSMenuItem* menuItemScrollToBranch = [[NSMenuItem alloc] initWithTitle:@"Scroll to Branch" action:NULL keyEquivalent:@""];
	NSMenu* menuOfBranches  = [[NSMenu alloc]init];
	branchToLabelDictionary = [[self repositoryData] branchToLabelDictionary];
	NSArray* sortedBranchLabels = [[branchToLabelDictionary allValues] sortedArrayUsingDescriptors:[LabelData descriptorsForSortByRevisionAscending]];
	for (LabelData* label in sortedBranchLabels)
		[menuOfBranches addItem:[self menuItemForLabel:label]];
	[menuItemScrollToBranch setSubmenu:menuOfBranches];

	NSMenuItem* menuItemScrollToOpenHead = [[NSMenuItem alloc] initWithTitle:@"Scroll to OpenHead" action:NULL keyEquivalent:@""];
	NSMenu* menuOfOpenHeads  = [[NSMenu alloc]init];
	openHeadToLabelDictionary = [[self repositoryData] openHeadToLabelDictionary];
	NSArray* sortedOpenHeadLabels = [[openHeadToLabelDictionary allValues] sortedArrayUsingDescriptors:[LabelData descriptorsForSortByRevisionAscending]];
	for (LabelData* label in sortedOpenHeadLabels)
		[menuOfOpenHeads addItem:[self menuItemForLabel:label]];
	[menuItemScrollToOpenHead setSubmenu:menuOfOpenHeads];
	
	NSMenu* newMenu = [[NSMenu alloc]init];
	[newMenu addItem:menuItemScrollToTag];
	[newMenu addItem:menuItemScrollToBookmark];
	[newMenu addItem:menuItemScrollToBranch];
	[newMenu addItem:menuItemScrollToOpenHead];
	thePopUpMenu = newMenu;	
	[thePopUpMenu setDelegate:self];
}


- (void) mouseDown:(NSEvent*)theEvent
{
	if (
		tagToLabelDictionary	  != [[self repositoryData] tagToLabelDictionary] ||
		bookmarkToLabelDictionary != [[self repositoryData] bookmarkToLabelDictionary] ||
		branchToLabelDictionary   != [[self repositoryData] branchToLabelDictionary] ||
		openHeadToLabelDictionary != [[self repositoryData] openHeadToLabelDictionary])
		[self updatePopupMenu];
	
	NSRect frame = [self frame];
	NSControlSize controlSize = [[self cell] controlSize];
	CGFloat offset = (controlSize == NSRegularControlSize) ? 3 : 4;
	
    NSPoint menuOrigin = [self convertPoint:NSMakePoint(0, frame.size.height + offset) toView:nil];	
	NSEvent* event = [NSEvent mouseEventWithType:NSLeftMouseDown location:menuOrigin modifierFlags:NSLeftMouseDownMask timestamp:[theEvent timestamp]
									windowNumber:[theEvent windowNumber] context:[theEvent context] eventNumber:[theEvent eventNumber] clickCount:1 pressure:1.0];
    [NSMenu popUpContextMenu:thePopUpMenu withEvent:event forView:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) scrollToLabel:(id)sender
{
	NSMenuItem* item = DynamicCast(NSMenuItem, sender);
	LabelData* label = DynamicCast(LabelData, [item representedObject]);
	if ([label revision])
		[logTable selectAndScrollToRevision:[label revision]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Menu Delegates
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) menuWillOpen:(NSMenu*)menu
{
	[self highlight:YES];
	[self needsDisplay];
}
- (void) menuDidClose:(NSMenu*)menu
{
	[self highlight:NO];
	[self needsDisplay];
}



@end
