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
#import "AboutWindowController.h"
#import "LogEntry.h"
#import "LogRecord.h"
#import "EMKeychainItem.h"
#import "NSURL+Parameters.h"

NSString* kKeyPathUseWhichToolForDiffing = @"values.UseWhichToolForDiffing";
NSString* kKeyPathUseWhichToolForMerging = @"values.UseWhichToolForMerging";




@interface AppController (PrivateAPI)
- (void) checkDiffTool;
- (void) checkMergeTool;
- (NSString*) bundleIdentiferForDiffTool: (ToolForDiffing)tool;
- (NSString*) bundleIdentiferForMergeTool:(ToolForMerging)tool;
@end

@implementation AppController

@synthesize repositoryIdentityForPath = repositoryIdentityForPath_;





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

	configurationForProgress = [NSArray arrayWithObjects:@"--config", @"extensions.progress=", @"--config", @"progress.delay=0.5", @"--config", @"progress.format=number", @"--config", @"progress.assume-tty=True", @"--config", @"progress.refresh=0.25", nil];
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
	NSColor* darkGreen = [NSColor colorWithCalibratedRed:0.0  green:0.35 blue:0.0 alpha:1.0];
	NSColor* fadedRed   = [NSColor colorWithCalibratedRed:0.5 green:0.0  blue:0.0 alpha:0.4];

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

	standardMissingSidebarFontAttributes = [NSDictionary dictionaryWithObjectsAndKeys: smallSystemFont, NSFontAttributeName, fadedRed, NSForegroundColorAttributeName, ps, NSParagraphStyleAttributeName, nil];
}

- (id) init
{
	self = [super init];
	applicationHasStarted = NO;
	repositoryIdentityForPath_			= [[NSMutableDictionary alloc]init];
	computingRepositoryIdentityForPath_ = [[NSMutableDictionary alloc]init];
	dirtyRepositoryIdentityForPath_     = [[NSMutableDictionary alloc]init];

	// Initlize globals
	changesetHashToLogRecord			= [[NSMutableDictionary alloc]init];

	// Receive a notification when the diff tool and merge tool change in the preferences.
	id defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[defaults  addObserver:self  forKeyPath:kKeyPathUseWhichToolForDiffing	options:NSKeyValueObservingOptionNew  context:NULL];
	[defaults  addObserver:self  forKeyPath:kKeyPathUseWhichToolForMerging	options:NSKeyValueObservingOptionNew  context:NULL];
	
	return self;
}

- (void) observeValueForKeyPath:(NSString*)keyPath  ofObject:(id)object  change:(NSDictionary*)change  context:(void*)context
{
    if ([keyPath isEqualToString:kKeyPathUseWhichToolForDiffing])
		[self checkDiffTool];
    if ([keyPath isEqualToString:kKeyPathUseWhichToolForMerging])
		[self checkMergeTool];
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

- (AboutWindowController*) theAboutWindowController
{
	if (!theAboutWindowController_)
		theAboutWindowController_ = [[AboutWindowController alloc] initAboutWindowController];
	return theAboutWindowController_;
}




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Version Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) shortVersionNumberString	{ return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; }
- (NSString*) shortVersionString		{ return fstr(@"Version:%@", [self shortVersionNumberString]); }
- (NSString*) shortMacHgVersionString	{ return fstr(@"MacHg %@", [self shortVersionNumberString]); }

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

