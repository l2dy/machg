//
//  FSBrowserCell.m
//  Was based on some of apples code but has now been heavily modified.
//
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//


#import "FSNodeInfo.h"
#import "FSViewerPaneCell.h"
#import "AppController.h"
#import "FSViewer.h"


NSDictionary* fsStringAttributes(FSNodeInfo* nodeInfo);
void commonLoadCellContents(NSCell* cell)
{
	NSString* stringValue = [cell stringValue];
	FSNodeInfo* nodeInfo = [cell performSelectorIfPossible:@selector(nodeInfo)];
	if (!stringValue || !nodeInfo)
		return;

	// Set the text part.  FSNode will format the string (underline, bold, etc...) based on various properties of the file.
	NSAttributedString* attrStringValue = [NSAttributedString string:stringValue withAttributes:fsStringAttributes(nodeInfo)];
	[cell setAttributedStringValue:attrStringValue];
	
	// If we don't have access to the file, make sure the user can't select it!
	[cell setEnabled:[nodeInfo isReadable]];
	[cell setBackgroundStyle:NSBackgroundStyleLight];
	[cell setHighlighted:NO];
	if ([cell respondsToSelector:@selector(setFileIcon:)])
	{
		NSImage* theFileIcon = nil;
		if (DisplayFileIconsInBrowserFromDefaults())
			theFileIcon = [nodeInfo iconImageOfSize:NSMakeSize(ICON_SIZE, ICON_SIZE)];
		[(id)cell setFileIcon:theFileIcon];
	}
}




// ------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewerPaneCell
// ------------------------------------------------------------------------------------


@implementation FSViewerPaneCell

@synthesize nodeInfo = nodeInfo_;
@synthesize parentNodeInfo = parentNodeInfo_;

- (void) loadCellContents
{
	commonLoadCellContents(self);
}

+ (NSSize) iconRowSize:(FSNodeInfo*)parentNodeInfo
{
	int iconCount = parentNodeInfo ? [parentNodeInfo maxIconCountOfSubitems] : 1;
	return NSMakeSize(ICON_SIZE + floor(ICON_SIZE * (iconCount - 1)/IconOverlapCompression), ICON_SIZE);
}

@end




// ------------------------------------------------------------------------------------
// MARK: -
// MARK: FSViewerPaneIconedCell
// ------------------------------------------------------------------------------------

@implementation FSViewerPaneIconedCell

@synthesize fileIcon = fileIcon;


- (NSSize) cellSizeForBounds:(NSRect)aRect
{
	// Make our cells a bit higher than normal to give some additional space for the icon to fit.
	BOOL isOutlineCell = [self isKindOfClass:[FSViewerOutlinePaneIconedCell class]];
	NSSize theSize  = [super cellSizeForBounds:aRect];
	NSSize iconRowSize = [FSViewerPaneCell iconRowSize:self.parentNodeInfo];
	theSize.width += ICON_INSET_HORIZ + iconRowSize.width;
	if (isOutlineCell)
		theSize.width += DISCLOSURE_SPACING + DISCLOSURE_SIZE + DISCLOSURE_SPACING;
	if (fileIcon)
		theSize.width += ICON_INTERSPACING + ICON_SIZE;
	theSize.width += ICON_TEXT_SPACING;
	theSize.height = MAX(iconRowSize.height + ICON_INSET_VERT * 2.0, [self.attributedStringValue size].height + 5);
	return theSize;
}


