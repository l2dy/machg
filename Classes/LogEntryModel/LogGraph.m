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
#import "RepositoryData.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LineSegment
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation LineSegment

@synthesize lowRev;
@synthesize lowCol;
@synthesize highRev;
@synthesize highCol;
@synthesize drawCol;

- (LineSegment*) initWithLowRev:(NSNumber*)lowR  lowColumn:(NSNumber*)lowC	highRev:(NSNumber*)highR  highColumn:(NSNumber*)highC  drawColumn:(NSNumber*)drawC
{
	lowRev  = lowR;
	highRev = highR;
	lowCol  = lowC;
	highCol = highC;
	drawCol = drawC;
	return self;
}

- (NSString*) description { return fstr(@"Line from (%@,%@) to (%@,%@)",lowRev,lowCol,highRev,highCol); }

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LogGraph
// -----------------------------------------------------------------------------------------------------------------------------------------

inline static NSString* revPair(NSNumber* low, NSNumber* high) { return fstr(@"%@:%@",low,high); }

@implementation LogGraph

@synthesize maxColumn;
@synthesize lineSegments;


- (void) resetCaches
{
	lowRevision  = -1;
	highRevision = -1;
	columnOfRevision =		[[NSMutableDictionary alloc] init];
	drawColumnOfRevision =	[[NSMutableDictionary alloc] init];
	lineSegments =			[[NSMutableDictionary alloc] init];
}

- (LogGraph*) initWithRepositoryData:(RepositoryData*)collection andOldCollection:(RepositoryData*)oldCollection;
{
	[self resetCaches];
	repositoryData = collection;
	oldRepositoryData = oldCollection;
	MacHgDocument* myDocument = [repositoryData myDocument];
	[self observe:kLogEntriesDidChange	from:myDocument  byCalling:@selector(logEntriesDidChange)];
	return self;
}

- (void) logEntriesDidChange				{ [self resetCaches]; }


- (NSArray*) replaceNodeByParentsOfNodeInColumns:(NSNumber*)node andConnections:(NSArray*)connections
{
	// Fall back to the old log entry collection if the new log collection does not yet have parents filled out.
	NSArray* theParents = [repositoryData parentsOfRev:node];
	if (!theParents && ![repositoryData entryIsLoadedForRevisionNumber:node])
		theParents = [oldRepositoryData parentsOfRev:node];

	NSMutableArray* newParents = [NSMutableArray arrayWithArray:theParents];
	NSMutableArray* newConnections = [NSMutableArray arrayWithArray:connections];
	int len = [newConnections count];


	// First off if we are merging two columns into their destination node we replace the node which is not the column for the node
	// with a slot. slot, ie if we have something like [connectionsForNode: 8 , {3 , 6, 8, 2, 8, 1} ] and we know the column for 8
	// is the 3rd column, then our new configuration would become {3, 6, 8, 2, Slot, 1} since the 8 in the second to last column
	// would be merged with the one in the third column. Then we put in the parent for 8 in the third column and other parents in
	// other columns,

	int i;
	BOOL found = NO;
	NSInteger foundColumn = NSNotFound;
	for (i = 0; i < len; i++)
	{
		NSNumber* connectioni = [newConnections objectAtIndex:i];
		if ([connectioni isEqualToNumber:node])
		{
			if (!found)
			{
				found = YES;
				foundColumn = i;
				[columnOfRevision setValue:intAsNumber(i) forNumberKey:node];
			}
			else
			{
				[newConnections replaceObjectAtIndex:i withObject:SlotNumber];
			}
		}
	}

	// If we can't find the node in the connections we have a new head. Add it to the connections and try again.
	if (!found)
	{
		// If we find an empty slot stick the new head there or if not stick it at the end of the connections.
		NSInteger index = [newConnections indexOfObject:SlotNumber];
		if (index != NSNotFound)
		{
			maxColumn = MAX(maxColumn,index);
			[newConnections replaceObjectAtIndex:index withObject:node];
		}
		else
		{
			maxColumn = MAX(maxColumn,len);
			[newConnections addObject:node];
		}
		return [self replaceNodeByParentsOfNodeInColumns:node andConnections:newConnections];
	}


	// replace this node with its first parent
	if (IsEmpty(newParents))
		[newConnections replaceObjectAtIndex:foundColumn withObject:SlotNumber];
	else
	{
		NSNumber* firstParent = [newParents objectAtIndex:0];
		[newConnections replaceObjectAtIndex:foundColumn withObject:firstParent];
		[drawColumnOfRevision setValue:intAsNumber(foundColumn) forKey:revPair(firstParent, node)];
		[newParents removeObjectAtIndex:0];
	}
	
	// eliminate any other parents that are already connected setting their drawColumns
	NSArray* newParentsCopy = [NSArray arrayWithArray:newParents];
	for (NSNumber* parent in newParentsCopy)
	{
		NSInteger index = [newConnections indexOfObject:parent];
		if (index != NSNotFound)
		{
			[drawColumnOfRevision setValue:intAsNumber(index) forKey:revPair(parent, node)];
			[newParents removeObject:parent];
		}
	}

	// Replace other slots with any parents that remain until we run out of parents
	for (i = 0; (i < len) && ([newParents count] > 0); i++)
	{
		NSNumber* connectioni = [newConnections objectAtIndex:i];
		if ([connectioni isEqualToNumber:SlotNumber])
		{
			NSNumber* nextParent = [newParents objectAtIndex:0];
			[newConnections replaceObjectAtIndex:i withObject:nextParent];
			[newParents removeObjectAtIndex:0];
			[drawColumnOfRevision setValue:intAsNumber(i) forKey:revPair(nextParent, node)];
			maxColumn = MAX(maxColumn,i);
		}
	}

	// any remaining parents go on the end of the connections
	if (IsNotEmpty(newParents))
	{
		i = len;
		for (NSNumber* p in newParents)
		{
			[newConnections addObject:p];
			[drawColumnOfRevision setValue:intAsNumber(i) forKey:revPair(p, node)];
			maxColumn = MAX(maxColumn,i);
			i++;
		}
			
	}
	
	// trim any slots off the end if they are there
	while ([[newConnections lastObject] isEqualToNumber:SlotNumber])
		[newConnections removeLastObject];

	// If we have any children outside our range we need to make a line to those children in a new final column.
	NSArray* childrenNodes = [repositoryData childrenOfRev:node];
	for (NSNumber* childNode in childrenNodes)
		if (numberAsInt(childNode) > highRevision)
			[drawColumnOfRevision setValue:intAsNumber(++maxColumn) forKey:revPair(node,childNode)];

	return newConnections;
}


