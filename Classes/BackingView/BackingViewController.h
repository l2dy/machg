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
{
	MacHgDocument*			myDocument;
	IBOutlet NSBox*			backingBox;
	IBOutlet NSBox*			buttonBox;
	IBOutlet BackingView*	backingView;
}

@property (readwrite,assign) MacHgDocument*  myDocument;
@property (nonatomic, assign) NSBox* buttonBox;
@property (nonatomic, assign) NSBox* backingBox;
@property (nonatomic, assign) BackingView* backingView;

- (BackingViewController*) initBackingViewControllerWithDocument:(MacHgDocument*)doc;

@end





@interface BackingView : NSView <AccessesDocument, NSUserInterfaceValidations>
{
	IBOutlet BackingViewController* parentContoller;
	MacHgDocument*					myDocument;
}

@property (readwrite,assign) MacHgDocument*	myDocument;

- (void)	 unload;
- (void)	 prepareToOpenBackingView;
@end
