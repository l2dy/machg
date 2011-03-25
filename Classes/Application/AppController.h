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

	IBOutlet NSWindow*			aboutWindow;
	IBOutlet WebView*			creditsWebview;
	IBOutlet RadialGradiantBox*	backingBox;
	
	NSMutableDictionary*		repositoryIdentityForPath_;				// This dictionary contains the collection of root changesets for a given path.
																		// Ie for /Users/jason/Development/MyProject the value might be 2e7ba9cebde9
	NSMutableDictionary*		dirtyRepositoryIdentityForPath_;		// This dictionary contains the paths of repositories where we need to recompute
																		// the root changesets
	NSMutableDictionary*		computingRepositoryIdentityForPath_;	// This dictionary contains the paths of the repositories we are
																		// currently computing the changesets of.
	NSTimer*					periodicCheckingForRepositoryIdentity;
}

@property (readwrite, assign) NSMutableDictionary* repositoryIdentityForPath;


+ (AppController*)				sharedAppController;
- (InitializationWizardController*) theInitilizationWizardController;

// Initialization
- (void)	  applicationDidFinishLaunching:(NSNotification*)aNotification;
- (void)	  checkConfigFileForExtensions:(BOOL)onStartup;


// Preferences
+ (void)	  initializePreferenceDefaults;
+ (void)	  resetUserPreferences;
- (IBAction)  resetPreferences: (id)sender;
- (IBAction)  showPreferences:(id)sender;
- (NSArray*)  annotationOptionsFromDefaults;


// About Box
- (IBAction)  showAboutBox:(id)sender;
- (void)	  webView:(WebView*)webView decidePolicyForNavigationAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request frame:(WebFrame*)frame decisionListener:(id < WebPolicyDecisionListener >)listener;

// Version Utilities
- (NSString*) shortVersionString;					// Eg "Version:0.9.5"
- (NSString*) shortVersionNumberString;				// Eg "0.9.5"
- (NSString*) macHgShortVersionString;				// Eg "MacHg 0.9.5"
- (NSString*) macHgBuildHashKeyString;				// Eg "df3754a23dd7"
- (NSString*) shortMercurialVersionNumberString;	// Eg "1.5.3"
- (NSString*) shortMercurialVersionString;			// Eg "Mercurial SCM 1.5.3"
- (NSString*) mercurialBuildHashKeyString;			// Eg "20100514"
- (NSAttributedString*) fullVersionString;


// External Diff Support
- (NSString*) scriptNameForDiffTool:(ToolForDiffing)tool;
- (NSString*) applicationNameForDiffTool:(ToolForDiffing)tool;
- (void)	  preLaunchDiffToolIfNeeded:(ToolForDiffing)tool;
- (BOOL)	  diffToolWantsGroupedFiles:(ToolForDiffing)tool;
- (BOOL)	  diffToolNeedsPreLaunch:(ToolForDiffing)tool;


// External Merge Support
- (NSString*) scriptNameForMergeTool:(ToolForMerging)tool;
- (NSString*) applicationNameForMergeTool:(ToolForMerging)tool;
- (void)	  preLaunchMergeToolIfNeeded:(ToolForMerging)tool;
- (BOOL)	  mergeToolWantsGroupedFiles:(ToolForMerging)tool;
- (BOOL)	  mergeToolNeedsPreLaunch:(ToolForMerging)tool;


// Help Menus
- (IBAction)  openQuickStartPage:(id)sender;
- (IBAction)  openBugReportPage:(id)sender;
- (IBAction)  openReleaseNotes:(id)sender;
- (IBAction)  openWebsite:(id)sender;


// Cache handling
- (NSString*) cacheDirectory;


// Changeset handling
- (void)	  checkRepositoryIdentities:(NSTimer*)theTimer;
- (void)	  computeRepositoryIdentityForPath:(NSString*)path;									// recompute the root changeset for a given path
- (void)	  computeRepositoryIdentityForPath:(NSString*)path forNodePath:(NSString*)nodePath;	// recompute the root changeset for a given path and announce this for
																								// sidebar nodes with path nodePath.
@end




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  URL operations
// -----------------------------------------------------------------------------------------------------------------------------------------

NSString* FullServerURL(NSString* baseURL, PasswordVisibilityType visibility);	// Flush out the base url with the password if it is stored in the keychain




