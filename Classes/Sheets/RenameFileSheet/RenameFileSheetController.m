//
//  RenameFileSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "RenameFileSheetController.h"
#import "MacHgDocument.h"
#import "FSNodeInfo.h"
#import "TaskExecutions.h"
#import "DisclosureBoxController.h"

@implementation RenameFileSheetController
@synthesize theCurrentNameFieldValue	= theCurrentNameFieldValue_;
@synthesize theNewNameFieldValue		= theNewNameFieldValue_;
@synthesize theAlreadyMovedButtonValue	= theAlreadyMovedButtonValue_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (RenameFileSheetController*) initRenameFileSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"RenameFileSheet" owner:self];
	return self;
}


- (void) awakeFromNib
{
	[errorDisclosureController roundTheBoxCorners];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Validation
// ------------------------------------------------------------------------------------

- (IBAction) validateButtons:(id)sender
{
	BOOL pathsDiffer = [theCurrentNameFieldValue_ isNotEqualToString:theNewNameFieldValue_];
	if (!pathsDiffer)
	{
		[errorMessageTextField setStringValue:@"You must choose a new file name which is different than the current file name."];
		[errorDisclosureController ensureDisclosureBoxIsOpen:YES];
		[theRenameButton setEnabled:NO];
		return;
	}
		
	BOOL pathsDifferOnlyByCase = [theCurrentNameFieldValue_ differsOnlyInCaseFrom:theNewNameFieldValue_];
	if (pathsDifferOnlyByCase)
	{
		[errorMessageTextField setStringValue:@"You cannot rename the current file to a new name which differs only in the case of the name. (The file system used by Macintosh OSX is case insensitive.)"];
		[errorDisclosureController ensureDisclosureBoxIsOpen:YES];
		[theRenameButton setEnabled:NO];
		return;
	}

	[errorDisclosureController ensureDisclosureBoxIsClosed:YES];
	[theRenameButton setEnabled:YES];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Actions
// ------------------------------------------------------------------------------------

- (IBAction) openRenameFileSheet:(id)sender
{

	NSArray* theSelectedFiles = [myDocument absolutePathsOfChosenFiles];

	if ([theSelectedFiles count] < 1)
	{
		PlayBeep();
		NSRunAlertPanel(@"No File Selected", @"You need to select a file to rename", @"OK", nil, nil);
		return;
	}
	
	if (![theSelectedFiles count] > 1)
	{
		PlayBeep();
		NSRunAlertPanel(@"Too Many Files Selected", @"You need to select just a single file to rename", @"OK", nil, nil);
		return;
	}
	
	NSString* filePath = [theSelectedFiles lastObject];
	
	FSNodeInfo* theNode = [myDocument nodeForPath:filePath];
	BOOL itemIsDirectory = [theNode isDirectory];
	if (itemIsDirectory)
	{
		PlayBeep();
		NSString* subMessage = fstr(@"“%@” is a directory. Renaming the directory will effectively rename evey file in the directory. Do you want to continue?", [filePath lastPathComponent]);
		int result = NSRunCriticalAlertPanel(@"Directory Rename", subMessage, @"Cancel", @"Rename", nil);
		if (result != NSAlertAlternateReturn)
			return;
	}

	if (!bitsInCommon([theNode hgStatus],eHGStatusInRepository))
	{
		PlayBeep();
		NSString* subMessage = fstr(@"“%@” is not managed by Mercurial. You can rename or relocate the file in the finder without incident.", [filePath lastPathComponent]);
		NSRunAlertPanel(@"File Not Under Management", subMessage, @"OK", nil, nil);
		return;
	}
	
	[renameSheetTitle setStringValue:itemIsDirectory ? @"Rename Directory" : @"Rename File"];
	[mainMessageTextField setStringValue:itemIsDirectory ?
		@"Please enter a new directory name. (Renaming the directory in Mercurial allows Mercurial to track the history of the files in the directory across name changes." :
		@"Please enter a new file name. (Renaming the file in Mercurial allows Mercurial to track the history of the file across name changes."];

	[errorDisclosureController setToOpenState:NO withAnimation:NO];
	
	NSString* newPath = [filePath stringByDeletingLastPathComponent];
	NSString* newName = fstr(@"Renamed%@", [filePath lastPathComponent]);
	NSString* newPathName = [newPath stringByAppendingPathComponent:newName];
	NSNumber* newButtonState =[NSNumber numberWithBool:bitsInCommon([theNode hgStatus],eHGStatusMissing)];

	[self setTheCurrentNameFieldValue:filePath];
	[self setTheNewNameFieldValue:newPathName];	
	[theRenameFileSheet resizeSoContentsFitInFields:theCurrentNameField, theNewNameField, nil];
	[self setTheAlreadyMovedButtonValue:newButtonState];
	[self validateButtons:self];
	[myDocument beginSheet:theRenameFileSheet];
}


- (IBAction) sheetButtonRename:(id)sender
{
	if (DisplayWarningForRenamingFilesFromDefaults())
	{
		NSString* subMessage = fstr(@"Are you sure you want to rename “%@” to “%@”?", [theCurrentNameFieldValue_ lastPathComponent], [theNewNameFieldValue_ lastPathComponent]);
		int result = RunCriticalAlertPanelWithSuppression(@"Renaming Selected File", subMessage, @"Rename", @"Cancel", MHGDisplayWarningForRenamingFiles);
		if (result != NSAlertFirstButtonReturn)
			return;
	}
	[theRenameFileSheet makeFirstResponder:theRenameFileSheet];	// Make the text fields of the sheet commit any changes they currently have

	[myDocument removeAllUndoActionsForDocument];
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];

	[myDocument dispatchToMercurialQueuedWithDescription:@"Renaming Files" process:^{
		NSArray* paths = @[theCurrentNameFieldValue_, theNewNameFieldValue_];
		[myDocument registerPendingRefresh:paths];
		NSMutableArray* argsRename = [NSMutableArray arrayWithObjects:@"rename", nil];
		if ([theAlreadyMovedButtonValue_ boolValue])
			[argsRename addObject:@"--after"];
		[argsRename addObject:theCurrentNameFieldValue_ followedBy:theNewNameFieldValue_];

		[myDocument delayEventsUntilFinishBlock:^{
			[TaskExecutions executeMercurialWithArgs:argsRename  fromRoot:rootPath];
			[myDocument addToChangedPathsDuringSuspension:paths];
		}];		
	}];

	[myDocument endSheet:theRenameFileSheet];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[myDocument endSheet:theRenameFileSheet];
}

- (IBAction) browseToPath: (id)sender
{
	NSString* filename = getSingleFilePathFromOpenPanel();
	if (filename)
		[self setTheNewNameFieldValue:filename];
}




// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// ------------------------------------------------------------------------------------

- (void) controlTextDidChange:(NSNotification*)aNotification
{
	[self validateButtons:[aNotification object]];
}


@end
