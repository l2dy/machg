//
//  BackingViewController.m
//  MacHg
//
//  Created by Jason Harris on 12/4/09.
//  Copyright 2010 Jason F Harris. All rights reserved.
//  This software is licensed under the "New BSD License". The full license text is given in the file License.txt
//

#import "BackingViewController.h"
#import <QuartzCore/CIFilter.h>


@implementation BackingViewController

@synthesize buttonBox;
@synthesize backingBox;
@synthesize backingView;
@synthesize myDocument = myDocument_;





// ------------------------------------------------------------------------------------
// MARK: -
// MARK: Initialization
// ------------------------------------------------------------------------------------

- (BackingViewController*) initBackingViewControllerWithDocument:(MacHgDocument*)doc
{
	myDocument_ = doc;
	self = [self initWithNibName:@"BackingView" bundle:nil];
	[self loadView];
	return self;
}

- (void) awakeFromNib
{
}


@end



@implementation BackingView

@synthesize parentContoller = parentContoller_;
@synthesize myDocument = myDocument_;

-(void) unload
{
}

- (void) prepareToOpenBackingView
{
}

- (BOOL) validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem, NSObject >)anItem
{
	return NO;
}

@end
