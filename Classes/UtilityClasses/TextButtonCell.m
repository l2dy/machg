//
//  TextButtonCell.m
//  MacHg
//
//  Created by Jason Harris on 5/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TextButtonCell.h"
#import "Common.h"

@implementation TextButtonCell


- (NSRect) buttonFrameSize
{
	NSAttributedString* title = [self attributedTitle];
	NSSize s = [title size];
	return NSMakeRect(0, -7, s.width + 30, 22);	
}

- (void) setButtonTitle:(NSString*)title
{
	static NSDictionary* theDictionary = nil;
	if (theDictionary == nil)
	{
		NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
		[paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		NSFont* font = [NSFont controlContentFontOfSize:[NSFont systemFontSize]];
		theDictionary = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
	}
	[self setAttributedTitle:[NSAttributedString string:title withAttributes:theDictionary]];
}



- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)aView
{
	[super drawWithFrame:cellFrame inView:aView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	cellFrame.origin.y -= 1;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (BOOL)wantsToTrackMouse
{
	return YES;
}

- (BOOL)wantsToTrackMouseForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(NSUInteger)charIndex
{
	return YES;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)aTextView atCharacterIndex:(NSUInteger)charIndex untilMouseUp:(BOOL)flag
{
	return [self trackMouse:theEvent inRect:cellFrame ofView:aTextView untilMouseUp:flag];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)aView characterIndex:(NSUInteger)charIndex
{
	[self drawWithFrame:cellFrame inView:aView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *)layoutManager
{
	[self drawWithFrame:cellFrame inView:controlView];
}

- (NSPoint)cellBaselineOffset
{
	NSRect titleRect = [self titleRectForBounds:[self buttonFrameSize]];
	CGFloat baseline = ceil(NSMinY(titleRect) + [[self font] ascender]);
	return NSMakePoint(0, baseline);
}

- (NSRect)cellFrameForTextContainer:(NSTextContainer*)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(NSPoint)position characterIndex:(NSUInteger)charIndex
{
	return [self buttonFrameSize];
}

- (NSTextAttachment *)attachment
{
	return parentAttacment;
}

- (void)setAttachment:(NSTextAttachment *)anAttachment
{
	parentAttacment = anAttachment;
}

@end
