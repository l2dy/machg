//
//  LogGraph.m
//  MacHg
//
//  Created by Jason Harris on 24/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LogGraph.h"
#import "MacHgDocument.h"
#import "LogEntry.h"


const NSInteger revNotInitilized = -2;
const NSInteger maxRevDistance = 72;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: LineSegment
// ------------------------------------------------------------------------------------

@implementation LineSegment

@synthesize lowRev = lowRev;
@synthesize lowCol = lowCol;
@synthesize highRev = highRev;
@synthesize highCol = highCol;
@synthesize drawCol = drawCol;

+ (LineSegment*) withLowRev:(NSInteger)l  highRev:(NSInteger)h
{
	LineSegment* segment = [[LineSegment alloc] init];
	[segment setLowRev:l];
	[segment setHighRev:h];
	[segment setLowCol:NSNotFound];
	[segment setHighCol:NSNotFound];
	[segment setDrawCol:NSNotFound];
	return segment;
}

+ (LineSegment*) withLowRev:(NSInteger)l  highRev:(NSInteger)h  lowColumn:(NSInteger)lCol  highColumn:(NSInteger)hCol  drawColumn:(NSInteger)dCol
{
	LineSegment* segment = [[LineSegment alloc] init];
	[segment setLowRev:l];
	[segment setHighRev:h];
	[segment setLowCol:lCol];
	[segment setHighCol:hCol];
	[segment setDrawCol:dCol];
	return segment;
}

- (BOOL) highColKnown	{ return highCol != NSNotFound; }
- (BOOL) lowColKnown	{ return lowCol  != NSNotFound; }
- (BOOL) drawColKnown	{ return drawCol != NSNotFound; }


- (NSString*) description { return fstr(@"Line from (%ld,%ld) to (%ld,%ld) drawn in col %ld", lowRev, lowCol, highRev, highCol, drawCol); }

@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: LogGraph
// ------------------------------------------------------------------------------------

@interface LogGraph (PrivateAPI)
- (BOOL)	  fillOutLine:(LineSegment*)line suggestedColumnPlacement:(NSInteger)suggestedCol;
- (void)      addLineSegment:(LineSegment*)line;
- (NSMutableIndexSet*) findDrawColumnForLow:(NSInteger)l andHigh:(NSInteger)h;
@end


@implementation LogGraph

@synthesize maxColumn;
@synthesize revisionNumberToLineSegments = revisionNumberToLineSegments_;


