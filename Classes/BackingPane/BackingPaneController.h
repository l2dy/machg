//
//  BackingPaneController.h
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface BackingPaneController : NSViewController <AccessesDocument>
{
	MacHgDocument*	myDocument;
	IBOutlet NSBox*	backingBox;
	IBOutlet NSBox*	buttonBox;
}

@property (nonatomic, assign) NSBox* buttonBox;
@property (nonatomic, assign) NSBox* backingBox;
@property (readwrite,assign) MacHgDocument*  myDocument;

- (BackingPaneController*) initBackingPaneControllerWithDocument:(MacHgDocument*)doc;

@end

// This box draws itself with a radial gradiant centered on the centering Object
@interface RadialGradiantBox : NSBox
{
	IBOutlet NSView*	centeringObject;
}

@end
