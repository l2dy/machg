//
//  LocalRepositoryRefSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LocalRepositoryRefSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "AppController.h"


@implementation LocalRepositoryRefSheetController
@synthesize shortNameFieldValue = shortNameFieldValue_;
@synthesize pathFieldValue      = pathFieldValue_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (LocalRepositoryRefSheetController*) initLocalRepositoryRefSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"LocalRepositoryRefSheet" owner:self];
	return self;
}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Local Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) clearSheetFieldValues
{
	[self setShortNameFieldValue:@""];
	[self setPathFieldValue:@""];
	[self validateButtons:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) validateButtons:(id)sender
{
	BOOL valid = ([[self pathFieldValue] length] > 0) && ([[self shortNameFieldValue] length] > 0);
	[okButton setEnabled:valid];
	BOOL repositoryExists = repositoryExistsAtPath(pathFieldValue_);
	[repositoryPathBox setHidden:!repositoryExists];
	[okButton setTitle:(repositoryExists ? @"Manage Repository" : @"Create Repository")];
	[theTitleText setStringValue:(repositoryExists ? @"Manage Repository" : @"Create Repository")];
}




// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions browseToPath   -----------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) browseToPath: (id)sender
{
	NSString* filename = getSingleDirectoryPathFromOpenPanel();
	if (filename)
	{
		[self setPathFieldValue:filename];
		if ([self shortNameFieldValue] == @"")
			[self setShortNameFieldValue:[filename lastPathComponent]];
	}
	[self validateButtons:sender];
}



// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions AddRepository   --------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) openSheetForNewRepositoryRef
{
	SidebarNode* node = [[myDocument sidebar] chosenNode];
	if (node)
		[self openSheetForNewRepositoryRefNamed:@"" atPath:@"" addNewRepositoryRefTo:[node parent] atIndex:[[node parent] indexOfChildNode:node]+1];
	else
		[self openSheetForNewRepositoryRefNamed:@"" atPath:@"" addNewRepositoryRefTo:nil atIndex:0];
}

- (void) openSheetForNewRepositoryRefNamed:(NSString*)name atPath:(NSString*)path addNewRepositoryRefTo:(SidebarNode*)parent atIndex:(NSInteger)index
{
	[self clearSheetFieldValues];
	[self setShortNameFieldValue:name];
	[self setPathFieldValue:path];
	nodeToConfigure = nil;
	addNewRepositoryRefTo = parent;
	addNewRepositoryRefAtIndex = index;
	[theTitleText setStringValue:@"Create Repository"];
	[theLocalRepositoryRefSheet resizeSoContentsFitInFields: shortNameField, pathField, nil];
	[self validateButtons:self];
	[NSApp beginSheet:theLocalRepositoryRefSheet modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (void) openSheetForConfigureRepositoryRef:(SidebarNode*)node
{
	// If the user has chosen the wrong type of configuration do the correct thing.
	if ([node isServerRepositoryRef])
	{
		[[myDocument theServerRepositoryRefSheetController] openSheetForConfigureRepositoryRef:node];
		return;
	}
	
	nodeToConfigure = node;
	addNewRepositoryRefTo = nil;
	if ([node isLocalRepositoryRef])
	{
		[self setShortNameFieldValue:[node shortName]];
		[self setPathFieldValue:[node path]];
	}
	else
		[self clearSheetFieldValues];

	[theLocalRepositoryRefSheet resizeSoContentsFitInFields: shortNameField, pathField, nil];
	[self validateButtons:self];
	[NSApp beginSheet:theLocalRepositoryRefSheet modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[theLocalRepositoryRefSheet makeFirstResponder:theLocalRepositoryRefSheet];	// Make the text fields of the sheet commit any changes they currently have

	Sidebar* theSidebar = [myDocument sidebar];
	[[theSidebar prepareUndoWithTarget:theSidebar] setRootAndUpdate:[[theSidebar root] copyNodeTree]];
	[[theSidebar undoManager] setActionName: (nodeToConfigure ? @"Configure Repository" : @"Add Local Repository")];
	
	NSString* newName    = [shortNameFieldValue_ copy];
	NSString* newPath    = [pathFieldValue_ copy];

	@try
	{
		BOOL repositoryExists = repositoryExistsAtPath(newPath);
		if (!repositoryExists)
		{
			NSMutableArray* argsInit = [NSMutableArray arrayWithObjects:@"init", newPath, nil];
			ExecutionResult* initResults = [myDocument  executeMercurialWithArgs:argsInit  fromRoot:@"/" whileDelayingEvents:YES];
			if ([initResults hasErrors] || [initResults hasWarnings])
				[NSException raise:@"Initialize Repository" format:@"Mercurial could not initialize a repository at %@", newPath, nil];

			NSFileManager* fileManager = [NSFileManager defaultManager];
			NSString* hgignorePath = [newPath stringByAppendingPathComponent:@".hgignore"];
			NSData* dataToWrite = [[DefaultHGIgnoreContentsFromDefaults() stringByAppendingString:@"\n"] dataUsingEncoding:NSMacOSRomanStringEncoding];
			BOOL created = [fileManager createFileAtPath:hgignorePath contents:dataToWrite attributes:nil];
			if (!created)
				[NSException raise:@"Initialize Repository" format:@"MacHg could not create .hgignore file at %@ while initializing the repository.", hgignorePath, nil];
				
			NSMutableArray* argsCommit = [NSMutableArray arrayWithObjects:@"commit", @"--addremove", @".hgignore", @"--message", @"initialize repository", nil];
			ExecutionResult* commitResults = [myDocument  executeMercurialWithArgs:argsCommit  fromRoot:newPath  whileDelayingEvents:YES];
			if ([commitResults hasErrors])
				[NSException raise:@"Initialize Repository" format:@"Mercurial could not commit %@ while initializing the repository.", hgignorePath, nil];
		}
		
		if (nodeToConfigure)
		{
			[theSidebar removeConnectionsFor:[nodeToConfigure path]];
			[nodeToConfigure setPath:newPath];
			[nodeToConfigure setShortName:newName];
			[[myDocument sidebar] selectNode:nodeToConfigure];
			[nodeToConfigure refreshNodeIcon];
		}
		else
		{
			SidebarNode* newNode = [SidebarNode nodeWithCaption:newName  forLocalPath:newPath];
			[[myDocument sidebar] emmbedAnyNestedRepositoriesForPath:newPath atNode:newNode];
			NSArray* newServers  = [[myDocument sidebar] serversIfAvailable:newPath includingAlreadyPresent:NO];
			[[AppController sharedAppController] computeRepositoryIdentityForPath:newPath];
			[newNode refreshNodeIcon];
			if (addNewRepositoryRefTo)
			{
				[addNewRepositoryRefTo insertChild:newNode atIndex:addNewRepositoryRefAtIndex];
				if (newServers)
					for (SidebarNode* newServer in newServers)
						[addNewRepositoryRefTo insertChild:newServer atIndex:addNewRepositoryRefAtIndex];
			}
			else
			{
				if (newServers)
					for (SidebarNode* newServer in newServers)
						[[myDocument sidebar] addSidebarNode:newServer];
				[[myDocument sidebar] addSidebarNode:newNode];
			}
			[[myDocument sidebar] reloadData];
			[[myDocument sidebar] selectNode:newNode];
		}

		[myDocument postNotificationWithName:kRepositoryRootChanged];
	}
	@catch (NSException* e)
	{
		if ([[e name] isEqualTo:@"Initialize Repository"])
			NSRunAlertPanel(@"Initialize Repository", [e reason], @"OK", nil, nil);
		else
			[e raise];
	}
	@finally
	{
		[NSApp endSheet:theLocalRepositoryRefSheet];
		[theLocalRepositoryRefSheet orderOut:sender];
		[[myDocument sidebar] reloadData];
		[myDocument saveDocumentIfNamed];
		[myDocument postNotificationWithName:kSidebarSelectionDidChange];
		[myDocument postNotificationWithName:kUnderlyingRepositoryChanged]; 	// Check that we still need to post this notification. The command
																				// should like cause a refresh in any case.
		[myDocument refreshBrowserContent:self];
	}

}

- (IBAction) sheetButtonCancel:(id)sender
{
	[theLocalRepositoryRefSheet makeFirstResponder:theLocalRepositoryRefSheet];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theLocalRepositoryRefSheet];
	[theLocalRepositoryRefSheet orderOut:sender];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) controlTextDidChange:(NSNotification*)aNotification
{
	[self validateButtons:[aNotification object]];
}



@end
