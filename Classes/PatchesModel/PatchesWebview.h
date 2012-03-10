//
//  PatchesWebview.h
//  MacHg
//
//  Created by Jason Harris on 1/29/12.
//  Copyright 2012 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "Common.h"
#import "TaskExecutions.h"





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  ControllerForPatchesWebview
// -----------------------------------------------------------------------------------------------------------------------------------------
// All Controllers which embed a FSBrowser must conform to this protocol
@protocol ControllerForPatchesWebview <NSObject>
- (MacHgDocument*)	myDocument;
- (HunkExclusions*)	hunkExclusions;				// The hunk exclusions which mediate which hunks are excluded or not
- (NSURL*)			patchDetailURL;				// The URL of the page to display
@end




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  RegenerationTaskController
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface RegenerationTaskController : ShellTaskController
{
	NSInteger taskNumber_;
}
@property (nonatomic, assign) NSInteger	taskNumber;
@end




// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  PatchesWebview
// -----------------------------------------------------------------------------------------------------------------------------------------

@interface PatchesWebview : WebView
{
	IBOutlet id <ControllerForPatchesWebview> parentController;
	RegenerationTaskController* currentRegenerationTask_; // The current regenerationTask if there is one.
	PatchData*	backingPatch_;			// This is the patch to display in the webview.
	NSString*	fallbackMessage_;		// This is the message to display if we don't have a patch to display.
	NSInteger	taskNumber_;			// This is the task number that was most reently exectued to process and display a patch.
										// It happends that if the user chooses a really large patch and then quickly chooses a
										// smaller patch and the smaller patch is processed and dispalyed first we must make sure
										// that once the bigger patch finishes it doesn't overwrite the later smaller patch and so
										// we record the task number to prevents this.
	NSString*  repositoryRootForPatch_;	// When we load up a new patch, record it's root path so we can use this for access into
										// the hunkExclusions
	BOOL		showExternalDiffButton_;// Do we show the external diff button in the patches.
}
@property (assign,readwrite) BOOL	showExternalDiffButton;


// Refreshing and Regeneration
- (NSInteger) nextTaskNumber;		// Start a new process and display of a patch.
- (NSInteger) currentTaskNumber;	// What is the current latest task number.
- (void)	  regenerateDifferencesForSelectedPaths:(NSArray*)selectedPaths andRoot:(NSString*)rootPath;
- (void)      setBackingPatch:(PatchData*)patchData andFallbackMessage:(NSString*)fallbackMessage;
- (void)      setBackingPatch:(PatchData*)patchData andFallbackMessage:(NSString*)fallbackMessage withTaskNumber:(NSInteger)taskNumber;


// Actions
- (IBAction)  fileDiffsDisplayPreferencesChanged:(id)sender;	// Respond to a change in the display preferences

@end
