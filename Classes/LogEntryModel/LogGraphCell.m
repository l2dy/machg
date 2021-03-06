//
//  LogGraphCell.m
//  MacHg
//
//  Created by Jason Harris on 25/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LogGraphCell.h"
#import "LogGraph.h"
#import "LogEntry.h"
#import "LogTableView.h"
#import <AppKit/NSCell.h>
#import "RepositoryData.h"


@implementation LogGraphCell


@synthesize entry = entry_;
@synthesize logTableView = logTableView;
@synthesize logTableColumn = logTableColumn_;


- (id) copyWithZone:(NSZone*)zone
{
    LogGraphCell* cell = (LogGraphCell*)[super copyWithZone:zone];
    // The image ivar will be directly copied; we need to retain or copy it.
    return cell;
}



- (CGFloat) columnSpacingWithinFrame:(NSRect)bounds
{
	RepositoryData* data = logTableView.repositoryData;
	if (!data.logGraph && !data.oldLogGraph)
		return 0;

	NSInteger maxColumn = MAX(data.logGraph.maxColumn, data.oldLogGraph.maxColumn);
	return bounds.size.width/ (maxColumn + 2);
}

- (CGFloat) xCoordOfColumn:(NSInteger)column withinFrame:(NSRect)bounds
{
	CGFloat spacing = [self columnSpacingWithinFrame:bounds];
	return floor(NSMinX(bounds) + spacing * column + spacing);
}

- (CGFloat) rowSpacingWithinFrame:(NSRect)bounds
{
	return bounds.size.height;
}

- (CGFloat) yCoordOfRevision:(NSInteger)rev withinFrame:(NSRect)bounds
{
	CGFloat rowHeight = bounds.size.height;
	int thisRow   = [logTableView tableRowForRevision:entry_.revision];
	int targetRow = [logTableView tableRowForRevision:intAsNumber(rev)];
	return floor(NSMidY(bounds) + (self.controlView.isFlipped ? 1 : -1) * (targetRow - thisRow) * rowHeight);
}


void addRoundedLine(NSBezierPath* path, NSPoint a, NSPoint d)
{
	static float r = 15.0;
	
	if (a.x == d.x)
	{
		[path moveToPoint:a];
		[path lineToPoint:d];
		return;
	}
	
	BOOL xsense = a.x < d.x;
	BOOL ysense = a.y < d.y;
	
	// If the ysense is around the wrong way we can simply flip the order of the points.
	if (!ysense)
	{
		addRoundedLine(path, d, a);
		return;
	}
	
	if (xsense)
	{
		float theR = MIN(MIN(ABS(d.x-a.x), ABS(d.y-a.y)),r);
		NSPoint b = NSMakePoint(d.x - theR, a.y);
		NSPoint c = NSMakePoint(d.x, a.y + theR);
		NSPoint arcCenter = NSMakePoint(b.x, c.y);
		
		[path moveToPoint:a];
		[path lineToPoint:b];
		[path appendBezierPathWithArcWithCenter:arcCenter radius:theR startAngle:-90.0 endAngle:0 clockwise:NO];
		[path lineToPoint:d];
	}
	else if (!xsense)
	{
		float theR = MIN(MIN(ABS(d.x-a.x), ABS(d.y-a.y)),r);
		NSPoint b = NSMakePoint(a.x, d.y - theR);
		NSPoint c = NSMakePoint(a.x - theR, d.y);
		NSPoint arcCenter = NSMakePoint(c.x, b.y);
		
		[path moveToPoint:a];
		[path lineToPoint:b];
		[path appendBezierPathWithArcWithCenter:arcCenter radius:theR startAngle:0.0 endAngle:90 clockwise:NO];
		[path lineToPoint:d];
	}
}


