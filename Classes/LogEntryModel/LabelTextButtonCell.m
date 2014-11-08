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


// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// ------------------------------------------------------------------------------------

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
	labelCell.buttonTitle = label.name;
	labelCell.bezelStyle = NSRoundRectBezelStyle;
	labelCell.target = labelCell;
	[labelCell setAction:@selector(gotoLabel:)];
	attachment.attachmentCell = labelCell;
	return attachment;
}



// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Set members
// ------------------------------------------------------------------------------------

- (void) setButtonTitle:(NSString*)title
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		paragraphStyle.paragraphStyle = NSParagraphStyle.defaultParagraphStyle;
		paragraphStyle.alignment = NSCenterTextAlignment;
		NSFont* font = [NSFont fontWithName:@"Helvetica"  size:NSFont.smallSystemFontSize];
		theDictionary = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle};
	}
	[self setAttributedTitle:[NSAttributedString string:title withAttributes:theDictionary]];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// ------------------------------------------------------------------------------------

- (IBAction) gotoLabel:(id)sender
{
	// I am not sure what action clicking on the label should have for now.
	//	MacHgDocument* document = entry_.repositoryData.myDocument;
	//	if (!document.showingASheet && document.showingHistoryView)
}


- (NSRect) buttonFrameSize
{
	NSAttributedString* title = self.attributedTitle;
	NSSize s = title.size;
	return NSMakeRect(0, -5, s.width + 15, 15);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)aView
{
	NSRect newRect = cellFrame;
	newRect.origin.y -= 0.5;
	newRect.origin.x += 0.5;
	newRect.size.width -= 1.0;
	NSBezierPath* path   = [NSBezierPath bezierPathWithRoundedRect:newRect xRadius:4.0 yRadius:4.0];
	NSColor* fillColor   = NSColor.lightGrayColor;
	NSColor* strokeColor = NSColor.blackColor;

	path.lineWidth = 0;
	if (label_.isBranch)
		fillColor   = LogEntryTableBranchHighlightColor();
	else if (label_.isBookmark)
		fillColor = LogEntryTableBookmarkHighlightColor();
	else if (label_.isTag)
		fillColor = LogEntryTableTagHighlightColor();
	
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

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	cellFrame.origin.y -= 1;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}



@end
