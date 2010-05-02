//
//  BrowserPaneController.h
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "FSBrowser.h"

@interface BrowserPaneController : NSViewController <AccessesDocument, ControllerForFSBrowser>
{
	IBOutlet FSBrowser*		theBrowser;
	IBOutlet NSImageView*	nodeIconWell;  // Image well showing the selected items icon.
	IBOutlet NSTextField*	nodeInspector; // Text field showing the selected items attributes.
	MacHgDocument*			myDocument;
}

@property (readwrite,assign) MacHgDocument*	myDocument;
@property (readonly,assign)  FSBrowser*		theBrowser;

- (BrowserPaneController*) initBrowserPaneControllerWithDocument:(MacHgDocument*)doc;
- (void)	 unload;

- (IBAction) refreshBrowserContent:(id)sender;
- (NSArray*) statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath;
- (void)	 updateCurrentPreviewImage;

@end
