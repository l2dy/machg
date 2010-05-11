//
//  TaskExecutions.m
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "TaskExecutions.h"
#import "AppController.h"
#import "Common.h"

// This isn't really an error for us so go ahead and prune the missing extensions warnings.
ExecutionResult PruneMissingExtensionsErrors(ExecutionResult results)
{
	if (IsEmpty(results.errStr))
		return results;
	NSString* regex = @"*** failed to import extension (.*?) from (.*?): (.*?)\n";
	results.errStr = [results.errStr stringByReplacingOccurrencesOfRegex:regex withString:@""];
	results.errStr = results.errStr ? results.errStr : @"";
	return results;
}

#pragma mark -
@implementation TaskExecutions

+ (TaskExecutions*) theInstance
{
	static TaskExecutions* theTaskExecutions = nil;
	if (!theTaskExecutions)
		theTaskExecutions = [[TaskExecutions alloc] init];	// This will actually get the instance in the init method.
	return theTaskExecutions;
}

- (TaskExecutions*) init
{
	static TaskExecutions* theTaskExecutions = nil;
	if (!theTaskExecutions)
		theTaskExecutions = [TaskExecutions alloc];
	return theTaskExecutions;
}





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Core Execution
// -----------------------------------------------------------------------------------------------------------------------------------------

+ (ExecutionResult) synchronouslyExecute:(NSString*)cmd withArgs:(NSArray*)args onTask:(NSTask*)theTask
{
	NSTask* task = theTask ? theTask : [[NSTask alloc] init];
	[task startExecution:cmd withArgs:args];
	return [task extractResults];
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
			[answer addObject:[NSString stringWithFormat:@"--%@", dupString(option)]];
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

+(void) logMercurialResult:(ExecutionResult)results
{
	NSMutableString* theCommandAsString = [[NSMutableString alloc] init];
	NSArray* args = results.generatingArgs;
	for (id s in args)
		[theCommandAsString appendFormat:@"%@ ", s];
	NSString* currentTime = [[NSDate date] description];
	NSString* hgBinary = executableLocationHG();
	NSString* message = [NSString stringWithFormat:@"MacHg issued(%@):\n%@ %@\nResult code was:%d\nStandard out was:\n%@\nStandard error was:\n%@\n\n\n",
						 currentTime, hgBinary, theCommandAsString, results.result, results.outStr, results.errStr];
	[[NSFileManager defaultManager] appendString:message toFilePath:MacHgLogFileLocation()];
}


+ (void) logAndReportAnyErrors:(LoggingEnum)log forResults:(ExecutionResult)result
{
	// Write to log files.
	int level = LoggingLevelForHGCommands();
	if ( (level == 1 && bitsInCommon(log, eLogAllToFile)) || level == 2)
		[self logMercurialResult:result];

	// report errors if we asked for error reporting
	if (IsNotEmpty(result.errStr) && result.result != 0)
		if (bitsInCommon(log, eIssueErrorsInAlerts))
		{
			NSString* errorMessage = [NSString stringWithFormat:@"Error During %@", [[result.generatingArgs objectAtIndex:0] capitalizedString]];
			NSString* fullErrorMessage = [NSString stringWithFormat:@"Mercurial reported error number %d:\n%@", result.result, result.errStr];
			dispatch_async(mainQueue(), ^{
				NSRunAlertPanel(errorMessage, fullErrorMessage, @"Ok", nil, nil);
			});
		}
}

+ (BOOL) taskWasKilled:(ExecutionResult)results
{
	return (results.result == SIGTERM || (results.result == 255 && [results.errStr isEqualToString:@"killed!\n"]));
}



// This will preprocess a command before sending it off to mercurial. It does 3 things
// 1. It adds a default string which is null so it overrides any defaults (so if the user has some default set in the .hgrc) it won't conflict with MacHg
// 2. It adds the option to change the working directory to the root path
// 3. It sets the command to be non-interactive since we don't want it to halt in its execution.
+ (NSMutableArray*) preProcessMercurialCommandArgs: (NSMutableArray*)args fromRoot:(NSString*)rootPath
{
	if (HandleCommandDefaultsFromDefaults() == eExcludeHGRCCommandDefaults)
	{
		NSString* hgCmd = [args objectAtIndex:0];
		NSString* defaultsString = [NSString stringWithFormat:@"defaults.%@=", hgCmd];
		NSIndexSet* insertionLocation = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 5)];
		NSArray* defaultArguments = [NSArray arrayWithObjects: @"--cwd", rootPath, @"--config", defaultsString, @"--noninteractive", nil];
		NSMutableArray* newArgs = [NSMutableArray arrayWithArray:args];
		[newArgs insertObjects:defaultArguments  atIndexes:insertionLocation];
		return newArgs;
	}
	else
	{
		NSIndexSet* insertionLocation = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 3)];
		NSArray* defaultArguments = [NSArray arrayWithObjects: @"--cwd", rootPath, @"--noninteractive", nil];
		NSMutableArray* newArgs = [NSMutableArray arrayWithArray:args];
		[newArgs insertObjects:defaultArguments  atIndexes:insertionLocation];
		return newArgs;
	}
}


