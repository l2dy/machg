//
//  ResultsWindowController.h
//  MacHg
//
//  Created by Jason Harris on 16/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ResultsWindowController : NSObject
{
	IBOutlet NSTextField*	titleMessageTextField;
	IBOutlet NSTextView*	resultsMessageTextView;
	IBOutlet NSWindow*		resultsWIndow;
	IBOutlet NSButton*		okButtonForResultsWindow;
	
	NSString*				pendingMessage;
	NSString*				pendingWindowTitle;
}

- (IBAction) doneWithResults:(id)sender;

- (ResultsWindowController*) initWithMessage:(NSString*)message andResults:(NSAttributedString*)results andWindowTitle:(NSString*)windowTitle;
+ (ResultsWindowController*) createWithMessage:(NSString*)message andResults:(NSAttributedString*)results andWindowTitle:(NSString*)windowTitle;

@end
