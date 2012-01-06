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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PreferenceController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation PreferenceController

- (void)setupToolbar
{	
	[self addView:generalPreferenceView		label:@"General"	imageName:@"NSPreferencesGeneral"];
	[self addView:appearancePreferenceView	label:@"Appearance" imageName:@"AppearancePreferences"];
	[self addView:mercurialPreferenceView	label:@"Mercurial"	imageName:@"MercurialPreferences"];
	[self addView:messagesPreferenceView	label:@"Messages"	imageName:@"AlertPreferences"];
	[self addView:advancedPreferenceView	label:@"Advanced"	imageName:@"NSAdvanced"];
	[self addView:updatePreferenceView		label:@"Updates"	imageName:@"UpdatePreferences"];
	
	// Optional configuration settings.
	[self setCrossFade:[[NSUserDefaults standardUserDefaults] boolForKey:@"PreferencesFadeSwitch"]];
	[self setShiftSlowsAnimation:[[NSUserDefaults standardUserDefaults] boolForKey:@"PreferencesShiftSlowsAnimation"]];
}

- (IBAction) displayPreferencesChanged:(id)sender			{ [self postNotificationWithName:kBrowserDisplayPreferencesChanged]; }
- (IBAction) differencesDisplayPreferencesChanged:(id)sender{ [self postNotificationWithName:kDifferencesDisplayPreferencesChanged]; }
- (IBAction) resetPreferences:(id)sender					{ [AppController resetUserPreferences]; }
- (IBAction) repositoryEditingPreferencesChanged:(id)sender	{ ; }
- (IBAction) openMacHgHGRCFileInExternalEditor:(id)sender	{ [[NSWorkspace sharedWorkspace] openFile:fstr(@"%@/hgrc", applicationSupportFolder())]; }
- (IBAction) openHomeHGRCFileInExternalEditor:(id)sender	{ [[NSWorkspace sharedWorkspace] openFile:[NSHomeDirectory() stringByAppendingPathComponent:@".hgrc"]]; }
@end


@implementation UseWhichDiffToolToHideFieldTransformer
+ (Class) transformedValueClass			{ return [NSNumber class]; }
+ (BOOL)  allowsReverseTransformation	{ return NO; }
- (id)	  transformedValue:(id)value	{ return [value intValue] != eUseOtherForDiffs ? YESasNumber : NOasNumber; }
@end

@implementation UseWhichMergeToolToHideFieldTransformer
+ (Class) transformedValueClass			{ return [NSNumber class]; }
+ (BOOL)  allowsReverseTransformation	{ return NO; }
- (id)	  transformedValue:(id)value	{ return [value intValue] != eUseOtherForMerges ? YESasNumber : NOasNumber; }
@end