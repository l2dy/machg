//
//  SingleTimedQueue.h
//  MacHg
//
//  Created by Jason Harris on 2/21/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"


// A simple class which will execute a block after a specified delay. If a new block is "added" to be executed before the current
// block has executed, the old block is canceled and the new block will start the timer again and execute after the given delay,
// etc.

// We can use this were we want something to "truly" fire only once but we might receive a flood of firing events. Eg consider
// kUnderlyingRepositoryHasChanged (the notification we receive that the underlying repository has changed.), Various methods
// might post this. If we have a small SingleTimedQueue we can ensure that if we wait for a small delay with each one of these
// methods queuing up we will in the end only fire one true kUnderlyingRepositoryHasChanged, notification etc.

@interface SingleTimedQueue : NSObject
{
	dispatch_queue_t    dispatchQueue_;
	NSTimeInterval		delay_;
	BlockProcess		block_;
	NSTimer*			timer_;
	NSInteger			operationNumber_;
	NSString*			descriptiveQueueName_;			// Only used for debugging
	BOOL				suspended_;
}
@property (readonly, assign) NSInteger operationNumber;

+ (SingleTimedQueue*) SingleTimedQueueExecutingOn:(dispatch_queue_t)dispatchQueue withTimeDelay:(NSTimeInterval)delay  descriptiveName:(NSString*)name;
- (NSInteger) addBlockOperation:(BlockProcess)block;
- (NSInteger) addBlockOperation:(BlockProcess)block withDelay:(NSTimeInterval)delay;
- (void) invalidateBlocksOnQueue;
- (void) suspendQueue;
- (void) resumeQueue;
- (BOOL) operationQueued;


@end
