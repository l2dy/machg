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
{
	NSArray*	leafNodeForTableRow_;				// Array FSNodeInfo* (each table row has the associated node)
	FSViewer*	parentViewer_;
}
@property (readwrite, assign) FSViewer*	parentViewer;

- (NSArray*) leafNodeForTableRow;

@end



@interface FSViewerTableButtonCell : NSButtonCell
{
	//IBOutlet NSTextField* buttonMessage;
	NSTableColumn*		tableColumn_;
	FSNodeInfo*			nodeInfo_;
}
@property (assign,readwrite) NSTableColumn*	tableColumn;
@property (assign,readwrite) FSNodeInfo*	nodeInfo;

@end