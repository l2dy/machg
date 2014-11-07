//
//  CloneSheetController
//  MacHg
//
//  Created by Jason Harris on 1/18/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "CloneSheetController.h"
#import "ButtonPopoverController.h"
#import "MacHgDocument.h"
#import "TaskExecutions.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "DisclosureBoxController.h"
#import "OptionController.h"
#import "AppController.h"
#import "ProcessListController.h"

@implementation CloneSheetController

@synthesize myDocument          = myDocument_;
@synthesize shortNameFieldValue = shortNameFieldValue_;
@synthesize pathFieldValue      = pathFieldValue_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (CloneSheetController*) initCloneSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"CloneSheet"];
	[self window];	// force / ensure the nib is loaded
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
	cmdOptions = @[revOption, sshOption, updaterevOption, remotecmdOption, noupdateOption, pullOption, uncompressedOption];
	[errorDisclosureController roundTheBoxCorners];
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
	[errorDisclosureController ensureDisclosureBoxIsClosed:NO];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions browseToPath
// ------------------------------------------------------------------------------------

- (IBAction) browseToPath:(id)sender
{
	NSString* filename = collapseWhiteSpace([sourceNode_ shortName]);
	NSString* pathName = getSingleDirectoryPathFromOpenPanel();
	if (pathName)
	{
		if (pathIsExistentDirectory(pathName))
			pathName = [pathName stringByAppendingPathComponent:filename];
		[self setPathFieldValue:pathName];
		if ([[self shortNameFieldValue] isEqualToString:@""])
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
	
	BOOL repoExists = repositoryExistsAtPath([self pathFieldValue]);
	if (repoExists)
	{
		[errorMessageTextField setStringValue:@"A Mercurial repository already exists at the chosen local destination."];
		[errorDisclosureController ensureDisclosureBoxIsOpen:YES];
		[okButton setEnabled:NO];
		return;
	}
	
	BOOL dir;
	BOOL pathExists = [[NSFileManager defaultManager] fileExistsAtPath:[self pathFieldValue] isDirectory:&dir];
	BOOL fileExists = pathExists && !dir;
	BOOL dirExists  = pathExists && dir;
    if (dirExists) 
    {
        NSArray* fileInfo = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self pathFieldValue] error:NULL];
        if (IsEmpty(fileInfo))
			dirExists = NO;
        
        //SG: This can be removed if core mecurial allows cloning into essentially empty directories (ie containing only .DS_Store).
        if (dirExists && [fileInfo count] == 1 && [[fileInfo firstObject] isEqualToString:@".DS_Store"]) 
            dirExists = ![[NSFileManager defaultManager] removeItemAtPath:[[self pathFieldValue] stringByAppendingPathComponent:@".DS_Store"] error:NULL];
    }
	if (fileExists || dirExists)
	{
		[errorMessageTextField setStringValue:fstr(@"A %@ already exists at the chosen local destination.", dirExists ? @"directory" : @"file")];
		[errorDisclosureController ensureDisclosureBoxIsOpen:YES];
		[okButton setEnabled:NO];
		return;
	}

	[errorDisclosureController ensureDisclosureBoxIsClosed:YES];
	[okButton setEnabled:YES];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Actions AddRepository
// ------------------------------------------------------------------------------------

- (IBAction) openCloneSheet:(id)sender	{ [self openCloneSheetWithSource:[[myDocument_ sidebar] selectedNode]]; }

