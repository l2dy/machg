//
//  InitializationWizardController.h
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface InitializationWizardController : NSWindowController
{
	IBOutlet NSTextField* userNameField;
	IBOutlet NSTextField* informativeMessage;
	IBOutlet NSButton*	  okButton;
	
	NSString*			  userNameFieldValue_;
}
@property (readwrite,assign) NSString*	  userNameFieldValue;

- (InitializationWizardController*) initInitializationWizardController;

- (IBAction) initializationWizardSheetButtonOk:(id)sender;
- (IBAction) initializationWizardSheetCancel:(id)sender;
- (IBAction) validateButtons:(id)sender;

- (void)	 showWizard;
- (void)	 closeWizard;


// Delegate Methods for text fields
- (void)	 controlTextDidChange:(NSNotification*)aNotification;

@end
