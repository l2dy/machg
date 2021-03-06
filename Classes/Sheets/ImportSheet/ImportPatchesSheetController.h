//
//  ImportPatchesSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "PatchesTableView.h"


@interface ImportPatchesSheetController : BaseSheetWindowController < ControllerForPatchesTableView >
{
	// Main window
	IBOutlet NSWindow*			theImportPatchesSheet;
	IBOutlet PatchesTableView*	patchesTable;
	IBOutlet NSSplitView*		inspectorSplitView;
	IBOutlet NSTextField*		sheetInformativeMessageTextField;
	IBOutlet NSTextField*		importSheetTitle;
	IBOutlet NSButton*			okButton;
}

@property (weak,readonly) MacHgDocument*	myDocument;
@property BOOL					guessRenames;
@property float					guessSimilarityFactor;
@property (readonly) HunkExclusions*		hunkExclusions;


- (ImportPatchesSheetController*) initImportPatchesSheetControllerWithDocument:(MacHgDocument*)doc;


// Actions Patch Management
- (IBAction) addPatches:(id)sender;
- (IBAction) removeSelectedPatches:(id)sender;
- (IBAction) validate:(id)sender;
- (void)	 patchesDidChange;


// Actions Sheet Management
- (IBAction) openImportPatchesSheet:(id)sender;
- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;

@end

