//
//  FSBrowserCell.h
//
//  Copyright (c) 2001-2007, Apple Inc. All rights reserved.
//
//  FSBrowserCell knows how to display file system info obtained from an FSNodeInfo object.
//
//  Extensively modified by Jason Harris.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

#define ICON_INSET_VERT		 2.0	// The size of empty space between the icon end the top/bottom of the cell
#define ICON_SIZE			16.0	// Our Icons are ICON_SIZE x ICON_SIZE
#define ICON_INSET_HORIZ 	 4.0	// Distance to inset the icon from the left edge.
#define ICON_INTERSPACING	 5.0	// Distance between the status icons and the file icon if the file icon is present.
#define ICON_TEXT_SPACING	 4.0	// Distance between the end of the icon and the text part


@interface FSViewerPaneCell : NSTextFieldCell
{
  @private
	NSImage*	fileIcon;
	FSNodeInfo* nodeInfo;
	FSNodeInfo* parentNodeInfo;
}

@property (readwrite,assign) NSImage*		fileIcon;
@property (readwrite,assign) FSNodeInfo*	nodeInfo;
@property (readwrite,assign) FSNodeInfo*	parentNodeInfo;

- (void)		loadCellContents;
- (FSViewer*)	parentFSViewer;
@end
