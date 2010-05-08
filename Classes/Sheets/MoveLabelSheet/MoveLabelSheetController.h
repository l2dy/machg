//
//  MoveLabelSheetController.h
//  MacHg
//
//  Created by Jason Harris on 5/05/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

typedef enum
{
	eMoveLabelTabLocalTag  = 0x0,
	eMoveLabelTabGlobalTag = 0x1,
	eMoveLabelTabBookmark  = 0x2,
	eMoveLabelTabBranch	  = 0x3
} MoveLabelTabEnum;

@interface MoveLabelSheetController : BaseSheetWindowController <NSTabViewDelegate>
{
	IBOutlet NSWindow*		theMoveLabelSheet;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	moveLabelSheetTitle;
	IBOutlet NSButton*		okButton;
	IBOutlet NSTabView*		moveLabelTabView;

	IBOutlet NSTextView*	commitMessageTextView;

	MacHgDocument*		myDocument;
	
	NSString*			theNewNameFieldValue_;
	NSString*			theRevisionFieldValue_;
	NSAttributedString*	theMovementMessage_;
	NSAttributedString*	theScopeMessage_;
	NSAttributedString*	theCommitMessageValue_;
	BOOL				forceValue_;
	MoveLabelTabEnum		moveLabelTabNumber_;

}

@property (readwrite,assign) NSString*				theNewNameFieldValue;
@property (readwrite,assign) NSString*				theRevisionFieldValue;
@property (readwrite,assign) BOOL					forceValue;
@property (readwrite,assign) MoveLabelTabEnum		moveLabelTabNumber;
@property (readwrite,assign) NSAttributedString*	theMovementMessage;
@property (readwrite,assign) NSAttributedString*	theScopeMessage;
@property (readwrite,assign) NSAttributedString*	theCommitMessageValue;


- (MoveLabelSheetController*) initMoveLabelSheetControllerWithDocument:(MacHgDocument*)doc;


- (IBAction) openMoveLabelSheet:(id)sender;
- (IBAction) sheetButtonOkForMoveLabelSheet:(id)sender;
- (IBAction) sheetButtonCancelForMoveLabelSheet:(id)sender;
- (IBAction) didSelectSegment:(id)sender;
- (IBAction) didChangeFieldContents:(id)sender;

- (void)	 openMoveLabelSheetForMoveLabel:(LabelData*)label;

@end
