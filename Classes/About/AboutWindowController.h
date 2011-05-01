//
//  AboutWindowController.h
//  MacHg
//
//  Created by Jason Harris on 5/1/11.
//  Copyright 2011 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WebView;

@interface AboutWindowController : NSWindowController
{
	IBOutlet NSWindow*			aboutWindow;
	IBOutlet WebView*			creditsWebview;
	IBOutlet RadialGradiantBox*	backingBox;	
}

- (AboutWindowController*) initAboutWindowController;
- (void)	  showAboutWindow;
- (void)	  webView:(WebView*)webView decidePolicyForNavigationAction:(NSDictionary*)actionInformation request:(NSURLRequest*)request frame:(WebFrame*)frame decisionListener:(id < WebPolicyDecisionListener >)listener;

// Version Utilities
- (NSString*) shortMacHgVersionString;				// Eg "MacHg 0.9.5"
- (NSString*) shortMercurialVersionString;			// Eg "Mercurial SCM 1.5.3"
- (NSString*) macHgBuildHashKeyString;				// Eg "df3754a23dd7"
- (NSString*) mercurialBuildHashKeyString;			// Eg "20100514"

@end