void addNewRoundedLine(NSBezierPath* path, NSPoint a, NSPoint m, NSPoint g)
{
	static float maxR = 15.0;
	
	if (a.x == m.x && m.x == g.x)
	{
		[path moveToPoint:a];
		[path lineToPoint:g];
		return;
	}
	
	BOOL ysense = a.y < g.y;
	
	// If the ysense is around the wrong way we can simply flip the order of the points.
	if (!ysense)
	{
		addNewRoundedLine(path, g, m, a);
		return;
	}

	float r1 = MIN(MIN(ABS(a.x-m.x), ABS(a.y-m.y)), maxR);
	float r2 = MIN(MIN(ABS(g.x-m.x), ABS(g.y-m.y)), maxR);

	[path moveToPoint:a];
	if (r1 > 0)
	{
		NSPoint b = NSMakePoint(m.x + (a.x<m.x?-1:1)*r1, a.y);
		NSPoint c = NSMakePoint(m.x    ,   a.y+r1);
		NSPoint arcCenter1 = NSMakePoint(b.x, c.y);
		[path lineToPoint:b];
		BOOL arcsense = b.x < c.x;
		if (arcsense)
			[path appendBezierPathWithArcWithCenter:arcCenter1 radius:r1 startAngle:-90.0 endAngle:0 clockwise:NO];
		else
			[path appendBezierPathWithArcWithCenter:arcCenter1 radius:r1 startAngle:-90 endAngle:180 clockwise:YES];
	}
	if (r2 > 0)
	{
		NSPoint d = NSMakePoint(m.x  , g.y-r2);
		NSPoint e = NSMakePoint(m.x + (g.x<m.x?-1:1)*r2, g.y);
		NSPoint arcCenter2 = NSMakePoint(e.x, d.y);
		[path lineToPoint:d];
		BOOL arcsense = e.x < d.x;
		if (arcsense)
			[path appendBezierPathWithArcWithCenter:arcCenter2 radius:r2 startAngle:0 endAngle:90.0 clockwise:NO];
		else
			[path appendBezierPathWithArcWithCenter:arcCenter2 radius:r2 startAngle:180.0 endAngle:90.0 clockwise:YES];
	}
	[path lineToPoint:g];
	return;

}


- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	
	LogGraph* theLogGraph    = logTableView.repositoryData.logGraph;
	LogGraph* theOldLogGraph = logTableView.repositoryData.oldLogGraph;
	if (!theLogGraph)
		return;
		
	if (logTableView.tableIsFiltered)
		return;

	//DebugLog(@"drawingLines for %@", entry.revision);
	NSRect cellBounds = NSInsetRect(cellFrame, -1, -1);  	// This should be a method somewhere so we can always be sure the cell frame is just a single pixel.

	[NSGraphicsContext saveGraphicsState];
	NSRectClip(cellBounds);
	[NSColor.greenColor set];
	
	NSNumber* revision    = entry_.revision;
	NSInteger revisionInt = numberAsInt(revision);
	NSInteger theColumnOfRev = NSNotFound;
	NSArray* lines = theLogGraph.revisionNumberToLineSegments[revision];
	if (!lines)
		lines = theOldLogGraph.revisionNumberToLineSegments[revision];
	BOOL hasIncompleteRevision = logTableView.repositoryData.includeIncompleteRevision;
	NSInteger incompleteRevisionInt = [logTableView.repositoryData.incompleteRevisionEntry revisionInt];

	for (LineSegment* line in lines)
	{
		NSBezierPath* thePath = NSBezierPath.bezierPath;
		int startColInt = line.highCol;
		int stopColInt  = line.lowCol;
		int drawColInt = line.drawCol;
		CGFloat startx = round([self xCoordOfColumn:startColInt withinFrame:cellBounds]);
		CGFloat stopx  = round([self xCoordOfColumn:stopColInt  withinFrame:cellBounds]);
		CGFloat drawx  = round([self xCoordOfColumn:drawColInt  withinFrame:cellBounds]);
		CGFloat starty = round([self yCoordOfRevision:line.highRev withinFrame:cellBounds]);
		CGFloat stopy  = round([self yCoordOfRevision:line.lowRev  withinFrame:cellBounds]);
		CGFloat drawy  = round((starty+stopy)/2);
	
		NSPoint a = NSMakePoint(startx, starty);
		NSPoint b = NSMakePoint(drawx,  drawy);
		NSPoint c = NSMakePoint(stopx,  stopy);
		addNewRoundedLine(thePath, a, b, c);

		// addRoundedLine(thePath, b, a);
		// addRoundedLine(thePath, c, b);
		
		CGFloat hue = (drawColInt * 4799.09 + 1223.1)/ (22.9);
		hue = hue - floor(hue);
		[[NSColor colorWithDeviceHue:hue saturation:1.0 brightness:0.6 alpha:1.0] set];
		
		if (hasIncompleteRevision && incompleteRevisionInt == line.highRev)
		{
			CGFloat lineDash[2];
			lineDash[0] = 4.0;
			lineDash[1] = 4.0;
			[thePath setLineDash:lineDash count:2 phase:0.0];
			[[NSColor colorWithDeviceHue:hue saturation:0.5 brightness:0.5 alpha:0.5] set];
		}

		thePath.lineWidth = 1.5;
		[thePath stroke];
		
		if (line.highRev == revisionInt)
			theColumnOfRev = startColInt;
		else if (line.lowRev == revisionInt)
			theColumnOfRev = stopColInt;
	}
	[NSGraphicsContext restoreGraphicsState];


	// Draw dot in center of graph line
	if (theColumnOfRev != NSNotFound)
		[self drawGraphDot:NSMakePoint([self xCoordOfColumn:theColumnOfRev withinFrame:cellBounds], NSMidY(cellBounds))];
}