- (void) openCloneSheetWithSource:(SidebarNode*)source
{
	[self clearSheetFieldValues];
	sourceNode_ = source;
	
	NSString* sourcePath   = [sourceNode_ path];
	NSString* sourceName   = [sourceNode_ shortName];
	NSString* cloneNameSuffix = @"Clone";
	if ([sourceNode_ isLocalRepositoryRef])
	{
		if (pathIsExistent(fstr(@"%@%@", sourcePath, cloneNameSuffix)))
		{
			int i = 1;
			while (pathIsExistent(fstr(@"%@%@%d", sourcePath, cloneNameSuffix,i)))
				i++;
			cloneNameSuffix = fstr(@"%@%d", cloneNameSuffix, i);
		}
	}
	NSString* clonePath    = [sourceNode_ isLocalRepositoryRef] ? fstr(@"%@%@", sourcePath, cloneNameSuffix) : [DefaultWorkspacePathFromDefaults() stringByAppendingPathComponent:collapseWhiteSpace(sourceName)];
	NSString* cloneName    = [sourceNode_ isLocalRepositoryRef] ? fstr(@"%@%@", sourceName, cloneNameSuffix) : sourceName;
	NSImage* sourceIconImage = [sourceNode_ isLocalRepositoryRef] ? [NSWorkspace iconImageOfSize:[sourceIconWell frame].size forPath:sourcePath] : [NSImage imageNamed:NSImageNameNetwork];
	
	NoAnimationBlock(^{
		[self setShortNameFieldValue:cloneName];
		[self setPathFieldValue:clonePath];
		[sourceIconWell setImage:sourceIconImage];
		[cloneSourceLabel setStringValue:sourceName];
		[theTitleText setStringValue:fstr(@"Clone “%@”", sourceName)];
		[self setFieldsFromConnectionForSource:source];
		BOOL showAdvancedOptions = [OptionController containsOptionWhichIsSet:cmdOptions];
		[disclosureController setToOpenState:showAdvancedOptions withAnimation:NO];
		[errorDisclosureController setToOpenState:NO withAnimation:NO];
		[self validateButtons:self];
	});
	
	[myDocument_ beginSheet:theCloneSheet];
}




- (IBAction) sheetButtonOk:(id)sender
{
	[theCloneSheet makeFirstResponder:theCloneSheet];	// Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:theCloneSheet];

	Sidebar* theSidebar = [myDocument_ sidebar];
	[[theSidebar prepareUndoWithTarget:theSidebar] setRootAndUpdate:[[theSidebar root] copyNodeTree]];
	[[theSidebar undoManager] setActionName: @"Clone Repository"];

	NSString* sourceName  = [sourceNode_ shortName];
	NSString* destinationName  = [shortNameFieldValue_ copy];
	NSString* destinationPath  = [pathFieldValue_ copy];
	NSString* cloneDescription = fstr(@"Cloning “%@”", sourceName);

	NSMutableArray* argsClone = [NSMutableArray arrayWithObjects:@"clone", @"--noninteractive", nil];
	[argsClone addObjectsFromArray:configurationForProgress];
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

	ProcessController* processController = [ProcessController processControllerWithMessage:cloneDescription forList:[myDocument_ theProcessListController]];
	dispatch_async([myDocument_ mercurialTaskSerialQueue], ^{
		ExecutionResult* results = [TaskExecutions  executeMercurialWithArgs:argsClone  fromRoot:@"/tmp"  logging:eLogAllIssueErrors  withDelegate:processController];
		if ([results hasNoErrors])
			dispatch_async(mainQueue(), ^{
				SidebarNode* newNode = [SidebarNode nodeWithCaption:destinationName  forLocalPath:destinationPath];
				[[AppController sharedAppController] computeRepositoryIdentityForPath:destinationPath];
				[[AppController sharedAppController] computeRepositoryIdentityForPath:destinationPath forNodePath:[sourceNode_ path]];
				[[myDocument_ sidebar] addSidebarNode:newNode afterNode:sourceNode_];
				[[myDocument_ sidebar] selectNode:newNode];
				[[myDocument_ sidebar] reloadData];
				[myDocument_ postNotificationWithName:kRepositoryRootChanged];
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:MHGShowCleanFilesInBrowser];	// Show all files after we have cloned
				[myDocument_ refreshBrowserContent:self];
				[myDocument_ saveDocumentIfNamed];
			});
		[processController terminateController];
	});
	
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[theCloneSheet makeFirstResponder:theCloneSheet];				// Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:theCloneSheet];
	[self setConnectionFromFieldsForSource:sourceNode_];	// Cache advanced option settings for this source.
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Archive / Restore connections
// ------------------------------------------------------------------------------------

- (void) setConnectionFromFieldsForSource:(SidebarNode*)source
{
	NSString* partialKey = fstr(@"Clone§%@§", [source path]);
	[OptionController setConnections:[myDocument_ connections] fromOptions:cmdOptions  forKey:partialKey];
}

- (void) setFieldsFromConnectionForSource:(SidebarNode*)source
{
	NSString* partialKey = fstr(@"Clone§%@§", [source path]);
	[OptionController setOptions:cmdOptions fromConnections:[myDocument_ connections] forKey:partialKey];
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
