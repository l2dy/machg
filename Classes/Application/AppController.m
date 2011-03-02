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
#import "LogRecord.h"
#import "RadialGradiantBox.h"
#import "EMKeychainItem.h"
#import "NSURL+Parameters.h"

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
	FullDateFormatter = [[NSDateFormatter alloc] init];
	[FullDateFormatter setDateStyle:NSDateFormatterLongStyle];
	[FullDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[FullDateFormatter setDoesRelativeDateFormatting:YES];
	

	setupGlobalsForLogEntryPartsAndTemplate();
	setupGlobalsForLogRecordPartsAndTemplate();
	
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
	NSFont* smallFixedPitchUserFont = [NSFont userFixedPitchFontOfSize:	[NSFont smallSystemFontSize]];

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
	smallFixedWidthUserFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys: smallFixedPitchUserFont, NSFontAttributeName, nil];

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
	computingRepositoryIdentityForPath_ = [[NSMutableDictionary alloc]init];
	dirtyRepositoryIdentityForPath_     = [[NSMutableDictionary alloc]init];

	// Initlize globals
	changesetHashToLogRecord			= [[NSMutableDictionary alloc]init];
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

- (void) includeHomeHGRC:(BOOL)include inProcess:(BlockProcess)block
{
	@synchronized(self)
	{
		BOOL oldIncludeHomeHgrc  = IncludeHomeHgrcInHGRCPATHFromDefaults();
		[[NSUserDefaults standardUserDefaults] setBool:include			   forKey:MHGIncludeHomeHgrcInHGRCPATH];	// Temporarily include / exclude ~/.hgrc
		block();
		[[NSUserDefaults standardUserDefaults] setBool:oldIncludeHomeHgrc  forKey:MHGIncludeHomeHgrcInHGRCPATH];	// Restore HGRC path
	}
}



- (void) checkForSupportDirectory
{
	if (pathIsExistent(applicationSupportFolder()))
		return;

	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSError* err = nil;
	[fileManager createDirectoryAtPath:applicationSupportFolder() withIntermediateDirectories:YES attributes:nil error:&err];
	[NSApp presentAnyErrorsAndClear:&err];
}


