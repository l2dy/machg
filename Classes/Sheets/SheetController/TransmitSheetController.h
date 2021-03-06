//
//  SheetController.h
//  MacHg
//
//  Created by Jason Harris on 1/22/10.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "Common.h"

// This sheet controller is the basis for the push / pull / incoming / outgoing sheets. There is a lot of common code in those
// sheets like the layout of the source and destination and syncing of options with connections, etc. It's collected into this
// parent class.
@interface TransmitSheetController : BaseSheetWindowController<NSMenuDelegate, NSWindowDelegate>
{
	IBOutlet NSWindow*			sheetWindow;					// The window of the sheet
	IBOutlet NSTextField*		titleText;						// The title of the sheer.

	IBOutlet NSImageView*		sourceIconWell;					// Image well showing an icon of the source.
	IBOutlet NSImageView*		destinationIconWell;			// Image well showing an icon of the destination.
	IBOutlet NSView*			sourceLabel;					// The label for the source can be the repository name or could be the popup with the compatible repositories.
	IBOutlet NSView*			destinationLabel;				// The label for the destination can be the repository name or could be the popup with the compatible repositories.
	IBOutlet NSTextField*		sourceURI;						// The URI for the source (path if local URL if remote)
	IBOutlet NSTextField*		destinationURI;					// the URI for the destination (path if local URL if remote)
	IBOutlet NSTextField*		incomingOutgoingCount;			// The label where we display the count of incoming / outgoing
	IBOutlet NSBox*				mainGroupingBox;				// The box containing the source and the destion labels, arrows, icons, popups and URI.

	IBOutlet NSBox*				advancedOptionsBox;				// The box containing all the advanced options
	IBOutlet NSButton*			sheetButtonAllowOperationWithAnyRepository;
	IBOutlet NSPopUpButton*		compatibleRepositoriesPopup;
	IBOutlet OptionController*	forceOption;
	IBOutlet DisclosureBoxController*	disclosureController;	// The disclosure box for the advanced options
	NSArray*					cmdOptions;						// The collection of advanced option controllers

@protected
	MacHgDocument* __weak		myDocument_;
}

@property (weak,readonly) MacHgDocument*	myDocument;
@property BOOL			allowOperationWithAnyRepository;		// Do we list incompatible repositories



// These methods *must* be re-implemented in the children. What I would like to do here is say these methods are pure like in C++
// I would say = 0 here, but I don't think this is possible in Objective-C. If you know and it is then email me!
- (SidebarNode*)		sourceRepository;
- (SidebarNode*)		destinationRepository;
- (NSString*)			operationName;
- (OptionController*)	commonRevOption;
- (MacHgDocument*)		myDocument;


// Utilities
- (NSString*) sourceRepositoryName;
- (NSString*) destinationRepositoryName;

// Sheet handling
- (IBAction)  openSheet:(id)sender;
- (void)	  layoutGroupsForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination;

// PopupMenu control and syncing
- (IBAction)  syncForceOptionToAllowOperationAndRepopulate:(id)sender;
- (IBAction)  populatePopupMenuItemsAndRelayout:(id)sender;
- (void)	  setConnectionFromFieldsForSource:(SidebarNode*)source		andDestination:(SidebarNode*)destination;
- (void)	  setFieldsFromConnectionForSource:(SidebarNode*)source		andDestination:(SidebarNode*)destination;
- (void)	  updateIncomingOutgoingCountForSource:(SidebarNode*)source andDestination:(SidebarNode*)destination;
- (void)	  updateIncomingOutgoingCount;

@end
