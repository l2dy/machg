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
	NSNumber* lowRev;
	NSNumber* lowCol;		// This is the column where the line begins.
	NSNumber* highRev;		// This is the revision where the line terminates.
	NSNumber* highCol;		// This is the column where the line terminates.
	NSNumber* drawCol;		// This is the column where the bulk of the line is drawn. Its usually the same as the highCol but not always.
}

@property (readwrite,assign) NSNumber*			lowRev;
@property (readwrite,assign) NSNumber*			lowCol;
@property (readwrite,assign) NSNumber*			highRev;
@property (readwrite,assign) NSNumber*			highCol;
@property (readwrite,assign) NSNumber*			drawCol;

- (LineSegment*)	initWithLowRev:(NSNumber*)lowR  lowColumn:(NSNumber*)lowC	highRev:(NSNumber*)hightR  highColumn:(NSNumber*)highC  drawColumn:(NSNumber*)drawC;
@end


@interface LogGraph : NSObject
{
	// Cached
	RepositoryData*		repositoryData;
	RepositoryData*		oldRepositoryData;

	// Specified
	int						lowRevision;
	int						highRevision;					// low < high

	// Computed
	NSMutableDictionary*	lineSegments;					// Rev NSNumber -> MutableArray per column of LineSegments passing or intersecting this rev.
	NSMutableDictionary*	columnOfRevision;				// Rev NSNumber -> column for the revision (NSNumber)
	NSMutableDictionary*	drawColumnOfRevision;			// LowRev NSString: HighRev NSString -> draw column for the revision (NSNumber)
	int						maxColumn;						// The max column used to draw the connections. 0 based, so if one
															// column used this will be 0, if two columns used this will be 1,
															// etc.
}

@property (readonly) int maxColumn;
@property (readonly,assign) NSMutableDictionary* lineSegments;


- (LogGraph*)	initWithRepositoryData:(RepositoryData*)collection andOldCollection:(RepositoryData*)oldCollection;

- (BOOL)		limitsDiffer:(LowHighPair)limits;
- (void)		computeColumnsOfRevisionsForLimits:(LowHighPair)limits;	// compute columnOfRevision
- (int)			columnOfRevision:(NSNumber*)rev;

@end


