//
//  FSBrowserCell.m
//  Was based on some of apples code but has now been heavily modified.
//
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//


#import "FSNodeInfo.h"
#import "FSBrowserCell.h"
#import "AppController.h"
#import "FSViewer.h"

#define iconOverlapCompression 3	// This controls how squished the icons look when there are multiple icons representing the
									// status of a directory. With this setting just a 3rd of an icon pokes out behind the icon in
									// front of it. This looks to be a nice balance between composite images not being too large
									// and still seeing the multiple icons which make up the status.

@interface FSBrowserCell(PrivateUtilities)
- (NSDictionary*) fsStringAttributes;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: FSBrowserCell
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation FSBrowserCell

@synthesize fileIcon;
@synthesize nodeInfo;
@synthesize parentNodeInfo;

- (id) init
{
	self = [super init];
	if (self)
		fileIcon = nil;
	return self;
}


- (FSViewer*) parentFSViewer { return [nodeInfo parentFSViewer]; }


- (void) loadCellContents
{
	// Given a particular FSNodeInfo object set up our display properties.
	NSString* stringValue = [nodeInfo lastPathComponent];
	if (!stringValue)
		return;

	// Set the text part.  FSNode will format the string (underline, bold, etc...) based on various properties of the file.
	NSDictionary* attributesToApply = [self fsStringAttributes];
	NSAttributedString* attrStringValue = [NSAttributedString string:stringValue withAttributes:attributesToApply];
	[self setAttributedStringValue:attrStringValue];
	
	if (DisplayFileIconsInBrowserFromDefaults())
	{
		NSSize imageSize = NSMakeSize(ICON_SIZE, ICON_SIZE);
		NSImage* theFileIcon = [nodeInfo iconImageOfSize:imageSize];
		[self setFileIcon:theFileIcon];
	}
	else
		[self setFileIcon:nil];


	// If we don't have access to the file, make sure the user can't select it!
	[self setEnabled:[nodeInfo isReadable]];
	[self setBackgroundStyle:NSBackgroundStyleLight];
	[self setHighlighted:NO];
}


- (NSSize) cellSizeForBounds:(NSRect)aRect
{
	// Make our cells a bit higher than normal to give some additional space for the icon to fit.
	NSSize theSize = [super cellSizeForBounds:aRect];
	NSSize iconSize = NSMakeSize(ICON_SIZE, ICON_SIZE);
	theSize.width += iconSize.width + ICON_INSET_HORIZ + ICON_TEXT_SPACING;
	theSize.height = MAX(ICON_SIZE + ICON_INSET_VERT*  2.0, [[self attributedStringValue] size].height + 5);
	return theSize;
}




- (CGFloat) iconRowSize
{
	int iconCount = [parentNodeInfo maxIconCountOfSubitems];
	return ICON_SIZE + floor(ICON_SIZE * (iconCount - 1)/iconOverlapCompression);
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSArray* icons = [nodeInfo notableIconImages];
	NSSize imageSize = NSMakeSize(ICON_SIZE, ICON_SIZE);
	NSRect imageFrame, textFrame;
	
	// Divide the cell into 2 parts, the image part (on the left) and the text part.
	
	NSDivideRect(cellFrame, &imageFrame, &textFrame, ICON_INSET_HORIZ + [self iconRowSize] + (fileIcon ? ICON_INTERSPACING + ICON_SIZE: 0) + ICON_TEXT_SPACING, NSMinXEdge);
	imageFrame.origin.x += ICON_INSET_HORIZ;
	imageFrame.size = imageSize;
	
	// Adjust the image frame top account for the fact that we may or may not be in a flipped control view,
	// since when compositing the online documentation states: "The image will have the orientation of the
	// base coordinate system, regardless of the destination coordinates".
	imageFrame.origin.y += ceil((textFrame.size.height + ([controlView isFlipped] ? 1 : -1) * imageFrame.size.height) / 2);
	
	[self setDrawsBackground:NO];

	// If we have fewer icons than the maximum, then inset the origin accordingly so that the icons are right aligned
	imageFrame.origin.x += (((CGFloat)[parentNodeInfo maxIconCountOfSubitems]) - ((CGFloat)[icons count])) * ICON_SIZE / iconOverlapCompression;


	for (NSImage* icon in icons)
	{
		[icon compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver fraction:1.0];
		imageFrame.origin.x += imageSize.width / iconOverlapCompression;
	}

	// If we are including file icons then draw it after the status icon
	if (fileIcon)
	{
		imageFrame.origin.x -= imageSize.width / iconOverlapCompression;
		imageFrame.origin.x += ICON_SIZE + ICON_INTERSPACING;
		[fileIcon compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver fraction:1.0];
	}
	
	// Have NSBrowserCell kindly draw the text part, since it knows how to do that for us, no need to re-invent what it knows how to do.
	[super drawInteriorWithFrame:textFrame inView:controlView];
}


// Expansion tool tip support
- (NSRect) expansionFrameWithFrame:(NSRect)cellFrame inView:(NSView*)view
{
	// We could access our recommended cell size with [self cellSize] and see if it fits in cellFrame, but NSBrowserCell already does this for us!
	NSRect expansionFrame = [super expansionFrameWithFrame:cellFrame inView:view];
	// If we do need an expansion frame, the rect will be non-empty. We need to move it over, and shrink it, since we won't be drawing the icon in it
	if (!NSIsEmptyRect(expansionFrame))
	{
		CGFloat iconsSize = [self iconRowSize];
		expansionFrame.origin.x   = expansionFrame.origin.x   +  iconsSize + ICON_INSET_HORIZ  + ICON_TEXT_SPACING;
		expansionFrame.size.width = expansionFrame.size.width - (iconsSize + ICON_TEXT_SPACING + ICON_INSET_HORIZ / 2.0);
	}
	return expansionFrame;
}

- (void) drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView*)view
{
	// We want to ignore the image that is to be custom drawn, and just let the superclass handle the drawing. This will correctly draw just the text, but nothing else
	[super drawInteriorWithFrame:cellFrame inView:view];
}

- (NSDictionary*) fsStringAttributes
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
		
		standardAttributes = [NSDictionary dictionaryWithObjectsAndKeys: textFont,       NSFontAttributeName, ps, NSParagraphStyleAttributeName, nil];
		italicAttributes   = [NSDictionary dictionaryWithObjectsAndKeys: italicTextFont, NSFontAttributeName, ps, NSParagraphStyleAttributeName, nil];
		grayedAttributes   = [NSDictionary dictionaryWithObjectsAndKeys: textFont,       NSFontAttributeName, greyColor, NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, nil];
		dirtyAttributes    = [NSDictionary dictionaryWithObjectsAndKeys: boldTextFont,   NSFontAttributeName, greyColor, NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, nil];
		virtualAttributes  = [NSDictionary dictionaryWithObjectsAndKeys: italicTextFont, NSFontAttributeName, ps, NSParagraphStyleAttributeName, nil];
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

@end


