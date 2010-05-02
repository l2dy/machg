//
//  RenameFileSheetController.m
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "RenameFileSheetController.h"
#import "MacHgDocument.h"
#import "FSNodeInfo.h"
#import "TaskExecutions.h"

@implementation RenameFileSheetController
@synthesize theCurrentNameFieldValue	= theCurrentNameFieldValue_;
@synthesize theNewNameFieldValue		= theNewNameFieldValue_;
@synthesize theAlreadyMovedButtonValue	= theAlreadyMovedButtonValue_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (RenameFileSheetController*) initRenameFileSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"RenameFileSheet" owner:self];
	return self;
}


- (IBAction) browseToPath: (id)sender
{
	NSString* filename = getSingleFilePathFromOpenPanel();
	if (filename)
		[self setTheNewNameFieldValue:filename];
}


- (IBAction) openRenameFileSheet:(id)sender
{

	NSArray* theSelectedFiles = [myDocument absolutePathsOfBrowserChosenFiles];

	if ([theSelectedFiles count] < 1)
	{
		PlayBeep();
		NSRunAlertPanel(@"No File Selected", @"You need to select a file to rename", @"Ok", nil, nil);
		return;
	}
	
	if (![theSelectedFiles count] > 1)
	{
		PlayBeep();
		NSRunAlertPanel(@"Too Many Files Selected", @"You need to select just a single file to rename", @"Ok", nil, nil);
		return;
	}
	
	NSString* filePath = [theSelectedFiles lastObject];
	
	FSNodeInfo* theNode = [myDocument nodeForPath:filePath];
	if ([theNode isDirectory])
	{
		PlayBeep();
		NSString* subMessage = [NSString stringWithFormat:@"“%@” is a directory. Mercurial only permits renaming files", [filePath lastPathComponent]];
		NSRunAlertPanel(@"Rename Not Allowed", subMessage, @"Ok", nil, nil);
		return;
	}

	if (!bitsInCommon([theNode hgStatus],eHGStatusInRepository))
	{
		PlayBeep();
		NSString* subMessage = [NSString stringWithFormat:@"“%@” is not managed by Mercurial. You can rename or relocate the file in the finder without incident.", [filePath lastPathComponent]];
		NSRunAlertPanel(@"File Not Under Management", subMessage, @"Ok", nil, nil);
		return;
	}
	
	
	NSString* newName = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"NewName"];
	NSNumber* newButtonState =[NSNumber numberWithBool:bitsInCommon([theNode hgStatus],eHGStatusMissing)];

	[self setTheCurrentNameFieldValue:filePath];
	[self setTheNewNameFieldValue:newName];
	[self setTheAlreadyMovedButtonValue:newButtonState];
	[NSApp beginSheet:theRenameFileSheet modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (IBAction) sheetButtonOkForRenameFileSheet:(id)sender
{
	if (DisplayWarningForRenamingFilesFromDefaults())
	{
		NSString* subMessage = [NSString stringWithFormat:@"Are you sure you want to rename “%@” to “%@”?", [theCurrentNameFieldValue_ lastPathComponent], [theNewNameFieldValue_ lastPathComponent]];
		int result = RunCriticalAlertPanelWithSuppression(@"Renaming Selected File", subMessage, @"Rename", @"Cancel", MHGDisplayWarningForRenamingFiles);
		if (result != NSAlertFirstButtonReturn)
			return;
	}
	[theRenameFileSheet makeFirstResponder:theRenameFileSheet];	// Make the text fields of the sheet commit any changes they currently have

	[myDocument removeAllUndoActionsForDocument];
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];

	[myDocument dispatchToMercurialQueuedWithDescription:@"Renaming Files" process:^{
		NSArray* paths = [NSArray arrayWithObjects:theCurrentNameFieldValue_, theNewNameFieldValue_,nil];
		[myDocument registerPendingRefresh:paths];
		NSMutableArray* argsRename = [NSMutableArray arrayWithObjects:@"rename", nil];
		if ([theAlreadyMovedButtonValue_ boolValue])
			[argsRename addObject:@"--after"];
		[argsRename addObject:theCurrentNameFieldValue_ followedBy:theNewNameFieldValue_];
		[myDocument executeMercurialWithArgs:argsRename  fromRoot:rootPath  whileDelayingEvents:YES];
	}];

	[NSApp endSheet:theRenameFileSheet];
	[theRenameFileSheet orderOut:sender];
}

- (IBAction) sheetButtonCancelForRenameFileSheet:(id)sender
{
	[NSApp endSheet:theRenameFileSheet];
	[theRenameFileSheet orderOut:sender];
}


@end