- (NSArray*) computeColumnOfNodeAndColumnConnections:(NSNumber*)node andConnections:(NSArray*)connections
{
	return [self replaceNodeByParentsOfNodeInColumns:node andConnections:connections];
}


- (void) addLineSegment:(LineSegment*)line atNode:(NSNumber*)node
{
	NSMutableArray* lines = [lineSegments valueForNumberKey:node];
	if (!lines)
	{
		lines = [[NSMutableArray alloc] init];
		[lineSegments setValue:lines forNumberKey:node];
	}
	[lines addObject:line];
}


- (void) AddLineSegmentsToChildren:(NSNumber*)node
{
	const int nodeInt    = numberAsInt(node);
	NSNumber* theNodeCol = [columnOfRevision valueForNumberKey:node];

	
	// Fall back to the old log entry collection if the new log collection does not yet have parents or children filled out.
	NSArray* childrenNodes = [repositoryData childrenOfRev:node];
	if (!childrenNodes && ![repositoryData entryIsLoadedForRevisionNumber:node])
		childrenNodes = [oldRepositoryData childrenOfRev:node];
	NSArray* parentNodes = [repositoryData parentsOfRev:node];
	if (!parentNodes && ![repositoryData entryIsLoadedForRevisionNumber:node])
		parentNodes = [oldRepositoryData parentsOfRev:node];
	
	for (NSNumber* childNode in childrenNodes)
	{
		int childInt = numberAsInt(childNode);
		NSString* thePair = revPair(node,childNode);
		NSNumber* theDrawCol  = [drawColumnOfRevision objectForKey:thePair];
		NSNumber* theChildCol = [columnOfRevision valueForNumberKey:childNode];
		theChildCol = theChildCol ? theChildCol : theDrawCol;
		LineSegment* line = [[LineSegment alloc]  initWithLowRev:node  lowColumn:theNodeCol  highRev:childNode  highColumn:theChildCol  drawColumn:theDrawCol];

		for (int i = nodeInt; i <= childInt && i <= highRevision; i++)
			[self addLineSegment:line atNode:intAsNumber(i)];
	}

	// For the parents outside our range at least just include a line extending up into the past. (The lines from node <->
	// (parents within our range) are included by the adding of line segments to the parent.
	for (NSNumber* parentNode in parentNodes)
	{
		if (numberAsInt(parentNode) < lowRevision)
		{
			NSString* thePair = revPair(parentNode,node);
			NSNumber* theDrawCol  = [drawColumnOfRevision objectForKey:thePair];
			LineSegment* line = [[LineSegment alloc]  initWithLowRev:parentNode  lowColumn:theDrawCol  highRev:node  highColumn:theNodeCol  drawColumn:theDrawCol];
			for (int i = nodeInt; i >= lowRevision; i--)
				[self addLineSegment:line atNode:intAsNumber(i)];
		}
	}

}

