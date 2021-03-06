//  MergeSheetController.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "MergeSheetController.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "RepositoryData.h"
#import "ResultsWindowController.h"





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  MergeSheetController
// ------------------------------------------------------------------------------------
// MARK: -

@interface MergeSheetController (PrivateAPI)
- (NSAttributedString*) normalFormattedSheetMessage;
- (NSAttributedString*) ancestorFormattedSheetMessage;
@end


@implementation MergeSheetController

@synthesize forceTheMerge = forceTheMerge_;
@synthesize myDocument = myDocument_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (MergeSheetController*) initMergeSheetControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithWindowNibName:@"MergeSheet"];
	[self window];	// force / ensure the nib is loaded
	return self;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (void) clearSheetFieldValues
{
	[self validateButtons:self];
}





// ------------------------------------------------------------------------------------
//  Validation   ---------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------


- (IBAction) validateButtons:(id)sender
{
	NSString* theSelectedRevision = numberAsString(logTableView.selectedRevision);
	NSString* theParentRevision   = numberAsString([[myDocument_ repositoryData]getHGParent1Revision]);
	BOOL canMerge = YES;
	
	NSAttributedString* message = nil;
	
	if (!theSelectedRevision || [theSelectedRevision isEqualToString:theParentRevision])
	{
		message  = normalSheetMessageAttributedString(@"");
		canMerge = NO;
	}
	
	if (!message)
	{
		NSString* rootPath = myDocument_.absolutePathOfRepositoryRoot;
		NSMutableArray* argsDebugAncestor = [NSMutableArray arrayWithObjects:@"debugancestor", theSelectedRevision, theParentRevision, nil];
		ExecutionResult* results = [myDocument_ executeMercurialWithArgs:argsDebugAncestor fromRoot:rootPath whileDelayingEvents:YES];
		if (results.outStr)
		{
			NSString* ancestor = trimString([results.outStr stringByMatching:@"(\\d+):[\\d\\w]+\\s*" capture:1L]);
			if ([ancestor isEqualToString:theParentRevision] || [ancestor isEqualToString:theSelectedRevision])
			{
				message = self.ancestorFormattedSheetMessage;
				canMerge = NO;
			}
		}
	}

	if (!message)
	{
		message = self.normalFormattedSheetMessage;
		canMerge = YES;
	}
	
	dispatch_async(mainQueue(), ^{
		sheetButtonOkForMergeSheet.enabled = canMerge;
		sheetInformativeMessageTextField.attributedStringValue =  message;
	});
}





// ------------------------------------------------------------------------------------
//  Actions Merge   ------------------------------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------


- (void) openMergeSheetWithRevision:(NSNumber*)revision
{
	[self openMergeSheet:self];
	[logTableView selectAndScrollToRevision:revision];
	[logTableView scrollToRevision:revision];
}


- (IBAction) openMergeSheet:(id)sender
{
	[myDocument_ beginSheet:mergeSheetWindow];
	[self validateButtons:self];
	[logTableView resetTable:self];
}


- (IBAction) sheetButtonOk:(id)sender
{
	[mergeSheetWindow makeFirstResponder:mergeSheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:mergeSheetWindow];
	NSNumber* theSelectedRevision = logTableView.selectedRevision;
	NSArray* theOptions = self.forceTheMerge ? @[@"--force"] : nil;
	[myDocument_ primaryActionMergeWithVersion:theSelectedRevision andOptions:theOptions withConfirmation:NO];
}


- (IBAction) sheetButtonCancel:(id)sender
{
	[mergeSheetWindow makeFirstResponder:mergeSheetWindow]; // Make the text fields of the sheet commit any changes they currently have
	[myDocument_ endSheet:mergeSheetWindow];
}


- (IBAction) sheetButtonViewDifferencesForMergeSheet:(id)sender
{
	NSArray* rootPathAsArray = myDocument_.absolutePathOfRepositoryRootAsArray;
	NSNumber* versionToMergeWith = logTableView.selectedRevision;
	[myDocument_ viewDifferencesInCurrentRevisionFor:rootPathAsArray toRevision:numberAsString(versionToMergeWith)];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Table Delegate Methods
// ------------------------------------------------------------------------------------

- (void) logTableViewSelectionDidChange:(LogTableView*)theLogTable
{
	[self validateButtons:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Create Sheet Message
// ------------------------------------------------------------------------------------

- (NSAttributedString*) normalFormattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	NSNumber* parent1Revision = myDocument_.getHGParent1Revision;
	if (!parent1Revision)
	{
		[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(@"No parent revision.")];
		return newSheetMessage;
	}
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@"The revision selected above (")];
	NSNumber* rev = logTableView.selectedRevision;
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(rev ? numberAsString(rev) : @"-")];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@") will be merged into the current revision (")];
	[newSheetMessage appendAttributedString: emphasizedSheetMessageAttributedString(myDocument_.isCurrentRevisionTip ? @"tip" : numberAsString(parent1Revision))];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(@").")];
	return newSheetMessage;
}


- (NSAttributedString*) ancestorFormattedSheetMessage
{
	NSMutableAttributedString* newSheetMessage = [[NSMutableAttributedString alloc] init];
	[newSheetMessage appendAttributedString: grayedSheetMessageAttributedString(@"Cannot merge (")];
	NSNumber* rev = logTableView.selectedRevision;
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(rev ? numberAsString(rev) : @"-")];
	[newSheetMessage appendAttributedString: grayedSheetMessageAttributedString(@") into the current revision (")];
	[newSheetMessage appendAttributedString: normalSheetMessageAttributedString(myDocument_.isCurrentRevisionTip ? @"tip" : numberAsString(myDocument_.getHGParent1Revision))];
	[newSheetMessage appendAttributedString: grayedSheetMessageAttributedString(@") since one of the revisions is a direct ancestor of the other.")];
	return newSheetMessage;
}


@end









