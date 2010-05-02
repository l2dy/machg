//
//  InitilizationWizardController.m
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "Common.h"
#import "InitializationWizardController.h"

@implementation InitializationWizardController
@synthesize userNameFieldValue = userNameFieldValue_;

- (InitializationWizardController*) initInitializationWizardController
{
	[NSBundle loadNibNamed:@"InitializationWizard" owner:self];
	return self;
}

- (void) awakeFromNib
{
	// both are needed, otherwise hyperlink won't accept mousedown
    [informativeMessage setAllowsEditingTextAttributes: YES];
    [informativeMessage setSelectable: YES];
	
    NSURL* url = [NSURL URLWithString:@"http://hgtip.com/tips/beginner/2009-09-30-configuring-mercurial/"];
    NSMutableAttributedString* string = [NSMutableAttributedString string:[informativeMessage stringValue] withAttributes:smallSystemFontAttributes];
    [string appendAttributedString: [NSAttributedString hyperlinkFromString:@"more..." withURL:url]];
	[informativeMessage setAttributedStringValue:string];
	[self setUserNameFieldValue:@""];
}

- (void) showWizard
{
	[self validateButtons:self];
	[NSApp runModalForWindow:[self window]];
}

- (void) closeWizard
{
	[NSApp stopModal];
	[[self window] performClose:self];
}



- (IBAction) initializationWizardSheetButtonOk:(id)sender
{
	NSString* dotHGRC = [NSHomeDirectory() stringByAppendingPathComponent:@".hgrc"];
	NSString* addition = [NSString stringWithFormat:@"\n[ui]\nusername = %@\n",[self userNameFieldValue]];
	[[NSFileManager defaultManager] appendString:addition toFilePath:dotHGRC];
	
	[self closeWizard];
}

- (IBAction) initializationWizardSheetCancel:(id)sender
{
	[self closeWizard];
}

- (IBAction) validateButtons:(id)sender
{
	BOOL valid = ([[self userNameFieldValue] length] > 0);
	[okButton setEnabled:valid];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Delegate Methods
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) controlTextDidChange:(NSNotification*)aNotification
{
	[self validateButtons:[aNotification object]];
}


@end