- (NSComparisonResult) bundleVersion:(NSString*)vOne comparedTo:(NSString*)vTwo
{
	if (!vOne && !vTwo)
		return NSOrderedSame;
	if (!vOne && vTwo)
		return NSOrderedAscending;
	if (!vTwo && vOne)
		return NSOrderedDescending;
	
	NSString* majorOneStr = nil;
	NSString* minorOneStr = nil;
	NSString* pointOneStr = nil;
	BOOL parsedOneStr = [vOne getCapturesWithRegexAndTrimedComponents:@"^\\s*(\\d+)\\.(\\d+)\\.(\\d+)" firstComponent:&majorOneStr  secondComponent:&minorOneStr  thirdComponent:&pointOneStr];
	if (!parsedOneStr)
		return NSOrderedAscending;
	
	NSString* majorTwoStr = nil;
	NSString* minorTwoStr = nil;
	NSString* pointTwoStr = nil;	
	BOOL parsedTwoStr = [vTwo getCapturesWithRegexAndTrimedComponents:@"^\\s*(\\d+)\\.(\\d+)\\.(\\d+)" firstComponent:&majorTwoStr  secondComponent:&minorTwoStr  thirdComponent:&pointTwoStr];
	if (!parsedTwoStr)
		return NSOrderedDescending;
	
	if ([majorOneStr intValue] < [majorTwoStr intValue])
		return NSOrderedAscending;
	if ([majorOneStr intValue] > [majorTwoStr intValue])
		return NSOrderedDescending;
	
	if ([minorOneStr intValue] < [minorTwoStr intValue])
		return NSOrderedAscending;
	if ([minorOneStr intValue] > [minorTwoStr intValue])
		return NSOrderedDescending;
	
	if ([pointOneStr intValue] < [pointTwoStr intValue])
		return NSOrderedAscending;
	if ([pointOneStr intValue] > [pointTwoStr intValue])
		return NSOrderedDescending;
	
	return NSOrderedSame;
}



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Configuration Checking
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) ensureFileExists:(NSString*)filePath orCopyFromBundleResource:(NSString*)resourceName
{
	NSError* err = nil;
	if (pathIsExistent(filePath))
		return;
	
	NSFileManager* fileManager = [NSFileManager defaultManager];

	if (!pathIsExistent([filePath stringByDeletingLastPathComponent]))
	{
		[fileManager createDirectoryAtPath:[filePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&err];
		[NSApp presentAnyErrorsAndClear:&err];
	}

	NSString* sourcePath = fstr(@"%@/%@",[[NSBundle mainBundle] resourcePath], resourceName);
	[fileManager copyItemAtPath:sourcePath toPath:filePath error:&err];
	[NSApp presentAnyErrorsAndClear:&err];
}


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


- (void) checkForOutdatedSupportFiles
{
	NSString* currentBundleString = [self shortVersionNumberString];
	NSString* mostModernMacHgVersionExecuted = [[NSUserDefaults standardUserDefaults] stringForKey:@"MostModernMacHgVersionExecuted"];
	BOOL replacedHgrc = NO;
	BOOL replacedHgignore = NO;
	BOOL olderVersionThan_0_9_20 = ([self bundleVersion:mostModernMacHgVersionExecuted comparedTo:@"0.9.20"] == NSOrderedAscending);
	BOOL olderVersionThan_0_9_24 = ([self bundleVersion:mostModernMacHgVersionExecuted comparedTo:@"0.9.24"] == NSOrderedAscending);
	BOOL olderThanCurent = ([self bundleVersion:mostModernMacHgVersionExecuted comparedTo:currentBundleString] == NSOrderedAscending);
	if (olderVersionThan_0_9_24)
	{
		NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
		if (pathIsExistent(macHgHGRCFilePath))
		{
			moveFilesToTheTrash([NSArray arrayWithObject:macHgHGRCFilePath]);
			replacedHgrc = YES;
		}
	}	
	if (olderVersionThan_0_9_20)
	{
		NSString* macHgIgnoreFilePath = fstr(@"%@/hgignore",applicationSupportFolder());
		if (pathIsExistent(macHgIgnoreFilePath))
		{
			moveFilesToTheTrash([NSArray arrayWithObject:macHgIgnoreFilePath]);
			replacedHgignore = YES;
		}
	}

	if (olderThanCurent)
		[[NSUserDefaults standardUserDefaults] setObject:currentBundleString forKey:@"MostModernMacHgVersionExecuted"];

	if (replacedHgrc || replacedHgignore)
	{
		NSString* titleMessage = replacedHgrc ? @"Updated Configuration Files" : @"Updated Ignore File";
		NSString* bodyMessage = nil;
		if (replacedHgrc && replacedHgignore)
			bodyMessage = fstr(@"MacHg's configuration files 'hgrc' and 'hgignore' located in %@ have been updated.\n\nThe old configuration files have been moved to the trash. If you made any personal modifications to these support files for specific tools or extensions outside MacHg then you may need to replicate these changes in the updated files.", applicationSupportFolder());
		else if (replacedHgrc)
			bodyMessage = fstr(@"MacHg's configuration file 'hgrc' located in %@ has been updated.\n\nThe old configuration file has been moved to the trash. If you made any personal modifications to this support file for specific tools or extensions outside MacHg then you may need to replicate these changes in the updated file.", applicationSupportFolder());
		else if (replacedHgignore)
			bodyMessage = fstr(@"MacHg's ignore file 'hgignore' located in %@ has been updated.\n\nThe old ignore file has been moved to the trash. If you made any personal modifications to this support file for specific tools or extensions outside MacHg then you may need to replicate these changes in the updated file.", applicationSupportFolder());
		NSRunCriticalAlertPanel(titleMessage, bodyMessage, @"OK", @"", @"");
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

	// If the ~/.hgignore exists then make sure ~/Application Support/MacHg/hgrc points to it
	if (pathIsExistent(userHgignorePath))
	{
		NSMutableArray* argsCedit = [NSMutableArray arrayWithObjects:@"cedit", @"--config", @"extensions.cedit=", @"--add", fstr(@"ui.ignore = %@", userHgignorePath), @"--file", macHgHGRCFilePath, nil];
		[TaskExecutions executeMercurialWithArgs:argsCedit  fromRoot:@"/tmp"];
	}

	NSString* macHgIgnoreFilePath = fstr(@"%@/hgignore",applicationSupportFolder());
	[self ensureFileExists:macHgIgnoreFilePath orCopyFromBundleResource:@"hgignore"];

	NSMutableArray* argsCedit = [NSMutableArray arrayWithObjects:@"cedit", @"--config", @"extensions.cedit=", @"--add", fstr(@"ui.ignore.other = %@", macHgIgnoreFilePath), @"--file", macHgHGRCFilePath, nil];
	[TaskExecutions executeMercurialWithArgs:argsCedit  fromRoot:@"/tmp"];
}


- (void) checkForTrustedCertificates
{
	[self includeHomeHGRC:NO inProcess:^{
		NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
		NSString* macHgCertFilePath = fstr(@"%@/TrustedCertificates.pem",applicationSupportFolder());

		[self ensureFileExists:macHgCertFilePath orCopyFromBundleResource:@"TrustedCertificates.pem"];

		// Determine current configuration:
		NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", @"web.cacerts", nil];
		ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
		
		// If we currently don't have a certificate then point to our TrustedCertificates
		if ([result hasErrors] || [result hasWarnings] || IsEmpty([result outStr]))
		{
			NSMutableArray* argsCedit = [NSMutableArray arrayWithObjects:@"cedit", @"--config", @"extensions.cedit=", @"--add", fstr(@"web.cacerts = %@", macHgCertFilePath), @"--file", macHgHGRCFilePath, nil];
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

- (void) checkForFileMerge
{
	if (UseWhichToolForDiffingFromDefaults() != eUseFileMergeForDiffs && UseWhichToolForMergingFromDefaults() != eUseFileMergeForMerges)
		return;
	if (![[NSWorkspace sharedWorkspace] fullPathForApplication:@"FileMerge"])
	{
		if (pathIsExistent(@"/Developer/Applications/Utilities/FileMerge.app"))
			[[NSWorkspace sharedWorkspace] launchApplicationAtURL:[NSURL fileURLWithPath:@"/Developer/Applications/Utilities/FileMerge.app"] options:NSWorkspaceLaunchAsync|NSWorkspaceLaunchAndHide configuration:nil error:nil];
		else
			NSRunCriticalAlertPanel(@"FileMerge not found", @"FileMerge was not found on this system. Please install the full developer tools from the system disk which came with your computer (they contain the application FileMerge). (Alternatively you can install a different diffing and merging tool and select it in the preferences.) (Sometimes you need to run FileMerge once so that OSX \"recognizes it exists\".)", @"OK", nil, nil);
	}
	if (!pathIsExistent(@"/usr/bin/opendiff") && !pathIsExistent(@"/Developer/usr/bin/opendiff"))
		NSRunCriticalAlertPanel(@"Opendiff not found", @"Neither /usr/bin/opendiff nor /Developer/usr/bin/opendiff was found on this system. Please install the full developer tools from the system disk which came with your computer (they contain the application FileMerge). (Alternatively you can install a different diffing and merging tool and select it in the preferences.).", @"OK", nil, nil);
}

- (void) checkForAraxisScripts
{
	// Make sure ~/Application Support/MacHg/AraxisScripts scripts exists
	NSString* araxishgmergePath = fstr(@"%@/AraxisScripts/araxishgmerge",applicationSupportFolder());
	[self ensureFileExists:araxishgmergePath orCopyFromBundleResource:@"araxishgmerge"];
	NSString* araxiscomparePath = fstr(@"%@/AraxisScripts/araxiscompare",applicationSupportFolder());
	[self ensureFileExists:araxiscomparePath orCopyFromBundleResource:@"araxiscompare"];
}



- (void) checkForMercurialWarningsAndErrors
{
	NSArray* versionArgs = [NSArray arrayWithObject:@"version"];
	NSString* hgBinary = executableLocationHG();
	ExecutionResult* results = [ShellTask execute:hgBinary withArgs:versionArgs withEnvironment:[TaskExecutions environmentForHg]];
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
// MARK:  Common External Tool Support
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) preLaunchApplicationWithBundleIdentifier:(NSString*)bundleIdentifier
{
	if (!bundleIdentifier)
		return;
	
	NSArray* runningApplications = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
	if (IsNotEmpty(runningApplications))
		return;
	
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:bundleIdentifier options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:nil];
}

-(void) installExtToolConfiguration:(NSString*)configurationString forApplicationWithBundleID:(NSString*)bundleIdentifier
{
	if (!bundleIdentifier)
		return;
	NSString* toolPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleIdentifier];
	if (!toolPath)
		return;
	NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
	NSString* macHgBundleResourcePath = [[NSBundle mainBundle] resourcePath];
	NSString* configurationString1 = [configurationString  stringByReplacingOccurrencesOfRegex:@"TOOL_PATH" withString:toolPath];
	NSString* configurationString2 = [configurationString1 stringByReplacingOccurrencesOfRegex:@"MACHG_RESOURCE_PATH" withString:macHgBundleResourcePath];
	NSMutableArray* argsCedit = [NSMutableArray arrayWithObjects:@"cedit", @"--config", @"extensions.cedit=", @"--add", configurationString2, @"--file", macHgHGRCFilePath, nil];
	[TaskExecutions executeMercurialWithArgs:argsCedit  fromRoot:@"/tmp"];
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: External Diff Tool Support
// -----------------------------------------------------------------------------------------------------------------------------------------


- (void) checkAvailbilityOfDiffTool:(ToolForDiffing)tool
{
	BOOL revert = NO;
	NSString* applicationName  = [self applicationNameForDiffTool:tool];
	NSString* bundleIdentifier = [self bundleIdentiferForDiffTool:tool];
	if (!applicationName || !bundleIdentifier)
		return;

	if ((tool == eUseP4MergeForDiffs) && !pathIsExistent(@"/Applications/p4merge.app"))
	{
		NSString* path = @"/Applications/p4merge.app";
		NSRunCriticalAlertPanel(fstr(@"%@ not found", applicationName), fstr(@"%@ was not found at %@. Please download and install %@ and place it at %@ in order to view diffs using %@.", applicationName, path, applicationName, path, applicationName), @"OK", nil, nil);
		revert = YES;
	}
	
	if (!revert && ![[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleIdentifier])
	{
		NSRunCriticalAlertPanel(fstr(@"%@ not found", applicationName), fstr(@"%@ was not found on this system. Please download and install %@ in order to view diffs using %@.", applicationName, applicationName, applicationName), @"OK", nil, nil);
		revert = YES;
	}

	if (!revert && (tool == eUseKaleidoscopeForDiffs) && !pathIsExistentFile(@"/usr/local/bin/ksdiff-wrapper"))
	{
		NSRunCriticalAlertPanel(fstr(@"%@ scripts not found", applicationName), @"The Kaleidoscope scripts are not installed on this system. Please open Kaleidoscope and install the Kaleidoscope Command Line Tool from the menu Kaleidoscope > Integration... in order to use Kaleidoscope with MacHg.", @"OK", nil, nil);
		revert = YES;
	}

	if (revert)
		dispatch_async(globalQueue(), ^{
			usleep(0.3 * USEC_PER_SEC);
			[[NSUserDefaults standardUserDefaults] setInteger:eUseNothingForDiffs forKey:MHGUseWhichToolForDiffing];
		});
}


- (NSString*) bundleIdentiferForDiffTool:(ToolForDiffing)tool
{
	switch (tool)
	{
		case eUseFileMergeForDiffs:			return @"com.apple.FileMerge";
		case eUseAraxisMergeForDiffs:		return @"com.araxis.merge";
		case eUseP4MergeForDiffs:			return @"com.perforce.p4merge";
		case eUseDiffMergeForDiffs:			return @"com.sourcegear.DiffMerge";
		case eUseKDiff3ForDiffs:			return @"com.yourcompany.kdiff3";
		case eUseDelatWalkerForDiffs:		return @"com.deltopia.deltawalker";
		case eUseKaleidoscopeForDiffs:		return @"com.madebysofa.Kaleidoscope";
		case eUseChangesForDiffs:			return @"com.skorpiostech.Changes";
		case eUseBBEditForDiffs:			return @"com.barebones.bbedit";
		case eUseTextWranglerForDiffs:		return @"com.barebones.textwrangler";
		case eUseDiffForkForDiffs:			return @"com.dotfork.DiffFork";
		default:							return nil;
	}
	return nil;
}


- (NSString*) scriptNameForDiffTool:(ToolForDiffing)tool
{
	switch (tool)
	{
		case eUseFileMergeForDiffs:			return @"opendiff";
		case eUseAraxisMergeForDiffs:		return @"arxdiff";
		case eUseP4MergeForDiffs:			return @"p4diff";
		case eUseDiffMergeForDiffs:			return @"diffmerge";
		case eUseKDiff3ForDiffs:			return @"kdiff3";
		case eUseDelatWalkerForDiffs:		return @"deltawalker";
		case eUseKaleidoscopeForDiffs:		return @"ksdiff";
		case eUseChangesForDiffs:			return @"chdiff";
		case eUseDiffForkForDiffs:			return @"dfdiff";
		case eUseBBEditForDiffs:			return @"bbdiff";
		case eUseTextWranglerForDiffs:		return @"twdiff";
		case eUseOtherForDiffs:				return ToolNameForDiffingFromDefaults();
		default:							return @"diff";
	}
	return nil;
}

- (NSString*) applicationNameForDiffTool:(ToolForDiffing)tool
{
	switch (tool)
	{
		case eUseFileMergeForDiffs:			return @"FileMerge";
		case eUseAraxisMergeForDiffs:		return @"Araxis Merge";
		case eUseP4MergeForDiffs:			return @"p4merge";
		case eUseDiffMergeForDiffs:			return @"DiffMerge";
		case eUseKDiff3ForDiffs:			return @"kdiff3";
		case eUseDelatWalkerForDiffs:		return @"DeltaWalker";
		case eUseKaleidoscopeForDiffs:		return @"Kaleidoscope";
		case eUseChangesForDiffs:			return @"Changes";
		case eUseDiffForkForDiffs:			return @"DiffFork";
		case eUseBBEditForDiffs:			return @"BBEdit";
		case eUseTextWranglerForDiffs:		return @"TextWrangler";
		default:							return nil;
	}
	return nil;
}

- (BOOL) diffToolNeedsPreLaunch:(ToolForDiffing)tool
{
	switch (tool)
	{
		case eUseFileMergeForDiffs:			return NO;
		case eUseAraxisMergeForDiffs:		return YES;
		case eUseP4MergeForDiffs:			return YES;
		case eUseDiffMergeForDiffs:			return NO;
		case eUseKDiff3ForDiffs:			return NO;
		case eUseDelatWalkerForDiffs:		return NO;
		case eUseKaleidoscopeForDiffs:		return NO;
		case eUseChangesForDiffs:			return NO;
		case eUseDiffForkForDiffs:			return NO;
		case eUseBBEditForDiffs:			return YES;
		case eUseTextWranglerForDiffs:		return YES;
		default:							return NO;
	}
	return NO;
}

- (BOOL) diffToolWantsGroupedFiles:(ToolForDiffing)tool
{
	switch (tool)
	{
		case eUseFileMergeForDiffs:			return NO;
		case eUseAraxisMergeForDiffs:		return NO;
		case eUseP4MergeForDiffs:			return NO;
		case eUseDiffMergeForDiffs:			return YES;
		case eUseKDiff3ForDiffs:			return YES;
		case eUseDelatWalkerForDiffs:		return YES;
		case eUseKaleidoscopeForDiffs:		return YES;
		case eUseChangesForDiffs:			return NO;
		case eUseDiffForkForDiffs:			return NO;
		case eUseBBEditForDiffs:			return NO;
		case eUseTextWranglerForDiffs:		return NO;
		default:							return NO;
	}
	return NO;
}

- (void) preLaunchDiffToolIfNeeded:(ToolForDiffing)tool
{
	if (![self diffToolNeedsPreLaunch:tool])
		return;
	[self preLaunchApplicationWithBundleIdentifier:[self bundleIdentiferForDiffTool:tool]];
}


- (void) installExtDiffToolConfiguration:(NSString*)configurationString forTool:(ToolForDiffing)tool
{
	[self installExtToolConfiguration:configurationString forApplicationWithBundleID:[self bundleIdentiferForDiffTool:tool]];
}

- (void) checkDiffTool
{
	ToolForDiffing tool = UseWhichToolForDiffingFromDefaults();
	switch (tool)
	{
		case eUseFileMergeForDiffs:			[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.opendiff = MACHG_RESOURCE_PATH/fmdiff.sh"						forTool:tool];		break;
		case eUseAraxisMergeForDiffs:		[self checkAvailbilityOfDiffTool:tool];																																				break;
		case eUseP4MergeForDiffs:			[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.p4diff = TOOL_PATH/Contents/Resources/launchp4merge"			forTool:tool];		break;
		case eUseDiffMergeForDiffs:			[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.diffmerge = TOOL_PATH/Contents/MacOS/DiffMerge"					forTool:tool];		break;
		case eUseKDiff3ForDiffs:			[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.kdiff3 = TOOL_PATH/Contents/MacOS/kdiff3"						forTool:tool];		break;
		case eUseDelatWalkerForDiffs:		[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.deltawalker = TOOL_PATH/Contents/MacOS/hg"						forTool:tool];		break;
		case eUseKaleidoscopeForDiffs:		[self checkAvailbilityOfDiffTool:tool];																																				break;
		case eUseChangesForDiffs:			[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.chdiff = TOOL_PATH/Contents/Resources/chdiff"					forTool:tool];		break;
		case eUseDiffForkForDiffs:			[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.dfdiff = TOOL_PATH/Contents/SharedSupport/Support/bin/difffork"	forTool:tool];		break;
		case eUseBBEditForDiffs:			[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.bbdiff = TOOL_PATH/Contents/MacOS/bbdiff"						forTool:tool];		break;
		case eUseTextWranglerForDiffs:		[self checkAvailbilityOfDiffTool:tool];		[self installExtDiffToolConfiguration:@"extdiff.cmd.twdiff = TOOL_PATH/Contents/MacOS/twdiff"						forTool:tool];		break;
		default:							break;
	}
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: External Merge Tool Support
// -----------------------------------------------------------------------------------------------------------------------------------------


- (void) checkAvailbilityOfMergeTool:(ToolForMerging)tool
{
	BOOL revert = NO;
	NSString* applicationName  = [self applicationNameForMergeTool:tool];
	NSString* bundleIdentifier = [self bundleIdentiferForMergeTool:tool];
	if (!applicationName || !bundleIdentifier)
		return;
	
	if ((tool == eUseP4MergeForMerges) && !pathIsExistent(@"/Applications/p4merge.app"))
	{
		NSString* path = @"/Applications/p4merge.app";
		NSRunCriticalAlertPanel(fstr(@"%@ not found", applicationName), fstr(@"%@ was not found at %@. Please download and install %@ and place it at %@ in order to view merges using %@.", applicationName, path, applicationName, path, applicationName), @"OK", nil, nil);
		revert = YES;
	}
	
	if (!revert && ![[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleIdentifier])
	{
		NSRunCriticalAlertPanel(fstr(@"%@ not found", applicationName), fstr(@"%@ was not found on this system. Please download and install %@ in order to view merges using %@.", applicationName, applicationName, applicationName), @"OK", nil, nil);
		revert = YES;
	}

	if (revert)
		dispatch_async(globalQueue(), ^{
			usleep(0.3 * USEC_PER_SEC);
			[[NSUserDefaults standardUserDefaults] setInteger:eUseNothingForMerges forKey:MHGUseWhichToolForMerging];
		});
}


- (NSString*) bundleIdentiferForMergeTool:(ToolForMerging)tool
{
	switch (tool)
	{
		case eUseFileMergeForMerges:		return @"com.apple.FileMerge";
		case eUseAraxisMergeForMerges:		return @"com.araxis.merge";
		case eUseP4MergeForMerges:			return @"com.perforce.p4merge";
		case eUseDiffMergeForMerges:		return @"com.sourcegear.DiffMerge";
		case eUseKDiff3ForMerges:			return @"com.yourcompany.kdiff3";
		case eUseDelatWalkerForMerges:		return @"com.deltopia.deltawalker";
		case eUseChangesForMerges:			return @"com.skorpiostech.Changes";
		default:							return nil;
	}
	return nil;
}


- (NSString*) scriptNameForMergeTool:(ToolForMerging)tool
{
	switch (tool)
	{
		case eUseFileMergeForMerges:		return @"opendiff";
		case eUseAraxisMergeForMerges:		return @"arxmerge";
		case eUseP4MergeForMerges:			return @"p4merge";
		case eUseDiffMergeForMerges:		return @"diffmerge";
		case eUseKDiff3ForMerges:			return @"kdiff3";
		case eUseDelatWalkerForMerges:		return @"deltawalker";
		case eUseChangesForMerges:			return @"changes";
		case eUseOtherForMerges:			return ToolNameForMergingFromDefaults();
		default:							return nil;
	}
	return nil;
}

- (NSString*) applicationNameForMergeTool:(ToolForMerging)tool
{
	switch (tool)
	{
		case eUseFileMergeForMerges:		return @"FileMerge";
		case eUseAraxisMergeForMerges:		return @"Araxis Merge";
		case eUseP4MergeForMerges:			return @"p4merge";
		case eUseDiffMergeForMerges:		return @"DiffMerge";
		case eUseKDiff3ForMerges:			return @"kdiff3";
		case eUseChangesForMerges:			return @"Changes";
		case eUseDelatWalkerForMerges:		return @"DeltaWalker";
		default:							return nil;
	}
	return nil;
}

- (BOOL) mergeToolNeedsPreLaunch:(ToolForMerging)tool
{
	switch (tool)
	{
		case eUseFileMergeForMerges:		return NO;
		case eUseAraxisMergeForMerges:		return YES;
		case eUseP4MergeForMerges:			return YES;
		case eUseDiffMergeForMerges:		return NO;
		case eUseKDiff3ForMerges:			return NO;
		case eUseChangesForMerges:			return NO;
		case eUseDelatWalkerForMerges:		return NO;
		default:							return NO;
	}
	return NO;
}

- (BOOL) mergeToolWantsGroupedFiles:(ToolForMerging)tool
{
	switch (tool)
	{
		case eUseFileMergeForMerges:		return NO;
		case eUseAraxisMergeForMerges:		return NO;
		case eUseP4MergeForMerges:			return NO;
		case eUseDiffMergeForMerges:		return NO;
		case eUseKDiff3ForMerges:			return NO;
		case eUseChangesForMerges:			return NO;
		case eUseDelatWalkerForMerges:		return NO;
		default:							return NO;
	}
	return NO;
}

- (void) preLaunchMergeToolIfNeeded:(ToolForMerging)tool
{
	if (![self mergeToolNeedsPreLaunch:tool])
		return;
	[self preLaunchApplicationWithBundleIdentifier:[self bundleIdentiferForMergeTool:tool]];
}


- (void) installExtMergeToolConfiguration:(NSString*)configurationString forTool:(ToolForMerging)tool
{
	[self installExtToolConfiguration:configurationString forApplicationWithBundleID:[self bundleIdentiferForMergeTool:tool]];
}

- (void) checkMergeTool
{
	ToolForMerging tool = UseWhichToolForMergingFromDefaults();
	switch (tool)
	{
		case eUseFileMergeForMerges:	[self checkAvailbilityOfMergeTool:tool];	[self installExtMergeToolConfiguration:@"merge-tools.opendiff.executable = MACHG_RESOURCE_PATH/opendiff-w.sh"			forTool:tool];		break;
		case eUseAraxisMergeForMerges:	[self checkAvailbilityOfMergeTool:tool];																																				break;
		case eUseP4MergeForMerges:		[self checkAvailbilityOfMergeTool:tool];	[self installExtMergeToolConfiguration:@"merge-tools.p4merge.executable = TOOL_PATH/Contents/Resources/launchp4merge"	forTool:tool];		break;
		case eUseDiffMergeForMerges:	[self checkAvailbilityOfMergeTool:tool];	[self installExtMergeToolConfiguration:@"merge-tools.diffmerge.executable = TOOL_PATH/Contents/MacOS/DiffMerge"			forTool:tool];		break;
		case eUseKDiff3ForMerges:		[self checkAvailbilityOfMergeTool:tool];	[self installExtMergeToolConfiguration:@"merge-tools.kdiff3.executable = TOOL_PATH/Contents/MacOS/kdiff3"				forTool:tool];		break;
		case eUseDelatWalkerForMerges:	[self checkAvailbilityOfMergeTool:tool];	[self installExtMergeToolConfiguration:@"merge-tools.deltawalker.executable = TOOL_PATH/Contents/MacOS/hg"				forTool:tool];		break;
		case eUseChangesForMerges:		[self checkAvailbilityOfMergeTool:tool];	[self installExtMergeToolConfiguration:@"merge-tools.changes.executable = TOOL_PATH/Contents/Resources/chdiff"			forTool:tool];		break;
		default:						break;
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
	[ShellTask execute:@"/bin/mv" withArgs:[NSArray arrayWithObjects:@"-f", MacHgLogFileLocation(), oldMacHgLogFileLocation, nil]];
}


- (void) applicationDidFinishLaunching:(NSNotification*)aNotification
{
	// Increment launch count
	NSInteger launchCount = [[NSUserDefaults standardUserDefaults] integerForKey:MHGLaunchCount];
	[[NSUserDefaults standardUserDefaults] setInteger:launchCount +1 forKey:MHGLaunchCount];

	[self checkForOutdatedSupportFiles];
	[self checkForSupportDirectory];
	[self checkForConfigFile];
	[self checkForIgnoreFile];
	[self checkForTrustedCertificates];
	[self checkConfigFileForUserName];
	[self checkForFileMerge];
	[self checkForAraxisScripts];
	[self checkForMercurialWarningsAndErrors];
	[self checkDiffTool];
	[self checkMergeTool];
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

- (IBAction) showAboutBox:(id)sender	{ [[self theAboutWindowController] showAboutWindow]; }





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


- (void) computeRepositoryIdentityForPath:(NSString*)path
{
	[self computeRepositoryIdentityForPath:path forNodePath:path];
}

- (void) computeRepositoryIdentityForPath:(NSString*)path forNodePath:(NSString*)nodePath
{
	if (!path)
		return;
	
	NSString* fullPath = FullServerURL(path, eAllPasswordsAreVisible);

	// If we are already computing the root changeset then don't compute it again
	if ([computingRepositoryIdentityForPath_ synchronizedObjectForKey:nodePath])
		return;
	
	// Indicate that we are now about to compute the root changeset of the path
	[computingRepositoryIdentityForPath_ synchronizedSetObject:YESasNumber forKey:nodePath];
	
	// Find out how many times we have tried to compute the path before.
	id val = [dirtyRepositoryIdentityForPath_ synchronizedObjectForKey:nodePath];
	if ([val isEqual:@"uncomputable"])
		return;
	
	// Increment the attempt number.
	int attempts = numberAsInt(DynamicCast(NSNumber, val)) + 1;
	[dirtyRepositoryIdentityForPath_ synchronizedSetObject:intAsNumber(attempts) forKey:nodePath];
	
	// If we have attempted too many times to compute the root just give up and mark it "uncomputable"
	if (attempts > 6)
	{
		[dirtyRepositoryIdentityForPath_ synchronizedSetObject:@"uncomputable" forKey:nodePath];
		return;
	}

	NSTimeInterval timeOutInSeconds = 5.0 * pow(2.0, attempts);
	
	dispatch_async(globalQueue(), ^{
		NSMutableArray* argsIdentify = [NSMutableArray arrayWithObjects:@"identify", @"--insecure", @"--noninteractive", @"--rev", @"0", @"--id", @"--quiet", fullPath, nil];
		__block ShellTaskController* theTaskController = [[ShellTaskController alloc]init];
		__block ExecutionResult* results;
		dispatchWithTimeOut(globalQueue(), timeOutInSeconds, ^{
			results = [TaskExecutions executeMercurialWithArgs:argsIdentify fromRoot:@"/tmp" logging:eLoggingNone withDelegate:theTaskController];
		});

		[computingRepositoryIdentityForPath_ synchronizedRemoveObjectForKey:nodePath];
	
		if (![[theTaskController shellTask] isRunning] && results.result == 0 && IsEmpty(results.errStr) && IsNotEmpty(results.outStr))
		{
			// We look for the 12 digit hashKey which is optionally seperated from other bits by whitespace.
			static NSString* pickOutHashKeyRegex = @"^(.*\\s+)?([0-9abcdefABCDEF]{12})(\\s+.*)?$";
			NSString* newRepositoryIdentity;
			BOOL matched = [results.outStr getCapturesWithRegexAndComponents:pickOutHashKeyRegex firstComponent:nil secondComponent:&newRepositoryIdentity thirdComponent:nil];
			if (!matched)
				return;

			NSString* oldRepositoryIdentity = [repositoryIdentityForPath_ synchronizedObjectForKey:nodePath];
			[repositoryIdentityForPath_ synchronizedSetObject:newRepositoryIdentity forKey:nodePath];
			if (!oldRepositoryIdentity || [oldRepositoryIdentity isNotEqualToString:newRepositoryIdentity])
			{
				NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:nodePath, @"path", newRepositoryIdentity, @"repositoryIdentity", nil];
				[self postNotificationWithName:kRepositoryIdentityChanged userInfo:info];
			}
			[dirtyRepositoryIdentityForPath_ synchronizedRemoveObjectForKey:nodePath];
			//DebugLog(@"Root changeset of %@ is %@ on attempt %d", path, repositoryIdentity, attempts);
			return;
		}

		//if ([[theTaskController task] isRunning])
		//	DebugLog(@"Determining root changeset for the repository at %@ timed out after %f seconds on attempt %d", path, timeOutInSeconds, attempts);
		//else
		//	DebugLog(@"Unable to determine root changeset for the repository at %@ on attempt %d", path, attempts);
		
		[[theTaskController shellTask] cancelTask];
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



