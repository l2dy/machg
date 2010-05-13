//
//  ExportPatchesSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ExportPatchesSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "LogEntry.h"
#import "RepositoryData.h"
#import "LogTableView.h"
#import "HistoryPaneController.h"

@implementation ExportPatchesSheetController

@synthesize textOption = textOption_;
@synthesize gitOption = gitOption_;
@synthesize noDatesOption = noDatesOption_;
@synthesize switchParentOption = switchParentOption_;
@synthesize patchNameOption = patchNameOption_;
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (ExportPatchesSheetController*) initExportPatchesSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"ExportPatchesSheet" owner:self];
	return self;
}


- (IBAction) openSplitViewPaneToDefaultHeight: (id)sender
{
	[inspectorSplitView setPosition:200 ofDividerAtIndex: 0];
}


- (void) awakeFromNib
{
	[self openSplitViewPaneToDefaultHeight: self];
	[theExportPatchesSheet makeFirstResponder:logTableView];
	[logTableView setCanSelectIncompleteRevision:YES];
	[self setPatchNameOption:@"%b-feature%n.patch"];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) validate:(id)sender
{
	BOOL valid = ![logTableView noRevisionSelected];
	[okButton setEnabled:valid];
	[sheetInformativeMessageTextField setAttributedStringValue: (valid ? [self formattedSheetMessage] : normalSheetMessageAttributedString(@"You need to select one or more revisions in order to export a patch."))];
}

- (IBAction) openExportPatchesSheetWithSelectedRevisions:(id)sender
{
	NSString* newTitle = [NSString stringWithFormat:@"Exporting Selected Patches in %@", [myDocument selectedRepositoryShortName]];
	[exportSheetTitle setStringValue:newTitle];
	 
	// Report the branch we are about to export to in the dialog
	NSString* newSheetMessage = [NSString stringWithFormat:@"The following files will be exported to the versions as of the revision selected below (%@)", [logTableView selectedRevision]];
	[sheetInformativeMessageTextField setStringValue: newSheetMessage];
	
	[logTableView resetTable:self];
	
	NSArray* revs = [[[myDocument theHistoryPaneController] logTableView] chosenRevisions];
	if ([revs count] > 0)
	{
		NSInteger minRev = stringAsInt([revs objectAtIndex:0]);
		NSInteger maxRev = stringAsInt([revs objectAtIndex:0]);
		for (NSString* stringRev in revs)
		{
			NSInteger revInt = stringAsInt(stringRev);
			minRev = MIN(revInt, minRev);
			maxRev = MAX(revInt, maxRev);
		}
		NSInteger minTableRow = [logTableView tableRowForIntegerRevision:minRev];
		NSInteger maxTableRow = [logTableView tableRowForIntegerRevision:maxRev];
		NSIndexSet* firstLastIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRangeFirstLast(minTableRow, maxTableRow)];
		[logTableView selectAndScrollToIndexSet:firstLastIndexSet];
	}
	else
	{
		[logTableView scrollToRevision:[myDocument getHGTipRevision]];
		[logTableView selectAndScrollToRevision:[myDocument getHGTipRevision]];
	}
	
	[NSApp beginSheet:theExportPatchesSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (IBAction) sheetButtonOkForExportPatchesSheet:(id)sender
{
	[theExportPatchesSheet makeFirstResponder:theExportPatchesSheet];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theExportPatchesSheet];
	[theExportPatchesSheet orderOut:sender];
	
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];
	
	BOOL exportPatchForIncompleteVersion = NO;
	BOOL exportPatchesForLowHigh = YES;
	NSString* exportDescription = [NSString stringWithFormat:@"exporting %d-%d", pair.lowRevision, pair.highRevision];
	if (pair.highRevision == stringAsInt([logTableView incompleteRevision]))
	{
		exportPatchForIncompleteVersion = YES;
		if (pair.lowRevision == pair.highRevision)
		{
			exportPatchesForLowHigh = NO;
			exportDescription = @"exporting current changes";
		}
		else
		{
			pair.highRevision -= 1;
			[NSString stringWithFormat:@"exporting %d to current changes", pair.lowRevision];
		}
	}
	
	NSInteger numberOfPatches = (exportPatchForIncompleteVersion ? 1 : 0) + (exportPatchesForLowHigh ? (pair.highRevision - pair.lowRevision + 1) : 0);
	NSMutableArray* argsExportRange = nil;
	NSMutableArray* argsDiff = nil;
	NSString* fileNameTemplate = [self patchNameOption];
	fileNameTemplate  = [fileNameTemplate stringByReplacingOccurrencesOfRegex:@"\\%N" withString:intAsString(numberOfPatches)];
	BOOL changingFileName = [fileNameTemplate isMatchedByRegex:@"\\%[nrRhH]" options:RKLNoOptions];

	if (exportPatchesForLowHigh)
	{
		argsExportRange = [NSMutableArray arrayWithObjects:@"export", nil];
		NSString* revisionNumbers = [NSString stringWithFormat:@"%d%:%d", pair.lowRevision, pair.highRevision];
		
		if ([self textOption])			[argsExportRange addObject:@"--text"];
		if ([self gitOption])			[argsExportRange addObject:@"--git"];
		if ([self noDatesOption])		[argsExportRange addObject:@"--nodates"];
		if ([self switchParentOption])	[argsExportRange addObject:@"--switch-parent"];
		[argsExportRange addObject:@"--output" followedBy:fileNameTemplate];
		[argsExportRange addObject:revisionNumbers];
	}
	
	if (exportPatchForIncompleteVersion)
	{
		argsDiff = [NSMutableArray arrayWithObjects:@"diff", nil];		
		if ([self textOption])			[argsDiff addObject:@"--text"];
		if ([self gitOption])			[argsDiff addObject:@"--git"];
		if ([self noDatesOption])		[argsDiff addObject:@"--nodates"];
	}
	
	[myDocument dispatchToMercurialQueuedWithDescription:exportDescription  process:^{
		if (exportPatchesForLowHigh)
			[myDocument  executeMercurialWithArgs:argsExportRange  fromRoot:rootPath  whileDelayingEvents:YES];
		if (exportPatchForIncompleteVersion)
		{
			// For the incomplete version since writing this file can't be handled by export we have to use diff instead.
			// Substitute the %_ control characters for their values and then write the diff to the file
			ExecutionResult result = [myDocument  executeMercurialWithArgs:argsDiff  fromRoot:rootPath  whileDelayingEvents:YES];
			if (result.outStr)
			{
				NSString* patchFileName = fileNameTemplate;
				patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%R" withString:[logTableView incompleteRevision]];
				patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%b" withString:[rootPath lastPathComponent]];
				patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%n" withString:intAsString(numberOfPatches)];
				patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%r" withString:[logTableView incompleteRevision]];
				if (![patchFileName isAbsolutePath])
					patchFileName = [rootPath stringByAppendingPathComponent:patchFileName];
				if (changingFileName)
					[result.outStr writeToFile:patchFileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
				else
					[[NSFileManager defaultManager] appendString:[NSString stringWithFormat:@"\n\n%@",result.outStr] toFilePath:patchFileName];
			}
		}
	}];	
}

