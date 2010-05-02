//
//  JointSplitView.h
//  TestLinkedSubViews
//
//  Created by Jason Harris on 12/3/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JointSplitView : NSObject
{
	IBOutlet NSSplitView*	splitViewOne;
	IBOutlet NSSplitView*	splitViewTwo;
}

- (void) splitViewDidResizeSubviews:(NSNotification*)aNotification;

@end
