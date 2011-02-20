//
//  DisclosureBoxController.h
//  MacHg
//
//  Created by Jason Harris on 22/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"



// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  DisclosureBoxController
// -----------------------------------------------------------------------------------------------------------------------------------------

// This disclosure controller controls nicely sliding out a box or hiding a box. Eg when we want to show / hide advanced options
// we put them all in a box and link it to the disclosure box. The parentWindow grows by the size of the disclosure box when it is
// shown and shrinks by the size of the disclosure box when it is hidden. The disclosure box controller also caches information
// about all the other views which are children of the parent window. It records the autoresize mask and if the view is above or
// below the disclosure box. Then when the disclosure is happening it sets the auto resize mask correctly to allow the subviews to
// adjust correctly to showing the main disclosure view. When the disclosure is fully shown it resets the auto resize masks back
// to their original values.

@interface DisclosureBoxController : NSObject
{
	IBOutlet NSWindow*			parentWindow;
	IBOutlet NSButton*			disclosureButton;
	IBOutlet NSBox*				disclosureBox;
	
	NSMapTable*					savedViewsInfo;			// Dictionary of NSView* view -> SavedViewInfo (We use an NSMapTable instead
														// of an NSDictionary since our keys are pointer values.)
	NSString*					autoSaveName_;			// The NSUserDefaults key name (if any) for the state of the disclosure box
	BOOL						disclosureIsVisable_;	// Do we show the disclosure box (if we don't have a button we still need
	NSInteger					animationDepth_;
	BOOL						savedShowsResizeIndicator_;	// Did this window show its resize indicator
}
@property (readonly,assign) NSBox*  disclosureBox;

- (IBAction) disclosureTrianglePressed:(id)sender;
- (void)     ensureDisclosureBoxIsOpen:(BOOL)animate;
- (void)     ensureDisclosureBoxIsClosed:(BOOL)animate;
- (void)     setToOpenState:(BOOL)state withAnimation:(BOOL)animate;
- (BOOL)	 disclosureIsVisable;

- (void)	 setBackgroundToBad;	// Color the background of the disclosure box in the "error" style
- (void)	 setBackgroundToGood;	// Color the background of the disclosure box in the "valid" style
- (void)	 roundTheBoxCorners;	// Set the rounding of the corners of the box so it looks a little nicer.
@end





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK:  SavedViewInfo
// -----------------------------------------------------------------------------------------------------------------------------------------

// Typedef and class to record the original view auto resize mask and relative view location

typedef enum
{
	eViewAboveDisclosure = 0,
	eViewBelowDisclosure = 1
} ViewPosition;


@interface SavedViewInfo : NSObject
{
	NSUInteger		mask_;
	ViewPosition	position_;
};

@property (readwrite,assign) NSUInteger		mask;
@property (readwrite,assign) ViewPosition	position;

+ (SavedViewInfo*)	savedViewInfoWithMask:(NSUInteger)mask position:(ViewPosition)position;

@end
