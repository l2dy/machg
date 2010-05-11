//
//  PreferenceController.h
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"

@interface PreferenceController : DBPrefsWindowController
{
	IBOutlet NSView* generalPreferenceView;
	IBOutlet NSView* appearancePreferenceView;
	IBOutlet NSView* mercurialPreferenceView;
	IBOutlet NSView* messagesPreferenceView;
	IBOutlet NSView* advancedPreferenceView;
	IBOutlet NSView* updatePreferenceView;
}

- (IBAction) displayPreferencesChanged:(id)sender;
+ (IBAction) resetPreferences:(id)sender;
- (IBAction) repositoryEditingPreferencesChanged:(id)sender;

@end