- (void) drawGraphDot:(NSPoint) dotCenter
{
	//
	// Calculate the fillColor and strokeColor
	//
	static NSColor* defaultRed;
	if (!defaultRed)
		defaultRed = [NSColor colorWithCalibratedRed:0.4 green:0.0 blue:0.0 alpha:1.0];
	NSColor* fillColor   = defaultRed;
	NSColor* strokeColor = nil;
	BOOL entryIsClosed   = NO;
	BOOL hasLabels = IsNotEmpty(entry_.labels);
	
	if (logTableView.repositoryData.incompleteRevisionEntry == entry_)
	{
		fillColor   = NSColor.whiteColor;
		strokeColor = NSColor.grayColor;
	}
	else if ([logTableView.repositoryData revisionIsParent:entry_.revision])
	{
		fillColor   = [LogEntryTableParentHighlightColor() intensifySaturationAndBrightness:4.0];
		strokeColor = defaultRed;
	}
	else if (hasLabels && IsNotEmpty(entry_.branchHead))
	{
		fillColor   = [LogEntryTableBranchHighlightColor() intensifySaturationAndBrightness:4.0];
		strokeColor = defaultRed;
	}
	else if (hasLabels && IsNotEmpty(entry_.bookmarks))
	{
		fillColor = [LogEntryTableBookmarkHighlightColor() intensifySaturationAndBrightness:4.0];
		strokeColor = defaultRed;
	}
	else if (hasLabels && IsNotEmpty(entry_.tags))
	{
		fillColor = [LogEntryTableTagHighlightColor() intensifySaturationAndBrightness:4.0];
		strokeColor = defaultRed;
	}

	if (hasLabels && entry_.isClosedBranchHead)
	{
		entryIsClosed = YES;
		fillColor   = NSColor.grayColor;
		strokeColor = NSColor.blackColor;
	}
	
	

	NSBezierPath* path = nil;

	// If the entry is closed we draw a bar, or else in the normal case we draw the dot.
	if (entryIsClosed)
	{
		int halfWidth  = 5.0;
		int halfHeight = 1.0;
		NSRect dotRect;
		dotRect.origin.x = dotCenter.x - halfWidth;
		dotRect.origin.y = dotCenter.y - halfHeight;
		dotRect.size.width  = 2 * halfWidth;
		dotRect.size.height = 2 * halfHeight;
		path = [NSBezierPath bezierPathWithRect:dotRect];
	}
	else
	{
		int radius = 3.0;
		NSRect dotRect;
		dotRect.origin.x = dotCenter.x - radius;
		dotRect.origin.y = dotCenter.y - radius;
		dotRect.size.width  = 2 * radius;
		dotRect.size.height = 2 * radius;
		path = [NSBezierPath bezierPathWithOvalInRect:dotRect];
	}

	//
	// We are drawing a dot
	//
	
	if (fillColor)
	{
		[fillColor set];
		[path fill];
	}
	if (strokeColor)
	{
		[strokeColor set];
		[path stroke];
	}
}

- (NSSize) cellSize
{
    // NSSize cellSize = super.cellSize;
	// DebugLog(@"naturalSize is %f,%f", cellSize.width, cellSize.height);
	//    cellSize.width += (image ? image.size.width : 0) + 3;
    return NSMakeSize(84,19);
}


@end

