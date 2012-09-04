//  OutgoingSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "OutgoingSheetController.h"
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
// MARK: OutgoingSheetController
// ------------------------------------------------------------------------------------
// MARK: -

@implementation OutgoingSheetController





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (OutgoingSheetController*) initOutgoingSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	[NSBundle loadNibNamed:@"OutgoingSheet" owner:self];
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

- (SidebarNode*)		sourceRepository		{ return [myDocument_ selectedRepositoryRepositoryRef]; }
- (SidebarNode*)		destinationRepository	{ return [[compatibleRepositoriesPopup selectedItem] representedObject]; }
- (NSString*)			operationName			{ return @"Outgoing"; }
- (OptionController*)	commonRevOption			{ return revOption; }





// ------------------------------------------------------------------------------------
//  Actions   ------------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------


- (void)	 clearSheetFieldValues { }
- (IBAction) validateButtons:(id)sender { }
- (void)	 controlTextDidChange:(NSNotification*)aNotification { [self validateButtons:[aNotification object]]; }





// ------------------------------------------------------------------------------------
//  Actions ConfigureExistingOutgoing   --------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

- (IBAction) openSheet:(id)sender
{
	[titleText setStringValue:fstr(@"Outgoing from “%@”", [self sourceRepositoryName])];
	[super openSheet:sender];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:sheetWindow];

	SidebarNode* outgoingDestination  = [self destinationRepository];
	SidebarNode* outgoingSource       = [self sourceRepository];
	NSString* outgoingSourceName      = [outgoingSource shortName];
	NSString* outgoingDestinationName = [outgoingDestination shortName];
	
	// Construct the outgoing args
	NSString* rootPath = [myDocument_ absolutePathOfRepositoryRoot];
	NSMutableArray* argsOutgoing = [NSMutableArray arrayWithObjects:@"outgoing", @"--noninteractive", nil];
	[argsOutgoing addObjectsFromArray:configurationForProgress];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsOutgoing];
	if (self.allowOperationWithAnyRepository || [forceOption optionIsSet])
		[argsOutgoing addObject:@"--force"];
	if (!RequireVerifiedServerCertificatesFromDefaults())
		[argsOutgoing addObject:@"--insecure"];
	[argsOutgoing addObject:[outgoingDestination fullURLPath]];
	
	// Execute the outgoing command
	ProcessController* processController = [ProcessController processControllerWithMessage:@"Outgoing Changesets" forList:[myDocument_ theProcessListController]];
	dispatch_async([myDocument_ mercurialTaskSerialQueue], ^{
		ExecutionResult* results = [myDocument_ executeMercurialWithArgs:argsOutgoing  fromRoot:rootPath  withDelegate:processController  whileDelayingEvents:YES];
		[processController terminateController];
		NSString* messageString = fstr(@"Results of Outgoing “%@” into “%@”", outgoingSourceName, outgoingDestinationName);
		NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
		[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:fstr(@"Outgoing Results - %@", outgoingSourceName) onScreen:[sheetWindow screen]];
	});
	
	// Cache the connection parameters
	[self setConnectionFromFieldsForSource:outgoingSource andDestination:outgoingDestination];
	[outgoingDestination setRecentPushConnection:[outgoingSource path]];
}

- (IBAction) sheetButtonCancel:(id)sender
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:sheetWindow];
	[self setConnectionFromFieldsForSource:[self sourceRepository] andDestination:[self destinationRepository]];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Archive / Restore connections
// ------------------------------------------------------------------------------------

- (void) setConnectionFromFieldsForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* partialKey = fstr(@"Outgoing§%@§%@§", [source path], [destination path]);
	[OptionController setConnections:[myDocument_ connections] fromOptions:cmdOptions  forKey:partialKey];
}

- (void) setFieldsFromConnectionForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* partialKey = fstr(@"Outgoing§%@§%@§", [source path], [destination path]);
	[OptionController setOptions:cmdOptions fromConnections:[myDocument_ connections] forKey:partialKey];
}

@end









