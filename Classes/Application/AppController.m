//
//  AppController.m
//  MacHg
//
//  Created by Jason Harris on 26/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "AppController.h"
#import "TaskExecutions.h"
#import "PreferenceController.h"
#import "InitializationWizardController.h"
#import "LogEntry.h"
#import "RadialGradiantBox.h"

@implementation AppController
@synthesize urlUsesPassword = urlUsesPassword_;




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
	urlUsesPassword_					= [[NSMutableSet alloc]init];
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


- (InitializationWizardController*) theInitilizationWizardController
{
	if (!theInitilizationWizardController_)
		theInitilizationWizardController_ = [[InitializationWizardController alloc] initInitializationWizardController];
	return theInitilizationWizardController_;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Version Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) shortVersionNumberString	{ return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; }
- (NSString*) shortVersionString		{ return fstr(@"Version:%@", [self shortVersionNumberString]); }
- (NSString*) macHgShortVersionString	{ return fstr(@"MacHg %@", [self shortVersionNumberString]); }

- (NSString*) macHgBuildHashKeyString
{
	NSString* key = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"BuildHashKey"];
	return nonNil(key);
}

- (NSString*) mercurialVersionString
{
	static NSString* versionString = nil;
	if (!versionString)
	{
		NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"version", @"--quiet", nil];
		ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
		NSArray* versionParts = [result.outStr componentsSeparatedByString:@"\n"];
		versionString = ([versionParts count] > 0) ? [versionParts objectAtIndex:0] : nil;
	}
	return versionString ? versionString : @"";
}

- (NSString*) shortMercurialVersionNumberString
{
	NSString* shortNumber;
	BOOL matched = [[self mercurialVersionString] getCapturesWithRegexAndComponents:@"Mercurial Distributed SCM \\(version ([0-9\\.]+)\\+[0-9\\.]+\\)" firstComponent:&shortNumber];
	return matched ? shortNumber : @"";
}

- (NSString*) mercurialBuildHashKeyString
{
	NSString* hashKeyString;
	BOOL matched = [[self mercurialVersionString] getCapturesWithRegexAndComponents:@"Mercurial Distributed SCM \\(version [0-9\\.]+\\+([0-9\\.]+)\\)" firstComponent:&hashKeyString];
	return matched ? hashKeyString : @"";
}

- (NSString*) shortMercurialVersionString	{ return fstr(@"Mercurial SCM %@", [self shortMercurialVersionNumberString]); }


- (NSAttributedString*) fullVersionString
{
	NSMutableAttributedString* version = [[NSMutableAttributedString alloc] init];	
	[version appendString:[self shortVersionString] withAttributes:systemFontAttributes];
	[version appendString:fstr(@" (%@)",[self macHgBuildHashKeyString]) withAttributes:smallGraySystemFontAttributes];
	
	// Switch the version string to center aligned
	NSMutableParagraphStyle* ps = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[ps setAlignment:NSCenterTextAlignment];
	NSDictionary* newParagraphStyle = [NSDictionary dictionaryWithObject:ps forKey:NSParagraphStyleAttributeName];
	[version addAttributes:newParagraphStyle range:NSMakeRange(0, [version length])];
	return version;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Configuration Checking
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) checkForSupportDirectory
{
	if (pathIsExistent(applicationSupportFolder()))
		return;

	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSError* theError;
	[fileManager createDirectoryAtPath:applicationSupportFolder() withIntermediateDirectories:YES attributes:nil error:&theError];
}

- (void) checkForConfigFile
{
	NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
	if (pathIsExistent(macHgHGRCFilePath))
		return;

	NSString* sourceMacHgHGRCpath = fstr(@"%@/%@",[[NSBundle mainBundle] resourcePath], @"hgrc");
	NSString* hgrcContents = [NSString stringWithContentsOfFile:sourceMacHgHGRCpath encoding:NSUTF8StringEncoding error:nil];
	hgrcContents = [hgrcContents stringByReplacingOccurrencesOfString:@"~" withString:NSHomeDirectory()];
	[hgrcContents writeToFile:macHgHGRCFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void) checkConfigFileForUserName
{
	NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"ui.username", nil];
	ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
	if (IsEmpty(result.outStr))
		[[self theInitilizationWizardController] showWizard];	
}


