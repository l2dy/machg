
#import "LNCStopwatch.h"

@implementation LNCStopwatch

- (id) init
{
	mach_timebase_info_data_t info;
	mach_timebase_info(&info);
	conversionToSeconds = 1e-9 * ((double)info.numer) / ((double)info.denom);
	
	timeCount = 0;
	[self reset];
	return self;
}

- (void) reset
{
	started = NO;
	sum = 0;
}

- (void) start
{
	if (!started)
	{
        lastStart = mach_absolute_time();
        started = YES;
	}
}

- (void) stop
{
	if (started)
	{
        sum += mach_absolute_time() - lastStart;
        started = NO;
		timeCount++;
	}
}

/*
 Returns the number of seconds elapsed as a decimal
 NOTE: This can be called without calling stop: for
 incremental timing.
 */
- (double) elapsedSeconds
{
	uint64_t extra = 0;
	if (started) // account for time between last start and now
        extra = mach_absolute_time() - lastStart;
	
	return conversionToSeconds * (sum + extra);
}

- (void) stopAndLogTimeAndReset
{
	[self stop];
	NSLog(@"Timing %d took %f seconds", timeCount, [self elapsedSeconds]);
	[self reset];
}


@end