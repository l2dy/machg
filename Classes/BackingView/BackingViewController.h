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

@property (nonatomic) BackingView* backingView;
@property (nonatomic) NSBox* backingBox;
@property (nonatomic) NSBox* buttonBox;

- (BackingViewController*) initBackingViewControllerWithDocument:(MacHgDocument*)doc;

@end





@interface BackingView : NSView <AccessesDocument, NSUserInterfaceValidations>
{
	IBOutlet BackingViewController* parentContoller;
}

@property (weak,readonly) MacHgDocument*	myDocument;

- (void)	 unload;
- (void)	 prepareToOpenBackingView;
@end
