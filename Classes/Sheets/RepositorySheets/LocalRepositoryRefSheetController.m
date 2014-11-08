//
//  LocalRepositoryRefSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "LocalRepositoryRefSheetController.h"
#import "ServerRepositoryRefSheetController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "AppController.h"


@implementation LocalRepositoryRefSheetController
@synthesize myDocument			= myDocument_;
@synthesize shortNameFieldValue = shortNameFieldValue_;
@synthesize pathFieldValue      = pathFieldValue_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (LocalRepositoryRefSheetController*) initLocalRepositoryRefSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"LocalRepositoryRefSheet"];
	[self window];	// force / ensure the nib is loaded
	return self;
}


// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Local Methods
// ------------------------------------------------------------------------------------

- (void) clearSheetFieldValues
{
	[self setShortNameFieldValue:@""];
	[self setPathFieldValue:@""];
	[self validateButtons:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: validateButtons
// ------------------------------------------------------------------------------------

- (IBAction) validateButtons:(id)sender
{
	BOOL repositoryExists = repositoryExistsAtPath(pathFieldValue_);
	BOOL directoryExists = repositoryExists || pathIsExistentDirectory(pathFieldValue_);
	if (directoryExists && [[theLocalRepositoryRefSheet firstResponder] hasAncestor:pathField])
		if (IsEmpty(shortNameFieldValue_) || [[pathFieldValue_ pathComponents] containsObject:shortNameFieldValue_])
			[self setShortNameFieldValue:[pathFieldValue_ lastPathComponent]];
	
	BOOL valid = ([self.pathFieldValue length] > 0) && ([self.shortNameFieldValue length] > 0);
	[okButton setEnabled:valid];
	[repositoryPathBox setHidden:!repositoryExists];
	[okButton setTitle:(repositoryExists ? @"Manage Repository" : @"Create Repository")];
	[theTitleText setStringValue:(repositoryExists ? @"Manage Repository" : @"Create Repository")];
}




// ------------------------------------------------------------------------------------
//  Actions browseToPath   -----------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

- (IBAction) browseToPath: (id)sender
{
	NSString* filename = getSingleDirectoryPathFromOpenPanel();
	if (filename)
	{
		[self setPathFieldValue:filename];
		if ([self.shortNameFieldValue isEqualToString: @""])
			[self setShortNameFieldValue:[filename lastPathComponent]];
	}
	[self validateButtons:sender];
}



// ------------------------------------------------------------------------------------
//  Actions AddRepository   --------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

- (void) openSheetForNewRepositoryRef
{
	SidebarNode* node = [[myDocument_ sidebar] chosenNode];
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
	[myDocument_ beginSheet:theLocalRepositoryRefSheet];
}


- (void) openSheetForConfigureRepositoryRef:(SidebarNode*)node
{
	// If the user has chosen the wrong type of configuration do the correct thing.
	if ([node isServerRepositoryRef])
	{
		[[myDocument_ theServerRepositoryRefSheetController] openSheetForConfigureRepositoryRef:node];
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
	[myDocument_ beginSheet:theLocalRepositoryRefSheet];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[theLocalRepositoryRefSheet makeFirstResponder:theLocalRepositoryRefSheet];	// Make the text fields of the sheet commit any changes they currently have

	Sidebar* theSidebar = [myDocument_ sidebar];
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
			ExecutionResult* initResults = [myDocument_  executeMercurialWithArgs:argsInit  fromRoot:@"/" whileDelayingEvents:YES];
			if ([initResults hasErrors] || [initResults hasWarnings])
				[NSException raise:@"Initialize Repository" format:@"Mercurial could not initialize a repository at %@", newPath, nil];

			NSFileManager* fileManager = [NSFileManager defaultManager];
			NSString* hgignorePath = [newPath stringByAppendingPathComponent:@".hgignore"];
			NSData* dataToWrite = [[DefaultHGIgnoreContentsFromDefaults() stringByAppendingString:@"\n"] dataUsingEncoding:NSMacOSRomanStringEncoding];
			BOOL created = [fileManager createFileAtPath:hgignorePath contents:dataToWrite attributes:nil];
			if (!created)
				[NSException raise:@"Initialize Repository" format:@"MacHg could not create .hgignore file at %@ while initializing the repository.", hgignorePath, nil];
				
			NSMutableArray* argsCommit = [NSMutableArray arrayWithObjects:@"commit", @"--addremove", @".hgignore", @"--message", @"initialize repository", nil];
			ExecutionResult* commitResults = [myDocument_  executeMercurialWithArgs:argsCommit  fromRoot:newPath  whileDelayingEvents:YES];
			if ([commitResults hasErrors])
				[NSException raise:@"Initialize Repository" format:@"Mercurial could not commit %@ while initializing the repository.", hgignorePath, nil];
		}
		
		if (nodeToConfigure)
		{
			[theSidebar removeConnectionsFor:[nodeToConfigure path]];
			[nodeToConfigure setPath:newPath];
			[nodeToConfigure setShortName:newName];
			[[myDocument_ sidebar] selectNode:nodeToConfigure];
			[nodeToConfigure refreshNodeIcon];
		}
		else
		{
			SidebarNode* newNode = [SidebarNode nodeWithCaption:newName  forLocalPath:newPath];
			[[myDocument_ sidebar] emmbedAnyNestedRepositoriesForPath:newPath atNode:newNode];
			NSArray* newServers  = [[myDocument_ sidebar] serversIfAvailable:newPath includingAlreadyPresent:NO];
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
						[[myDocument_ sidebar] addSidebarNode:newServer];
				[[myDocument_ sidebar] addSidebarNode:newNode];
			}
			[[myDocument_ sidebar] reloadData];
			[[myDocument_ sidebar] selectNode:newNode];
		}

		[myDocument_ postNotificationWithName:kRepositoryRootChanged];
	}
	@catch (NSException* e)
	{
		if ([[e name] isEqualTo:@"Initialize Repository"])
			RunAlertPanel(@"Initialize Repository", [e reason], @"OK", nil, nil);
		else
			[e raise];
	}
	@finally
	{
		[NSApp endSheet:theLocalRepositoryRefSheet];
		[theLocalRepositoryRefSheet orderOut:sender];
		[[myDocument_ sidebar] reloadData];
		[myDocument_ saveDocumentIfNamed];
		[myDocument_ postNotificationWithName:kSidebarSelectionDidChange];
		[myDocument_ postNotificationWithName:kUnderlyingRepositoryChanged]; 	// Check that we still need to post this notification. The command
																				// should like cause a refresh in any case.
		[myDocument_ refreshBrowserContent:self];
	}

}

- (IBAction) sheetButtonCancel:(id)sender
{
	[theLocalRepositoryRefSheet makeFirstResponder:theLocalRepositoryRefSheet];	// Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:theLocalRepositoryRefSheet];
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




@implementation PathTextField

- (void) awakeFromNib
{
	[super awakeFromNib];
	NSMutableArray* dragTypes = [NSMutableArray arrayWithArray:self.registeredDraggedTypes];
	[dragTypes addObject:NSFilenamesPboardType];
	[self registerForDraggedTypes:dragTypes];
}

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal  { return NSDragOperationMove; }


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)info
{
	[self.window makeFirstResponder:self];
	NSPasteboard*  pasteboard  = [info draggingPasteboard];
	NSString* availableType = [pasteboard availableTypeFromArray:@[NSFilenamesPboardType, NSURLPboardType, NSStringPboardType, NSMultipleTextSelectionPboardType, NSRTFPboardType]];
	if (availableType)
	{
		[self.window makeFirstResponder:self];
		return NSDragOperationCopy;
	}
	return NSDragOperationNone;
}

@end
