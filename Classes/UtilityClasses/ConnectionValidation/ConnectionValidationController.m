//
//  ConnectionValidationController.m
//  MacHg
//
//  Created by Jason Harris on 22/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ConnectionValidationController.h"
#import "TaskExecutions.h"
#import "MacHgDocument.h"
#import "SingleTimedQueue.h"
#import "ServerRepositoryRefSheetController.h"
#import "DisclosureBoxController.h"
#import "AppController.h"

NSAttributedString*   titledAttributedString(NSString* string);
NSAttributedString*   fixedWidthAttributedString(NSString* string);

@implementation ConnectionValidationController


// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Initialization
// ------------------------------------------------------------------------------------

- (id) init
{
	self = [super init];
    if (self)
	{
		queueForConnectionValidation_ = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue()  withTimeDelay:1.5  descriptiveName:@"queueForConnectionValidation"];
		goodNetworkImage_ = [NSImage imageNamed:@"GoodNetwork.png"];
		badNetworkImage_  = [NSImage imageNamed:@"BadNetwork.png"];
		goodDetailsImage_ = [NSImage imageNamed:@"toolbar_resolved.png"];
		badDetailsImage_  = [NSImage imageNamed:@"AlertPreferences.png"];
    }
    return self;
}


- (void) awakeFromNib
{
	[connectionDetailsDisclosure roundTheBoxCorners];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Showing and Hiding
// ------------------------------------------------------------------------------------

- (void) hideValidationGraphicAndMessage
{
	if (!showConnectionDetailsButton.isHidden)
		detailsWasOpen_ = connectionDetailsDisclosure.disclosureIsVisible;
	[repositoryConnectionStatusImage	setHidden:YES];
	[repositoryDetailsStatusImage		setHidden:YES];
	[showConnectionDetailsButton		setHidden:YES];
	[connectionDetailsDisclosure		ensureDisclosureBoxIsClosed:YES];
}

- (void) showBadValidationGraphicAndMessage
{
	[repositoryConnectionStatusImage	setImage:badNetworkImage_];
	[repositoryDetailsStatusImage		setImage:badDetailsImage_];
	[repositoryConnectionStatusImage	setHidden:NO];
	[repositoryDetailsStatusImage		setHidden:NO];
	[showConnectionDetailsButton		setHidden:NO];
	[connectionDetailsDisclosure		setBackgroundToBad];
	[connectionDetailsDisclosure		setToOpenState:detailsWasOpen_ withAnimation:YES];
}

- (void) showGoodValidationGraphicAndMessage
{
	[repositoryConnectionStatusImage	setImage:goodNetworkImage_];
	[repositoryDetailsStatusImage		setImage:goodDetailsImage_];
	[repositoryConnectionStatusImage	setHidden:NO];
	[repositoryDetailsStatusImage		setHidden:NO];
	[showConnectionDetailsButton		setHidden:NO];
	[connectionDetailsDisclosure		setBackgroundToGood];
	[connectionDetailsDisclosure		setToOpenState:detailsWasOpen_ withAnimation:YES];
}

- (void) showValidationProgressIndicator
{
	validationProgressIndicator.hidden = NO;
	[validationProgressIndicator startAnimation:self];
}

- (void) hideValidationProgressIndicator
{
	validationProgressIndicator.hidden = YES;
	[validationProgressIndicator stopAnimation:self];
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK:  Interface Methods
// ------------------------------------------------------------------------------------

- (void) resetForSheetOpen
{
	[self hideValidationGraphicAndMessage];
	[self hideValidationProgressIndicator];
	detailsWasOpen_ = NO;
}


- (IBAction) testConnection:(id)sender
{
	[self hideValidationGraphicAndMessage];
	[self hideValidationProgressIndicator];
	
	// So if the serverTextField is not empty, after 1.5 seconds we start validation. (If before 1.5 seconds another validation
	// request comes along we don't do the validation but reset the timer and start waiting again for 1.5's to do the validation.)
	// Once we are validating we try to validate during 20 seconds, upon doing the validation if our results are still relevant
	// (ie another verification hasn't yet been requested) then we put up the success / fail of the validation. If we timed out
	// and again our results are still relevant then we put up the failure of the validation.
	if (IsNotEmpty(theServerRefController.baseServerURLFieldValue))
	{
		NSInteger validationAttempt = queueForConnectionValidation_.operationNumber + 1;	// Once we add the next block operation, the operationNumber will be
																							// incremented so + 1 will give the operationNumber we are just about to get...
		ConnectionValidationController* __weak weakSelf = self;
		ServerRepositoryRefSheetController* __weak weakServerRefController = theServerRefController;
		SingleTimedQueue* __weak queueForConnectionValidation = queueForConnectionValidation_;
		NSTextView* __unsafe_unretained	weakRepositoryConnectionStatusDetails = repositoryConnectionStatusDetails;


		[queueForConnectionValidation_ addBlockOperation:^{
			PasswordVisibilityType visibilityInDisclosure = weakServerRefController.showRealPassword ? eAllPasswordsAreVisible : eKeyChainPasswordsAreMangled;
			NSString* fullServerURL      = [weakServerRefController generateFullServerURLIncludingPassword:YES andMaskingPassword:NO];
			NSString* visibleServerURL   = [weakServerRefController generateFullServerURLIncludingPassword:YES andMaskingPassword:visibilityInDisclosure != eAllPasswordsAreVisible];
			if (IsEmpty(fullServerURL) || IsEmpty(visibleServerURL))
				return;
			dispatchWithTimeOutBlock(globalQueue(), 20.0,
									 
									 // Main Block
									 ^{
										 [weakSelf showValidationProgressIndicator];
										 NSMutableArray* argsIdentify = [NSMutableArray arrayWithObjects:@"identify", @"--insecure", @"--noninteractive", @"--rev", @"tip", fullServerURL, nil];
										 ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsIdentify  fromRoot:@"/tmp"  logging:eLogAllToFile];
										 
										// If our results are still relevant show the success or failure result
										 if (queueForConnectionValidation.operationNumber == validationAttempt)
										 {
											 NSString* visibleCommand = fstr(@"chg identify --insecure --noninteractive --rev tip %@", visibleServerURL);
											 NSMutableAttributedString* resultsStr = [[NSMutableAttributedString alloc]init];

											 [resultsStr appendAttributedString: titledAttributedString(@"Command:\n")];
											 [resultsStr appendAttributedString: fixedWidthAttributedString(fstr(@"%@\n", visibleCommand))];
											 if (IsNotEmpty(results.outStr))
											 {
												 [resultsStr appendAttributedString: titledAttributedString(@"\nOutput:\n")];
												 [resultsStr appendAttributedString: fixedWidthAttributedString(fstr(@"%@", trimString(results.outStr)))];
											 }
											 if (IsNotEmpty(results.errStr))
											 {
												 [resultsStr appendAttributedString: titledAttributedString(@"\nErrors:\n")];
												 [resultsStr appendAttributedString: fixedWidthAttributedString(fstr(@"%@", trimString(results.errStr)))];
											 }
											 											 
											 dispatch_async(mainQueue(), ^{
												 [weakRepositoryConnectionStatusDetails.textStorage setAttributedString:resultsStr];
											 
												 [weakSelf hideValidationProgressIndicator];
												 if (IsNotEmpty(results.outStr) && results.outStr.length >= 12 && results.isClean)
													 [weakSelf showGoodValidationGraphicAndMessage];
												 else
													 [weakSelf showBadValidationGraphicAndMessage];
											 });
										 }
									 },
									 
									 // Time-out Block
									 ^{
										 // If our results are still relevant but we timed out show failure result
										 if (queueForConnectionValidation.operationNumber == validationAttempt)
										 {
											 NSString* visibleCommand = fstr(@"chg identify --insecure --noninteractive --rev tip %@", visibleServerURL);
											 NSMutableAttributedString* resultsStr = [[NSMutableAttributedString alloc]init];
											 
											 [resultsStr appendAttributedString: titledAttributedString(@"Command:\n")];
											 [resultsStr appendAttributedString: fixedWidthAttributedString(fstr(@"%@\n", visibleCommand))];
											 
											 [resultsStr appendAttributedString: titledAttributedString(@"\nOutput:\n")];
											 [resultsStr appendAttributedString: fixedWidthAttributedString(@"Operation timed out after 20 seconds.")];
											 
											 dispatch_async(mainQueue(), ^{
												 [weakRepositoryConnectionStatusDetails.textStorage setAttributedString:resultsStr];

												 [weakSelf hideValidationProgressIndicator];
												 [weakSelf showBadValidationGraphicAndMessage];
											 });
										 }
									 }
			);
		}];
	}
	
}



@end

NSAttributedString*   titledAttributedString(NSString* string)		{ return [NSAttributedString string:string withAttributes:graySystemFontAttributes]; }
NSAttributedString*   fixedWidthAttributedString(NSString* string)	{ return [NSAttributedString string:string withAttributes:smallFixedWidthUserFontAttributes]; }

