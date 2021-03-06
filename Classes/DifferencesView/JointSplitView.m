//
//  JointSplitView.m
//  TestLinkedSubViews
//
//  Created by Jason Harris on 12/3/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "JointSplitView.h"


@implementation JointSplitView

- (CGFloat) firstPaneHeight:(NSSplitView*)theSplitView
{
	return [theSplitView.subviews[0] frame].size.height;
}

- (void) splitViewDidResizeSubviews:(NSNotification*)aNotification
{
	CGFloat svOnePosition = [self firstPaneHeight:splitViewOne];
	CGFloat svTwoPosition = [self firstPaneHeight:splitViewTwo ];

	if (aNotification.object == splitViewOne)
		if (svOnePosition != svTwoPosition)
			[splitViewTwo setPosition:svOnePosition ofDividerAtIndex:0];

	if (aNotification.object == splitViewTwo)
		if (svOnePosition != svTwoPosition)
			[splitViewOne setPosition:svTwoPosition ofDividerAtIndex:0];
}


@end
