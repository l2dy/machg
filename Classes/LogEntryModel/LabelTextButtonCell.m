//
//  LabelTextButtonCell.m
//  MacHg
//
//  Created by Jason Harris on 5/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "LabelTextButtonCell.h"
#import "MacHgDocument.h"
#import "LabelData.h"
#import "RepositoryData.h"



@implementation LabelTextButtonCell

@synthesize entry = entry_;
@synthesize label = label_;


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]))
	{
		label_ = nil;
		entry_ = nil;
	}
	return self;
}


- (id) initWithLabel:(LabelData*)label andLogEntry:(LogEntry*)entry
{
	if ((self = [super init]))
	{
		label_ = label;
		entry_ = entry;
	}
	return self;
}


+ (NSTextAttachment*) labelButtonAttachmentWithLabel:(LabelData*)label andLogEntry:(LogEntry*)entry
{
	NSTextAttachment* attachment   = [[NSTextAttachment alloc] init];
	LabelTextButtonCell* labelCell = [[LabelTextButtonCell alloc] initWithLabel:label andLogEntry:entry];
	[labelCell setButtonTitle:[label name]];
	[labelCell setBezelStyle:NSRoundRectBezelStyle];
	[labelCell setTarget:labelCell];
	[labelCell setAction:@selector(gotoLabel:)];
	[attachment setAttachmentCell:labelCell];
	return attachment;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Set members
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setButtonTitle:(NSString*)title
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		//NSFont* textFont = [NSFont fontWithName:@"Verdana" size:[NSFont smallSystemFontSize]];
		NSFont* font = [NSFont fontWithName:@"Helvetica"  size:[NSFont smallSystemFontSize]];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	[self setAttributedTitle:[NSAttributedString string:title withAttributes:theDictionary]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) gotoLabel:(id)sender
{
	MacHgDocument* document = [[entry_ repositoryData] myDocument];
}


- (NSRect) buttonFrameSize
{
	NSAttributedString* title = [self attributedTitle];
	NSSize s = [title size];
	return NSMakeRect(0, -7, s.width + 5, 19);	
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)aView
{
	NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:4.0 yRadius:4.0];

	static NSColor* defaultRed;
	if (!defaultRed)
		defaultRed = [NSColor colorWithCalibratedRed:0.5 green:0.0 blue:0.0 alpha:1.0];
	NSColor* fillColor   = defaultRed;
	NSColor* strokeColor = nil;
	
	if ([[entry_ repositoryData] incompleteRevisionEntry] == entry_)
	{
		fillColor   = [NSColor whiteColor];
		strokeColor = [NSColor grayColor];
	}
	else if ([[entry_ repositoryData] revisionIsParent:[entry_ revision]])
	{
		fillColor   = [LogEntryTableParentHighlightColor() intensifySaturationAndBrightness:4.0];
		strokeColor = defaultRed;
	}
	else if (IsNotEmpty([entry_ branch]))
	{
		fillColor   = [LogEntryTableBranchHighlightColor() intensifySaturationAndBrightness:4.0];
		strokeColor = defaultRed;
	}
	else if (IsNotEmpty([entry_ bookmarks]))
	{
		fillColor = [LogEntryTableBookmarkHighlightColor() intensifySaturationAndBrightness:4.0];
		strokeColor = defaultRed;
	}
	else if (IsNotEmpty([entry_ tags]))
	{
		fillColor = [LogEntryTableTagHighlightColor() intensifySaturationAndBrightness:4.0];
		strokeColor = defaultRed;
	}
	
	if (fillColor)
	{
		[fillColor set];
		[path fill];
	}
	if (strokeColor)
	{
		[strokeColor set];
		[path stroke];
	}
	
	[super drawInteriorWithFrame:cellFrame inView:aView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	cellFrame.origin.y -= 1;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}



@end
