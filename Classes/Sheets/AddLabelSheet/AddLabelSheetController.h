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
}

@property NSString*				theNewNameFieldValue;
@property NSString*				theRevisionFieldValue;
@property BOOL					forceValue;
@property AddLabelTabEnum		addLabelTabNumber;
@property NSAttributedString*	theMovementMessage;
@property NSAttributedString*	theScopeMessage;
@property NSAttributedString*	theCommitMessageValue;
@property (weak,readonly) MacHgDocument*	myDocument;


- (AddLabelSheetController*) initAddLabelSheetControllerWithDocument:(MacHgDocument*)doc;


- (IBAction) openAddLabelSheet:(id)sender;

- (IBAction) openAddLabelSheetForBookmark:(id)sender;
- (IBAction) openAddLabelSheetForLocalTag:(id)sender;
- (IBAction) openAddLabelSheetForGlobalTag:(id)sender;
- (IBAction) openAddLabelSheetForBranch:(id)sender;

- (IBAction) sheetButtonOk:(id)sender;
- (IBAction) sheetButtonCancel:(id)sender;
- (IBAction) didSelectSegment:(id)sender;
- (IBAction) didChangeFieldContents:(id)sender;

@end
