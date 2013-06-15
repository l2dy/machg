//
//  FSViewerTable.h
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FSViewer.h"

@interface FSViewerTable : NSTableView <FSViewerProtocol, NSTableViewDelegate, NSTableViewDataSource>

@property (weak) FSViewer*		parentViewer;
@property (readonly) NSArray*	leafNodeForTableRow;	// Array FSNodeInfo* (each table row has the associated node)

@end



@interface FSViewerTableButtonCell : NSButtonCell

@property (weak) NSTableColumn*	tableColumn;
@property FSNodeInfo*			nodeInfo;

@end