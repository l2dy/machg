//
//  TaskExecutions.h
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@class AppController;
@class MonitorFSEvents;


typedef enum
{
	eLoggingNone			= 0,
	eLogResultsToFile		= 1<<1,
	eLogErrorsToFIle		= 1<<2,
	eIssueErrorsInAlerts	= 1<<3,
	eIssueResultsInAlerts	= 1<<4,
	eDisplayErrorsInWindow	= 1<<5,
	eDisplayResultsInWindow	= 1<<6,
	eLogAllToFile			= eLogResultsToFile | eLogErrorsToFIle ,
	eDisplayAllInWindow		= eDisplayErrorsInWindow | eDisplayResultsInWindow,
	eLogAllAndDisplayAll	= eLogAllToFile | eDisplayAllInWindow,
	eLogAllIssueErrors		= eLogAllToFile | eIssueErrorsInAlerts
} LoggingEnum;


@interface ExecutionResult : NSObject
{
	NSString* generatingCmd_;	// The command that was executed
	NSArray*  generatingArgs_;	// The arguments used to the command
	int		  result_;			// The result of executing the command
	NSString* outStr_;			// The output received on stdOut due to executing the command
	NSString* errStr_;			// The output received on stdErr due to executing the command
}

@property (readonly, assign) NSString* generatingCmd;
@property (readonly, assign) NSArray*  generatingArgs;
@property (readonly, assign) int	   result;
@property (readonly, assign) NSString* outStr;
@property (readonly, assign) NSString* errStr;

+ (ExecutionResult*) extractResults:(NSTask*)task;
+ (ExecutionResult*) resultWithCmd:(NSString*)cmd args:(NSArray*)args result:(int)result outStr:(NSString*)outStr errStr:(NSString*)errStr;

- (BOOL) hasErrors;
- (BOOL) hasNoErrors;
- (BOOL) hasWarnings;

@end




// NSTask category extensions
@interface NSTask (NSTaskPlusExtensions)
- (void) startExecution:(NSString*)cmd withArgs:(NSArray*)args;
- (void) cancelTask;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: TaskExecutions
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface TaskExecutions : NSObject
{
	AppController* appController;
}

// Initialization
+ (TaskExecutions*) theInstance;
- (TaskExecutions*) init;	// The init method returns the unique instance.


// General Task handling.
+ (ExecutionResult*) synchronouslyExecute:(NSString*)cmd withArgs:(NSArray*)args onTask:(NSTask*)theTask;
+ (NSMutableArray*) parseArguments:(NSString*)args;
+ (NSMutableArray*) filterOptions:(NSArray*)options byValidOptions:(NSArray*)validOptions;


// Mercurial task handling
+ (void)			logMercurialResult:(ExecutionResult*)results;
+ (void)			logAndReportAnyErrors:(LoggingEnum)log forResults:(ExecutionResult*)results;
+ (BOOL)			taskWasKilled:(ExecutionResult*)results;

+ (NSMutableArray*) preProcessMercurialCommandArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath;

+ (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath;
+ (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  logging:(LoggingEnum)log;
+ (ExecutionResult*) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  logging:(LoggingEnum)log  onTask:(NSTask*)theTask;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

extern OSStatus DoTerminalScript(NSString* script);
