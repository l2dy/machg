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
{
	NSInteger lowRev;
	NSInteger lowCol;		// This is the column where the line begins.
	NSInteger highRev;		// This is the revision where the line terminates.
	NSInteger highCol;		// This is the column where the line terminates.
	NSInteger drawCol;		// This is the column where the bulk of the line is drawn. It's usually the same as the highCol but not always.
}

@property (readwrite,assign) NSInteger		lowRev;
@property (readwrite,assign) NSInteger		lowCol;
@property (readwrite,assign) NSInteger		highRev;
@property (readwrite,assign) NSInteger		highCol;
@property (readwrite,assign) NSInteger		drawCol;

+ (LineSegment*) withLowRev:(NSInteger)l  highRev:(NSInteger)h;
+ (LineSegment*) withLowRev:(NSInteger)l  highRev:(NSInteger)h  lowColumn:(NSInteger)lCol  highColumn:(NSInteger)hCol  drawColumn:(NSInteger)dCol;

- (BOOL) highColKnown;
- (BOOL) lowColKnown;
- (BOOL) drawColKnown;

@end


@interface LogGraph : NSObject
{
	// Initilized
	RepositoryData*			repositoryData;

	
	NSMutableDictionary*	revisionNumberToLineSegments_;	// Map of (NSNumber*)revision -> (NSMutableArray*)LineSegment LineSegments
															// passing or intersecting this rev.

	// Computed
	NSInteger				maxColumn;						// The max column used to draw the connections. 0 based, so if one
															// column used this will be 0, if two columns used this will be 1,
															// etc.
}

@property (readonly) NSInteger maxColumn;
@property (readonly,assign) NSMutableDictionary* revisionNumberToLineSegments;


- (LogGraph*)	initWithRepositoryData:(RepositoryData*)collection;

- (void) addEntries:(NSArray*)entries;
- (void) removeEntries:(NSArray*)entries;

@end


