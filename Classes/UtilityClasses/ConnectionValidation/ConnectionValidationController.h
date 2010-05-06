//
//  ConnectionValidationController.h
//  MacHg
//
//  Created by Jason Harris on 22/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

// This class is used to test a connection and see if it has a reachable and compatible repository
@interface ConnectionValidationController : NSObject
{
	IBOutlet NSImageView*		repositoryConnectionStatusImage;
	IBOutlet NSTextField*		repositoryConnectionStatusMessage;
	IBOutlet NSTextField*		serverTextField;
	IBOutlet NSProgressIndicator* validationProgressIndicator;

	IBOutlet id <AccessesDocument> parentController;

	SingleTimedQueue*			queueForConnectionValidation_;
	NSImage*					goodNetworkImage_;
	NSImage*					badNetworkImage_;
}

- (IBAction) testConnection:(id)sender;

@end
