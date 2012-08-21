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
@synthesize reversePatchOption = reversePatchOption_;
@synthesize patchNameOption = patchNameOption_;
@synthesize myDocument;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (ExportPatchesSheetController*) initExportPatchesSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	gitOption_ = YES;
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions Log Inspector
// ------------------------------------------------------------------------------------

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
		NSInteger minRev = numberAsInt(revs[0]);
		NSInteger maxRev = numberAsInt(revs[0]);
		for (NSNumber* revision in revs)
		{
			NSInteger revInt = numberAsInt(revision);
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
	
	[myDocument beginSheet:theExportPatchesSheet];
}


static NSInteger entrySort(id entry1, id entry2, void* context)
{
    int v1 = [entry1 revisionInt];
    int v2 = [entry2 revisionInt];
    if (v1 < v2)
        return NSOrderedAscending;
    if (v1 > v2)
        return NSOrderedDescending;
	return NSOrderedSame;
}

static NSInteger entryReverseSort(id entry1, id entry2, void* context)
{
    int v1 = [entry1 revisionInt];
    int v2 = [entry2 revisionInt];
    if (v1 > v2)
        return NSOrderedAscending;
    if (v1 < v2)
        return NSOrderedDescending;
	return NSOrderedSame;
}

- (IBAction) sheetButtonOk:(id)sender
{
	[theExportPatchesSheet makeFirstResponder:theExportPatchesSheet];	// Make the text fields of the sheet commit any changes they currently have
	[myDocument endSheet:theExportPatchesSheet];
	
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSArray* entries = [logTableView selectedEntries];
	NSInteger incompleteRev = numberAsInt([logTableView incompleteRevision]);
	BOOL singleEntrySelected = [entries count] == 1;

	// Sort the entries into the correct order.
	if (reversePatchOption_)
		entries = [entries sortedArrayUsingFunction:entryReverseSort context:NULL];
	else
		entries = [entries sortedArrayUsingFunction:entrySort context:NULL];
	
	NSInteger start = [[entries firstObject] revisionInt];
	NSInteger end   = [[entries lastObject] revisionInt];
	BOOL incompleteRevSelected = (incompleteRev == start || incompleteRev == end);
	
	NSString* exportDescription;
	
	if      ( singleEntrySelected && !reversePatchOption_ &&  incompleteRevSelected)	exportDescription =      @"exporting current changes";
	else if ( singleEntrySelected &&  reversePatchOption_ &&  incompleteRevSelected)	exportDescription =      @"exporting current changes (reversed)";
	else if ( singleEntrySelected && !reversePatchOption_ && !incompleteRevSelected)	exportDescription = fstr(@"exporting %d", start);
	else if ( singleEntrySelected &&  reversePatchOption_ && !incompleteRevSelected)	exportDescription = fstr(@"exporting %d (reversed)", start);
	else if (!singleEntrySelected && !reversePatchOption_                          )	exportDescription =      @"exporting selected revisions";
	else if (!singleEntrySelected &&  reversePatchOption_                          )	exportDescription =      @"exporting selected revisions (reversed)";
	
	NSInteger numberOfPatches  = [entries count];
	NSString* fileNameTemplate = [self patchNameOption];
	fileNameTemplate      = [fileNameTemplate stringByReplacingOccurrencesOfRegex:@"\\%N" withString:intAsString(numberOfPatches)];
	BOOL changingFileName = [fileNameTemplate isMatchedByRegex:@"\\%[nrRhH]" options:RKLNoOptions];
	
	NSString* countFormat    = [@[@"%0", intAsString([intAsString(numberOfPatches) length]), @"d"] componentsJoinedByString:@""];
	NSString* revisionFormat = [@[@"%0", intAsString([intAsString(MAX(start, end)) length]), @"d"] componentsJoinedByString:@""];
	
	[myDocument dispatchToMercurialQueuedWithDescription:exportDescription  process:^{
		[myDocument delayEventsUntilFinishBlock:^{
			NSInteger count = 1;
			for (LogEntry* entry in entries)
			{
				NSInteger rev = [entry revisionInt];
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
					/*
					 # HG changeset patch
					 # User jfh <jason@jasonfharris.com>
					 # Date 1276975872 -7200
					 # Node ID bdd9a9abe32337b87506fb1f1265bd9448636e2e
					 # Parent  58e3679ba81330385744e98ccd5de9fb9e18e84b
					 */
					NSString* content = result.outStr;
					if (rev != incompleteRev && !reversePatchOption_)
					{
						[entry fullyLoadEntry];
						NSNumber* firstParentRev = [entry firstParent];
						LogEntry* parent = [[myDocument repositoryData] entryForRevision:firstParentRev];
						[parent fullyLoadEntry];
						
						LogEntry* entry = [[myDocument repositoryData] entryForRevision:intAsNumber(rev)];
						NSString* header1 = @"# HG changeset patch";
						NSString* header2 = fstr(@"# User %@", [entry fullAuthor]);
						NSString* header3 = fstr(@"# Date %@", [entry isoDate]);
						NSString* header4 = fstr(@"# Node ID %@", [entry changeset]);
						NSString* header5 = fstr(@"# Parent  %@", [parent changeset]);
						NSString* header6 = fstr(@"%@\n", [entry fullComment]);
						content = [@[header1, header2, header3, header4, header5, header6, content] componentsJoinedByString:@"\n"];
					}
					else if (rev != incompleteRev && reversePatchOption_)
					{
						[entry fullyLoadEntry];
						LogEntry* parent = [[myDocument repositoryData] entryForRevision:[entry firstParent]];
						[parent fullyLoadEntry];
						
						LogEntry* entry = [[myDocument repositoryData] entryForRevision:intAsNumber(rev)];
						NSString* header1 = @"# HG changeset patch";
						NSString* header2 = fstr(@"# User %@", [entry fullAuthor]);
						NSString* header3 = fstr(@"Backout: %@\n", [entry fullComment]);
						content = [@[header1, header2, header3, content] componentsJoinedByString:@"\n"];
					}
					NSString* patchFileName = fileNameTemplate;
					patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%R" withString:intAsString(rev)];
					patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%b" withString:[rootPath lastPathComponent]];
					patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%n" withString:fstr(countFormat,  count)];
					patchFileName = [patchFileName stringByReplacingOccurrencesOfRegex:@"\\%r" withString:fstr(revisionFormat, rev)];
					if (![patchFileName isAbsolutePath])
						patchFileName = [rootPath stringByAppendingPathComponent:patchFileName];
					if (changingFileName)
					{
						NSError* err = nil;
						[content writeToFile:patchFileName atomically:YES encoding:NSUTF8StringEncoding error:&err];
						[NSApp presentAnyErrorsAndClear:&err];
					}
					else
						[[NSFileManager defaultManager] appendString:fstr(@"\n\n%@", content) toFilePath:patchFileName];
				}
				count++;
			}
		}];
	}];	
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[myDocument endSheet:theExportPatchesSheet];
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





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// ------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[self validate:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: TextField Delegate Methods
// ------------------------------------------------------------------------------------

