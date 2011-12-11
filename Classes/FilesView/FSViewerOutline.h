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
	FSViewer*	parentViewer_;
}
@property (readwrite, assign) FSViewer*	parentViewer;

@end
