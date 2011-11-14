//
//  TaskExecutions.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "TaskExecutions.h"



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  ShellTaskController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation ShellTaskController
@synthesize shellTask = shellTask_;
- (void)	shellTaskCreated:(ShellTask*)shellTask	{ shellTask_ = shellTask; }
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  ShellTask
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface ShellTask (PrivateAPI)
- (NSString*) commandLineString;
@end


@implementation ShellTask


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Handling
// -----------------------------------------------------------------------------------------------------------------------------------------

- (NSString*) commandLineString
{
    NSMutableString* desc = [NSMutableString stringWithString:[[self launchPath] lastPathComponent]];
    for (NSString* arg in [self arguments])
	{
        [desc appendString:@" "];
        [desc appendString:arg];
    }
    return desc;
}


// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  Execution
// -----------------------------------------------------------------------------------------------------------------------------------------

- (void) gotOutputBytes:(char*)bytes ofLength:(size_t)len
{
	//DebugLog(@"got output %@ ", [[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding]);
	if ([delegate_ respondsToSelector:@selector(gotOutput:)])
		[delegate_ gotOutput:[[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding]];
}

- (void) gotErrorBytes:(char*)bytes ofLength:(size_t)len
{
	//DebugLog(@"got error '%@' with length %d", [[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding], len);
	if ([delegate_ respondsToSelector:@selector(gotError:)])
		[delegate_ gotError:[[NSString alloc] initWithBytes:bytes length:len encoding:NSUTF8StringEncoding]];
}


- (id) initWithCommand:(NSString*)cmd andArgs:(NSArray*)args withEnvironment:(NSDictionary*)env withDelegate:(id <ShellTaskDelegate>)delegate
{
	if ((self = [super init]))
	{
		delegate_ = delegate;
		if (env)
			[self setEnvironment:env];
		[self setLaunchPath:cmd];
		[self setArguments:args];
	}
	return self;
}

NSString* filterProgressOutOfErrorString(NSString* rawErrorStr)
{
	NSString* replaced = [rawErrorStr stringByReplacingOccurrencesOfRegex:@"(?m-s)^MHGProgress:.*?$" withString:@""];
	return [replaced stringByReplacingOccurrencesOfRegex:@"(?m)\n\n\n*" withString:@"\n\n"];
}

+ (ExecutionResult*) execute:(NSString*)cmd withArgs:(NSArray*)args										{ return [self execute:cmd withArgs:args withEnvironment:nil withDelegate:nil]; }
+ (ExecutionResult*) execute:(NSString*)cmd withArgs:(NSArray*)args	withEnvironment:(NSDictionary*)env	{ return [self execute:cmd withArgs:args withEnvironment:env withDelegate:nil]; }
+ (ExecutionResult*) execute:(NSString*)cmd withArgs:(NSArray*)args withEnvironment:(NSDictionary*)env withDelegate:(id <ShellTaskDelegate>)delegate
{
	ShellTask* shellTask;
	int repeats = 0;
	NSString* outStr = nil;
	NSString* errStr = nil;

	do {
		shellTask = [[ShellTask alloc] initWithCommand:cmd andArgs:args withEnvironment:env withDelegate:delegate];
		if ([delegate respondsToSelector:@selector(shellTaskCreated:)])
			[delegate shellTaskCreated:shellTask];
		
		[shellTask launch];			// Start the process
		DebugLog(@"launched %@", [shellTask commandLineString]);

		// Move the process into our group if we can so when we quit all child processes are killed. See http:
		// www.cocoadev.com/index.pl?NSTaskTermination. Maybe there is a better way to do this in which case I would like to know.
		pid_t group = setsid();
		if (group == -1)
			group = getpgrp();
		setpgid([shellTask  processIdentifier], group);

		[shellTask waitUntilExit];
		outStr = nonNil([shellTask outputString]);
		errStr = nonNil([shellTask errorString]);
		BOOL isHgCommand = [cmd hasSuffix:@"MacHg.app/Contents/Resources/localhg"];
		
		if (!isHgCommand)
			break;
		if ([outStr hasPrefix:@"MercurialOutput:\n"])
		{
			outStr =[outStr substringFromIndex:17];
			break;
		}
		DebugLog(@"Recieved Null Mercurial Output for: %@", [shellTask commandLineString]);
		repeats++;
		sleep(repeats * 0.1);
	} while (repeats < 4);

	DebugLog(@"Finished execute cmd for %@", [shellTask commandLineString]);

	if (IsNotEmpty(errStr))
		DebugLog(@"err string for cmd %@ is %@", [shellTask commandLineString], errStr);

	ExecutionResult* result = [ExecutionResult resultWithCmd:cmd args:args result:[shellTask terminationStatus] outStr:outStr errStr:filterProgressOutOfErrorString(errStr)];
	result->theShellTask_ = shellTask;
	return result;
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  ExecutionResult
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation ExecutionResult

@synthesize generatingCmd = generatingCmd_;
@synthesize generatingArgs = generatingArgs_;
@synthesize result = result_;
@synthesize outStr = outStr_;
@synthesize errStr = errStr_;
@synthesize loggedToAlertOrWindow = loggedToAlertOrWindow_;

+ (ExecutionResult*) resultWithCmd:(NSString*)cmd args:(NSArray*)args result:(int)result outStr:(NSString*)outStr errStr:(NSString*)errStr
{
	ExecutionResult* newResult = [[ExecutionResult alloc]init];
	newResult->generatingCmd_ = cmd;
	newResult->generatingArgs_ = args;
	newResult->result_ = result;
	newResult->outStr_ = outStr;
	newResult->errStr_ = errStr;
	return newResult;
}


// This isn't really an error for us so go ahead and prune the missing extensions warnings.
- (void) pruneMissingExtensionsErrors
{
	if (IsEmpty(errStr_))
		return;
	NSString* regex = @"\\*\\*\\* failed to import extension (.*?)\n";
	errStr_ = [errStr_ stringByReplacingOccurrencesOfRegex:regex withString:@""];
	errStr_ = errStr_ ? trimString(errStr_) : @"";
}

- (BOOL) hasErrors		{ return ( result_ == 1 && IsNotEmpty(errStr_)) || result_ > 1 || result_ < 0 || [errStr_ isMatchedByRegex:@"^(?i)abort" options:RKLMultiline]; }
- (BOOL) hasWarnings	{ return IsNotEmpty(errStr_) && ![self hasErrors]; }
- (BOOL) hasNoErrors	{ return ![self hasErrors]; }
- (BOOL) isClean		{ return result_ == 0 && IsEmpty(errStr_); }

- (NSString*) description
{
	NSString* cmdPart       = [generatingCmd_ isEqualToString:executableLocationHG()] ? @"localhg" : generatingCmd_;
	NSString* cmdClause     = fstr(@"%@ %@", cmdPart, [generatingArgs_ componentsJoinedByString:@" "]);
	NSMutableArray* clauses = [[NSMutableArray alloc]init];
	if (IsNotEmpty(errStr_))	[clauses addObject: fstr(@"err:%@", errStr_)];
	if (IsNotEmpty(outStr_))	[clauses addObject: fstr(@"stdout:%@", outStr_)];
	[clauses addObject:cmdClause];
	return fstr(@"<%@ { code:%d, %@} >", [self className], result_, [clauses componentsJoinedByString:@", "]);
}

- (void) displayAnyHostIdentificationViolations
{
	NSString* cmd = [generatingArgs_ firstObject];
	if (![cmd isMatchedByRegex:@"incoming|outgoing|pull|push|identify"])
		return;
	if (IsEmpty(errStr_))
		return;

	if (![errStr_ isMatchedByRegex:@"warning: (.*) certificate with fingerprint ([0-9a-fA-F:]+) not verified"] &&
		![errStr_ isMatchedByRegex:@"abort: error:.*certificate verify failed"])
		return;

	NSString* fingerPrint = nil;
	NSURL* url = [NSURL URLWithString:[generatingArgs_ lastObject]];
	NSString* host = [url host];
	NSNumber* port = [url port];
	if (!host)
		return;

	NSString* scriptPath = fstr(@"%@/%@",[[NSBundle mainBundle] resourcePath], @"getHTTPSfingerprint.py");
	ExecutionResult* results = [ShellTask execute:scriptPath withArgs:[NSArray arrayWithObjects:host, port ? numberAsString(port) : @"443", nil] withEnvironment:[TaskExecutions environmentForHg]];
	if ([results hasNoErrors])
		fingerPrint = trimString(results.outStr);

	if (!fingerPrint)
		return;

	loggedToAlertOrWindow_ = YES;

	// Check to see if we already have a finger print in which case the fingerprint couldn't be used to verify the host which is bad.
	NSMutableArray* argsShowConfig = [NSMutableArray arrayWithObjects:@"showconfig", fstr(@"hostfingerprints.%@", host), nil];
	ExecutionResult* result = [TaskExecutions executeMercurialWithArgs:argsShowConfig  fromRoot:@"/tmp"];
	if ([result hasNoErrors] && IsNotEmpty(result.outStr))
	{
		NSRunCriticalAlertPanel(@"Mismatched Fingerprint Key", fstr(@"The key stored for the host '%@' is different than the key returned by connecting to %@. This could indicate the connection has been compromised. Check your configuration settings!", host, host), @"OK", @"", @"");
		return;
	}

	// Report we basically encountered a new host.
	NSString* errorMessage = @"Unsecured Host Encountered";
	NSString* fullErrorMessage = fstr(@"The authenticity of host '%@' cannot be established from stored certificates or host keys.\n\nThe host is reporting the key fingerprint:\n  %@\n\nIf you trust that this key fingerprint really represents '%@', you can permanently add this fingerprint to the accepted hosts.", host, fingerPrint, host);

	if (RequireVerifiedServerCertificatesFromDefaults())
		dispatch_async(mainQueue(), ^{
			NSAlert* alert = NewAlertPanel(errorMessage, fullErrorMessage, @"Decline", @"Add", nil);
			[alert setShowsHelp:YES];
			[alert setHelpAnchor:@"AboutServerIdentitySecurity"];
			int response = [alert runModal];
			if (response != NSAlertSecondButtonReturn)
				return;
			
			NSString* macHgHGRCFilePath = fstr(@"%@/hgrc",applicationSupportFolder());
			if (!pathIsExistent(macHgHGRCFilePath))
			{
				NSRunCriticalAlertPanel(@"Missing Configuration File", fstr(@"MacHg's configuration file %@ is missing. Please restart MacHg to recreate this file.", macHgHGRCFilePath), @"OK", @"", @"");
				return;
			}					
			NSMutableArray* argsCedit = [NSMutableArray arrayWithObjects:@"cedit", @"--config", @"extensions.hgext.cedit=", @"--add", fstr(@"hostfingerprints.%@ = %@", host, fingerPrint), @"--file", macHgHGRCFilePath, nil];
			[TaskExecutions executeMercurialWithArgs:argsCedit  fromRoot:@"/tmp"];
			
			NSString* successMessage = fstr(@"Permanently recorded for host '%@' the fingerprint:\n\n%@\n\nso it can be verifiably recognized in the future.", host, fingerPrint);
			NSRunAlertPanel(@"Fingerprint Added", successMessage, @"Ok", @"", @"");
		});	
}

- (void) logMercurialResult
{
	NSMutableString* theCommandAsString = [[NSMutableString alloc] init];
	NSArray* args = generatingArgs_;
	for (id s in args)
		if ([s isNotEqualTo:@"--header"])
			[theCommandAsString appendFormat:@"%@ ", s];
	NSString* filteredCommandString = [theCommandAsString stringByReplacingOccurrencesOfRegex:@"((?:ssh|http|https)://.*?):.*?@" withString:@"$1:***@"];
	NSString* currentTime = [[NSDate date] description];
	NSString* hgBinary = executableLocationHG();
	NSString* message = fstr(@"MacHg issued(%@):\n%@ %@\nResult code was:%d\nStandard out was:\n%@\nStandard error was:\n%@\n\n\n",
							 currentTime, hgBinary, filteredCommandString, result_, outStr_, errStr_);
	[[NSFileManager defaultManager] appendString:message toFilePath:MacHgLogFileLocation()];
}


- (void) logAndReportAnyErrors:(LoggingEnum)log
{
	
	// Write to log files.
	int level = LoggingLevelForHGCommands();
	if ( (level == 1 && bitsInCommon(log, eLogAllToFile)) || level == 2)
		[self logMercurialResult];
	
	if ([self hasErrors])
		[self displayAnyHostIdentificationViolations];
	
	// report errors if we asked for error reporting and it hasn't already been handled.
	if (!loggedToAlertOrWindow_ && [self hasErrors] && bitsInCommon(log, eIssueErrorsInAlerts))
	{
		NSString* errorMessage = fstr(@"Error During %@", [[generatingArgs_ firstObject] capitalizedString]);
		
		// This is a heuristic see the thread I started Versioning of Extensions and Matt's rather empty response here http:
		// www.selenic.com/pipermail/mercurial/2010-May/032095.html
		NSString* errorString = IsEmpty(errStr_) ? outStr_ : errStr_;
		NSString* fullErrorMessage = fstr(@"Mercurial reported error number %d:\n%@", result_, errorString);
		dispatch_async(mainQueue(), ^{
			NSRunAlertPanel(errorMessage, fullErrorMessage, @"OK", nil, nil);
		});
		loggedToAlertOrWindow_ = YES;
	}
}

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  TaskExecutions
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@implementation TaskExecutions





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Core Execution
// -----------------------------------------------------------------------------------------------------------------------------------------

static NSString* processedPathEnv(NSDictionary* processEnv)
{
	// Ensure /usr/local/bin is on the path
	NSString* pathEnv = [processEnv objectForKey:@"PATH"];
	if ([pathEnv isMatchedByRegex:@"^(.*:)?/usr/local/bin(:.*)?$"])
		return pathEnv;
	BOOL colonTerminated = [pathEnv hasSuffix:@":"];
	return [pathEnv stringByAppendingString: colonTerminated ? @"/usr/local/bin" : @":/usr/local/bin"];
}

+ (NSDictionary*) environmentForHg
{
	static NSDictionary* env = nil;
	static BOOL includeHomeHgrc  = NO;
	if (!env || includeHomeHgrc != IncludeHomeHgrcInHGRCPATHFromDefaults())
	{
		includeHomeHgrc  = IncludeHomeHgrcInHGRCPATHFromDefaults();
		
		NSDictionary* processEnv    = [[NSProcessInfo processInfo] environment];
		NSMutableDictionary* newEnv = [[NSMutableDictionary alloc] init];

		NSString* hgrc_Path = hgrcPath();
		NSString* localMercurialPath = fstr(@"%@/LocalMercurial", [[NSBundle mainBundle] builtInPlugInsPath]);
		NSString* PATHenv = processedPathEnv(processEnv);		// This is $PATH with /usr/local/bin included if necessary
		
		[newEnv copyValueOfKey:@"SSH_ASKPASS"	from:processEnv];
		[newEnv copyValueOfKey:@"SSH_AUTH_SOCK"	from:processEnv];
		[newEnv copyValueOfKey:@"HOME"			from:processEnv];
		[newEnv copyValueOfKey:@"TMPDIR"		from:processEnv];
		[newEnv copyValueOfKey:@"USER"			from:processEnv];
		[newEnv setObject:localMercurialPath	 forKey:@"PYTHONPATH"];
		[newEnv setObject:executableLocationHG() forKey:@"HG"];
		[newEnv setObject:PATHenv   forKey:@"PATH"];
		[newEnv setObject:@"UTF-8"  forKey:@"HGENCODING"];
		[newEnv setObject:@"1"		forKey:@"HGPLAIN"];
		[newEnv setObject:hgrc_Path	forKey:@"HGRCPATH"];
		env = [NSDictionary dictionaryWithDictionary:newEnv];
	}
	return env;
}


// Give a string of arguments like "--rev 23 --git --force --no-merges --remotecmd blargsplatter" break this into the array
// ["--rev", "23", "--git", "--force", "--no-merges", "--remotecmd", "blargsplatter"]
+ (NSMutableArray*) parseArguments:(NSString*)args
{
	NSString* option;
	NSString* optionArg;
	NSString* regexString = @"^(\\s*[\\w-]+)\\s*(.*?)\\s*$";

	NSMutableArray* answer = [[NSMutableArray alloc] init];
	NSArray* argParts = [args componentsSeparatedByString:@"--"];
	for (NSString* argPart in argParts)
	{
		if (IsEmpty(argPart)) continue;
		option    = NULL;
		optionArg = NULL;
		if ([argPart getCapturesWithRegexAndComponents:regexString firstComponent:&option  secondComponent:&optionArg])
		{
			if (IsEmpty(option)) continue;
			[answer addObject:fstr(@"--%@", dupString(option))];
			if (IsEmpty(optionArg)) continue;
			[answer addObject: dupString(optionArg)];
		}
	}
	return answer;
}


+ (NSMutableArray*) filterOptions:(NSArray*)options byValidOptions:(NSArray*)validOptions
{
	NSMutableArray* filtered = [[NSMutableArray alloc] init];
	BOOL validOptionRead = NO;
	for (NSString* arg in options)
	{
		BOOL argIsOption = [arg isMatchedByRegex:@"--.*"];	// XXXX

		// We have perviously read a valid option now add the argument.
		if (!argIsOption && validOptionRead)
		{
			[filtered addObject:arg];
			validOptionRead = NO;	// reset for next option
			continue;
		}

		if (argIsOption && ![validOptions containsObject:arg])
			continue;
			
		if (argIsOption)
		{
			[filtered addObject:arg];
			validOptionRead = YES;
		}
	}
	return filtered;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Mercurial execution
// -----------------------------------------------------------------------------------------------------------------------------------------




+ (BOOL) taskWasKilled:(ExecutionResult*)results
{
	return (results.result == SIGTERM || (results.result == 255 && [results.errStr isEqualToString:@"killed!\n"]));
}



// This will preprocess a command before sending it off to mercurial. It does 3 things
// 1. It adds a default string which is null so it overrides any defaults (so if the user has some default set in the .hgrc) it won't conflict with MacHg
// 2. It adds the option to change the working directory to the root path
// 3. It sets the command to be non-interactive since we don't want it to halt in its execution.
+ (NSMutableArray*) preProcessMercurialCommandArgs: (NSMutableArray*)args fromRoot:(NSString*)rootPath
{
	NSIndexSet* insertionLocation = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 3)];
	NSArray* defaultArguments = [NSArray arrayWithObjects: @"--header", @"--cwd", rootPath, nil];
	NSMutableArray* newArgs = [NSMutableArray arrayWithArray:args];
	[newArgs insertObjects:defaultArguments  atIndexes:insertionLocation];
	return newArgs;
}


// Execute the hg command with the arguments args putting results into pipe and reading the data from that and returning it.
+ (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath
{
	return [TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath   logging:eLogAllIssueErrors  withDelegate:nil];
}
+ (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath logging:(LoggingEnum)log
{
	return [TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath   logging:log  withDelegate:nil];
}
+ (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  logging:(LoggingEnum)log  withDelegate:(id <ShellTaskDelegate>)delegate
{
	if (!rootPath)
		return [ExecutionResult resultWithCmd:executableLocationHG() args:[NSArray arrayWithArray:args] result:255 outStr: @"" errStr:@"Null root path"];

	NSMutableArray* newArgs = [self preProcessMercurialCommandArgs:args fromRoot:rootPath];
	NSString* hgBinary = executableLocationHG();
	ExecutionResult* results = [ShellTask  execute:hgBinary  withArgs:newArgs  withEnvironment:[TaskExecutions environmentForHg]  withDelegate:delegate];
	[results pruneMissingExtensionsErrors];
	[results logAndReportAnyErrors:log];
	return results;
}


@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: DoTerminalScript
// -----------------------------------------------------------------------------------------------------------------------------------------

// From http://lists.apple.com/archives/Cocoa-dev/2008/Jan/msg00848.html
OSStatus DoTerminalScript(NSString* script)
{
	// Launch the terminal if it's not already active...
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.Terminal" options:0 additionalEventParamDescriptor:nil launchIdentifier:nil];
	const char* utf8Script = [script UTF8String];
    /*
     * Run a shell script in Terminal.app.
     * (Terminal.app must be running first.)
     */
    char* bundleID = "com.apple.terminal";
    AppleEvent evt, res;
    AEDesc desc;
    OSStatus err;
	
	// Build event
	err = AEBuildAppleEvent(kAECoreSuite, kAEDoScript,
							typeApplicationBundleID,
							bundleID, strlen(bundleID),
							kAutoGenerateReturnID,
							kAnyTransactionID,
							&evt, NULL,
							"'----':utf8(@)", strlen(utf8Script), utf8Script);
	if (err) return err;
	// Send event and check for any Apple Event Manager errors
	err = AESendMessage(&evt, &res, kAEWaitReply, kAEDefaultTimeout);
	AEDisposeDesc(&evt);
	if (err) return err;
	// Check for any application errors
	err = AEGetParamDesc(&res, keyErrorNumber, typeSInt32, &desc);
	AEDisposeDesc(&res);
	if (!err)
	{
		AEGetDescData(&desc, &err, sizeof(err));
		AEDisposeDesc(&desc);
	}
	else if (err == errAEDescNotFound)
		err = noErr;
	return err;
}





