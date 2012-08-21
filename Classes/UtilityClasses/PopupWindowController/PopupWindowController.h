//
//  PopupWindowController.h
//  MacHg
//
//  Created by Jason Harris on 2/3/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MAAttachedWindow.h"


@interface PopupWindowController : NSObject <NSWindowDelegate>
{
	IBOutlet NSButton*		displayButton;
	IBOutlet NSView*		popupContentView;
    MAAttachedWindow*		attachedPopupWindow;
	NSNumber*				__strong attachedPosition;
}
@property (readwrite,strong) NSNumber*	attachedPosition;

- (IBAction) toggleAttachedPopupWindow:(id)sender;

@end
