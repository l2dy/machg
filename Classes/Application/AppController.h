//
//  AppController.h
//  MacHg
//
//  Created by Jason Harris on 26/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "Common.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: AppController
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface AppController : NSObject <NSApplicationDelegate>
{
	BOOL applicationHasStarted;
	InitializationWizardController* theInitilizationWizardController_;

	IBOutlet WebView*			creditsWebview;
	
	TaskExecutions*				theTaskExecutions;						// We have this reference to ensure garbage collection doesn't collect this.
	NSMutableDictionary*		repositoryIdentityForPath_;				// This dictionary contains the collection of root changesets for a given path.
																		// Ie for /Users/jason/Development/MyProject the value might be 2e7ba9cebde9
	NSMutableDictionary*		dirtyRepositoryIdentityForPath_;		// This dictionary contains the paths of repositories where we need to recompute
																		// the root changesets
	NSMutableDictionary*		computingRepositoryIdentityForPath_;	// This dictionary contains the paths of the repositories we are
																		// currently computing the changesets of.
	NSTimer*					periodicCheckingForRepositoryIdentity;
}

+ (AppController*)				sharedAppController;
- (InitializationWizardController*) theInitilizationWizardController;


// Initialization
- (void)	  applicationDidFinishLaunching:(NSNotification*)aNotification;
- (void)	  checkConfigFileForEditingExtensions:(BOOL)onStartup;


// Preferences
+ (void)	  initializePreferenceDefaults;
- (IBAction)  resetPreferences: (id)sender;
- (IBAction)  showPreferences:(id)sender;


// About Box
- (IBAction)  showAboutBox:(id)sender;
- (void)	  webView:(WebView*)webView decidePolicyForNavigationAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request frame:(WebFrame*)frame decisionListener:(id < WebPolicyDecisionListener >)listener;

// Version Utilities
- (NSString*) shortVersionString;
- (NSString*) shortVersionNumberString;
- (NSString*) macHgBuildHashKeyString;
- (NSString*) mercurialVersionString;
- (NSAttributedString*) fullVersionString;


// Help Menus
- (IBAction)  openQuickStartPage:(id)sender;
- (IBAction)  openBugReportPage:(id)sender;
- (IBAction)  openRelaseNotes:(id)sender;


// Changeset handling
- (NSString*) repositoryIdentityForPath:(NSString*)path;
- (void)	  setRepositoryIdentity:(NSString*)changeset ForPath:(NSString*)path;
- (void)	  checkRepositoryIdentities:(NSTimer*)theTimer;
- (void)	  computeRepositoryIdentityForPath:(NSString*)path;	// recompute the root changeset for a given path


@end






