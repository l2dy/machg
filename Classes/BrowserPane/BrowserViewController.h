//
//  BrowserViewController.h
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"
#import "FSBrowser.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  BrowserViewController
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface BrowserViewController : NSViewController
{
	MacHgDocument*			myDocument;
	IBOutlet BrowserView*	theBrowserView;
}
@property (readwrite,assign) MacHgDocument*	myDocument;
@property (readwrite,assign) BrowserView*	theBrowserView;

- (BrowserViewController*) initBrowserViewControllerWithDocument:(MacHgDocument*)doc;
- (void) unload;
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  BrowserView
// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -

@interface BrowserView : NSView <AccessesDocument, ControllerForFSBrowser>
{
	IBOutlet BrowserViewController* parentContoller;
	IBOutlet FSBrowser*		theBrowser;
	IBOutlet NSImageView*	nodeIconWell;  // Image well showing the selected items icon.
	IBOutlet NSTextField*	nodeInspector; // Text field showing the selected items attributes.
	MacHgDocument*			myDocument;
}

@property (readwrite,assign) MacHgDocument*	myDocument;
@property (readonly,assign)  FSBrowser*		theBrowser;

- (void)	 unload;

- (IBAction) refreshBrowserContent:(id)sender;
- (NSArray*) statusLinesForPaths:(NSArray*)absolutePaths withRootPath:(NSString*)rootPath;
- (void)	 updateCurrentPreviewImage;

@end
