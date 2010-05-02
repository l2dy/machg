//
//  AppController.m
//  MacHg
//
//  Created by Jason Harris on 26/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "AppController.h"
#import "TaskExecutions.h"
#import "PreferenceController.h"
#import "InitializationWizardController.h"
#import "LogEntry.h"

@implementation AppController





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) setupGlobals
{
	DebugLog(@"set up globals");
	periodicCheckingForRepositoryIdentity = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(checkRepositoryIdentities:) userInfo:nil repeats:YES];
	NOasNumber  = [NSNumber numberWithBool:NO];
	YESasNumber = [NSNumber numberWithBool:YES];
	SlotNumber  = [NSNumber numberWithInteger:(NSNotFound -1)];

	setupGlobalsForPartsAndTemplate();
	
	// Cache the two attribute cases for the sidebar fonts to help improve speed. This will be called a lot, and helps improve performance.
	//NSFontManager* fontManager = [NSFontManager sharedFontManager];
	//NSFont* textFont = [NSFont fontWithName:@"Verdana" size:[NSFont smallSystemFontSize]];
	NSMutableParagraphStyle* ps  = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	NSMutableParagraphStyle* cps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

	[ps setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[cps setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[cps setAlignment:NSCenterTextAlignment];
	NSFont* systemFont			= [NSFont systemFontOfSize:		[NSFont systemFontSize]];
	NSFont* boldSystemFont		= [NSFont boldSystemFontOfSize:	[NSFont systemFontSize]];
	NSFont* smallSystemFont		= [NSFont systemFontOfSize:		[NSFont smallSystemFontSize]];
	NSFont* smallBoldSystemFont = [NSFont boldSystemFontOfSize:	[NSFont smallSystemFontSize]];
	// There is no italic version of the system font so we use NSObliquenessAttributeName
	// NSFont* italicTextFont = [fontManager convertFont:textFont toHaveTrait:NSItalicFontMask];
	NSColor* grayColor = [NSColor grayColor];
	NSColor* darkGreen = [NSColor colorWithCalibratedRed:0.0 green:0.35 blue:0.0 alpha:1.0];

	// Set up font attributes
	systemFontAttributes			= [NSDictionary dictionaryWithObjectsAndKeys: systemFont, NSFontAttributeName, nil];
	graySystemFontAttributes		= [NSDictionary dictionaryWithObjectsAndKeys: systemFont, NSFontAttributeName, grayColor, NSForegroundColorAttributeName, nil];
	boldSystemFontAttributes		= [NSDictionary dictionaryWithObjectsAndKeys: boldSystemFont, NSFontAttributeName, nil];
	italicSystemFontAttributes		= [NSDictionary dictionaryWithObjectsAndKeys: systemFont, NSFontAttributeName, [NSNumber numberWithFloat:0.15], NSObliquenessAttributeName, nil];

	smallSystemFontAttributes       = [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont, NSFontAttributeName, nil];
	smallGraySystemFontAttributes   = [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont, NSFontAttributeName, grayColor, NSForegroundColorAttributeName, nil];
	smallBoldSystemFontAttributes   = [NSDictionary dictionaryWithObjectsAndKeys: smallBoldSystemFont, NSFontAttributeName, nil];
	smallItalicSystemFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont, NSFontAttributeName, [NSNumber numberWithFloat:0.15], NSObliquenessAttributeName, nil];

	smallCenteredSystemFontAttributes     = [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont,     NSFontAttributeName, cps, NSParagraphStyleAttributeName, nil];
	smallBoldCenteredSystemFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys: smallBoldSystemFont, NSFontAttributeName, cps, NSParagraphStyleAttributeName, nil];
	
	standardSidebarFontAttributes		= [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont, NSFontAttributeName, ps, NSParagraphStyleAttributeName, nil];
	italicSidebarFontAttributes			= [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont, NSFontAttributeName, ps, NSParagraphStyleAttributeName, [NSNumber numberWithFloat:0.15], NSObliquenessAttributeName, nil];
	
	standardVirginSidebarFontAttributes	= [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont, NSFontAttributeName, darkGreen, NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, nil];
	italicVirginSidebarFontAttributes	= [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont, NSFontAttributeName, darkGreen, NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, [NSNumber numberWithFloat:0.15], NSObliquenessAttributeName, nil];

	//grayedAttributes   = [NSDictionary dictionaryWithObjectsAndKeys: textFont,       NSFontAttributeName, greyColor, NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, nil];
	
}

