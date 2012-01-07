//
//  LogTableView.h
//  MacHg
//
//  Created by Jason Harris on 8/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@class LogTableTextView;

@protocol ControllerForLogTableView <NSObject>
- (MacHgDocument*)	myDocument;
@optional
- (NSString*)		searchFieldValue;
- (void)			logTableViewSelectionDidChange:(LogTableView*)theTable;
- (NSIndexSet*)		tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes;	// We forward the delegate method of implemented
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LogTableView
// -----------------------------------------------------------------------------------------------------------------------------------------

// This class is a subclass of NSTableView which is its own data source and own delegate. It turned out it's easier this way. And
// thus in the one class we wrap up all the behavior of managing a list of revisions. It only needs the two outlets below connected up.
@interface LogTableView : NSTableView <NSTableViewDelegate, NSTableViewDataSource, NSUserInterfaceValidations>
{
	IBOutlet id	<ControllerForLogTableView> parentController; // Controlling class should be an object which is controlling a sheet or a
															// window controller.
	IBOutlet LogTableTextView* detailedEntryTextView;		// This is the field where the details of the log entry are displayed.

	RepositoryData*			repositoryData_;				// The current log entry collection which backs this LogTableView.
	NSString*				rootPath_;						// The root of the repository

	BOOL					canSelectIncompleteRevision_;	// Are you allowed to select the incomplete revision in this LogTableView
	NSArray*				theTableRows_;					// Map of table row -> revision number (NSString)
	BOOL					tableIsFiltered_;				// Are the revisions filtered through some keyword, or revset filter
	SingleTimedQueue*		queueForDetailedEntryDisplay_;	// When we are asked to display the details of an entry or range of
															// entries we put the request on this queue. This means when eg drag
															// selecting when the selection is constantly changing we are not
															// firing off lots and lots of requests.
	BOOL					awake_;							// Has this nib been awakened yet?
}

@property (readwrite,assign) NSArray*	theTableRows;
@property (readonly, assign) BOOL		tableIsFiltered;
@property BOOL							canSelectIncompleteRevision;

- (void)		unload;
- (IBAction)	refreshTable:(id)sender;
- (IBAction)	resetTable:(id)sender;


// Table Delegate Methods
- (NSInteger)	numberOfRowsInTableView:(NSTableView*)aTableView;
- (id)			tableView:(NSTableView*)aTableView  objectValueForTableColumn:(NSTableColumn*)aTableColumn  row:(NSInteger)requestedRow;
- (void)		tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex;
- (void)		tableViewSelectionDidChange:(NSNotification*)aNotification;


// Query The Table
- (MacHgDocument*)	myDocument;
- (RepositoryData*)	repositoryData;
- (LogEntry*)	entryForTableRow:(NSInteger)rowNum;
- (NSString*)	revisionForTableRow:(NSInteger)rowNum;
- (NSInteger)	tableRowForRevision:(NSNumber*)revision;
- (NSInteger)	tableRowForIntegerRevision:(NSInteger)revisionInt;
- (NSInteger)	closestTableRowForRevision:(NSNumber*)revision;

- (BOOL)		includeIncompleteRevision;
- (NSNumber*)	incompleteRevision;


// Test selection
- (BOOL)		noRevisionSelected;
- (BOOL)		revisionsAreSelected;
- (BOOL)		singleRevisionSelected;
- (BOOL)		multipleRevisionsSelected;


// Chosen / Selected item(s)
- (LogEntry*)	chosenEntry;
- (NSArray*)	chosenEntries;		// Array of LogEntry
- (NSNumber*)	chosenRevision;
- (NSArray*)	chosenRevisions;	// Array of NSNumbers
- (LogEntry*)	selectedEntry;
- (NSArray*)	selectedEntries;	// Array of LogEntry
- (NSNumber*)	selectedRevision;
- (NSArray*)	selectedRevisions;	// Array of NSNumbers
- (NSNumber*)	selectedCompleteRevision;

- (LogEntry*)   lowestSelectedEntry;	// The highest revision of the selected revisions
- (LogEntry*)   highestSelectedEntry;	// The lowest  revision of the selected revisions

- (LowHighPair) lowestToHighestSelectedRevisions;
- (LowHighPair) parentToHighestSelectedRevisions;



// Scrolling
- (void)		scrollToRevision:(NSNumber*)revision;
- (void)		scrollToRangeOfRevisions:(LowHighPair)limits;
- (IBAction)	scrollToCurrentRevision:(id)sender;
- (IBAction)	scrollToBeginning:(id)sender;
- (IBAction)	scrollToEnd:(id)sender;
- (IBAction)	scrollToSelected:(id)sender;
- (void)		selectAndScrollToRevision:(NSNumber*)revision;
- (void)		selectAndScrollToRevisions:(NSArray*)revisions;
- (void)		selectAndScrollToIndexSet:(NSIndexSet*)indexSet;


// Goto
- (IBAction)	getAndScrollToChangeset:(id)sender;


// Drawing methods
- (void)		drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect;


// Graphic Operations
- (NSRect)		rectOfRowInWindow:(NSInteger)row;

@end




@interface LogTableTextFieldCell : NSTextFieldCell
{
	LogEntry*		entry_;				// The entry backing this cell
	LogTableView*	logTableView_;
	NSTableColumn*	logTableColumn_;
}
@property (readwrite,assign) LogEntry*		entry;
@property (assign,readwrite) LogTableView*	logTableView;
@property (assign,readwrite) NSTableColumn*	logTableColumn;

- (NSColor*)	highlightColorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView;
@end




@interface LogTableTextView : NSTextView
- (NSArray*)	writablePasteboardTypes;
- (BOOL)		writeSelectionToPasteboard:(NSPasteboard*)pboard type:(NSString*)type;
@end


