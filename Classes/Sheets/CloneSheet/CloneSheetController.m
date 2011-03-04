//
//  CloneSheetController
//  MacHg
//
//  Created by Jason Harris on 1/18/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "CloneSheetController.h"
#import "AttachedWindowController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "DisclosureBoxController.h"
#import "OptionController.h"
#import "AppController.h"

@implementation CloneSheetController

@synthesize shortNameFieldValue   = shortNameFieldValue_;
@synthesize pathFieldValue        = pathFieldValue_;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (CloneSheetController*) initCloneSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"CloneSheet" owner:self];
	return self;
}

- (void) awakeFromNib
{
	[revOption setSpecialHandling:YES];
	[revOption			setName:@"rev"];
	[sshOption			setName:@"ssh"];
	[updaterevOption	setName:@"updaterev"];
	[remotecmdOption	setName:@"remotecmd"];
	[noupdateOption		setName:@"noupdate"];
	[pullOption			setName:@"pull"];
	[uncompressedOption setName:@"uncompressed"];
	cmdOptions = [NSArray arrayWithObjects:revOption, sshOption, updaterevOption, remotecmdOption, noupdateOption, pullOption, uncompressedOption, nil];
	[errorDisclosureController roundTheBoxCorners];
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
	[errorDisclosureController ensureDisclosureBoxIsClosed:NO];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions browseToPath
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) browseToPath:(id)sender
{
	NSString* filename = collapseWhiteSpace([sourceNode_ shortName]);
	NSString* pathName = getSingleDirectoryPathFromOpenPanel();
	if (pathName)
	{
		if (pathIsExistentDirectory(pathName))
			pathName = [pathName stringByAppendingPathComponent:filename];
		[self setPathFieldValue:pathName];
		if ([self shortNameFieldValue] == @"")
			[self setShortNameFieldValue:[pathName lastPathComponent]];
	}
	[self validateButtons:sender];
}

