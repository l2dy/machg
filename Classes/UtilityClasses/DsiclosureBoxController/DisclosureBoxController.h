//
//  DisclosureBoxController.h
//  MacHg
//
//  Created by Jason Harris on 22/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>

// This disclosure controller controls nicely sliding out a box or hiding a box. Eg when we want to show / hide advanced options
// we put them all in a box and link it to the disclosure box. The parentWindow grows by the size of the disclosure box when it is
// shown and shrinks by the size of the disclosure box when it is hidden.

@interface DisclosureBoxController : NSObject
{
	IBOutlet NSWindow*			parentWindow;
	IBOutlet NSButton*			disclosureButton;
	IBOutlet NSBox*				disclosureBox;
}

- (IBAction) disclosureTrianglePressed:(id)sender;
- (IBAction) ensureDisclosureBoxIsOpen:(id)sender;
- (IBAction) ensureDisclosureBoxIsClosed:(id)sender;

- (void) setToOpenState:(BOOL)state;
- (void) syncronizeDisclosureBoxToButtonStateWithAnimation:(BOOL)animate;

@end
