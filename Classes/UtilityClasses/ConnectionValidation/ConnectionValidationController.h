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
	IBOutlet NSTextView*		repositoryConnectionStatusDetails;
	IBOutlet NSProgressIndicator* validationProgressIndicator;
	IBOutlet NSButton*			showConnectionDetailsButton;
	IBOutlet ServerRepositoryRefSheetController* theServerRefController;
	IBOutlet DisclosureBoxController* connectionDetailsDisclosure;

	SingleTimedQueue*			queueForConnectionValidation_;
	NSImage*					goodNetworkImage_;
	NSImage*					badNetworkImage_;
	BOOL						detailsWasOpen_;	// The state of the disclosure just before we hide everything (normally we are
													// about to do a new validation)
}

- (void)	 resetForSheetOpen;
- (IBAction) testConnection:(id)sender;

@end