- (void) checkForConfigFile
{
	NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
	if (pathIsExistent(macHgHGRCFilePath))
		return;

	NSError* err = nil;
	NSString* sourceMacHgHGRCpath = fstr(@"%@/%@",[[NSBundle mainBundle] resourcePath], @"hgrc");
	NSString* hgrcContents = [NSString stringWithContentsOfFile:sourceMacHgHGRCpath encoding:NSUTF8StringEncoding error:&err];
	[NSApp presentAnyErrorsAndClear:&err];

	hgrcContents = [hgrcContents stringByReplacingOccurrencesOfString:@"~" withString:NSHomeDirectory()];
	[hgrcContents writeToFile:macHgHGRCFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
	[NSApp presentAnyErrorsAndClear:&err];
}


- (void) checkForIgnoreFile
{
	NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
	NSString* userHgignorePath = [NSHomeDirectory() stringByAppendingPathComponent:@".hgignore"];
	NSError* err = nil;

	// If the ~/.hgignore exists then make sure ~/Application Support/MacHg/hgrc points to it
	if (pathIsExistent(userHgignorePath))
	{
		NSMutableArray* argsCedit = [NSMutableArray arrayWithObjects:@"cedit", @"--config", @"hgext.cedit=", @"--add", fstr(@"ui.ignore = %@", userHgignorePath), @"--file", macHgHGRCFilePath, nil];
		[TaskExecutions executeMercurialWithArgs:argsCedit  fromRoot:@"/tmp"];
	}

	NSString* macHgIgnoreFilePath = fstr(@"%@/hgignore",applicationSupportFolder());
	if (!pathIsExistent(macHgIgnoreFilePath))
	{
		NSString* sourceMacHgHignorePath = fstr(@"%@/%@",[[NSBundle mainBundle] resourcePath], @"hgignore");
		NSString* hgignoreContents = [NSString stringWithContentsOfFile:sourceMacHgHignorePath encoding:NSUTF8StringEncoding error:&err];
		[NSApp presentAnyErrorsAndClear:&err];
		[hgignoreContents writeToFile:macHgIgnoreFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
		[NSApp presentAnyErrorsAndClear:&err];
	}

	NSMutableArray* argsCedit = [NSMutableArray arrayWithObjects:@"cedit", @"--config", @"hgext.cedit=", @"--add", fstr(@"ui.ignore.other = %@", macHgIgnoreFilePath), @"--file", macHgHGRCFilePath, nil];
	[TaskExecutions executeMercurialWithArgs:argsCedit  fromRoot:@"/tmp"];
}


- (void) checkForTrustedCertificates
{
	[self includeHomeHGRC:NO inProcess:^{
		NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
		NSString* macHgCertFilePath = fstr(@"%@/TrustedCertificates.pem",applicationSupportFolder());
		NSError* err = nil;

		// If the ~/.hgignore exists then make sure ~/Application Support/MacHg/hgrc points to it
		if (!pathIsExistent(macHgCertFilePath))
		{
			NSString* sourceCertFilePath = fstr(@"%@/%@",[[NSBundle mainBundle] resourcePath], @"TrustedCertificates.pem");
			NSString* certFileContents = [NSString stringWithContentsOfFile:sourceCertFilePath encoding:NSMacOSRomanStringEncoding error:&err];
			[NSApp presentAnyErrorsAndClear:&err];
			[certFileContents writeToFile:macHgCertFilePath atomically:YES encoding:NSMacOSRomanStringEncoding error:&err];
			[NSApp presentAnyErrorsAndClear:&err];
		}

		// Determine current configuration:
		NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"web.cacerts", nil];
		ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
		
		// If we currently don't have a certificate then point to our TrustedCertificates
		if ([result hasErrors] || [result hasWarnings] || IsEmpty([result outStr]))
		{
			NSMutableArray* argsCedit = [NSMutableArray arrayWithObjects:@"cedit", @"--config", @"hgext.cedit=", @"--add", fstr(@"web.cacerts = %@", macHgCertFilePath), @"--file", macHgHGRCFilePath, nil];
			[TaskExecutions executeMercurialWithArgs:argsCedit  fromRoot:@"/tmp"];
		}		
	}];	
}


- (void) checkConfigFileForUserName
{
	__block BOOL done = NO;

	// If we can find the user name in only our ~/Application Support/MacHg/hgrc file we are done.
	[self includeHomeHGRC:NO inProcess:^{
		NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"ui.username", nil];
		ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
		done = IsNotEmpty(result.outStr);
	}];
	if (done)
		return;

	
	// Switch the hgrc path to include both ~/Application Support/MacHg/hgrc and ~/.hgrc and look for the user name
	[self includeHomeHGRC:YES inProcess:^{
		NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"ui.username", nil];
		ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
		
		// If we found a user name in the user ~/.hgrc file but not the application support then copy the user name to the application
		// support file.
		if (!IsEmpty(result.outStr))
		{
			NSFileManager* fileManager = [NSFileManager defaultManager];
			NSString* macHgHGRCpath = fstr(@"%@/hgrc", applicationSupportFolder());
			[fileManager appendString:@"\n[ui]\n" toFilePath:macHgHGRCpath];
			[fileManager appendString:fstr(@"username = %@\n",	result.outStr) toFilePath:macHgHGRCpath];
			done = YES;
		}
	}];
	if (done)
		return;


	// Since we could not find a user name we have to ask the user for it
		[[self theInitilizationWizardController] showWizard];	
}


- (void) checkConfigFileForExtensions:(BOOL)onStartup;
{
	[self includeHomeHGRC:NO inProcess:^{
		
		// Find out which extensions are enabled within our ~/Application Support/MacHg/hgrc file
		NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"extensions", nil];
		ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
		
		BOOL addExtDiff         = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.extdiff\\s*="	  options:RKLMultiline];
		BOOL addExtBookmarks    = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.bookmarks\\s*="    options:RKLMultiline];
		BOOL addExtMq		    = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.mq\\s*="		      options:RKLMultiline];
		BOOL addExtRebase       = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.rebase\\s*="       options:RKLMultiline];
		BOOL addExtHistEdit	    = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.histedit\\s*="     options:RKLMultiline];
		BOOL addExtCollapse     = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.collapse\\s*="     options:RKLMultiline];
		BOOL addExtCedit        = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.cedit\\s*="		  options:RKLMultiline];
		BOOL addExtCombinedInfo = ![result.outStr isMatchedByRegex:@"^extensions\\.hgext\\.combinedinfo\\s*=" options:RKLMultiline];
		
		if (addExtDiff || addExtBookmarks || addExtMq || addExtRebase || addExtHistEdit || addExtCollapse || addExtCedit || addExtCombinedInfo)
		{
			NSFileManager* fileManager = [NSFileManager defaultManager];
			NSString* macHgHGRCPath = fstr(@"%@/hgrc",applicationSupportFolder());
			
			[fileManager appendString:@"\n[extensions]\n" toFilePath:macHgHGRCPath];
			if (addExtDiff)			[fileManager appendString:@"hgext.extdiff=\n"	   toFilePath:macHgHGRCPath];
			if (addExtBookmarks)	[fileManager appendString:@"hgext.bookmarks=\n"    toFilePath:macHgHGRCPath];
			if (addExtMq)			[fileManager appendString:@"hgext.mq=\n"		   toFilePath:macHgHGRCPath];
			if (addExtRebase)		[fileManager appendString:@"hgext.rebase=\n"	   toFilePath:macHgHGRCPath];
			if (addExtHistEdit)		[fileManager appendString:@"hgext.histedit=\n"	   toFilePath:macHgHGRCPath];
			if (addExtCollapse)		[fileManager appendString:@"hgext.collapse=\n"	   toFilePath:macHgHGRCPath];
			if (addExtCedit)		[fileManager appendString:@"hgext.cedit=\n"	       toFilePath:macHgHGRCPath];
			if (addExtCombinedInfo)	[fileManager appendString:@"hgext.combinedinfo=\n" toFilePath:macHgHGRCPath];
		}
		
	}];
	
	if (!onStartup)
		NSRunAlertPanel(@"Editing Extensions Enabled", @"The history editing extensions are enabled.", @"OK", nil, nil);
}