- (IBAction) validateButtons:(id)sender
{
	if ([[self shortNameFieldValue] length] <= 0)
	{
		[errorMessageTextField setStringValue:@"You need to enter a short name of your choosing to refer to the repository."];
		[errorDisclosureController ensureDisclosureBoxIsOpen:YES];
		[okButton setEnabled:NO];
		return;
	}

	if ([[self pathFieldValue] length] <= 0)
	{
		[errorMessageTextField setStringValue:@"You need to choose a local destination to clone the repository to."];
		[errorDisclosureController ensureDisclosureBoxIsOpen:YES];
		[okButton setEnabled:NO];
		return;
	}
	
	BOOL exists1 = repositoryExistsAtPath([self pathFieldValue]);
	if (exists1)
	{
		[errorMessageTextField setStringValue:@"A Mercurial repository already exists at the chosen local destination."];
		[errorDisclosureController ensureDisclosureBoxIsOpen:YES];
		[okButton setEnabled:NO];
		return;
	}
	
	BOOL dir2;
	BOOL exists2 = [[NSFileManager defaultManager] fileExistsAtPath:[self pathFieldValue] isDirectory:&dir2];
	if (exists2)
	{
		[errorMessageTextField setStringValue:fstr(@"A %@ already exists at the chosen local destination.", dir2 ? @"directory" : @"file")];
		[errorDisclosureController ensureDisclosureBoxIsOpen:YES];
		[okButton setEnabled:NO];
		return;
	}

	[errorDisclosureController ensureDisclosureBoxIsClosed:YES];
	[okButton setEnabled:YES];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions AddRepository
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openCloneSheet:(id)sender	{ [self openCloneSheetWithSource:[[myDocument sidebar] selectedNode]]; }

- (void) openCloneSheetWithSource:(SidebarNode*)source
{
	[self clearSheetFieldValues];
	sourceNode_ = source;
	
	NSString* sourcePath   = [sourceNode_ path];
	NSString* sourceName   = [sourceNode_ shortName];
	NSString* clonePath    = [sourceNode_ isLocalRepositoryRef] ? fstr(@"%@Clone", sourcePath) : [DefaultWorkspacePathFromDefaults() stringByAppendingPathComponent:collapseWhiteSpace(sourceName)];
	NSString* cloneName    = [sourceNode_ isLocalRepositoryRef] ? fstr(@"%@Clone", sourceName) : sourceName;
	NSImage* sourceIconImage = [sourceNode_ isLocalRepositoryRef] ? [NSWorkspace iconImageOfSize:[sourceIconWell frame].size forPath:sourcePath] : [NSImage imageNamed:NSImageNameNetwork];
	
	NoAnimationBlock(^{
		[self setShortNameFieldValue:cloneName];
		[self setPathFieldValue:clonePath];
		[sourceIconWell setImage:sourceIconImage];
		[pullSourceLabel setStringValue:sourceName];
		[theTitleText setStringValue:fstr(@"Clone “%@”", sourceName)];
		[self setFieldsFromConnectionForSource:source];
		BOOL showAdvancedOptions = [OptionController containsOptionWhichIsSet:cmdOptions];
		[disclosureController setToOpenState:showAdvancedOptions withAnimation:NO];
		[errorDisclosureController setToOpenState:NO withAnimation:NO];
		[self validateButtons:self];
	});
	
	[NSApp beginSheet:theWindow modalForWindow:[myDocument mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}




- (IBAction) sheetButtonOk:(id)sender;
{
	[theWindow makeFirstResponder:theWindow];	// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theWindow];
	[theWindow orderOut:sender];

	Sidebar* theSidebar = [myDocument sidebar];
	[[theSidebar prepareUndoWithTarget:theSidebar] setRootAndUpdate:[[theSidebar root] copyNodeTree]];
	[[theSidebar undoManager] setActionName: @"Clone Repository"];

	NSString* sourceName  = [sourceNode_ shortName];
	NSString* destinationName  = [shortNameFieldValue_ copy];
	NSString* destinationPath  = [pathFieldValue_ copy];
	NSString* cloneDescription = fstr(@"Cloning “%@”", sourceName);

	NSMutableArray* argsClone = [NSMutableArray arrayWithObjects:@"clone", @"--noninteractive", nil];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsClone];
	if ([revOption optionIsSet])
	{
		NSArray* revs = [[revOption optionValue] componentsSeparatedByRegex:@"\\s+"];
		for (NSString* rev in revs)
			[argsClone addObject:@"--rev" followedBy:rev];
	}
	if (!RequireVerifiedServerCertificatesFromDefaults())
		[argsClone addObject:@"--insecure"];
	[argsClone addObject:[sourceNode_ fullURLPath] followedBy:destinationPath];
	
	[self setConnectionFromFieldsForSource:sourceNode_];		// Cache advanced option settings for this source.

	[myDocument dispatchToMercurialQueuedWithDescription:cloneDescription  process:^{
		ExecutionResult* results = [TaskExecutions  executeMercurialWithArgs:argsClone  fromRoot:@"/tmp"];
		if ([results hasNoErrors])
			dispatch_async(mainQueue(), ^{
				SidebarNode* newNode = [SidebarNode nodeWithCaption:destinationName  forLocalPath:destinationPath];
				[[AppController sharedAppController] computeRepositoryIdentityForPath:destinationPath];
				[[myDocument sidebar] addSidebarNode:newNode afterNode:sourceNode_];
				[[myDocument sidebar] selectNode:newNode];
				[[myDocument sidebar] reloadData];
				[myDocument postNotificationWithName:kRepositoryRootChanged];
				[myDocument refreshBrowserContent:self];
				[myDocument saveDocumentIfNamed];
			});
	}];
	
}

- (IBAction) sheetButtonCancel:(id)sender;
{
	[theWindow makeFirstResponder:theWindow];				// Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:theWindow];
	[theWindow orderOut:sender];
	[self setConnectionFromFieldsForSource:sourceNode_];	// Cache advanced option settings for this source.
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Archive / Restore connections
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setConnectionFromFieldsForSource:(SidebarNode*)source
{
	NSString* partialKey = fstr(@"Clone§%@§", [source path]);
	[OptionController setConnections:[myDocument connections] fromOptions:cmdOptions  forKey:partialKey];
}

- (void) setFieldsFromConnectionForSource:(SidebarNode*)source
{
	NSString* partialKey = fstr(@"Clone§%@§", [source path]);
	[OptionController setOptions:cmdOptions fromConnections:[myDocument connections] forKey:partialKey];
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
