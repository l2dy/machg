//
//  TextButtonCell.m
//  MacHg
//
//  Created by Jason Harris on 5/21/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "TextButtonCell.h"
#import "Common.h"

@implementation TextButtonCell


// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// ------------------------------------------------------------------------------------

- (id) init
{
	if ((self = [super init]))
	{
		[super setTarget:self];
		[super setAction:@selector(forwardActionAfterTrackedClick:)];
		trueTarget = nil;
		trueAction = nil;
	}
	return self;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Handling of targets & actions
// ------------------------------------------------------------------------------------

- (void) setTarget:(id)object
{
	trueTarget = object;
	[super setTarget:self];
}
- (void) setAction:(SEL)action
{
	trueAction = action;
	[super setAction:@selector(forwardActionAfterTrackedClick:)];
}

- (IBAction) forwardActionAfterTrackedClick:(id)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	if (doActionAfterTrack)
		[trueTarget performSelector:trueAction withObject:sender];
#pragma clang diagnostic pop
}

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
		theDictionary = @{NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraphStyle};
	}
	[self setAttributedTitle:[NSAttributedString string:title withAttributes:theDictionary]];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Tracking for NSTextAttachmentCell Protocol
// ------------------------------------------------------------------------------------



- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView*)controlView
{
	doActionAfterTrack = YES;
	return YES;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)currentPoint inView:(NSView*)controlView
{
	if (!NSPointInRect(currentPoint, currentCellFrame) && NSPointInRect(lastPoint, currentCellFrame))
		[self highlight:NO withFrame:currentCellFrame inView:controlView];
	else if (NSPointInRect(currentPoint, currentCellFrame) && !NSPointInRect(lastPoint, currentCellFrame))
		[self highlight:YES withFrame:currentCellFrame inView:controlView];
	return YES;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView*)controlView mouseIsUp:(BOOL)flag
{
	doActionAfterTrack = NSPointInRect(stopPoint, currentCellFrame) && flag;
}


- (BOOL)wantsToTrackMouse
{
	return YES;
}

- (BOOL)wantsToTrackMouseForEvent:(NSEvent*)theEvent inRect:(NSRect)cellFrame ofView:(NSView*)controlView atCharacterIndex:(NSUInteger)charIndex
{
	return YES;
}

- (BOOL)trackMouse:(NSEvent*)theEvent inRect:(NSRect)cellFrame ofView:(NSView*)aTextView atCharacterIndex:(NSUInteger)charIndex untilMouseUp:(BOOL)flag
{
	currentCellFrame = cellFrame;
	[self highlight:YES withFrame:cellFrame inView:aTextView];
	BOOL ans = [super trackMouse:theEvent inRect:cellFrame ofView:aTextView untilMouseUp:YES];
	[self highlight:NO withFrame:cellFrame inView:aTextView];
	return ans;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Drawing for NSTextAttachmentCell Protocol
// ------------------------------------------------------------------------------------

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)aView
{
	[super drawWithFrame:cellFrame inView:aView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	cellFrame.origin.y -= 1;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)aView characterIndex:(NSUInteger)charIndex
{
	[self drawWithFrame:cellFrame inView:aView];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager*)layoutManager
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Parent Attachment
// ------------------------------------------------------------------------------------

- (NSTextAttachment*)attachment	{ return parentAttacment; }
- (void)setAttachment:(NSTextAttachment*) anAttachment
{
	parentAttacment = anAttachment;
}

@end
