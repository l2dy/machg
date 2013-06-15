//
//  FSViewerBrowser.h
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSViewer.h"

@interface FSViewerBrowser : NSBrowser <NSBrowserDelegate, FSViewerProtocol>
{
	NSViewController*	browserLeafPreviewController_;
	NSIndexPath*		lastSelectedIndexPath_;
}
@property (weak) FSViewer*	parentViewer;

@end
