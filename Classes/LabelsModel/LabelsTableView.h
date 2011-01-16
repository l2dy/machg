//
//  LabelsTableView.h
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"


@protocol ControllerForLabelsTableView <NSObject>
- (MacHgDocument*)	myDocument;
- (void)			labelsChanged;
@end

// This class is a subclass of NSTableView which is its own data source and own delegate. It turned out it's easier this way. And
// thus in the one class we wrap up all the behavior of managing a list of revisions. It only needs the two outlets below connected up.
@interface LabelsTableView : NSTableView <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet id	<ControllerForLabelsTableView> parentController;// Controlling class should be an object which is controlling a sheet or a
																// window controller.
	IBOutlet NSButton*		showTags;
	IBOutlet NSButton*		showBookmarks;
	IBOutlet NSButton*		showBranches;
	IBOutlet NSButton*		showClosedBranches;
	IBOutlet NSButton*		showOpenHeads;

	NSArray*				labelsTableData_;					// The array of ordered labels (tags, branches, bookmarks) which backs the allLabelsTableView

	LabelType				labelsTableFilterType_;				// We cache the types of labels we are going to show. If this changes
																// we have to recompute the labelsTableData_
}

- (MacHgDocument*)	myDocument;

- (LabelData*)		selectedLabel;
- (LabelData*)		chosenLabel;
- (void)			unload;


// Actions
- (IBAction) resetTable:(id)sender;
- (IBAction) labelTableSingleClick:(id) sender;
- (IBAction) labelTableDoubleClick:(id) sender;

@end