// Execute the hg command with the arguments args putting results into pipe and reading the data from that and returning it.
+ (ExecutionResult) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath
{
	return [TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath   logging:eLogAllIssueErrors  onTask:nil];
}
+ (ExecutionResult) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath logging:(LoggingEnum)log
{
	return [TaskExecutions executeMercurialWithArgs:args  fromRoot:rootPath   logging:log onTask:nil];
}
+ (ExecutionResult) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  logging:(LoggingEnum)log  onTask:(NSTask*)theTask
{
	ExecutionResult results;
	if (!rootPath)
	{
		results.outStr = @"";
		results.errStr = @"Null root path";
		results.result = 255;
		results.generatingCmd  = executableLocationHG();
		results.generatingArgs = [NSArray arrayWithArray:args];
		return results;
	}
	NSMutableArray* newArgs = [self preProcessMercurialCommandArgs:args fromRoot:rootPath];
	NSString* hgBinary = executableLocationHG();
	results = [TaskExecutions synchronouslyExecute:hgBinary withArgs:newArgs onTask:theTask];
	results = PruneMissingExtensionsErrors(results);
	[TaskExecutions logAndReportAnyErrors:log forResults:results];
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
	// Launch the terminal if its not already active...
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





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Extensions
// -----------------------------------------------------------------------------------------------------------------------------------------

@implementation NSTask (NSTaskPlusResultExtraction)

- (ExecutionResult) extractResults
{
	ExecutionResult results;
	NSPipe* outPipe = [self standardOutput];												// get the standard output
	NSPipe* errPipe = [self standardError];													// get the standard error
	NSData* outData = [[outPipe fileHandleForReading] readDataToEndOfFileIgnoringErros];	// Read the output
	NSData* errData = [[errPipe fileHandleForReading] readDataToEndOfFileIgnoringErros];	// Read the output
	[self waitUntilExit];	// Wait *after* the data read. Seems counter intuitive but see the Cocodev articles about NSTask
	results.generatingCmd   = [self launchPath];
	results.generatingArgs  = [NSArray arrayWithArray:[self arguments]];
	results.outStr = [[NSString alloc] initWithData:outData  encoding:NSUTF8StringEncoding];
	results.errStr = [[NSString alloc] initWithData:errData  encoding:NSUTF8StringEncoding];
	results.result = [self terminationStatus];
	[self cancelTask];
	return results;
}


- (void) startExecution:(NSString*)cmd withArgs:(NSArray*)args
{
	NSPipe* outPipe = [[NSPipe alloc] init];     // Create the pipe to write standard out to
	NSPipe* errPipe = [[NSPipe alloc] init];     // Create the pipe to write standard error to
	[self setLaunchPath:cmd];
	[self setArguments:args];
	[self setStandardOutput:outPipe];
	[self setStandardError:errPipe];
	[self launch];			// Start the process

	// Move the process into our group if we can so when we quit all child processes are killed. See http:
	// www.cocoadev.com/index.pl?NSTaskTermination. Maybe there is a better way to do this in which case I would like to know.
	pid_t group = setsid();
	if (group == -1)
		group = getpgrp();
	setpgid([self processIdentifier], group);
}

- (void) cancelTask
{
	if ([self isRunning])
		[self terminate];
}

@end

