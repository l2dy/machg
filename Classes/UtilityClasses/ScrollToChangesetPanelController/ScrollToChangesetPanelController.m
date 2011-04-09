//
//  ScrollToChangesetPanelController.m
//  MacHg
//
//  Created by Jason Harris on 4/4/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import "ScrollToChangesetPanelController.h"

static ScrollToChangesetPanelController* sharedScrollToChangesetPanelController_ = nil;

@implementation ScrollToChangesetPanelController

// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: ScrollTo Panel
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (ScrollToChangesetPanelController*) sharedScrollToChangesetPanelController
{
	if (!sharedScrollToChangesetPanelController_)
	{
		sharedScrollToChangesetPanelController_ = [[ScrollToChangesetPanelController alloc]init];
		[NSBundle loadNibNamed:@"ScrollToChangesetPanel" owner:sharedScrollToChangesetPanelController_];		
		[sharedScrollToChangesetPanelController_->scrollToChangesetPanel center];
	}
	return sharedScrollToChangesetPanelController_;
}


- (NSString*) getChangesetToScrollTo
{
	[scrollToChangesetPanel makeKeyAndOrderFront:nil];
	NSInteger result = [NSApp runModalForWindow:scrollToChangesetPanel];
	
	if (result == NSRunAbortedResponse)
		return nil;
	if (result == NSRunStoppedResponse)
		return [scrollToChangesetPanelField stringValue];
	return nil;
}

- (IBAction) scrollToPanelButtonScrollTo:(id)sender
{
	[NSApp stopModal];
	[scrollToChangesetPanel orderOut:self];
}
- (IBAction) scrollToPanelButtonCancel:(id)sender
{
	[NSApp abortModal];
	[scrollToChangesetPanel orderOut:self];
}

@end
