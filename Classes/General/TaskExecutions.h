//
//  TaskExecutions.h
//  MacHg
//
//  Created by Jason Harris on 29/04/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
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



// NSTask category extensions
@interface NSTask (NSTaskPlusResultExtraction)
- (ExecutionResult) extractResults;
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
+ (ExecutionResult) synchronouslyExecute:(NSString*)cmd withArgs:(NSArray*)args onTask:(NSTask*)theTask;
+ (NSMutableArray*) parseArguments:(NSString*)args;
+ (NSMutableArray*) filterOptions:(NSArray*)options byValidOptions:(NSArray*)validOptions;


// Mercurial task handling
+ (void)			logMercurialResult:(ExecutionResult)results;
+ (void)			logAndReportAnyErrors:(LoggingEnum)log forResults:(ExecutionResult)results;
+ (BOOL)			taskWasKilled:(ExecutionResult)results;

+ (NSMutableArray*) preProcessMercurialCommandArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath;

+ (ExecutionResult) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath;
+ (ExecutionResult) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  logging:(LoggingEnum)log;
+ (ExecutionResult) executeMercurialWithArgs:(NSMutableArray*)args  fromRoot:(NSString*)rootPath  logging:(LoggingEnum)log  onTask:(NSTask*)theTask;

@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Utilities
// -----------------------------------------------------------------------------------------------------------------------------------------

extern OSStatus DoTerminalScript(NSString* script);