- (LogGraph*) init
{
	self = [super init];
	if (self)
	{
		revisionNumberToLineSegments_ = [[NSMutableDictionary alloc] init];
		maxColumn = 0;
	}
	return self;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Index Utilities
// ------------------------------------------------------------------------------------

static NSInteger firstFreeIndex(NSIndexSet* indexes)
{
	NSInteger i = 0;
	while ([indexes containsIndex:i])
		i++;
	return i;
}

static NSInteger closestFreeIndex(NSIndexSet* indexes, NSInteger desiredIndex)
{
	NSInteger i = 0;
	while ([indexes containsIndex:ABS(desiredIndex - i)] && [indexes containsIndex:desiredIndex + i])
		i++;
	if (![indexes containsIndex:ABS(desiredIndex - i)])
		return ABS(desiredIndex - i);
	return desiredIndex + i;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  LineSegement Utilities
// ------------------------------------------------------------------------------------

- (LineSegment*) findSegmentFromLow:(NSInteger)l toHigh:(NSInteger)h
{
	NSArray* lines = revisionNumberToLineSegments_[intAsNumber(l)];
	for (LineSegment* line in lines)
		if ([line lowRev] == l && [line highRev] == h)
			return line;
	return nil;
}

- (NSInteger) columnForRevisionInt:(NSInteger)revisionInt
{
	NSArray* lines = revisionNumberToLineSegments_[intAsNumber(revisionInt)];
	if (!lines)
		return NSNotFound;
	for (LineSegment* line in lines)
	{
		if ([line lowRev] == revisionInt)
			return [line lowCol];
		if ([line highRev] == revisionInt)
			return [line highCol];
	}
	return NSNotFound;
}

- (BOOL) revisionHasKnownColumn:(NSInteger)revisionInt { return [self columnForRevisionInt:revisionInt] != NSNotFound; }




// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Add and Remove Entries
// ------------------------------------------------------------------------------------

- (void) addEntries:(NSArray*)entries
{

	//
	// Make sure we are working with entries high to low
	//
	NSSortDescriptor* byRev = [NSSortDescriptor sortDescriptorWithKey:@"revision" ascending:NO  selector:@selector(compare:)];
	NSArray* descriptors    = @[byRev];
	NSArray* sortedEntries  = [entries sortedArrayUsingDescriptors:descriptors];
	
	
	//
	// Initially compute the newLineSegments
	//
	NSMutableArray* newLineSegments = [[NSMutableArray alloc]init];
	for (LogEntry* entry in sortedEntries)
	{
		NSInteger h = [entry revisionInt];
		for (NSNumber* parent in [entry parentsArray])
		{
			LineSegment* line = [LineSegment withLowRev:numberAsInt(parent) highRev:h];
			[newLineSegments addObject:line];
		}
	}
	
	@synchronized(revisionNumberToLineSegments_)
	{
		while (IsNotEmpty(newLineSegments))
		{
			//
			// Loop over all the lines finding all possible descending chains
			//
			NSMutableArray* firstChain = [NSMutableArray arrayWithObject:[newLineSegments firstObject]];
			NSMutableArray* chains = [NSMutableArray arrayWithObject:firstChain];
			for (LineSegment* line in newLineSegments)
			{
				if (![line highColKnown])
					[line setHighCol:[self columnForRevisionInt:[line highRev]]];	// Likely its just setting the highCol to NSNotFound if it wasn't
																					// found before
				for (NSMutableArray* chain in chains)
					if ([[chain lastObject] lowRev] == [line highRev])
						[chain addObject:line];
				if ([line highColKnown])
					[chains addObject:[NSMutableArray arrayWithObject:line]];
			}
			
			//
			// Find the best chain amongst all possible chains
			//
			NSMutableArray* bestChain = firstChain;
			BOOL bestChainStartKnown = [[bestChain firstObject] highColKnown];
			for (NSMutableArray* chain in chains)
			{
				BOOL chainStartKnown = [[chain firstObject] highColKnown];
				if ( chainStartKnown && (!bestChainStartKnown || [chain count] <= [bestChain count]) )
				{
					bestChain = chain;
					bestChainStartKnown = chainStartKnown;
				}
			}
			
			
			//
			// Find the draw column for the chain
			//
			NSMutableIndexSet* usedDrawColumns = [self findDrawColumnForLow:[[bestChain lastObject] lowRev] andHigh:[[bestChain firstObject] highRev]];
			NSInteger drawColumnForChain;
			if ([[bestChain firstObject] highColKnown])
				drawColumnForChain = closestFreeIndex(usedDrawColumns, [[bestChain firstObject] highCol]);
			else if ([[bestChain lastObject] lowColKnown])
				drawColumnForChain = closestFreeIndex(usedDrawColumns, [[bestChain lastObject] lowCol]);
			else
				drawColumnForChain = firstFreeIndex(usedDrawColumns);

			
			//
			// add the lines in the chain
			//
			for (LineSegment* line in bestChain)
			{
				BOOL filledOut = [self fillOutLine:line suggestedColumnPlacement:drawColumnForChain];
				if (filledOut)
					[self addLineSegment:line];
				[newLineSegments removeObject:line];
			}
		}
	}

}


- (void) removeEntries:(NSArray*)entries
{
	@synchronized(revisionNumberToLineSegments_)
	{
		for (LogEntry* entry in entries)
			[revisionNumberToLineSegments_ removeObjectForKey:[entry revision]];
		if (IsEmpty(revisionNumberToLineSegments_))
			maxColumn = 0;
	}	
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Add and Remove Lines
// ------------------------------------------------------------------------------------

- (void) addLineSegment:(LineSegment*)line
{
	if ([line lowRev] < 0)
		[line setLowRev:0]; 
	// DebugLog(@"adding :%@", line);
	NSInteger maxCol = maxColumn;
	maxCol = MAX(maxCol, [line highCol]);
	maxCol = MAX(maxCol, [line lowCol]);
	maxCol = MAX(maxCol, [line drawCol]);
	maxColumn = maxCol;
	
	for (NSInteger r = [line lowRev]; r <= [line highRev]; r++)
	{
		NSNumber* revision = intAsNumber(r);
		NSMutableArray* lines = [revisionNumberToLineSegments_ objectForKey:revision addingIfNil:[NSMutableArray class]];
		[lines addObject:line];
	}		
}


- (NSMutableIndexSet*) findDrawColumnForLow:(NSInteger)l  andHigh:(NSInteger)h
{

	//
	// Find every unique line which intersects our range l to h. usuallly there are degeneracies so by collecting just the
	// unqiue lines its quicker to iterate over them.
	//
	NSMutableSet* setOfLines = [[NSMutableSet alloc]init];
	for (NSInteger rev = l; rev <= h; rev++)
	{
		NSArray* lines = revisionNumberToLineSegments_[intAsNumber(rev)];
		if (lines)
			[setOfLines addObjectsFromArray:lines];
	}
	
	//
	// Find the draw columns which are used and the terminating columns
	//
	NSMutableIndexSet* drawColUsed = [[NSMutableIndexSet alloc]init];		// These are the indexes where we cannot place the bulk of the line
	for (LineSegment* line in setOfLines)
	{
		NSInteger hs    = [line highRev];
		NSInteger ls    = [line lowRev];

		if (hs <= l || h <= ls)
			continue;

		[drawColUsed addIndex:[line drawCol]];
		if (l < hs && hs < h)
			[drawColUsed addIndex:[line highCol]];
		if (l < ls && ls < h)
			[drawColUsed addIndex:[line lowCol]];
	}
	return drawColUsed;
}



// In the computation of the columns used we need to take the following cases into account where l is the low revision, h is the
// high revision, ls is the low revision of the line segment, and hs is the high revision of the line segement.
//
//		   l..........h
//   ---------------------
//	  ls...hs
//	  ls........hs
//		   ls...hs
//		      ls...hs
//			   ls.....hs
//		   ls.........hs
//	  ls..............hs
//	                  ls....hs
//			   ls...........hs
//		   ls...............hs
//	  ls....................hs

// Given the low l and high h, fill out drawColUsed and allDrawColUsed indexed sets as filling out the line segment if we can.
//
// drawColUsed    	 These are the indexes where we cannot place the bulk of the line
// allDrawColUsed 	 These are the indexes where we would perfer or cannot place the bulk of the line
- (BOOL) findAcceptableRangesForLine:(LineSegment*)theLine  andDrawCol:(NSMutableIndexSet*)drawColUsed  andAllDrawCol:(NSMutableIndexSet*)allDrawColUsed
{
	//
	// Find every unique line which intersects our range l to h. usuallly there are degeneracies so by collecting just the
	// unqiue lines its quicker to iterate over them.
	//
	NSInteger h = [theLine highRev];
	NSInteger l = [theLine lowRev];
	NSMutableSet* setOfLines = [[NSMutableSet alloc]init];
	for (NSInteger rev = l; rev <= h; rev++)
	{
		NSArray* lines = revisionNumberToLineSegments_[intAsNumber(rev)];
		if (lines)
			[setOfLines addObjectsFromArray:lines];
	}
	
	//
	// Find the draw columns which are used and the terminating columns
	//
	for (LineSegment* line in setOfLines)
	{
		NSInteger hs    = [line highRev];
		NSInteger ls    = [line lowRev];
		
		// If the line ls..hs has a common endpoint with l..h then we can fix one of l or h

		if		(l == ls)	[theLine setLowCol:[line lowCol]];
		else if (l == hs)	[theLine setLowCol:[line highCol]];
		
		if		(h == ls)	[theLine setHighCol:[line lowCol]];
		else if (h == hs)	[theLine setHighCol:[line highCol]];

		if (h == hs && l == ls)
		{
			// Shouldn't happen should almost be an assert
			//				DebugLog(@"found existing line %ld..%ld", ls, hs);
			return NO;
		}
		

		if (l < hs && hs < h)
			[drawColUsed addIndex:[line highCol]];
		if (l < ls && ls < h)
			[drawColUsed addIndex:[line lowCol]];
		if (ls < l && h < hs)
			[drawColUsed addIndex:[line drawCol]];

		
		if ((ls < l && l < hs) || (ls < h && h < hs))
		{
			BOOL allowed = NO;
			if (l == ls && [theLine lowCol]  == [line drawCol])
				allowed = YES;
			if (h == hs && [theLine highCol] == [line drawCol])
				allowed = YES;
			if (!allowed)
				[drawColUsed addIndex:[line drawCol]];
			[allDrawColUsed addIndex:[line drawCol]];
		}
	}
	[allDrawColUsed addIndexes:drawColUsed];	// Make sure anything in drawColUsed is in allDrawColUsed
	return YES;
}


- (BOOL) fillOutLine:(LineSegment*)line suggestedColumnPlacement:(NSInteger)suggestedCol
{
	NSMutableIndexSet* drawColUsed    = [[NSMutableIndexSet alloc]init];		// These are the indexes where we cannot place the bulk of the line
	NSMutableIndexSet* allDrawColUsed = [[NSMutableIndexSet alloc]init];		// These are the indexes where we would perfer or cannot place the bulk of the line
	@synchronized(revisionNumberToLineSegments_)
	{
		[self findAcceptableRangesForLine:line  andDrawCol:drawColUsed  andAllDrawCol:allDrawColUsed];

		// If we haven't located the column for the high end or low end of the line segement then use the suggested col
		if (![line highColKnown])
			[line setHighCol:suggestedCol];
		if (![line lowColKnown])
			[line setLowCol:suggestedCol];

		NSInteger hCol = [line highCol];
		NSInteger lCol = [line lowCol];
		BOOL allDrawColFreeOfLCol = [allDrawColUsed freeOfIndex:lCol];
		BOOL allDrawColFreeOfHCol = [allDrawColUsed freeOfIndex:hCol];
		BOOL drawColFreeOfLCol    = [drawColUsed    freeOfIndex:lCol];
		BOOL drawColFreeOfHCol    = [drawColUsed    freeOfIndex:hCol];
		
		//
		// Place the line segement according to where we can
		//
		
		// Place the bulk of the line in the column which looks best. We like to have the curve of any line be like the top
		// right quarter of the circle rather than the bottom left quarter of the circle.
		NSInteger drawCol;
		if		( allDrawColFreeOfLCol && !allDrawColFreeOfHCol)	drawCol = lCol;
		else if	(!allDrawColFreeOfLCol &&  allDrawColFreeOfHCol)	drawCol = hCol;
		else if	(lCol < hCol && drawColFreeOfHCol)					drawCol = hCol;
		else if (lCol > hCol && drawColFreeOfLCol)					drawCol = lCol;
		else if (drawColFreeOfHCol)									drawCol = hCol;
		else if (drawColFreeOfLCol)									drawCol = lCol;
		else														drawCol = closestFreeIndex(drawColUsed, hCol);

		[line setDrawCol:drawCol];
		return YES;
	}
	return YES;
}



@end


