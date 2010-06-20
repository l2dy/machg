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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  ImportPatchesSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface ImportPatchesSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end

@implementation ImportPatchesSheetController

@synthesize guessRenames = guessRenames_;
@synthesize guessSimilarityFactor = guessSimilarityFactor_;
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (ImportPatchesSheetController*) initImportPatchesSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"ImportPatchesSheet" owner:self];
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
	[self setGuessRenames:YES];
	[self setGuessSimilarityFactor:1.0];
	
	// Old Loading of example data when debugging...
	//	NSMutableArray* newPatches = [[NSMutableArray alloc]init];
	//	for (int i = 1; i<10; i++)
	//	{
	//		NSString* patchPath = fstr(@"/Volumes/QuickSilver/Development/sandbox/myrepo/myrepo-feature0%d.patch", i);
	//		PatchData* patch = [PatchData patchDataFromFilePath:patchPath];
	//		[newPatches addObject:patch];
	//	}
	//	[patchesTable addPatches:newPatches];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Patch Management
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) addPatches:(id)sender
{
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	[panel setDirectoryURL:[NSURL fileURLWithPath:[myDocument absolutePathOfRepositoryRoot]]];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:YES];
	[panel beginSheetModalForWindow:theImportPatchesSheet completionHandler:^(NSInteger result){
		if (result == NSAlertAlternateReturn)
			return;
		
		NSArray* fileURLs = [panel URLs];
		NSMutableArray* newPatches = [[NSMutableArray alloc]init];
		for (NSURL* pathURL in fileURLs)
		{
			PatchData* patch = [PatchData patchDataFromFilePath:[pathURL path]];
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
	[okButton setEnabled:valid];
	[sheetInformativeMessageTextField setAttributedStringValue: (valid ? [self formattedSheetMessage] : normalSheetMessageAttributedString(@"You need to add one or more patches in order to import patches."))];
}

- (void)	 patchesDidChange
{
	[self validate:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions Sheet Management
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openImportPatchesSheet:(id)sender
{
	NSString* newTitle = fstr(@"Importing Patches into %@", [myDocument selectedRepositoryShortName]);
	[importSheetTitle setStringValue:newTitle];
	 
	// Report the branch we are about to import to in the dialog	
	[patchesTable resetTable:self];
	[self validate:self];
	
	[NSApp beginSheet:theImportPatchesSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (IBAction) sheetButtonOk:(id)sender
{
	
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	BOOL canClose = NO;

	while (true)
	{
		NSMutableArray* argsImport = [NSMutableArray arrayWithObjects:@"import", nil];
		if ([[patchesTable patches] count] <= 0)
		{
			canClose = YES;
			break;
		}
		PatchData* patch = [[patchesTable patches] firstObject];
		if (!patch)
			break;

		if ([patch authorIsModified])			[argsImport addObject:@"--user"    followedBy:[patch author]];
		if ([patch dateIsModified])				[argsImport addObject:@"--date"    followedBy:[patch date]];
		if ([patch commitMessageIsModified])	[argsImport addObject:@"--message" followedBy:[patch commitMessage]];
		if ([patch forceOption])				[argsImport addObject:@"--force"];
		if ([patch exactOption])				[argsImport addObject:@"--exact"];
		if ([patch importBranchOption])			[argsImport addObject:@"--import-branch"];
		if ([patch dontCommitOption])			[argsImport addObject:@"--no-commit"];
		if (guessRenames_)						[argsImport addObject:@"--similarity" followedBy:intAsString(constrainInteger((int)round(100 * guessSimilarityFactor_), 0, 100))];
		[argsImport addObject:[patch path]];
		ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsImport  fromRoot:rootPath];
		if ([result hasErrors] || [result hasWarnings])
			break;
		[patchesTable removePatchAtIndex:0];
	}

	if (!canClose)
		return;
	[theImportPatchesSheet makeFirstResponder:theImportPatchesSheet];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theImportPatchesSheet];
	[theImportPatchesSheet orderOut:sender];
}


- (IBAction) sheetButtonCancel:(id)sender
{
	[NSApp endSheet:theImportPatchesSheet];
	[theImportPatchesSheet orderOut:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	NSString* message = fstr(@"The patches listed above will be imported into the repository %@", [myDocument selectedRepositoryShortName]);
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(message)];
	return newSheetMessage;
}


@end

