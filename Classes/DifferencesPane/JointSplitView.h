//
//  JointSplitView.h
//  TestLinkedSubViews
//
//  Created by Jason Harris on 12/3/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>


@interface JointSplitView : NSObject
{
	IBOutlet NSSplitView*	splitViewOne;
	IBOutlet NSSplitView*	splitViewTwo;
}

- (void) splitViewDidResizeSubviews:(NSNotification*)aNotification;

@end
