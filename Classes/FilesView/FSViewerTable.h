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
	FSViewer*	__strong parentViewer_;
}
@property (readwrite, strong) FSViewer*	parentViewer;

- (NSArray*) leafNodeForTableRow;

@end



@interface FSViewerTableButtonCell : NSButtonCell
{
	//IBOutlet NSTextField* buttonMessage;
	NSTableColumn*		__strong tableColumn_;
	FSNodeInfo*			__strong nodeInfo_;
}
@property (strong,readwrite) NSTableColumn*	tableColumn;
@property (strong,readwrite) FSNodeInfo*	nodeInfo;

@end