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

@protocol ControllerForLogTableView <NSObject>
- (MacHgDocument*)	myDocument;
@optional
- (void)			logTableViewSelectionDidChange:(LogTableView*)theTable;
- (NSIndexSet*)		tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes;	// We forward the delegate method of implemented
@end

// This class is a subclass of NSTableView which is its own data source and own delegate. It turned out its easier this way. And
// thus in the one class we wrap up all the behavior of managing a list of revisions. It only needs the two outlets below connected up.
@interface LogTableView : NSTableView <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet id	<ControllerForLogTableView> parentController; // Controlling class should be an object which is controlling a sheet or a
															// window controller.
	IBOutlet NSTextView*	detailedEntryTextView;			// This is the field where the details of the log entry are displayed.

	RepositoryData*			repositoryData_;				// The current log entry collection which backs this LogTableView.
	RepositoryData*			oldRepositoryData_;				// The second oldest log entry collection (which we sometimes fall
															// back to in order to avoid flicker while the repositoryData is
															// being updated)

	LogGraph*				theLogGraph_;					// The object representing the graph of the revisions
	NSString*				rootPath_;						// The root of the repository


	BOOL					canSelectIncompleteRevision_;	// Are you allowed to select the incomplete revision in this LogTableView
	int						numberOfTableRows_;
	NSArray*				theTableRows_;					// Map of table row -> revision number (NSString)
	NSString*				theSearchFilter_;				// The current search filter if any
	SingleTimedQueue*		queueForDetailedEntryDisplay_;	// When we are asked to display the details of an entry or range of
															// entries we put the request on this queue. This means when eg drag
															// selecting when the selection is constantly changing we are not
															// firing off lots and lots of requests.
}

@property (readwrite,assign) LogGraph*	theLogGraph;
@property (readwrite,assign) NSString*	theSearchFilter;
@property (readwrite,assign) NSArray*	theTableRows;
@property int							numberOfTableRows;
@property BOOL							canSelectIncompleteRevision;

- (void)		unload;
- (IBAction)	refreshTable:(id)sender;
- (IBAction)	resetTable:(id)sender;
- (void)		refreshLogGraph;


// Table Delegate Methods
- (NSInteger)	numberOfRowsInTableView:(NSTableView*)aTableView;
- (id)			tableView:(NSTableView*)aTableView  objectValueForTableColumn:(NSTableColumn*)aTableColumn  row:(NSInteger)requestedRow;
- (void)		tableView:(NSTableView*)aTableView  willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex;
- (void)		tableViewSelectionDidChange:(NSNotification*)aNotification;


// Query The Table
- (MacHgDocument*)		myDocument;
- (RepositoryData*)	repositoryData;
- (LogEntry*)	entryForTableRow:(NSInteger)rowNum;
- (NSString*)	revisionForTableRow:(NSInteger)rowNum;
- (NSInteger)	tableRowForRevision:(NSString*)revision;
- (NSInteger)	tableRowForIntegerRevision:(NSInteger)revisionInt;
- (NSInteger)	closestTableRowForRevision:(NSString*)revision;

- (BOOL)		includeIncompleteRevision;
- (NSString*)	incompleteRevision;


// Test selection
- (BOOL)		noRevisionSelected;
- (BOOL)		singleRevisionSelected;
- (BOOL)		multipleRevisionsSelected;


// Chosen / Selected item(s)
- (LogEntry*)	chosenEntry;
- (NSArray*)	chosenEntries;		// Array of LogEntry
- (NSString*)	chosenRevision;
- (NSArray*)	chosenRevisions;	// Array of NSString
- (LogEntry*)	selectedEntry;
- (NSArray*)	selectedEntries;	// Array of LogEntry
- (NSString*)	selectedRevision;
- (NSArray*)	selectedRevisions;	// Array of NSString

- (LowHighPair) lowestToHighestSelectedRevisions;
- (LowHighPair) parentToHighestSelectedRevisions;



// Scrolling
- (void)		scrollToRevision:(NSString*)revision;
- (void)		scrollToRangeOfRevisions:(LowHighPair)limits;
- (IBAction)	scrollToCurrentRevision:(id)sender;
- (IBAction)	scrollToBeginning:(id)sender;
- (IBAction)	scrollToEnd:(id)sender;
- (IBAction)	scrollToSelected:(id)sender;
- (void)		selectAndScrollToRevision:(NSString*)revision;
- (void)		selectAndScrollToRevisions:(NSArray*)revisions;
- (void)		selectAndScrollToIndexSet:(NSIndexSet*)indexSet;


// Drawing methods
- (void)		drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect;

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

- (NSColor*) highlightColorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView;
@end
