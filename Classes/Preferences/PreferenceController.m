//
//  PreferenceController.m
//  MacHg
//
//  Created by Jason Harris on 3/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "PreferenceController.h"
#import "Common.h"
#import "AppController.h"

@implementation PreferenceController

- (PreferenceController*) initPreferenceController
{
	[NSBundle loadNibNamed:@"Preferences" owner:self];
	return self;
}


- (BOOL) windowShouldClose
{
//	[[self window] hide
	return NO;
}

- (IBAction) displayPreferencesChanged:(id)sender
{
	[self postNotificationWithName:kBrowserDisplayPreferencesChanged];
}

- (IBAction) resetPreferences:(id)sender
{
	// load the default values for the user defaults
	NSString*	  userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary* userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
	
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:userDefaultsValuesDict];
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];
}


- (IBAction) repositoryEditingPreferencesChanged:(id)sender
{
	[[AppController sharedAppController] checkConfigFileForEditingExtensions:NO];
}

@end
