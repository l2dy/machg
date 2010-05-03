//
//  ResultsWindowController.m
//  MacHg
//
//  Created by Jason Harris on 16/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import "ResultsWindowController.h"
#import "Common.h"
#import "TaskExecutions.h"

@implementation ResultsWindowController

- (ResultsWindowController*) initWithMessage:(NSString*)message andResults:(NSAttributedString*)results andWindowTitle:(NSString*)windowTitle
{
	[NSBundle loadNibNamed:@"ResultsWindow" owner:self];
	[titleMessageTextField setStringValue:message];
	[[resultsMessageTextView textStorage] setAttributedString:results];

	NSSize titleSize = [[titleMessageTextField attributedStringValue] size];
	NSSize resultsSize = [results size];
	NSSize newSize;
	newSize.width  = MAX(resultsSize.width,  titleSize.width);
	newSize.width  = MIN(1000, newSize.width);
	newSize.height = MAX(resultsSize.height, titleSize.height);
	newSize.height = MIN(720, newSize.height);
	newSize.width  += 40;
	newSize.height += 70;

	NSSize currentSize = [resultsMessageTextView frame].size;
	NSRect f = [resultsWIndow frame];
	f.size.width  += (newSize.width  - currentSize.width);
	f.size.height += (newSize.height - currentSize.height);
	[resultsWIndow setFrame:f display:YES];
	[resultsWIndow setTitle:windowTitle];
	[resultsWIndow makeKeyAndOrderFront:self];
	[resultsWIndow makeFirstResponder:okButtonForResultsWindow];

	return self;
}

+ (ResultsWindowController*) createWithMessage:(NSString*)message andResults:(NSAttributedString*)results andWindowTitle:(NSString*)windowTitle
{
	return [[ResultsWindowController alloc] initWithMessage:message andResults:results andWindowTitle:windowTitle];
}


- (IBAction) doneWithResults:(id)sender
{
	[resultsWIndow close];
}

@end
