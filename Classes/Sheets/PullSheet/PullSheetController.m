//  PullSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "PullSheetController.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "ResultsWindowController.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "DisclosureBoxController.h"
#import "OptionController.h"
#import "ProcessListController.h"





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: PullSheetController
// ------------------------------------------------------------------------------------

@implementation PullSheetController




// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (PullSheetController*) initPullSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"PullSheet"];
	[self window];	// force / ensure the nib is loaded
	return self;
}

- (void) awakeFromNib
{
	[self observe:kReceivedCompatibleRepositoryCount byCalling:@selector(updateIncomingOutgoingCount)];
	forceOption.specialHandling = YES;
	[forceOption		setName:@"force"];
	[bookmarkOption		setName:@"bookmark"];
	[branchOption		setName:@"branch"];
	[insecureOption		setName:@"insecure"];	
	[rebaseOption		setName:@"rebase"];
	[remotecmdOption	setName:@"remotecmd"];
	[revOption			setName:@"rev"];
	[sshOption			setName:@"ssh"];
	[updateOption		setName:@"update"];
	cmdOptions = @[forceOption, bookmarkOption, branchOption, insecureOption, rebaseOption, remotecmdOption, revOption, sshOption, updateOption];
}

- (void) dealloc	{ [self stopObserving]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors
// ------------------------------------------------------------------------------------

- (SidebarNode*)		sourceRepository		{ return compatibleRepositoriesPopup.selectedItem.representedObject; }
- (SidebarNode*)		destinationRepository	{ return myDocument_.selectedRepositoryRepositoryRef; }
- (NSString*)			operationName			{ return @"Pull"; }
- (OptionController*)	commonRevOption			{ return revOption; }



// ------------------------------------------------------------------------------------
//  Actions   ------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

- (void)	 clearSheetFieldValues { }
- (IBAction) validateButtons:(id)sender { }
- (void)	 controlTextDidChange:(NSNotification*)aNotification { [self validateButtons:aNotification.object]; }





// ------------------------------------------------------------------------------------
//  Actions ConfigureExistingPull   --------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

- (IBAction) openSheet:(id)sender
{
	titleText.stringValue = fstr(@"Pull to ???%@???", self.destinationRepositoryName);
	[super openSheet:sender];
}


- (IBAction) sheetButtonPull:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:sheetWindow];
	
	SidebarNode* pullDestination  = self.destinationRepository;
	SidebarNode* pullSource       = self.sourceRepository;
	NSString* pullSourceName      = pullSource.shortName;
	NSString* pullDestinationName = pullDestination.shortName;

	// Display warning if prefs say we should
	if (DisplayWarningForPullingFromDefaults())
	{
		NSString* mainMessage = fstr(@"Pulling %@", pullSourceName);
		NSString* subMessage  = fstr( @"Are you sure you want to pull the repository ???%@??? into ???%@????", pullSourceName, pullDestinationName);
		int result = RunCriticalAlertPanelWithSuppression(mainMessage, subMessage, @"Pull", @"Cancel", MHGDisplayWarningForPulling);
		if (result != NSAlertFirstButtonReturn)
			return;
	}
	
	// Construct the pull args
	NSString* rootPath = myDocument_.absolutePathOfRepositoryRoot;
	NSMutableArray* argsPull = [NSMutableArray arrayWithObjects:@"pull", @"--noninteractive", nil];
	[argsPull addObjectsFromArray:configurationForProgress];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsPull];
	if (self.allowOperationWithAnyRepository || forceOption.optionIsSet)
		[argsPull addObject:@"--force"];
	if (!RequireVerifiedServerCertificatesFromDefaults())
		[argsPull addObject:@"--insecure"];
	[argsPull addObject:pullSource.fullURLPath];
	
	// Execute the pull command
	ProcessController* processController = [ProcessController processControllerWithMessage:@"Pulling Changesets" forList:myDocument_.theProcessListController];
	dispatch_async(myDocument_.mercurialTaskSerialQueue, ^{
		ExecutionResult* results = [myDocument_ executeMercurialWithArgs:argsPull  fromRoot:rootPath  withDelegate:processController  whileDelayingEvents:YES];
		[processController terminateController];
		if (DisplayResultsOfPullingFromDefaults())
		{
			NSString* messageString = fstr(@"Results of Pulling ???%@??? into ???%@???", pullSourceName, pullDestinationName);
			NSString* mainMessage = [results.outStr stringByReplacingOccurrencesOfString:@"(run 'hg heads' to see heads, 'hg merge' to merge)" withString:@""];
			NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(mainMessage);
			[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:fstr(@"Pull Results - %@", pullDestinationName) onScreen:sheetWindow.screen];
		}
	});
	
	// Cache the connection parameters
	[self setConnectionFromFieldsForSource:pullSource andDestination:pullDestination];
	pullDestination.recentPullConnection = pullSource.path;
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:sheetWindow];
	[self setConnectionFromFieldsForSource:self.sourceRepository andDestination:self.destinationRepository];
}

@end









