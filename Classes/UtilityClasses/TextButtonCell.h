//
//  TextButtonCell.h
//  MacHg
//
//  Created by Jason Harris on 5/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TextButtonCell : NSButtonCell <NSTextAttachmentCell>
{
	NSTextAttachment* parentAttacment;
}

- (void) setButtonTitle:(NSString*)title;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)aView;
- (BOOL)wantsToTrackMouse;

@end