- (id) init
{
	self = [super init];
	applicationHasStarted = NO;
	theTaskExecutions = [TaskExecutions theInstance];
	repositoryIdentityForPath_	        = [[NSMutableDictionary alloc]init];
	computingRepositoryIdentityForPath_ = [[NSMutableDictionary alloc]init];
	dirtyRepositoryIdentityForPath_     = [[NSMutableDictionary alloc]init];
	return self;
}

+ (void) initialize
{
	[self initializePreferenceDefaults];
}


+ (AppController*) sharedAppController
{
	return DynamicCast(AppController, [NSApp delegate]);
}


- (PreferenceController*) thePreferenceController
{
	if (!thePreferenceController_)
		thePreferenceController_ = [[PreferenceController alloc] initPreferenceController];
	return thePreferenceController_;
}

- (InitializationWizardController*) theInitilizationWizardController
{
	if (!theInitilizationWizardController_)
		theInitilizationWizardController_ = [[InitializationWizardController alloc] initInitializationWizardController];
	return theInitilizationWizardController_;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) shortVersionNumberString	{ return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; }
- (NSString*) shortVersionString		{ return [NSString stringWithFormat:@"Version:%@", [self shortVersionNumberString]]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Configuration Checking
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) checkConfigFileForUserName
{
	NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"ui.username", nil];
	ExecutionResult result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
	if (IsEmpty(result.outStr))
		[[self theInitilizationWizardController] showWizard];	
}

- (NSString*) applicationSupportFolder;
{
	NSArray* searchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString* applicationSupportFolder = [searchPaths objectAtIndex:0];
	return [NSString stringWithFormat:@"%@/%@/%@", applicationSupportFolder, [[NSProcessInfo processInfo] processName], [self shortVersionNumberString]];
}


