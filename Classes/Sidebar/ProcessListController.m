//
//  ProcessListController.m
//  MacHg
//
//  Created by Jason Harris on 12/28/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ProcessListController.h"
#import "MacHgDocument.h"

@implementation ProcessListController

- (void) awakeFromNib
{
	processDescriptions_    = [[NSMutableDictionary alloc]init];
	progressIndicators_     = [[NSMutableDictionary alloc]init];
	processProgressStrings_ = [[NSMutableDictionary alloc]init];
	processNumber_ = 0;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Add/ remove process indicators
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSNumber*) addProcessIndicator:(NSString*)processDescription
{
	NSProgressIndicator* indicator = [[NSProgressIndicator alloc]init];
	[indicator setStyle:NSProgressIndicatorSpinningStyle];
	[indicator setControlSize:NSMiniControlSize];
	[indicator startAnimation:nil];
	[indicator setHidden:NO];

	NSNumber* processNum;
	@synchronized(self)
	{
		processNum = [NSNumber numberWithInt:(processNumber_++)];
		if ([progressIndicators_ synchronizedCount] == 0)
			[[informationAndActivityBox animator] setContentView:activityBox];
		[processDescriptions_ synchronizedSetObject:processDescription forKey:processNum];
		[progressIndicators_ synchronizedSetObject:indicator forKey:processNum];
		dispatch_async(mainQueue(), ^{
			[processListTableView addSubview:indicator];
			[processListTableView reloadData];
		});
	}
	return processNum;
}

- (void) removeProcessIndicator:(NSNumber*)processNum
{
	@synchronized(self)
	{
		NSProgressIndicator* indicator = [progressIndicators_ synchronizedObjectForKey:processNum];
		[processDescriptions_ synchronizedRemoveObjectForKey:processNum];
		[progressIndicators_ synchronizedRemoveObjectForKey:processNum];
		dispatch_async(mainQueue(), ^{
			[indicator setHidden:YES];
			[indicator removeFromSuperview];
			[processListTableView reloadData];
			if ([progressIndicators_ synchronizedCount] == 0)
			{
				[[informationAndActivityBox animator] setContentView:informationBox];
				[informationBox setNeedsDisplay:YES];
			}
		});
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Process management
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSNumber*) keyForRow:(NSInteger)requestedRow
{
	NSArray* allKeys = [processDescriptions_ synchronizedAllKeys];
	NSArray* sortedKeys = [allKeys sortedArrayUsingComparator: ^(id obj1, id obj2) {
		if ([obj1 integerValue] > [obj2 integerValue])
			return (NSComparisonResult)NSOrderedDescending;
		if ([obj1 integerValue] < [obj2 integerValue])
			return (NSComparisonResult)NSOrderedAscending;
		return (NSComparisonResult)NSOrderedSame;
	}];
	return ([sortedKeys count] > requestedRow) ? [sortedKeys objectAtIndex:requestedRow] : nil;
}

- (NSProgressIndicator*) indicatorForRow:(NSInteger)requestedRow
{
	NSNumber* key = [self keyForRow:requestedRow];
	return [progressIndicators_ synchronizedObjectForKey:key];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSInteger) numberOfRowsInTableView:(NSTableView*)aTableView
{
	return [processDescriptions_ synchronizedCount];
}

- (id) tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)requestedRow
{
	NSNumber* key = [self keyForRow:requestedRow];
	NSString* processDescription = key ? [processDescriptions_ synchronizedObjectForKey:key] : @"finishing";
	NSString* processProgress = key ? [processProgressStrings_ synchronizedObjectForKey:key] : @"";
	if (processDescription && processProgress)
		return fstr(@"%@ %@", processDescription, processProgress);
	return processDescription;
}

- (void) tableView:(NSTableView*)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	if ([aCell isKindOfClass:[ProcessListCell class]])
		[aCell setIndicator:[self indicatorForRow:rowIndex]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Setting progress
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setProgress:(NSString*)progress forKey:(NSNumber*)key
{
	[processProgressStrings_ setObject:progress forKey:key];
	[processListTableView reloadData];
}


@end




@implementation ProcessListCell

- (void) setIndicator:(NSProgressIndicator*)indicator { indicator_ = indicator; }

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSRect spinningFrame, textFrame;
	const int spinnerSize = 16;
	NSDivideRect (cellFrame, &spinningFrame, &textFrame, spinnerSize, NSMinXEdge);

	[indicator_ setFrame:spinningFrame];
	[indicator_ sizeToFit];

	[super drawInteriorWithFrame:textFrame inView:controlView];	// drawText
}

@end


@implementation ProcessController

@synthesize processNumber = processNumber_;
@synthesize baseMessage   = baseMessage_;
@synthesize processList   = processList_;

+ (ProcessController*) processControllerWithMessage:(NSString*)message forList:(ProcessListController*)list
{
	ProcessController* newProcess = [[ProcessController alloc]init];
	NSNumber* processNum = [list addProcessIndicator:message];
	[newProcess setProcessList:list];
	[newProcess setBaseMessage:message];
	[newProcess setProcessNumber:processNum];
	return newProcess;
}

- (void) terminateController
{
	[processList_ removeProcessIndicator:processNumber_];
}

// The progress updates come in on the standard error pipe
- (void) gotError:(NSString*)errorString
{
	NSString* part = nil;
	NSString* total = nil;
	if ([errorString getCapturesWithRegexAndTrimedComponents:@".*?MHGProgress:.*?(\\d+)/(\\d+)\\s*$" firstComponent:&part  secondComponent:&total])
	{
		NSString* combined = fstr(@"%@/%@", part, total);
		[processList_ setProgress:combined forKey:processNumber_];
	}
	else if ([errorString getCapturesWithRegexAndTrimedComponents:@".*?MHGProgress:.*?(\\d+)\\s*$" firstComponent:&total])
		[processList_ setProgress:total forKey:processNumber_];
}

@end


