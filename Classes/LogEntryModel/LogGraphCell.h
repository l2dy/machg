//
//  LogGraphCell.h
//  MacHg
//
//  Created by Jason Harris on 25/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface LogGraphCell : NSImageCell
{
	// These variables reference the table view in which this cell is based, and they get set in tableView:willDisplayCell:...
	LogEntry*		entry_;				// The entry backing this cell
	LogTableView*	logTableView;		// This is the table view containing this cell.
	NSTableColumn*	logTableColumn_;	// This is the table column of the LogTableView containing this LogGraphCell.
	NSInteger		theColumn;			// The column number of the node in the graph.
}

@property (readwrite,assign) LogEntry*			entry;
@property (readwrite,assign) LogTableView*		logTableView;
@property (readwrite,assign) NSTableColumn*		logTableColumn;
@property (readwrite,assign) NSInteger			theColumn;

- (void)		drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView;
- (NSSize)		cellSize;

@end
