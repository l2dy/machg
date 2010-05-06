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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: OutgoingSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation OutgoingSheetController





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (OutgoingSheetController*) initOutgoingSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"OutgoingSheet" owner:self];
	return self;
}

- (void) awakeFromNib
{
	[self observe:kReceivedCompatibleRepositoryCount byCalling:@selector(updateIncomingOutgoingCount)];
	[forceOption setSpecialHandling:YES];
	[forceOption		setName:@"force"];
	[revOption			setName:@"rev"];
	[newestfirstOption	setName:@"newest-first"];
	[patchOption		setName:@"patch"];
	[gitOption			setName:@"git"];
	[limitOption		setName:@"limit"];
	[nomergesOption		setName:@"no-merges"];
	[styleOption		setName:@"style"];
	[templateOption		setName:@"template"];
	[sshOption			setName:@"ssh"];
	[remotecmdOption	setName:@"remotecmd"];
	[graphOption		setName:@"graph"];
	cmdOptions = [NSArray arrayWithObjects:	forceOption, revOption, newestfirstOption, patchOption, gitOption, limitOption, nomergesOption, styleOption, templateOption, sshOption, remotecmdOption, graphOption, nil];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Accessors
// -----------------------------------------------------------------------------------------------------------------------------------------

- (SidebarNode*) sourceRepository		{ return [myDocument selectedRepositoryRepositoryRef]; }
- (SidebarNode*) destinationRepository	{ return [[compatibleRepositoriesPopup selectedItem] representedObject]; }
- (BOOL)		 sourceOnLeft			{ return YES; }
- (NSString*)    operationName			{ return @"Outgoing"; }





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions   ------------------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------


- (void)	 clearSheetFieldValues { }
- (IBAction) validateButtons:(id)sender { }
- (void)	 controlTextDidChange:(NSNotification*)aNotification { [self validateButtons:[aNotification object]]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions ConfigureExistingOutgoing   --------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openSheet:(id)sender;
{
	[titleText setStringValue:[NSString stringWithFormat:@"Outgoing from “%@”", [self sourceRepositoryName]]];
	[super openSheet:sender];
}


- (IBAction) sheetButtonOkForOutgoingSheet:(id)sender;
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:sender];

	SidebarNode* outgoingDestination  = [self destinationRepository];
	SidebarNode* outgoingSource       = [self sourceRepository];
	NSString* outgoingSourceName      = [outgoingSource shortName];
	NSString* outgoingDestinationName = [outgoingDestination shortName];
	
	// Construct the outgoing args
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* argsOutgoing = [NSMutableArray arrayWithObjects:@"outgoing", nil];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsOutgoing];
	if (allowOperationWithAnyRepository_ || [forceOption optionIsSet])
		[argsOutgoing addObject:@"--force"];
	[argsOutgoing addObject:[outgoingDestination path]];
	
	// Execute the outgoing command
	[myDocument dispatchToMercurialQueuedWithDescription:@"Outgoing Changesets" process:^{
		ExecutionResult results = [myDocument  executeMercurialWithArgs:argsOutgoing  fromRoot:rootPath  whileDelayingEvents:YES];
		NSString* messageString = [NSString stringWithFormat:@"Results of Outgoing “%@” into “%@”", outgoingSourceName, outgoingDestinationName];
		NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
		[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:@"Outgoing Results"];
	}];
	
	// Cache the connection parameters
	[self setConnectionFromFieldsForSource:outgoingSource andDestination:outgoingDestination];
	[outgoingDestination addRecentConnection:outgoingSource];
}

- (IBAction) sheetButtonCancelForOutgoingSheet:(id)sender;
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:sender];
	[self setConnectionFromFieldsForSource:[self sourceRepository] andDestination:[self destinationRepository]];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Archive / Restore connections
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setConnectionFromFieldsForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* partialKey = [NSString stringWithFormat:@"Outgoing§%@§%@§", [source path], [destination path]];
	[OptionController setConnections:[myDocument connections] fromOptions:cmdOptions  forKey:partialKey];
}

- (void) setFieldsFromConnectionForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination
{
	NSString* partialKey = [NSString stringWithFormat:@"Outgoing§%@§%@§", [source path], [destination path]];
	[OptionController setOptions:cmdOptions fromConnections:[myDocument connections] forKey:partialKey];
}

@end









