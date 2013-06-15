//
//  TextButtonCell.h
//  MacHg
//
//  Created by Jason Harris on 5/21/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>


@interface TextButtonCell : NSButtonCell <NSTextAttachmentCell>
{
	NSTextAttachment* __weak	parentAttacment;
	NSRect						currentCellFrame;		// We cache this for use during tracking since this buttoncell doesn't actually
														// live in a control view.
	id __weak					trueTarget;				// We intercept the target to be ourselves so store the true target if we actually
														// want to send the true action to the true target
	SEL							trueAction;				// We intercept the target to be ourselves so store the true action if we actually
														// want to send the true action to the true target
	BOOL						doActionAfterTrack;		// After finishing the tracking should we actually send the action to the target?
}

- (void) setButtonTitle:(NSString*)title;
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)aView;
- (BOOL)wantsToTrackMouse;

@end
