//
//  MonitorFSEvents.h
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//
//  Some parts derived from SCEvents by Stuart Connolly http://stuconnolly.com/projects/source-code/
//


@class SingleTimedQueue;

@protocol MonitorFSEventListenerProtocol
 // Conforming objects' implementation of this method will be called whenever an event occurs. The instance of FSEvents which
// received the event and the event itself are passed as parameters.
- (void) fileEventsOccurredIn:(NSArray*)eventPaths;
@end

@interface MonitorFSEvents : NSObject
{
    id <MonitorFSEventListenerProtocol> __weak delegate_;    // The delegate that FSEvents is to notify when events occur.
    FSEventStreamRef eventStream_;					// The actual FSEvents stream reference.
}

@property (weak) id delegate;
@property (readonly) BOOL isWatchingPaths;			// Is the events stream currently running.
@property (strong) NSMutableArray* watchedPaths;	// The paths that are to be watched for events.

- (BOOL) startWatchingPaths:(NSMutableArray*)paths;
- (BOOL) startWatchingPaths:(NSMutableArray*)paths onRunLoop:(NSRunLoop*)runLoop;
- (BOOL) stopWatchingPaths;
- (BOOL) flushEventStreamSync;
- (BOOL) flushEventStreamAsync;

- (NSString*) streamDescription;

@end
