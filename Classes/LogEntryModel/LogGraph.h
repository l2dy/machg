//
//  LogGraph.h
//  MacHg
//
//  Created by Jason Harris on 24/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface LineSegment : NSObject

@property NSInteger	lowRev;
@property NSInteger	lowCol;		// This is the column where the line begins.
@property NSInteger	highRev;	// This is the revision where the line terminates.
@property NSInteger	highCol;	// This is the column where the line terminates.
@property NSInteger	drawCol;	// This is the column where the bulk of the line is drawn. It's usually the same as the highCol but not always.

+ (LineSegment*) withLowRev:(NSInteger)l  highRev:(NSInteger)h;
+ (LineSegment*) withLowRev:(NSInteger)l  highRev:(NSInteger)h  lowColumn:(NSInteger)lCol  highColumn:(NSInteger)hCol  drawColumn:(NSInteger)dCol;

- (BOOL) highColKnown;
- (BOOL) lowColKnown;
- (BOOL) drawColKnown;

@end


@interface LogGraph : NSObject
{	
	NSMutableDictionary*	revisionNumberToLineSegments_;	// Map of (NSNumber*)revision -> (NSMutableArray*)LineSegment LineSegments
															// passing or intersecting this rev.
	// Computed
	NSInteger				maxColumn;						// The max column used to draw the connections. 0 based, so if one
															// column used this will be 0, if two columns used this will be 1,
															// etc.
}

@property (readonly) NSInteger maxColumn;
@property (readonly) NSMutableDictionary* revisionNumberToLineSegments;


- (LogGraph*)	init;
- (void) addEntries:(NSArray*)entries;
- (void) removeEntries:(NSArray*)entries;

@end