- (void) checkConfigFileForEditingExtensions:(BOOL)onStartup;
{
	// Find out which extensions are enabled
	NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"extensions", nil];
	ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];

	BOOL addExtDiff      = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.extdiff\\s*="	options:RKLMultiline];
	BOOL addExtBookmarks = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.bookmarks\\s*=" options:RKLMultiline];
	BOOL addExtMq		 = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.mq\\s*="		options:RKLMultiline];
	BOOL addExtRebase    = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.rebase\\s*="	options:RKLMultiline];
	BOOL addExtHistEdit	 = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.histedit\\s*="  options:RKLMultiline];
	BOOL addExtCollapse  = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.collapse\\s*="  options:RKLMultiline];

	if (addExtDiff || addExtBookmarks || addExtMq || addExtRebase || addExtHistEdit || addExtCollapse)
	{
		NSFileManager* fileManager = [NSFileManager defaultManager];
		NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
		[fileManager appendString:@"\n[extensions]\n" toFilePath:macHgHGRCFilePath];
		if (addExtDiff)			[fileManager appendString:@"hgext.extdiff=\n"	toFilePath:macHgHGRCFilePath];
		if (addExtBookmarks)	[fileManager appendString:@"hgext.bookmarks=\n" toFilePath:macHgHGRCFilePath];
		if (addExtMq)			[fileManager appendString:@"hgext.mq=\n"		toFilePath:macHgHGRCFilePath];
		if (addExtRebase)		[fileManager appendString:@"hgext.rebase=\n"	toFilePath:macHgHGRCFilePath];
		if (addExtHistEdit)		[fileManager appendString:@"hgext.histedit=\n"	toFilePath:macHgHGRCFilePath];
		if (addExtCollapse)		[fileManager appendString:@"hgext.collapse=\n"	toFilePath:macHgHGRCFilePath];
	}

	if (!onStartup)
		NSRunAlertPanel(@"Editing Extensions Enabled", @"The history editing extensions are enabled.", @"OK", nil, nil);
}

- (void) checkForFileMerge
{
	if (![[NSWorkspace sharedWorkspace] fullPathForApplication:@"FileMerge"])
		NSRunCriticalAlertPanel(@"FileMerge not found", @"FileMerge was not found on this system. Please install the developer tools from the system disk which came with your computer (they contain the application FileMerge). MacHg can function without FileMerge but you cannot view any diffs, since this is the tool MacHg uses to view diffs.", @"OK", nil, nil);
	if (!pathIsExistent(@"/usr/bin/opendiff"))
		NSRunCriticalAlertPanel(@"Opendiff not found", @"/usr/bin/opendiff was not found on this system. Please install the developer tools from the system disk which came with your computer (they contain the application FileMerge). MacHg can function without FileMerge but you cannot view any diffs, since this is the tool MacHg uses to view diffs.", @"OK", nil, nil);
}



- (void) checkForMercurialWarningsAndErrors
{
	NSArray* versionArgs = [NSArray arrayWithObject:@"version"];
	NSString* hgBinary = executableLocationHG();
	ExecutionResult* results = [TaskExecutions synchronouslyExecute:hgBinary withArgs:versionArgs onTask:nil];
	if ([results hasWarnings] && WarnAboutBadMercurialConfigurationFromDefaults())
	{
		NSString* mainMessage = fstr(@"The version of Mercurial included with MacHg is producing the following warnings:\n\n%@\n\nMacHg might not function as intended. To resolve this check your configuration settings in your .hgrc file.", results.errStr);
		RunCriticalAlertPanelWithSuppression(@"Mercurial Warnings", mainMessage, @"OK", nil, MHGWarnAboutBadMercurialConfiguration);	
	}	
	if ([results hasErrors])
	{
		NSString* mainMessage = fstr(@"The version of Mercurial included with MacHg is producing the following Errors:\n\n%@\n\nMacHg cannot proceed. To resolve this check your configuration settings in your .hgrc file.", results.errStr);
		NSRunCriticalAlertPanel(@"Mercurial Errors", mainMessage, @"OK", nil, nil);
		[NSApp terminate:self];
	}
}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Starting up
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) awakeFromNib
{
	[self setupGlobals];
	// mv now old log file ontop of old old log file name
	NSString* oldMacHgLogFileLocation = fstr(@"%@.old",MacHgLogFileLocation());
	[TaskExecutions synchronouslyExecute:@"/bin/mv" withArgs:[NSArray arrayWithObjects:@"-f", MacHgLogFileLocation(), oldMacHgLogFileLocation, nil] onTask:nil];
}


