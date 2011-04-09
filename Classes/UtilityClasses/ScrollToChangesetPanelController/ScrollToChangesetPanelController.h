//
//  ScrollToChangesetPanelController.h
//  MacHg
//
//  Created by Jason Harris on 4/4/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface ScrollToChangesetPanelController : BaseSheetWindowController
{
	IBOutlet NSPanel*			scrollToChangesetPanel;
	IBOutlet NSTextField*		scrollToChangesetPanelField;
}

+ (ScrollToChangesetPanelController*) sharedScrollToChangesetPanelController;

- (NSString*) getChangesetToScrollTo;
- (IBAction)  scrollToPanelButtonScrollTo:(id)sender;
- (IBAction)  scrollToPanelButtonCancel:(id)sender;


@end
