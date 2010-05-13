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

@implementation ConnectionValidationController

- (id) init
{
	self = [super init];
    if (self)
	{
		queueForConnectionValidation_ = [SingleTimedQueue SingleTimedQueueExecutingOn:globalQueue()  withTimeDelay:1.5  descriptiveName:@"queueForConnectionValidation"];
		goodNetworkImage_ = [NSImage imageNamed:@"GoodNetwork.png"];
		badNetworkImage_  = [NSImage imageNamed:@"BadNetwork.png"];
    }
    return self;
}

- (void) hideValidationGraphicAndMessage
{
	[repositoryConnectionStatusImage		setHidden:YES];
	[repositoryConnectionStatusMessage		setHidden:YES];
}


- (void) showBadValidationGraphicAndMessage
{
	[repositoryConnectionStatusImage	setImage:badNetworkImage_];
	[repositoryConnectionStatusImage	setHidden:NO];
	[repositoryConnectionStatusMessage	setStringValue:@"Remote Repository is Unreachable"];
	[repositoryConnectionStatusMessage	setHidden:NO];
	[repositoryConnectionStatusMessage	setNeedsDisplay:YES];
}

- (void) showGoodValidationGraphicAndMessage
{
	[repositoryConnectionStatusImage	setImage:goodNetworkImage_];
	[repositoryConnectionStatusImage	setHidden:NO];
	[repositoryConnectionStatusMessage	setStringValue:@"Remote Repository is Reachable"];
	[repositoryConnectionStatusMessage	setHidden:NO];
	[repositoryConnectionStatusMessage	setNeedsDisplay:YES];
}

- (void) showValidationProgressIndicator
{
	[validationProgressIndicator setHidden:NO];
	[validationProgressIndicator startAnimation:self];
}

- (void) hideValidationProgressIndicator
{
	[validationProgressIndicator setHidden:YES];
	[validationProgressIndicator stopAnimation:self];
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
	if (IsNotEmpty([serverTextField stringValue]))
	{
		NSInteger validationAttempt = [queueForConnectionValidation_ operationNumber] + 1;	// Once we add the next block operation, the operationNumber will be
																							// incremented so + 1 will give the operationNumber we are just about to get...
		[queueForConnectionValidation_ addBlockOperation:^{
			dispatchWithTimeOutBlock(globalQueue(), 20.0,
									 
									 // Main Block
									 ^{
										 [self showValidationProgressIndicator];
										 NSMutableArray* argsIdentify = [NSMutableArray arrayWithObjects:@"identify", @"--rev", @"0", [serverTextField stringValue], nil];
										 ExecutionResult* results = [TaskExecutions executeMercurialWithArgs:argsIdentify  fromRoot:@"/tmp"  logging:eLogAllToFile];
										 
										// If our results are still relevant show the success or failure result
										 if ([queueForConnectionValidation_ operationNumber] == validationAttempt)
										 {
											 [self hideValidationProgressIndicator];
											 if (IsNotEmpty(results.outStr) && [results.outStr length] >= 12 && IsEmpty(results.errStr) && (results.result == 0 ))
												 [self showGoodValidationGraphicAndMessage];
											 else
												 [self showBadValidationGraphicAndMessage];
										 }
									 },
									 
									 // Time-out Block
									 ^{
										 // If our results are still relevant but we timed out show failure result
										 if ([queueForConnectionValidation_ operationNumber] == validationAttempt)
										 {
											 [self hideValidationProgressIndicator];
											 [self showBadValidationGraphicAndMessage];
										 }
									 }
									 );
		}];
	}
	
}



@end