- (void) checkConfigFileForEditingExtensions:(BOOL)onStartup;
{
	// If history editing is not allowed then we don't need to turn the extensions on.
	if (!AllowHistoryEditingOfRepositoryFromDefaults())
		return;

	NSFileManager* fileManager = [NSFileManager defaultManager];
	
	// Look for [extensions]\nhgext.extdiff = and if we don't find it add it to the default .hgrc file. This allows us to do diffs, etc.
	NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"extensions", nil];
	ExecutionResult result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];

	BOOL addExtDiff      = ![result.outStr matchesRegex:@"^extensions\\.hgext\\.extdiff\\s*="	options:RKLMultiline];
	BOOL addExtBookmarks = ![result.outStr matchesRegex:@"^extensions\\.hgext\\.bookmarks\\s*=" options:RKLMultiline];
	BOOL addExtMq		 = ![result.outStr matchesRegex:@"^extensions\\.hgext\\.mq\\s*="		options:RKLMultiline];
	BOOL addExtRebase    = ![result.outStr matchesRegex:@"^extensions\\.hgext\\.rebase\\s*="	options:RKLMultiline];
	BOOL addExtHistEdit	 = ![result.outStr matchesRegex:@"^extensions\\.hgext\\.histedit\\s*="  options:RKLMultiline];
	BOOL addExtCollapse  = ![result.outStr matchesRegex:@"^extensions\\.hgext\\.collapse\\s*="  options:RKLMultiline];

	// Create the named versioned application support extensions directory
	NSError* theError;
	NSString* supportFolder = [[self applicationSupportFolder] stringByAppendingPathComponent:@"extensions"];
	[fileManager createDirectoryAtPath:supportFolder withIntermediateDirectories:YES attributes:nil error:&theError];
	
	NSString* histeditDest = [supportFolder stringByAppendingPathComponent:@"histedit.py"];
	NSString* collapseDest = [supportFolder stringByAppendingPathComponent:@"collapse.py"];
	NSString* histeditSource = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] builtInPlugInsPath], @"LocalMercurial/hgext/histedit/__init__.py"];
	NSString* collapseSource = [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] builtInPlugInsPath], @"LocalMercurial/hgext/collapse.py"];
	
	//NSDictionary* dict = [manager attributesOfItemAtPath:histeditDest error:&theError];
	if (![fileManager isReadableFileAtPath:histeditDest])
		[fileManager copyItemAtPath:histeditSource toPath:histeditDest error:&theError];
	if (![fileManager isReadableFileAtPath:collapseDest])
		[fileManager copyItemAtPath:collapseSource toPath:collapseDest error:&theError];
	
	if (!addExtDiff && !addExtBookmarks && !addExtMq && !addExtRebase && !addExtHistEdit && !addExtCollapse)
	{
		if (!onStartup)
			NSRunAlertPanel(@"Editing Extensions Enabled", @"The history editing extensions are enabled in your mercurial configuration file (.hgrc).", @"Ok", nil, nil);
		return;
	}
	
	NSString* dotHGRC = [NSHomeDirectory() stringByAppendingPathComponent:@".hgrc"];
	[fileManager appendString:@"\n[extensions]\n" toFilePath:dotHGRC];
	if (addExtDiff)			[fileManager appendString:@"hgext.extdiff=\n"	toFilePath:dotHGRC];
	if (addExtBookmarks)	[fileManager appendString:@"hgext.bookmarks=\n" toFilePath:dotHGRC];
	if (addExtMq)			[fileManager appendString:@"hgext.mq=\n"		toFilePath:dotHGRC];
	if (addExtRebase)		[fileManager appendString:@"hgext.rebase=\n"	toFilePath:dotHGRC];
	if (addExtHistEdit)
	{
		NSString* extensionPath = [NSString stringWithFormat:@"hgext.histedit=%@\n", histeditDest];
		[fileManager appendString:extensionPath toFilePath:dotHGRC];
	}
	if (addExtCollapse)
	{
		NSString* extensionPath = [NSString stringWithFormat:@"hgext.collapse=%@\n", collapseDest];
		[fileManager appendString:extensionPath toFilePath:dotHGRC];
	}

	if (!addExtMq && !addExtRebase && !addExtHistEdit && !addExtCollapse)
	{
		NSString* message = onStartup ? @"History editing was previously enabled, yet some extensions where not enabled in your mercurial configuration file (.hgrc). The necessary extensions have been re-enabled in your mercurial configuration file at %@. These extensions are used when you edit a repositories history from within MacHg. Having these extensions enabled does not effect any other standard mercurial operations." :
										@"History editing in MacHg has been enabled. The necessary extensions have been enabled in your mercurial configuration file at %@. These extensions are used when you edit a repositories history from within MacHg. Having these extensions enabled does not effect any other standard mercurial operations.";
		NSString* completeMessage = [NSString stringWithFormat:message, dotHGRC];
		NSRunAlertPanel(@"Editing Extensions Enabled", completeMessage, @"Ok", nil, nil);
	}
}

- (void) checkForFileMerge
{
	if(![[NSWorkspace sharedWorkspace] fullPathForApplication:@"FileMerge"])
		NSRunCriticalAlertPanel(@"FileMerge not found", @"FileMerge was not found on this system. Please install the developer tools from the system disk which came with your computer (they contain the application FileMerge). MacHg can function without FileMerge but you cannot view any diffs, since this is the tool MacHg uses to view diffs.", @"Ok", nil, nil);
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Starting up
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	[self setupGlobals];
	// mv now old log file ontop of old old log file name
	NSString* oldMacHgLogFileLocation = [NSString stringWithFormat:@"%@.old",MacHgLogFileLocation()];
	[TaskExecutions synchronouslyExecute:@"/bin/mv" withArgs:[NSArray arrayWithObjects:@"-f", MacHgLogFileLocation(), oldMacHgLogFileLocation, nil] onTask:nil];
}


