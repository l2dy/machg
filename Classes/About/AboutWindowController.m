//
//  AboutWindowController.m
//  MacHg
//
//  Created by Jason Harris on 5/1/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "Common.h"
#import "AboutWindowController.h"
#import "RadialGradiantBox.h"
#import "AppController.h"


@implementation AboutWindowController

- (AboutWindowController*) initAboutWindowController
{
	return self;
}

- (void) showAboutWindow
{
	if (![self window])
	{
		[NSBundle loadNibNamed:@"About" owner:self];
		[backingBox setRadius:[NSNumber numberWithFloat:190.0]];
		[backingBox setOffsetFromCenter:NSMakePoint(0.0, -40.0)];
		[backingBox setNeedsDisplay:YES];
		NSURL* creditsURL = [NSURL fileURLWithPath:fstr(@"%@/MacHGHelp/%@",[[NSBundle mainBundle] resourcePath], @"Credits.html")];
		[[creditsWebview mainFrame] loadRequest:[NSURLRequest requestWithURL:creditsURL]];			
	}
	[[self window] makeKeyAndOrderFront:nil];
}

- (void) webView:(WebView*)webView decidePolicyForNavigationAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request frame:(WebFrame*)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
	// Any non file URL gets opened externally to MacHg. Ie in Safari, etc.
	if (![[request URL] isFileURL])
	{
		NSURL* paypalURL = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VUKBMKTKZMPV2"];
		
		// Strangely due to http: www.cocoabuilder.com/archive/cocoa/165312-open-safari-and-send-post-variables.html#165322 it
		// appears that you can't open safari with a post NSURLRequest. This appears to be a limitation. Anyway, because of this
		// specially intercept the method we would send out to paypal and change it to the link above.
		if ([[[request URL] absoluteString] isEqualToString:@"https://www.paypal.com/cgi-bin/webscr"])
			[[NSWorkspace sharedWorkspace] openURL:paypalURL];
		else
			[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
	else
		[listener use];
}

- (NSString*) shortMacHgVersionString		{ return [[AppController sharedAppController] shortMacHgVersionString]; }
- (NSString*) shortMercurialVersionString	{ return [[AppController sharedAppController] shortMercurialVersionString]; }
- (NSString*) macHgBuildHashKeyString		{ return [[AppController sharedAppController] macHgBuildHashKeyString]; }
- (NSString*) mercurialBuildHashKeyString	{ return [[AppController sharedAppController] mercurialBuildHashKeyString]; }

@end
