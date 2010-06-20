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
#import "HistoryViewController.h"

@interface ExportPatchesSheetController (PrivateAPI)
- (NSAttributedString*) formattedSheetMessage;
@end


@implementation ExportPatchesSheetController

@synthesize textOption = textOption_;
@synthesize gitOption = gitOption_;
@synthesize noDatesOption = noDatesOption_;
@synthesize switchParentOption = switchParentOption_;
@synthesize reversePatchOption = reversePatchOption_;
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
	NSString* newTitle = fstr(@"Exporting Selected Patches in %@", [myDocument selectedRepositoryShortName]);
	[exportSheetTitle setStringValue:newTitle];
	 
	// Report the branch we are about to export to in the dialog
	NSString* newSheetMessage = fstr(@"The following files will be exported to the versions as of the revision selected below (%@)", [logTableView selectedRevision]);
	[sheetInformativeMessageTextField setStringValue: newSheetMessage];
	
	[logTableView resetTable:self];
	
	NSArray* revs = [[[myDocument theHistoryView] logTableView] chosenRevisions];
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
		NSIndexSet* firstLastIndexSet = [NSIndexSet indexSetWithIndexesInRange:MakeRangeFirstLast(minTableRow, maxTableRow)];
		[logTableView selectAndScrollToIndexSet:firstLastIndexSet];
	}
	else
	{
		[logTableView scrollToRevision:[myDocument getHGTipRevision]];
		[logTableView selectAndScrollToRevision:[myDocument getHGTipRevision]];
	}
	
	[NSApp beginSheet:theExportPatchesSheet  modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[theExportPatchesSheet makeFirstResponder:theExportPatchesSheet];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theExportPatchesSheet];
	[theExportPatchesSheet orderOut:sender];
	
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	LowHighPair pair = [logTableView lowestToHighestSelectedRevisions];

	NSInteger incompleteRev = stringAsInt([logTableView incompleteRevision]);	
	NSString* exportDescription;
	
	if      (pair.highRevision == pair.lowRevision && !reversePatchOption_ && pair.highRevision == incompleteRev)	exportDescription = fstr(@"exporting current changes", pair.lowRevision);
	else if (pair.highRevision == pair.lowRevision &&  reversePatchOption_ && pair.highRevision == incompleteRev)	exportDescription = fstr(@"exporting current changes (reversed)", pair.lowRevision);
	else if (pair.highRevision != pair.lowRevision && !reversePatchOption_ && pair.highRevision == incompleteRev)	exportDescription = fstr(@"exporting %d to current changes", pair.lowRevision);
	else if (pair.highRevision != pair.lowRevision &&  reversePatchOption_ && pair.highRevision == incompleteRev)	exportDescription = fstr(@"exporting current changes to %d (reversed)", pair.lowRevision);
	else if (pair.highRevision == pair.lowRevision && !reversePatchOption_ && pair.highRevision != incompleteRev)	exportDescription = fstr(@"exporting %d", pair.lowRevision);
	else if (pair.highRevision == pair.lowRevision &&  reversePatchOption_ && pair.highRevision != incompleteRev)	exportDescription = fstr(@"exporting %d (reversed)", pair.lowRevision);
	else if (pair.highRevision != pair.lowRevision && !reversePatchOption_ && pair.highRevision != incompleteRev)	exportDescription = fstr(@"exporting %d - %d", pair.lowRevision, pair.highRevision);
	else if (pair.highRevision != pair.lowRevision &&  reversePatchOption_ && pair.highRevision != incompleteRev)	exportDescription = fstr(@"exporting %d - %d (reversed)", pair.highRevision, pair.lowRevision);
	
	NSInteger numberOfPatches = pair.highRevision - pair.lowRevision + 1;
	NSString* fileNameTemplate = [self patchNameOption];
	fileNameTemplate  = [fileNameTemplate stringByReplacingOccurrencesOfRegex:@"\\%N" withString:intAsString(numberOfPatches)];
	BOOL changingFileName = [fileNameTemplate isMatchedByRegex:@"\\%[nrRhH]" options:RKLNoOptions];
	
	NSString* countFormat    = [[NSArray arrayWithObjects:@"%0", intAsString([intAsString(numberOfPatches)   length]), @"d", nil] componentsJoinedByString:@""];
	NSString* revisionFormat = [[NSArray arrayWithObjects:@"%0", intAsString([intAsString(pair.highRevision) length]), @"d", nil] componentsJoinedByString:@""];
	
	[myDocument dispatchToMercurialQueuedWithDescription:exportDescription  process:^{

		NSInteger start = reversePatchOption_ ? pair.highRevision : pair.lowRevision;
		NSInteger end   = reversePatchOption_ ? pair.lowRevision  : pair.highRevision;
		NSInteger count = 0;
		NSInteger rev;
		for (rev = start; !reversePatchOption_ ? rev <= end : end <= rev; rev = rev + (reversePatchOption_ ? -1 : 1))
		{
			NSMutableArray* argsDiff = [NSMutableArray arrayWithObjects:@"diff", nil];		
			if ([self textOption])			[argsDiff addObject:@"--text"];
			if ([self gitOption])			[argsDiff addObject:@"--git"];
			if ([self noDatesOption])		[argsDiff addObject:@"--nodates"];
			if ([self reversePatchOption])	[argsDiff addObject:@"--reverse"];
			if (rev != incompleteRev)
				[argsDiff addObject:@"--change" followedBy:intAsString(rev)];
	
			ExecutionResult* result = [myDocument  executeMercurialWithArgs:argsDiff  fromRoot:rootPath  whileDelayingEvents:YES];
			if (result.outStr)
			{
				NSString* patchFileName = fileNameTemplate;
				patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%R" withString:intAsString(rev)];
				patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%b" withString:[rootPath lastPathComponent]];
				patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%n" withString:fstr(countFormat,  count)];
				patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%r" withString:fstr(revisionFormat, rev)];
				if (![patchFileName isAbsolutePath])
					patchFileName = [rootPath stringByAppendingPathComponent:patchFileName];
				if (changingFileName)
					[result.outStr writeToFile:patchFileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
				else
					[[NSFileManager defaultManager] appendString:fstr(@"\n\n%@",result.outStr) toFilePath:patchFileName];
			}
			count++;
		}
	}];	
}

- (IBAction) sheetButtonCancel:(id)sender
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
	NSString* revisionNumbers = fstr(@"%d%:%d", pair.lowRevision, pair.highRevision);
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
	NSRange range = MakeRangeFirstLast([proposedSelectionIndexes firstIndex], [proposedSelectionIndexes lastIndex]);
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