- (void) checkForFileMerge
{
	if (![[NSWorkspace sharedWorkspace] fullPathForApplication:@"FileMerge"])
		NSRunCriticalAlertPanel(@"FileMerge not found", @"FileMerge was not found on this system. Please install the full developer tools from the system disk which came with your computer (they contain the application FileMerge). MacHg can function without FileMerge but you cannot view any diffs, since this is the tool MacHg uses to view diffs.", @"OK", nil, nil);
	if (!pathIsExistent(@"/usr/bin/opendiff"))
		NSRunCriticalAlertPanel(@"Opendiff not found", @"/usr/bin/opendiff was not found on this system. Please install the full developer tools from the system disk which came with your computer (they contain the application FileMerge). MacHg can function without FileMerge but you cannot view any diffs, since this is the tool MacHg uses to view diffs.", @"OK", nil, nil);
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
	[self checkConfigFileForExtensions:YES];
	[self checkForIgnoreFile];
	[self checkForTrustedCertificates];
	[self checkConfigFileForUserName];
	[self checkForFileMerge];
	[self checkForMercurialWarningsAndErrors];
}


// On startup, when asked to open an untitled file, open the last opened
// file instead See http://cocoawithlove.com/2008/05/open-previous-document-on-application.html
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication*)sender
{
	if (OnActivationOpenFromDefaults() == eOpenLastDocument)
	{
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
		[NSApp presentAnyErrorsAndClear:&err];
		if (newDoc)
		{
			[newDoc saveToURL:defaultURL ofType:@"MacHgDocument" forSaveOperation:NSSaveAsOperation error:&err];
			[NSApp presentAnyErrorsAndClear:&err];
			[newDoc showWindows];
			return NO;
		}
		return YES;
	}
	
	if (OnActivationOpenFromDefaults() == eDontOpenAnything)
		return NO;
	if (OnActivationOpenFromDefaults() == eOpenNewDocument)
		return YES;

	return YES;			// If we are not starting up then the user can open an untitled document
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Shutting down
// -----------------------------------------------------------------------------------------------------------------------------------------


- (NSString*) cacheDirectory
{
	NSString* cacheDir = nil;
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	if ([paths count])
	{
		NSString* bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
		cacheDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
	}
	return cacheDir;	
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	// Remove the cache directory
	NSString* cacheDir = [self cacheDirectory];
	if (cacheDir)
	{
		NSFileManager* fileManager = [NSFileManager defaultManager];
		NSString* snapshotsDir = [cacheDir stringByAppendingPathComponent:@"snapshots"];
		[fileManager removeItemAtPath:snapshotsDir error:nil];
	}

    return NSTerminateNow;
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

- (NSArray*) annotationOptionsFromDefaults
{
	NSMutableArray* options = [[NSMutableArray alloc] init];
	if (DefaultAnnotationOptionChangesetFromDefaults())		[options addObject:@"--changeset"];
	if (DefaultAnnotationOptionDateFromDefaults())			[options addObject:@"--date"];
	if (DefaultAnnotationOptionFollowFromDefaults())		[options addObject:@"--follow"];
	if (DefaultAnnotationOptionLineNumberFromDefaults())	[options addObject:@"--line-number"];
	if (DefaultAnnotationOptionNumberFromDefaults())		[options addObject:@"--number"];
	if (DefaultAnnotationOptionTextFromDefaults())			[options addObject:@"--text"];
	if (DefaultAnnotationOptionUserFromDefaults())			[options addObject:@"--user"];
	return options;
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: About Box
// -----------------------------------------------------------------------------------------------------------------------------------------

- (IBAction) showAboutBox:(id)sender
{
	if (aboutWindow == NULL)
	{
		[NSBundle loadNibNamed:@"About" owner:self];
		[backingBox setRadius:[NSNumber numberWithFloat:190.0]];
		[backingBox setOffsetFromCenter:NSMakePoint(0.0, -40.0)];
		[backingBox setNeedsDisplay:YES];
		NSURL* creditsURL = [NSURL fileURLWithPath:fstr(@"%@/MacHGHelp/%@",[[NSBundle mainBundle] resourcePath], @"Credits.html")];
		[[creditsWebview mainFrame] loadRequest:[NSURLRequest requestWithURL:creditsURL]];
	}
	
	[aboutWindow makeKeyAndOrderFront:nil];
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
	NSURL* bugReportPage = [NSURL URLWithString:@"http://jasonfharris.com/machg/downloads/notes/releasenotes.html"];
	[[NSWorkspace sharedWorkspace] openURL:bugReportPage];
}
- (IBAction) openWebsite:(id)sender
{
	NSURL* bugReportPage = [NSURL URLWithString:@"http://jasonfharris.com/machg"];
	[[NSWorkspace sharedWorkspace] openURL:bugReportPage];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Changeset handling
// -----------------------------------------------------------------------------------------------------------------------------------------

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
	
	NSString* fullPath = FullServerURL(path, eAllPasswordsAreVisible);

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
	
	// If we have attempted too many times to compute the root just give up and mark it "uncomputable"
	if (attempts > 6)
	{
		[dirtyRepositoryIdentityForPath_ synchronizedSetObject:@"uncomputable" forKey:path];
		return;
	}

	NSTimeInterval timeOutInSeconds = 5.0 * pow(2.0, attempts);
	
	dispatch_async(globalQueue(), ^{
		NSMutableArray* argsIdentify = [NSMutableArray arrayWithObjects:@"identify", @"--insecure", @"--noninteractive", @"--rev", @"0", @"--id", @"--quiet", fullPath, nil];
		__block NSTask* theTask = [[NSTask alloc]init];
		__block ExecutionResult* results;
		dispatchWithTimeOut(globalQueue(), timeOutInSeconds, ^{
			results = [TaskExecutions executeMercurialWithArgs:argsIdentify fromRoot:@"/tmp" logging:eLoggingNone onTask:theTask];
		});

		[computingRepositoryIdentityForPath_ synchronizedRemoveObjectForKey:path];
	
		if (![theTask isRunning] && results.result == 0 && IsEmpty(results.errStr) && IsNotEmpty(results.outStr))
		{
			// We look for the 12 digit hashKey which is optionally seperated from other bits by whitespace.
			static NSString* pickOutHashKeyRegex = @"^(.*\\s+)?([0-9abcdefABCDEF]{12})(\\s+.*)?$";
			NSString* repositoryIdentity;
			BOOL matched = [results.outStr getCapturesWithRegexAndComponents:pickOutHashKeyRegex firstComponent:nil secondComponent:&repositoryIdentity thirdComponent:nil];
			if (!matched)
				return;
			NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:path, @"path", repositoryIdentity, @"repositoryIdentity", nil];
			[self postNotificationWithName:kRepositoryIdentityChanged userInfo:info];
			[dirtyRepositoryIdentityForPath_ synchronizedRemoveObjectForKey:path];
			//DebugLog(@"Root changeset of %@ is %@ on attempt %d", path, repositoryIdentity, attempts);
			return;
		}

		//if ([theTask isRunning])
		//	DebugLog(@"Determining root changeset for the repository at %@ timed out after %f seconds on attempt %d", path, timeOutInSeconds, attempts);
		//else
		//	DebugLog(@"Unable to determine root changeset for the repository at %@ on attempt %d", path, attempts);
		
		[theTask cancelTask];
	});
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Server Path Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

NSString* FullServerURL(NSString* baseURLString, PasswordVisibilityType visibility)
{
	NSString* password = nil;
	NSURL* baseURL = [NSURL URLWithString:baseURLString];
	if (!baseURL || ![baseURL scheme] || ![baseURL host])
		return baseURLString;

	EMGenericKeychainItem* newKeychainItem = [EMGenericKeychainItem genericKeychainItemForService:kMacHgApp withUsername:baseURLString];
	BOOL hasPassword = newKeychainItem || [baseURL password];
	if (hasPassword && visibility == eAllPasswordsAreMangled)
		password = @"***";
	else if (newKeychainItem && visibility == eKeyChainPasswordsAreMangled)
		password = @"***";
	else if (newKeychainItem)
		password = nonNil(newKeychainItem.password);
	else
		password = [baseURL password];

	NSString* fullURLString = [[baseURL URLByReplacingPassword:password] absoluteString];
	return fullURLString ? fullURLString : baseURLString;
}



