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
	MacHgDocument*			__strong myDocument;
	IBOutlet NSBox*			__strong backingBox;
	IBOutlet NSBox*			__strong buttonBox;
	IBOutlet BackingView*	__strong backingView;
}

@property (readwrite,strong) MacHgDocument*  myDocument;
@property (nonatomic, strong) NSBox* buttonBox;
@property (nonatomic, strong) NSBox* backingBox;
@property (nonatomic, strong) BackingView* backingView;

- (BackingViewController*) initBackingViewControllerWithDocument:(MacHgDocument*)doc;

@end





@interface BackingView : NSView <AccessesDocument, NSUserInterfaceValidations>
{
	IBOutlet BackingViewController* parentContoller;
	MacHgDocument*					__strong myDocument;
}

@property (readwrite,strong) MacHgDocument*	myDocument;

- (void)	 unload;
- (void)	 prepareToOpenBackingView;
@end
