//
//  InitilizationWizardController.m
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"
#import "InitializationWizardController.h"

@implementation InitializationWizardController
@synthesize userNameFieldValue = userNameFieldValue_;

- (InitializationWizardController*) initInitializationWizardController
{
	self = [self initWithWindowNibName:@"InitializationWizard"];
	[self window];	// force / ensure the nib is loaded
	return self;
}

- (void) awakeFromNib
{
	// both are needed, otherwise hyperlink won't accept mousedown
    informativeMessage.allowsEditingTextAttributes =  YES;
    informativeMessage.selectable =  YES;
	
    NSURL* url = [NSURL URLWithString:@"http://hgtip.com/tips/beginner/2009-09-30-configuring-mercurial/"];
    NSMutableAttributedString* string = [NSMutableAttributedString string:informativeMessage.stringValue withAttributes:smallSystemFontAttributes];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"more..." withURL:url]];
	informativeMessage.attributedStringValue = string;
	self.userNameFieldValue = @"";
}

- (void) showWizard
{
	[self validateButtons:self];
	[NSApp runModalForWindow:self.window];
}

- (void) closeWizard
{
	[NSApp stopModal];
	[self.window performClose:self];
}



- (IBAction) initializationWizardSheetButtonOk:(id)sender
{
	NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
	NSString* addition = fstr(@"\n[ui]\nusername = %@\n",self.userNameFieldValue);
	[NSFileManager.defaultManager appendString:addition toFilePath:macHgHGRCFilePath];
	
	[self closeWizard];
}

- (IBAction) initializationWizardSheetCancel:(id)sender
{
	[self closeWizard];
}

- (IBAction) validateButtons:(id)sender
{
	BOOL valid = (self.userNameFieldValue.length > 0);
	okButton.enabled = valid;
}





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// ------------------------------------------------------------------------------------

- (void) controlTextDidChange:(NSNotification*)aNotification
{
	[self validateButtons:aNotification.object];
}


@end
