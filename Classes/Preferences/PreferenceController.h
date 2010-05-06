//
//  PreferenceController.h
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>


@interface PreferenceController : NSWindowController
{
}

- (PreferenceController*) initPreferenceController;
- (BOOL)	 windowShouldClose;

- (IBAction) displayPreferencesChanged:(id)sender;
- (IBAction) resetPreferences:(id)sender;
- (IBAction) repositoryEditingPreferencesChanged:(id)sender;

@end
