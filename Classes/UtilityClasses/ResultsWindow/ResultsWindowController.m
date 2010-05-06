//
//  ResultsWindowController.m
//  MacHg
//
//  Created by Jason Harris on 16/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "ResultsWindowController.h"
#import "Common.h"
#import "TaskExecutions.h"

static inline CGFloat constrain(CGFloat val, CGFloat min, CGFloat max)	{ if (val < min) return min; if (val > max) return max; return val; }

@implementation ResultsWindowController

- (ResultsWindowController*) initWithMessage:(NSString*)message andResults:(NSAttributedString*)results andWindowTitle:(NSString*)windowTitle
{
	[NSBundle loadNibNamed:@"ResultsWindow" owner:self];
	[titleMessageTextField setStringValue:message];
	[[resultsMessageTextView textStorage] setAttributedString:results];

	NSSize titleSize = [[titleMessageTextField attributedStringValue] size];
	NSSize resultsSize = [results size];
	NSSize newSize;
	
	NSRect visibleFrame = [[resultsWindow screen] visibleFrame];
	
	newSize.width   = constrain(MAX(resultsSize.width,  titleSize.width)  + 40, 50, visibleFrame.size.width  - 20);
	newSize.height  = constrain(MAX(resultsSize.height, titleSize.height) + 70, 50, visibleFrame.size.height - 20);

	NSSize currentSize = [resultsMessageTextView frame].size;
	NSRect f = [resultsWindow frame];
	f.size.width  += (newSize.width  - currentSize.width);
	f.size.height += (newSize.height - currentSize.height);
	[resultsWindow setFrame:f display:YES];
	[resultsWindow setTitle:windowTitle];
	[resultsWindow makeKeyAndOrderFront:self];
	[resultsWindow makeFirstResponder:okButtonForResultsWindow];

	return self;
}

+ (ResultsWindowController*) createWithMessage:(NSString*)message andResults:(NSAttributedString*)results andWindowTitle:(NSString*)windowTitle
{
	return [[ResultsWindowController alloc] initWithMessage:message andResults:results andWindowTitle:windowTitle];
}


- (IBAction) doneWithResults:(id)sender
{
	[resultsWindow close];
}

@end
