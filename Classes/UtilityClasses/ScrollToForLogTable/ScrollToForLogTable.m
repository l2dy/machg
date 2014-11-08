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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// ------------------------------------------------------------------------------------

- (void) awakeFromNib
{
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Handle Clicks
// ------------------------------------------------------------------------------------

- (RepositoryData*) repositoryData { return logTable.myDocument.repositoryData; }

- (NSMenuItem*) menuItemForLabel:(LabelData*)label
{
	NSMenuItem* item = [[NSMenuItem alloc]init];
	NSMutableAttributedString* menuTitle = [[NSMutableAttributedString alloc] init];
	if (IsEmpty(label.name))
		[menuTitle appendAttributedString:[NSAttributedString string:label.revisionStr withAttributes:systemFontAttributes]];
	else
	{
		[menuTitle appendAttributedString:[NSAttributedString string:label.name withAttributes:systemFontAttributes]];
		[menuTitle appendAttributedString:[NSAttributedString string:fstr(@" (%@)",label.revision) withAttributes:graySystemFontAttributes]];
	}
	item.representedObject = label;
	item.target = self;
	[item setAction:@selector(scrollToLabel:)];
	item.attributedTitle = menuTitle;
	return item;
}

- (void) updatePopupMenu
{
	NSMenuItem* menuItemScrollToTag = [[NSMenuItem alloc] initWithTitle:@"Scroll to Tag" action:NULL keyEquivalent:@""];
	NSMenu* menuOfTags  = [[NSMenu alloc]init];
	NSArray* tagLabels = [LabelData filterLabelsDictionary: self.repositoryData.revisionNumberToLabels  byType:eTagLabel];
	NSArray* sortedTagLabels = [tagLabels sortedArrayUsingDescriptors:LabelData.descriptorsForSortByRevisionAscending];
	for (LabelData* label in sortedTagLabels)
		[menuOfTags addItem:[self menuItemForLabel:label]];
	menuItemScrollToTag.submenu = menuOfTags;

	
	NSMenuItem* menuItemScrollToBookmark = [[NSMenuItem alloc] initWithTitle:@"Scroll to Bookmark" action:NULL keyEquivalent:@""];
	NSMenu* menuOfBookmarks  = [[NSMenu alloc]init];
	NSArray* bookmarkLabels = [LabelData filterLabelsDictionary: self.repositoryData.revisionNumberToLabels  byType:eBookmarkLabel];
	NSArray* sortedBookmarkLabels = [bookmarkLabels sortedArrayUsingDescriptors:LabelData.descriptorsForSortByRevisionAscending];
	for (LabelData* label in sortedBookmarkLabels)
		[menuOfBookmarks addItem:[self menuItemForLabel:label]];
	menuItemScrollToBookmark.submenu = menuOfBookmarks;

	
	NSMenuItem* menuItemScrollToBranch = [[NSMenuItem alloc] initWithTitle:@"Scroll to Branch" action:NULL keyEquivalent:@""];
	NSMenu* menuOfBranches  = [[NSMenu alloc]init];
	NSArray* branchLabels = [LabelData filterLabelsDictionary: self.repositoryData.revisionNumberToLabels  byType:eBranchLabel];
	NSArray* sortedBranchLabels = [branchLabels sortedArrayUsingDescriptors:LabelData.descriptorsForSortByRevisionAscending];
	for (LabelData* label in sortedBranchLabels)
		[menuOfBranches addItem:[self menuItemForLabel:label]];
	menuItemScrollToBranch.submenu = menuOfBranches;

	
	NSMenuItem* menuItemScrollToOpenHead = [[NSMenuItem alloc] initWithTitle:@"Scroll to OpenHead" action:NULL keyEquivalent:@""];
	NSMenu* menuOfOpenHeads  = [[NSMenu alloc]init];
	NSArray* openHeadLabels = [LabelData filterLabelsDictionary: self.repositoryData.revisionNumberToLabels  byType:eOpenHead];
	NSArray* sortedOpenHeadLabels = [openHeadLabels sortedArrayUsingDescriptors:LabelData.descriptorsForSortByRevisionAscending];
	for (LabelData* label in sortedOpenHeadLabels)
		[menuOfOpenHeads addItem:[self menuItemForLabel:label]];
	menuItemScrollToOpenHead.submenu = menuOfOpenHeads;

	NSMenuItem* scrollToChangesetItem = [[NSMenuItem alloc] initWithTitle:@"Scroll to Changeset…" action:@selector(getAndScrollToChangeset:) keyEquivalent:@"l"];
	scrollToChangesetItem.target = logTable;
		
	
	NSMenu* newMenu = [[NSMenu alloc]init];
	[newMenu addItem:menuItemScrollToTag];
	[newMenu addItem:menuItemScrollToBookmark];
	[newMenu addItem:menuItemScrollToBranch];
	[newMenu addItem:menuItemScrollToOpenHead];
	[newMenu addItem:NSMenuItem.separatorItem];
	[newMenu addItem:scrollToChangesetItem];
	thePopUpMenu = newMenu;
	thePopUpMenu.delegate = self;
}


- (void) mouseDown:(NSEvent*)theEvent
{
	[self updatePopupMenu];
	
	NSRect frame = self.frame;
	NSControlSize controlSize = [self.cell controlSize];
	CGFloat offset = (controlSize == NSRegularControlSize) ? 3 : 4;
	
    NSPoint menuOrigin = [self convertPoint:NSMakePoint(0, frame.size.height + offset) toView:nil];
	NSEvent* event = [NSEvent mouseEventWithType:NSLeftMouseDown location:menuOrigin modifierFlags:NSLeftMouseDownMask timestamp:theEvent.timestamp
									windowNumber:theEvent.windowNumber context:theEvent.context eventNumber:theEvent.eventNumber clickCount:1 pressure:1.0];
    [NSMenu popUpContextMenu:thePopUpMenu withEvent:event forView:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// ------------------------------------------------------------------------------------

- (IBAction) scrollToLabel:(id)sender
{
	NSMenuItem* item = DynamicCast(NSMenuItem, sender);
	LabelData* label = DynamicCast(LabelData, item.representedObject);
	if (label.revision)
		[logTable selectAndScrollToRevision:label.revision];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Menu Delegates
// ------------------------------------------------------------------------------------

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
