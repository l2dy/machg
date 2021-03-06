//
//  MonitorFSEvents.m
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//
//  Some parts derived from SCEvents by Stuart Connolly http://stuconnolly.com/projects/source-code/
//

#import "MonitorFSEvents.h"
#import "Common.h"
#import "SingleTimedQueue.h"
#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>

@interface MonitorFSEvents (PrivateAPI)

- (void) setupEventsStream_;
static void FSEventsCallBack_(ConstFSEventStreamRef streamRef, void* clientCallBackInfo, size_t numEvents, void* eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@end

@implementation MonitorFSEvents

@synthesize delegate = delegate_;
@synthesize isWatchingPaths = isWatchingPaths_;
@synthesize watchedPaths = watchedPaths_;


/**
 * Initializes an instance of FSEvents setting its default values.
 */
- (id) init
{
    if ((self = [super init]))
	{
        isWatchingPaths_ = NO;
	}
    return self;
}


/**
 * Starts watching the supplied array of paths for events on the current run loop.
 */
- (BOOL) startWatchingPaths:(NSMutableArray*)paths { return [self startWatchingPaths:paths onRunLoop:NSRunLoop.currentRunLoop]; }

/**
 * Starts watching the supplied array of paths for events on the supplied run loop.
 * A boolean value is returned to indicate the success of starting the stream. If
 * there are no paths to watch or the stream is already running then false is
 * returned.
 */
- (BOOL) startWatchingPaths:(NSMutableArray*)paths onRunLoop:(NSRunLoop*)runLoop
{
    if ((paths.count == 0) || (isWatchingPaths_))
		return NO;
    
    self.watchedPaths = paths;
    [self setupEventsStream_];
    FSEventStreamScheduleWithRunLoop(eventStream_, runLoop.getCFRunLoop, kCFRunLoopDefaultMode);	    // Schedule the event stream on the supplied run loop
    FSEventStreamStart(eventStream_);	    // Start the event stream
	isWatchingPaths_ = YES;
    return YES;
}

/**
 * Stops the event stream from watching the set paths. A boolean value is returned
 * to indicate the success of stopping the stream. False is return if this method
 * is called when the stream is not already running.
 */
- (BOOL) stopWatchingPaths
{
    if (!isWatchingPaths_)
		return NO;

    FSEventStreamStop(eventStream_);
    FSEventStreamInvalidate(eventStream_);
	
	if (eventStream_)
		FSEventStreamRelease(eventStream_), eventStream_ = nil;
    
    isWatchingPaths_ = NO;
    return YES;
}


// Flushes the event stream synchronously by sending events that have already occurred but not yet delivered.
- (BOOL) flushEventStreamSync
{
	if (!isWatchingPaths_)
		return NO;
	
	FSEventStreamFlushSync(eventStream_);
	
	return YES;
}

// Flushes the event stream asynchronously by sending events that have already
//occurred but not yet delivered.
- (BOOL) flushEventStreamAsync
{
	if (!isWatchingPaths_)
		return NO;
	FSEventStreamFlushAsync(eventStream_);
	return YES;
}


- (NSString*) streamDescription
{
	if (!isWatchingPaths_)
		return @"The event stream is not running. Start it by calling: startWatchingPaths:";
	CFStringRef desc = FSEventStreamCopyDescription(eventStream_);
	NSString* ans = [NSString stringWithString:(__bridge NSString*)desc];
	CFRelease(desc);
	return ans;
}

/**
 * Provides the string used when printing this object in NSLog, etc. Useful for
 * debugging purposes.
 */
- (NSString*) description { return fstr(@"<%@ { watchedPaths = %@ } >", [self className], watchedPaths_); }

- (void) dealloc
{
	delegate_ = nil;
	if (isWatchingPaths_)
		[self stopWatchingPaths];

}

@end



@implementation MonitorFSEvents (PrivateAPI)

/**
 * Constructs the events stream.
 */
- (void) setupEventsStream_
{
    FSEventStreamContext callbackInfo;
	callbackInfo.version = 0;
	callbackInfo.info    = (__bridge void*)self;
	callbackInfo.retain  = NULL;
	callbackInfo.release = NULL;
	callbackInfo.copyDescription = NULL;

    CFTimeInterval   notificationLatency = 1.0;
	
	if (eventStream_)
		FSEventStreamRelease(eventStream_);
    eventStream_ = FSEventStreamCreate(kCFAllocatorDefault, &FSEventsCallBack_, &callbackInfo, (__bridge CFArrayRef)watchedPaths_, kFSEventStreamEventIdSinceNow, notificationLatency, kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagWatchRoot);
}

/**
 * FSEvents callback function. The frequency at which this callback is
 * called depends upon the notification latency value. This callback is usually
 * called with more than one event and all are passed back to the delegate.
 */
static void FSEventsCallBack_(ConstFSEventStreamRef streamRef, void* clientCallBackInfo, size_t numEvents, void* eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[])
{
    MonitorFSEvents* pathWatcher = (__bridge MonitorFSEvents*)clientCallBackInfo;
	if ([pathWatcher.delegate conformsToProtocol:@protocol(MonitorFSEventListenerProtocol)])
		[pathWatcher.delegate fileEventsOccurredIn:(__bridge NSArray *)(eventPaths)];
}

@end
