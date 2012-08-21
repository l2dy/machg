//
//  ProcessListController.h
//  MacHg
//
//  Created by Jason Harris on 12/28/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import "TaskExecutions.h"



@interface ProcessListController : NSObject
{
	IBOutlet NSTableView*	processListTableView;
	IBOutlet MacHgDocument*	myDocument;
	IBOutlet NSBox*			informationAndActivityBox;
	IBOutlet NSBox*			informationBox;
	IBOutlet NSBox*			activityBox;
	
  @private
	NSMutableDictionary*	progressIndicators_;		// A storage dictionary of number key -> progress indicators
	NSMutableDictionary*	processDescriptions_;		// This is the dictionary of number key -> process description
	NSMutableDictionary*	processProgressStrings_;	// This is the dictionary of number key -> process progress of the form '45/674'
	NSInteger				processNumber_;				// Unique number used to identify the next process in the process list
}

// Add/ remove process indicators
- (NSProgressIndicator*)	indicatorForRow:(NSInteger)requestedRow;
- (NSNumber*)	addProcessIndicator:(NSString*)processDescription;
- (void)		removeProcessIndicator:(NSNumber*)processNum;


// Table Delegate Methods
- (NSInteger)	numberOfRowsInTableView:(NSTableView*)aTableView;
- (id)			tableView:(NSTableView*)aTableView  objectValueForTableColumn:(NSTableColumn*)aTableColumn  row:(NSInteger)requestedRow;


// Setting progress
- (void)		setProgress:(NSString*)progress forKey:(NSNumber*)key;
@end





@interface ProcessListCell : NSTextFieldCell
{
	NSProgressIndicator* indicator_;
}
- (void) setIndicator:(NSProgressIndicator*)indicator;
@end





@interface ProcessController : ShellTaskController
{
	ProcessListController* __strong processList_;
	NSNumber* __strong processNumber_;
	NSString* __strong baseMessage_;
}
@property (nonatomic, strong) NSNumber*	processNumber;
@property (nonatomic, strong) NSString*	baseMessage;
@property (nonatomic, strong) ProcessListController* processList;

+ (ProcessController*) processControllerWithMessage:(NSString*)message forList:(ProcessListController*)list;
- (void) terminateController;
@end

