//
//  LabelsTableView.h
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"


@protocol ControllerForLabelsTableView <NSObject>
- (MacHgDocument*)	myDocument;
- (void)			labelsChanged;
@end

// This class is a subclass of NSTableView which is its own data source and own delegate. It turned out its easier this way. And
// thus in the one class we wrap up all the behavior of managing a list of revisions. It only needs the two outlets below connected up.
@interface LabelsTableView : NSTableView <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet id	<ControllerForLabelsTableView> parentController;// Controlling class should be an object which is controlling a sheet or a
																// window controller.
	IBOutlet NSButton*		showTags;
	IBOutlet NSButton*		showBookmarks;
	IBOutlet NSButton*		showBranches;
	IBOutlet NSButton*		showOpenHeads;

	NSArray*				labelsTableData_;					// The array of ordered labels (tags, branches, bookmarks) which backs the allLabelsTableView

	RepositoryData*			repositoryData_;					// The current log entry collection which backs this LogTableView.
	RepositoryData*			oldRepositoryData_;					// The second oldest log entry collection (which we sometimes fall
																// back to in order to avoid flicker while the repositoryData is
																// being updated)
	
	// Caches, we compare these to the live value from the logEntryController to see if we need to update the backing
	// labelsTableData_
	NSDictionary*			cachedTagToLabelDictionary_;		
	NSDictionary*			cachedBranchToLabelDictionary_;
	NSDictionary*			cachedBookmarkToLabelDictionary_;
	NSDictionary*			cachedOpenHeadToLabelDictionary_;
}

- (MacHgDocument*)		myDocument;

- (LabelData*) selectedLabel;
- (LabelData*) chosenLabel;
- (void)	 unload;


// Actions
- (IBAction) resetTable:(id)sender;
- (IBAction) labelTableSingleClick:(id) sender;
- (IBAction) labelTableDoubleClick:(id) sender;

@end
