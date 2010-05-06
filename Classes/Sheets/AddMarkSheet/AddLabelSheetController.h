//
//  AddLabelSheetController.h
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
	eAddLabelTabLocalTag  = 0x0,
	eAddLabelTabGlobalTag = 0x1,
	eAddLabelTabBookmark  = 0x2,
	eAddLabelTabBranch	  = 0x3
} AddLabelTabEnum;

@interface AddLabelSheetController : BaseSheetWindowController <NSTabViewDelegate>
{
	IBOutlet NSWindow*		theAddLabelSheet;
	IBOutlet NSTextField*	sheetInformativeMessageTextField;
	IBOutlet NSTextField*	addLabelSheetTitle;
	IBOutlet NSButton*		okButton;
	IBOutlet NSTabView*		addLabelTabView;

	IBOutlet NSTextView*	commitMessageTextView;

	MacHgDocument*		myDocument;
	
	NSString*			theNewNameFieldValue_;
	NSString*			theRevisionFieldValue_;
	NSAttributedString*	theMovementMessage_;
	NSAttributedString*	theScopeMessage_;
	NSAttributedString*	theCommitMessageValue_;
	BOOL				forceValue_;
	AddLabelTabEnum		addLabelTabNumber_;

}

@property (readwrite,assign) NSString*				theNewNameFieldValue;
@property (readwrite,assign) NSString*				theRevisionFieldValue;
@property (readwrite,assign) BOOL					forceValue;
@property (readwrite,assign) AddLabelTabEnum		addLabelTabNumber;
@property (readwrite,assign) NSAttributedString*	theMovementMessage;
@property (readwrite,assign) NSAttributedString*	theScopeMessage;
@property (readwrite,assign) NSAttributedString*	theCommitMessageValue;


- (AddLabelSheetController*) initAddLabelSheetControllerWithDocument:(MacHgDocument*)doc;


- (IBAction) openAddLabelSheet:(id)sender;
- (IBAction) sheetButtonOkForAddLabelSheet:(id)sender;
- (IBAction) sheetButtonCancelForAddLabelSheet:(id)sender;
- (IBAction) didSelectSegment:(id)sender;
- (IBAction) didChangeFieldContents:(id)sender;

- (void)	 openAddLabelSheetForMoveLabel:(LabelData*)label;

@end
