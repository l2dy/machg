// Code for timing use as in the following:

	//	LNCStopwatch* stopwatch = [[LNCStopwatch alloc] init];
	//	[stopwatch start];
	//	// code here
	//	[stopwatch stop];
	//	double elapsed = [stopwatch elapsedSeconds];
	//	NSLog(@"task time took %f seconds.", elapsed);


// or

	//	LNCStopwatch* stopwatch = [[LNCStopwatch alloc] init];
	//	[stopwatch start];
	//	// code here
	//	[stopwatch stopAndLogTimeAndReset];
	//	...
	//	[stopwatch start];
	//	// more code here
	//	[stopwatch stopAndLogTimeAndReset];


#import <Cocoa/Cocoa.h>
#import <mach/mach_time.h>





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: LNCStopwatch
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface LNCStopwatch : NSObject
{
	double conversionToSeconds;
	BOOL started;
	uint64_t lastStart;
	uint64_t sum;
	int timeCount; // how many times have we done a timing.
}

- (void) reset;
- (void) start;
- (void) stop;
- (void) stopAndLogTimeAndReset;
- (double) elapsedSeconds;

@end