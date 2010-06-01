//
//  BackingPaneController.m
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "BackingPaneController.h"
#import <QuartzCore/CIFilter.h>


@implementation BackingPaneController

@synthesize buttonBox;
@synthesize backingBox;
@synthesize myDocument;





// -----------------------------------------------------------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// -----------------------------------------------------------------------------------------------------------------------------------------

- (BackingPaneController*) initBackingPaneControllerWithDocument:(MacHgDocument*)doc
{
	myDocument = doc;
	[NSBundle loadNibNamed:@"BackingPane" owner:self];
	return self;
}

- (void) awakeFromNib
{
}


@end