- (void) applicationDidFinishLaunching:(NSNotification*)aNotification
{
	// Increment launch count
	NSInteger launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:MHGLaunchCount];
	[[NSUserDefaults standardUserDefaults] setInteger:launchCount +1 forKey:MHGLaunchCount];

	[self checkForSupportDirectory];
	[self checkForConfigFile];
	[self checkConfigFileForUserName];
	[self checkConfigFileForEditingExtensions:YES];
	[self checkForFileMerge];
	[self checkForMercurialWarningsAndErrors];
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

		// look for ~/Application Support/MacHg/Repositories.machg
		NSString* defaultDocumentPath = fstr(@"%@/Repositories.mchg", applicationSupportFolder());
		NSURL* defaultURL = [NSURL fileURLWithPath:defaultDocumentPath];
		if ([[NSFileManager defaultManager] fileExistsAtPath:[defaultURL path]])
			if ([docController openDocumentWithContentsOfURL:defaultURL display:YES error:nil])
				return NO;

		// create document ~/Application Support/MacHg/Repositories.machg
		NSError* err = nil;
		MacHgDocument* newDoc = [docController openUntitledDocumentAndDisplay:YES error:&err];
		if (newDoc)
		{
			[newDoc saveToURL:defaultURL ofType:@"MacHgDocument" forSaveOperation:NSSaveAsOperation error:&err];
			[newDoc showWindows];
			return NO;
		}
		return YES;
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

- (IBAction) resetPreferences:(id)sender	{ [AppController resetUserPreferences]; }
- (IBAction) showPreferences:(id)sender		{ [[PreferenceController sharedPrefsWindowController] showWindow:nil]; }





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: About Box
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) showAboutBox:(id)sender
{
	[NSBundle loadNibNamed:@"About" owner:self];
	[backingBox setRadius:[NSNumber numberWithFloat:190.0]];
	[backingBox setOffsetFromCenter:NSMakePoint(0.0, -40.0)];
	[backingBox setNeedsDisplay:YES];
	NSURL* creditsURL = [NSURL fileURLWithPath:fstr(@"%@/MacHGHelp/%@",[[NSBundle mainBundle] resourcePath], @"Credits.html")];
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
	NSURL* bugReportPage = [NSURL URLWithString:@"http://bitbucket.org/jfh/machg/issues?status=new&status=open"];
	[[NSWorkspace sharedWorkspace] openURL:bugReportPage];
}
- (IBAction) openReleaseNotes:(id)sender
{
	NSURL* bugReportPage = [NSURL URLWithString:@"http://www.jasonfharris.com/machg/downloads/notes/releasenotes.html"];
	[[NSWorkspace sharedWorkspace] openURL:bugReportPage];
}
- (IBAction) openWebsite:(id)sender
{
	NSURL* bugReportPage = [NSURL URLWithString:@"http://www.jasonfharris.com/machg"];
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
	
	NSString* fullPath = path;
	if ([[self urlUsesPassword] containsObject:path])
		fullPath = FullServerURL(path, YES);

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
		NSMutableArray* argsIdentify = [NSMutableArray arrayWithObjects:@"identify", @"--rev", @"0", @"--id", @"--quiet", fullPath, nil];
		__block NSTask* theTask = [[NSTask alloc]init];
		__block ExecutionResult* results;
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
