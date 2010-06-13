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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: IncomingSheetController
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation IncomingSheetController





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IncomingSheetController*) initIncomingSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"IncomingSheet" owner:self];
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

- (SidebarNode*) sourceRepository		{ return [[compatibleRepositoriesPopup selectedItem] representedObject]; }
- (SidebarNode*) destinationRepository	{ return [myDocument selectedRepositoryRepositoryRef]; }
- (BOOL)		 sourceOnLeft			{ return NO; }
- (NSString*)    operationName			{ return @"Incoming"; }



// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions   ------------------------------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void)	 clearSheetFieldValues { }
- (IBAction) validateButtons:(id)sender { }
- (void)	 controlTextDidChange:(NSNotification*)aNotification { [self validateButtons:[aNotification object]]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
//  Actions ConfigureExistingIncoming   --------------------------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openSheet:(id)sender;
{
	[titleText setStringValue:fstr(@"Incoming to “%@”", [self destinationRepositoryName])];
	[super openSheet:sender];
}


- (IBAction) sheetButtonOk:(id)sender;
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:sender];
	
	SidebarNode* incomingDestination  = [self destinationRepository];
	SidebarNode* incomingSource       = [self sourceRepository];
	NSString* incomingSourceName      = [incomingSource shortName];
	NSString* incomingDestinationName = [incomingDestination shortName];
	
	// Construct the incoming args
	NSString* rootPath = [myDocument absolutePathOfRepositoryRoot];
	NSMutableArray* argsIncoming = [NSMutableArray arrayWithObjects:@"incoming", nil];
	for (OptionController* opt in cmdOptions)
		[opt addOptionToArgs:argsIncoming];
	if (allowOperationWithAnyRepository_ || [forceOption optionIsSet])
		[argsIncoming addObject:@"--force"];
	[argsIncoming addObject:[incomingSource fullURLPath]];
	
	// Execute the incoming command
	[myDocument dispatchToMercurialQueuedWithDescription:@"Incoming Changesets" process:^{
		ExecutionResult* results = [myDocument executeMercurialWithArgs:argsIncoming  fromRoot:rootPath  whileDelayingEvents:YES];
		NSString* messageString = fstr(@"Results of Incoming “%@” into “%@”", incomingSourceName, incomingDestinationName);
		NSAttributedString* resultsString = fixedWidthResultsMessageAttributedString(results.outStr);
		[ResultsWindowController createWithMessage:messageString andResults:resultsString andWindowTitle:fstr(@"Incoming Results - %@", incomingDestinationName)];
	}];
	
	// Cache the connection parameters
	[self setConnectionFromFieldsForSource:incomingSource andDestination:incomingDestination];
	[incomingDestination addRecentConnection:incomingSource];
}

- (IBAction) sheetButtonCancel:(id)sender;
{
	[sheetWindow makeFirstResponder:sheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[NSApp endSheet:sheetWindow];
	[sheetWindow orderOut:sender];
	[self setConnectionFromFieldsForSource:[self sourceRepository] andDestination:[self destinationRepository]];
}

@end









