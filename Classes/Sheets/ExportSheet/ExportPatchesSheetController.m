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
	LowHighPair pair = [logTableView lowestHighestSelectedRevisions];
	NSString* exportDescription = [NSString stringWithFormat:@"exporting %d-%d", pair.lowRevision, pair.highRevision];
	NSMutableArray* argsExport = [NSMutableArray arrayWithObjects:@"export", nil];
	NSString* revisionNumbers = [NSString stringWithFormat:@"%d%:%d", pair.lowRevision, pair.highRevision];

	if ([self textOption])			[argsExport addObject:@"--text"];
	if ([self gitOption])			[argsExport addObject:@"--git"];
	if ([self noDatesOption])		[argsExport addObject:@"--nodates"];
	if ([self switchParentOption])	[argsExport addObject:@"--switch-parent"];
	[argsExport addObject:@"--output" followedBy:[self patchNameOption]];
	[argsExport addObject:revisionNumbers];
	
	[myDocument dispatchToMercurialQueuedWithDescription:exportDescription  process:^{
		[myDocument  executeMercurialWithArgs:argsExport  fromRoot:rootPath  whileDelayingEvents:YES];
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
	LowHighPair pair = [logTableView lowestHighestSelectedRevisions];
	LogEntry* lowRevEntry = [[logTableView repositoryData] entryForRevisionString:intAsString(pair.lowRevision)];
	NSArray* parents = [lowRevEntry parentsOfEntry];
	if ([parents count] == 0)
		pair.lowRevision = MAX(0,pair.lowRevision - 1);	// Step back one to see the differences from the previous version to this version.
	else
		pair.lowRevision = numberAsInt([parents objectAtIndex:0]);
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
	LowHighPair pair = [logTableView lowestHighestSelectedRevisions];
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

