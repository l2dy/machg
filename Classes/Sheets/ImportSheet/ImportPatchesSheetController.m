//
//  ImportPatchesSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ImportPatchesSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "HistoryViewController.h"
#import "PatchData.h"
#import "HunkExclusions.h"





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  ImportPatchesSheetController
// ------------------------------------------------------------------------------------
// MARK: -

@interface ImportPatchesSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end

@implementation ImportPatchesSheetController

@synthesize guessRenames = guessRenames_;
@synthesize guessSimilarityFactor = guessSimilarityFactor_;
@synthesize hunkExclusions = hunkExclusions_;
@synthesize myDocument = myDocument_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (ImportPatchesSheetController*) initImportPatchesSheetControllerWithDocument:(MacHgDocument*)doc
{
	self = [super init];
	if (!self)
		return nil;
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"ImportPatchesSheet"];
	[self window];	// force / ensure the nib is loaded
	hunkExclusions_ = [[HunkExclusions alloc]init];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[inspectorSplitView setPosition:200 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theImportPatchesSheet makeFirstResponder:patchesTable];
	self.guessRenames = YES;
	self.guessSimilarityFactor = 1.0;
	
	// Old Loading of example data when debugging...
	//	NSMutableArray* newPatches = [[NSMutableArray alloc]init];
	//	for (int i = 1; i<10; i++)
	//	{
	//		NSString* patchPath = fstr(@"/Volumes/QuickSilver/Development/sandbox/myrepo/myrepo-feature0%d.patch", i);
	//		PatchRecord* patch = [PatchRecord patchRecordFromFilePath:patchPath];
	//		[newPatches addObject:patch];
	//	}
	//	[patchesTable addPatches:newPatches];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Patch Management
// ------------------------------------------------------------------------------------

- (IBAction) addPatches:(id)sender
{
	NSOpenPanel* panel = NSOpenPanel.openPanel;
	[panel setDirectoryURL:[NSURL fileURLWithPath:myDocument_.absolutePathOfRepositoryRoot]];
	panel.canChooseFiles = YES;
	panel.canChooseDirectories = NO;
	panel.allowsMultipleSelection = YES;
	[panel beginSheetModalForWindow:theImportPatchesSheet completionHandler:^(NSInteger result){
		if (result == NSAlertAlternateReturn)
			return;
		
		NSArray* fileURLs = panel.URLs;
		NSMutableArray* newPatches = [[NSMutableArray alloc]init];
		for (NSURL* pathURL in fileURLs)
		{
			PatchRecord* patch = [PatchRecord patchRecordFromFilePath:pathURL.path];
			[newPatches addObject:patch];
		}
		[patchesTable addPatches:newPatches];
		[self validate:self];
	}];
}
	 


- (IBAction) removeSelectedPatches:(id)sender
{
	[patchesTable removeSelectedPatches:sender];
	[self validate:self];
}


- (IBAction) validate:(id)sender
{
	BOOL valid = [patchesTable numberOfRowsInTableView:patchesTable] > 0;
	okButton.enabled = valid;
	[sheetInformativeMessageTextField setAttributedStringValue: (valid ? self.formattedSheetMessage : normalSheetMessageAttributedString(@"You need to add one or more patches in order to import patches."))];
}

- (void)	 patchesDidChange
{
	[self validate:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions Sheet Management
// ------------------------------------------------------------------------------------

- (IBAction) openImportPatchesSheet:(id)sender
{
	NSString* newTitle = fstr(@"Importing Patches into %@", myDocument_.selectedRepositoryShortName);
	importSheetTitle.stringValue = newTitle;
	 
	// Report the branch we are about to import to in the dialog
	[patchesTable resetTable:self];
	[self validate:self];
	
	[myDocument_ beginSheet:theImportPatchesSheet];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[theImportPatchesSheet makeFirstResponder:theImportPatchesSheet];	// Make the fields of the sheet commit any changes they currently have
	NSString* rootPath = myDocument_.absolutePathOfRepositoryRoot;
	NSMutableString* cumulativeMessages = [[NSMutableString alloc] init];
	BOOL canClose = NO;

	while (true)
	{
		NSMutableArray* argsImport = [NSMutableArray arrayWithObjects:@"import", nil];
		if (patchesTable.patches.count <= 0)
		{
			canClose = YES;
			break;
		}
		PatchRecord* patch = patchesTable.patches.firstObject;
		if (!patch)
			break;

		BOOL willFilterPatch = IsNotEmpty([hunkExclusions_ repositoryHunkExclusionsForRoot:rootPath]);
		if (patch.authorIsModified        || willFilterPatch)		[argsImport addObject:@"--user"    followedBy:patch.author];
		if (patch.dateIsModified          || willFilterPatch)		[argsImport addObject:@"--date"    followedBy:patch.date];
		if (patch.commitMessageIsModified || willFilterPatch)		[argsImport addObject:@"--message" followedBy:patch.commitMessage];
		if (patch.forceOption)									[argsImport addObject:@"--force"];
		if (patch.exactOption)									[argsImport addObject:@"--exact"];
		if (patch.importBranchOption)								[argsImport addObject:@"--import-branch"];
		if (patch.dontCommitOption)								[argsImport addObject:@"--no-commit"];
		if (guessRenames_)											[argsImport addObject:@"--similarity" followedBy:intAsString(constrainInteger((int)round(100 * guessSimilarityFactor_), 0, 100))];

		PatchData* patchData = patch.patchData;
		NSString* patchPath = patch.path;
		if (willFilterPatch)
			patchPath = [patchData tempFileWithPatchBodyExcluding:hunkExclusions_ withRoot:rootPath];
		[argsImport addObject:patchPath];
		ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsImport  fromRoot:rootPath];
		if (result.hasWarnings)
			RunAlertPanel(@"Results of Import", result.errStr, @"OK", nil, nil);

//		if (result.hasWarnings)
//			[cumulativeMessages appendString:result.errStr];
		if (result.hasErrors)
			break;
		[patchesTable removePatchAtIndex:0];
	}

	if (IsNotEmpty(cumulativeMessages))
		RunAlertPanel(@"Results of Import", cumulativeMessages, @"OK", nil, nil);
	if (!canClose)
		return;
	[theImportPatchesSheet makeFirstResponder:theImportPatchesSheet];	// Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:theImportPatchesSheet];
}


- (IBAction) sheetButtonCancel:(id)sender
{
	[myDocument_ endSheet:theImportPatchesSheet];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// ------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	NSString* message = fstr(@"The patches listed above will be imported into the repository %@", myDocument_.selectedRepositoryShortName);
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(message)];
	return newSheetMessage;
}


@end