- (void) applicationDidFinishLaunching:(NSNotification*)aNotification
{
	// Increment launch count
	NSInteger launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:MHGLaunchCount];
	[[NSUserDefaults standardUserDefaults] setInteger:launchCount +1 forKey:MHGLaunchCount];

	[self checkConfigFileForUserName];
	[self checkConfigFileForEditingExtensions:YES];	
	[self checkForFileMerge];
}


// On startup, when asked to open an untitled file, open the last opened
// file instead See http://cocoawithlove.com/2008/05/open-previous-document-on-application.html
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*)sender
{
	static BOOL startingUp = YES;

	if (startingUp && OnStartupOpenFromDefaults() == eOpenLastDocument)
	{
		startingUp = NO;
		// Reopen last document
		NSDocumentController* docController = [NSDocumentController sharedDocumentController];
		if ([[docController recentDocumentURLs] count] > 0)
			for (NSURL* url in [docController recentDocumentURLs])
				if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]])
					if ([docController openDocumentWithContentsOfURL:url display:YES error:nil])
						return NO;
	}
	startingUp = NO;
	
	if (OnStartupOpenFromDefaults() == eDontOpenAnything)
		return NO;
	if (OnStartupOpenFromDefaults() == eOpenNewDocument)
		return YES;

	return YES;			// If we are not starting up then the user can open an untitled document
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Preference Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (void) initializePreferenceDefaults
{
	// load the default values for the user defaults
	NSString*	  userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary* userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
	
	// set them in the standard user defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
}

+ (void) resetUserPreferences
{
	// load the default values for the user defaults
	NSString*	  userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	NSDictionary* userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];

	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:userDefaultsValuesDict];
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:nil];
}

- (IBAction) resetPreferences: (id)sender
{
	[[self thePreferenceController] resetPreferences:sender];
}

- (IBAction) showPreferences:(id)sender
{
	[[self thePreferenceController] showWindow:self];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: About Box
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) showAboutBox:(id)sender
{
	[NSBundle loadNibNamed:@"About" owner:self];
	NSURL* creditsURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/MacHGHelp/%@",[[NSBundle mainBundle] resourcePath], @"Credits.html"]];
	[[creditsWebview mainFrame] loadRequest:[NSURLRequest requestWithURL:creditsURL]];
}


- (void) webView:(WebView*)webView decidePolicyForNavigationAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request frame:(WebFrame*)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
	// Any non file URL gets opened externally to MacHg. Ie in Safari, etc.
	if (![[request URL] isFileURL])
	{
		NSURL* paypalURL = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VUKBMKTKZMPV2"];
		
		// Strangely due to http: www.cocoabuilder.com/archive/cocoa/165312-open-safari-and-send-post-variables.html#165322 it
		// appears that you can't open safari with a post NSURLRequest. This appears to be a limitation. Anyway, because of this
		// specially intercept the method we would send out to paypal and change it to the link above.
		if ([[[request URL] absoluteString] isEqualToString:@"https://www.paypal.com/cgi-bin/webscr"])
			[[NSWorkspace sharedWorkspace] openURL:paypalURL];
		else
			[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
	else
		[listener use];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Help Menus
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) openQuickStartPage:(id)sender
{
	NSString* locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"QuickStart" inBook:locBookName];
}
- (IBAction) openBugReportPage:(id)sender
{
	NSURL* bugReportPage = [NSURL URLWithString:@"http://bitbucket.org/jfh/machg/issues/"];
	[[NSWorkspace sharedWorkspace] openURL:bugReportPage];
}
- (IBAction) openRelaseNotes:(id)sender
{
	NSURL* bugReportPage = [NSURL URLWithString:@"http://www.jasonfharris.com/machg/downloads/notes/releasenotes.html"];
	[[NSWorkspace sharedWorkspace] openURL:bugReportPage];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Changeset handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) repositoryIdentityForPath:(NSString*)path								{ return DynamicCast(NSString, [repositoryIdentityForPath_ synchronizedObjectForKey:path]); }
