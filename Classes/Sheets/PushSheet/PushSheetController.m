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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: PushSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation PushSheetController





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (PushSheetController*) initPushSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"PushSheet" owner:self];
	return self;
}

- (void) awakeFromNib
{
	[self observe:kReceivedCompatibleRepositoryCount byCalling:@selector(updateIncomingOutgoingCount)];
	[forceOption setSpecialHandling:YES];
	[forceOption		setName:@"force"];
	[revOption			setName:@"rev"];
	[sshOption			setName:@"ssh"];
	[remotecmdOption	setName:@"remotecmd"];
	cmdOptions = [NSArray arrayWithObjects:forceOption, revOption, sshOption, remotecmdOption, nil];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (SidebarNode*)		sourceRepository		{ return [myDocument selectedRepositoryRepositoryRef]; }
- (SidebarNode*)		destinationRepository	{ return [[compatibleRepositoriesPopup selectedItem] representedObject]; }
- (NSString*)			operationName			{ return @"Push"; }
- (OptionController*)	commonRevOption			{ return revOption; }




// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions   ------------------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------


- (void)	 clearSheetFieldValues { }
- (IBAction) validateButtons:(id)sender { }
- (void)	 controlTextDidChange:(NSNotification*)aNotification { [self validateButtons:[aNotification object]]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions ConfigureExistingPush   --------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------


- (IBAction) openSheet:(id)sender
{
	[titleText setStringValue:fstr(@"Push from “%@”", [self sourceRepositoryName])];
	[super openSheet:sender];
}


- (IBAction) sheetButtonPush:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:sender];

	SidebarNode* pushDestination  = [self destinationRepository];
	SidebarNode* pushSource       = [self sourceRepository];
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
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* argsPush = [NSMutableArray arrayWithObjects:@"push", @"--noninteractive", nil];
	[argsPush addObjectsFromArray:configurationForProgress];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsPush];
	if (allowOperationWithAnyRepository_ || [forceOption optionIsSet])
			[argsPush addObject:@"--force"];
	if (!RequireVerifiedServerCertificatesFromDefaults())
		[argsPush addObject:@"--insecure"];
	[argsPush addObject:[pushDestination fullURLPath]];
	
	// Execute the push command
	ProcessController* processController = [ProcessController processControllerWithMessage:@"Pushing Changesets" forList:[myDocument theProcessListController]];
	dispatch_async([myDocument mercurialTaskSerialQueue], ^{
		ExecutionResult* results = [myDocument executeMercurialWithArgs:argsPush  fromRoot:rootPath  withDelegate:processController  whileDelayingEvents:YES];
		[processController terminateController];
		[myDocument postNotificationWithName:kCompatibleRepositoryChanged];
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
	[pushDestination setRecentPushConnection:[pushSource path]];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:sender];
	[self setConnectionFromFieldsForSource:[self sourceRepository] andDestination:[self destinationRepository]];
}

@end









