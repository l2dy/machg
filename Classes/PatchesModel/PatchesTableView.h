//
//  PatchesTableView.h
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import "PatchesWebview.h"

@protocol ControllerForPatchesTableView <NSObject>
- (MacHgDocument*)	myDocument;
- (void)			patchesDidChange;
- (HunkExclusions*) hunkExclusions;
@end

// This class is a subclass of NSTableView which is its own data source and own delegate. It turned out it's easier this way. And
// thus in the one class we wrap up all the behavior of managing a list of revisions. It only needs the two outlets below connected up.
@interface PatchesTableView : NSTableView <NSTableViewDelegate, NSTableViewDataSource, ControllerForPatchesWebview>
{
	IBOutlet id	<ControllerForPatchesTableView> parentController;	// Controlling class should be an object which is controlling a sheet or a
																	// window controller.
	
	IBOutlet PatchesWebview*	detailedPatchesWebView;				// This is the field where the details of the patch are displayed.

	NSArray*					patchesTableData_;					// The array of ordered patches (tags, branches, bookmarks) which
																	// backs the PatchesTableView	
}

- (MacHgDocument*)		myDocument;


// Quieres
- (BOOL)			patchIsSelected;
- (BOOL)			patchIsClicked;
- (PatchRecord*)	selectedPatch;
- (PatchRecord*)	clickedPatch;
- (PatchRecord*)	chosenPatch;
- (NSArray*)		patches;

// Actions
- (IBAction) resetTable:(id)sender;
- (IBAction) patchTableSingleClick:(id) sender;
- (IBAction) patchTableDoubleClick:(id) sender;


// Table Data Management
- (void)	 addPatches:(NSArray*)patches;
- (IBAction) removeSelectedPatches:(id)sender;
- (BOOL)	 removePatchAtIndex:(NSInteger)index;


@end





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Patches Table Cells
// ------------------------------------------------------------------------------------

@interface PatchesTableCell : NSTextFieldCell
{
	BOOL			isEditingOrSelecting_;
}
@property NSTableColumn*	patchesTableColumn;
@property PatchRecord*	patch;
@end


@interface PatchesTableCommitMessageCell : PatchesTableCell
@end

@interface PatchesTablePatchNameCell : PatchesTableCell
@end


@interface PatchesTableButtonCell : NSButtonCell
{
	IBOutlet NSTextField* buttonMessage;
}
@property NSTableColumn*	patchesTableColumn;
@property PatchRecord*	patch;

@end