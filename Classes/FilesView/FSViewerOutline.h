//
//  FSViewerOutline.h
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSViewer.h"

@interface FSViewerOutline : NSOutlineView <FSViewerProtocol, NSOutlineViewDelegate, NSOutlineViewDataSource>
{
	NSMutableSet*	expandedNodes_;					// The set of NSString* of which nodes need to be expanded in outline view
}
@property (weak) FSViewer*	parentViewer;

- (void) saveExpandedStateToUserDefaults;
- (void) restoreExpandedStateFromUserDefaults;

@end