- (void) controlTextDidChange:(NSNotification*)aNotification
{
	[self validate:[aNotification object]];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// ------------------------------------------------------------------------------------

- (NSAttributedString*) formattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];

	NSArray* entries = [logTableView selectedEntries];
	NSInteger incompleteRev = numberAsInt([logTableView incompleteRevision]);
	BOOL singleEntrySelected = [entries count] == 1;
	
	// Sort the entries into the correct order.
	if (reversePatchOption_)
		entries = [entries sortedArrayUsingFunction:entryReverseSort context:NULL];
	else
		entries = [entries sortedArrayUsingFunction:entrySort context:NULL];
	
	NSInteger start = [[entries firstObject] revisionInt];
	NSInteger end   = [[entries lastObject] revisionInt];

	NSString* fileNameTemplate = [self patchNameOption];
	BOOL changingFileName = [fileNameTemplate isMatchedByRegex:@"\\%[nrRhH]" options:RKLNoOptions];
	BOOL incompleteRevSelected = (incompleteRev == start || incompleteRev == end);
	
	
	
	if (singleEntrySelected && incompleteRevSelected && !reversePatchOption_)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"A patch corresponding to the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"uncommitted changes")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to the given filename.")];
	}
	else if (singleEntrySelected && incompleteRevSelected && reversePatchOption_)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"A patch corresponding to the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"opposite")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" of the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"uncommitted changes")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to the given filename.")];
	}
	else if (singleEntrySelected && !incompleteRevSelected && !reversePatchOption_)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"A patch corresponding to revision ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString([[entries firstObject] revisionStr])];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to the given filename.")];
	}
	else if (singleEntrySelected && !incompleteRevSelected && reversePatchOption_)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"A patch corresponding to the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"opposite")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" of revision ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString([[entries firstObject] revisionStr])];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to the given filename.")];
	}
	else if (reversePatchOption_ && changingFileName)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"Patches corresponding to the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"opposite")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" of the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"selected revisions")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to files specified by the filename template.")];
	}
	else if (reversePatchOption_ && !changingFileName)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"Patches corresponding to the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"opposite")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" of the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"selected revisions")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to the given filename.")];
	}
	else if (!reversePatchOption_ && changingFileName)
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"Patches corresponding to the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"selected revisions")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to files specified by the filename template.")];
	}
	else /*if (!reversePatchOption_ && !changingFileName)*/
	{
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"Patches corresponding to the ")];
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"selected revisions")];
		[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@" will be written to the given filename.")];
	}
	return newSheetMessage;
}


@end

