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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: PullSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation PullSheetController





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (PullSheetController*) initPullSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"PullSheet" owner:self];
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
	[updateOption		setName:@"update"];
	cmdOptions = [NSArray arrayWithObjects:revOption, sshOption, remotecmdOption, updateOption, forceOption, nil];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (SidebarNode*) sourceRepository		{ return [[compatibleRepositoriesPopup selectedItem] representedObject]; }
- (SidebarNode*) destinationRepository	{ return [myDocument selectedRepositoryRepositoryRef]; }
- (BOOL)		 sourceOnLeft			{ return NO; }
- (NSString*)	 operationName			{ return @"Pull"; }



// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions   ------------------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void)	 clearSheetFieldValues { }
- (IBAction) validateButtons:(id)sender { }
- (void)	 controlTextDidChange:(NSNotification*)aNotification { [self validateButtons:[aNotification object]]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions ConfigureExistingPull   --------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openSheet:(id)sender;
{
	[titleText setStringValue:fstr(@"Pull to “%@”", [self destinationRepositoryName])];
	[super openSheet:sender];
}


- (IBAction) sheetButtonOk:(id)sender;
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:sender];
	
	SidebarNode* pullDestination  = [self destinationRepository];
	SidebarNode* pullSource       = [self sourceRepository];
	NSString* pullSourceName      = [pullSource shortName];
	NSString* pullDestinationName = [pullDestination shortName];

	// Display warning if prefs say we should
	if (DisplayWarningForPullingFromDefaults())
	{
		NSString* mainMessage = fstr(@"Pulling %@", pullSourceName);
		NSString* subMessage  = fstr( @"Are you sure you want to pull the repository “%@” into “%@”?", pullSourceName, pullDestinationName);
		int result = RunCriticalAlertPanelWithSuppression(mainMessage, subMessage, @"Pull", @"Cancel", MHGDisplayWarningForPulling);
		if (result != NSAlertFirstButtonReturn)
			return;
	}
	
	// Construct the pull args
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* argsPull = [NSMutableArray arrayWithObjects:@"pull", nil];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsPull];
	if (allowOperationWithAnyRepository_ || [forceOption optionIsSet])
		[argsPull addObject:@"--force"];
	[argsPull addObject:[pullSource fullURLPath]];
	
	// Execute the pull command
	[myDocument dispatchToMercurialQueuedWithDescription:@"Pulling Changesets" process:^{
		ExecutionResult* results = [myDocument executeMercurialWithArgs:argsPull  fromRoot:rootPath  whileDelayingEvents:YES];
		if (DisplayResultsOfPullingFromDefaults())
		{
			NSString* messageString = fstr(@"Results of Pulling “%@” into “%@”", pullSourceName, pullDestinationName);
			NSString* mainMessage = [results.outStr stringByReplacingOccurrencesOfString:@"(run 'hg heads' to see heads, 'hg merge' to merge)" withString:@""];
			NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(mainMessage);
			[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:fstr(@"Pull Results - %@", pullDestinationName)];
		}
	}];
	
	// Cache the connection parameters
	[self setConnectionFromFieldsForSource:pullSource andDestination:pullDestination];
	[pullDestination addRecentConnection:pullSource];
}

- (IBAction) sheetButtonCancel:(id)sender;
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:sender];
	[self setConnectionFromFieldsForSource:[self sourceRepository] andDestination:[self destinationRepository]];
}

@end









