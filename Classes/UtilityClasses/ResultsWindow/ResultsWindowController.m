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

- (ResultsWindowController*) initWithMessage:(NSString*)message andResults:(NSAttributedString*)results andWindowTitle:(NSString*)windowTitle onScreen:(NSScreen*)screen
{
	self = [super init];
	if (!self)
		return nil;

	theRetainedSelf = self;
	dispatch_async(mainQueue(), ^{
		[NSBundle loadNibNamed:@"ResultsWindow" owner:self];
		titleMessageTextField.stringValue = message;
		[resultsMessageTextView.textStorage setAttributedString:results];

		NSSize titleSize = titleMessageTextField.attributedStringValue.size;
		NSSize resultsSize = results.size;
		NSSize newSize;
		
		NSRect visibleFrame = screen.visibleFrame;
		NSSize currentSize = resultsMessageTextView.frame.size;
		NSRect f = resultsWindow.frame;
		
		CGFloat padH   = f.size.width  - currentSize.width;
		CGFloat padV   = f.size.height - currentSize.height;
		newSize.width  = constrain(MAX(resultsSize.width,  titleSize.width)  + 40, 50, visibleFrame.size.width  - 20 - padH);
		newSize.height = constrain(MAX(resultsSize.height, titleSize.height) + 70, 50, visibleFrame.size.height - 20 - padV);

		f.size.width   = (newSize.width  + padH);
		f.size.height  = (newSize.height + padV);
		f.origin.x     = constrain(f.origin.x, 10, MAX(visibleFrame.size.width  - newSize.width  - 20, 10));
		f.origin.y     = constrain(f.origin.y, 10, MAX(visibleFrame.size.height - newSize.height - 20, 10));
	
		[resultsWindow setFrame:f display:YES];
		resultsWindow.title = windowTitle;
		[resultsWindow makeKeyAndOrderFront:self];
		[resultsWindow makeFirstResponder:okButtonForResultsWindow];
	});
	
	return self;
}

+ (ResultsWindowController*) createWithMessage:(NSString*)message andResults:(NSAttributedString*)results andWindowTitle:(NSString*)windowTitle onScreen:(NSScreen*)screen
{
	return [[ResultsWindowController alloc] initWithMessage:message andResults:results andWindowTitle:windowTitle onScreen:screen];
}

- (IBAction) doneWithResults:(id)sender
{
	[resultsWindow close];
	theRetainedSelf = nil;
}

@end