- (BOOL) limitsDiffer:(LowHighPair)limits		{ return (lowRevision != limits.lowRevision || highRevision != limits.highRevision); }

- (void) computeColumnsOfRevisionsForLimits:(LowHighPair)limits
{
	NSArray* connections = [[NSArray alloc] init];
	columnOfRevision	 = [[NSMutableDictionary alloc] init];
	drawColumnOfRevision = [[NSMutableDictionary alloc] init];
	lineSegments		 = [[NSMutableDictionary alloc] init];
	lowRevision  = limits.lowRevision;
	highRevision = limits.highRevision;

	maxColumn = 0;

	for (int rev = highRevision; rev >= lowRevision; rev--)
	{
		connections = [self computeColumnOfNodeAndColumnConnections:intAsNumber(rev) andConnections:connections];
		//NSMutableString* str = [NSMutableString stringWithFormat:@"connections for %@ : ", intAsNumber(rev)];
		//for (NSNumber* c in connections)
		//	[str appendFormat:@"%@ ", c];
		//[str appendFormat:@"  maxc:%d ", maxColumn];
		//DebugLog(@"%@", str);
	}
	for (int rev = highRevision; rev >= lowRevision; rev--)
		[self AddLineSegmentsToChildren:intAsNumber(rev)];
	//DebugLog(@"maxColumn: %d", maxColumn);
}


- (int)	columnOfRevision:(NSNumber*)rev
{
	return numberAsInt([columnOfRevision valueForNumberKey:rev]);
}


// This is now somewhat outdated but it's where I played with the first versions of the algorithm to layout the various nodes and their connections.
/*

In[766]:= ReplaceToParents[node_, parents_, connections_] :=
 
 Block[{i, alreadyFound = False, newConnections = connections,
   newParents = parents, len = Length @ connections},
  
  (* Merge the nodes *)
  For[i = 1, i <= len, i++,
   If[newConnections[[i]] == node,
    If[alreadyFound == True,
     newConnections[[i]] = Slott,
     alreadyFound = True]]];
  
  (* replace first node with its parent *)
  
  For[i = 1, newParents != {} && i <= len, i++,
   If[newConnections[[i]] == node,
    newConnections[[i]] = First @ newParents; newParents = Rest@newParents;
    Break[]]];
  
  (* replace the next slott if available with the next parent *)
  
  For[i = 1, newParents != {} && i <= len, i++,
   If[newConnections[[i]] == Slott,
    newConnections[[i]] = First @ newParents; newParents = Rest@newParents]];
  
  TrimTrailing @ Join[newConnections, newParents]
  ]
  */
/*
In[767]:= connect[node_, connections : {l___, node_, r___}] :=
 (col@node = Length@{l};
  AppendTo[lineSegments, { {col@node, node}, {col@#, #} }] & /@ child@node;
  ReplaceToParents[node, par@node, connections])

In[768]:= connect[node_, connections : {l___, Slott, r___}] :=
 (col@node = Length@{l};
  AppendTo[lineSegments, { {col@node, node}, {col@#, #} }] & /@ child@node;
  ReplaceToParents[node, par@node, connections])

In[769]:= connect[node_, connections : {l___}] :=
 (col@node = Length@{l};
  AppendTo[lineSegments, { {col@node, node}, {col@#, #} }] & /@ child@node;
  ReplaceToParents[node, par@node, connections])
*/

/*
Loops

In[776]:= lineSegments = {};
In[777]:= ClearAll /@ {cols, col};
In[778]:= cols[55] = {};

In[752]:= cols[54] = connect[55, cols[55]]
Out[752]= {54, 48}

In[753]:= cols[54]
Out[753]= {54, 48}

In[754]:= connect[54, cols[54]]
Out[754]= {53, 48, 51}

In[779]:= For[i = 55, i >= 0, i--,
 cols[i - 1] = connect[i, cols[i]]
 ]
 
*/


@end