- (void)	  setRepositoryIdentity:(NSString*)changeset ForPath:(NSString*)path	{ [repositoryIdentityForPath_ synchronizedSetObject:changeset forKey:path]; }

- (void) checkRepositoryIdentities:(NSTimer*)theTimer
{
	NSArray* allDirtyRepos = [dirtyRepositoryIdentityForPath_ synchronizedAllKeys];
	for (NSString* path in allDirtyRepos)
		if ([computingRepositoryIdentityForPath_ synchronizedObjectForKey:path] == nil)
			[self computeRepositoryIdentityForPath:path];
}


- (void) computeRepositoryIdentityForPath:(NSString*)path;
{
	if (!path)
		return;
	
	// If we are already computing the root changeset then don't compute it again
	if ([computingRepositoryIdentityForPath_ synchronizedObjectForKey:path])
		return;
	
	// Indicate that we are now about to compute the root changeset of the path
	[computingRepositoryIdentityForPath_ synchronizedSetObject:YESasNumber forKey:path];
	
	// Find out how many times we have tried to compute the path before.
	id val = [dirtyRepositoryIdentityForPath_ synchronizedObjectForKey:path];
	if ([val isEqual:@"uncomputable"])
		return;
	
	// Increment the attempt number.
	int attempts = numberAsInt(DynamicCast(NSNumber, val)) + 1;
	[dirtyRepositoryIdentityForPath_ synchronizedSetObject:intAsNumber(attempts) forKey:path];
	
	// If we have attempted to many times to compute the root just give up and mark it "uncomputable"
	if (attempts > 6)
	{
		[dirtyRepositoryIdentityForPath_ synchronizedSetObject:@"uncomputable" forKey:path];
		return;
	}

	NSTimeInterval timeOutInSeconds = 5.0 * pow(2.0, attempts);
	
	dispatch_async(globalQueue(), ^{
		NSMutableArray* argsIdentify = [NSMutableArray arrayWithObjects:@"identify", @"--rev", @"0", @"--id", @"--quiet", path, nil];
		__block NSTask* theTask = [[NSTask alloc]init];
		__block ExecutionResult results;
		dispatchWithTimeOut(globalQueue(), timeOutInSeconds, ^{
			results = [TaskExecutions executeMercurialWithArgs:argsIdentify fromRoot:@"/tmp" logging:eLoggingNone onTask:theTask];
		});

		[computingRepositoryIdentityForPath_ synchronizedRemoveObjectForKey:path];
	
		if (![theTask isRunning] && results.result == 0 && IsEmpty(results.errStr) && IsNotEmpty(results.outStr))
		{
			NSString* changesetIdentity = trimString(results.outStr);
			NSString* oldValue = [repositoryIdentityForPath_ synchronizedObjectForKey:path];
			[repositoryIdentityForPath_ synchronizedSetObject:changesetIdentity forKey:path];
			if ([changesetIdentity isNotEqualTo:oldValue])
			{
				NSDictionary* info = [NSDictionary dictionaryWithObject:path forKey:@"path"];
				[self postNotificationWithName:kRepositoryIdentityChanged userInfo:info];
			}
			[dirtyRepositoryIdentityForPath_ synchronizedRemoveObjectForKey:path];
			DebugLog(@"Root changeset of %@ is %@ on attempt %d", path, changesetIdentity, attempts);
			return;
		}

		if ([theTask isRunning])
			DebugLog(@"Determining root changeset for the repository at %@ timed out after %f seconds on attempt %d", path, timeOutInSeconds, attempts);
		else
			DebugLog(@"Unable to determine root changeset for the repository at %@ on attempt %d", path, attempts);
		
		[theTask cancelTask];
	});
}



@end
