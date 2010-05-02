//
//  ProcessListController.h
//  MacHg
//
//  Created by Jason Harris on 12/28/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "Common.h"



@interface ProcessListController : NSObject
{
	IBOutlet NSTableView*	processListTableView;
	IBOutlet MacHgDocument*	myDocument;
	IBOutlet NSBox*			informationAndActivityBox;
	IBOutlet NSBox*			informationBox;
	IBOutlet NSBox*			activityBox;
	
  @private
	NSMutableDictionary*	progressIndicators_;	// A storage dictionary of number key -> progress indicators
	NSMutableDictionary*	processList_;			// This is the dictionary of number key -> process description
	NSInteger				processNumber_;			// Unique number used to identify the next process in the process list
}

// Add/ remove process indicators
- (NSNumber*)				addProcessIndicator:(NSString*)processDescription;
- (void)					removeProcessIndicator:(NSNumber*)processNum;
- (NSProgressIndicator*)	indicatorForRow:(NSInteger)requestedRow;


// Table Delegate Methods
- (NSInteger)				numberOfRowsInTableView:(NSTableView*)aTableView;
- (id)						tableView:(NSTableView*)aTableView  objectValueForTableColumn:(NSTableColumn*)aTableColumn  row:(NSInteger)requestedRow;

@end


@interface ProcessListCell : NSTextFieldCell
{
	NSProgressIndicator* indicator_;
}
- (void) setIndicator:(NSProgressIndicator*)indicator;

@end