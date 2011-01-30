//
//  PatchesTableView.h
//  MacHg
//
//  Created by Jason Harris on 4/10/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"


@protocol ControllerForPatchesTableView <NSObject>
- (MacHgDocument*)	myDocument;
- (void)			patchesDidChange;
@end

// This class is a subclass of NSTableView which is its own data source and own delegate. It turned out it's easier this way. And
// thus in the one class we wrap up all the behavior of managing a list of revisions. It only needs the two outlets below connected up.
@interface PatchesTableView : NSTableView <NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet id	<ControllerForPatchesTableView> parentController;	// Controlling class should be an object which is controlling a sheet or a
																	// window controller.
	IBOutlet NSTextView*	detailedPatchTextView;					// This is the field where the details of the patch are displayed.

	NSArray*				patchesTableData_;						// The array of ordered patches (tags, branches, bookmarks) which
																	// backs the PatchesTableView
}

- (MacHgDocument*)			myDocument;
- (void)					unload;


// Quieres
- (BOOL)		patchIsSelected;
- (BOOL)		patchIsClicked;
- (PatchData*)	selectedPatch;
- (PatchData*)	clickedPatch;
- (PatchData*)	chosenPatch;
- (NSArray*)	patches;

// Actions
- (IBAction) resetTable:(id)sender;
- (IBAction) patchTableSingleClick:(id) sender;
- (IBAction) patchTableDoubleClick:(id) sender;


// Table Data Management
- (void)	 addPatches:(NSArray*)patches;
- (IBAction) removeSelectedPatches:(id)sender;
- (BOOL)	 removePatchAtIndex:(NSInteger)index;


@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Patches Table Cells
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface PatchesTableCell : NSTextFieldCell
{
	NSTableColumn*	patchesTableColumn_;
	PatchData*		patch_;
	BOOL			isEditingOrSelecting_;
}
@property (assign,readwrite) NSTableColumn*	patchesTableColumn;
@property (assign,readwrite) PatchData*		patch;
@end


@interface PatchesTableCommitMessageCell : PatchesTableCell
{}
@end

@interface PatchesTablePatchNameCell : PatchesTableCell
{}
@end


@interface PatchesTableButtonCell : NSButtonCell
{
	IBOutlet NSTextField* buttonMessage;
	NSTableColumn* patchesTableColumn_;
	PatchData*	   patch_;
}
@property (assign,readwrite) NSTableColumn*	patchesTableColumn;
@property (assign,readwrite) PatchData*		patch;

@end