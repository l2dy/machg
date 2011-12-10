//
//  FSViewerOutline.m
//  MacHg
//
//  Created by Jason Harris on 12/11/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import "FSViewerOutline.h"


@implementation FSViewerOutline

@synthesize parentViewer = parentViewer_;

- (void) awakeFromNib
{
	[self setDelegate:self];
}


// Testing of selection and clicks
- (BOOL)		nodesAreSelected				{ return NO; }
- (BOOL)		nodeIsClicked					{ return NO; }
- (BOOL)		nodesAreChosen					{ return NO; }
- (FSNodeInfo*) clickedNode						{ return nil; }
- (BOOL)		clickedNodeInSelectedNodes		{ return NO; }
- (FSNodeInfo*) chosenNode						{ return nil; }
- (NSArray*)	selectedNodes;					{ return [NSArray array]; }
- (NSArray*)	chosenNodes						{ return [NSArray array]; }


// Path and Selection Operations
- (BOOL)		singleFileIsChosenInBrowser											{ return NO; }
- (BOOL)		singleItemIsChosenInBrowser											{ return NO; }
- (HGStatus)	statusOfChosenPathsInBrowser										{ return eHGStatusClean; }
- (NSArray*)	absolutePathsOfSelectedFilesInBrowser								{ return [NSArray array]; }
- (NSArray*)	absolutePathsOfChosenFilesInBrowser									{ return [NSArray array]; }
- (NSString*)	enclosingDirectoryOfChosenFilesInBrowser							{ return @""; }
- (NSArray*)	filterPaths:(NSArray*)absolutePaths byBitfield:(HGStatus)status		{ return [NSArray array]; }


// Graphic Operations
- (NSRect)		frameinWindowOfRow:(NSInteger)row inColumn:(NSInteger)column		{ return NSMakeRect(0, 0, 20, 20); }

- (BOOL)		clickedNodeCoincidesWithTerminalSelections							{ return NO; }

- (void)		reloadDataSin														{ [self reloadData]; }
- (void)		repositoryDataIsNew													{ }
- (NSArray*)	quickLookPreviewItems												{ return [NSArray array]; }

// Save and restore browser, outline, or table state
- (FSViewerSelectionState*)	saveViewerSelectionState								{ return [[FSViewerSelectionState alloc]init]; }
- (void)					restoreViewerSelectionState:(FSViewerSelectionState*)savedState {}



@end
