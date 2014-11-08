//  PushSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "PushSheetController.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "ResultsWindowController.h"
#import "Sidebar.h"
#import "SidebarNode.h"
#import "DisclosureBoxController.h"
#import "OptionController.h"
#import "AppController.h"
#import "ProcessListController.h"





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: PushSheetController
// ------------------------------------------------------------------------------------

@implementation PushSheetController





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (PushSheetController*) initPushSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"PushSheet"];
	[self window];	// force / ensure the nib is loaded
	return self;
}

- (void) awakeFromNib
{
	[self observe:kReceivedCompatibleRepositoryCount byCalling:@selector(updateIncomingOutgoingCount)];
	[forceOption setSpecialHandling:YES];
	[forceOption		setName:@"force"];
	[bookmarkOption		setName:@"bookmark"];
	[branchOption		setName:@"branch"];
	[insecureOption		setName:@"insecure"];
	[remotecmdOption	setName:@"remotecmd"];
	[revOption			setName:@"rev"];
	[sshOption			setName:@"ssh"];
	cmdOptions = @[forceOption, bookmarkOption, branchOption, insecureOption, remotecmdOption, revOption, sshOption];
}

- (void) dealloc	{ [self stopObserving]; }





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors
// ------------------------------------------------------------------------------------

- (SidebarNode*)		sourceRepository		{ return [myDocument_ selectedRepositoryRepositoryRef]; }
- (SidebarNode*)		destinationRepository	{ return [[compatibleRepositoriesPopup selectedItem] representedObject]; }
- (NSString*)			operationName			{ return @"Push"; }
- (OptionController*)	commonRevOption			{ return revOption; }




// ------------------------------------------------------------------------------------
//  Actions   ------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------


- (void)	 clearSheetFieldValues { }
- (IBAction) validateButtons:(id)sender { }
- (void)	 controlTextDidChange:(NSNotification*)aNotification { [self validateButtons:[aNotification object]]; }





// ------------------------------------------------------------------------------------
//  Actions ConfigureExistingPush   --------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------


- (IBAction) openSheet:(id)sender
{
	[titleText setStringValue:fstr(@"Push from “%@”", self.sourceRepositoryName)];
	[super openSheet:sender];
}


- (IBAction) sheetButtonPush:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:sheetWindow];

	SidebarNode* pushDestination  = self.destinationRepository;
	SidebarNode* pushSource       = self.sourceRepository;
	NSString* pushSourceName      = [pushSource shortName];
	NSString* pushDestinationName = [pushDestination shortName];
	
	// Display warning if prefs say we should
	if (DisplayWarningForPushingFromDefaults())
	{
		NSString* mainMessage = fstr(@"Pushing %@", pushSourceName);
		NSString* subMessage  = fstr( @"Are you sure you want to push the repository “%@” into “%@”?", pushSourceName, pushDestinationName);
		int result = RunCriticalAlertPanelWithSuppression(mainMessage, subMessage, @"Push", @"Cancel", MHGDisplayWarningForPushing);
		if (result != NSAlertFirstButtonReturn)
			return;
	}
	
	// Construct the push args
	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];
	NSMutableArray* argsPush = [NSMutableArray arrayWithObjects:@"push", @"--noninteractive", nil];
	[argsPush addObjectsFromArray:configurationForProgress];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsPush];
	if (self.allowOperationWithAnyRepository || [forceOption optionIsSet])
			[argsPush addObject:@"--force"];
	if (!RequireVerifiedServerCertificatesFromDefaults())
		[argsPush addObject:@"--insecure"];
	[argsPush addObject:[pushDestination fullURLPath]];
	
	// Execute the push command
	ProcessController* processController = [ProcessController processControllerWithMessage:@"Pushing Changesets" forList:[myDocument_ theProcessListController]];
	dispatch_async([myDocument_ mercurialTaskSerialQueue], ^{
		ExecutionResult* results = [myDocument_ executeMercurialWithArgs:argsPush  fromRoot:rootPath  withDelegate:processController  whileDelayingEvents:YES];
		[processController terminateController];
		[myDocument_ postNotificationWithName:kCompatibleRepositoryChanged];
		if (DisplayResultsOfPushingFromDefaults())
		{
			NSString* messageString = fstr(@"Results of Pushing “%@” into “%@”", pushSourceName, pushDestinationName);
			NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
			[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:fstr(@"Push Results - %@", pushSourceName) onScreen:[sheetWindow screen]];
		}
		if ([pushDestination isVirginRepository])
			[[AppController sharedAppController] computeRepositoryIdentityForPath:[pushDestination path]];
	});
	
	// Cache the connection parameters
	[self setConnectionFromFieldsForSource:pushSource andDestination:pushDestination];
	[pushSource setRecentPushConnection:[pushDestination path]];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:sheetWindow];
	[self setConnectionFromFieldsForSource:self.sourceRepository andDestination:self.destinationRepository];
}

@end