static void drawImageAtPoint(NSImage* img, NSPoint pt, BOOL flipped)
{
	if (!flipped)
		[img drawAtPoint:pt fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	else
	{
		NSAffineTransform* transform = [NSAffineTransform transform];
		[transform translateXBy:pt.x yBy:pt.y];
		[transform scaleXBy:1.0 yBy:-1.0];
		[transform concat];
		[img drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[transform invert];
		[transform concat];
	}
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSImage* combinedIcon = [self.nodeInfo combinedIconImage];
	BOOL isOutlineCell = [self isKindOfClass:[FSViewerOutlinePaneIconedCell class]];
	BOOL hasChildren = IsNotEmpty([self.nodeInfo childNodes]);
	
	[self setDrawsBackground:NO];

	CGFloat iconRowWidth = [FSViewerPaneCell iconRowSize:self.parentNodeInfo].width;
	NSPoint drawPoint = cellFrame.origin;
	
	BOOL isFlipped = [controlView isFlipped];
	
	// Draw IconRow
	drawPoint.x += ICON_INSET_HORIZ;
	// Adjust the image frame top account for the fact that we may or may not be in a flipped control view,
	// since when compositing the online documentation states: "The image will have the orientation of the
	// base coordinate system, regardless of the destination coordinates".
	drawPoint.y += ceil((cellFrame.size.height + (isFlipped ? 1 : -1) * cellFrame.size.height) / 2);
	//drawPoint.y += isFlipped ? ceil(cellFrame.size.height) : 0;

	float heightDelta = cellFrame.size.height - combinedIcon.size.height;
	drawPoint.y -= floor(heightDelta/3);
	
	// Leave space that the disclosure triangle would take
	if (isOutlineCell && !hasChildren)
		drawPoint.x += DISCLOSURE_SPACING + DISCLOSURE_SIZE + DISCLOSURE_SPACING;
	
	drawPoint.x += iconRowWidth - combinedIcon.size.width;
	drawImageAtPoint(combinedIcon, drawPoint, isFlipped);
	drawPoint.x += combinedIcon.size.width;
	
	// Leave space for the disclosure triangle if present
	if (isOutlineCell && hasChildren)
		drawPoint.x += DISCLOSURE_SPACING + DISCLOSURE_SIZE + DISCLOSURE_SPACING;
	
	// Draw the fileIcon if present
	if (fileIcon)
	{
		drawPoint.x += ICON_INTERSPACING;
		drawImageAtPoint(fileIcon, drawPoint, isFlipped);
		drawPoint.x += fileIcon.size.width;
	}
	
	// Space before text
	drawPoint.x += ICON_TEXT_SPACING;
	
	// Comute the textFrame and draw it
	CGFloat xOffset = drawPoint.x - cellFrame.origin.x;
	NSRect textFrame = cellFrame;
	textFrame.size.width -= xOffset;
	textFrame.origin.x   += xOffset;
	[super drawInteriorWithFrame:textFrame inView:controlView];		// Have NSBrowserCell kindly draw the text part, since it knows how to
																	// do that for us, no need to re-invent what it knows how to do. 

}


// Expansion tool tip support
- (NSRect) expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView*)view
{
	// We could access our recommended cell size with self.cellSize and see if it fits in cellFrame, but NSBrowserCell already does this for us!
	NSRect expansionFrame = [super expansionFrameWithFrame:cellFrame inView:view];
	// If we do need an expansion frame, the rect will be non-empty. We need to move it over, and shrink it, since we won't be drawing the icon in it
	if (!NSIsEmptyRect(expansionFrame))
	{
		CGFloat iconsWidth = [FSViewerPaneCell iconRowSize:self.parentNodeInfo].width;
		expansionFrame.origin.x   = expansionFrame.origin.x   +  iconsWidth + ICON_INSET_HORIZ  + ICON_TEXT_SPACING;
		expansionFrame.size.width = expansionFrame.size.width - (iconsWidth + ICON_TEXT_SPACING + ICON_INSET_HORIZ / 2.0);
	}
	return expansionFrame;
}

- (void) drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView*)view
{
	// We want to ignore the image that is to be custom drawn, and just let the superclass handle the drawing. This will correctly draw just the text, but nothing else
	[super drawInteriorWithFrame:cellFrame inView:view];
}


@end



@implementation FSViewerOutlinePaneIconedCell

// Do drawing here.

@end







NSDictionary* fsStringAttributes(FSNodeInfo* nodeInfo)
{
	// Cache the two common attribute cases to help improve speed. This will be called a lot, and helps improve performance.
	static NSDictionary* standardAttributes = nil;
	static NSDictionary* italicAttributes   = nil;
	static NSDictionary* virtualAttributes  = nil;
	static NSDictionary* dirtyAttributes    = nil;
	static NSDictionary* grayedAttributes   = nil;
	static float storedFontSizeofBrowserItems = 0.0;
	
	if (standardAttributes == nil || storedFontSizeofBrowserItems != fontSizeOfBrowserItemsFromDefaults())
	{
		storedFontSizeofBrowserItems = fontSizeOfBrowserItemsFromDefaults();
		NSFontManager* fontManager   = [NSFontManager sharedFontManager];
		NSMutableParagraphStyle* ps  = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[ps setLineBreakMode:NSLineBreakByTruncatingMiddle];
		NSFont* textFont = [NSFont fontWithName:@"Verdana" size:storedFontSizeofBrowserItems];
		NSColor* greyColor = [NSColor grayColor];
		NSFont* italicTextFont = [fontManager convertFont:textFont toHaveTrait:NSItalicFontMask];
		NSFont* boldTextFont   = [fontManager convertFont:textFont toHaveTrait:NSBoldFontMask];
		
		standardAttributes = @{NSFontAttributeName: textFont, NSParagraphStyleAttributeName: ps};
		italicAttributes   = @{NSFontAttributeName: italicTextFont, NSParagraphStyleAttributeName: ps};
		grayedAttributes   = @{NSFontAttributeName: textFont, NSForegroundColorAttributeName: greyColor, NSParagraphStyleAttributeName: ps};
		dirtyAttributes    = @{NSFontAttributeName: boldTextFont, NSForegroundColorAttributeName: greyColor, NSParagraphStyleAttributeName: ps};
		virtualAttributes  = @{NSFontAttributeName: italicTextFont, NSParagraphStyleAttributeName: ps};
	}
	
	if ([nodeInfo isDirty])
		return dirtyAttributes;
	
	if ([[nodeInfo parentFSViewer] areNodesVirtual])
		return virtualAttributes;
	
	if ([nodeInfo isLink])
		return italicAttributes;
	
	if ([nodeInfo hgStatus] == eHGStatusIgnored)
		return grayedAttributes;
	
	return standardAttributes;
}

