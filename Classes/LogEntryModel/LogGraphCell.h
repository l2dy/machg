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

// These variables reference the table view in which this cell is based, and they get set in tableView:willDisplayCell:...
@property LogEntry*				entry;				// The entry backing this cell
@property (weak) LogTableView*	logTableView;		// This is the table view containing this cell.
@property (weak) NSTableColumn*	logTableColumn;		// This is the table column of the LogTableView containing this LogGraphCell.

- (void)	drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView;
- (void)	drawGraphDot:(NSPoint) dotCenter;
- (NSSize)	cellSize;

@end
