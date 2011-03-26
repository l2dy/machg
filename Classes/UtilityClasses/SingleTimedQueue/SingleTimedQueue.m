//
//  SingleTimedQueue.m
//  MacHg
//
//  Created by Jason Harris on 2/21/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "SingleTimedQueue.h"


@implementation SingleTimedQueue

@synthesize operationNumber = operationNumber_;

+ (SingleTimedQueue*) SingleTimedQueueExecutingOn:(dispatch_queue_t)dispatchQueue  withTimeDelay:(NSTimeInterval)delay  descriptiveName:(NSString*)name
{
	SingleTimedQueue* newstq = [SingleTimedQueue alloc];
	newstq->dispatchQueue_ = dispatchQueue;
	newstq->delay_ = delay;
	newstq->descriptiveQueueName_ = name;
	newstq->timer_ = nil;
	newstq->operationNumber_ = 0;
	newstq->suspended_ = NO;
	return newstq;
}

- (void) executeTheBlock:(NSTimer*)theTimer
{
	//DebugLog(@"firing single timed queue %@", descriptiveQueueName_);
	
	// We refernce the block_ here with a local variable so there are no synchronization issues of the block_ being set to nil
	// and then the dispatch_async firing with a nil block which causes a lock.
	BlockProcess theBlock = block_;
	block_ = nil;
	if (theBlock)
		dispatch_async(dispatchQueue_, theBlock);
}

- (NSInteger) addBlockOperation:(BlockProcess)block	{ return [self addBlockOperation:block withDelay:delay_]; }

- (NSInteger) addBlockOperation:(BlockProcess)block withDelay:(NSTimeInterval)delay
{
	//DebugLog(@"adding block to single timed queue %@", descriptiveQueueName_);
	[timer_ invalidate];
	block_ = [block copy];
	if (!suspended_)
		dispatchSpliced(mainQueue(), ^{
			timer_ = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(executeTheBlock:) userInfo:nil repeats:NO];
		});
	return operationNumber_++;
}

- (void) invalidateBlocksOnQueue
{
	[timer_ invalidate];
	block_ = nil;
}

- (void) suspendQueue
{
	[timer_ invalidate];
	suspended_ = YES;
}

- (void) resetTimer
{
	[timer_ invalidate];
	if (!suspended_)
		dispatchSpliced(mainQueue(), ^{
			timer_ = [NSTimer scheduledTimerWithTimeInterval:delay_ target:self selector:@selector(executeTheBlock:) userInfo:nil repeats:NO];
		});	
}

// I would like to have the resumeQueue actually call executeTheBlock and do the dispatch_async(dispatchQueue_, block_), but
// strangely this is always locking up in an internal call to _dispatch_Block_copy and I don't know why. So for now just delete
// everything in the queue and keep going. Everyone that wants to do something needs to look to see if there is a block operation
// already queued.
- (void) resumeQueue
{
	suspended_ = NO;
	block_ = nil;
}

- (BOOL) operationQueued
{
	return block_ != nil;
}


@end