- (IBAction) sheetButtonCancelForExportPatchesSheet:(id)sender
{
	[NSApp endSheet:theExportPatchesSheet];
	[theExportPatchesSheet orderOut:sender];
}


- (IBAction) sheetButtonCleanForExportOption:(id)sender
{
	[self logTableViewSelectionDidChange:logTableView];
}


- (IBAction) sheetButtonViewDifferencesForExportPatchesSheet:(id)sender
{
	NSArray* rootPathAsArray = [myDocument absolutePathOfRepositoryRootAsArray];
	LowHighPair pair = [logTableView parentToHighestSelectedRevisions];
	NSString* revisionNumbers = [NSString stringWithFormat:@"%d%:%d", pair.lowRevision, pair.highRevision];
	[myDocument viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:revisionNumbers];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable;
{
	[self validate:self];
}

- (NSIndexSet*) tableView:(NSTableView*)tableView selectionIndexesForProposedSelection:(NSIndexSet*)proposedSelectionIndexes
{
	NSRange range = NSMakeRangeFirstLast([proposedSelectionIndexes firstIndex], [proposedSelectionIndexes lastIndex]);
	return [NSIndexSet indexSetWithIndexesInRange:range];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];
	if (pair.lowRevision == pair.highRevision)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"A patch corresponding to revision ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.lowRevision))];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to the given filename.")];
	}
	else
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"Patches corresponding to revisions ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.lowRevision))];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" through ")];		
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(intAsString(pair.highRevision))];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to the given filename.")];		
	}
	return newSheetMessage;
}


@end

