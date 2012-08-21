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
	LogEntry*		__strong entry_;				// The entry backing this cell
	LogTableView*	__strong logTableView;		// This is the table view containing this cell.
	NSTableColumn*	__strong logTableColumn_;	// This is the table column of the LogTableView containing this LogGraphCell.
}

@property (readwrite,strong) LogEntry*			entry;
@property (readwrite,strong) LogTableView*		logTableView;
@property (readwrite,strong) NSTableColumn*		logTableColumn;

- (void)	drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView;
- (void)	drawGraphDot:(NSPoint) dotCenter;
- (NSSize)	cellSize;

@end
