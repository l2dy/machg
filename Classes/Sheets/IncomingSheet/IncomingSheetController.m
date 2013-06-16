//  IncomingSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "IncomingSheetController.h"
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
// MARK: IncomingSheetController
// ------------------------------------------------------------------------------------

@implementation IncomingSheetController





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (IncomingSheetController*) initIncomingSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"IncomingSheet"];
	[self window];	// force / ensure the nib is loaded
	return self;
}

- (void) awakeFromNib
{
	[self observe:kReceivedCompatibleRepositoryCount byCalling:@selector(updateIncomingOutgoingCount)];
	[forceOption setSpecialHandling:YES];
	[forceOption		setName:@"force"];
	[branchOption		setName:@"branch"];
	[gitOption			setName:@"git"];
	[graphOption		setName:@"graph"];
	[insecureOption		setName:@"insecure"];
	[limitOption		setName:@"limit"];
	[newestfirstOption	setName:@"newest-first"];
	[nomergesOption		setName:@"no-merges"];
	[patchOption		setName:@"patch"];
	[remotecmdOption	setName:@"remotecmd"];
	[revOption			setName:@"rev"];
	[sshOption			setName:@"ssh"];
	[styleOption		setName:@"style"];
	[templateOption		setName:@"template"];
	cmdOptions = @[forceOption, branchOption, gitOption, graphOption, insecureOption, limitOption, newestfirstOption, nomergesOption, patchOption, remotecmdOption, revOption, sshOption, styleOption, templateOption];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors
// ------------------------------------------------------------------------------------

- (SidebarNode*)		sourceRepository		{ return [[compatibleRepositoriesPopup selectedItem] representedObject]; }
- (SidebarNode*)		destinationRepository	{ return [myDocument_ selectedRepositoryRepositoryRef]; }
- (NSString*)			operationName			{ return @"Incoming"; }
- (OptionController*)	commonRevOption			{ return revOption; }




// ------------------------------------------------------------------------------------
//  Actions   ------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

- (void)	 clearSheetFieldValues { }
- (IBAction) validateButtons:(id)sender { }
- (void)	 controlTextDidChange:(NSNotification*)aNotification { [self validateButtons:[aNotification object]]; }





// ------------------------------------------------------------------------------------
//  Actions ConfigureExistingIncoming   ----------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

- (IBAction) openSheet:(id)sender
{
	[titleText setStringValue:fstr(@"Incoming to “%@”", [self destinationRepositoryName])];
	[super openSheet:sender];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:sheetWindow];
	
	SidebarNode* incomingDestination  = [self destinationRepository];
	SidebarNode* incomingSource       = [self sourceRepository];
	NSString* incomingSourceName      = [incomingSource shortName];
	NSString* incomingDestinationName = [incomingDestination shortName];
	
	// Construct the incoming args
	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];
	NSMutableArray* argsIncoming = [NSMutableArray arrayWithObjects:@"incoming", @"--noninteractive", nil];
	[argsIncoming addObjectsFromArray:configurationForProgress];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsIncoming];
	if (self.allowOperationWithAnyRepository || [forceOption optionIsSet])
		[argsIncoming addObject:@"--force"];
	if (!RequireVerifiedServerCertificatesFromDefaults())
		[argsIncoming addObject:@"--insecure"];
	[argsIncoming addObject:[incomingSource fullURLPath]];
	
	// Execute the incoming command
	ProcessController* processController = [ProcessController processControllerWithMessage:@"Incoming Changesets" forList:[myDocument_ theProcessListController]];
	dispatch_async([myDocument_ mercurialTaskSerialQueue], ^{
		ExecutionResult* results = [myDocument_ executeMercurialWithArgs:argsIncoming  fromRoot:rootPath  withDelegate:processController  whileDelayingEvents:YES];
		[processController terminateController];
		NSString* messageString = fstr(@"Results of Incoming “%@” into “%@”", incomingSourceName, incomingDestinationName);
		NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
		[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:fstr(@"Incoming Results - %@", incomingDestinationName) onScreen:[sheetWindow screen]];
	});
	
	// Cache the connection parameters
	[self setConnectionFromFieldsForSource:incomingSource andDestination:incomingDestination];
	[incomingDestination setRecentPullConnection:[incomingSource path]];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:sheetWindow];
	[self setConnectionFromFieldsForSource:[self sourceRepository] andDestination:[self destinationRepository]];
}

@end









