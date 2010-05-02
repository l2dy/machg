//
//  BackingPaneController.h
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Common.h"

@interface BackingPaneController : NSViewController <AccessesDocument>
{
	MacHgDocument*	myDocument;
}

@property (readwrite,assign) MacHgDocument*  myDocument;

- (BackingPaneController*) initBackingPaneControllerWithDocument:(MacHgDocument*)doc;

@end
