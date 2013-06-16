//
//  BackingViewController.h
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface BackingViewController : NSViewController <AccessesDocument>

@property (weak,readonly) MacHgDocument*  myDocument;

@property (nonatomic) IBOutlet BackingView* backingView;
@property (nonatomic) IBOutlet NSBox* backingBox;
@property (nonatomic) IBOutlet NSBox* buttonBox;

- (BackingViewController*) initBackingViewControllerWithDocument:(MacHgDocument*)doc;

@end





@interface BackingView : NSView <AccessesDocument, NSUserInterfaceValidations>

@property (weak,readonly) MacHgDocument*			myDocument;
@property (assign) IBOutlet BackingViewController*	parentContoller;

- (void)	 prepareToOpenBackingView;
@end
